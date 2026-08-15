-- 도희의 추가근로 캘린더 — Supabase 스키마
-- Supabase 대시보드 → SQL Editor 에 통째로 붙여넣고 실행하세요.
-- 마지막 INSERT 의 이메일만 실제 계정으로 바꾸면 됩니다.

-- ─────────────────────────────────────────────────────────────
-- 1. 접속을 허용할 계정 목록
--    클라이언트에는 정책을 하나도 주지 않는다 = 브라우저에서 조회 불가.
-- ─────────────────────────────────────────────────────────────
create table if not exists public.allowed_emails (
  email text primary key
);

alter table public.allowed_emails enable row level security;

-- ─────────────────────────────────────────────────────────────
-- 2. 현재 로그인한 사람이 허용 계정인지 판정
--    security definer 라서 위 테이블의 RLS를 우회해 읽을 수 있다.
--    로그인 안 한 상태에서는 auth.jwt() 가 null 이라 자동으로 false.
-- ─────────────────────────────────────────────────────────────
create or replace function public.is_allowed()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.allowed_emails
    where lower(email) = lower(auth.jwt() ->> 'email')
  );
$$;

revoke all on function public.is_allowed() from public;
grant execute on function public.is_allowed() to anon, authenticated;

-- ─────────────────────────────────────────────────────────────
-- 3. 근무 기록 — 하루에 한 행
--    work_hours : 주말·휴일에 실제로 일한 시간
--    ot_hours   : 야근 시간 (휴일이면 work_hours 에 포함된 값)
--    day_override : 'hol' = 평일을 휴일로 지정, 'wd' = 공휴일을 평일로 처리
-- ─────────────────────────────────────────────────────────────
create table if not exists public.work_log (
  day          date primary key,
  work_hours   numeric(4,2) not null default 0,
  ot_hours     numeric(4,2) not null default 0,
  memo         text         not null default '',
  day_override text,
  updated_at   timestamptz  not null default now(),
  constraint work_log_override_check
    check (day_override is null or day_override in ('hol','wd')),
  constraint work_log_hours_check
    check (work_hours >= 0 and work_hours <= 24 and ot_hours >= 0 and ot_hours <= 24)
);

alter table public.work_log enable row level security;

-- 허용된 계정만 읽고 쓴다. 다른 구글 계정으로 로그인해도 여기서 전부 막힌다.
drop policy if exists "allowed_select" on public.work_log;
drop policy if exists "allowed_insert" on public.work_log;
drop policy if exists "allowed_update" on public.work_log;
drop policy if exists "allowed_delete" on public.work_log;

create policy "allowed_select" on public.work_log
  for select using (public.is_allowed());

create policy "allowed_insert" on public.work_log
  for insert with check (public.is_allowed());

create policy "allowed_update" on public.work_log
  for update using (public.is_allowed()) with check (public.is_allowed());

create policy "allowed_delete" on public.work_log
  for delete using (public.is_allowed());

-- ─────────────────────────────────────────────────────────────
-- 4. 와이프 구글 계정 등록 — 이 이메일만 바꿔주세요
-- ─────────────────────────────────────────────────────────────
insert into public.allowed_emails (email)
values ('WIFE_EMAIL@gmail.com')
on conflict (email) do nothing;
