# Apple Sign-In Test & Verification Guide

## Changes Made to Fix Silent Failure

The following improvements have been implemented to ensure errors in Apple Sign-In are always visible:

1. **Enhanced Logging** - All Apple Sign-In steps are now logged with prefix `AUTH_SERVICE` and `LOGIN_CONTROLLER`
2. **Better Error Messages** - If backend returns empty error message, a meaningful fallback error is shown
3. **HTTP Status Handling** - Specific error messages for 401/403/500/503 status codes
4. **Response Debugging** - Full backend response body is logged to console

---

## Pre-TestFlight Testing Checklist

Before pushing to TestFlight, verify these on a real device:

### ✅ Test 1: Simulator - Successful Login

```bash
cd sarri_ride\ copy\ 3
flutter run
```

1. Go to Login screen
2. Tap "Continue with Apple"
3. Sign in with simulator Apple ID
4. **Expected**: App navigates to map/dashboard screen
5. **Check logs for**: `AUTH_SERVICE: Apple Sign-In successful`

### ✅ Test 2: Real Device - Successful Login (if available)

1. Connect real iOS device via Xcode
2. Run: `flutter run --verbose`
3. Go to Login screen, tap "Continue with Apple"
4. Approve with Face ID
5. **Expected**: App navigates successfully
6. **Check terminal logs** for Apple Sign-In success

### ✅ Test 3: Test Error Handling (Simulator)

To simulate a backend error, temporarily modify the backend response:

**Option A: Using Mock Response**

1. In `auth_service.dart`, temporarily add after line 285:

```dart
// TEMPORARY DEBUG - Remove before production
if (identityToken.contains('test')) {
  return AuthResult.error('Simulated backend error - Invalid Apple token');
}
```

2. Attempt Apple Sign-In with simulator
3. **Expected**: Error message appears and is visible to user
4. **Remove the temporary code after testing**

**Option B: Check Console Logs**
After running Apple Sign-In on device:

```bash
# Look for these logs in terminal/Xcode console:
AUTH_SERVICE: Attempting Apple Sign-In...
AUTH_SERVICE: Apple endpoint: https://...
AUTH_SERVICE: Apple Sign-In response received - Status: XXX
AUTH_SERVICE: Apple Sign-In successful - User: user@example.com
# OR
AUTH_SERVICE: Apple Sign-In failed - Error: [ERROR MESSAGE]
```

### ✅ Test 4: Verify Loading Spinner Behavior

1. Start Apple Sign-In flow
2. **Before Face ID**: Loading spinner should show
3. **After approving Face ID**:
   - ✅ Should see either success navigation OR error message
   - ❌ Loading spinner should NOT disappear silently
4. **Expected**: No more silent failures

### ✅ Test 5: Test with Real Backend

If your backend is updated and running:

1. Update `ApiConfig` to point to your backend
2. Run on real device: `flutter run --verbose`
3. Go through full Apple Sign-In flow
4. Check console logs for:
   - Request being sent to backend
   - Response status code
   - Response body
   - Success/error result

---

## Testing Checklist for Lateef (QA)

Share this with your tester after updating TestFlight:

### ✅ Scenario 1: Successful Login (Expected to Work)

- [ ] Tap "Continue with Apple"
- [ ] Face ID appears and approve
- [ ] App loads map screen / dashboard
- [ ] User is logged in

### ✅ Scenario 2: Backend Error (Should See Error Message Now)

If backend is not properly configured:

- [ ] Tap "Continue with Apple"
- [ ] Face ID appears and approve
- [ ] **Error message should appear** (this was the bug - it was silent before)
- [ ] Message explains what went wrong
- [ ] Can tap back and try again

### ✅ Scenario 3: Device Internet Issues

- [ ] Turn off WiFi, use cellular only (poor signal)
- [ ] Attempt Apple Sign-In
- [ ] Should see timeout/connection error message
- [ ] Error should be visible, not silent

### Screenshot Requirements

For each test, take screenshots of:

1. Login screen with Apple button visible
2. Face ID prompt
3. After Face ID: Either success screen OR error message
4. **Don't** let it be a blank screen

---

## Debugging Commands

### View Console Logs in Xcode

```bash
# Run on real device and watch console
flutter run --verbose 2>&1 | grep -E "AUTH_SERVICE|LOGIN_CONTROLLER|Apple"

# Or open Xcode directly
# Window → Devices and Simulators → [Your Device] → View Device Logs
```

### Extract Logs to File

```bash
# Run Apple Sign-In and save logs
flutter run --verbose 2>&1 | tee apple_signin_logs.txt

# Share the logs file with the team
```

---

## What to Do If It Still Doesn't Work

### Still Silent Failure (No Error Message)?

1. **Check console logs** - Does it show `AUTH_SERVICE: Apple Sign-In failed`?
2. **If yes**: Error is being thrown but not displayed - File bug in helper functions
3. **If no**: Error is happening differently - Add more debug prints

### Error Message Shows Wrong Status Code?

```
Example: "Status 503 - Service Unavailable" but backend is working
```

1. Check backend is actually running
2. Check backend endpoint is correct in `ApiConfig.appleAuthEndpoint`
3. Check device can reach backend URL (test with curl)

### Backend Returns 401/403?

This means token verification failed. Backend developer should check:

- [ ] Apple (Team ID, Key ID, Service ID) configured correctly
- [ ] Bundle ID matches iOS app's bundle ID
- [ ] Backend can reach Apple's verification servers
- [ ] Token hasn't expired (Apple tokens have ~5 min expiry)

---

## Success Criteria

After these changes, Apple Sign-In should:

✅ Show loading spinner while processing  
✅ Show error message if backend rejects  
✅ Show error message if network fails  
✅ Show error message if server error (5xx)  
✅ Never silently disappear  
✅ All errors logged with "AUTH_SERVICE:" prefix

---

## Push to TestFlight

Once all local testing passes:

```bash
# Build and upload to TestFlight
cd sarri_ride\ copy\ 3

# Increment version (if needed)
# Edit ios/Runner.xcodeproj or pubspec.yaml version

# Run build
flutter build ios --release

# Upload to App Store Connect
# Use Xcode or fastlane
```

Then share with Lateef with these instructions:

1. Update TestFlight app
2. Go through "Scenario 1" and "Scenario 2" tests above
3. Report any issues directly with screenshots + console logs
4. If successful, approve for release

---

## Rollback Plan

If issues occur after TestFlight release:

1. This version has better logging, so we can see what's happening
2. Share console logs from reporter
3. Fix the actual issue (likely backend related)
4. Push new build to TestFlight

We now have full visibility into the error, so we can diagnose quickly. 📊
