with
  date_seq   as (select current_date + seq.num as date from generate_series(0, 30) as seq(num)),
  reg_counts as (select exam_date, count(id) as reg_count from registrations group by exam_date)
select
  date_seq.date,
  coalesce(reg_counts.reg_count, 0)                 as registration_count,
  coalesce(daily_overrides.registration_limit, 250) as daily_limit
from date_seq
left outer join reg_counts      on date_seq.date = reg_counts.exam_date
left outer join daily_overrides on date_seq.date = daily_overrides.date
/* where coalesce(reg_counts.reg_count, 0) >= coalesce(daily_overrides.registration_limit, 250) */
order by date_seq.date;

with
  date_seq   as (select current_date + seq.num as date from generate_series(0, 30) as seq(num)),
  reg_counts as (select exam_date, count(id) as reg_count from registrations group by exam_date),
  full_join  as (
    select
      date_seq.date,
      coalesce(reg_counts.reg_count, 0)                 as registration_count,
      coalesce(daily_overrides.registration_limit, 250) as daily_limit
    from date_seq
    left outer join reg_counts      on date_seq.date = reg_counts.exam_date
    left outer join daily_overrides on date_seq.date = daily_overrides.date
  )
  select date, registration_count, daily_limit, registration_count >= daily_limit as is_full from full_join
  where registration_count >= daily_limit
  order by date;
