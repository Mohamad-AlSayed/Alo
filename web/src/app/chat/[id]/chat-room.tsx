"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import type { Message } from "@/lib/types";

export default function ChatRoom({
  conversationId,
  title,
  initialMessages,
  currentUserId,
}: {
  conversationId: string;
  title: string;
  initialMessages: Message[];
  currentUserId: string;
}) {
  const [messages, setMessages] = useState<Message[]>(initialMessages);
  const [text, setText] = useState("");
  const bottomRef = useRef<HTMLDivElement>(null);
  const router = useRouter();
  const supabase = createClient();

  useEffect(() => {
    const channel = supabase
      .channel(`conversation:${conversationId}`)
      .on(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "messages",
          filter: `conversation_id=eq.${conversationId}`,
        },
        (payload) => {
          setMessages((prev) => [...prev, payload.new as Message]);
        },
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [conversationId, supabase]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  async function sendMessage() {
    if (!text.trim()) return;
    const content = text;
    setText("");
    await supabase.from("messages").insert({
      conversation_id: conversationId,
      sender_id: currentUserId,
      content,
    });
  }

  async function startCall(isVideo: boolean) {
    router.push(`/chat/${conversationId}/call?video=${isVideo}`);
  }

  return (
    <div className="flex h-screen flex-col bg-gray-100">
      <header className="flex items-center justify-between bg-green-600 px-4 py-3 text-white">
        <h1 className="font-semibold">{title}</h1>
        <div className="flex gap-3">
          <button onClick={() => startCall(false)} title="مكالمة صوتية">
            📞
          </button>
          <button onClick={() => startCall(true)} title="مكالمة فيديو">
            🎥
          </button>
        </div>
      </header>

      <div className="flex-1 space-y-2 overflow-y-auto p-4">
        {messages.map((m) => (
          <div
            key={m.id}
            className={`max-w-xs rounded-lg px-3 py-2 ${
              m.sender_id === currentUserId
                ? "ml-auto bg-green-200"
                : "bg-white"
            }`}
          >
            {m.content}
          </div>
        ))}
        <div ref={bottomRef} />
      </div>

      <div className="flex gap-2 border-t bg-white p-3">
        <input
          value={text}
          onChange={(e) => setText(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && sendMessage()}
          placeholder="اكتب رسالة..."
          className="flex-1 rounded-full border px-4 py-2"
        />
        <button
          onClick={sendMessage}
          className="rounded-full bg-green-600 px-4 py-2 text-white"
        >
          إرسال
        </button>
      </div>
    </div>
  );
}
