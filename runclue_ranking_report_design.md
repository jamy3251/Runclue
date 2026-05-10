# RunClue 랭킹/리포트 배치 설계 + Redis/크론/큐 + 쿼리 최적화

## 1. 목표
- 참여/완주/보상 이벤트를 **실시간에 가깝게** 반영
- 모바일 앱은 가볍게 조회하고, 최종 집계/정산은 **PostgreSQL**에서 신뢰 가능한 스냅샷으로 남김
- Redis는 **순위/카운터/단기 집계**, PostgreSQL은 **원장/감사/스냅샷** 역할

## 2. 왜 이 구조인가
- Redis Sorted Set은 멤버를 점수로 정렬해 **리더보드**를 구현하기 좋다.
- Redis Pub/Sub은 **at-most-once**라 이벤트 유실 가능성이 있어, 배치/집계 입력엔 부적합하다.
- Redis Streams는 **지속성 + stronger delivery semantics**가 가능하므로, 랭킹/리포트 집계 입력 큐로 더 적합하다.
- PostgreSQL은 파티셔닝과 인덱스 전략으로 evidences/audit_logs/report tables 유지보수에 유리하다.
- clue_steps.config 같은 JSONB는 GIN 인덱스로 탐색/필터 성능을 확보할 수 있다.

## 3. 권장 데이터 흐름(Outbox + Streams)
1. API 서버가 PostgreSQL 트랜잭션 안에서 원장 테이블 업데이트
2. 같은 트랜잭션에서 `domain_outbox`에 이벤트 기록
3. Outbox relay worker가 Redis Stream으로 `XADD`
4. `ranking-consumer`, `report-consumer`, `notification-consumer`가 consumer group으로 처리
5. Redis 실시간 집계 반영
6. 주기적 snapshot/reconcile job이 PostgreSQL 스냅샷 테이블에 확정 저장

## 4. 추가 테이블 제안
```sql
CREATE TABLE domain_outbox (
  id                BIGSERIAL PRIMARY KEY,
  event_type        TEXT NOT NULL,
  aggregate_type    TEXT NOT NULL,
  aggregate_id      UUID NOT NULL,
  payload           JSONB NOT NULL,
  idempotency_key   TEXT NOT NULL UNIQUE,
  occurred_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  published_at      TIMESTAMPTZ
);

CREATE INDEX idx_domain_outbox_unpublished
  ON domain_outbox (occurred_at)
  WHERE published_at IS NULL;

CREATE TABLE report_daily_user (
  local_date        DATE NOT NULL,
  user_id           UUID NOT NULL,
  region_code       TEXT,
  clues_joined      INTEGER NOT NULL DEFAULT 0,
  clues_completed   INTEGER NOT NULL DEFAULT 0,
  steps_completed   INTEGER NOT NULL DEFAULT 0,
  reward_points     BIGINT NOT NULL DEFAULT 0,
  reward_krw        BIGINT NOT NULL DEFAULT 0,
  first_places      INTEGER NOT NULL DEFAULT 0,
  streak_days       INTEGER NOT NULL DEFAULT 0,
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (local_date, user_id)
) PARTITION BY RANGE (local_date);

CREATE TABLE weekly_ranking_snapshots (
  week_key          TEXT NOT NULL,
  scope_type        TEXT NOT NULL,      -- GLOBAL | REGION | CLUE
  scope_id          TEXT NOT NULL,
  user_id           UUID NOT NULL,
  rank              INTEGER NOT NULL,
  score             BIGINT NOT NULL,
  percentile        NUMERIC(5,2),
  generated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (week_key, scope_type, scope_id, user_id)
);
```

## 5. 이벤트 타입
```json
[
  "PARTICIPATION_JOINED",
  "STEP_VALIDATED",
  "STEP_FAILED",
  "CLUE_COMPLETED",
  "REWARD_ISSUED",
  "REPORT_CORRECTION_APPLIED",
  "USER_PENALTY_APPLIED"
]
```

