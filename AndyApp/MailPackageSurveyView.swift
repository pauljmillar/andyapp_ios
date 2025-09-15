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
    
    @Environment(\.dismiss) private var dismiss
    @State private var recipientAnswer: String = ""
    @State private var brandNameAnswer: String = ""
    @State private var intentionAnswer: String = ""
    
    // Computed property to check if addressee question should be shown
    private var shouldShowAddresseeQuestion: Bool {
        guard let recipient = processingResult.recipient else { return false }
        return !recipient.isEmpty && recipient.lowercased() != "current resident"
    }
    
    // Function to get the correct question number based on whether addressee question is shown
    private func questionNumber(for originalNumber: Int) -> String {
        if shouldShowAddresseeQuestion {
            return "Question \(originalNumber)"
        } else {
            // If addressee question is skipped, shift all numbers down by 1
            return "Question \(originalNumber - 1)"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                // Survey Questions
                VStack(spacing: AppSpacing.xl) {
                    // Question 1: Recipient Name (only show if specific addressee is detected)
                    if shouldShowAddresseeQuestion {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Question 1")
                                .font(AppTypography.caption1)
                                .foregroundColor(AppColors.textSecondary)
                                .textCase(.uppercase)
                            
                            Text("Who is **\(processingResult.recipient!)**?")
                                .font(AppTypography.title3)
                                .foregroundColor(AppColors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                            
                            VStack(spacing: AppSpacing.sm) {
                                RadioButton(
                                    title: "\(processingResult.recipient!) is me",
                                    isSelected: recipientAnswer == "me",
                                    action: { recipientAnswer = "me" }
                                )
                                
                                RadioButton(
                                    title: "\(processingResult.recipient!) is someone else in my house",
                                    isSelected: recipientAnswer == "someone_else",
                                    action: { recipientAnswer = "someone_else" }
                                )
                                
                                RadioButton(
                                    title: "I don't know",
                                    isSelected: recipientAnswer == "dont_know",
                                    action: { recipientAnswer = "dont_know" }
                                )
                            }
                        }
                        .padding()
                        .background(AppColors.cardBackground)
                        .cornerRadius(AppCornerRadius.medium)
                    }
                    
                    // Question 2: Brand Name (or Question 1 if addressee question is skipped)
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text(questionNumber(for: 2))
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
                    
                    // Question 3: Intention (or Question 2 if addressee question is skipped)
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text(questionNumber(for: 3))
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
                .padding(.top, AppSpacing.lg)
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: AppSpacing.md) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    
                    Button("Submit") {
                        submitSurvey()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    .disabled(!canSubmit)
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
        let hasBrandNameAnswer = !brandNameAnswer.isEmpty
        let hasIntentionAnswer = !intentionAnswer.isEmpty
        
        // Only require recipient answer if the addressee question is shown
        if shouldShowAddresseeQuestion {
            let hasRecipientAnswer = !recipientAnswer.isEmpty
            return hasRecipientAnswer && hasBrandNameAnswer && hasIntentionAnswer
        } else {
            return hasBrandNameAnswer && hasIntentionAnswer
        }
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
        onSurveyCompleted: { _ in }
    )
}
