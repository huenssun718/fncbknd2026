-- 2.0 增量遷移：保留舊貼文、管理金鑰與時間觸發器。先備份。
begin;
alter table public.board_posts add column if not exists bands text[];
-- 回填分類不視為作者編輯：僅在此交易內暫停已啟用的時間觸發器。
do $$
declare pause_times boolean;
begin
 select exists(select 1 from pg_trigger where tgrelid='public.board_posts'::regclass and tgname='board_post_times' and tgenabled='O') into pause_times;
 if pause_times then execute 'alter table public.board_posts disable trigger board_post_times'; end if;
 update public.board_posts set bands=array[band] where bands is null;
 if pause_times then execute 'alter table public.board_posts enable trigger board_post_times'; end if;
end $$;
alter table public.board_posts alter column bands set not null;
create or replace function public.normalize_board_bands() returns trigger language plpgsql set search_path=public,pg_temp as $$
begin
 if NEW.bands is null then NEW.bands:=array[NEW.band]; end if;
 if cardinality(NEW.bands) < 1 or cardinality(NEW.bands)>5 or array_position(NEW.bands,null) is not null or not (NEW.bands <@ array['FTISLAND','CNBLUE','N.Flying','Hi-Fi Un!corn','AxMxP']::text[]) then raise exception '請選擇有效的應援團體'; end if;
 NEW.bands:=array(select distinct x from unnest(NEW.bands) x order by x);
 if NEW.type='交換' and cardinality(NEW.bands)<>1 then raise exception '福利交換限單一持有團體'; end if;
 if not (NEW.band=any(NEW.bands)) then raise exception '持有團體與勾選團體不一致'; end if;
 return NEW;
end $$;
drop trigger if exists board_bands_normalize on public.board_posts;
create trigger board_bands_normalize before insert or update on public.board_posts for each row execute function public.normalize_board_bands();
create index if not exists board_posts_bands_gin on public.board_posts using gin(bands);
create or replace function public.create_board_post(post_id uuid,manage_token text,payload jsonb) returns void language plpgsql security definer set search_path=public,extensions,pg_temp as $$
begin
 if length(manage_token)<64 then raise exception '管理金鑰長度不足'; end if;
 insert into public.board_posts(id,title,nickname,type,band,bands,benefit,wanted_band,wanted_benefit,wanted_day,days,location,description,contact,image,status)
 values(post_id,payload->>'title',payload->>'nickname',payload->>'type',payload->>'band',case when jsonb_typeof(payload->'bands')='array' then array(select jsonb_array_elements_text(payload->'bands')) else array[payload->>'band'] end,payload->>'benefit',coalesce(payload->>'wanted_band',''),coalesce(payload->>'wanted_benefit',''),coalesce(payload->>'wanted_day',''),array(select jsonb_array_elements_text(payload->'days')),payload->>'location',payload->>'description',payload->>'contact',coalesce(payload->>'image',''),payload->>'status');
 insert into public.board_keys values(post_id,encode(digest(manage_token,'sha256'),'hex'));
end $$;
create or replace function public.manage_board_post(post_id uuid,manage_token text,payload jsonb) returns void language plpgsql security definer set search_path=public,extensions,pg_temp as $$
begin
 if not exists(select 1 from public.board_keys k where k.post_id=manage_board_post.post_id and k.token_hash=encode(digest(manage_token,'sha256'),'hex')) then raise exception '管理連結無效'; end if;
 if payload is null then delete from public.board_posts where id=post_id; return; end if;
 update public.board_posts set title=payload->>'title',nickname=payload->>'nickname',band=payload->>'band',bands=case when jsonb_typeof(payload->'bands')='array' then array(select jsonb_array_elements_text(payload->'bands')) when band=payload->>'band' then bands else array[payload->>'band'] end,benefit=payload->>'benefit',wanted_band=coalesce(payload->>'wanted_band',''),wanted_benefit=coalesce(payload->>'wanted_benefit',''),wanted_day=coalesce(payload->>'wanted_day',''),days=array(select jsonb_array_elements_text(payload->'days')),location=payload->>'location',description=payload->>'description',contact=payload->>'contact',image=coalesce(payload->>'image',''),status=payload->>'status' where id=post_id;
end $$;
revoke all on function public.create_board_post(uuid,text,jsonb),public.manage_board_post(uuid,text,jsonb) from public;
grant execute on function public.create_board_post(uuid,text,jsonb),public.manage_board_post(uuid,text,jsonb) to anon,authenticated;

commit;
