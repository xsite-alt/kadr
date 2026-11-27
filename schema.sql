-- Supabase: SQL Editor -> New query -> вставьте весь файл -> Run
-- Также: Authentication -> Providers -> Email -> выключите "Confirm email",
-- если не хотите подтверждать почту при регистрации.

create table if not exists movies (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  tmdb_id int not null,
  title text not null,
  year text,
  poster text,
  tmdb_rating numeric,
  runtime int,
  genres text,
  status text not null check (status in ('watched','watchlist')),
  my_rating int check (my_rating between 1 and 10),
  note text,
  created_at timestamptz default now(),
  unique (user_id, tmdb_id)
);

alter table movies enable row level security;

-- Каждый видит и меняет только свои строки
create policy "own movies" on movies
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Доступ через API для вошедших пользователей
-- (нужен, потому что при создании проекта выключено "Grant API access to new tables automatically")
grant select, insert, update, delete on table movies to authenticated;

-- ===== Профиль, аватар и баннер (24.11.2026) =====

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
