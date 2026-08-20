"use client";

import { createClient } from "@/lib/supabase/client";

export default function LoginPage() {
  const supabase = createClient();
    
  const handleGoogleLogin = async () => {
    await supabase.auth.signInWithOAuth({
      provider: "google",
      options: {
        redirectTo: `${window.location.origin}/auth/callback`,
      },
    });
  };

  return (
    <main className="min-h-screen flex items-center justify-center bg-zinc-50">
      <div className="w-full max-w-sm rounded-2xl bg-white p-8 shadow">
        <h1 className="text-center text-3xl font-bold text-zinc-900">
          日々抄
        </h1>

        <p className="mt-4 text-center text-zinc-600">
          Googleアカウントでログインしてください
        </p>

        <button
          type="button"
          onClick={handleGoogleLogin}
          className="mt-8 w-full rounded-lg border border-zinc-300 bg-white px-4 py-3 font-medium text-zinc-800 hover:bg-zinc-50"
        >
          Googleでログイン
        </button>
      </div>
    </main>
  );
}
