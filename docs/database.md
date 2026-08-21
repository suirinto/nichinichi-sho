# Database Guide

## 基本方針

-   Dashboardだけ変更して終わらせない
-   migrationを必ずGit管理する
-   RLSを利用する

## DashboardでDB変更した場合

### 1. ローカルSupabase起動

``` bash
npx supabase start
```

### 2. リモート変更をmigration化

``` bash
npx supabase db pull
```

### 3. migration内容確認

``` bash
cat supabase/migrations/<migration>.sql
```

確認事項 - RLS - Policy - Trigger - Function - 不要な差分がないこと

### 4. Git反映

``` bash
git add .
git commit
git push
```

## よく使うコマンド

``` bash
npx supabase start
npx supabase stop
npx supabase db pull
npx supabase db diff
```

## 現在の運用

-   auth.users → public.users はTriggerで同期
-   usersテーブルはRLS有効
-   Policy: Users can read own profile
