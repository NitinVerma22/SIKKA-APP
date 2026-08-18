========================
APP OVERVIEW
========================

1. Total number of games: 4 (Math Rush, Emoji Memory, Treasure Grid, Spin & Earn)
2. Average duration of each game: ~1-3 minutes per session
3. Average session duration: ~10-15 minutes (to fill the 80-coin Gullak limit)
4. Average sessions per day: 3-5 sessions based on Spin replenishments and Gullak capacity

========================
COIN EARNING SYSTEM
========================

- Feature Name: Daily Login (Streak Bonus)
  - Coins Earned: Day * 10 (e.g., Day 1 = 10, Day 2 = 20). Milestone days: Day 7 (500), Day 14 (1000), Day 21 (1500), Day 28 (2000).
  - Is there any cooldown?: 24 hours.
  - Maximum claims per day: 1.
  - Does it require watching an ad?: Milestone days (7, 14, 21, 28) require a Rewarded Ad.
  - Estimated daily coins: 10 - 2000 (depending on day).

- Feature Name: Gullak (Game Earnings)
  - Coins Earned: Max 80 coins per claim. Earned by playing games (e.g., Math Rush yields 1-3 coins per correct answer based on difficulty).
  - Is there any cooldown?: Fills as you play.
  - Maximum claims per day: Unlimited, but Ad sequence dictates user fatigue.
  - Does it require watching an ad?: Yes, sequence based (Interstitial -> Rewarded Ad -> None). User can also bypass the ad by paying a 30-coin fee.
  - Estimated daily coins: 240 - 400 (assuming 3-5 fills).

- Feature Name: Spin & Earn
  - Coins Earned: 1, 2, 3, 5, 7, 10, 15, 20, 30 coins per spin.
  - Is there any cooldown?: None, but limited by Spins.
  - Maximum claims per day: Users start with 3 spins. Infinite as long as they watch ads for more spins.
  - Does it require watching an ad?: Yes, watching a Rewarded Ad grants 3 Free Spins.
  - Estimated daily coins: 30 - 100.

- Feature Name: Social Join Tasks
  - Coins Earned: ~50 coins per task.
  - Is there any cooldown?: One-time per task.
  - Maximum claims per day: Dependent on active tasks in config.
  - Does it require watching an ad?: Yes, requires a Rewarded Ad to claim after validating the 20-second visit.
  - Estimated daily coins: 50 - 100 (if tasks available).

- Feature Name: Visit & Earn
  - Coins Earned: ~5 coins per visit.
  - Is there any cooldown?: None.
  - Maximum claims per day: Depends on available links.
  - Does it require watching an ad?: No, but requires a time-on-page validation.
  - Estimated daily coins: 10 - 25.

- Feature Name: Offerwall / App Install
  - Coins Earned: Ranges heavily (e.g., 80, 220).
  - Is there any cooldown?: None.
  - Maximum claims per day: Unlimited (supply constrained).
  - Does it require watching an ad?: No, requires app install/verification.
  - Estimated daily coins: 200 - 500.

- Feature Name: Surveys
  - Coins Earned: ~250, 500, 800 coins.
  - Is there any cooldown?: None.
  - Maximum claims per day: Subject to survey availability.
  - Does it require watching an ad?: No.
  - Estimated daily coins: 0 - 800.

- Feature Name: Daily Code
  - Coins Earned: Dynamic via backend promo code.
  - Is there any cooldown?: Promo specific.
  - Maximum claims per day: Total uses restricted globally per code (`maxClaims`).
  - Does it require watching an ad?: No.
  - Estimated daily coins: 0 - 100.

- Feature Name: Referral Network
  - Coins Earned: Dynamic percentage or fixed per install.
  - Is there any cooldown?: None.
  - Maximum claims per day: Unlimited.
  - Does it require watching an ad?: No.
  - Estimated daily coins: Highly variable.

========================
ADVERTISEMENT SYSTEM
========================

- Placement: Game Screens (Math Rush, Spin Wheel)
  - Ad Type: Banner Ad.
  - Trigger: Always visible at the top/bottom of the screen.
  - Frequency: Persistent.

