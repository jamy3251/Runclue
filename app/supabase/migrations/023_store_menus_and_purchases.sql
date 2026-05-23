-- ============================================================================
-- 023 · 가게 커머스 메뉴 + QR 결제 (트랙 E, Step 16)
-- ============================================================================
-- 두 번째 다이아 사용처. 사용자 → 사장 직접 다이아 흐름:
--   1. 사장이 본인 가게 메뉴 등록 (store_menus, owner_id=auth.uid())
--   2. 사용자가 다이아로 결제 → qr_token 생성 + 사장 다이아 잔액 즉시 적립
--   3. 사용자가 매장 방문 시 QR 표시
--   4. 사장이 QR 스캔 → redeemed_at 표시 (재사용 차단)
--
-- 다이아 흐름:
--   buyer.diamond_balance  -= cost  (diamond_ledger 'spend_store')
--   owner.diamond_balance  += cost  (diamond_ledger 'store_revenue')
--   → 사장은 받은 다이아를 자기 클루 풀 충전 등 마케팅 재투입 가능.
--   → 운영 정산(현금 환전)은 별도 admin 흐름 (선불업 라이선스 검토 후).
--
-- escrow 회피: 결제 즉시 사장 적립. 환불은 admin이 grant_diamond/grant_diamond으로 수동.
-- ============================================================================

-- 1. store_menus — 사장 본인 메뉴 등록
CREATE TABLE IF NOT EXISTS public.store_menus (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id      uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name          text NOT NULL,
  description   text,
  price_diamond integer NOT NULL,
  image_url     text,
  active        boolean NOT NULL DEFAULT true,
  display_order integer NOT NULL DEFAULT 100,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT store_menus_price_check CHECK (price_diamond > 0)
);

CREATE INDEX IF NOT EXISTS store_menus_owner_idx
  ON public.store_menus (owner_id, display_order)
  WHERE active = true;

ALTER TABLE public.store_menus ENABLE ROW LEVEL SECURITY;

-- 활성 메뉴는 모든 로그인 사용자가 조회 가능 (가게 노출)
DROP POLICY IF EXISTS "store_menus_active_select" ON public.store_menus;
CREATE POLICY "store_menus_active_select" ON public.store_menus
  FOR SELECT TO authenticated USING (active = true OR owner_id = auth.uid());

-- 본인 메뉴만 CRUD
DROP POLICY IF EXISTS "store_menus_owner_write" ON public.store_menus;
CREATE POLICY "store_menus_owner_write" ON public.store_menus
  FOR INSERT TO authenticated WITH CHECK (owner_id = auth.uid());
DROP POLICY IF EXISTS "store_menus_owner_update" ON public.store_menus;
CREATE POLICY "store_menus_owner_update" ON public.store_menus
  FOR UPDATE TO authenticated USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());
DROP POLICY IF EXISTS "store_menus_owner_delete" ON public.store_menus;
CREATE POLICY "store_menus_owner_delete" ON public.store_menus
  FOR DELETE TO authenticated USING (owner_id = auth.uid());

DROP POLICY IF EXISTS "store_menus_admin_all" ON public.store_menus;
CREATE POLICY "store_menus_admin_all" ON public.store_menus
  FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- 2. store_purchases — 사용자 결제 + QR redemption
CREATE TABLE IF NOT EXISTS public.store_purchases (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  menu_id         uuid NOT NULL REFERENCES public.store_menus(id) ON DELETE RESTRICT,
  store_owner_id  uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  diamond_cost    integer NOT NULL,
  qr_token        text NOT NULL UNIQUE,
  redeemed_at     timestamptz,
  redeemed_by     uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  expires_at      timestamptz NOT NULL DEFAULT (now() + interval '30 days'),
  created_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT store_purchases_cost_check CHECK (diamond_cost > 0)
);

