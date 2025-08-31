//
//  AuthManager.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import Foundation
import Combine
import SwiftUI

// MARK: - Authentication Manager
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Check for existing auth token on app launch
        checkExistingAuth()
    }
    
    // MARK: - Authentication State Management
    private func checkExistingAuth() {
        // TEMPORARY: For development, start authenticated
        // In a real app, you'd check for stored auth token
        isAuthenticated = true
        currentUser = UserProfile(
            id: "dev-user-1",
            email: "dev@example.com",
            firstName: "Developer",
            lastName: "User",
            avatarUrl: nil,
            points: 1250,
            joinDate: Date(),
            surveysCompleted: 8,
            totalEarned: 2500
        )
    }
    
    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        apiService.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] authResponse in
                    self?.handleSuccessfulAuth(authResponse)
                }
            )
            .store(in: &cancellables)
    }
    
    func signUp(email: String, password: String, firstName: String?, lastName: String?) {
        isLoading = true
        errorMessage = nil
        
        apiService.register(email: email, password: password, firstName: firstName, lastName: lastName)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] authResponse in
                    self?.handleSuccessfulAuth(authResponse)
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleSuccessfulAuth(_ authResponse: AuthResponse) {
        // Store auth token
        apiService.setAuthToken(authResponse.token)
        
        // Update user profile
        currentUser = authResponse.user
        isAuthenticated = true
        
        // Store auth data securely (in a real app, use Keychain)
        UserDefaults.standard.set(authResponse.token, forKey: "authToken")
        UserDefaults.standard.set(authResponse.refreshToken, forKey: "refreshToken")
    }
    
    func signOut() {
        // Clear auth data
        apiService.clearAuthToken()
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        
        // Reset state
        isAuthenticated = false
        currentUser = nil
        errorMessage = nil
    }
    
    func refreshUserProfile() {
        guard isAuthenticated else { return }
        
        apiService.getUserProfile()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                        // If unauthorized, sign out
                        if case .unauthorized = error {
                            self?.signOut()
                        }
                    }
                },
                receiveValue: { [weak self] userProfile in
                    self?.currentUser = userProfile
                }
            )
            .store(in: &cancellables)
    }
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Authentication Views
struct SignInView: View {
    @StateObject private var authManager = AuthManager.shared
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
                        authManager.signIn(email: email, password: password)
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
                SignUpView()
            }
        }
    }
}

struct SignUpView: View {
    @StateObject private var authManager = AuthManager.shared
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
                            authManager.signUp(
                                email: email,
                                password: password,
                                firstName: firstName.isEmpty ? nil : firstName,
                                lastName: lastName.isEmpty ? nil : lastName
                            )
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
