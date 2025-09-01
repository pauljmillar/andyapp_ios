//
//  TestDataHelper.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import SwiftUI
import UIKit

#if targetEnvironment(simulator)
/// Helper class for testing in simulator
class TestDataHelper {
    static let shared = TestDataHelper()
    
    private init() {}
    
    /// Creates sample images for testing mail scanning
    func createSampleImages() -> [UIImage] {
        var images: [UIImage] = []
        
        // Create sample images with different colors and text
        let colors: [UIColor] = [.red, .blue, .green, .orange, .purple]
        let texts = ["Sample Ad 1", "Sample Ad 2", "Sample Ad 3", "Sample Ad 4", "Sample Ad 5"]
        
        print("🎨 Creating \(texts.count) sample images for testing...")
        
        for i in 0..<5 {
            let image = createSampleImage(
                size: CGSize(width: 300, height: 400),
                backgroundColor: colors[i],
                text: texts[i]
            )
            images.append(image)
            print("✅ Created sample image \(i+1): \(texts[i]) with \(colors[i]) background")
        }
        
        print("🎯 Sample images created successfully! Total: \(images.count)")
        return images
    }
    
    /// Creates a sample image with text
    private func createSampleImage(size: CGSize, backgroundColor: UIColor, text: String) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Fill background
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Add text
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
            
            // Add border
            let borderPath = UIBezierPath(rect: CGRect(origin: .zero, size: size))
            UIColor.white.setStroke()
            borderPath.lineWidth = 2
            borderPath.stroke()
        }
    }
    
    /// Adds sample photos to simulator for testing
    func addSamplePhotosToSimulator() {
        // This would typically be done through the simulator's Features menu
        // But we can create sample images in our app for testing
        print("📱 Simulator: Use Features → Add Photos to Library to add sample photos")
        print("📱 Or use the 'Create Sample Images' button in the app")
    }
}
#endif
