//
//  MailView.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import SwiftUI
import Combine
import AVFoundation
import UIKit
import Vision
import VisionKit

/*
 🍎 Document Scanning Options Implemented:
 
 1. ✅ Apple's VNDocumentCameraViewController (RECOMMENDED)
    - Native iOS document scanner
    - Excellent document detection
    - Automatic cropping and perspective correction
    - Multi-page support
    - Free and maintained by Apple
 
 2. 🔧 Custom Vision Framework Implementation (FALLBACK)
    - Basic rectangle detection
    - Manual corner adjustment
    - Can be unstable/jumpy
 
 3. 📱 Google ML Kit for iOS (ALTERNATIVE - NOT IMPLEMENTED)
    To add Google ML Kit Document Scanner:
    
    a) Add to Podfile:
       pod 'GoogleMLKit/DocumentScanner'
    
    b) Import and use:
       import MLKitDocumentScanner
       
       let scanner = DocumentScanner()
       scanner.scan { result in
           // Handle scanned documents
       }
    
    c) Benefits:
       - Same technology as Android app
       - Consistent behavior across platforms
       - Excellent document detection
       - Real-time processing
*/

struct MailView: View {
    @StateObject private var viewModel = MailViewModel()
    @State private var showingCamera = false
    @State private var showingScanningTips = false
    let onIndustriesChanged: ([String]) -> Void
    @Binding var selectedFilter: String?
    
    // Filtered mail packages based on selected filter
    var filteredMailPackages: [MailPackage] {
        guard let selectedFilter = selectedFilter else {
            return viewModel.mailPackages
        }
        return viewModel.mailPackages.filter { $0.industry == selectedFilter }
    }
    
    // Grouped mail packages by date (using filtered packages)
    var groupedMailPackages: [MailPackageGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredMailPackages) { mailPackage in
            calendar.startOfDay(for: mailPackage.createdAt)
        }
        