### 권장 이벤트 payload 예시
```json
{
  "eventType": "CLUE_COMPLETED",
  "eventId": "evt_01JQ...",
  "occurredAt": "2026-03-06T20:05:30+09:00",
  "userId": "6c3c0e7d-70d4-4da5-b6ab-c0fef0f67aaa",
  "clueId": "f9c6f8a0-7d25-4af3-bd7d-0b76da694321",
  "regionCode": "KR-41-GURI",
  "difficulty": "MEDIUM",
  "baseScore": 1200,
  "speedBonus": 180,
  "rewardPoints": 250,
  "rewardKrw": 10000,
  "weekKey": "2026-W10"
}
```

## 6. Redis 키 설계
### 실시간 랭킹
- `rc:lb:weekly:global:{weekKey}` → ZSET (`member=userId`, `score=weeklyScore`)
- `rc:lb:weekly:region:{regionCode}:{weekKey}` → ZSET
- `rc:lb:weekly:clue:{clueId}:{weekKey}` → ZSET

### 실시간 리포트 카운터
- `rc:report:daily:user:{userId}:{yyyyMMdd}` → HASH
- `rc:report:daily:region:{regionCode}:{yyyyMMdd}` → HASH

### 중복 방지 / 락
- `rc:idem:event:{eventId}` → STRING/SETEX
- `rc:lock:weekly-snapshot:{weekKey}` → STRING NX EX
- `rc:lock:report-materialize:{yyyyMMdd}` → STRING NX EX

### 큐
- `stream:runclue:ranking-events`
- `stream:runclue:report-events`
- `stream:runclue:notification-events`

## 7. 점수 모델(정수 기반 권장)
Redis sorted set score는 64-bit floating point다. 정수는 `±2^53` 범위까지 정확히 표현되므로,
랭킹 점수는 **소수점 없이 정수 점수**를 쓰는 편이 안전하다.

```text
weeklyScore =
  baseScore
+ difficultyWeight
+ speedBonus
+ streakBonus
+ featuredEventBonus
- manualPenalty
```

### 예시
- STEP_VALIDATED: +50 ~ +300
- CLUE_COMPLETED: +800 ~ +2000
- 1등 보너스: +500
- 운영 페널티: -1000

## 8. Consumer Group 구성
### ranking-consumer-group
- 입력: `stream:runclue:ranking-events`
- 처리:
  - `ZINCRBY rc:lb:weekly:global:{weekKey} scoreDelta userId`
  - `ZINCRBY rc:lb:weekly:region:{regionCode}:{weekKey} scoreDelta userId`
  - `ZINCRBY rc:lb:weekly:clue:{clueId}:{weekKey} scoreDelta userId`
  - `HINCRBY rc:report:daily:user:{userId}:{yyyyMMdd} clues_completed 1`
  - ACK

### report-consumer-group
- 입력: `stream:runclue:report-events`
- 처리:
  - `HINCRBY` / `HSET`
  - 리포트용 streak, top_category, top_region 등 보조값 계산
  - ACK

### notification-consumer-group
- 입력: 보상/리포트 완성 이벤트
- 처리:
  - 인앱 알림/푸시 발송
  - ACK

## 9. 크론 스케줄(Asia/Seoul 기준)
### 매분
- `outbox-relay`: 미전송 outbox → Redis Streams 발행
- `stream-pending-retry`: idle pending message 재할당

### 5분마다
- `leaderboard-reconcile-light`
  - Redis 상위 1000명과 PostgreSQL recent deltas 샘플 대조
- `report-flush-partials`
  - Redis HASH → PostgreSQL `report_daily_user` UPSERT

### 매시 10분
- `clue-expiry-sync`
  - 만료된 clue status sync / ranking 대상 제외 반영

### 매일 00:10
- `daily-report-materialize`
  - 전날 `report_daily_user` finalize
  - 오늘 주간 streak 계산 업데이트

### 매주 월요일 00:05
- `weekly-ranking-snapshot`
  - Redis ZSET → PostgreSQL `weekly_ranking_snapshots`
  - rank / percentile 계산
  - Redis key TTL 갱신(예: +14일 보관 후 삭제)

