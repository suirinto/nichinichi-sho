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

type Event = {
  id: string;
  item_id: string;
  status: string;
  happened_on: string;
  start_at: string | null;
  end_at: string | null;
  duration_minutes: number | null;
};

export default function HomePage() {
  const router = useRouter();
  const supabase = useMemo(() => createClient(), []);

  const [displayName, setDisplayName] = useState("");
  const [dailyRecord, setDailyRecord] = useState<DailyRecord | null>(null);
  const [categories, setCategories] = useState<Category[]>([]);
  const [items, setItems] = useState<Item[]>([]);
  const [events, setEvents] = useState<Event[]>([]);

  useEffect(() => {
    const loadData = async () => {
      const {
        data: { user },
      } = await supabase.auth.getUser();

      if (!user) {
        return;
      }

      const recordDate = new Date().toLocaleDateString("sv-SE", {
        timeZone: "Asia/Tokyo",
      });
      
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
      
      const { data: eventData, error: eventError } = await supabase
        .from("events")
        .select(
          "id, item_id, status, happened_on, start_at, end_at, duration_minutes"
        )
        .eq("user_id", user.id)
        .eq("happened_on", recordDate)
        .order("start_at", { ascending: true });

      if (eventError) {
        console.error("Failed to load events:", eventError);
        return;
      }

      setEvents(eventData ?? []);

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

  const handleCreateEvent = async (itemId: string) => {
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return;
    }

    const recordDate = new Date().toLocaleDateString("sv-SE", {
      timeZone: "Asia/Tokyo",
    });

    const { data: createdEvent, error } = await supabase
      .from("events")
      .insert({
        user_id: user.id,
        item_id: itemId,
        happened_on: recordDate,
        status: "scheduled",
        source: "manual",
      })
      .select(
        "id, item_id, status, happened_on, start_at, end_at, duration_minutes"
      )
      .single();

    if (error) {
      console.error("Failed to create event:", error);
      return;
    }

    setEvents((currentEvents) => [...currentEvents, createdEvent]);
    
  };

  const calculateDurationMinutes = (
    startAt: string | null,
    endAt: string | null
  ) => {
    if (!startAt || !endAt) {
      return null;
    }

    const duration = Math.round(
      (new Date(endAt).getTime() - new Date(startAt).getTime()) / 60000
    );

    return duration >= 0 ? duration : null;
  };
  
  const handleUpdateStartTime = async (
    eventId: string,
    happenedOn: string,
    time: string,
    endAt: string | null
  ) => {
    const startAt = `${happenedOn}T${time}:00+09:00`;
    const durationMinutes = calculateDurationMinutes(startAt, endAt);

    const { error } = await supabase
      .from("events")
      .update({
        start_at: startAt,
        duration_minutes: durationMinutes,
      })
      .eq("id", eventId);

    if (error) {
      console.error("Failed to update start_at:", error);
    }
  };

  const handleUpdateEndTime = async (
    eventId: string,
    happenedOn: string,
    time: string,
    startAt: string | null
  ) => {
    const endAt = `${happenedOn}T${time}:00+09:00`;
    const durationMinutes = calculateDurationMinutes(startAt, endAt);

    const { error } = await supabase
      .from("events")
      .update({
        end_at: endAt,
        duration_minutes: durationMinutes,
      })
      .eq("id", eventId);

    if (error) {
      console.error("Failed to update end_at:", error);
    }
  };
  
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
                      <li key={item.id}>
                        <button
                          type="button"
                          onClick={() => handleCreateEvent(item.id)}
                          className="w-full rounded-lg border border-zinc-200 px-3 py-2 text-left text-sm text-zinc-800 hover:bg-zinc-50"
                        >
                          {item.name}
                        </button>
                      </li>
                    ))}
                  </ul>
                </div>
              );
            })}
          </div>
        </div>
          
        <div className="mt-8 text-left">
          <p className="text-sm font-semibold text-zinc-700">
            今日のイベント
          </p>

          {events.length === 0 ? (
            <p className="mt-2 text-sm text-zinc-500">
              まだイベントはありません
            </p>
          ) : (
            <ul className="mt-3 space-y-2">
              {events.map((event) => {
                const item = items.find(
                  (item) => item.id === event.item_id
                );

                return (
                  <li
                    key={event.id}
                    className="rounded-lg border border-zinc-200 px-3 py-2 text-sm text-zinc-800"
                  >
                    {item?.name ?? "不明な項目"}

                    <div className="mt-2">
                      <label className="block text-xs text-zinc-500">
                        開始時刻
                      </label>

                      <input
                        type="time"
                        value={
                          event.start_at
                            ? new Date(event.start_at).toLocaleTimeString("ja-JP", {
                                hour: "2-digit",
                                minute: "2-digit",
                                hour12: false,
                                timeZone: "Asia/Tokyo",
                              })
                            : ""
                        }
                        onChange={(e) => {
                          const time = e.target.value;
                          const startAt = `${event.happened_on}T${time}:00+09:00`;
                          const durationMinutes = calculateDurationMinutes(
                            startAt,
                            event.end_at
                          );

                          setEvents((currentEvents) =>
                            currentEvents.map((currentEvent) =>
                              currentEvent.id === event.id
                                ? {
                                    ...currentEvent,
                                    start_at: startAt,
                                    duration_minutes: durationMinutes,
                                  }
                                : currentEvent
                            )
                          );

                          handleUpdateStartTime(
                            event.id,
                            event.happened_on,
                            time,
                            event.end_at
                          );
                        }}
                        className="mt-1 w-full rounded-md border border-zinc-300 px-2 py-1 text-sm"
                      />
                      <div className="mt-2">
                        <label className="block text-xs text-zinc-500">
                          終了時刻
                        </label>

                        <input
                          type="time"
                          value={
                            event.end_at
                              ? new Date(event.end_at).toLocaleTimeString("ja-JP", {
                                  hour: "2-digit",
                                  minute: "2-digit",
                                  hour12: false,
                                  timeZone: "Asia/Tokyo",
                                })
                              : ""
                          }
                        onChange={(e) => {
                          const time = e.target.value;
                          const endAt = `${event.happened_on}T${time}:00+09:00`;
                          const durationMinutes = calculateDurationMinutes(
                            event.start_at,
                            endAt
                          );

                          setEvents((currentEvents) =>
                            currentEvents.map((currentEvent) =>
                              currentEvent.id === event.id
                                ? {
                                    ...currentEvent,
                                    end_at: endAt,
                                    duration_minutes: durationMinutes,
                                  }
                                : currentEvent
                            )
                          );

                          handleUpdateEndTime(
                            event.id,
                            event.happened_on,
                            time,
                            event.start_at
                          );
                        }}
                          className="mt-1 w-full rounded-md border border-zinc-300 px-2 py-1 text-sm"
                        />
                      </div>
                    </div>
                        
                    <div className="mt-2">
                      <span className="block text-xs text-zinc-500">
                        実施時間
                      </span>

                      <span className="mt-1 block text-sm text-zinc-800">
                        {event.duration_minutes !== null
                          ? `${event.duration_minutes}分`
                          : "未計算"}
                      </span>
                    </div>
                        
                  </li>
                );
              })}
            </ul>
          )}
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
