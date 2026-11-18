"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import type { Profile } from "@/lib/types";

export default function NewConversationPage() {
  const [email, setEmail] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const supabase = createClient();

  async function start() {
    setLoading(true);
    setError(null);

    const { data: me } = await supabase.auth.getUser();
    if (!me.user) {
      setLoading(false);
      setError("لازم تسجّل دخول");
      return;
    }

    const { data: otherProfile, error: findError } = await supabase
      .rpc("find_user_by_email", { p_email: email })
      .single<Profile>();

    if (findError || !otherProfile) {
      setLoading(false);
      setError("ما لقيت حساب بهاد الإيميل");
      return;
    }

    if (otherProfile.id === me.user.id) {
      setLoading(false);
      setError("ما فيك تبدأ محادثة مع نفسك");
      return;
    }

    const { data: conversation, error: convError } = await supabase
      .from("conversations")
      .insert({ is_group: false, created_by: me.user.id })
      .select()
      .single();

    if (convError || !conversation) {
      setLoading(false);
      setError(convError?.message ?? "صار خطأ بإنشاء المحادثة");
      return;
    }

    const { error: membersError } = await supabase.from("conversation_members").insert([
      { conversation_id: conversation.id, user_id: me.user.id },
      { conversation_id: conversation.id, user_id: otherProfile.id },
    ]);

    setLoading(false);
    if (membersError) {
      setError(membersError.message);
      return;
    }

    router.push(`/chat/${conversation.id}`);
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50">
      <div className="w-full max-w-sm space-y-4 rounded-xl bg-white p-8 shadow">
        <h1 className="text-xl font-semibold text-center">محادثة جديدة</h1>

        <input
          type="email"
          placeholder="إيميل الشخص"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="w-full rounded-lg border px-4 py-2"
        />

        <button
          onClick={start}
          disabled={loading || !email}
          className="w-full rounded-lg bg-green-600 py-2 text-white disabled:opacity-50"
        >
          {loading ? "..." : "ابدأ المحادثة"}
        </button>

        {error && <p className="text-sm text-red-600">{error}</p>}
      </div>
    </div>
  );
}
