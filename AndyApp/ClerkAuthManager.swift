//
//  ClerkAuthManager.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import Foundation
import SwiftUI
import Clerk
import GoogleSignIn


// MARK: - Clerk Authentication Manager
@MainActor
final class ClerkAuthManager: ObservableObject {
    static let shared = ClerkAuthManager()
    
    @Published var currentUser: UserProfile?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    private init() {
        // Configure Clerk with your publishable key
        Clerk.shared.configure(publishableKey: "pk_test_cmVhZHktYWFyZHZhcmstMTQuY2xlcmsuYWNjb3VudHMuZGV2JA")
        
        // Check for existing session first
        Task {
            await checkExistingSession()
        }
    }
    
    // MARK: - Check Existing Session
    private func checkExistingSession() async {
        // Check if there's already an active session
        if let session = Clerk.shared.session, let user = session.user {
            print("Found existing session for user: \(user.emailAddresses.first?.emailAddress ?? "unknown")")
            
            // Convert Clerk User to our UserProfile with default values
            let userProfile = UserProfile(
                id: user.id,
                email: user.emailAddresses.first?.emailAddress ?? "",
                firstName: user.firstName,
                lastName: user.lastName,
                avatarUrl: user.imageUrl,
                points: 0, // Will be updated from API
                joinDate: user.createdAt,
                surveysCompleted: 0, // Will be updated from API
                totalEarned: 0, // Will be updated from API
                totalRedeemed: 0, // Will be updated from API
                totalScans: 0 // Will be updated from API
            )
            
            await MainActor.run {
                currentUser = userProfile
                isAuthenticated = true
            }
            
            // Fetch panelist profile data
            await fetchPanelistProfile()
        } else {
            print("No existing session found")
            await MainActor.run {
                currentUser = nil
                isAuthenticated = false
            }
        }
    }
    
    // MARK: - Check Current User (Legacy method for compatibility)
    func checkCurrentUser() {
        Task {
            await checkExistingSession()
        }
    }
    
    // MARK: - Generate JWT Token
    func generateJWTToken() async throws -> String {
        guard let session = Clerk.shared.session else {
            print("❌ No session found - user not authenticated")
            throw APIError.unauthorized
        }
        
        print("🔑 Session found - ID: \(session.id)")
        print("🔑 Session user ID: \(session.user?.id ?? "unknown")")
        print("🔑 Session user email: \(session.user?.emailAddresses.first?.emailAddress ?? "unknown")")
        
        // Get proper JWT token using session.getToken()
        print("🔑 Requesting JWT token from session...")
        guard let tokenResource = try await session.getToken() else {
            print("❌ No token resource returned from session.getToken()")
            throw APIError.unauthorized
        }
        
        let jwtToken = tokenResource.jwt
        print("🔑 JWT token received: \(jwtToken)")
        
        return jwtToken
    }
    
    // MARK: - Fetch Panelist Profile
    func fetchPanelistProfile() async {
        guard isAuthenticated else { 
            print("❌ Not authenticated, skipping panelist profile fetch")
            return 
        }
        
        print("🔄 Starting panelist profile fetch...")
        
        do {
            // Generate JWT token
            print("🔑 Generating JWT token...")
            let token = try await generateJWTToken()
            
            // Set token in API service
            print("🔑 Setting auth token in API service...")
            print("🔑 Token being set: \(token)")
            apiService.setAuthToken(token)
            
            // Fetch panelist profile
            print("🌐 Making API call to /api/auth/panelist-profile...")
            let panelistProfile = try await apiService.fetchPanelistProfile()
                .async()
            
            print("✅ Panelist profile received successfully!")
            print("📊 Points Balance: \(panelistProfile.pointsBalance)")
            print("📊 Total Earned: \(panelistProfile.totalPointsEarned)")
            print("📊 Total Redeemed: \(panelistProfile.totalPointsRedeemed)")
            print("📊 Surveys Completed: \(panelistProfile.surveysCompleted)")
            print("📊 Total Scans: \(panelistProfile.totalScans)")
            
            // Update current user with real data
            if let currentUser = currentUser {
                let updatedUser = UserProfile(
                    id: currentUser.id,
                    email: currentUser.email,
                    firstName: currentUser.firstName,
                    lastName: currentUser.lastName,
                    avatarUrl: currentUser.avatarUrl,
                    points: panelistProfile.pointsBalance,
                    joinDate: currentUser.joinDate,
                    surveysCompleted: panelistProfile.surveysCompleted,
                    totalEarned: panelistProfile.totalPointsEarned,
                    totalRedeemed: panelistProfile.totalPointsRedeemed,
                    totalScans: panelistProfile.totalScans
                )
                
                await MainActor.run {
                    self.currentUser = updatedUser
                    print("✅ User profile updated with API data")
                }
            }
            
        } catch {
            print("❌ Error fetching panelist profile: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error description: \(error.localizedDescription)")
            
            // Keep using default values if API call fails
        }
    }
    
