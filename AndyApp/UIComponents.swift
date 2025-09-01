//
//  UIComponents.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import SwiftUI

// MARK: - Card Components
struct InfoCard: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    let action: (() -> Void)?
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        color: Color = AppColors.primaryGreen,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: AppSpacing.md) {
                // Icon
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundColor(color)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppTypography.footnote)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(AppSpacing.lg)
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.medium)
            .shadow(
                color: AppShadows.small.color,
                radius: AppShadows.small.radius,
                x: AppShadows.small.x,
                y: AppShadows.small.y
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PointsCard: View {
    let points: Int
    let title: String
    let subtitle: String?
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.primaryGreen)
                
                Spacer()
                
                Text("\(points)")
                    .font(AppTypography.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppSpacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.medium)
        .shadow(
            color: AppShadows.small.color,
            radius: AppShadows.small.radius,
            x: AppShadows.small.x,
            y: AppShadows.small.y
        )
    }
}

// MARK: - Filter Components
// Note: FilterPill is now defined in TopNavigationView.swift

// MARK: - Survey Components
struct SurveyCard: View {
    let survey: SurveyViewItem
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Survey content
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(survey.title)
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                            .multilineTextAlignment(.leading)
                        
                        Text(survey.description)
                            .font(AppTypography.footnote)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    if survey.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.success)
                    }
                }
                
                // Footer
                HStack {
                    // Status pill
                    Text(survey.status)
                        .font(AppTypography.caption1)
                        .foregroundColor(survey.isCompleted ? AppColors.success : AppColors.primaryGreen)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background((survey.isCompleted ? AppColors.success : AppColors.primaryGreen).opacity(0.1))
                        .cornerRadius(AppCornerRadius.small)
                    
                    Spacer()
                    
                    // Points and time
                    HStack(spacing: AppSpacing.md) {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.primaryGreen)
                            
                            Text("\(survey.points)")
                                .font(AppTypography.caption1)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)
                            
                            Text(survey.estimatedTime)
                                .font(AppTypography.caption1)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            }
            
            // Action button for available surveys
            if !survey.isCompleted {
                Button(action: action) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                        Text("Start Survey")
                    }
                    .font(AppTypography.body)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColors.primaryGreen)
                    .cornerRadius(AppCornerRadius.small)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.medium)
        .shadow(
            color: AppShadows.small.color,
            radius: AppShadows.small.radius,
            x: AppShadows.small.x,
            y: AppShadows.small.y
        )
    }
}

// MARK: - Activity Components
struct ActivityItemView: View {
    let activity: ActivityItem
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Icon
            Circle()
                .fill(iconColor.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: iconName)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)
                )
            
            // Content
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(activity.title)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(activity.description)
                    .font(AppTypography.footnote)
                    .foregroundColor(AppColors.textSecondary)
                
                if let points = activity.points {
                    Text("\(points > 0 ? "+" : "")\(points) pts")
                        .font(AppTypography.caption1)
                        .foregroundColor(points > 0 ? AppColors.success : AppColors.error)
                }
            }
            
            Spacer()
            
            // Time
            Text(timeAgo)
                .font(AppTypography.caption2)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.medium)
        .shadow(
            color: AppShadows.small.color,
            radius: AppShadows.small.radius,
            x: AppShadows.small.x,
            y: AppShadows.small.y
        )
    }
    
    private var iconName: String {
        switch activity.type {
        case .surveyCompleted:
            return "doc.text.fill"
        case .pointsEarned:
            return "star.fill"
        case .pointsRedeemed:
            return "gift.fill"
        case .achievement:
            return "trophy.fill"
        case .system:
            return "bell.fill"
        }
    }
    
    private var iconColor: Color {
        switch activity.type {
        case .surveyCompleted:
            return AppColors.success
        case .pointsEarned:
            return AppColors.primaryGreen
        case .pointsRedeemed:
            return AppColors.warning
        case .achievement:
            return AppColors.info
        case .system:
            return AppColors.textSecondary
        }
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: activity.createdAt, relativeTo: Date())
    }
}

// MARK: - Loading and Error States
struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryGreen))
                .scaleEffect(1.2)
            
            Text(message)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

struct ErrorView: View {
    let message: String
    let retryAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(AppColors.error)
            
            Text("Oops!")
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)
            
            Text(message)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            
            if let retryAction = retryAction {
                Button("Try Again") {
                    retryAction()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppColors.textSecondary)
            
            Text(title)
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)
            
            Text(message)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle) {
                    action()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

// MARK: - Custom Button Styles
struct IconButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16))
            .foregroundColor(color)
            .padding(AppSpacing.sm)
            .background(color.opacity(0.1))
            .cornerRadius(AppCornerRadius.small)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(AppSpacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(AppColors.divider, lineWidth: 1)
            )
    }
}
