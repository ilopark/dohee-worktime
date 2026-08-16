-- 도희의 추가근로 캘린더 — Supabase 스키마
-- Supabase 대시보드 → SQL Editor 에 통째로 붙여넣고 실행하세요.
-- 마지막 INSERT 의 이메일만 실제 계정으로 바꾸면 됩니다.
--
-- 이미 쓰고 있는 프로젝트에 얹어도 되도록 모든 이름에 dohee_ 접두어를 붙였다.
-- 기존 테이블·함수와 충돌하지 않으며, 이 앱의 정책은 dohee_work_log 에만 걸린다.

-- ─────────────────────────────────────────────────────────────
-- 1. 접속을 허용할 계정 목록
--    클라이언트에는 정책을 하나도 주지 않는다 = 브라우저에서 조회 불가.
-- ─────────────────────────────────────────────────────────────
create table if not exists public.dohee_allowed_emails (
  email text primary key
);

alter table public.dohee_allowed_emails enable row level security;

-- ─────────────────────────────────────────────────────────────
-- 2. 현재 로그인한 사람이 허용 계정인지 판정
--    security definer 라서 위 테이블의 RLS를 우회해 읽을 수 있다.
--    로그인 안 한 상태에서는 auth.jwt() 가 null 이라 자동으로 false.
-- ─────────────────────────────────────────────────────────────
create or replace function public.dohee_is_allowed()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.dohee_allowed_emails
    where lower(email) = lower(auth.jwt() ->> 'email')
  );
$$;

revoke all on function public.dohee_is_allowed() from public;
grant execute on function public.dohee_is_allowed() to anon, authenticated;

-- ─────────────────────────────────────────────────────────────
-- 3. 근무 기록 — 하루에 한 행
--    평일은 기본 8시간 근무로 보고 따로 저장하지 않는다. 여기 쌓이는 건 그 기준에서
--    벗어나는 값들뿐이다.
--
--    work_hours  : 주말·휴일에 실제로 일한 시간 (평일이면 0)
--    ot_hours    : 평일 야근 시간 (주말·휴일이면 0)
--    leave_hours : 평일 휴가 — 반반차 2 / 반차 4 / 연차 8. 총 근로시간에서 빠진다.
--    day_override: 'hol' = 평일을 휴일로 지정, 'wd' = 공휴일을 평일로 처리
-- ─────────────────────────────────────────────────────────────
create table if not exists public.dohee_work_log (
  day          date primary key,
  work_hours   numeric(4,2) not null default 0,
  ot_hours     numeric(4,2) not null default 0,
  leave_hours  numeric(4,2) not null default 0,
  memo         text         not null default '',
  day_override text,
  updated_at   timestamptz  not null default now(),
  constraint dohee_work_log_override_check
    check (day_override is null or day_override in ('hol','wd')),
  constraint dohee_work_log_hours_check
    check (work_hours  >= 0 and work_hours  <= 24
       and ot_hours    >= 0 and ot_hours    <= 24
       and leave_hours in (0, 2, 4, 8))
);

alter table public.dohee_work_log enable row level security;

-- 허용된 계정만 읽고 쓴다. 다른 구글 계정으로 로그인해도 여기서 전부 막힌다.
drop policy if exists "allowed_select" on public.dohee_work_log;
drop policy if exists "allowed_insert" on public.dohee_work_log;
drop policy if exists "allowed_update" on public.dohee_work_log;
drop policy if exists "allowed_delete" on public.dohee_work_log;

create policy "allowed_select" on public.dohee_work_log
  for select using (public.dohee_is_allowed());

create policy "allowed_insert" on public.dohee_work_log
  for insert with check (public.dohee_is_allowed());

create policy "allowed_update" on public.dohee_work_log
  for update using (public.dohee_is_allowed()) with check (public.dohee_is_allowed());

create policy "allowed_delete" on public.dohee_work_log
  for delete using (public.dohee_is_allowed());

-- ─────────────────────────────────────────────────────────────
-- 4. 와이프 구글 계정 등록 — 이 이메일만 바꿔주세요
-- ─────────────────────────────────────────────────────────────
insert into public.dohee_allowed_emails (email)
values ('WIFE_EMAIL@gmail.com')
on conflict (email) do nothing;