- Placement: Spin & Earn Extra Spins
  - Ad Type: Rewarded Video Ad.
  - Trigger: When user exhausts 3 spins and clicks "Get Spins".
  - Frequency: Every 3 spins.

- Placement: Gullak Claim
  - Ad Type: Interstitial or Rewarded Ad.
  - Trigger: When user clicks to claim the 80 filled coins. 
  - Frequency: Dictated by `gullakAdSequence` (default: interstitial -> rewarded -> none).

- Placement: Game Exit
  - Ad Type: Interstitial Ad.
  - Trigger: Fired immediately after successfully claiming the Gullak and exiting the game.
  - Frequency: Once per session end.

- Placement: Daily Streak Milestones
  - Ad Type: Rewarded Video Ad.
  - Trigger: When claiming Day 7, 14, 21, and 28 rewards.
  - Frequency: Weekly.

- Placement: Social Join Tasks
  - Ad Type: Rewarded Video Ad.
  - Trigger: Fired after the validation timer completes to claim the ~50 coin reward.
  - Frequency: Once per task.

*Note: The app relies heavily on `FakeAdDialog` to simulate ad experiences or handle missing ad inventory without breaking the user flow.*

========================
USER FLOW
========================

1. **Onboarding / Start**: User opens the app, sees persistent Banner Ads, and navigates to the Home Screen.
2. **Daily Routine**: User clicks the Daily Streak banner. If it's a milestone day, they watch a Rewarded Ad. Otherwise, they claim coins instantly.
3. **Gaming & Earning**: User enters a game (e.g., Math Rush). They play multiple rounds (answering questions). Their performance fills up the Gullak (up to 80 coins) and their session coins.
4. **Claiming Loop**: 
   - Once the Gullak is full, they must claim it to continue earning.
   - The user clicks claim and is served an Interstitial or Rewarded Ad (or pays 30 coins to bypass). 
   - Post-claim, if they exit, another Interstitial Ad might trigger.
5. **Alternative Earnings**: User runs out of gaming stamina or spins. They navigate to Spin & Earn, use 3 spins, and watch a Rewarded Ad for 3 more. They may also do Visit & Earn or Surveys.
6. **Withdrawal**: User accumulates 10,000 Sikka in their Self Earning pool and withdraws ₹100.

========================
EXPECTED USER ACTIVITY
========================

- **Active Days/Week**: 5-7 days (heavily incentivized by the escalating streak and streak rescue cost).
- **Daily Time Spent**: 30-45 minutes (mostly inside games and watching claim ads).
- **Ad Views Per Day**: ~8-15 ads (3-4 Banners, 3-5 Interstitials from Gullak, 2-6 Rewarded from Spins/Gullak/Tasks).
- **Daily Average Earnings (Without Surveys/Installs)**: 300-600 coins.

========================
LIMITS
========================

- **Gullak Limit**: Hard cap at 80 coins. User MUST claim to keep earning.
- **Withdrawal Limits**: 
  - Minimum withdrawal is 10,000 coins (₹100).
  - Options: ₹100, ₹200, ₹300, ₹500.
- **Referral Withdrawal Limits**: Requires a minimum of 50 hours (3000 mins) of personal playtime and at least 2 active referrals to unlock the referral balance.
- **Penalty Limits (Math Rush)**: Incorrect answer = -1 coin. Timeout = -10 coins.
- **Streak Rescue Cost**: Dynamic cost in coins to rescue a broken streak.
- **Ad Bypass Limit**: Costs 30 coins to bypass the Gullak claim ad.

========================
FINAL SUMMARY
========================

- Economy revolves around high-frequency micro-earning through games that force a hard stop at 80 coins, triggering an aggressive ad sequence.
- Ad inventory is maximized by blending Banners, Interstitials (on exit/claim), and Rewarded Video (spins/milestones/claims).
- Withdrawals are strictly gated: ₹100 requires 10,000 coins. At ~500 coins a day, it takes a highly active user roughly 20 days of organic grind to reach their first self-earning payout.
- Referral payouts are deeply protected by requiring 50 hours of personal gameplay and 2 active invites, severely limiting fraudulent network draining.
