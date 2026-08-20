"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

export default function HomePage() {
  const router = useRouter();
  const supabase = useMemo(() => createClient(), []);
  const [email, setEmail] = useState("");

  useEffect(() => {
    const loadUser = async () => {
      const { data } = await supabase.auth.getUser();

      if (data.user) {
        setEmail(data.user.email ?? "");
      }
    };

    loadUser();
  }, [supabase]);

  const handleLogout = async () => {
    await supabase.auth.signOut();
    router.replace("/login");
  };

  return (
    <main className="min-h-screen flex items-center justify-center bg-zinc-50">
      <div className="w-full max-w-md rounded-xl bg-white p-8 text-center text-zinc-900 shadow">
        <h1 className="text-3xl font-bold">日々抄</h1>

        <p className="mt-6 text-zinc-600">ログイン中のユーザー</p>

        <p className="mt-2 break-all font-semibold text-zinc-900">
          {email || "取得中..."}
        </p>

        <button
          type="button"
          onClick={handleLogout}
          className="mt-6 rounded-lg border border-zinc-300 bg-white px-4 py-2 text-sm text-zinc-800 hover:bg-zinc-50"
        >
          ログアウト
        </button>
      </div>
    </main>
  );
}
