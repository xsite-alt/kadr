-- Supabase: SQL Editor -> New query -> вставьте весь файл -> Run
-- Друзья по коду приглашения: видят списки и оценки друг друга.
-- Безопасно запускать повторно. ВЫПОЛНИТЕ ДО ЗАГРУЗКИ НОВОГО index.html.

alter table profiles add column if not exists invite_code text;
create unique index if not exists profiles_invite_code_key on profiles (invite_code);

create table if not exists friendships (
  user_a uuid not null references auth.users on delete cascade,
  user_b uuid not null references auth.users on delete cascade,
  created_at timestamptz default now(),
  primary key (user_a, user_b),
  check (user_a < user_b)
);
alter table friendships enable row level security;
drop policy if exists "own friendships read" on friendships;
drop policy if exists "own friendships delete" on friendships;
create policy "own friendships read" on friendships for select to authenticated
  using (auth.uid() = user_a or auth.uid() = user_b);
create policy "own friendships delete" on friendships for delete to authenticated
  using (auth.uid() = user_a or auth.uid() = user_b);
grant select, delete on table friendships to authenticated;

-- Друг ли мне этот пользователь (для политик ниже)
create or replace function public.is_friend(other uuid) returns boolean
language sql security definer stable set search_path = public as $$
  select exists (select 1 from friendships
    where user_a = least(auth.uid(), other) and user_b = greatest(auth.uid(), other));
$$;

-- Друзья могут ЧИТАТЬ (но не менять) фильмы и профиль друг друга
drop policy if exists "friends read movies" on movies;
create policy "friends read movies" on movies for select to authenticated using (public.is_friend(user_id));
drop policy if exists "friends read profiles" on profiles;
create policy "friends read profiles" on profiles for select to authenticated using (public.is_friend(user_id));

-- Мой код приглашения (создаётся при первом обращении)
create or replace function public.my_invite_code() returns text
language plpgsql security definer set search_path = public as $$
declare c text;
begin
  if auth.uid() is null then raise exception 'Нужно войти'; end if;
  select invite_code into c from profiles where user_id = auth.uid();
  if c is null then
    c := upper(substr(md5(random()::text || clock_timestamp()::text || auth.uid()::text), 1, 10));
    insert into profiles (user_id, invite_code) values (auth.uid(), c)
      on conflict (user_id) do update set invite_code = excluded.invite_code;
  end if;
  return c;
end $$;

-- Добавить друга по коду (дружба взаимная)
create or replace function public.add_friend(code text) returns text
language plpgsql security definer set search_path = public as $$
declare other uuid; nm text;
begin
  if auth.uid() is null then raise exception 'Нужно войти'; end if;
  select user_id, coalesce(display_name, '') into other, nm from profiles where invite_code = upper(trim(code));
  if other is null then raise exception 'Код не найден'; end if;
  if other = auth.uid() then raise exception 'Это ваш собственный код'; end if;
  insert into friendships (user_a, user_b) values (least(auth.uid(), other), greatest(auth.uid(), other))
    on conflict do nothing;
  return nm;
end $$;

revoke all on function public.is_friend(uuid), public.my_invite_code(), public.add_friend(text) from public, anon;
grant execute on function public.is_friend(uuid), public.my_invite_code(), public.add_friend(text) to authenticated;
