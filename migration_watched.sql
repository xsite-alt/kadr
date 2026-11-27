-- Supabase: SQL Editor -> New query -> вставьте весь файл -> Run
-- Добавляет дату просмотра (для «Итогов года» и правильного порядка в списках).
-- Безопасно запускать повторно. ВЫПОЛНИТЕ ДО ЗАГРУЗКИ НОВОГО index.html.

alter table movies add column if not exists watched_at date;
