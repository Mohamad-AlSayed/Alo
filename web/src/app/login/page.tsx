"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [displayName, setDisplayName] = useState("");
  const [mode, setMode] = useState<"login" | "signup">("login");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const supabase = createClient();

  async function submit() {
    setLoading(true);
    setError(null);

    if (mode === "signup") {
      const { error } = await supabase.auth.signUp({
        email,
        password,
        options: { data: { display_name: displayName || email.split("@")[0] } },
      });
      setLoading(false);
      if (error) return setError(error.message);
      window.location.href = "/";
      return;
    }

    const { error } = await supabase.auth.signInWithPassword({ email, password });
    setLoading(false);
    if (error) return setError(error.message);
    window.location.href = "/";
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50">
      <div className="w-full max-w-sm space-y-4 rounded-xl bg-white p-8 shadow">
        <h1 className="text-xl font-semibold text-center">
          {mode === "login" ? "تسجيل الدخول" : "حساب جديد"}
        </h1>

        {mode === "signup" && (
          <input
            type="text"
            placeholder="الاسم"
            value={displayName}
            onChange={(e) => setDisplayName(e.target.value)}
            className="w-full rounded-lg border px-4 py-2"
          />
        )}

        <input
          type="email"
          placeholder="البريد الإلكتروني"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="w-full rounded-lg border px-4 py-2"
        />

        <input
          type="password"
          placeholder="كلمة السر"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="w-full rounded-lg border px-4 py-2"
        />

        <button
          onClick={submit}
          disabled={loading || !email || !password}
          className="w-full rounded-lg bg-green-600 py-2 text-white disabled:opacity-50"
        >
          {loading ? "..." : mode === "login" ? "دخول" : "إنشاء حساب"}
        </button>

        <button
          onClick={() => setMode(mode === "login" ? "signup" : "login")}
          className="w-full text-center text-sm text-green-700 underline"
        >
          {mode === "login" ? "ما عندك حساب؟ أنشئ واحد" : "عندك حساب؟ سجّل دخول"}
        </button>

        {error && <p className="text-sm text-red-600">{error}</p>}
      </div>
    </div>
  );
}
