"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";

export default function LoginPage() {
  const [phone, setPhone] = useState("");
  const [otp, setOtp] = useState("");
  const [stage, setStage] = useState<"phone" | "otp">("phone");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const supabase = createClient();

  async function sendOtp() {
    setLoading(true);
    setError(null);
    const { error } = await supabase.auth.signInWithOtp({ phone });
    setLoading(false);
    if (error) return setError(error.message);
    setStage("otp");
  }

  async function verifyOtp() {
    setLoading(true);
    setError(null);
    const { error } = await supabase.auth.verifyOtp({
      phone,
      token: otp,
      type: "sms",
    });
    setLoading(false);
    if (error) return setError(error.message);
    window.location.href = "/";
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50">
      <div className="w-full max-w-sm space-y-4 rounded-xl bg-white p-8 shadow">
        <h1 className="text-xl font-semibold text-center">تسجيل الدخول</h1>

        {stage === "phone" ? (
          <>
            <input
              type="tel"
              placeholder="+963xxxxxxxxx"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              className="w-full rounded-lg border px-4 py-2"
            />
            <button
              onClick={sendOtp}
              disabled={loading || !phone}
              className="w-full rounded-lg bg-green-600 py-2 text-white disabled:opacity-50"
            >
              {loading ? "..." : "إرسال الرمز"}
            </button>
          </>
        ) : (
          <>
            <input
              type="text"
              placeholder="رمز التحقق"
              value={otp}
              onChange={(e) => setOtp(e.target.value)}
              className="w-full rounded-lg border px-4 py-2"
            />
            <button
              onClick={verifyOtp}
              disabled={loading || !otp}
              className="w-full rounded-lg bg-green-600 py-2 text-white disabled:opacity-50"
            >
              {loading ? "..." : "تأكيد"}
            </button>
          </>
        )}

        {error && <p className="text-sm text-red-600">{error}</p>}
      </div>
    </div>
  );
}
