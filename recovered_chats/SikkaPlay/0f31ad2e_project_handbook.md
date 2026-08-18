# SikkaPlay Project Handbook 🎮📱

Welcome to the **SikkaPlay** project handbook. This document serves as a comprehensive reference guide summarizing the architecture, tech stack, database structure, features, configurations, and deployment guidelines for future developers and AI assistants.

---

## 🛠️ Technology Stack

SikkaPlay is built as a three-tier system comprising a mobile application, a backend API service, and a web admin panel.

### 1. Mobile Application (Frontend)
*   **Framework:** Flutter (Dart) - Cross-platform (supports Android & iOS).
*   **Authentication:** Firebase Auth & Google Sign-In integration.
*   **Notifications:** Firebase Cloud Messaging (FCM) via `firebase_messaging`.
*   **Real-time Communication:** `socket_io_client` for matchmaking and playground chat.
*   **State & Services:** Custom API services powered by `http` and `shared_preferences`.

### 2. Admin Panel (Web Portal)
*   **Framework:** React 19 + TypeScript.
*   **Bundler/Build Tool:** Vite + TailwindCSS style variables.
*   **Charts:** Recharts for financial and ad performance analytics.
*   **API Client:** Axios (with automatic localhost/Cloud Run detection).
*   **Hosting:** Firebase Hosting (`https://sikkaplay-admin.web.app`).

### 3. Backend API Service (Backend)
*   **Runtime:** Node.js (TypeScript).
*   **Framework:** Express.js (for REST APIs) + Socket.io (for WebSocket servers).
*   **ORM:** Prisma Client.
*   **Database:** Supabase PostgreSQL.
*   **Cache/Queue Fallback:** Redis (via `ioredis`) for matchmaking room states, with a built-in automated **in-memory Map/Queue fallback** (`memoryStore`) for Redis-free serverless deployments like Google Cloud Run.
*   **Hosting:** Google Cloud Run (`https://sikkaplay-backend-834810172223.asia-south1.run.app`).

---

## 💾 Data Storage & Databases

*   **Primary Database:** **PostgreSQL** hosted on Supabase.
    *   *Connection Pooler Port (6543):* Used in production (Prisma transactions).
    *   *Direct Connection Port (5432):* Used for structural schema changes (migrations).
*   **Matchmaking State:** Redis (in production) or Local Node.js Memory Fallback (in development/local testing). Keeps track of active rooms, online matchmaking statuses, and current room keys.

---

## 🚀 Core Application Features

### 1. Earning Engine
*   **Daily Streaks:** An interactive 28-day daily checking calendar.
    *   *Continuous Cycle:* Streaks continue past Day 28, awarding a flat **200 coins** daily as long as the user doesn't miss a day. If a day is missed, it resets to Day 1.
*   **Gullak Chest:** A coin-earning vault with customizable Ad sequences (e.g., *interstitial, rewarded, none*).
*   **Task System:** Includes Watch tasks (time-based video milestones), Play tasks (gaming playtime), Daily Codes, and Visit Links tasks.
*   **MLM Referral Network:** Direct MLM commission system distributing a percentage of referrals' earnings.

### 2. Playground Matchmaking & Chat
*   **Matchmaking Queue:** Gender-filtered random matchmaking with lobby profile checks.
*   **Playground Studio Chat:** Socket.io powered real-time chat supporting:
    *   *Real-time Exit notices:* Instantly removes the typing box for the remaining user and displays `"{Name} left this chat"` in a red banner and as a system badge.
    *   *Exit Confirmation:* A confirmation dialog (`Leave Chat?`) pops up if a user attempts to leave an active chat room by pressing back.
    *   *Gifts system:* Inline coin-based gifting.
    *   *Tic-Tac-Toe:* An interactive mini-game inside the chat room with automatic forfeit handling if one user leaves mid-game.

### 3. User & Profiles
*   **Auto-Username Generation:** Google registrants automatically get a random username (e.g., `Sikka_User_xxxx`) upon entry to ensure complete profile parameters for matchmaking.
*   **Profile Editing:** Users can modify their Display Name, Username, Bio, and Gender.
*   **Soft Account Deletion:** Clears sensitive personal logs (phone, deviceId, Firebase UID, avatar) and updates profile `name` to `'Deleted User'` while maintaining database integrity for MLM network trees.

---

## 🔑 Crucial Environments & Credentials

### 1. Backend Environment Variables (`.env`)
```properties
PORT=3000
DATABASE_URL="postgresql://postgres.ehvrlqdqdgfqjfstjncd:[PASSWORD]@aws-1-ap-south-1.pooler.supabase.com:6543/postgres?pgbouncer=true"
DIRECT_URL="postgresql://postgres.ehvrlqdqdgfqjfstjncd:[PASSWORD]@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"
JWT_SECRET="super-secret-sikkaplay-key"
REDIS_URL="redis://localhost:6379"
```

### 2. Admin Credentials (Default Seeded Account)
*   **Username:** `admin`
*   **Password:** `admin123`
*   **Role:** `superadmin`

---

## 🏗️ Development & Deployment Workflow

### Running Locally
1.  **Backend:** `cd backend && npm run dev` (Runs backend on `http://localhost:3000`).
2.  **Admin Panel:** `cd admin && npm run dev` (Runs web UI on `http://localhost:5173`).
3.  **App:** `flutter run` (Connects to localhost backend during development).

### Pushing to Production
1.  **Backend (Cloud Run):** 
    ```bash
    cd backend
    gcloud run deploy sikkaplay-backend --source . --region asia-south1 --platform managed --allow-unauthenticated
    ```
2.  **Admin Panel (Firebase):**
    ```bash
    cd admin
    npm run build
    firebase deploy --only hosting
    ```
3.  **App Release (.aab):** Ensure `android/key.properties` is configured correctly, then run:
    ```bash
    flutter build appbundle
    ```

---

*This handbook is preserved locally inside the project workspace as a reference manual.*