### 매주 월요일 00:20
- `weekly-report-generate`
  - 개인 주간 리포트 materialize
  - 알림 큐 적재

### 매월 1일 00:30
- `partition-maintenance`
  - 다음 2개월 파티션 선생성
  - 오래된 evidence/report partition 아카이브/삭제

## 10. Snapshot 알고리즘
### weekly-ranking-snapshot
1. `SET rc:lock:weekly-snapshot:{weekKey} NX EX 900`
2. `ZREVRANGE rc:lb:weekly:global:{weekKey} 0 99999 WITHSCORES`
3. 순위 계산:
   - rank = dense rank 또는 standard rank 중 정책 선택
   - percentile = `100 * (1 - (rank - 1) / totalParticipants)`
4. `COPY` 또는 batch insert로 `weekly_ranking_snapshots` 저장
5. `generated_at` 확정
6. 알림 이벤트 발행

### 주의
- tie-break는 `score DESC, user_id ASC`처럼 deterministic 하게
- 모바일 표시는 Redis 실시간, 정산/보상은 PostgreSQL snapshot 기준

## 11. Reconcile 전략
### 왜 필요하나
- Streams는 at-least-once로 재처리될 수 있으니, 소비자는 **idempotent** 해야 한다.
- Outbox relay / consumer 재시작 / 네트워크 이슈 대비

### 방법
- `eventId` 또는 `idempotency_key`별 처리 이력 Redis SET + PostgreSQL 테이블 유지
- consumer는 처리 전 `SETNX processed:{eventId}` 확인
- weekly snapshot 직전에는 `domain_outbox` 대비 누락 이벤트 샘플 검사

## 12. 쿼리 최적화: 핵심 패턴

## 12.1 탐색(내 주변 클루)
### 권장 컬럼
```sql
ALTER TABLE clues
  ADD COLUMN geo_lat NUMERIC(9,6),
  ADD COLUMN geo_lng NUMERIC(9,6),
  ADD COLUMN geohash6 TEXT,
  ADD COLUMN reward_total_krw BIGINT DEFAULT 0,
  ADD COLUMN popularity_score BIGINT DEFAULT 0,
  ADD COLUMN is_featured BOOLEAN DEFAULT false;
```

### 권장 인덱스
```sql
CREATE INDEX idx_clues_live_public
  ON clues (status, visibility, start_at, end_at);

CREATE INDEX idx_clues_geohash6_live
  ON clues (geohash6, start_at DESC)
  WHERE status = 'PUBLISHED';

CREATE INDEX idx_clues_category_live
  ON clues (category, start_at DESC)
  WHERE status = 'PUBLISHED';
```

### 조회 패턴
1. geohash6 또는 bounding box로 후보 축소
2. 시간/가시성 필터
3. 거리 계산은 후보에만 적용
4. 정렬은 `featured DESC, distance ASC, popularity_score DESC`

```sql
WITH candidate AS (
  SELECT
    c.id,
    c.title,
    c.category,
    c.reward_total_krw,
    c.geo_lat,
    c.geo_lng,
    c.popularity_score,
    c.is_featured,
    (
      6371000 * acos(
        cos(radians($1)) * cos(radians(c.geo_lat)) *
        cos(radians(c.geo_lng) - radians($2)) +
        sin(radians($1)) * sin(radians(c.geo_lat))
      )
    ) AS distance_m
  FROM clues c
  WHERE c.status = 'PUBLISHED'
    AND c.visibility IN ('PUBLIC', 'UNLISTED_DISCOVERABLE')
    AND c.geohash6 = ANY($3)
    AND now() BETWEEN c.start_at AND c.end_at
)
SELECT *
FROM candidate
WHERE distance_m <= $4
ORDER BY is_featured DESC, distance_m ASC, popularity_score DESC
LIMIT $5 OFFSET $6;
```

## 12.2 사용자 진행도(현재 참여 중 클루)
### 인덱스
```sql
CREATE INDEX idx_participations_user_active
  ON participations (user_id, status, joined_at DESC)
  WHERE status IN ('JOINED', 'IN_PROGRESS');

CREATE INDEX idx_clue_steps_clue_order
  ON clue_steps (clue_id, order_no);
```

