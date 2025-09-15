//
//  CameraSelectionView.swift
//  AndyApp
//
//  Created by Paul Millar on 9/15/25.
//

import SwiftUI

struct CameraSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    let onCameraSelected: () -> Void
    let onSampleImageSelected: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                // Header
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.primaryGreen)
                    
                    Text("Scan Mail Package")
                        .font(AppTypography.largeTitle)
                        .foregroundColor(AppColors.textPrimary)
                        .fontWeight(.bold)
                    
                    Text("Choose how you'd like to scan your mail")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppSpacing.xl)
                
                Spacer()
                
                // Selection Options
                VStack(spacing: AppSpacing.lg) {
                    // Camera Option
                    Button(action: {
                        onCameraSelected()
                        dismiss()
                    }) {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Use Camera")
                                    .font(AppTypography.headline)
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                                
                                Text("Take photos with your device camera")
                                    .font(AppTypography.caption1)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(AppSpacing.lg)
                        .background(AppColors.primaryGreen)
                        .cornerRadius(AppCornerRadius.medium)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Sample Image Option
                    Button(action: {
                        onSampleImageSelected()
                        dismiss()
                    }) {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 24))
                                .foregroundColor(AppColors.textPrimary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Use Sample Image")
                                    .font(AppTypography.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                    .fontWeight(.semibold)
                                
                                Text("Test with a sample mail image")
                                    .font(AppTypography.caption1)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(AppSpacing.lg)
                        .background(AppColors.cardBackground)
                        .cornerRadius(AppCornerRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                .stroke(AppColors.divider, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, AppSpacing.lg)
                
                Spacer()
                
                // Help Text
                VStack(spacing: AppSpacing.sm) {
                    Text("💡 Tip")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.primaryGreen)
                        .fontWeight(.semibold)
                    
                    Text("Use the sample image to test the app without a physical device")
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, AppSpacing.xl)
            }
            .background(AppColors.background)
            .navigationTitle("Scan Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primaryGreen)
                }
            }
        }
    }
}

#Preview {
    CameraSelectionView(
        onCameraSelected: {},
        onSampleImageSelected: {}
    )
}
