import SwiftUI

struct ScanningTipsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Mail Scanning Tips")
                            .font(AppTypography.largeTitle)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Get the best results from your mail scans")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.bottom, AppSpacing.md)
                    
                    // Tips Section
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        TipCard(
                            icon: "camera.fill",
                            title: "Good Lighting",
                            description: "Ensure your mail is well-lit. Natural light works best, but avoid harsh shadows.",
                            tips: [
                                "Hold your device steady",
                                "Avoid glare from overhead lights",
                                "Use a flat surface if possible"
                            ]
                        )
                        
                        TipCard(
                            icon: "doc.text.fill",
                            title: "Document Position",
                            description: "Position your mail document clearly within the camera frame.",
                            tips: [
                                "Keep the entire document in view",
                                "Avoid cutting off edges or corners",
                                "Hold the camera parallel to the document"
                            ]
                        )
                        
                        TipCard(
                            icon: "textformat.abc",
                            title: "Text Clarity",
                            description: "Make sure all text is clearly visible and readable.",
                            tips: [
                                "Avoid blurry or out-of-focus shots",
                                "Ensure text isn't too small to read",
                                "Check for any obstructions covering text"
                            ]
                        )
                        
                        TipCard(
                            icon: "checkmark.circle.fill",
                            title: "What We Accept",
                            description: "We can process most types of mail and documents.",
                            tips: [
                                "Junk mail and advertisements",
                                "Bills and statements",
                                "Catalogs and flyers",
                                "Postcards and letters"
                            ]
                        )
                        
                        TipCard(
                            icon: "xmark.circle.fill",
                            title: "What We Don't Accept",
                            description: "Some items cannot be processed for points.",
                            tips: [
                                "Personal photos or documents",
                                "Sensitive financial information",
                                "Medical records or prescriptions",
                                "Legal documents or contracts"
                            ]
                        )
                    }
                    
                    // Points Information
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Earning Points")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("You earn points for each successfully processed mail item. Points can be redeemed for rewards in the Redeem tab.")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.top, AppSpacing.lg)
                    
                    Spacer(minLength: AppSpacing.xl)
                }
                .padding(.horizontal, AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primaryGreen)
                }
            }
        }
    }
}

struct TipCard: View {
    let icon: String
    let title: String
    let description: String
    let tips: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.primaryGreen)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Text(description)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                ForEach(tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: AppSpacing.xs) {
                        Text("•")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.primaryGreen)
                        
                        Text(tip)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.divider, lineWidth: 1)
        )
    }
}

#Preview {
    ScanningTipsView()
}
