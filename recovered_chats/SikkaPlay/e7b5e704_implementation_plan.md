# Implement OTP Auth & Forgot Password Flow

This plan will address the issues with OTP authentication during registration and implement a working "Forgot Password" functionality.

## Proposed Changes

### Frontend (Flutter)

#### [MODIFY] [register_screen.dart](file:///e:/development/SikkaPlay/lib/features/auth/screens/register_screen.dart)
- Update the registration flow to include an OTP verification step.
- When the user taps "Register", we will first call `AuthService.sendOTP` using Firebase.
- We will show an OTP input modal (or dialog) to the user.
- Upon successful OTP verification, we will then call the backend `/register` API to complete the signup.

#### [NEW] [forgot_password_screen.dart](file:///e:/development/SikkaPlay/lib/features/auth/screens/forgot_password_screen.dart)
- Create a new screen to handle password resets.
- **Step 1:** Ask the user for their phone number.
- **Step 2:** Send an OTP using Firebase Auth.
- **Step 3:** User enters the OTP. Once verified, they will get a Firebase session token.
- **Step 4:** Ask the user for a new password.
- **Step 5:** Send the new password and Firebase token to the backend's `/forgot-password` API to update the database.

#### [MODIFY] [login_screen.dart](file:///e:/development/SikkaPlay/lib/features/auth/screens/login_screen.dart)
- Connect the "Forgot Password" button to navigate to the new `/forgot_password` route.

#### [MODIFY] [app_router.dart](file:///e:/development/SikkaPlay/lib/routes/app_router.dart)
- Add a new route `/forgot_password` that loads the `ForgotPasswordScreen`.

#### [MODIFY] [auth_service.dart](file:///e:/development/SikkaPlay/lib/core/auth/auth_service.dart)
- Add a new `resetPassword` method that sends the required Firebase JWT and new password to the backend `/api/auth/forgot-password` endpoint.

## Verification Plan

### Manual Verification
- Attempt to register a new user and ensure the OTP dialog appears and works correctly before calling the backend.
- Attempt to tap "Forgot Password" on the Login screen, verify the OTP, enter a new password, and ensure the backend accepts it.
- Log in with the newly set password.

> [!IMPORTANT]
> The OTP system relies on Firebase Phone Authentication. Please ensure that your Firebase project has Phone Authentication enabled and is properly configured for this app (including SHA-1/SHA-256 fingerprints for Android).
