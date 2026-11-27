-- migration_v4.sql: «примерные» даты просмотра. Выполнить один раз в Supabase (SQL Editor).
-- 1) колонка-метка: true = дата выдуманная, фильм не учитывается в «Итогах года» и ленте друзей
alter table movies add column if not exists date_guess boolean not null default false;

-- 2) случайные даты (с 2018 года до даты добавления) для просмотренных без даты, с меткой.
--    ЗАМЕНИТЕ ВАША_ПОЧТА на свою. Другим пользователям запрос не нужен.
update movies
set watched_at = least(created_at::date, date '2018-01-01')
      + floor(random() * (created_at::date - least(created_at::date, date '2018-01-01') + 1))::int,
    date_guess = true
where user_id = (select id from auth.users where email = 'ВАША_ПОЧТА')
  and status = 'watched'
  and watched_at is null;
