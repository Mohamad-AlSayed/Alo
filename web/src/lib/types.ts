export type Profile = {
  id: string;
  phone: string | null;
  display_name: string;
  avatar_url: string | null;
  status: string | null;
  last_seen: string;
};

export type Conversation = {
  id: string;
  is_group: boolean;
  title: string | null;
  avatar_url: string | null;
  created_by: string | null;
  created_at: string;
};

export type Message = {
  id: string;
  conversation_id: string;
  sender_id: string;
  content: string | null;
  media_url: string | null;
  media_type: "image" | "video" | "audio" | "file" | null;
  reply_to: string | null;
  created_at: string;
  edited_at: string | null;
  deleted_at: string | null;
};
