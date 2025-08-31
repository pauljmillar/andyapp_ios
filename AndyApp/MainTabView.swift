//
//  MainTabView.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var selectedTab = 0
    @State private var showingProfileMenu = false
    @State private var selectedFilter: String?
    
    var body: some View {
        ZStack {
            // Main Content
            VStack(spacing: 0) {
                // Top Navigation Bar
                TopNavigationView(
                    title: tabTitle,
                    showProfileMenu: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingProfileMenu.toggle()
                        }
                    },
                    showNotifications: {
                        // Placeholder for notifications
                    },
                    filterCategories: filterCategories,
                    selectedFilter: $selectedFilter
                )
                
                // Main Tab View
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Home")
                        }
                        .tag(0)
                    
                    SurveyView()
                        .tabItem {
                            Image(systemName: "doc.text.fill")
                            Text("Survey")
                        }
                        .tag(1)
                    
                    MailView()
                        .tabItem {
                            Image(systemName: "envelope.fill")
                            Text("Mail")
                        }
                        .tag(2)
                    
                    RedeemView()
                        .tabItem {
                            Image(systemName: "gift.fill")
                            Text("Redeem")
                        }
                        .tag(3)
                }
                .accentColor(AppColors.primaryGreen)
                .onAppear {
                    // Set tab bar appearance to black background
                    let appearance = UITabBarAppearance()
                    appearance.configureWithOpaqueBackground()
                    appearance.backgroundColor = UIColor.black
                    UITabBar.appearance().standardAppearance = appearance
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }
            }
            .background(AppColors.background)
            
            // Profile Menu Overlay - Now properly positioned as an overlay
            if showingProfileMenu {
                ProfileMenuView(isShowing: $showingProfileMenu)
                    .transition(.move(edge: .leading))
                    .zIndex(1000)
                    .ignoresSafeArea()
            }
        }
    }
    
    private var tabTitle: String {
        switch selectedTab {
        case 0: return "Home"
        case 1: return "Survey"
        case 2: return "Mail"
        case 3: return "Redeem"
        default: return "Home"
        }
    }
    
    private var filterCategories: [String] {
        switch selectedTab {
        case 0: return ["Technology", "Health", "Finance", "Entertainment", "Lifestyle"]
        case 1: return ["Technology", "Health", "Finance", "Entertainment", "Education", "Lifestyle"]
        case 2: return ["Important", "Unread", "System", "Updates"]
        case 3: return ["Gift Cards", "Merchandise", "Donations", "Experiences"]
        default: return []
        }
    }
}

// MARK: - Profile Menu View
struct ProfileMenuView: View {
    @Binding var isShowing: Bool
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isShowing = false
                    }
                }
            
                        // Menu content
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    // Profile header
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        // Add top padding to avoid system status bar
                        Spacer()
                            .frame(height: 50)
                        HStack {
                            // Profile image
                            Circle()
                                .fill(AppColors.profileBlue)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text(authManager.currentUser?.displayName.prefix(1).uppercased() ?? "U")
                                        .font(AppTypography.title2)
                                        .foregroundColor(.black)
                                )
                        
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(authManager.currentUser?.displayName ?? "User")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text(authManager.currentUser?.email ?? "")
                                .font(AppTypography.footnote)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Points display
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(AppColors.primaryGreen)
                        
                        Text("\(authManager.currentUser?.points ?? 0) Points")
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                    }
                }
                .padding(AppSpacing.lg)
                .background(AppColors.cardBackground)
                
                // Menu items
                ScrollView {
                    VStack(spacing: 0) {
                        ProfileMenuItem(
                            icon: "person.fill",
                            title: "Profile",
                            action: {
                                // Navigate to profile
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isShowing = false
                                }
                            }
                        )
                        
                        ProfileMenuItem(
                            icon: "chart.bar.fill",
                            title: "Activity",
                            action: {
                                // Navigate to activity
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isShowing = false
                                }
                            }
                        )
                        
                        ProfileMenuItem(
                            icon: "gear",
                            title: "Settings",
                            action: {
                                // Navigate to settings
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isShowing = false
                                }
                            }
                        )
                        
                        ProfileMenuItem(
                            icon: "questionmark.circle.fill",
                            title: "Help & Support",
                            action: {
                                // Navigate to help
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isShowing = false
                                }
                            }
                        )
                        
                        Divider()
                            .background(AppColors.divider)
                        
                        ProfileMenuItem(
                            icon: "rectangle.portrait.and.arrow.right",
                            title: "Sign Out",
                            action: {
                                authManager.signOut()
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isShowing = false
                                }
                            }
                        )
                    }
                }
                .background(AppColors.cardBackground)
                
                Spacer()
            }
            .frame(maxWidth: 280, maxHeight: .infinity)
            .background(AppColors.cardBackground)
                
                Spacer()
            }
        }
    }
}

// MARK: - Profile Menu Item
struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Placeholder Views for Tabs
// HomeView is now defined in HomeView.swift

// SurveyView is now defined in SurveyView.swift

// MailView is now defined in MailView.swift

// RedeemView is now defined in RedeemView.swift

#Preview {
    MainTabView()
}
