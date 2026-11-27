-- Supabase: SQL Editor -> New query -> вставьте весь файл -> Run
-- Добавляет профиль (имя, "обо мне", аватар, баннер) и хранилище для картинок.
-- Безопасно запускать повторно.

create table if not exists profiles (
  user_id uuid primary key default auth.uid() references auth.users on delete cascade,
  display_name text,
  bio text,
  avatar_url text,
  banner_url text,
  updated_at timestamptz default now()
);

alter table profiles enable row level security;
drop policy if exists "own profile" on profiles;
create policy "own profile" on profiles
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
grant select, insert, update, delete on table profiles to authenticated;

-- Публичная корзина для аватаров и баннеров (до 5 МБ, только картинки)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('profile-media', 'profile-media', true, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true, file_size_limit = 5242880;

-- Каждый пользователь работает только с файлами в своей папке (имя папки = его id)
drop policy if exists "pm select own" on storage.objects;
drop policy if exists "pm insert own" on storage.objects;
drop policy if exists "pm update own" on storage.objects;
drop policy if exists "pm delete own" on storage.objects;
create policy "pm select own" on storage.objects for select to authenticated
  using (bucket_id = 'profile-media' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "pm insert own" on storage.objects for insert to authenticated
  with check (bucket_id = 'profile-media' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "pm update own" on storage.objects for update to authenticated
  using (bucket_id = 'profile-media' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'profile-media' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "pm delete own" on storage.objects for delete to authenticated
  using (bucket_id = 'profile-media' and (storage.foldername(name))[1] = auth.uid()::text);
