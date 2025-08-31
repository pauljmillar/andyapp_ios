//
//  StyleGuide.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import SwiftUI

// MARK: - Color Palette
struct AppColors {
    // Primary Colors
    static let primaryGreen = Color(hex: "#1ED760") // Spotify Green
    static let darkGreen = Color(hex: "#1DB954")    // Darker Spotify Green
    static let lightGreen = Color(hex: "#1ED760")   // Spotify Green
    static let profileBlue = Color(hex: "#509BFS")  // Profile Circle Blue
    
    // Background Colors
    static let background = Color.black              // Dark mode background
    static let cardBackground = Color(hex: "#1C1C1E") // Dark card background
    
    // Text Colors
    static let textPrimary = Color.white             // White text for dark mode
    static let textSecondary = Color(hex: "#8E8E93") // Light gray text for dark mode
    
    // Divider Colors
    static let divider = Color(hex: "#38383A")      // Dark divider for dark mode
    
    // Status Colors
    static let success = Color(hex: "#4CAF50")
    static let warning = Color(hex: "#FF9800")
    static let error = Color(hex: "#F44336")
    static let info = Color(hex: "#2196F3")
}

// MARK: - Typography
struct AppTypography {
    static let largeTitle = Font.system(size: 34, weight: .bold)
    static let title1 = Font.system(size: 28, weight: .bold)
    static let title2 = Font.system(size: 22, weight: .semibold)
    static let title3 = Font.system(size: 20, weight: .semibold)
    static let headline = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 17, weight: .regular)
    static let callout = Font.system(size: 16, weight: .regular)
    static let subheadline = Font.system(size: 15, weight: .regular)
    static let footnote = Font.system(size: 13, weight: .regular)
    static let caption1 = Font.system(size: 12, weight: .regular)
    static let caption2 = Font.system(size: 11, weight: .regular)
}

// MARK: - Spacing
struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
struct AppCornerRadius {
    static let small: CGFloat = 4
    static let medium: CGFloat = 8
    static let large: CGFloat = 12
    static let xl: CGFloat = 16
    static let pill: CGFloat = 20
}

// MARK: - Shadows
struct AppShadows {
    static let small = Shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    static let medium = Shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    static let large = Shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
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

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.headline)
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.primaryGreen)
            .cornerRadius(AppCornerRadius.medium)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.headline)
            .foregroundColor(AppColors.primaryGreen)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(AppColors.primaryGreen, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct FilterPillStyle: ViewModifier {
    let isSelected: Bool
    
    func body(content: Content) -> some View {
        content
            .font(AppTypography.subheadline)
            .foregroundColor(isSelected ? .white : AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(isSelected ? AppColors.primaryGreen : AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.pill)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.pill)
                    .stroke(isSelected ? AppColors.primaryGreen : AppColors.divider, lineWidth: 1)
            )
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
    
    func filterPillStyle(isSelected: Bool) -> some View {
        modifier(FilterPillStyle(isSelected: isSelected))
    }
}
