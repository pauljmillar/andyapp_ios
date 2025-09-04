//
//  MailPackageSurveyView.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import SwiftUI

struct MailPackageSurveyView: View {
    let processingResult: ProcessingResult
    let onSurveyCompleted: (MailPackageSurvey) -> Void
    let onCancel: () -> Void
    
    @State private var recipientAnswer: String = ""
    @State private var brandNameAnswer: String = ""
    @State private var intentionAnswer: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                // Header
                VStack(spacing: AppSpacing.md) {
                    Text("📬 Mail Package Survey")
                        .font(AppTypography.largeTitle)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Please answer a few questions about this mail piece")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppSpacing.xl)
                
                // Survey Questions
                VStack(spacing: AppSpacing.xl) {
                    // Question 1: Recipient Name
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Question 1")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                            .textCase(.uppercase)
                        
                        Text("Was this offer sent to **\(processingResult.recipient ?? "you")**?")
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                        
                        VStack(spacing: AppSpacing.sm) {
                            RadioButton(
                                title: "Yes",
                                isSelected: recipientAnswer == "yes",
                                action: { recipientAnswer = "yes" }
                            )
                            
                            RadioButton(
                                title: "No",
                                isSelected: recipientAnswer == "no",
                                action: { recipientAnswer = "no" }
                            )
                        }
                    }
                    .padding()
                    .background(AppColors.cardBackground)
                    .cornerRadius(AppCornerRadius.medium)
                    
                    // Question 2: Brand Name
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Question 2")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                            .textCase(.uppercase)
                        
                        Text("Was this offer sent from **\(processingResult.brandName ?? "this company")**?")
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                        
                        VStack(spacing: AppSpacing.sm) {
                            RadioButton(
                                title: "Yes",
                                isSelected: brandNameAnswer == "yes",
                                action: { brandNameAnswer = "yes" }
                            )
                            
                            RadioButton(
                                title: "No",
                                isSelected: brandNameAnswer == "no",
                                action: { brandNameAnswer = "no" }
                            )
                        }
                    }
                    .padding()
                    .background(AppColors.cardBackground)
                    .cornerRadius(AppCornerRadius.medium)
                    
                    // Question 3: Intention
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Question 3")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                            .textCase(.uppercase)
                        
                        Text("Do you intend to act on this offer?")
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                        
                        VStack(spacing: AppSpacing.sm) {
                            RadioButton(
                                title: "Yes",
                                isSelected: intentionAnswer == "yes",
                                action: { intentionAnswer = "yes" }
                            )
                            
                            RadioButton(
                                title: "No",
                                isSelected: intentionAnswer == "no",
                                action: { intentionAnswer = "no" }
                            )
                        }
                    }
                    .padding()
                    .background(AppColors.cardBackground)
                    .cornerRadius(AppCornerRadius.medium)
                }
                .padding(.horizontal, AppSpacing.lg)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: AppSpacing.md) {
                    Button("Submit Survey") {
                        submitSurvey()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    .disabled(!canSubmit)
                    
                    Button("Cancel") {
                        onCancel()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
            .background(AppColors.background)
            .navigationTitle("Mail Survey")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Set default values
            }
        }
    }
    
    private var canSubmit: Bool {
        let hasRecipientAnswer = !recipientAnswer.isEmpty
        let hasBrandNameAnswer = !brandNameAnswer.isEmpty
        let hasIntentionAnswer = !intentionAnswer.isEmpty
        
        return hasRecipientAnswer && hasBrandNameAnswer && hasIntentionAnswer
    }
    
    private func submitSurvey() {
        let survey = MailPackageSurvey(
            mailPackageId: "", // Will be set by caller
            recipientAnswer: recipientAnswer,
            brandNameAnswer: brandNameAnswer,
            intentionAnswer: intentionAnswer,
            industry: processingResult.industry,
            primaryOffer: processingResult.primaryOffer,
            brandName: processingResult.brandName ?? "Unknown"
        )
        
        onSurveyCompleted(survey)
    }
}

// MARK: - Radio Button Component
struct RadioButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? AppColors.primaryGreen : AppColors.textSecondary, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(AppColors.primaryGreen)
                            .frame(width: 12, height: 12)
                    }
                }
                
                Text(title)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MailPackageSurveyView(
        processingResult: ProcessingResult(
            industry: "Retail",
            brandName: "Target",
            recipient: "CURRENT RESIDENT",
            responseIntention: "interested",
            nameCheck: "verified",
            mailType: "promotional",
            primaryOffer: "20% off your next purchase",
            urgencyLevel: "medium",
            estimatedValue: "$50"
        ),
        onSurveyCompleted: { _ in },
        onCancel: {}
    )
}
