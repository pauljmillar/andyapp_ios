//
//  ClerkAuthManager.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import Foundation
import SwiftUI
import Clerk

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
        checkCurrentUser()
    }
    
    // MARK: - Check Current User
    func checkCurrentUser() {
        if let user = Clerk.shared.user {
            // Convert Clerk User to our UserProfile
            let userProfile = UserProfile(
                id: user.id,
                email: user.emailAddresses.first?.emailAddress ?? "",
                firstName: user.firstName,
                lastName: user.lastName,
                avatarUrl: user.imageUrl,
                points: 1250, // Default points, should be fetched from your backend
                joinDate: user.createdAt,
                surveysCompleted: 8, // Default, should be fetched from your backend
                totalEarned: 2500 // Default, should be fetched from your backend
            )
            currentUser = userProfile
            isAuthenticated = true
        } else {
            currentUser = nil
            isAuthenticated = false
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
            totalEarned: 2500 // Default, should be fetched from your backend
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
                checkCurrentUser()
            } else {
                print("Sign-in incomplete. Status: \(signIn.status)")
            }
            
            isLoading = false
        } catch {
            isLoading = false
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
        
        // Refresh the current user data
        checkCurrentUser()
    }
    
    func clearError() {
        errorMessage = nil
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
