//
//  MailView.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import SwiftUI
import Combine

struct MailView: View {
    @StateObject private var viewModel = MailViewModel()
    @State private var showingCamera = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Mail packages list
                if viewModel.isLoading && viewModel.mailPackages.isEmpty {
                    LoadingView(message: "Loading mail...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.mailPackages.isEmpty {
                    EmptyStateView(
                        icon: "mail",
                        title: "No Mail Scanned",
                        message: "Tap the camera button to scan your first mail package.",
                        actionTitle: nil,
                        action: nil
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppSpacing.md) {
                            // Loading card at the top when processing
                            if viewModel.isProcessing {
                                ProcessingCard()
                                    .transition(.opacity.combined(with: .scale))
                                    .animation(.easeInOut(duration: 0.3), value: viewModel.isProcessing)
                            }
                            
                            ForEach(viewModel.mailPackages) { mailPackage in
                                MailPackageCard(mailPackage: mailPackage) {
                                    viewModel.selectMailPackage(mailPackage)
                                }
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                        .padding(AppSpacing.lg)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.mailPackages.count)
                    }
                }
            }
            .background(AppColors.background)
            
            // Floating Action Button (FAB)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingCamera = true
                    }) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(AppColors.primaryGreen)
                            .clipShape(Circle())
                            .shadow(
                                color: AppColors.primaryGreen.opacity(0.3),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                    }
                    .padding(.trailing, AppSpacing.lg)
                    .padding(.bottom, 80) // Above bottom tab bar
                }
            }
        }
        .onAppear {
            viewModel.loadMailPackages()
        }
        .sheet(isPresented: $showingCamera) {
            CameraView { images in
                Task {
                    await viewModel.startMailPackageWorkflow(with: images)
                }
            }
        }
        .sheet(item: $viewModel.selectedMailPackage) { mailPackage in
            MailPackageDetailView(mailPackage: mailPackage)
        }
        .sheet(isPresented: $viewModel.showingSurvey) {
            if let result = viewModel.processingResult {
                MailPackageSurveyView(
                    processingResult: result,
                    onSurveyCompleted: { survey in
                        Task {
                            await viewModel.completeSurvey(survey: survey, mailPackageId: viewModel.currentMailPackageId)
                            viewModel.showingSurvey = false
                        }
                    },
                    onCancel: {
                        viewModel.showingSurvey = false
                        // If survey is cancelled, still mark processing as complete
                        viewModel.isProcessing = false
                    }
                )
                .interactiveDismissDisabled()
            }
        }
    }
}