        return grouped.map { date, packages in
            MailPackageGroup(date: date, packages: packages.sorted { $0.createdAt > $1.createdAt })
        }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Mail packages list
                if viewModel.isLoading && viewModel.mailPackages.isEmpty {
                    LoadingView(message: "Loading mail...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.mailPackages.isEmpty {
                    VStack(spacing: AppSpacing.lg) {
                        Image(systemName: "mail")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text("No Mail Scanned")
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.textPrimary)
                        
                        VStack(spacing: AppSpacing.sm) {
                            Text("Tap the camera to scan your first mail package.")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                            
                            Button(action: { showingScanningTips = true }) {
                                HStack(spacing: AppSpacing.xs) {
                                    Image(systemName: "questionmark.circle")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppColors.textSecondary)
                                    
                                    Text("Click here for scanning tips.")
                                        .font(AppTypography.body)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(AppSpacing.xl)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.background)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            // Loading card at the top when processing
                            if viewModel.isProcessing {
                                ProcessingCard()
                                    .transition(.opacity.combined(with: .scale))
                                    .animation(.easeInOut(duration: 0.3), value: viewModel.isProcessing)
                            }
                            
                            ForEach(Array(groupedMailPackages.enumerated()), id: \.element.date) { index, group in
                                // Date header (show for all groups)
                                DateHeaderView(date: group.date)
                                    .padding(.top, index > 0 ? AppSpacing.md : 0)
                                    .padding(.bottom, AppSpacing.sm)
                                
                                // Mail packages for this date
                                ForEach(group.packages) { mailPackage in
                                    MailPackageCard(mailPackage: mailPackage) {
                                        viewModel.selectMailPackage(mailPackage)
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.lg)
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
        .sheet(isPresented: $showingScanningTips) {
            ScanningTipsView()
        }
        .onAppear {
            LocalStorageManager.shared.migrateImagePathsIfNeeded()
            viewModel.loadMailPackages()
        }
        .onChange(of: viewModel.availableIndustries) { industries in
            onIndustriesChanged(industries)
        }
        .sheet(isPresented: $showingCamera) {
            DocumentScannerView { images in
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
                // Circular thumbnail - show actual scanned image
                if let thumbnailImage = getThumbnailImage(for: mailPackage) {
                    Image(uiImage: thumbnailImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
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
                            .fill(Color(red: 0.314, green: 0.608, blue: 0.961)) // Blue circle
                            .frame(width: 16, height: 16)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.black)
                            )
                    }
                }
            }
            .padding(AppSpacing.sm)
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
    
    private func getThumbnailImage(for mailPackage: MailPackage) -> UIImage? {
        // Get the first image from the mail package's image paths
        guard let imagePaths = mailPackage.imagePaths,
              let firstImagePath = imagePaths.first else {
            print("🔍 No image paths found for mail package: \(mailPackage.id)")
            return nil
        }
        
        print("🔍 Loading thumbnail from path: \(firstImagePath)")
        
        // Load the image from local storage
        let image = LocalStorageManager.shared.getMailScanImage(at: firstImagePath)
        if image == nil {
            print("❌ Failed to load image from path: \(firstImagePath)")
        } else {
            print("✅ Successfully loaded thumbnail image")
        }
        return image
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
    
    
    // Available industries from mail packages
    var availableIndustries: [String] {
        let industries = Set(mailPackages.compactMap { $0.industry })
        return Array(industries).sorted()
    }
    
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
                    // Sort packages by creation date (most recent first)
                    self?.mailPackages = localPackages.sorted { $0.createdAt > $1.createdAt }
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
                brandName: processingResult.brandName,
                primaryOffer: processingResult.primaryOffer,
                companyValidated: mailPackage.companyValidated,
                responseIntention: mailPackage.responseIntention,
                nameCheck: mailPackage.nameCheck,
                status: mailPackage.status,
                pointsAwarded: mailPackage.pointsAwarded,
                isApproved: mailPackage.isApproved,
                processingStatus: mailPackage.processingStatus,
                createdAt: mailPackage.createdAt,
                updatedAt: mailPackage.updatedAt,
                s3Key: mailPackage.s3Key,
                imagePaths: mailPackage.imagePaths
            )
            
            // Show survey with processing results
            await MainActor.run {
                self.processingResult = processingResult
                self.currentMailPackageId = mailPackage.id
                self.showingSurvey = true
                
                // Add the new mail package to the beginning of the list and save to local storage
                self.mailPackages.insert(updatedMailPackage, at: 0)
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
                    // Ensure the processing status is set to completed
                    let completedPackage = MailPackage(
                        id: updatedPackage.id,
                        panelistId: updatedPackage.panelistId,
                        packageName: updatedPackage.packageName,
                        packageDescription: updatedPackage.packageDescription,
                        industry: updatedPackage.industry,
                        brandName: updatedPackage.brandName,
                        primaryOffer: updatedPackage.primaryOffer,
                        companyValidated: updatedPackage.companyValidated,
                        responseIntention: updatedPackage.responseIntention,
                        nameCheck: updatedPackage.nameCheck,
                        status: updatedPackage.status,
                        pointsAwarded: updatedPackage.pointsAwarded,
                        isApproved: updatedPackage.isApproved,
                        processingStatus: .completed, // Explicitly set to completed
                        createdAt: self.mailPackages[index].createdAt, // Preserve original creation time
                        updatedAt: updatedPackage.updatedAt, // Use the updated time from API
                        s3Key: updatedPackage.s3Key,
                        imagePaths: self.mailPackages[index].imagePaths // Preserve image paths
                    )
                    
                    self.mailPackages[index] = completedPackage
                    // Save the updated package to local storage
                    LocalStorageManager.shared.saveMailPackage(completedPackage)
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
    @State private var capturedImages: [UIImage] = []
    @State private var showingDocumentScanner = false
    @State private var showingCustomCamera = false
    @State private var showingScanningTips = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                // Header
                VStack(spacing: AppSpacing.lg) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 80))
                        .foregroundColor(AppColors.primaryGreen)
                    
                    Text("Document Scanner")
                        .font(AppTypography.largeTitle)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Scan multiple pages of your mail documents")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.lg)
                }
                
                // Captured images preview
                if !capturedImages.isEmpty {
                    VStack(spacing: AppSpacing.md) {
                        Text("Captured Images (\(capturedImages.count))")
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.textPrimary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppSpacing.sm) {
                                ForEach(Array(capturedImages.enumerated()), id: \.offset) { index, image in
                                    VStack(spacing: 4) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(AppColors.primaryGreen, lineWidth: 2)
                                            )
                                        
                                        Text("Page \(index + 1)")
                                            .font(.caption2)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }
                            }
                            .padding(.horizontal, AppSpacing.lg)
                        }
                    }
                    .padding()
                    .background(AppColors.cardBackground)
                    .cornerRadius(AppCornerRadius.medium)
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
                    Button("📄 Native Document Scanner") {
                        showingDocumentScanner = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    
                    Button("📷 Custom Camera") {
                        showingCustomCamera = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    
                    Button("Choose from Library") {
                        showingImagePicker = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    
                    if !capturedImages.isEmpty {
                        Button("Process \(capturedImages.count) Images") {
                            onImagesCaptured(capturedImages)
                            dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .frame(maxWidth: .infinity)
                    }
                    
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
            .sheet(isPresented: $showingDocumentScanner) {
                DocumentScannerView { images in
                    capturedImages.append(contentsOf: images)
                }
            }
            .sheet(isPresented: $showingCustomCamera) {
                CustomDocumentScannerView { images in
                    capturedImages.append(contentsOf: images)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(images: capturedImages, onImagesSelected: { images in
                    capturedImages = images
                })
            }
            .sheet(isPresented: $showingPhotoLibrary) {
                SampleImagePickerView { images in
                    capturedImages = images
                }
            }
        }
    }
}

// MARK: - Document Scanner View
struct DocumentScannerView: UIViewControllerRepresentable {
    let onImagesCaptured: ([UIImage]) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView
        
        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            
            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                images.append(image)
            }
            
            parent.onImagesCaptured(images)
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Document scanner failed with error: \(error)")
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }
    }
}

