# Apple Sign-In TestFlight Debugging Guide

## Issue Summary

Apple Sign-In popup appears on real device (TestFlight), user approves with Face ID, but then the loading spinner disappears silently with no error message and no navigation.

**Key Observation**: Works fine on simulator, fails on real device.

---

## Root Cause Analysis

The silent failure after Face ID approval indicates a **backend token verification issue**. When the user approves:

1. ✅ Apple SDK returns a valid `identityToken`
2. ✅ Token is sent to backend at `/auth/client/apple` endpoint
3. ❌ Backend either rejects the token or returns an error
4. ❌ Error message is not properly displayed (or backend is timing out)

---

## What to Check

### 1. **Verify Backend Endpoint is Configured**

Ask your backend developer to confirm:

- [ ] Apple Sign-In endpoint `/auth/client/apple` exists and is properly configured
- [ ] The endpoint accepts POST requests with `idToken` and optional `user` data
- [ ] Backend is configured with Apple's authentication (Team ID, Key ID, Service ID)

### 2. **Check Backend Response**

The backend must return a proper error response (not crash/timeout):

**Example Success Response:**

```json
{
  "status": "success",
  "accessToken": "token_here",
  "refreshToken": "refresh_token_here",
  "client": {
    "id": "user_id",
    "email": "user@example.com",
    "role": "rider",
    "isVerified": true
  }
}
```

**Example Error Response:**

```json
{
  "status": "error",
  "message": "Invalid Apple token"
}
```

### 3. **Enable Console Logging**

Run the TestFlight app with console logging enabled:

```bash
# On connected device in Xcode
# Build and run with:
flutter run --verbose

# Look for these log patterns:
# AUTH_SERVICE: Attempting Apple Sign-In...
# AUTH_SERVICE: Apple endpoint: https://your-backend/auth/client/apple
# AUTH_SERVICE: Apple Sign-In response received - Status: XXX
# LOGIN_CONTROLLER: loginWithApple returned - Success: true/false
# LOGIN_CONTROLLER: Showing error snackbar: [ERROR_MESSAGE]
```

### 4. **Use Xcode Debugger**

If running on physical device via Xcode:

```swift
// AppDelegate.swift - Enable detailed logging
```

---

## Testing Steps

### For Lateef (Tester):

1. Run app on physical device (not simulator)
2. Go to login screen
3. Tap "Continue with Apple"
4. Approve with Face ID
5. **Watch for any error message at bottom of screen**
6. If error appears, screenshot it
7. If no error but screen goes back to login, report that

### For Julius (Developer):

1. **Check the logs** using the patterns above
2. **Look for these specific logs** after "Approve with Face ID":
   - `AUTH_SERVICE: Apple Sign-In response received - Status: XXX`
   - `LOGIN_CONTROLLER: loginWithApple returned - Success: true/false`
   - `LOGIN_CONTROLLER: Showing error snackbar: [MESSAGE]`

3. **If you see Status: 400 or 500**, the backend is rejecting the token
4. **If Status is 200 but success: false**, check `loginResponse.message`
5. **If no logs appear after Face ID**, there's a networking issue or timeout

---

## Common Issues & Solutions

### Issue 1: Backend Returns 401/403

**Solution**: Backend's Apple token verification is failing. Ensure backend has:

- Correct Apple Team ID
- Correct App Key ID
- Correct Service ID
- Bundle ID matches your iOS app's bundle ID

### Issue 2: Backend Returns 500

**Solution**: Backend service is crashing. Check backend logs for:

- Missing dependencies (e.g., Apple JWT verification library)
- Null pointer exceptions when processing token
- Timeout when contacting Apple's servers

### Issue 3: No Error Message Shows (Silent Failure)

**Solution**: This has been fixed in the latest update. The error message should now display:

```
Loading spinner disappears → Error snackbar appears with backend error message
```

If still not showing:

1. Check that `THelperFunctions.showErrorSnackBar()` is working
2. Try test error with email/password login to confirm snackbar works
3. Ensure error message is not empty (see log: `Showing error snackbar: [MESSAGE]`)

### Issue 4: Network Timeout

**Solution**: If log shows connection timeout:

- Check device internet connection
- Check backend server status
- Ensure backend can reach Apple's verification servers

---

## Debug Checklist for Each Attempt

Copy this for each test run:

```
🔍 Apple Sign-In Test Run - [Date/Time]

Device: [Simulator / Physical Device]
iOS Version: [e.g., 17.0]
App Version: [TestFlight version]

✓ Popup showed: YES / NO
✓ Face ID appeared: YES / NO
✓ After Face ID approved:
  - Loading spinner: YES / NO
  - Loading spinner disappeared: YES / NO
  - Error message appeared: YES / NO
  - Error message text: [COPY HERE]
  - Back to login screen: YES / NO

Console Logs to Check:
□ Found "AUTH_SERVICE: Attempting Apple Sign-In..."
□ Found "AUTH_SERVICE: Apple Sign-In response received - Status: XXX"
□ Found "LOGIN_CONTROLLER: Showing error snackbar: ..."
□ Status code was: _____ (200? 400? 500?)

Conclusion:
[ ] Works correctly
[ ] Failed with error message visible: ___________
[ ] Failed silently (no error message): Status was ____
```

---

## Next Steps

1. **First**, Lateef should run the app and check for error messages
2. **Share screenshot** of any error message that appears
3. **Share console logs** with the patterns mentioned above
4. **Julius** should check backend logs to see what's happening on server side
5. **Verify** backend is properly configured for Apple Sign-In
6. Once backend error is found, fix it and **push new build to TestFlight**

---

## Backend Implementation Checklist

Your backend needs:

```
✓ Route: POST /auth/client/apple
✓ Accept: { "idToken": "...", "user": { "email": "...", "name": {...} } }
✓ Verify Apple JWT token against Apple's servers
✓ Check token signature and expiration
✓ Extract user identifier from token
✓ Find or create user in database
✓ Generate access token and refresh token
✓ Return LoginResponse with user data
✓ Handle errors gracefully (not crash/timeout)
✓ Return proper error messages in 400-level responses
```

---

## Helpful Links

- [sign_in_with_apple Flutter package](https://pub.dev/packages/sign_in_with_apple)
- [Apple Sign-In backend verification guide](https://developer.apple.com/documentation/sign_in_with_apple/authenticating_users_through_sign_in_with_apple)
- [Common Apple Sign-In issues](https://stackoverflow.com/questions/tagged/sign-in-with-apple)
