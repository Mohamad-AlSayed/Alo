-- Users profile table (mirrors auth.users)
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  phone text unique,
  display_name text not null,
  avatar_url text,
  status text default 'Hey there! I am using WhatsApp Clone',
  last_seen timestamptz default now(),
  created_at timestamptz default now()
);

-- Conversations: either 1-1 or group
create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  is_group boolean not null default false,
  title text,
  avatar_url text,
  created_by uuid references public.profiles(id),
  created_at timestamptz default now()
);

-- Members of a conversation
create table public.conversation_members (
  conversation_id uuid references public.conversations(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  role text not null default 'member', -- 'owner' | 'admin' | 'member'
  joined_at timestamptz default now(),
  last_read_at timestamptz default now(),
  primary key (conversation_id, user_id)
);

-- Messages
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid references public.conversations(id) on delete cascade,
  sender_id uuid references public.profiles(id),
  content text,
  media_url text,
  media_type text, -- 'image' | 'video' | 'audio' | 'file' | null
  reply_to uuid references public.messages(id),
  created_at timestamptz default now(),
  edited_at timestamptz,
  deleted_at timestamptz
);

-- Message delivery/read receipts
create table public.message_receipts (
  message_id uuid references public.messages(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  delivered_at timestamptz,
  read_at timestamptz,
  primary key (message_id, user_id)
);

-- Calls (voice/video via LiveKit) metadata
create table public.calls (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid references public.conversations(id) on delete cascade,
  room_name text not null,
  started_by uuid references public.profiles(id),
  is_video boolean not null default false,
  started_at timestamptz default now(),
  ended_at timestamptz
);

create table public.call_participants (
  call_id uuid references public.calls(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  joined_at timestamptz default now(),
  left_at timestamptz,
  primary key (call_id, user_id)
);

-- Indexes
create index on public.messages (conversation_id, created_at desc);
create index on public.conversation_members (user_id);

-- Row Level Security
alter table public.profiles enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.message_receipts enable row level security;
alter table public.calls enable row level security;
alter table public.call_participants enable row level security;

-- Helper: is user a member of conversation
create or replace function public.is_conversation_member(conv_id uuid)
returns boolean language sql security definer stable as $$
  select exists (
    select 1 from public.conversation_members
    where conversation_id = conv_id and user_id = auth.uid()
  );
$$;

-- profiles: everyone authenticated can read, only owner can update
create policy "profiles_select_all" on public.profiles for select using (auth.uid() is not null);
create policy "profiles_update_own" on public.profiles for update using (id = auth.uid());
create policy "profiles_insert_own" on public.profiles for insert with check (id = auth.uid());

-- conversations: only members can see/update
create policy "conversations_select_member" on public.conversations for select using (public.is_conversation_member(id));
create policy "conversations_insert_auth" on public.conversations for insert with check (auth.uid() is not null);
create policy "conversations_update_member" on public.conversations for update using (public.is_conversation_member(id));

-- conversation_members: only members of the same conversation can see; user can insert themselves when invited (handled via function below)
create policy "members_select_member" on public.conversation_members for select using (public.is_conversation_member(conversation_id));
create policy "members_insert_self_or_owner" on public.conversation_members for insert with check (
  user_id = auth.uid() or public.is_conversation_member(conversation_id)
);
create policy "members_delete_self_or_owner" on public.conversation_members for delete using (
  user_id = auth.uid() or public.is_conversation_member(conversation_id)
);

-- messages: only members can read/write
create policy "messages_select_member" on public.messages for select using (public.is_conversation_member(conversation_id));
create policy "messages_insert_member" on public.messages for insert with check (
  public.is_conversation_member(conversation_id) and sender_id = auth.uid()
);
create policy "messages_update_own" on public.messages for update using (sender_id = auth.uid());

-- receipts: member can read/write their own receipt
create policy "receipts_select_member" on public.message_receipts for select using (
  exists (select 1 from public.messages m where m.id = message_id and public.is_conversation_member(m.conversation_id))
);
create policy "receipts_upsert_own" on public.message_receipts for insert with check (user_id = auth.uid());
create policy "receipts_update_own" on public.message_receipts for update using (user_id = auth.uid());

-- calls: only members can read/create
create policy "calls_select_member" on public.calls for select using (public.is_conversation_member(conversation_id));
create policy "calls_insert_member" on public.calls for insert with check (public.is_conversation_member(conversation_id));

create policy "call_participants_select_member" on public.call_participants for select using (
  exists (select 1 from public.calls c where c.id = call_id and public.is_conversation_member(c.conversation_id))
);
create policy "call_participants_insert_own" on public.call_participants for insert with check (user_id = auth.uid());

-- Realtime publication
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.conversation_members;
alter publication supabase_realtime add table public.calls;
