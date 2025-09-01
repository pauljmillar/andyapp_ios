# Clerk SDK Integration Setup

## Adding Clerk SDK to Xcode Project

1. **Open your Xcode project**
2. **Add Package Dependency:**
   - In Xcode, go to `File` → `Add Package Dependencies...`
   - Enter the Clerk SDK URL: `https://github.com/clerkinc/clerk-sdk-ios`
   - Click `Add Package`
   - Select your target (AndyApp) when prompted

## Configuration

The Clerk SDK has been configured with your provided credentials:

- **Publishable Key**: `pk_test_cmVhZHktYWFyZHZhcmstMTQuY2xlcmsuYWNjb3VudHMuZGV2JA`
- **Frontend URL**: `https://ready-aardvark-14.clerk.accounts.dev`
- **JWKS URL**: `https://ready-aardvark-14.clerk.accounts.dev/.well-known/jwks.json`

## Files Created/Modified

### New Files:
- `ClerkAuthManager.swift` - New authentication manager using Clerk SDK

### Modified Files:
- `AndyAppApp.swift` - Updated to use ClerkAuthManager
- `MainTabView.swift` - Updated to use ClerkAuthManager
- `HomeView.swift` - Updated to use ClerkAuthManager
- `RedeemView.swift` - Updated to use ClerkAuthManager

## Features Implemented

✅ **Sign In/Sign Up Flow**
- Email and password authentication
- User registration with first/last name
- Form validation
- Error handling

✅ **Session Management**
- Automatic session checking on app launch
- Secure session storage
- Session revocation on sign out

✅ **User Profile Integration**
- Clerk user data mapped to app UserProfile
- Integration with existing app structure
- Backend API token management

## Usage

The app now uses Clerk for authentication instead of the mock authentication. Users can:

1. **Sign In** with email and password
2. **Create Account** with email, password, and optional name fields
3. **Sign Out** from the profile menu
4. **Automatic session restoration** when reopening the app

## Next Steps

1. **Add Clerk SDK dependency** to your Xcode project
2. **Test the authentication flow**
3. **Integrate with your backend API** using Clerk session tokens
4. **Customize the UI** as needed

## Backend Integration

To integrate with your backend API:

1. Get the session token from Clerk: `Clerk.shared.session?.token`
2. Include this token in your API requests as a Bearer token
3. Verify the token on your backend using the JWKS endpoint
4. Map Clerk user data to your backend user model

## Security

- Clerk handles all authentication securely
- Session tokens are managed automatically
- JWKS verification ensures token authenticity
- No sensitive data stored locally
