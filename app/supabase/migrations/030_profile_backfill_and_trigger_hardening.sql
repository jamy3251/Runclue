-- 030: 프로필 누락 backfill + handle_new_user 트리거 강화
--
-- 문제: handle_new_user 트리거 생성 이전에 가입한 계정(예: 최초 운영자 계정)은
-- profiles 행이 없어 모든 재화 RPC(grant_coin 등)가 'insufficient_balance'로 실패한다.
-- (grant_coin의 UPDATE profiles가 0행에 적용 → new_balance NULL)
--
-- 조치:
-- 1) profiles 누락 사용자 backfill
-- 2) handle_new_user에 ON CONFLICT DO NOTHING + search_path 고정 (재발 방지 + 보안 권고)

-- 1) backfill — 트리거 이전 가입자
INSERT INTO public.profiles (id, nickname)
SELECT u.id, 'guest_' || substr(u.id::text, 1, 6)
FROM auth.users u
WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id)
ON CONFLICT (id) DO NOTHING;

-- 2) 트리거 강화 — 중복 시 가입 실패 방지 + search_path 고정
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
begin
  insert into public.profiles (id, nickname)
  values (new.id, 'guest_' || substr(new.id::text, 1, 6))
  on conflict (id) do nothing;
  return new;
end;
$function$;
