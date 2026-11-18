import { createClient } from "@/lib/supabase/server";
import ChatRoom from "./chat-room";

export default async function ChatPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createClient();

  const { data: user } = await supabase.auth.getUser();
  const { data: conversation } = await supabase
    .from("conversations")
    .select("id, is_group, title")
    .eq("id", id)
    .single();

  const { data: messages } = await supabase
    .from("messages")
    .select("*")
    .eq("conversation_id", id)
    .order("created_at", { ascending: true });

  return (
    <ChatRoom
      conversationId={id}
      title={conversation?.title ?? (conversation?.is_group ? "مجموعة" : "محادثة")}
      initialMessages={messages ?? []}
      currentUserId={user.user!.id}
    />
  );
}
