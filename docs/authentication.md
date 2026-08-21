# Authentication Guide

## 構成

-   Google OAuth
-   Supabase Auth
-   SSR
-   Cookie Session

## ユーザー同期

auth.users作成時にTriggerでpublic.usersを生成する。

## display_name

現在はGoogleプロフィールを利用。
正式版では初回ログイン時にユーザー自身が設定する予定。
