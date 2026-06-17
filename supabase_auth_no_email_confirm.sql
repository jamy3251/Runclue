-- RunClue MVP용: 이메일 확인 없이 회원가입 직후 로그인 허용
-- Supabase Dashboard > SQL Editor에서 실행하세요.
-- 운영 배포 전에 이메일 인증 정책을 다시 검토해야 합니다.

-- 이미 생성된 미확인 계정을 확인 처리합니다.
update auth.users
set
  email_confirmed_at = coalesce(email_confirmed_at, now()),
  updated_at = now()
where email is not null
  and email_confirmed_at is null;

-- 이후 생성되는 이메일 계정을 자동 확인 처리합니다.
create or replace function public.auto_confirm_email()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.email is not null and new.email_confirmed_at is null then
    new.email_confirmed_at := now();
  end if;

  return new;
end;
$$;

drop trigger if exists auto_confirm_email_trigger on auth.users;
create trigger auto_confirm_email_trigger
  before insert on auth.users
  for each row
  execute function public.auto_confirm_email();
