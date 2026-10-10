# SikkaPlay Tournaments System: Master Architecture & Engineering Specification

> **Version:** 1.0  
> **Status:** Finalized Specification  
> **Target Platforms:** Flutter Mobile App (Android/iOS), React Vite Admin Dashboard, Node.js + Express + Prisma + PostgreSQL Backend  
> **Document Purpose:** Complete A-to-Z Technical Architecture, Data Flow Diagrams (DFD), UI/UX Specifications, Monetization Strategy, and Database Design for the SikkaPlay Tournaments feature.

---

## Table of Contents
1. [Executive Summary & Core Rules](#1-executive-summary--core-rules)
2. [Data Flow Diagrams (DFD Level 0 & Level 1)](#2-data-flow-diagrams-dfd)
3. [System Architecture & State Flowcharts](#3-system-architecture--state-flowcharts)
4. [Sequence Diagrams (End-to-End Execution)](#4-sequence-diagrams)
5. [Database Schema & Data Models](#5-database-schema--data-models)
6. [API Specifications (REST Endpoints)](#6-api-specifications)
7. [Flutter Mobile App UI/UX Inventory](#7-flutter-mobile-app-uiux-inventory)
8. [Admin Panel Dashboard & Dynamic Controls](#8-admin-panel-dashboard--controls)
9. [Monetization & AdMob Placement Architecture](#9-monetization--admob-placement)
10. [Implementation Roadmap](#10-implementation-roadmap)

---

## 1. Executive Summary & Core Rules

### 1.1 Overview
The SikkaPlay Tournaments system transforms the casual gaming experience into an asynchronous, time-based **Coin Grinder Tournament**. Instead of restricting players to a single repetitive mini-game, users can play any of the **6 core casual games** to grind coins, where **1 Coin Earned = 1 Tournament Point**.

### 1.2 Eligible Games (Only 6 Games)
Coins earned from gameplay in only these 6 games increment the tournament score:
1. **Treasure Grid** (`treasure_grid`)
2. **Emoji Memory / Memory Flip** (`emoji_memory`)
3. **Math Rush** (`math_rush`)
4. **Colour Sort / Water Sort** (`water_sort`)
5. **Bubble Sort / Bubble Shooter** (`bubble_shooter`)
6. **Arrow Escape** (`arrow_escape`)

### 1.3 Excluded Rewards (0 Tournament Points)
To maintain integrity and fair play, all non-game earnings are strictly filtered out:
- Daily Check-in / Daily Streak
- Daily Promo Codes / Redeem Codes
- External Offerwalls & App Installs (Adscalx, Adscend, Tapjoy)
- Surveys (BitLabs, CPX Research)
- Social Tasks, Visit Links, Spin Wheel Rewards

### 1.4 Tie-Breaker Algorithm
When two or more players accumulate the exact same score:
$$\text{Rank Priority} = \text{Score (DESC)} \longrightarrow \text{lastScoreUpdatedAt (ASC)}$$
*(The player who reached the score first holds the higher rank).*

### 1.5 Scheduled Recurring Templates
1. **1-Hour Flash Rush (3 Times Daily):**
   - Morning: `09:00 AM – 10:00 AM IST`
   - Evening: `06:00 PM – 07:00 PM IST`
   - Night: `10:00 PM – 11:00 PM IST`
2. **Daily Mega Cup:** Every day (`00:00 to 23:59 IST`).
3. **Weekend Special:** Saturday `00:00` to Sunday `23:59 IST`.
4. **Weekly Championship:** Monday `00:00` to Sunday `23:59 IST`.
5. **Monthly Mega League:** 1st of month to final day of month.

---

## 2. Data Flow Diagrams (DFD)

### 2.1 DFD Level 0 (Context Diagram)
The high-level boundary showing data flows between external entities and the SikkaPlay Tournament Subsystem.

```mermaid
flowchart TD
    Admin["Admin (Web Dashboard)"] -->|"Create/Edit Tournaments, Schedules, Prize Tiers"| System["(0.0) SikkaPlay Tournaments Engine"]
    System -->|"Audit Logs, Live Participant Stats, Leaderboards"| Admin

    Player["Player (Flutter Mobile App)"] -->|"Join Request (Ad Proof / Coin Fee), Game Sessions"| System
    System -->|"Active Tournaments, Game Arena, Leaderboard, Prizes"| Player

    AdMob["AdMob / Ad Network"] -->|"Rewarded Ad SSV, Interstitial Impression"| System
    System -->|"Ad Request & Display Callbacks"| AdMob

    FCM["Firebase Cloud Messaging (FCM)"] <--"Push Notifications (Winner Alerts, Start Alerts)"-- System
    
    DB[("PostgreSQL Database")] <-->|"Tournaments, Scores, Wallets, Transactions"| System
```

---

### 2.2 DFD Level 1 (Detailed Subsystem Processes)
Decomposing the tournament system into 5 primary operational processes.

```mermaid
flowchart TD
    subgraph Admin_Operations ["Process 1.0: Tournament Lifecycle Management"]
        AdminUser["Admin"] -->|"Configure Rules, Prizes, Dates"| P1["1.0 Admin Tournament Management"]
        P1 -->|"Write Config & Schedule"| DB_T[("Tournaments Table")]
        P1 -->|"Trigger Payout / Refund"| P5["5.0 Automated Prize & Settlement Engine"]
    end

    subgraph Enrollment ["Process 2.0: Player Enrollment & Entry Fee"]
        Player1["Player"] -->|"Request Join"| P2{"2.0 Join Validator"}
        P2 -->|"Free: Verify Rewarded Ad"| AdMob["AdMob Network"]
        P2 -->|"Paid: Verify & Deduct Coins"| DB_U[("Users & Wallets Table")]
        P2 -->|"Record Enrollment"| DB_P[("Tournament Participants Table")]
    end

    subgraph Gameplay_Scoring ["Process 3.0: Game Session & Score Pipeline"]
        Player2["Player in Arena"] -->|"Play 1 of 6 Core Games (with tournamentId)"| P3["3.0 Game Session Verifier"]
        P3 -->|"Validate Gameplay & Max Coin Limits"| P3
        P3 -->|"Credit Wallet Balance"| DB_U
        P3 -->|"Atomic Increment score"| DB_P
    end

    subgraph Leaderboard_Ad ["Process 4.0: Leaderboard & Ad Monetization"]
        Player3["Player"] -->|"Request Leaderboard"| P4["4.0 Leaderboard Generator"]
        DB_P -->|"Query Top Ranks (Score DESC, Time ASC)"| P4
        P4 -->|"Render Leaderboard + User Rank"| Player3
        Player3 -->|"Press Back / Exit"| AdInter["Trigger Interstitial Ad"]
    end

    subgraph Settlement ["Process 5.0: Automated Settlement & Notification"]
        CronTimer["Cron Scheduler (Every 1m)"] -->|"Inspect Expired Tournaments"| P5
        DB_T -->|"Status: LIVE -> COMPLETED"| P5
        P5 -->|"Fetch Top Ranks vs Prize JSON"| DB_P
        P5 -->|"Credit Prize Coins & Ledger Tx"| DB_U
        P5 -->|"Log Winners"| DB_W[("Prize Winners Table")]
        P5 -->|"Dispatch Winner Notification"| FCM["FCM Notification Service"]
    end
```

---

## 3. System Architecture & State Flowcharts

### 3.1 State Diagram: Tournament Lifecycle
```mermaid
stateDiagram-v2
    [*] --> UPCOMING: Admin Creates Tournament (now < startTime)
    UPCOMING --> LIVE: Cron triggers when (now >= startTime)
    LIVE --> COMPLETED: Cron triggers when (now >= endTime)
    COMPLETED --> PRIZES_DISTRIBUTED: Cron resolves Top Ranks & Credits Wallets
    
    UPCOMING --> CANCELLED: Admin manually cancels (auto refund if paid)
    LIVE --> CANCELLED: Admin manually cancels (auto refund fees)
    
    PRIZES_DISTRIBUTED --> [*]
    CANCELLED --> [*]
```

### 3.2 Flowchart: Player Gameplay & Multi-Tournament Isolation Flow
```mermaid
flowchart TD
    Start([User opens SikkaPlay]) --> OpenTournaments[Navigate to Tournaments Tab]
    OpenTournaments --> List[View Live & Upcoming Tournaments]
    List --> JoinCheck{Already Joined?}
    
    JoinCheck -- No --> CheckEntryType{Entry Type?}
    CheckEntryType -- FREE --> WatchAd[Watch Rewarded Video Ad]
    WatchAd --> JoinSuccess[Enrolled in TournamentParticipant]
    CheckEntryType -- COINS --> ConfirmDialog[Show Coin Deduction Dialog]
    ConfirmDialog --> BalanceCheck{Balance >= Fee?}
    BalanceCheck -- No --> ErrorInsufficient[Show Insufficient Coins Alert]
    BalanceCheck -- Yes --> DeductCoins[Deduct Fee & Record Transaction]
    DeductCoins --> JoinSuccess

    JoinCheck -- Yes --> EnterArena[Enter Tournament Arena Screen]
    JoinSuccess --> EnterArena

    EnterArena --> ArenaUI[View Timer, Rank & 6 Game Cards]
    ArenaUI --> TapGame[Tap e.g. Math Rush Play Button]
    TapGame --> LaunchGame[Launch Game passing tournamentId]
    LaunchGame --> PlayGame[User plays mini-game session]
    PlayGame --> EndGameAPI[Call /game/end or /complete-level]
    
    EndGameAPI --> ServerCheck{Valid Session & Active Tournament?}
    ServerCheck -- Yes --> UpdateBoth[1. Wallet Balance += Coins<br/>2. Tournament Score += Coins]
    ServerCheck -- No --> UpdateWalletOnly[Wallet Balance += Coins only]
    
    UpdateBoth --> ReturnToArena[Return to Tournament Arena]
    ReturnToArena --> LiveUpdate[Live Rank & Score Updated on Screen]
    
    LiveUpdate --> TapLeaderboard[Tap 'View Full Leaderboard']
    TapLeaderboard --> LeaderboardScreen[Dedicated Leaderboard Screen]
    LeaderboardScreen --> BackTapped[Tap Back Button]
    BackTapped --> ShowInterstitial[Show Interstitial Ad]
    ShowInterstitial --> BackToArena[Return to Arena Screen]
```

---

## 4. Sequence Diagrams

### 4.1 Sequence Diagram: Game Completion & Score Update
```mermaid
sequenceDiagram
    autonumber
    actor Player as Mobile Player
    participant Flutter as Flutter App
    participant GameEngine as Game Screen / Engine
    participant Backend as Node.js API
    participant DB as PostgreSQL (Prisma Tx)

    Player->>Flutter: Taps "Play Math Rush" from Tournament #101
    Flutter->>GameEngine: Launch with extra: { tournamentId: '101' }
    GameEngine->>Backend: POST /game/start { gameType: 'math_rush' }
    Backend-->>GameEngine: Returns sessionId: 'sess_999'

    Note over Player, GameEngine: Player plays Math Rush for 60 seconds
    
    GameEngine->>Flutter: Game finishes (Earned 50 Coins)
    Flutter->>Backend: POST /game/end { sessionId: 'sess_999', coinsEarned: 50, tournamentId: '101' }
    
    activate Backend
    Backend->>DB: Begin Prisma $transaction
    DB->>DB: Verify GameSession (Duration, Rate-limit, Active status)
    DB->>DB: Update User Wallet: balance += 50
    DB->>DB: Insert Transaction { type: 'game', amount: 50 }
    
    opt tournamentId is present & valid
        DB->>DB: Verify Tournament #101 is LIVE and Player is enrolled
        DB->>DB: Update TournamentParticipant: score += 50, lastScoreUpdatedAt = NOW()
    end
    
    DB-->>Backend: Commit $transaction
    Backend-->>Flutter: 200 OK { success: true, coinsEarned: 50, newBalance: 1200, tournamentScore: 250 }
    deactivate Backend

    Flutter->>Player: Audio fanfare + Returns to Tournament Arena with Score 250!
```

---

### 4.2 Sequence Diagram: Automated Prize Payout via Cron
```mermaid
sequenceDiagram
    autonumber
    participant Cron as Background Cron Job (Every 1m)
    participant Service as TournamentService
    participant DB as PostgreSQL
    participant FCM as Firebase Cloud Messaging

    Cron->>Service: checkTournamentPrizes()
    Service->>DB: SELECT * FROM Tournament WHERE status = 'LIVE' AND endTime <= NOW()
    DB-->>Service: Returns expired tournaments [T1, T2]
    
    loop For each expired Tournament
        Service->>DB: UPDATE Tournament SET status = 'COMPLETED'
        Service->>DB: SELECT * FROM TournamentParticipant WHERE tournamentId = T.id ORDER BY score DESC, lastScoreUpdatedAt ASC
        DB-->>Service: Ranked list of participants
        
        Note over Service: Match participant ranks against prizeStructure JSON
        
        loop For each winner within prize tiers
            Service->>DB: Begin $transaction
            DB->>DB: UPDATE User SET balance = balance + prizeCoins
            DB->>DB: INSERT INTO Transaction (type: 'tournament_prize', amount: prizeCoins)
            DB->>DB: INSERT INTO TournamentPrizeWinner (tournamentId, userId, rank, prizeCoins)
            DB-->>Service: Commit $transaction
            
            Service->>FCM: Send push notification to winner User FCM Token
        end
        
        Service->>DB: UPDATE Tournament SET isPrizesDistributed = true
    end
```

---

## 5. Database Schema & Data Models

### 5.1 Prisma Schema Specification

```prisma
enum TournamentStatus {
  UPCOMING
  LIVE
  COMPLETED
  CANCELLED
}

enum TournamentEntryType {
  FREE    // Rewarded Ad entry
  COINS   // Coin entry fee deduction
}

model Tournament {
  id                  String               @id @default(uuid())
  title               String               // e.g., "1-Hour Flash Rush"
  description         String?              // Tournament guidelines & description
  bannerUrl           String?              // Promotional banner image
  tag                 String?              // e.g. "HOT", "FLASH", "MEGA", "WEEKEND"
  
  entryType           TournamentEntryType  @default(FREE)
  entryFee            Int                  @default(0) // 0 for FREE, > 0 for COINS
  maxParticipants     Int?                 // null = Unlimited
  
  allowedGames        String[]             @default(["treasure_grid", "emoji_memory", "math_rush", "water_sort", "bubble_shooter", "arrow_escape"])
  scoreMultiplier     Float                @default(1.0) // 1.0 standard, 2.0 for Happy Hour
  
  prizePool           Int                  @default(0)
  prizeStructure      Json                 // [{"rankMin": 1, "rankMax": 1, "prize": 1500}, {"rankMin": 2, "rankMax": 2, "prize": 800}, ...]
  
  startTime           DateTime
  endTime             DateTime
  status              TournamentStatus     @default(UPCOMING)
  isPrizesDistributed Boolean              @default(false)
  
  isRecurring         Boolean              @default(false)
  recurringCron       String?              // e.g., "0 9,18,22 * * *" for 3x daily flash
  
  createdAt           DateTime             @default(now())
  updatedAt           DateTime             @updatedAt

  participants        TournamentParticipant[]
  prizesAwarded       TournamentPrizeWinner[]

  @@index([status, startTime, endTime])
}

model TournamentParticipant {
  id                 String      @id @default(uuid())
  tournamentId       String
  userId             String
  score              Int         @default(0)
  joinedAt           DateTime    @default(now())
  lastScoreUpdatedAt DateTime    @default(now()) // Tie-breaker timestamp

  tournament         Tournament  @relation(fields: [tournamentId], references: [id], onDelete: Cascade)
  user               User        @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([tournamentId, userId])
  @@index([tournamentId, score(sort: Desc), lastScoreUpdatedAt(sort: Asc)])
}

model TournamentPrizeWinner {
  id            String      @id @default(uuid())
  tournamentId  String
  userId        String
  rank          Int
  score         Int
  prizeCoins    Int
  distributedAt DateTime    @default(now())

  tournament    Tournament  @relation(fields: [tournamentId], references: [id], onDelete: Cascade)
  user          User        @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([tournamentId, userId])
}
```

---

## 6. API Specifications

### 6.1 Public & Authenticated Player APIs

#### `GET /api/v1/tournaments`
- **Auth:** Bearer JWT
- **Query Params:** `tab`: `live` | `upcoming` | `my` | `history`
- **Response:**
```json
{
  "success": true,
  "tournaments": [
    {
      "id": "t-101",
      "title": "1-Hour Flash Rush (Evening)",
      "tag": "FLASH ⚡",
      "bannerUrl": "https://assets.sikkaplay.com/banners/flash.webp",
      "entryType": "FREE",
      "entryFee": 0,
      "prizePool": 2500,
      "startTime": "2026-10-10T18:00:00.000Z",
      "endTime": "2026-10-10T19:00:00.000Z",
      "status": "LIVE",
      "participantCount": 184,
      "isJoined": true,
      "userScore": 120,
      "userRank": 6
    }
  ]
}
```

#### `GET /api/v1/tournaments/:id`
- **Auth:** Bearer JWT
- **Returns:** Detailed tournament model, allowed games list, user enrollment status, top 3 podium preview, and prize tiers.

#### `POST /api/v1/tournaments/:id/join`
- **Auth:** Bearer JWT
- **Body:** `{ "adWatched": true }` (if FREE) or `{}` (if COINS)
- **Logic:**
  - If FREE: Verify `adWatched`, enroll user with `entryFee = 0`.
  - If COINS: Check user `balance >= entryFee`. Deduct fee, write ledger transaction, enroll user.

#### `GET /api/v1/tournaments/:id/leaderboard`
- **Auth:** Bearer JWT
- **Query Params:** `page=1&limit=50`
- **Returns:** Full sorted leaderboard list + Current User's pinned exact rank & score.

---

### 6.2 Admin Control APIs (`/api/v1/admin/tournaments`)

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/admin/tournaments` | List all tournaments with filters (status, date range, search) |
| `POST` | `/admin/tournaments` | Create new tournament with custom dynamic prize tiers & game list |
| `PUT` | `/admin/tournaments/:id` | Update tournament metadata, banner, status, or prizes |
| `POST` | `/admin/tournaments/:id/duplicate` | Clone existing tournament configuration for quick rescheduling |
| `POST` | `/admin/tournaments/:id/payout` | Force manual prize distribution trigger |
| `POST` | `/admin/tournaments/:id/cancel` | Cancel tournament and auto-refund entry coins to all participants |

---

## 7. Flutter Mobile App UI/UX Inventory

### 7.1 Screen 1: Tournaments Hub (`/tournaments`)
```
┌──────────────────────────────────────────────┐
│  🏆 Tournaments                🪙 1,250      │
├──────────────────────────────────────────────┤
│ [ 🔴 Live (2) ] [ Upcoming ] [ My (1) ] [Past]│
├──────────────────────────────────────────────┤
│ ┌──────────────────────────────────────────┐ │
│ │ ⚡ FLASH RUSH (EVENING)        [LIVE NOW]│ │
│ │ ⏱️ Ends in: 34m 12s   💰 Pool: 2,500 🪙   │ │
│ │ 👥 184 Players        🎟️ FREE (Ad)       │ │
│ │                                          │ │
│ │ [ ENTER ARENA ➔ ]                        │ │
│ └──────────────────────────────────────────┘ │
│ ┌──────────────────────────────────────────┐ │
│ │ 🏆 DAILY MEGA CUP               [50 🪙]  │ │
│ │ ⏱️ Ends in: 5h 20m    💰 Pool: 10,000 🪙  │ │
│ │ 👥 412 Players        🎟️ COINS ENTRY     │ │
│ │                                          │ │
│ │ [ JOIN NOW (50 🪙) ]                     │ │
│ └──────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘
```

---

### 7.2 Screen 2: Tournament Detail & Game Arena (`/tournaments/:id`)
```
┌──────────────────────────────────────────────┐
│  ← ⚡ 1-Hour Flash Rush        ⏱️ 34m 12s   │
├──────────────────────────────────────────────┤
│ ┌──────────────────────────────────────────┐ │
│ │ 👤 YOUR CURRENT STANDING                 │ │
│ │ Points: 150 Pts          Rank: #4 / 184  │ │
│ │ Winning Zone: Top 10     Prize: 200 🪙   │ │
│ └──────────────────────────────────────────┘ │
├──────────────────────────────────────────────┤
│ 🏆 [ VIEW FULL LEADERBOARD & PRIZES ➔ ]      │
├──────────────────────────────────────────────┤
│ 🎮 PLAY GAMES TO EARN POINTS                 │
│ ┌──────────────┐          ┌──────────────┐   │
│ │ 💣 Treasure  │          │ ⚡ Math Rush │   │
│ │    Grid      │          │              │   │
│ │   [ PLAY ]   │          │   [ PLAY ]   │   │
│ └──────────────┘          └──────────────┘   │
│ ┌──────────────┐          ┌──────────────┐   │
│ │ 🧠 Emoji     │          │ 🏹 Arrow     │   │
│ │    Memory    │          │    Escape    │   │
│ │   [ PLAY ]   │          │   [ PLAY ]   │   │
│ └──────────────┘          └──────────────┘   │
│ ┌──────────────┐          ┌──────────────┐   │
│ │ 🫧 Bubble    │          │ 🧪 Colour    │   │
│ │    Sort      │          │    Sort      │   │
│ │   [ PLAY ]   │          │   [ PLAY ]   │   │
│ └──────────────┘          └──────────────┘   │
└──────────────────────────────────────────────┘
```

---

### 7.3 Screen 3: Dedicated Leaderboard Screen (`/tournaments/:id/leaderboard`)
```
┌──────────────────────────────────────────────┐
│  ← 🏆 Leaderboard                            │
├──────────────────────────────────────────────┤
│                  🥇 Gold                     │
│               Aman_99 (450 Pts)              │
│                Prize: 1,000 🪙               │
│         🥈 Silver             🥉 Bronze      │
│      Rahul_G (380 Pts)     Priya_K (290 Pts) │
│       Prize: 500 🪙          Prize: 300 🪙   │
├──────────────────────────────────────────────┤
│ #4   YOU                   150 Pts    200 🪙 │
│ #5   Karan_V               140 Pts    100 🪙 │
│ #6   Deepak_S              125 Pts    100 🪙 │
│ #7   Rohit_M               110 Pts    100 🪙 │
├──────────────────────────────────────────────┤
│ [STICKY] YOU: Rank #4 | 150 Pts | Prize: 200🪙│
└──────────────────────────────────────────────┘
  ▲ When player taps '← Back', Interstitial Ad triggers!
```

---

## 8. Admin Panel Dashboard & Controls

Located in `admin/src/pages/Tournaments.tsx`:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 🏆 Tournaments Manager                         [ + Create Tournament ]      │
├─────────────────────────────────────────────────────────────────────────────┤
│ Search: [_____________]  Filter Status: [ ALL ▾ ]   Type: [ ALL ▾ ]         │
├─────────────────────────────────────────────────────────────────────────────┤
│ Title            Status   Dates             Entry  Prize Pool  Actions      │
│ 1-Hour Flash #1  LIVE     Today 18:00-19:00 FREE   2,500 🪙    [Edit] [View]│
│ Daily Mega Cup   LIVE     Today 00:00-23:59 50 🪙  10,000 🪙   [Edit] [View]│
│ Weekend Cup      UPCOMING Sat 00:00-Sun 23  100 🪙 25,000 🪙   [Edit] [Copy]│
└─────────────────────────────────────────────────────────────────────────────┘
```

### Dynamic Create/Edit Modal Features:
1. **Title & Tags:** Text inputs for Title, Subtitle, Banner URL, Badges.
2. **Scheduling:** Start DateTime & End DateTime Pickers.
3. **Entry Selection:** Toggle `FREE (Rewarded Ad)` vs `COINS (Input Fee)`.
4. **Allowed Games Selector:** 6 checkboxes for each game.
5. **Dynamic Prize Tiers Builder:**
   - Row 1: Rank `1` to `1` $\rightarrow$ Prize: `1500` Coins
   - Row 2: Rank `2` to `2` $\rightarrow$ Prize: `800` Coins
   - Row 3: Rank `3` to `3` $\rightarrow$ Prize: `400` Coins
   - Row 4: Rank `4` to `10` $\rightarrow$ Prize: `150` Coins each
   - `[ + Add Tier Row ]` button.
6. **Multipliers:** 1.0x default, or set 2.0x for promotional events.

---

## 9. Monetization & AdMob Placement

### 9.1 High-Value Touchpoints:
1. **Entry Touchpoint (Rewarded Video Ad):**
   - Every participant in a **FREE** tournament watches 1 full Rewarded Ad to enroll.
   - High eCPM ($2 to $5+ in Tier 1/2 geos, solid return in India).
2. **Leaderboard Exit Touchpoint (Interstitial Ad):**
   - Players obsessively check rankings after every match.
   - Back action triggers `AdService.instance.showInterstitialAd(...)`.
   - **Protection Rule:** 30–45 seconds cooldown timer prevents ad spam and ensures AdMob policy compliance.
3. **Paid Entry Coin Sink:**
   - 50–100 coins entry fee directly deflates the in-app economy and drives engagement towards high-value tasks.

---

## 10. Implementation Roadmap

| Phase | Milestone | Deliverables |
|---|---|---|
| **Phase 1** | **Database & Models** | Update `schema.prisma` with `Tournament`, `TournamentParticipant`, `TournamentPrizeWinner`. Run `prisma db push`. |
| **Phase 2** | **Backend APIs & Services** | Implement `tournament.service.ts`, `tournament.controller.ts`, `tournament.routes.ts`. |
| **Phase 3** | **Game Score Hookup** | Integrate `tournamentId` validation and score increments into `game.controller.ts`, `arrowEscape.controller.ts`, `waterSort.controller.ts`, `bubbleShooter.controller.ts`. |
| **Phase 4** | **Cron Automation** | Background runner for status transitions (Upcoming $\rightarrow$ Live $\rightarrow$ Completed) and automatic wallet prize distribution. |
| **Phase 5** | **Admin Dashboard** | Build React/Vite `Tournaments.tsx` screen with Dynamic Prize Tiers Builder and actions. |
| **Phase 6** | **Flutter Mobile Client** | Implement Tournaments Hub, Detail/Arena, Dedicated Leaderboard, Join Modals, and Interstitial Ad triggers. |
| **Phase 7** | **End-to-End Verification** | Full staging test: Admin creates tournament $\rightarrow$ User joins $\rightarrow$ Games played $\rightarrow$ Score incremented $\rightarrow$ Leaderboard checked $\rightarrow$ Prize distributed. |
