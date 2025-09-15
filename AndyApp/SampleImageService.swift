//
//  SampleImageService.swift
//  AndyApp
//
//  Created by Paul Millar on 9/15/25.
//

import Foundation
import UIKit

class SampleImageService {
    static let shared = SampleImageService()
    
    private init() {}
    
    /// Returns sample images for testing
    /// - Returns: Array of sample mail images
    func getSampleImages() -> [UIImage] {
        // Try to load the real sample image first
        if let realSampleImage = loadSampleImageFromAssets() {
            return [realSampleImage]
        }
        
        // Fallback to placeholder if real image not available
        return [createPlaceholderSampleImage()]
    }
    
    /// Creates a placeholder sample image for testing
    private func createPlaceholderSampleImage() -> UIImage {
        let size = CGSize(width: 400, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Border
            let borderRect = CGRect(origin: .zero, size: size).insetBy(dx: 10, dy: 10)
            context.cgContext.setStrokeColor(UIColor.black.cgColor)
            context.cgContext.setLineWidth(2)
            context.cgContext.stroke(borderRect)
            
            // Sample content
            let text = "SAMPLE MAIL\n\nCompany: The Home Depot\nIndustry: Retail/Home Improvement\nOffer: Credit Card Application\n\nThis is a sample image for testing the mail scanning functionality."
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.black
            ]
            
            let textRect = borderRect.insetBy(dx: 20, dy: 20)
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    /// Loads sample image from assets (when available)
    private func loadSampleImageFromAssets() -> UIImage? {
        // Load the real sample image from the asset catalog
        return UIImage(named: "SampleMailImage")
    }
}
