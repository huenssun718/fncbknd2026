-- v2：免註冊發布，獨立新表，不改動舊版 posts。
create extension if not exists pgcrypto with schema extensions;
create table public.board_posts (
 id uuid primary key,
 title text not null check(length(title) between 1 and 60),
 nickname text not null check(length(nickname) between 1 and 30),
 type text not null check(type in ('交換','領取')),
 band text not null check(band in ('FTISLAND','CNBLUE','N.Flying','Hi-Fi Un!corn','AxMxP')),
 benefit text not null,
 wanted_band text not null default '', wanted_benefit text not null default '', wanted_day text not null default '',
 days text[] not null check(cardinality(days) between 1 and 2 and days <@ array['11/7','11/8']::text[]),
 location text not null check(length(location) between 1 and 150),
 description text not null check(length(description) between 1 and 1000),
 contact text not null check(contact ~ '^https?://'),
 image text not null default '' check(image='' or image ~ '^https?://'),
 status text not null,
 created_at timestamptz not null default now(),
 check((type='交換' and benefit in ('HI-TOUCH（擊掌）','SIGNED POSTER（簽名海報）','SPECIAL POLAROID（特別拍立得）','GROUP PHOTO（團體合照）') and wanted_benefit in ('HI-TOUCH（擊掌）','SIGNED POSTER（簽名海報）','SPECIAL POLAROID（特別拍立得）','GROUP PHOTO（團體合照）') and wanted_band in ('任一團體','FTISLAND','CNBLUE','N.Flying','Hi-Fi Un!corn','AxMxP') and wanted_day in ('兩天皆可','11/7','11/8') and status in ('交換中','已完成')) or (type='領取' and benefit='粉絲自製應援物' and status in ('準備中','發放中','暫停','已發完')))
);
create table public.board_keys (post_id uuid primary key references public.board_posts(id) on delete cascade, token_hash text not null);
alter table public.board_posts enable row level security;
alter table public.board_keys enable row level security;
revoke all on public.board_posts, public.board_keys from anon, authenticated;
grant select on public.board_posts to anon, authenticated;
create policy "public board read" on public.board_posts for select using(true);
-- 私人金鑰僅儲存雜湊，不隨公開列表傳送。不提供直接新增、修改、刪除權限。
create function public.create_board_post(post_id uuid,manage_token text,payload jsonb) returns void language plpgsql security definer set search_path=public,extensions,pg_temp as $$
begin
 if length(manage_token)<64 then raise exception '管理金鑰長度不足'; end if;
 insert into public.board_posts(id,title,nickname,type,band,benefit,wanted_band,wanted_benefit,wanted_day,days,location,description,contact,image,status)
 values(post_id,payload->>'title',payload->>'nickname',payload->>'type',payload->>'band',payload->>'benefit',coalesce(payload->>'wanted_band',''),coalesce(payload->>'wanted_benefit',''),coalesce(payload->>'wanted_day',''),array(select jsonb_array_elements_text(payload->'days')),payload->>'location',payload->>'description',payload->>'contact',coalesce(payload->>'image',''),payload->>'status');
 insert into public.board_keys values(post_id,encode(digest(manage_token,'sha256'),'hex'));
end $$;
create function public.manage_board_post(post_id uuid,manage_token text,payload jsonb) returns void language plpgsql security definer set search_path=public,extensions,pg_temp as $$
begin
 if not exists(select 1 from public.board_keys k where k.post_id=manage_board_post.post_id and k.token_hash=encode(digest(manage_token,'sha256'),'hex')) then raise exception '管理連結無效'; end if;
 if payload is null then delete from public.board_posts where id=post_id; return; end if;
 update public.board_posts set title=payload->>'title',nickname=payload->>'nickname',band=payload->>'band',benefit=payload->>'benefit',wanted_band=coalesce(payload->>'wanted_band',''),wanted_benefit=coalesce(payload->>'wanted_benefit',''),wanted_day=coalesce(payload->>'wanted_day',''),days=array(select jsonb_array_elements_text(payload->'days')),location=payload->>'location',description=payload->>'description',contact=payload->>'contact',image=coalesce(payload->>'image',''),status=payload->>'status' where id=post_id;
end $$;
revoke all on function public.create_board_post(uuid,text,jsonb),public.manage_board_post(uuid,text,jsonb) from public;
grant execute on function public.create_board_post(uuid,text,jsonb),public.manage_board_post(uuid,text,jsonb) to anon,authenticated;