// MARK: - Custom Document Scanner View (Fallback)
struct CustomDocumentScannerView: View {
    let onImagesCaptured: ([UIImage]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var capturedImages: [UIImage] = []
    @State private var showingImagePicker = false
    @State private var cameraView: CameraPreviewView?
    @State private var isAutoDetectionEnabled = true
    
    var body: some View {
        NavigationView {
            ZStack {
                // Camera view with document detection
                DocumentCameraView { images in
                    capturedImages.append(contentsOf: images)
                } onCameraViewCreated: { cameraView in
                    self.cameraView = cameraView
                }
                
                // Overlay with grid and controls
                VStack {
                    // Top controls
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                        
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Text("Custom Scanner")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 8) {
                                Image(systemName: isAutoDetectionEnabled ? "viewfinder" : "viewfinder.circle")
                                    .foregroundColor(isAutoDetectionEnabled ? AppColors.primaryGreen : .white)
                                    .font(.caption)
                                
                                Text(isAutoDetectionEnabled ? "Auto" : "Manual")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                        .onTapGesture {
                            isAutoDetectionEnabled.toggle()
                            cameraView?.setAutoDetectionEnabled(isAutoDetectionEnabled)
                        }
                        
                        Spacer()
                        
                        Button("Library") {
                            showingImagePicker = true
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .padding(.top, 50)
                    
                    Spacer()
                    
                    // Bottom controls
                    VStack(spacing: 16) {
                        // Captured images preview
                        if !capturedImages.isEmpty {
                            HStack {
                                Text("Captured: \(capturedImages.count)")
                                    .foregroundColor(.white)
                                    .font(.caption)
                                
                                Spacer()
                                
                                Button("Done") {
                                    onImagesCaptured(capturedImages)
                                    dismiss()
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(AppColors.primaryGreen)
                                .cornerRadius(20)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                        }
                        
                        // Capture button
                        HStack {
                            Button(action: {
                                // Add haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                
                                cameraView?.capturePhoto()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 80, height: 80)
                                    
                                    Circle()
                                        .stroke(Color.black, lineWidth: 4)
                                        .frame(width: 70, height: 70)
                                    
                                    // Inner circle for visual feedback
                                    Circle()
                                        .fill(Color.black.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                }
                            }
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: 0.1), value: capturedImages.count)
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(images: capturedImages, onImagesSelected: { images in
                    capturedImages = images
                })
            }
        }
    }
}

// MARK: - Alternative: Custom Camera View (Fallback)
struct DocumentCameraView: UIViewRepresentable {
    let onImagesCaptured: ([UIImage]) -> Void
    let onCameraViewCreated: ((CameraPreviewView) -> Void)?
    @State private var isScanning = false
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.black
        
        // Add camera preview layer
        let cameraView = CameraPreviewView()
        cameraView.onImageCaptured = { image in
            onImagesCaptured([image])
        }
        
        // Call the callback to provide access to the camera view
        onCameraViewCreated?(cameraView)
        
        view.addSubview(cameraView)
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cameraView.topAnchor.constraint(equalTo: view.topAnchor),
            cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update view if needed
    }
}

// MARK: - Camera Preview View
class CameraPreviewView: UIView {
    var onImageCaptured: ((UIImage) -> Void)?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var documentOverlayView: DocumentOverlayView?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var documentDetectionTimer: Timer?
    private var lastDetectionTime = Date()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
    }
    
    deinit {
        documentDetectionTimer?.invalidate()
    }
    
    private func setupCamera() {
        // Set up camera session
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoInput) else {
            captureSession.commitConfiguration()
            return
        }
        
        captureSession.addInput(videoInput)
        
        // Add video output for document detection
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInitiated))
        
        if let videoOutput = videoOutput, captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        // Add photo output
        let photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        captureSession.commitConfiguration()
        
        // Set up preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = bounds
        
        if let previewLayer = previewLayer {
            layer.addSublayer(previewLayer)
        }
        
        // Add document overlay
        documentOverlayView = DocumentOverlayView()
        documentOverlayView?.frame = bounds
        documentOverlayView?.backgroundColor = UIColor.clear
        addSubview(documentOverlayView!)
        
        // Start document detection timer
        startDocumentDetection()
        
        // Start session
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
        documentOverlayView?.frame = bounds
    }
    