    private func handleClerkSession(_ session: Session) {
        guard let user = session.user else {
            isAuthenticated = false
            currentUser = nil
            return
        }
        
        // Convert Clerk user to our UserProfile
        let userProfile = UserProfile(
            id: user.id,
            email: user.emailAddresses.first?.emailAddress ?? "",
            firstName: user.firstName,
            lastName: user.lastName,
            avatarUrl: user.imageUrl,
            points: 1250, // Default points, should be fetched from your backend
            joinDate: user.createdAt,
            surveysCompleted: 8, // Default, should be fetched from your backend
            totalEarned: 2500, // Default, should be fetched from your backend
            totalRedeemed: 0, // Default, should be fetched from your backend
            totalScans: 0 // Default, should be fetched from your backend
        )
        
        currentUser = userProfile
        isAuthenticated = true
        
        // Fetch user data from your backend
        refreshUserProfile()
    }
    
    // MARK: - Sign In with Email & Password
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let signIn = try await SignIn.create(strategy: .identifier(email, password: password))
            
            if signIn.status == .complete {
                await checkExistingSession()
            } else {
                print("Sign-in incomplete. Status: \(signIn.status)")
            }
            
            isLoading = false
        } catch {
            isLoading = false
            
            // Handle "session exists" error gracefully
            if error.localizedDescription.contains("Session already exists") || 
               error.localizedDescription.contains("already signed in") {
                print("Session already exists, checking current session...")
                await checkExistingSession()
                return // Don't throw error, just proceed
            }
            
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Sign Up with Email & Password
    func signUp(email: String, password: String, firstName: String?, lastName: String?) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            var signUp = try await SignUp.create([
                "email_address": email,
                "password": password
            ])
            
            // Optional: Update user profile fields after creating sign-up
            if let firstName = firstName, !firstName.isEmpty {
                let updateParams = SignUp.UpdateParams(firstName: firstName)
                signUp = try await signUp.update(params: updateParams)
            }
            if let lastName = lastName, !lastName.isEmpty {
                let updateParams = SignUp.UpdateParams(lastName: lastName)
                signUp = try await signUp.update(params: updateParams)
            }
            
            if signUp.status == .complete {
                checkCurrentUser()
            } else if signUp.status == .missingRequirements {
                print("Sign-up missing requirements.")
            } else {
                print("Sign-up incomplete. Status: \(signUp.status)")
            }
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Sign Out
    func signOut() async {
        do {
            try await Clerk.shared.signOut()
            currentUser = nil
            isAuthenticated = false
            errorMessage = nil
        } catch {
            print("Sign-out error: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    func refreshUserProfile() {
        guard isAuthenticated else { return }
        
        // Fetch fresh panelist profile data
        Task {
            await fetchPanelistProfile()
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Sign In with Google - DISABLED FOR DEVELOPMENT
    // TODO: Re-enable when app is published to App Store
    func signInWithGoogle() async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get the root view controller for Google Sign-In presentation
            guard let rootViewController = await getRootViewController() else {
                throw NSError(domain: "GoogleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not get root view controller"])
            }
            
            // Start the Google Sign-In flow using Google Sign-In SDK
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw NSError(domain: "GoogleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not get Google ID token"])
            }
            
            print("✅ Google Sign-In successful, ID token received")
            
            // For now, let's just check if we have a session after Google Sign-In
            // The Google Sign-In SDK should have handled the authentication
            await checkExistingSession()
            print("✅ Google Sign-In completed, checking session...")
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            print("❌ Google Sign-In failed: \(error)")
            throw error
        }
    }
    
    // Helper method to get Google Client ID from Info.plist
    private func getGoogleClientID() -> String? {
        guard let path = Bundle.main.path(forResource: "GoogleSignIn-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientID = plist["GIDClientID"] as? String else {
            return nil
        }
        return clientID
    }
    
    // Helper method to get root view controller
    private func getRootViewController() async -> UIViewController? {
        return await MainActor.run {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                return nil
            }
            return window.rootViewController
        }
    }

}

