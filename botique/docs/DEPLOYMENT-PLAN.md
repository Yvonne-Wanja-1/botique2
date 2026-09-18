# Queens' Touch Deployment Plan

> **Goal:** Deploy the app so it works on phones (Android APK) with a live backend and database on the internet.

**Architecture:** Supabase (free PostgreSQL database) + Railway (free backend hosting) + Flutter APK build.

**Tech Stack:** PostgreSQL (Supabase), Node.js/Express (Railway), Flutter (APK)

---

## Task 1: Create Supabase Account & Database

**What you do:**
1. Go to https://supabase.com and sign up (free)
2. Click "New Project"
3. Fill in:
   - **Project name:** `queens-touch`
   - **Database password:** Choose something strong (save it!)
   - **Region:** Closest to your users (e.g., US East, EU West)
4. Click "Create new project"
5. Wait ~2 minutes for it to set up
6. Go to **Settings** → **Database** → **Connection string** → **URI**
7. Copy the URI. It looks like:
   ```
   postgresql://postgres.xxxxx:your-password@aws-0-us-east-1.pooler.supabase.com:6543/postgres
   ```

**Save this URI** — you'll need it in Task 4.

---

## Task 2: Import Schema into Supabase

**What you do:**
1. In your Supabase project, go to the **SQL Editor** (left sidebar)
2. Click "New query"
3. Open the file `database/schema.sql` from this project
4. **Copy the entire contents** and paste it into the SQL Editor
5. Click **Run** (or press Ctrl+Enter)
6. You should see "Success. No rows returned"

**This creates all your tables, seed data, and test accounts.**

---

## Task 3: Push Backend to GitHub

**What you do:**
1. Create a new GitHub repository (name it `queens-touch-backend` or similar)
2. Make sure the backend folder is ready:

```bash
cd C:\Users\HHP\Desktop\botique\botique\backend
```

3. Create a `.gitignore` in the backend folder (if not already there):
   ```
   node_modules/
   dist/
   .env
   uploads/
   server.log
   ```

4. Initialize git and push:
```bash
cd C:\Users\HHP\Desktop\botique\botique
git init
git add backend/ database/ lib/data/api/ pubspec.yaml
git commit -m "Initial commit for deployment"
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git push -u origin main
```

**Replace** `YOUR_USERNAME` and `YOUR_REPO_NAME` with your actual GitHub details.

---

## Task 4: Deploy Backend to Railway

**What you do:**
1. Go to https://railway.app and sign up with GitHub
2. Click **"New Project"** → **"Deploy from GitHub repo"**
3. Select your repository
4. Railway will detect it's a Node.js project
5. Go to **Variables** tab and add these environment variables:

| Variable | Value |
|----------|-------|
| `DATABASE_URL` | The Supabase URI from Task 1 |
| `JWT_SECRET` | A random string (e.g., `qt-production-secret-2026-change-me`) |
| `NODE_ENV` | `production` |
| `PORT` | `3000` |

6. Railway will automatically deploy. Wait for it to build.
7. Go to **Settings** → **Networking** → **Generate Domain**
8. You'll get a URL like: `queens-touch-backend-production.up.railway.app`

**Save this URL** — you'll need it in Task 5.

**Test it:** Open `https://YOUR_RAILWAY_URL/api/health` in a browser. You should see a response.

---

## Task 5: Update Flutter App API URL

**What you do:**
1. Open `lib/data/api/api_bootstrap.dart`
2. Change line 20 from:
   ```dart
   const String kApiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000');
   ```
   To:
   ```dart
   const String kApiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://YOUR_RAILWAY_URL');
   ```

3. Replace `YOUR_RAILWAY_URL` with the actual Railway URL from Task 4.

4. **Test it:** Run the app on your phone:
   ```bash
   flutter run
   ```
   Try signing in with:
   - Email: `admin@queenstouch.com`
   - Password: `Password123!`

---

## Task 6: Build APK for Phone Distribution

**What you do:**
1. Make sure you're in the project folder:
   ```bash
   cd C:\Users\HHP\Desktop\botique\botique
   ```

2. Build the release APK:
   ```bash
   flutter build apk --release
   ```

3. The APK file will be at:
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```

4. **To send to others:**
   - Upload the APK to Google Drive, Dropbox, or a file sharing service
   - Share the link with people
   - They need to enable "Install from unknown sources" on their Android phone
   - They tap the APK to install

---

## Quick Reference

| What | Where |
|------|-------|
| Database | Supabase (free) |
| Backend | Railway (free tier) |
| APK | `build/app/outputs/flutter-apk/app-release.apk` |
| Test login | `admin@queenstouch.com` / `Password123!` |

---

## Troubleshooting

**"Cannot connect to server" on phone:**
- Check that Railway deployment is active (green status)
- Verify the API URL in `api_bootstrap.dart` is correct
- Make sure you're using HTTPS, not HTTP

**"Invalid credentials" on login:**
- The schema import might have failed. Check Supabase SQL Editor for errors.
- The seed data includes test accounts — make sure the INSERT statements ran.

**APK won't install:**
- User needs to enable "Install from unknown sources" in Android settings
- The APK might be too large — check file size
