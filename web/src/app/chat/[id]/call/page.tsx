"use client";

import "@livekit/components-styles";
import {
  LiveKitRoom,
  VideoConference,
} from "@livekit/components-react";
import { useEffect, useState } from "react";
import { useParams, useSearchParams, useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

export default function CallPage() {
  const params = useParams<{ id: string }>();
  const searchParams = useSearchParams();
  const router = useRouter();
  const isVideo = searchParams.get("video") === "true";
  const [token, setToken] = useState<string | null>(null);
  const roomName = `conv-${params.id}`;

  useEffect(() => {
    (async () => {
      const supabase = createClient();
      const { data } = await supabase.auth.getSession();
      const res = await fetch("/api/livekit-token", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${data.session?.access_token}`,
        },
        body: JSON.stringify({ roomName }),
      });
      const json = await res.json();
      setToken(json.token);
    })();
  }, [roomName]);

  if (!token) {
    return (
      <div className="flex h-screen items-center justify-center bg-black text-white">
        جارِ الاتصال...
      </div>
    );
  }

  return (
    <LiveKitRoom
      token={token}
      serverUrl={process.env.NEXT_PUBLIC_LIVEKIT_URL}
      video={isVideo}
      audio
      onDisconnected={() => router.back()}
      style={{ height: "100vh" }}
    >
      <VideoConference />
    </LiveKitRoom>
  );
}
