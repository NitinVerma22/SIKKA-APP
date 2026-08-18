# Sikka Play - Technical Audit Report

This document outlines the findings of the strict technical audit conducted across the Sikka Play application, analyzing the Database, Node.js Backend, Flutter Frontend, Firebase Integration, and Cost Optimization layers.

## 🚀 1. Database & Supabase (Performance, Security & Cost)

### Row Level Security (RLS)
- **Current Status**: **Not Enforced at DB Level**. The application uses Prisma ORM with a direct connection string (`postgres://...pooler.supabase.com`). By default, Prisma connects as a highly privileged user, bypassing Supabase RLS. Security is currently handled at the application layer (Node.js controllers).
- **Recommendation**: Since Node.js acts as the gatekeeper, ensure all controllers strictly validate `req.user.id === requestedId`. If you want true DB-level RLS with Prisma, you must utilize Prisma's Client Extensions to pass the user's context to Postgres via `set_config('request.jwt.claim.sub', ...)`.

### Indexing
- **Current Status**: **Partial**. Basic indexes (`@unique` on `phoneNumber`, `firebaseUid`) are present in `schema.prisma`. 
- **Recommendation**: Ensure you have explicit compound indexes (`@@index`) on frequently filtered columns like `[userId, createdAt]` for transactions and `channelName` for playground messages to prevent slow sequential scans as the database grows.

### Connection Pooling
- **Current Status**: **Optimized & Active**. 
- **Details**: The `DATABASE_URL` correctly utilizes Supavisor/PgBouncer (`pooler.supabase.com:6543`) with the `?pgbouncer=true` flag. This prevents connection exhaustion during traffic spikes.

### Data Fetching
- **Current Status**: **Needs Improvement**. 
- **Details**: Throughout the backend (e.g., `user.controller.ts`), queries frequently use `prisma.user.findUnique({ where: { id } })` without a `select` clause, which retrieves all columns (equivalent to `SELECT *`).
- **Recommendation**: Use `select: { id: true, name: true, avatarUrl: true }` heavily, especially in public endpoints like leaderboards or matchmaking, to significantly reduce egress bandwidth costs.

---

## ⚙️ 2. Backend (Node.js) (Scalability & Security)

### Clustering & PM2
- **Current Status**: **Not Implemented**.
- **Details**: The `package.json` start script currently runs a single Node.js instance (`node dist/index.js`), meaning the app runs on a single thread and CPU core.
- **Recommendation**: Install PM2 (`npm install -g pm2`) and modify your start script to `pm2 start dist/index.js -i max` to spawn worker processes for every available CPU core, enabling horizontal scaling.

### Rate Limiting & DDOS Protection
- **Current Status**: **Implemented & Active**.
- **Details**: `express-rate-limit` is actively configured in `rateLimiter.middleware.ts` and successfully applied to critical routes including `auth`, `earn`, `withdraw`, `chat`, and `matchmaking`. It successfully falls back to Redis if a remote URL is provided.

### Caching
- **Current Status**: **Underutilized**.
- **Details**: Redis is successfully integrated for Socket.io (`@socket.io/redis-adapter`) and Rate Limiting (`rate-limit-redis`), but it is *not* used to cache Prisma queries.
- **Recommendation**: Cache heavy, read-heavy operations like the global leaderboard (`prisma.user.findMany({ orderBy: { totalEarned: 'desc' } })`) in Redis with a 5-10 minute TTL.

### Error Handling & Logs
- **Current Status**: **Secure & Centralized**.
- **Details**: A global error handler is present in `index.ts`. It securely obfuscates the error stack traces in production (`...(process.env.NODE_ENV !== 'production' && { stack: err.stack })`), preventing sensitive DB architecture leaks.

---

## 📱 3. Frontend (Flutter) (Speed & Optimization)

### Widget Tree Optimization
- **Current Status**: **Good**.
- **Details**: Flutter's linting rules enforce `const` constructors for static widgets, reducing paint times. 

### Asset & Image Caching
- **Current Status**: **Implemented**.
- **Details**: `cached_network_image` is utilized correctly (specifically implemented recently in `profile_screen.dart` and `playground_studio_screen.dart`) for avatars and network assets. This avoids re-downloading images, drastically saving Firebase/Supabase egress bandwidth.

### App Size Reduction
- **Current Status**: **Commented Out**.
- **Details**: In `android/app/build.gradle.kts`, the ABI split filters (`abiFilters.addAll(setOf("armeabi-v7a", "arm64-v8a"))`) are currently commented out. 
- **Recommendation**: If you are distributing via `.apk` manually, uncomment this to generate separate, smaller APKs. If you are uploading to the Play Store, generate a `.aab` (App Bundle) (`flutter build appbundle`), which automatically handles ABI splitting.

### Memory Leaks
- **Current Status**: **Optimized**.
- **Details**: Controllers (`TextEditingController`, `AnimationController`, `ScrollController`) are systematically disposed of inside the `dispose()` methods across the application screens (e.g., in `profile_screen.dart`).

---

## 🔐 4. Firebase & Integration (Security & Sync)

### Auth Token Validation
- **Current Status**: **Secure**.
- **Details**: The `auth.middleware.ts` correctly extracts the Bearer token and securely verifies it against Firebase Admin SDK (`auth.verifyIdToken(idToken)`), attaching the decoded `userId` to the request pipeline.

### Security Rules
- **Current Status**: **Needs Verification**.
- **Details**: Firebase rules (`storage.rules`) are managed via the Firebase Console rather than committed to the repository root.
- **Recommendation**: Log into Firebase Console -> Storage -> Rules, and ensure avatars are locked down. Do not use `allow read, write: if true;`. Use:
```javascript
match /avatars/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null && request.auth.uid == userId;
}
```

---

## 💰 5. Cost Optimization

### Serverless/Edge Functions
- **Current Status**: **Not Implemented**.
- **Details**: Sikka Play currently operates as a monolith Node.js API. 
- **Recommendation**: Background Cron jobs (like daily streak resets, weekly leaderboard distributions, or clearing old chat messages) should eventually be moved to Supabase Edge Functions. This offloads heavy background processing from your core Node.js server, preventing latency spikes for active users.

### Pagination
- **Current Status**: **Partially Implemented**.
- **Details**: Administrative routes and Wallet history endpoints properly utilize Prisma's `skip` and `take` for pagination. However, certain fetching operations (like fetching Playground Messages `prisma.playgroundMessage.findMany`) do not enforce a strict `take` limit.
- **Recommendation**: Enforce a strict `take: 50` on all `findMany` queries globally to ensure an unexpected surge of data doesn't crash the Node.js memory heap.