    private func startDocumentDetection() {
        documentDetectionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.performDocumentDetection()
        }
    }
    
    private func performDocumentDetection() {
        // Only perform detection if enough time has passed since last detection
        guard Date().timeIntervalSince(lastDetectionTime) > 0.5 else { return }
        
        // This will be called from the video output delegate
        // The actual detection happens in captureOutput:didOutput:from:
    }
    
    func capturePhoto() {
        guard let captureSession = captureSession,
              let photoOutput = captureSession.outputs.first(where: { $0 is AVCapturePhotoOutput }) as? AVCapturePhotoOutput else { return }
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func setAutoDetectionEnabled(_ enabled: Bool) {
        if enabled {
            startDocumentDetection()
            documentOverlayView?.setManualMode(false)
        } else {
            documentDetectionTimer?.invalidate()
            documentDetectionTimer = nil
            // Reset to default rect when auto-detection is disabled
            DispatchQueue.main.async {
                self.documentOverlayView?.updateDocumentRect(CGRect(x: 50, y: 150, width: 300, height: 400))
                self.documentOverlayView?.setDocumentDetected(false)
                self.documentOverlayView?.setManualMode(true)
            }
        }
    }
    
    private func detectDocument(in pixelBuffer: CVPixelBuffer) {
        // Use multiple detection strategies for better accuracy
        let rectangleRequest = VNDetectRectanglesRequest { [weak self] request, error in
            guard let self = self,
                  let observations = request.results as? [VNRectangleObservation] else {
                DispatchQueue.main.async {
                    self?.documentOverlayView?.setDocumentDetected(false)
                }
                return
            }
            
            // Find the best rectangle observation
            let bestObservation = self.findBestRectangleObservation(observations)
            
            if let bestObservation = bestObservation {
                // Convert Vision coordinates to view coordinates
                let documentRect = self.convertVisionRectToViewRect(bestObservation.boundingBox)
                
                DispatchQueue.main.async {
                    self.documentOverlayView?.updateDocumentRect(documentRect)
                    self.documentOverlayView?.setDocumentDetected(true)
                }
            } else {
                DispatchQueue.main.async {
                    self.documentOverlayView?.setDocumentDetected(false)
                }
            }
        }
        
        // Enhanced configuration for better document detection
        rectangleRequest.minimumAspectRatio = 0.2  // More flexible aspect ratio
        rectangleRequest.maximumAspectRatio = 2.0  // Allow wider documents
        rectangleRequest.minimumSize = 0.05        // Smaller minimum size
        rectangleRequest.minimumConfidence = 0.3            // Lower confidence threshold
        rectangleRequest.maximumObservations = 10  // Check multiple rectangles
        
        // Also try contour detection for better edge detection
        let contourRequest = VNDetectContoursRequest { [weak self] request, error in
            guard let self = self,
                  let observations = request.results as? [VNContoursObservation] else { return }
            
            // Find the largest contour that could be a document
            if let bestContour = self.findBestDocumentContour(observations) {
                let documentRect = self.convertContourToRect(bestContour)
                
                DispatchQueue.main.async {
                    self.documentOverlayView?.updateDocumentRect(documentRect)
                    self.documentOverlayView?.setDocumentDetected(true)
                }
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([rectangleRequest, contourRequest])
    }
    
    private func findBestRectangleObservation(_ observations: [VNRectangleObservation]) -> VNRectangleObservation? {
        // Filter out observations that are too small or have low confidence
        let validObservations = observations.filter { observation in
            observation.confidence > 0.3 &&
            observation.boundingBox.width > 0.1 &&
            observation.boundingBox.height > 0.1
        }
        
        // Sort by confidence and size
        return validObservations.max { obs1, obs2 in
            let score1 = CGFloat(obs1.confidence) * (obs1.boundingBox.width * obs1.boundingBox.height)
            let score2 = CGFloat(obs2.confidence) * (obs2.boundingBox.width * obs2.boundingBox.height)
            return score1 < score2
        }
    }
    
    private func findBestDocumentContour(_ observations: [VNContoursObservation]) -> VNContour? {
        guard let observation = observations.first else { return nil }
        
        // Find the largest contour that could represent a document
        let validContours = observation.topLevelContours.filter { contour in
            contour.normalizedPoints.count >= 4 && // At least 4 points for a rectangle
            contour.normalizedPoints.count <= 8    // Not too complex
        }
        
        return validContours.max { contour1, contour2 in
            let area1 = calculateContourArea(contour1.normalizedPoints)
            let area2 = calculateContourArea(contour2.normalizedPoints)
            return area1 < area2
        }
    }
    
    private func calculateContourArea(_ points: [simd_float2]) -> CGFloat {
        guard points.count >= 3 else { return 0 }
        
        var area: CGFloat = 0
        for i in 0..<points.count {
            let j = (i + 1) % points.count
            area += CGFloat(points[i].x) * CGFloat(points[j].y)
            area -= CGFloat(points[j].x) * CGFloat(points[i].y)
        }
        return abs(area) / 2
    }
    
    private func convertContourToRect(_ contour: VNContour) -> CGRect {
        let points = contour.normalizedPoints
        
        // Find bounding box of the contour
        let minX = points.map { CGFloat($0.x) }.min() ?? 0
        let maxX = points.map { CGFloat($0.x) }.max() ?? 1
        let minY = points.map { CGFloat($0.y) }.min() ?? 0
        let maxY = points.map { CGFloat($0.y) }.max() ?? 1
        
        let boundingBox = CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
        
        return convertVisionRectToViewRect(boundingBox)
    }
    
    private func convertVisionRectToViewRect(_ visionRect: CGRect) -> CGRect {
        // Vision coordinates are normalized (0-1) and have origin at bottom-left
        // Convert to view coordinates with origin at top-left
        
        let viewWidth = bounds.width
        let viewHeight = bounds.height
        
        // Convert from Vision's bottom-left origin to top-left origin
        let x = visionRect.origin.x * viewWidth
        let y = (1.0 - visionRect.origin.y - visionRect.height) * viewHeight
        let width = visionRect.width * viewWidth
        let height = visionRect.height * viewHeight
        
        // Add some padding and ensure minimum size
        let padding: CGFloat = 20
        let minSize: CGFloat = 200
        
        let adjustedRect = CGRect(
            x: max(padding, x - padding/2),
            y: max(padding, y - padding/2),
            width: max(minSize, width + padding),
            height: max(minSize, height + padding)
        )
        
        // Ensure the rect stays within bounds
        return CGRect(
            x: min(adjustedRect.origin.x, viewWidth - adjustedRect.width - padding),
            y: min(adjustedRect.origin.y, viewHeight - adjustedRect.height - padding),
            width: min(adjustedRect.width, viewWidth - 2 * padding),
            height: min(adjustedRect.height, viewHeight - 2 * padding)
        )
    }
}

// MARK: - Document Overlay View
class DocumentOverlayView: UIView {
    private var documentRect: CGRect = CGRect(x: 50, y: 150, width: 300, height: 400)
    private var isDocumentDetected = false
    private var isManualMode = false
    private var selectedCorner: Int? = nil
    private let cornerSize: CGFloat = 20
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        setupGestureRecognizers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = UIColor.clear
        setupGestureRecognizers()
    }
    
    private func setupGestureRecognizers() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard isManualMode else { return }
        
        let location = gesture.location(in: self)
        
        switch gesture.state {
        case .began:
            selectedCorner = getCornerAt(location: location)
        case .changed:
            if let corner = selectedCorner {
                updateCorner(corner, to: location)
            }
        case .ended, .cancelled:
            selectedCorner = nil
        default:
            break
        }
    }
    
    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        if documentRect.contains(location) {
            isManualMode.toggle()
            setNeedsDisplay()
        }
    }
    
    private func getCornerAt(location: CGPoint) -> Int? {
        let corners = getCornerPoints()
        for (index, corner) in corners.enumerated() {
            let distance = sqrt(pow(location.x - corner.x, 2) + pow(location.y - corner.y, 2))
            if distance <= cornerSize {
                return index
            }
        }
        return nil
    }
    
    private func getCornerPoints() -> [CGPoint] {
        return [
            CGPoint(x: documentRect.minX, y: documentRect.minY), // Top-left
            CGPoint(x: documentRect.maxX, y: documentRect.minY), // Top-right
            CGPoint(x: documentRect.minX, y: documentRect.maxY), // Bottom-left
            CGPoint(x: documentRect.maxX, y: documentRect.maxY)  // Bottom-right
        ]
    }
    
    private func updateCorner(_ cornerIndex: Int, to location: CGPoint) {
        let minSize: CGFloat = 100
        let padding: CGFloat = 20
        
        var newRect = documentRect
        
        switch cornerIndex {
        case 0: // Top-left
            newRect.origin.x = max(padding, min(location.x, documentRect.maxX - minSize))
            newRect.origin.y = max(padding, min(location.y, documentRect.maxY - minSize))
            newRect.size.width = documentRect.maxX - newRect.origin.x
            newRect.size.height = documentRect.maxY - newRect.origin.y
        case 1: // Top-right
            newRect.origin.y = max(padding, min(location.y, documentRect.maxY - minSize))
            newRect.size.width = max(minSize, min(location.x - documentRect.minX, bounds.width - documentRect.minX - padding))
            newRect.size.height = documentRect.maxY - newRect.origin.y
        case 2: // Bottom-left
            newRect.origin.x = max(padding, min(location.x, documentRect.maxX - minSize))
            newRect.size.width = documentRect.maxX - newRect.origin.x
            newRect.size.height = max(minSize, min(location.y - documentRect.minY, bounds.height - documentRect.minY - padding))
        case 3: // Bottom-right
            newRect.size.width = max(minSize, min(location.x - documentRect.minX, bounds.width - documentRect.minX - padding))
            newRect.size.height = max(minSize, min(location.y - documentRect.minY, bounds.height - documentRect.minY - padding))
        default:
            break
        }
        
        documentRect = newRect
        setNeedsDisplay()
    }
    
    func setManualMode(_ enabled: Bool) {
        isManualMode = enabled
        setNeedsDisplay()
    }
    
    func updateDocumentRect(_ rect: CGRect) {
        // Animate the rect change for smooth transitions
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            self.documentRect = rect
            self.setNeedsDisplay()
        })
    }
    
    func setDocumentDetected(_ detected: Bool) {
        isDocumentDetected = detected
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Draw semi-transparent overlay
        context.setFillColor(UIColor.black.withAlphaComponent(0.5).cgColor)
        context.fill(rect)
        
        // Clear the document area
        context.setBlendMode(.clear)
        context.fill(documentRect)
        context.setBlendMode(.normal)
        
        // Draw document border with different colors based on detection
        let borderColor = isDocumentDetected ? (AppColors.primaryGreen.cgColor ?? UIColor.green.cgColor) : UIColor.white.cgColor
        context.setStrokeColor(borderColor)
        context.setLineWidth(2)
        context.stroke(documentRect)
        
        // Draw corner indicators
        let cornerLength: CGFloat = 20
        let cornerWidth: CGFloat = 3
        
        context.setStrokeColor(AppColors.primaryGreen.cgColor ?? UIColor.green.cgColor)
        context.setLineWidth(cornerWidth)
        
        // Top-left corner
        context.move(to: CGPoint(x: documentRect.minX, y: documentRect.minY + cornerLength))
        context.addLine(to: CGPoint(x: documentRect.minX, y: documentRect.minY))
        context.addLine(to: CGPoint(x: documentRect.minX + cornerLength, y: documentRect.minY))
        
        // Top-right corner
        context.move(to: CGPoint(x: documentRect.maxX - cornerLength, y: documentRect.minY))
        context.addLine(to: CGPoint(x: documentRect.maxX, y: documentRect.minY))
        context.addLine(to: CGPoint(x: documentRect.maxX, y: documentRect.minY + cornerLength))
        
        // Bottom-left corner
        context.move(to: CGPoint(x: documentRect.minX, y: documentRect.maxY - cornerLength))
        context.addLine(to: CGPoint(x: documentRect.minX, y: documentRect.maxY))
        context.addLine(to: CGPoint(x: documentRect.minX + cornerLength, y: documentRect.maxY))
        
        // Bottom-right corner
        context.move(to: CGPoint(x: documentRect.maxX - cornerLength, y: documentRect.maxY))
        context.addLine(to: CGPoint(x: documentRect.maxX, y: documentRect.maxY))
        context.addLine(to: CGPoint(x: documentRect.maxX, y: documentRect.maxY - cornerLength))
        
        context.strokePath()
        
        // Draw manual adjustment handles if in manual mode
        if isManualMode {
            let corners = getCornerPoints()
            for corner in corners {
                let handleRect = CGRect(
                    x: corner.x - cornerSize/2,
                    y: corner.y - cornerSize/2,
                    width: cornerSize,
                    height: cornerSize
                )
                
                context.setFillColor(UIColor.white.cgColor)
                context.fillEllipse(in: handleRect)
                
                context.setStrokeColor(AppColors.primaryGreen.cgColor ?? UIColor.green.cgColor)
                context.setLineWidth(2)
                context.strokeEllipse(in: handleRect)
            }
        }
        
        // Draw grid lines
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(1)
        
        // Vertical grid lines
        for i in 1..<3 {
            let x = documentRect.minX + (documentRect.width / 3) * CGFloat(i)
            context.move(to: CGPoint(x: x, y: documentRect.minY))
            context.addLine(to: CGPoint(x: x, y: documentRect.maxY))
        }
        
        // Horizontal grid lines
        for i in 1..<3 {
            let y = documentRect.minY + (documentRect.height / 3) * CGFloat(i)
            context.move(to: CGPoint(x: documentRect.minX, y: y))
            context.addLine(to: CGPoint(x: documentRect.maxX, y: y))
        }
        
        context.strokePath()
        
        // Draw instruction text
        let instructionText: String
        if isManualMode {
            instructionText = "Drag corners to adjust • Tap document to exit manual mode"
        } else if isDocumentDetected {
            instructionText = "Document detected! Tap to capture • Tap document for manual adjustment"
        } else {
            instructionText = "Position document within the frame"
        }
        
        let textColor: UIColor = isDocumentDetected ? UIColor(AppColors.primaryGreen) : UIColor.white
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: textColor,
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]
        
        let textSize = instructionText.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (rect.width - textSize.width) / 2,
            y: documentRect.maxY + 20,
            width: textSize.width,
            height: textSize.height
        )
        
        instructionText.draw(in: textRect, withAttributes: attributes)
        
        // Draw detection indicator
        if isDocumentDetected {
            let indicatorSize: CGFloat = 12
            let indicatorRect = CGRect(
                x: documentRect.maxX - indicatorSize - 10,
                y: documentRect.minY + 10,
                width: indicatorSize,
                height: indicatorSize
            )
            
            context.setFillColor(AppColors.primaryGreen.cgColor ?? UIColor.green.cgColor)
            context.fillEllipse(in: indicatorRect)
            
            // Add pulsing animation effect
            let pulseRect = CGRect(
                x: indicatorRect.origin.x - 2,
                y: indicatorRect.origin.y - 2,
                width: indicatorRect.width + 4,
                height: indicatorRect.height + 4
            )
            
            context.setStrokeColor(AppColors.primaryGreen.cgColor ?? UIColor.green.cgColor)
            context.setLineWidth(2)
            context.strokeEllipse(in: pulseRect)
        }
    }
}