// MARK: - Processing Card
struct ProcessingCard: View {
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Loading circle
            Circle()
                .fill(AppColors.primaryGreen.opacity(0.1))
                .frame(width: 56, height: 56)
                .overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryGreen))
                )
            
            // Content - 3 lines of text
            VStack(alignment: .leading, spacing: 4) {
                // Line 1: Industry
                Text("Processing...")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                
                // Line 2: Company
                Text("AI analyzing your mail")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                
                // Line 3: Offer
                Text("Please wait...")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Right side: Time and loading indicator
            VStack(alignment: .trailing, spacing: 4) {
                Text("Now")
                    .font(AppTypography.caption2)
                    .foregroundColor(Color(red: 0.314, green: 0.608, blue: 0.961)) // #509bf5
                
                // Loading dots
                HStack(spacing: 2) {
                    ForEach(0..<3) { _ in
                        Circle()
                            .fill(AppColors.primaryGreen)
                            .frame(width: 4, height: 4)
                            .scaleEffect(0.8)
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color.black) // Black background with no border
        .cornerRadius(AppCornerRadius.medium)
    }
}

// MARK: - Mail Package Card
struct MailPackageCard: View {
    let mailPackage: MailPackage
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                // Circular thumbnail - full height of card
                if let s3Key = mailPackage.s3Key {
                    AsyncImage(url: URL(string: s3Key)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "doc.text.image")
                            .font(.system(size: 24))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                } else {
                    // Default placeholder
                    Circle()
                        .fill(AppColors.primaryGreen.opacity(0.1))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "doc.text.image")
                                .font(.system(size: 24))
                                .foregroundColor(AppColors.primaryGreen)
                        )
                }
                
                // Content - 3 lines of text
                VStack(alignment: .leading, spacing: 4) {
                    // Line 1: Industry (or Unknown)
                    Text(mailPackage.industry ?? "Unknown")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                    
                    // Line 2: Company or brand_name
                    Text(mailPackage.brandName ?? "Unknown Company")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                    
                    // Line 3: First few words of the offer
                    Text(mailPackage.primaryOffer ?? "No offer details")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Right side: Time and completion status
                VStack(alignment: .trailing, spacing: 4) {
                    // Time (blue color, same as profile circle)
                    Text(formatTime(mailPackage.createdAt))
                        .font(AppTypography.caption2)
                        .foregroundColor(Color(red: 0.314, green: 0.608, blue: 0.961)) // #509bf5
                    
                    // Completion check mark (only if processing is complete)
                    if mailPackage.processingStatus == .completed {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(Color.black) // Black background with no border
            .cornerRadius(AppCornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Mail View Model
class MailViewModel: ObservableObject {
    @Published var mailPackages: [MailPackage] = []
    @Published var selectedMailPackage: MailPackage?
    @Published var isLoading = false
    @Published var error: String?
    @Published var showingSurvey = false
    @Published var processingResult: ProcessingResult?
    @Published var currentMailPackageId = ""
    @Published var isProcessing = false
    
    private let apiService = APIService.shared
    private let mailProcessingService = MailProcessingService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadMailPackages()
    }
    
    func loadMailPackages() {
        isLoading = true
        error = nil
        
        // Load from local storage on main actor
        Task { @MainActor in
            let localPackages = LocalStorageManager.shared.getMailPackages()
            
            // Only update if we have packages or if we're not currently processing
            if !localPackages.isEmpty || !self.isProcessing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.isLoading = false
                    self?.mailPackages = localPackages
                }
            } else {
                // If we're processing, just stop loading but keep existing packages
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.isLoading = false
                }
            }
        }
    }
    
    func selectMailPackage(_ mailPackage: MailPackage) {
        selectedMailPackage = mailPackage
    }
    
    func startMailPackageWorkflow(with images: [UIImage]) async {
        guard !images.isEmpty else { return }
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        
        await MainActor.run {
            self.isProcessing = true
        }
        
        do {
            print("🚀 Starting mail package workflow with \(images.count) images...")
            
            // Create mail package and process ALL images (including AI processing)
            let mailPackage = try await mailProcessingService.createAndProcessMailPackage(
                images: images,
                timestamp: timestamp
            )
            
            print("✅ Mail package created and processed successfully")
            print("🆔 Mail package ID: \(mailPackage.id)")
            
            // Get the processing result from the service
            // We need to get the OCR texts from the images first
            var allOcrTexts: [String] = []
            
            // Extract OCR from all images
            for (index, image) in images.enumerated() {
                let ocrText = try await mailProcessingService.ocrService.extractText(from: image)
                allOcrTexts.append(ocrText)
                print("📝 OCR extracted from image \(index + 1): \(ocrText.count) characters")
            }
            
            let processingResult = try await mailProcessingService.completeMailPackage(
                mailPackageId: mailPackage.id,
                allOcrTexts: allOcrTexts,
                timestamp: timestamp
            )
            
            print("🤖 AI processing completed, showing survey...")
            
            // Update the mail package with the industry from processing result
            let updatedMailPackage = MailPackage(
                id: mailPackage.id,
                panelistId: mailPackage.panelistId,
                packageName: mailPackage.packageName,
                packageDescription: mailPackage.packageDescription,
                industry: processingResult.industry,
                brandName: mailPackage.brandName,
                primaryOffer: mailPackage.primaryOffer,
                companyValidated: mailPackage.companyValidated,
                responseIntention: mailPackage.responseIntention,
                nameCheck: mailPackage.nameCheck,
                status: mailPackage.status,
                pointsAwarded: mailPackage.pointsAwarded,
                isApproved: mailPackage.isApproved,
                processingStatus: mailPackage.processingStatus,
                createdAt: mailPackage.createdAt,
                updatedAt: mailPackage.updatedAt,
                s3Key: mailPackage.s3Key
            )
            
            // Show survey with processing results
            await MainActor.run {
                self.processingResult = processingResult
                self.currentMailPackageId = mailPackage.id
                self.showingSurvey = true
                
                // Add the new mail package to the list and save to local storage
                self.mailPackages.append(updatedMailPackage)
                LocalStorageManager.shared.saveMailPackage(updatedMailPackage)
                
                // Keep processing state true until survey is completed
                // self.isProcessing = false  // Don't set to false yet
            }
            
        } catch {
            print("❌ Mail package workflow failed: \(error)")
            await MainActor.run {
                self.error = error.localizedDescription
                self.isProcessing = false
            }
        }
    }
    
    func completeSurvey(survey: MailPackageSurvey, mailPackageId: String) async {
        do {
            // Update the survey with the mail package ID
            var updatedSurvey = survey
            updatedSurvey.mailPackageId = mailPackageId
            
            // Update mail package with survey results
            let updatedPackage = try await mailProcessingService.updateMailPackageWithSurvey(
                mailPackageId: mailPackageId,
                survey: updatedSurvey
            )
            
            // Update the local mail package with survey results
            await MainActor.run {
                // Find and update the existing package in the list
                if let index = self.mailPackages.firstIndex(where: { $0.id == mailPackageId }) {
                    self.mailPackages[index] = updatedPackage
                    // Save the updated package to local storage
                    LocalStorageManager.shared.saveMailPackage(updatedPackage)
                }
                
                // Now that survey is completed, set processing to false
                self.isProcessing = false
            }
            
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }
}

// MARK: - Camera View
struct CameraView: View {
    let onImagesCaptured: ([UIImage]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingImagePicker = false
    @State private var showingPhotoLibrary = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                // Camera placeholder
                VStack(spacing: AppSpacing.lg) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AppColors.primaryGreen)
                    
                    Text("Document Scanner")
                        .font(AppTypography.largeTitle)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Take photos of ads and offers from your mail")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.lg)
                }
                
                // Simulator testing info
                #if targetEnvironment(simulator)
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.orange)
                        Text("Simulator Mode")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    
                    Text("Camera will use photo library in simulator")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, AppSpacing.lg)
                #endif
                
                Spacer()
                
                // Action buttons
                VStack(spacing: AppSpacing.md) {
                    Button("Take Photos") {
                        showingImagePicker = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    
                    Button("Choose Sample Images") {
                        showingPhotoLibrary = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, AppSpacing.lg)
            }
            .padding(AppSpacing.xl)
            .background(AppColors.background)
            .navigationTitle("Scan Mail")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(images: [], onImagesSelected: { images in
                    onImagesCaptured(images)
                    dismiss()
                })
            }
            .sheet(isPresented: $showingPhotoLibrary) {
                SampleImagePickerView { images in
                    onImagesCaptured(images)
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Mail Package Detail View
struct MailPackageDetailView: View {
    let mailPackage: MailPackage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Mail Package")
                            .font(AppTypography.largeTitle)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Scanned on \(formatDate(mailPackage.createdAt))")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text("Mail Package")
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.primaryGreen)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xs)
                            .background(AppColors.primaryGreen.opacity(0.1))
                            .cornerRadius(AppCornerRadius.small)
                    }
                    
                    // Placeholder for future content
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "doc.text.image")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text("Mail Package Details")
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Additional details and functionality will be added here.")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.xl)
                    .background(AppColors.cardBackground)
                    .cornerRadius(AppCornerRadius.medium)
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle("Mail Details")
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    MailView()
}
