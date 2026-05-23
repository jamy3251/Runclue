-- ============================================================================
-- 017 · 풀 과도 지출 가드 트리거
-- ============================================================================
-- participations.total_points_earned가 0/NULL → 양수로 설정될 때,
-- 해당 clue의 reward_pool_committed에 누적 + reward_pool_net 초과 시 거부.
--
-- 구버전 호환: reward_pool_net = 0인 클루는 풀 없는 (수수료 모델 적용 전) →
--              가드 통과시키되 committed도 갱신 안 함.
--
-- 가드 위반 시 EXCEPTION → 트랜잭션 롤백 → 사용자는 보상 미발급 상태 유지
-- (운영 디버깅: clues.reward_pool_net 부족 → 사장에게 추가 충전 안내).
-- ============================================================================

CREATE OR REPLACE FUNCTION public.tg_participation_commit_pool()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  delta_v        integer;
  pool_net_v     integer;
  pool_commit_v  integer;
BEGIN
  -- 첫 보상 산정 시점 (0/NULL → 양수)
  IF (COALESCE(OLD.total_points_earned, 0) = 0)
     AND COALESCE(NEW.total_points_earned, 0) > 0 THEN
    delta_v := NEW.total_points_earned;

    SELECT reward_pool_net, reward_pool_committed
      INTO pool_net_v, pool_commit_v
      FROM clues WHERE id = NEW.clue_id FOR UPDATE;

    -- 풀이 적용된 신규 클루만 가드 + committed 갱신
    IF pool_net_v IS NOT NULL AND pool_net_v > 0 THEN
      IF pool_commit_v + delta_v > pool_net_v THEN
        RAISE EXCEPTION
          'pool_overspend: committed % + delta % > net % (clue=%)',
          pool_commit_v, delta_v, pool_net_v, NEW.clue_id;
      END IF;
      UPDATE clues
         SET reward_pool_committed = reward_pool_committed + delta_v
       WHERE id = NEW.clue_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS participation_commit_pool ON public.participations;
CREATE TRIGGER participation_commit_pool
  BEFORE UPDATE OF total_points_earned ON public.participations
  FOR EACH ROW EXECUTE FUNCTION public.tg_participation_commit_pool();
