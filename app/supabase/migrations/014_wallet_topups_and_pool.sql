-- ============================================================================
-- 014 · 사장 충전 ledger + 클루 보상 풀
-- ============================================================================
-- BM: 사장이 토스 결제로 클루 보상금 충전 → 플랫폼 ~15% 수수료 차감 →
--     net이 reward_pool_net 풀에 적립. 풀에서 참여자에게 분배.
--
-- 멱등성: wallet_topups.toss_payment_key UNIQUE — 토스 webhook 재시도 안전.
--
-- 후속:
--   015 · topup_clue_pool RPC (검증된 결제 → 풀 적립 단일 호출)
--   016 · pool overspend 가드 트리거
-- ============================================================================

-- 1. wallet_topups : 사장 결제 기록
CREATE TABLE IF NOT EXISTS public.wallet_topups (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clue_id           uuid REFERENCES public.clues(id) ON DELETE SET NULL,
  user_id           uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  gross_amount      integer NOT NULL,
  fee_amount        integer NOT NULL,
  net_amount        integer NOT NULL,
  fee_rate_bps      integer NOT NULL DEFAULT 1500, -- 15.00% (basis points)
  toss_payment_key  text UNIQUE,
  toss_order_id     text UNIQUE,
  status            text NOT NULL DEFAULT 'pending',
  approved_at       timestamptz,
  raw_response      jsonb,
  created_at        timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT wallet_topups_status_check
    CHECK (status IN ('pending','approved','failed','cancelled')),
  CONSTRAINT wallet_topups_amount_check
    CHECK (gross_amount >= 0 AND fee_amount >= 0 AND net_amount >= 0
           AND gross_amount = fee_amount + net_amount)
);

CREATE INDEX IF NOT EXISTS wallet_topups_user_idx
  ON public.wallet_topups (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS wallet_topups_clue_idx
  ON public.wallet_topups (clue_id, created_at DESC);

ALTER TABLE public.wallet_topups ENABLE ROW LEVEL SECURITY;

-- 사장 본인 SELECT만 (INSERT/UPDATE는 service_role 또는 RPC 통해서)
DROP POLICY IF EXISTS "wallet_topups_owner_select" ON public.wallet_topups;
CREATE POLICY "wallet_topups_owner_select" ON public.wallet_topups
  FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS "wallet_topups_admin_all" ON public.wallet_topups;
CREATE POLICY "wallet_topups_admin_all" ON public.wallet_topups
  FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- 2. clues 풀 컬럼 (사장 충전 net 누적 + 분배 시 차감)
ALTER TABLE public.clues
  ADD COLUMN IF NOT EXISTS reward_pool_net       integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS reward_pool_committed integer NOT NULL DEFAULT 0;

ALTER TABLE public.clues DROP CONSTRAINT IF EXISTS clues_reward_pool_check;
ALTER TABLE public.clues ADD  CONSTRAINT clues_reward_pool_check
  CHECK (reward_pool_net >= 0 AND reward_pool_committed >= 0);

-- 3. 플랫폼 매출 뷰 (일별 수수료 합)
CREATE OR REPLACE VIEW public.platform_revenue_v1 AS
SELECT
  date_trunc('day', approved_at)::date AS day,
  count(*)                              AS topup_count,
  sum(gross_amount)                     AS gross_total,
  sum(fee_amount)                       AS fee_total,
  sum(net_amount)                       AS net_total
FROM public.wallet_topups
WHERE status = 'approved'
GROUP BY 1
ORDER BY 1 DESC;

GRANT SELECT ON public.platform_revenue_v1 TO authenticated;
