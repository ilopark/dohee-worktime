-- 휴가(연차·반차·반반차) 기록을 위한 컬럼 추가
-- 이미 dohee_work_log 를 만들어 둔 프로젝트에서 한 번만 실행하세요.
-- SQL Editor 에 통째로 붙여넣고 Run 하면 됩니다.
--
-- 새로 설치하는 경우엔 이 파일이 필요 없습니다. schema.sql 에 이미 반영돼 있습니다.

alter table public.dohee_work_log
  add column if not exists leave_hours numeric(4,2) not null default 0;

-- 시간 범위 제약을 휴가까지 포함하도록 다시 건다.
-- leave_hours 는 임의의 값이 아니라 반반차(2) / 반차(4) / 연차(8) 셋 중 하나다.
alter table public.dohee_work_log
  drop constraint if exists dohee_work_log_hours_check;

alter table public.dohee_work_log
  add constraint dohee_work_log_hours_check
    check (work_hours  >= 0 and work_hours  <= 24
       and ot_hours    >= 0 and ot_hours    <= 24
       and leave_hours in (0, 2, 4, 8));
