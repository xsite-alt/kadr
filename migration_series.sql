-- Supabase: SQL Editor -> New query -> вставьте весь файл -> Run
-- Добавляет поддержку сериалов: тип записи (фильм или сериал).
-- Нужно, потому что у фильма и сериала в TMDB номера могут совпадать.
-- Безопасно запускать повторно. ВЫПОЛНИТЕ ДО ИМПОРТА И ДО ЗАГРУЗКИ НОВОГО index.html.

alter table movies add column if not exists media_type text not null default 'movie';
alter table movies drop constraint if exists movies_media_type_check;
alter table movies add constraint movies_media_type_check check (media_type in ('movie','tv'));

-- Уникальность теперь по тройке: пользователь + номер TMDB + тип
alter table movies drop constraint if exists movies_user_id_tmdb_id_key;
alter table movies drop constraint if exists movies_user_tmdb_type_key;
alter table movies add constraint movies_user_tmdb_type_key unique (user_id, tmdb_id, media_type);