// MARK: - Photo Capture Delegate
extension CameraPreviewView: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }
        
        DispatchQueue.main.async {
            self.onImageCaptured?(image)
        }
    }
}

// MARK: - Video Output Delegate
extension CameraPreviewView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Only process every few frames to avoid overwhelming the system
        guard Date().timeIntervalSince(lastDetectionTime) > 0.5 else { return }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Perform document detection
        detectDocument(in: pixelBuffer)
        lastDetectionTime = Date()
    }
}

// MARK: - Mail Package Detail View
struct MailPackageDetailView: View {
    let mailPackage: MailPackage
    @Environment(\.dismiss) private var dismiss
    @State private var scannedImages: [UIImage] = []
    @State private var showingImageZoom = false
    @State private var selectedImageIndex = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    headerSection
                    
                    if !scannedImages.isEmpty {
                        scannedImagesSection
                    }
                    
                    packageDetailsSection
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
            .onAppear {
                loadScannedImages()
            }
            .sheet(isPresented: $showingImageZoom) {
                ImageZoomView(
                    images: scannedImages,
                    selectedIndex: $selectedImageIndex
                )
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Mail Package")
                .font(AppTypography.largeTitle)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Scanned on \(formatDate(mailPackage.createdAt))")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
            
            Text(mailPackage.industry ?? "Unknown Industry")
                .font(AppTypography.title2)
                .foregroundColor(AppColors.primaryGreen)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColors.primaryGreen.opacity(0.1))
                .cornerRadius(AppCornerRadius.small)
        }
    }
    
    private var scannedImagesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Scanned Images")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(Array(scannedImages.enumerated()), id: \.offset) { index, image in
                        imageCard(for: image, at: index)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.medium)
    }
    
    private func imageCard(for image: UIImage, at index: Int) -> some View {
        Button(action: {
            selectedImageIndex = index
            showingImageZoom = true
        }) {
            VStack(spacing: 4) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.primaryGreen, lineWidth: 2)
                    )
                
                Text("Page \(index + 1)")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var packageDetailsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Package Details")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                DetailRow(label: "Industry", value: mailPackage.industry ?? "Unknown")
                DetailRow(label: "Brand", value: mailPackage.brandName ?? "Unknown")
                DetailRow(label: "Status", value: mailPackage.processingStatus?.rawValue.capitalized ?? "Unknown")
                DetailRow(label: "Company Validated", value: (mailPackage.companyValidated ?? false) ? "Yes" : "No")
                DetailRow(label: "Response Intention", value: mailPackage.responseIntention ?? "Not specified")
                DetailRow(label: "Name Check", value: mailPackage.nameCheck ?? "Not checked")
                DetailRow(label: "Primary Offer", value: mailPackage.primaryOffer ?? "No offer details")
                
                if let notes = mailPackage.notes, !notes.isEmpty {
                    DetailRow(label: "Notes", value: notes)
                }
                
                if let processingNotes = mailPackage.processingNotes, !processingNotes.isEmpty {
                    DetailRow(label: "Processing Notes", value: processingNotes)
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.medium)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func loadScannedImages() {
        // Load all scanned images for this mail package
        guard let imagePaths = mailPackage.imagePaths else {
            print("🔍 No image paths found for mail package: \(mailPackage.id)")
            scannedImages = []
            return
        }
        
        print("🔍 Loading \(imagePaths.count) images for mail package: \(mailPackage.id)")
        
        scannedImages = imagePaths.compactMap { path in
            print("🔍 Loading image from path: \(path)")
            let image = LocalStorageManager.shared.getMailScanImage(at: path)
            if image == nil {
                print("❌ Failed to load image from path: \(path)")
            } else {
                print("✅ Successfully loaded image")
            }
            return image
        }
        
        print("🔍 Loaded \(scannedImages.count) images successfully")
    }
}

