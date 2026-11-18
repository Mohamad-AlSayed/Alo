import { createClient } from "@/lib/supabase/server";
import Link from "next/link";

export default async function Home() {
  const supabase = await createClient();
  const { data: user } = await supabase.auth.getUser();

  const { data: conversations } = await supabase
    .from("conversation_members")
    .select(
      "conversation:conversations(id, is_group, title, avatar_url, created_at)",
    )
    .eq("user_id", user.user!.id);

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="flex items-center justify-between bg-green-600 px-4 py-3 text-white">
        <h1 className="text-lg font-semibold">المحادثات</h1>
        <Link href="/new" className="text-sm underline">
          محادثة جديدة
        </Link>
      </header>

      <ul className="divide-y divide-gray-200 bg-white">
        {conversations?.map((row) => {
          const c = row.conversation as unknown as {
            id: string;
            is_group: boolean;
            title: string | null;
            avatar_url: string | null;
          };
          if (!c) return null;
          return (
            <li key={c.id}>
              <Link
                href={`/chat/${c.id}`}
                className="flex items-center gap-3 px-4 py-3 hover:bg-gray-50"
              >
                <div className="h-12 w-12 flex-shrink-0 rounded-full bg-gray-300" />
                <span className="font-medium">
                  {c.title ?? (c.is_group ? "مجموعة" : "محادثة")}
                </span>
              </Link>
            </li>
          );
        })}
        {!conversations?.length && (
          <li className="px-4 py-8 text-center text-gray-400">
            لا يوجد محادثات بعد
          </li>
        )}
      </ul>
    </div>
  );
}
