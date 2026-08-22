"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

type DailyRecord = {
  id: string;
  user_id: string;
  record_date: string;
};

type Category = {
  id: string;
  name: string;
  sort_order: number;
  is_active: boolean;
};

type Item = {
  id: string;
  category_id: string;
  name: string;
  sort_order: number;
  is_active: boolean;
};

export default function HomePage() {
  const router = useRouter();
  const supabase = useMemo(() => createClient(), []);

  const [displayName, setDisplayName] = useState("");
  const [dailyRecord, setDailyRecord] = useState<DailyRecord | null>(null);
  const [categories, setCategories] = useState<Category[]>([]);
  const [items, setItems] = useState<Item[]>([]);

  useEffect(() => {
    const loadData = async () => {
      const {
        data: { user },
      } = await supabase.auth.getUser();

      if (!user) {
        return;
      }

      const { data: profile, error: profileError } = await supabase
        .from("users")
        .select("display_name")
        .eq("id", user.id)
        .single();

      if (profileError) {
        console.error("Failed to load profile:", profileError);
        return;
      }

      setDisplayName(profile.display_name ?? "");
      
      const { data: categoryData, error: categoryError } = await supabase
        .from("categories")
        .select("id, name, sort_order, is_active")
        .eq("user_id", user.id)
        .eq("is_active", true)
        .order("sort_order", { ascending: true });

      if (categoryError) {
        console.error("Failed to load categories:", categoryError);
        return;
      }

      setCategories(categoryData ?? []);
      
      const { data: itemData, error: itemError } = await supabase
        .from("items")
        .select("id, category_id, name, sort_order, is_active")
        .eq("user_id", user.id)
        .eq("is_active", true)
        .order("sort_order", { ascending: true });

      if (itemError) {
        console.error("Failed to load items:", itemError);
        return;
      }

      setItems(itemData ?? []);

      const recordDate = new Date().toLocaleDateString("sv-SE", {
        timeZone: "Asia/Tokyo",
      });

      const { data: existingRecord, error: selectError } = await supabase
        .from("daily_records")
        .select("id, user_id, record_date")
        .eq("user_id", user.id)
        .eq("record_date", recordDate)
        .maybeSingle();

      if (selectError) {
        console.error("Failed to load daily record:", selectError);
        return;
      }

      if (existingRecord) {
        setDailyRecord(existingRecord);
        return;
      }

      const { data: createdRecord, error: insertError } = await supabase
        .from("daily_records")
        .upsert(
          {
            user_id: user.id,
            record_date: recordDate,
          },
          {
            onConflict: "user_id,record_date",
          }
        )
        .select("id, user_id, record_date")
        .single();

      if (insertError) {
        console.error("Failed to create daily record:", insertError);
        return;
      }

      setDailyRecord(createdRecord);
    };

    loadData();
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
          {displayName || "取得中..."}
        </p>

        <p className="mt-6 text-sm text-zinc-500">
          {dailyRecord
            ? `今日の記録: ${dailyRecord.record_date}`
            : "今日の記録を準備中..."}
        </p>

          <div className="mt-6 text-left">
            <p className="text-sm font-semibold text-zinc-700">カテゴリ</p>

            <div className="mt-3 space-y-4">
              {categories.map((category) => {
                const categoryItems = items.filter(
                  (item) => item.category_id === category.id
                );

                return (
                  <div key={category.id}>
                    <p className="font-semibold text-zinc-900">{category.name}</p>

                    <ul className="mt-2 space-y-2">
                      {categoryItems.map((item) => (
                        <li
                          key={item.id}
                          className="rounded-lg border border-zinc-200 px-3 py-2 text-sm text-zinc-800"
                        >
                          {item.name}
                        </li>
                      ))}
                    </ul>
                  </div>
                );
              })}
            </div>
          </div>
          
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
