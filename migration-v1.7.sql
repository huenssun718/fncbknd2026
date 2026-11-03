-- 1.7 增量更新：在 Supabase SQL Editor 執行本檔。
-- 保留舊貼文與 created_at。過去未記錄的修改時間無法還原，維持 null。
begin;
alter table public.board_posts add column if not exists updated_at timestamptz;
create or replace function public.set_board_post_times()
returns trigger language plpgsql set search_path=public,pg_temp as $$
begin
 if TG_OP = 'INSERT' then
   NEW.created_at := now();
   NEW.updated_at := NEW.created_at;
 else
   NEW.created_at := OLD.created_at;
   NEW.updated_at := now();
 end if;
 return NEW;
end $$;
drop trigger if exists board_post_times on public.board_posts;
create trigger board_post_times before insert or update on public.board_posts
for each row execute function public.set_board_post_times();
commit;
