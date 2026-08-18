# Authentication Updates Walkthrough

I have successfully updated the app to fix the registration OTP flow and implemented the Forgot Password functionality.

## Changes Made

### 1. OTP Authentication for Registration
The `RegisterScreen` now handles phone verification securely through Firebase before registering the user on the backend.
- Replaced the direct registration call with `AuthService.sendOTP`.
- Added dynamic state in the UI so that once the OTP is sent, the user can input their OTP to verify.
- After successful verification via `AuthService.verifyOTP`, the final `AuthService.register` call is executed.
- Added a "Change Phone Number" button during OTP entry if the user made a mistake.

### 2. Forgot Password Flow
Created a brand new `ForgotPasswordScreen` and hooked it into the existing `LoginScreen`.
- **Step 1**: The user enters their phone number to receive an OTP.
- **Step 2**: The user enters the OTP they received via SMS to verify ownership.
- **Step 3**: The user inputs a new password, which is securely transmitted to the backend alongside a Firebase authentication token to reset the password.

### 3. Backend Integrations (`auth_service.dart`)
- **`verifyOTP`**: We added the ability to securely verify an OTP inside the Flutter app.
- **`resetPassword`**: Integrated with the `/api/auth/forgot-password` endpoint.

### 4. Routing
- The `app_router.dart` file has been updated to add the `/forgot_password` route.
- The route is excluded from interstitial ads to maintain a seamless authentication flow.

## Verification
- You can test the application directly. When you navigate to the register page, enter a phone number and you should receive an OTP. 
- Try testing the "Forgot Password" functionality from the login screen. It will take you to the new flow.

> [!NOTE]
> Please ensure that Firebase Phone Authentication is fully enabled in your Firebase Console and that you have added the necessary SHA-1 / SHA-256 fingerprints if you're testing on a real Android device.
