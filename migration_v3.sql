-- migration_v3.sql: прогресс сериалов и совместный выбор фильма с другом. Выполнить один раз в Supabase (SQL Editor).
alter table movies add column if not exists season int;
alter table movies add column if not exists episode int;

create table if not exists pair_votes (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  friend_id uuid not null,
  mkey text not null,
  vote smallint not null,
  created_at timestamptz default now(),
  primary key (user_id, friend_id, mkey)
);
alter table pair_votes enable row level security;
drop policy if exists pv_sel on pair_votes;
drop policy if exists pv_ins on pair_votes;
drop policy if exists pv_upd on pair_votes;
drop policy if exists pv_del on pair_votes;
create policy pv_sel on pair_votes for select using (auth.uid() = user_id or auth.uid() = friend_id);
create policy pv_ins on pair_votes for insert with check (auth.uid() = user_id);
create policy pv_upd on pair_votes for update using (auth.uid() = user_id);
create policy pv_del on pair_votes for delete using (auth.uid() = user_id);
