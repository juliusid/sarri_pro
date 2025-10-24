# API Integration Guide for Sarri Ride

This guide explains how to integrate your backend API with the Sarri Ride Flutter app.

## 🚀 What's Been Implemented

### 1. **HTTP Service** (`lib/core/services/http_service.dart`)
- Centralized HTTP client with authentication
- Automatic token management (access + refresh tokens)
- Retry logic with exponential backoff
- Error handling and response parsing
- Token refresh on 401 responses

### 2. **API Configuration** (`lib/config/api_config.dart`)
- Environment-based configuration (dev/staging/prod)
- Centralized endpoint definitions
- Timeout and header configuration

### 3. **Authentication Service** (`lib/features/authentication/services/auth_service.dart`)
- Login/logout functionality
- Token storage and management
- User data conversion from API to app models

### 4. **Authentication Models** (`lib/features/authentication/models/auth_model.dart`)
- Request/response models for auth endpoints
- User data models compatible with your API

## ⚙️ Configuration Steps

### Step 1: Update API Base URLs
Edit `lib/config/api_config.dart` and replace the placeholder URLs:

```dart
static const String _devBaseUrl = 'https://your-dev-api.com';
static const String _stagingBaseUrl = 'https://your-staging-api.com';
static const String _prodBaseUrl = 'https://your-production-api.com';
```

### Step 2: Update API Endpoints
If your API uses different endpoint paths, update them in `lib/config/api_config.dart`:

```dart
// Example: if your login endpoint is /api/v1/users/signin
static String get loginEndpoint => '$apiUrl/users/signin';
```

### Step 3: Update API Response Format
If your API returns data in a different format, update the parsing in `lib/features/authentication/models/auth_model.dart`.

## 🔐 Expected API Response Format

### Login Response
Your login endpoint should return JSON in this format:

```json
{
  "success": true,
  "message": "Login successful",
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "user": {
    "id": "user_123",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "phone_number": "+1234567890",
    "user_type": "rider",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z",
    "profile": {
      "rating": 4.8,
      "total_trips": 25,
      "saved_places": ["Home", "Work"],
      "emergency_contact": "+1234567890"
    }
  }
}
```

### Error Response
For errors, return:

```json
{
  "success": false,
  "message": "Invalid credentials",
  "status": 401
}
```

## 🧪 Testing the Integration

### 1. **Update API URLs**
First, update the base URLs in `lib/config/api_config.dart` with your actual API endpoints.

### 2. **Test Login**
- Run the app
- Try logging in with valid credentials
- Check the console for any error messages
- Verify that tokens are stored and user data is parsed correctly

### 3. **Check Network Requests**
Use Flutter DevTools or your browser's network tab to verify:
- Correct API endpoints are being called
- Request headers include proper content-type
- Response data matches expected format

## 🔧 Troubleshooting

### Common Issues

#### 1. **Network Error**
- Check if your API is accessible from the device/emulator
- Verify base URLs are correct
- Check firewall/network settings

#### 2. **Authentication Failed**
- Verify API endpoint paths
- Check request payload format
- Ensure API returns expected response format

#### 3. **Token Issues**
- Verify token storage in GetStorage
- Check if refresh token endpoint is working
- Ensure token format matches expected (Bearer token)

#### 4. **User Data Parsing Errors**
- Check console for parsing errors
- Verify API response structure matches models
- Update parsing logic if needed

### Debug Mode
Enable debug logging by adding this to your app:

```dart
// In main.dart or app initialization
if (kDebugMode) {
  print('API Base URL: ${ApiConfig.baseUrl}');
  print('Login Endpoint: ${ApiConfig.loginEndpoint}');
}
```

## 📱 Next Steps

### 1. **Complete Authentication Flow**
- Implement registration
- Add password reset functionality
- Handle social login if needed

### 2. **Replace More Demo Data**
- Ride booking endpoints
- User profile management
- Payment integration
- Driver location updates

### 3. **Add Error Handling**
- Network connectivity checks
- User-friendly error messages
- Retry mechanisms for failed requests

### 4. **Security Enhancements**
- Secure token storage (flutter_secure_storage)
- Certificate pinning for production
- API key management

## 📚 Files to Modify

- `lib/config/api_config.dart` - API endpoints and configuration
- `lib/features/authentication/models/auth_model.dart` - Response parsing
- `lib/features/authentication/services/auth_service.dart` - Business logic
- `lib/core/services/http_service.dart` - HTTP client configuration

## 🆘 Need Help?

If you encounter issues:

1. Check the console for error messages
2. Verify API endpoints are accessible
3. Ensure response format matches expected models
4. Test with a simple API client (Postman, curl) first

## 🔄 Demo Mode Toggle

To easily switch between demo and real API, you can add a flag:

```dart
// In lib/config/api_config.dart
static const bool useDemoMode = false; // Set to false for production

// In services, check this flag
if (ApiConfig.useDemoMode) {
  // Use demo data
} else {
  // Use real API
}
```

This allows you to quickly test both modes during development.
