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
                        actionTitle: "Scan Mail",
                        action: {
                            showingCamera = true
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppSpacing.md) {
                            ForEach(viewModel.mailPackages) { mailPackage in
                                MailPackageCard(mailPackage: mailPackage) {
                                    viewModel.selectMailPackage(mailPackage)
                                }
                            }
                        }
                        .padding(AppSpacing.lg)
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
                viewModel.createMailPackage(with: images)
            }
        }
        .sheet(item: $viewModel.selectedMailPackage) { mailPackage in
            MailPackageDetailView(mailPackage: mailPackage)
        }
    }
}

// MARK: - Mail Package Card
struct MailPackageCard: View {
    let mailPackage: MailPackage
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                // Circular thumbnail
                if let thumbnailPath = mailPackage.thumbnailPath {
                    AsyncImage(url: URL(string: thumbnailPath)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "doc.text.image")
                            .font(.system(size: 24))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(AppColors.primaryGreen.opacity(0.3), lineWidth: 2)
                    )
                } else {
                    // Default placeholder
                    RoundedRectangle(cornerRadius: 30)
                        .fill(AppColors.primaryGreen.opacity(0.1))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "doc.text.image")
                                .font(.system(size: 24))
                                .foregroundColor(AppColors.primaryGreen)
                        )
                }
                
                // Content
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Text(mailPackage.timestamp)
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Scan count badge
                        Text("\(mailPackage.scanCount) scan\(mailPackage.scanCount == 1 ? "" : "s")")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.primaryGreen)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xs)
                            .background(AppColors.primaryGreen.opacity(0.1))
                            .cornerRadius(AppCornerRadius.small)
                    }
                    
                    Text(formatDate(mailPackage.createdAt))
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
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
    
    private let apiService = APIService.shared
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.isLoading = false
                self?.mailPackages = localPackages
            }
        }
    }
    
    func selectMailPackage(_ mailPackage: MailPackage) {
        selectedMailPackage = mailPackage
    }
    
    func createMailPackage(with images: [UIImage]) {
        guard !images.isEmpty else { return }
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let mailPackageId = UUID().uuidString
        
        // Save images to local storage on main actor
        Task { @MainActor in
            let savedPaths = LocalStorageManager.shared.saveMailScans(
                images: images,
                mailPackageId: mailPackageId,
                timestamp: timestamp
            )
            
            // Create mail package
            let mailPackage = MailPackage(
                id: mailPackageId,
                timestamp: timestamp,
                createdAt: Date(),
                scanCount: images.count,
                thumbnailPath: savedPaths.first
            )
            
            // Save to local storage
            LocalStorageManager.shared.saveMailPackage(mailPackage)
            
            // Refresh the list
            await MainActor.run {
                loadMailPackages()
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
                    
                    Button("Choose from Library") {
                        showingPhotoLibrary = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    
                    #if targetEnvironment(simulator)
                    Button("Create Sample Images") {
                        print("🚀 Starting sample image creation...")
                        let sampleImages = TestDataHelper.shared.createSampleImages()
                        print("📸 Sample images created, calling onImagesCaptured with \(sampleImages.count) images")
                        onImagesCaptured(sampleImages)
                        dismiss()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.orange)
                    #endif
                    
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
                ImagePicker(images: [], onImagesSelected: { images in
                    onImagesCaptured(images)
                    dismiss()
                })
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
                        
                        Text("\(mailPackage.scanCount) scan\(mailPackage.scanCount == 1 ? "" : "s")")
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
