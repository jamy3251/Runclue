-- ============================================================================
-- 034 · handle_new_user — 가입 metadata 닉네임 반영
-- ============================================================================
-- 버그: 이메일 회원가입 시 signUp(data: {'nickname': ...})으로 닉네임을 보내지만
-- 트리거가 무시하고 무조건 'guest_xxxxxx'를 저장 → 사용자가 입력한 닉네임 증발.
--
-- 수정: raw_user_meta_data->>'nickname'이 있으면 사용 (공백/빈문자열 방어),
-- 없으면 (소셜/익명 로그인) 기존 guest_ 패턴 유지 → 앱이 첫 로그인 시
-- 닉네임 설정 화면으로 안내.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
begin
  insert into public.profiles (id, nickname)
  values (
    new.id,
    coalesce(
      nullif(trim(new.raw_user_meta_data->>'nickname'), ''),
      'guest_' || substr(new.id::text, 1, 6)
    )
  )
  on conflict (id) do nothing;
  return new;
end;
$function$;
