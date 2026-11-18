# WhatsApp Clone — خطة التشغيل

## البنية
- `supabase/migrations/0001_init.sql` — المخطط الكامل (users, conversations, messages, groups, calls) + RLS + Realtime.
- `web/` — Next.js 16 (App Router) + Tailwind + Supabase + LiveKit. يبني بنجاح (`npm run build`).
- `ios/` — كود SwiftUI (Login OTP, قائمة محادثات, شات realtime, مكالمات LiveKit). **غير مبني** — يحتاج Xcode على macOS.

## 1) Supabase
1. أنشئ مشروع على supabase.com.
2. طبّق المخطط: `supabase db push` (أو نفّذ محتوى `supabase/migrations/0001_init.sql` من SQL editor).
3. فعّل Phone Auth (Twilio أو مزوّد SMS) من Authentication → Providers.
4. خذ `Project URL` و `anon key` من Settings → API.

## 2) LiveKit (صوت/فيديو)
1. أنشئ مشروع على livekit.io (Cloud المجاني كافي للبدء).
2. خذ `API Key`, `API Secret`, و `WebSocket URL`.

## 3) تشغيل الويب
```bash
cd web
cp .env.local.example .env.local
# عبّي القيم: NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY,
# LIVEKIT_API_KEY, LIVEKIT_API_SECRET, NEXT_PUBLIC_LIVEKIT_URL
npm install
npm run dev
```

## 4) تشغيل iOS (لازم Mac + Xcode)
1. افتح Xcode → File → New → Project → iOS App → SwiftUI، اسمه `WhatsAppClone`.
2. اسحب محتوى `ios/WhatsAppClone/` فوق مجلد المشروع الجديد في Xcode.
3. أضف Swift Package Dependencies (File → Add Package Dependencies):
   - `https://github.com/supabase/supabase-swift`
   - `https://github.com/livekit/client-sdk-swift`
   - `https://github.com/livekit/components-swift` (اختياري، لـ `VideoConferenceLayout`)
4. عدّل القيم بـ `Services/SupabaseService.swift` → `enum Secrets` (أو حوّلها لـ xcconfig).
5. شغّل على Simulator أو جهاز حقيقي.

## الحالة الحالية (MVP)
- [x] تسجيل دخول OTP عبر الهاتف (ويب + iOS).
- [x] قائمة محادثات، شات 1-1/جروب مع Realtime.
- [x] مكالمات صوت/فيديو عبر LiveKit (ويب + iOS).
- [ ] إنشاء محادثة/مجموعة جديدة من الواجهة (الجداول جاهزة، الشاشة لسا لازم تُبنى: `/new`).
- [ ] رفع الصور/الملفات (حقول `media_url/media_type` جاهزة بالـDB، الرفع لـ Supabase Storage لسا).
- [ ] إشعارات Push.
- [ ] حالة "متصل الآن" / "آخر ظهور" فعلياً (الحقل موجود، التحديث التلقائي لسا).

## خطوة تالية مقترحة
بناء شاشة "محادثة جديدة" (`web/src/app/new`) لاختيار جهة اتصال وإنشاء `conversations` + `conversation_members`.
