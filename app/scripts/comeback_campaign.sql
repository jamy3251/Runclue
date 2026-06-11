-- ============================================================================
-- 재초대(컴백) 캠페인 — 기존 가입자에게 웰컴백 코인 + 인앱 알림
-- ============================================================================
-- 대상: 경제 시스템(5/23) 이전에 가입해 코인을 한 번도 경험 못한 실유저.
-- 실행: 운영자가 파일럿 시작 시점에 Supabase SQL Editor에서 직접 실행.
--       (새 APK 배포와 타이밍을 맞출 것 — 알림 보고 들어왔는데 구버전이면 역효과)
--
-- 멱등: campaign_key로 coin_ledger 중복 체크 — 두 번 실행해도 1회만 지급.
-- 캠페인 키를 바꾸면 (comeback-2026-07 등) 새 캠페인으로 재사용 가능.
--
-- 지급액 100코인 근거: 배틀 최소 베팅(10)의 10판 분량 — 새 기능(베팅 대전)을
-- 충분히 체험할 수 있는 양이면서 일일 적립 캡(500)의 20%라 인플레 영향 미미.
-- ============================================================================

DO $$
DECLARE
  campaign_key text := 'comeback-2026-06';
  gift_coin    integer := 100;
  u            record;
  new_balance  integer;
  granted      integer := 0;
BEGIN
  FOR u IN
    SELECT p.id
    FROM profiles p
    JOIN auth.users au ON au.id = p.id
    WHERE au.email NOT LIKE '%@test.runclue.example'      -- 테스트 계정 제외
      AND NOT EXISTS (                                     -- 멱등: 이미 받은 사람 제외
        SELECT 1 FROM coin_ledger cl
        WHERE cl.user_id = p.id AND cl.source_id = campaign_key
      )
  LOOP
    UPDATE profiles SET coin_balance = coin_balance + gift_coin
     WHERE id = u.id
     RETURNING coin_balance INTO new_balance;

    INSERT INTO coin_ledger (user_id, delta, reason, source_id, balance_after)
    VALUES (u.id, gift_coin, 'comeback_gift', campaign_key, new_balance);

    INSERT INTO notifications (user_id, type, title, body, data)
    VALUES (
      u.id,
      'system',
      '🎁 웰컴백 선물 100코인 도착!',
      'RunClue가 게임으로 진화했어요 — 미니게임 베팅 대전, 주간 시즌 랭킹, '
      || '걸음수 코인 적립까지. 받은 100코인으로 첫 배틀에 도전해 보세요!',
      jsonb_build_object('campaign', campaign_key, 'route', '/battle')
    );

    granted := granted + 1;
  END LOOP;

  RAISE NOTICE 'comeback campaign %: % users granted % coins each',
    campaign_key, granted, gift_coin;
END $$;

-- 실행 후 확인:
-- SELECT count(*), sum(delta) FROM coin_ledger WHERE source_id = 'comeback-2026-06';
-- SELECT count(*) FROM notifications WHERE data->>'campaign' = 'comeback-2026-06';
