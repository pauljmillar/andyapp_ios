//
//  TopNavigationView.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import SwiftUI

struct TopNavigationView: View {
    let title: String
    let showProfileMenu: () -> Void
    let showNotifications: () -> Void
    let filterCategories: [String]
    @Binding var selectedFilter: String?
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Top row: Profile circle, title, notification
            HStack(spacing: AppSpacing.md) {
                // Profile circle
                Button(action: showProfileMenu) {
                    Circle()
                        .fill(AppColors.profileBlue)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(profileInitial)
                                .font(AppTypography.headline)
                                .foregroundColor(.black)
                                .fontWeight(.semibold)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Title
                Text(title)
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Notification icon
                Button(action: showNotifications) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.textSecondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            
            // Bottom row: Filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    // All filter
                    FilterPill(
                        title: "All",
                        isSelected: selectedFilter == nil
                    ) {
                        selectedFilter = nil
                    }
                    
                    // Category filters
                    ForEach(filterCategories, id: \.self) { category in
                        FilterPill(
                            title: category,
                            isSelected: selectedFilter == category
                        ) {
                            selectedFilter = category
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
            .padding(.bottom, AppSpacing.sm)
        }
        .background(AppColors.background)
    }
    
    private var profileInitial: String {
        if let user = authManager.currentUser {
            if let firstName = user.firstName, !firstName.isEmpty {
                return String(firstName.prefix(1).uppercased())
            } else if !user.email.isEmpty {
                return String(user.email.prefix(1).uppercased())
            }
        }
        return "U"
    }
}

// Updated FilterPill to use Spotify green with black text
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.subheadline)
                .foregroundColor(isSelected ? .black : AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(isSelected ? AppColors.primaryGreen : AppColors.cardBackground)
                .cornerRadius(AppCornerRadius.pill)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.pill)
                        .stroke(isSelected ? AppColors.primaryGreen : AppColors.divider, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TopNavigationView(
        title: "Home",
        showProfileMenu: {},
        showNotifications: {},
        filterCategories: ["Technology", "Health", "Finance", "Entertainment"],
        selectedFilter: .constant(nil)
    )
}
