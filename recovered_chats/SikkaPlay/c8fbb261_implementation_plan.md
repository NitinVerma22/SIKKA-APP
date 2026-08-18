# Dynamic Coin-to-Rupee Conversion Rate

We need to make the coin-to-rupee conversion rate dynamically configurable via the backend `ConfigService`. Currently, the app hardcodes `100 coins = ₹1`. The goal is to allow administrators to change this rate (e.g., to `1000 coins = ₹1`) without needing an app update.

## Open Questions

> [!WARNING]
> Do you have a backend mechanism (e.g., Firebase Remote Config or a custom admin panel) ready to serve a new `coinsPerRupee` field in the config JSON payload? The app will look for this key and default to `100` if it's not found.

## Proposed Changes

### Configuration Layer

#### [MODIFY] [config_service.dart](file:///E:/development/SikkaPlay/lib/core/config/config_service.dart)
- Update `AppConfigState` to expose a convenient getter `int get coinsPerRupee => config?['coinsPerRupee'] ?? 100;`. This provides a central, safe default for the entire app.

### Wallet & Withdrawal

#### [MODIFY] [wallet_screen.dart](file:///E:/development/SikkaPlay/lib/features/wallet/screens/wallet_screen.dart)
- Fetch `coinsPerRupee` from `appConfigProvider`.
- Replace `minLimit ~/ 100` with `minLimit ~/ coinsPerRupee`.
- Replace hardcoded `100` in `_showSuccessSheet` call to `coinsAmount ~/ coinsPerRupee`.

### UI & Support

#### [MODIFY] [support_screen.dart](file:///E:/development/SikkaPlay/lib/features/profile/screens/support_screen.dart)
- Inject `appConfigProvider` into the `SupportScreen` state to access `coinsPerRupee`.
- Dynamically format the FAQ string about withdrawal limits to display the dynamic `coinsPerRupee` value instead of hardcoding `100`.

## Verification Plan

### Automated Tests
- Static analysis via `flutter analyze` to ensure no syntax errors.

### Manual Verification
- We will test the app by simulating a config payload with `coinsPerRupee: 1000`.
- Verify the Wallet screen correctly displays ₹10 for a 10,000 coin limit.
- Verify the Support Screen correctly reads `(1000 Sikka = 1 Rupee)` in both English and Hindi FAQs.