CREATE INDEX IF NOT EXISTS store_purchases_user_idx
  ON public.store_purchases (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS store_purchases_owner_idx
  ON public.store_purchases (store_owner_id, created_at DESC);

ALTER TABLE public.store_purchases ENABLE ROW LEVEL SECURITY;

-- 구매자 + 가게 사장 본인만 조회
DROP POLICY IF EXISTS "store_purchases_buyer_select" ON public.store_purchases;
CREATE POLICY "store_purchases_buyer_select" ON public.store_purchases
  FOR SELECT TO authenticated USING (user_id = auth.uid() OR store_owner_id = auth.uid());

DROP POLICY IF EXISTS "store_purchases_admin_all" ON public.store_purchases;
CREATE POLICY "store_purchases_admin_all" ON public.store_purchases
  FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- 3. purchase_store_menu RPC
-- 입력: menu_id
-- 동작: 다이아 buyer→owner 이동 + qr_token 생성
-- 반환: { ok, purchase_id, qr_token, diamond_cost, balance_after, owner_id, menu_name }
CREATE OR REPLACE FUNCTION public.purchase_store_menu(menu_id_in uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  uid          uuid := auth.uid();
  m            store_menus%ROWTYPE;
  buyer_dia    integer;
  buyer_new    integer;
  qr_v         text;
  purchase_id  uuid;
  owner_grant  jsonb;
BEGIN
  IF uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'auth_required');
  END IF;

  SELECT * INTO m FROM store_menus WHERE id = menu_id_in FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'menu_not_found');
  END IF;
  IF NOT m.active THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'menu_inactive');
  END IF;
  IF m.owner_id = uid THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'own_menu_not_purchasable');
  END IF;

  -- 구매자 잔액 확인 + 차감 (FOR UPDATE)
  SELECT diamond_balance INTO buyer_dia FROM profiles WHERE id = uid FOR UPDATE;
  IF buyer_dia IS NULL OR buyer_dia < m.price_diamond THEN
    RETURN jsonb_build_object(
      'ok', false, 'reason', 'insufficient_diamond',
      'have', COALESCE(buyer_dia, 0), 'need', m.price_diamond
    );
  END IF;

  UPDATE profiles
     SET diamond_balance = diamond_balance - m.price_diamond
   WHERE id = uid
   RETURNING diamond_balance INTO buyer_new;

  INSERT INTO diamond_ledger (user_id, delta, source, source_id, balance_after)
  VALUES (uid, -m.price_diamond, 'spend_store', m.id::text, buyer_new);

  -- 사장에게 즉시 다이아 적립 (grant_diamond 함수가 무캡)
  owner_grant := public.grant_diamond(
    m.owner_id, m.price_diamond, 'store_revenue', m.id::text
  );

  qr_v := gen_random_uuid()::text;
  INSERT INTO store_purchases
    (user_id, menu_id, store_owner_id, diamond_cost, qr_token)
  VALUES
    (uid, m.id, m.owner_id, m.price_diamond, qr_v)
  RETURNING id INTO purchase_id;

  RETURN jsonb_build_object(
    'ok', true,
    'purchase_id', purchase_id,
    'qr_token', qr_v,
    'diamond_cost', m.price_diamond,
    'balance_after', buyer_new,
    'owner_id', m.owner_id,
    'menu_name', m.name,
    'owner_grant', owner_grant
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.purchase_store_menu(uuid) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.purchase_store_menu(uuid) TO authenticated;

-- 4. redeem_store_purchase RPC — 사장이 QR 스캔
-- 입력: qr_token
-- 동작: 구매 row 조회 + 호출자가 가게 사장인지 검증 + redeemed_at 갱신
-- 반환: { ok, purchase_id, menu_name, buyer_id, redeemed_at }
CREATE OR REPLACE FUNCTION public.redeem_store_purchase(qr_token_in text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  uid uuid := auth.uid();
  p   store_purchases%ROWTYPE;
  m   store_menus%ROWTYPE;
BEGIN
  IF uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'auth_required');
  END IF;
  IF qr_token_in IS NULL OR length(trim(qr_token_in)) = 0 THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'qr_required');
  END IF;

  SELECT * INTO p FROM store_purchases WHERE qr_token = qr_token_in FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'qr_not_found');
  END IF;
  IF p.store_owner_id <> uid THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'not_owner');
  END IF;
  IF p.redeemed_at IS NOT NULL THEN
    RETURN jsonb_build_object(
      'ok', false, 'reason', 'already_redeemed',
      'redeemed_at', p.redeemed_at
    );
  END IF;
  IF p.expires_at < now() THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'expired',
                              'expires_at', p.expires_at);
  END IF;

  UPDATE store_purchases
     SET redeemed_at = now(),
         redeemed_by = uid
   WHERE id = p.id;

  SELECT * INTO m FROM store_menus WHERE id = p.menu_id;

  RETURN jsonb_build_object(
    'ok', true,
    'purchase_id', p.id,
    'menu_name', m.name,
    'menu_image', m.image_url,
    'buyer_id', p.user_id,
    'diamond_cost', p.diamond_cost,
    'redeemed_at', now()
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.redeem_store_purchase(text) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.redeem_store_purchase(text) TO authenticated;
