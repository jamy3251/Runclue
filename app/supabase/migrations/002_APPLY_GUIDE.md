# 002 마이그레이션 적용 가이드

## 무엇이 문제인가

`001_initial_schema.sql`에서 **`rewards`** 와 **`notifications`** 테이블에 INSERT RLS 정책이 빠져 있어요. RLS가 켜진 상태에서 INSERT 정책이 없으면 모든 INSERT가 거부됩니다.

결과:
- 사용자가 클루를 완료해도 `rewards` 테이블에 행이 안 생김 → 선물함이 비어 있음
- 알림 INSERT도 거부됨

## 적용 방법 (1분)

1. https://supabase.com/dashboard/project/cwhhekrtqkwaaabztmrq 접속
2. 좌측 메뉴에서 **SQL Editor** 클릭
3. **New query** 클릭
4. 아래 SQL을 통째로 붙여넣기

```sql
-- rewards: 본인 user_id로 INSERT 허용
DROP POLICY IF EXISTS "rewards_insert_own" ON rewards;
CREATE POLICY "rewards_insert_own"
  ON rewards FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- notifications: 본인 알림 INSERT/DELETE 허용
DROP POLICY IF EXISTS "notifications_insert_own" ON notifications;
CREATE POLICY "notifications_insert_own"
  ON notifications FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "notifications_delete_own" ON notifications;
CREATE POLICY "notifications_delete_own"
  ON notifications FOR DELETE
  USING (user_id = auth.uid());
```

5. **RUN** 버튼 클릭 — `Success. No rows returned` 가 뜨면 성공.

## 검증

같은 SQL Editor에서:

```sql
SELECT tablename, policyname, cmd
  FROM pg_policies
 WHERE schemaname = 'public'
   AND tablename IN ('rewards', 'notifications')
 ORDER BY tablename, cmd;
```

기대 결과 (7행):

| tablename     | policyname                | cmd    |
|---------------|---------------------------|--------|
| notifications | notifications_delete_own  | DELETE |
| notifications | notifications_insert_own  | INSERT |
| notifications | notifications_select_own  | SELECT |
| notifications | notifications_update_own  | UPDATE |
| rewards       | rewards_insert_own        | INSERT |
| rewards       | rewards_select_own        | SELECT |
| rewards       | rewards_update_own        | UPDATE |

## E2E 확인

1. 앱에서 클루 완료
2. 결과 화면에 **선물함에서 받기** 버튼 등장
3. 내정보 탭에 **선물함 (1)** 빨간 뱃지 표시
4. 선물함 진입 → 보상 카드 보임 → **받기** → 인벤토리로 이동

만약 여전히 비어있다면 Flutter 콘솔 로그에서 `[reward] _issueReward 실패` 라인을 찾아 어떤 에러인지 알려주세요.