// MARK: - Clerk Authentication Views
struct ClerkSignInView: View {
    @StateObject private var authManager = ClerkAuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                // Logo/Title
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.primaryGreen)
                    
                    Text("Survey Rewards")
                        .font(AppTypography.largeTitle)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Complete surveys and earn points")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppSpacing.xxl)
                
                // Sign In Form
                VStack(spacing: AppSpacing.lg) {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Email")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Password")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .font(AppTypography.footnote)
                            .foregroundColor(AppColors.error)
                            .padding(.horizontal)
                    }
                    
                    Button(action: {
                        Task {
                            do {
                                try await authManager.signIn(email: email, password: password)
                            } catch {
                                // Error is already handled in the authManager
                            }
                        }
                    }) {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign In")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
                }
                .padding(.horizontal, AppSpacing.xl)
                
                // Google Sign-In Button - HIDDEN FOR DEVELOPMENT
                // TODO: Re-enable when app is published to App Store
                /*
                VStack(spacing: AppSpacing.md) {
                    HStack {
                        Rectangle()
                            .fill(AppColors.textSecondary.opacity(0.3))
                            .frame(height: 1)
                        Text("or")
                            .font(AppTypography.caption2)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, AppSpacing.sm)
                        Rectangle()
                            .fill(AppColors.textSecondary.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    
                    Button(action: {
                        Task {
                            do {
                                try await authManager.signInWithGoogle()
                            } catch {
                                // Error is already handled in the authManager
                            }
                        }
                    }) {
                        // Official Google Sign-In button
                        Image("GoogleSignInContinue")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(authManager.isLoading)
                    .padding(.horizontal, AppSpacing.xl)
                }
                */
                
                // Sign Up Link
                HStack {
                    Text("Don't have an account?")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Button("Sign Up") {
                        showingSignUp = true
                    }
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.primaryGreen)
                }
                
                Spacer()
            }
            .background(AppColors.background)
            .sheet(isPresented: $showingSignUp) {
                ClerkSignUpView()
            }
        }
    }
}

struct ClerkSignUpView: View {
    @StateObject private var authManager = ClerkAuthManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                // Header
                VStack(spacing: AppSpacing.md) {
                    Text("Create Account")
                        .font(AppTypography.largeTitle)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Join our survey community")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppSpacing.lg)
                
                // Sign Up Form
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("First Name")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("Enter your first name", text: $firstName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Last Name")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("Enter your last name", text: $lastName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Email")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Password")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Confirm Password")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            SecureField("Confirm your password", text: $confirmPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        if let errorMessage = authManager.errorMessage {
                            Text(errorMessage)
                                .font(AppTypography.footnote)
                                .foregroundColor(AppColors.error)
                                .padding(.horizontal)
                        }
                        
                        Button(action: {
                            Task {
                                do {
                                    try await authManager.signUp(
                                        email: email,
                                        password: password,
                                        firstName: firstName.isEmpty ? nil : firstName,
                                        lastName: lastName.isEmpty ? nil : lastName
                                    )
                                } catch {
                                    // Error is already handled in the authManager
                                }
                            }
                        }) {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Create Account")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!isFormValid || authManager.isLoading)
                    }
                    .padding(.horizontal, AppSpacing.xl)
                }
                
                // Google Sign-In Button - HIDDEN FOR DEVELOPMENT
                // TODO: Re-enable when app is published to App Store
                /*
                VStack(spacing: AppSpacing.md) {
                    HStack {
                        Rectangle()
                            .fill(AppColors.textSecondary.opacity(0.3))
                            .frame(height: 1)
                        Text("or")
                            .font(AppTypography.caption2)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, AppSpacing.sm)
                        Rectangle()
                            .fill(AppColors.textSecondary.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    
                    Button(action: {
                        Task {
                            do {
                                try await authManager.signInWithGoogle()
                            } catch {
                                // Error is already handled in the authManager
                            }
                        }
                    }) {
                        // Official Google Sign-Up button
                        Image("GoogleSignInSignUp")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(authManager.isLoading)
                    .padding(.horizontal, AppSpacing.xl)
                }
                */
                
                Spacer()
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primaryGreen)
                }
            }
            .onReceive(authManager.$isAuthenticated) { isAuthenticated in
                if isAuthenticated {
                    dismiss()
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && 
        !password.isEmpty && 
        password == confirmPassword && 
        password.count >= 6
    }
}