### 조회
```sql
SELECT
  p.id,
  p.clue_id,
  p.status,
  p.current_step_order,
  c.title,
  c.end_at,
  s.id  AS current_step_id,
  s.type AS current_step_type,
  s.config
FROM participations p
JOIN clues c
  ON c.id = p.clue_id
LEFT JOIN clue_steps s
  ON s.clue_id = p.clue_id
 AND s.order_no = p.current_step_order
WHERE p.user_id = $1
  AND p.status IN ('JOINED', 'IN_PROGRESS')
ORDER BY p.joined_at DESC
LIMIT 20;
```

## 12.3 step.config 필터링(예: 촬영 포함/야간/팀전)
`clue_steps.config` 같은 JSONB 필드는 GIN 인덱스 사용 권장.

```sql
CREATE INDEX idx_clue_steps_config_gin
  ON clue_steps
  USING GIN (config jsonb_path_ops);

CREATE INDEX idx_clue_steps_type
  ON clue_steps (type);
```

### 예시
```sql
SELECT DISTINCT c.id, c.title
FROM clues c
JOIN clue_steps s ON s.clue_id = c.id
WHERE c.status = 'PUBLISHED'
  AND s.type = 'SNAPSHOT'
  AND s.config @> '{"privacy":{"visibility":"operator_only"}}'::jsonb;
```

## 12.4 evidences / audit logs
이 테이블은 커지기 쉬워 월별 파티셔닝 권장.

```sql
CREATE TABLE evidences_y2026m03 PARTITION OF evidences
FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');

CREATE INDEX idx_evidences_attempt_id ON evidences (attempt_id);
CREATE INDEX idx_evidences_created_at_brin ON evidences USING BRIN (created_at);
```

### 이유
- 최신 증거 조회는 `attempt_id`/`created_at` 중심
- 오래된 데이터는 파티션 detach/archive가 쉬움

## 12.5 weekly report 조회
리포트는 동적 집계보다 materialized table이 훨씬 안정적.

```sql
CREATE TABLE weekly_reports_materialized (
  week_key            TEXT NOT NULL,
  user_id             UUID NOT NULL,
  region_code         TEXT,
  percentile          NUMERIC(5,2),
  completed_clues     INTEGER NOT NULL,
  reward_points       BIGINT NOT NULL,
  reward_krw          BIGINT NOT NULL,
  top_categories      JSONB NOT NULL,
  highlight_clues     JSONB NOT NULL,
  grade               TEXT NOT NULL,
  generated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (week_key, user_id)
);

CREATE INDEX idx_weekly_reports_user_recent
  ON weekly_reports_materialized (user_id, week_key DESC);
```

조회:
```sql
SELECT *
FROM weekly_reports_materialized
WHERE user_id = $1
ORDER BY week_key DESC
LIMIT 12;
```

## 13. 랭킹 API read path
### 실시간 조회
- Top N: Redis `ZREVRANGE ... WITHSCORES`
- 내 순위: `ZREVRANK` + `ZSCORE`
- 내 주변 순위(앞뒤 5명): `ZREVRANK`로 rank 조회 후 `ZREVRANGE rank-5 rank+5`

### 확정 조회
- 주간 마감 이후: PostgreSQL `weekly_ranking_snapshots` 기준
- 보상 지급/정산: 확정 스냅샷만 사용

## 14. 추천 운영 기준
- 실시간 랭킹 보정 TTL: 14일
- Redis report hash flush 주기: 5분
- high concurrency 온라인 퀴즈는 region/global 랭킹만 실시간, clue per-question ranking은 배치 축소
- reward_krw는 PostgreSQL 원장을 기준으로만 정산

## 15. 장애 대응
- Redis 장애: 앱은 PostgreSQL snapshot fallback(최근 확정 랭킹)
- Stream consumer 장애: pending list reclaim
- Outbox relay 장애: unpublished row 기반 재시도
- 잘못된 이벤트 재처리: `REPORT_CORRECTION_APPLIED` 이벤트로 상쇄(절대 원장 직접 수정 X)