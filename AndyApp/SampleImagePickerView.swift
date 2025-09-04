import SwiftUI
import UIKit

struct SampleImagePickerView: View {
    let onImagesSelected: ([UIImage]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImages: [UIImage] = []
    
    // Sample images for testing
    private let sampleImages: [SampleImage] = [
        SampleImage(name: "Insurance Document", image: loadInsuranceImage() ?? createSampleImage(color: .systemBlue, text: "INSURANCE")),
        SampleImage(name: "Credit Card Offer", image: createSampleImage(color: .systemGreen, text: "CREDIT CARD")),
        SampleImage(name: "Retail Coupon", image: createSampleImage(color: .systemOrange, text: "COUPON")),
        SampleImage(name: "Bank Statement", image: createSampleImage(color: .systemPurple, text: "BANK")),
        SampleImage(name: "Utility Bill", image: createSampleImage(color: .systemRed, text: "UTILITY")),
        SampleImage(name: "Real Estate", image: createSampleImage(color: .systemTeal, text: "REAL ESTATE"))
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.primaryGreen)
                    
                    Text("Choose Sample Images")
                        .font(AppTypography.largeTitle)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Select images to test the mail scanning workflow")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.lg)
                }
                .padding(AppSpacing.xl)
                
                // Image grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: AppSpacing.md) {
                        ForEach(sampleImages.indices, id: \.self) { index in
                            let sampleImage = sampleImages[index]
                            SampleImageCard(
                                sampleImage: sampleImage,
                                isSelected: selectedImages.contains(sampleImage.image),
                                onTap: {
                                    if selectedImages.contains(sampleImage.image) {
                                        selectedImages.removeAll { $0 == sampleImage.image }
                                    } else {
                                        selectedImages.append(sampleImage.image)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
                
                // Action buttons
                VStack(spacing: AppSpacing.md) {
                    Button("Done (\(selectedImages.count) selected)") {
                        if !selectedImages.isEmpty {
                            onImagesSelected(selectedImages)
                            dismiss()
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    .disabled(selectedImages.isEmpty)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(maxWidth: .infinity)
                }
                .padding(AppSpacing.lg)
                .background(AppColors.cardBackground)
            }
            .background(AppColors.background)
            .navigationTitle("Sample Images")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Select All") {
                        selectedImages = sampleImages.map { $0.image }
                    }
                    .foregroundColor(AppColors.primaryGreen)
                }
            }
        }
    }
    
    // Helper function to load insurance image from Documents directory
    private static func loadInsuranceImage() -> UIImage? {
        #if targetEnvironment(simulator)
        // In simulator, try to access Downloads folder through a different approach
        let homePath = ProcessInfo.processInfo.environment["HOME"] ?? ""
        let downloadsPath = homePath.isEmpty ? "" : (homePath as NSString).appendingPathComponent("Downloads")
        let insurancePath = (downloadsPath as NSString).appendingPathComponent("insurance.jpg")
        
        if !downloadsPath.isEmpty, let imageData = try? Data(contentsOf: URL(fileURLWithPath: insurancePath)),
           let image = UIImage(data: imageData) {
            print("✅ Loaded insurance.jpg from Downloads folder: \(insurancePath)")
            
            // Also try to save it to Documents directory for future use
            if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let documentsInsurancePath = documentsPath.appendingPathComponent("insurance.jpg")
                try? imageData.write(to: documentsInsurancePath)
                print("💾 Saved insurance.jpg to Documents folder for future use")
            }
            
            return image
        } else {
            print("⚠️ Could not load insurance.jpg from Downloads folder, using generated image")
            return nil
        }
        #else
        // On device, we can't access Downloads folder, so just return nil
        return nil
        #endif
    }
    
    // Helper function to create sample images
    private static func createSampleImage(color: UIColor, text: String) -> UIImage {
        let size = CGSize(width: 300, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Background
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Border
            UIColor.white.setStroke()
            let path = UIBezierPath(rect: CGRect(origin: .zero, size: size))
            path.lineWidth = 4
            path.stroke()
            
            // Text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
}

struct SampleImage {
    let name: String
    let image: UIImage
}

struct SampleImageCard: View {
    let sampleImage: SampleImage
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppSpacing.sm) {
                Image(uiImage: sampleImage.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(AppCornerRadius.small)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.small)
                            .stroke(isSelected ? AppColors.primaryGreen : Color.clear, lineWidth: 3)
                    )
                
                Text(sampleImage.name)
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.primaryGreen)
                        .font(.system(size: 20))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SampleImagePickerView { images in
        print("Selected \(images.count) images")
    }
}