// MARK: - Mail Package Group
struct MailPackageGroup {
    let date: Date
    let packages: [MailPackage]
}

// MARK: - Date Header View
struct DateHeaderView: View {
    let date: Date
    
    var body: some View {
        HStack {
            Text(formatDateHeader(date))
                .font(AppTypography.caption1)
                .foregroundColor(AppColors.textSecondary)
                .textCase(.uppercase)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding(.horizontal, AppSpacing.lg)
    }
    
    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        if calendar.isDate(date, inSameDayAs: today) {
            return "Today"
        } else if calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Detail Row Component
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(AppTypography.caption1)
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(AppTypography.caption1)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

// MARK: - Image Zoom View
struct ImageZoomView: View {
    let images: [UIImage]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if !images.isEmpty {
                    TabView(selection: $selectedIndex) {
                        ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleEffect(scale)
                                .offset(offset)
                                .gesture(
                                    SimultaneousGesture(
                                        MagnificationGesture()
                                            .onChanged { value in
                                                let delta = value / lastScale
                                                lastScale = value
                                                scale = min(max(scale * delta, 1.0), 5.0)
                                            }
                                            .onEnded { _ in
                                                lastScale = 1.0
                                                if scale < 1.0 {
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        scale = 1.0
                                                        offset = .zero
                                                    }
                                                }
                                            },
                                        DragGesture()
                                            .onChanged { value in
                                                offset = CGSize(
                                                    width: lastOffset.width + value.translation.width,
                                                    height: lastOffset.height + value.translation.height
                                                )
                                            }
                                            .onEnded { _ in
                                                lastOffset = offset
                                            }
                                    )
                                )
                                .onTapGesture(count: 2) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        if scale > 1.0 {
                                            scale = 1.0
                                            offset = .zero
                                            lastOffset = .zero
                                        } else {
                                            scale = 2.0
                                        }
                                    }
                                }
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                }
            }
            .navigationTitle("Image \(selectedIndex + 1) of \(images.count)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            scale = 1.0
            lastScale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }
}

#Preview {
    MailView(
        onIndustriesChanged: { _ in },
        selectedFilter: .constant(nil)
    )
}
