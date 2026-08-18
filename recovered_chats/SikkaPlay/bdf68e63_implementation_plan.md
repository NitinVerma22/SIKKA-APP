# Virtual Gifts Expansion Plan

This plan outlines the expansion of virtual gifts in the SikkaPlay app. We will add multiple new gifts starting from 50 coins up to 5000 coins, including the special "Jackpot" and "Boys Kit" bundles. Since the number of gifts is increasing, the UI will also be updated to a scrollable grid so all gifts fit perfectly on the screen.

## Proposed Gifts List

| Coins | Gift Name | Emoji | Description |
|---|---|---|---|
| 50 | Coffee | ☕ | A warm cup of coffee |
| 50 | Heart | 💖 | A sparkling heart |
| 100 | Ice Cream | 🍦 | Sweet ice cream |
| 200 | Rose | 🌹 | A beautiful red rose |
| 500 | Chocolate | 🍫 | Delicious chocolate |
| 1000 | Crown | 👑 | A golden royal crown |
| 2000 | Ring | 💍 | A diamond ring |
| 5000 | Female Jackpot | 🛍️ | Dress, Ring, Jewelry, Rose, Female Shoes, Female Bag |
| 5000 | Boys Kit | 💼 | Boys Shoes, Coat Pant, Watch, etc. |

## Open Questions
- Please review the gifts list above. Are you happy with these names, emojis, and prices? Should I add or remove any?
- Since there are now many gifts, I will change the "Virtual Gifts" drawer in the app to be a scrollable list/grid. Is that okay?

## Proposed Changes

---

### Backend Schema & Data

#### [MODIFY] [playground.controller.ts](file:///E:/development/SikkaPlay/backend/src/controllers/playground.controller.ts)
- Update the `ensureSeedData` function to seed the new list of gifts into the database if the table is empty.
- Provide proper icon URLs (from flaticon or similar) for all new gifts to match the database requirements.

---

### Frontend App

#### [MODIFY] [playground_studio_screen.dart](file:///E:/development/SikkaPlay/lib/features/playground/screens/playground_studio_screen.dart)
- Update `_showGiftsDrawer()` to use a `GridView.builder` or a `Wrap` widget inside a `SingleChildScrollView`. This ensures that all 9+ gifts fit nicely on the screen without overflowing.
- Add all the new gifts to the hardcoded list in the drawer with their respective prices and emojis.

## Verification Plan
### Automated Tests
- Run `npm run build` for backend to ensure no syntax errors.

### Manual Verification
- Truncate the `Gift` table in the database and restart the backend to trigger the seeding script.
- Verify the new gifts are added to the DB.
- Open the SikkaPlay app, navigate to chat, open the gifts drawer, and verify that the scrollable grid displays all new gifts correctly.
- Test sending a 5000-coin gift to ensure coin deduction works correctly.
