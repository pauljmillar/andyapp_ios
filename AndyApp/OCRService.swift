//
//  OCRService.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import Foundation
import Vision
import UIKit

/// Service for extracting text from images using Apple's Vision Framework
class OCRService: ObservableObject {
    static let shared = OCRService()
    
    private init() {}
    
    /// Extracts text from a single image
    /// - Parameter image: UIImage to process
    /// - Returns: Extracted text string
    func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.processingFailed(error))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: recognizedText)
            }
            
            // Configure for high accuracy
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.processingFailed(error))
            }
        }
    }
    
    /// Processes multiple images and returns combined text in sequential order
    /// - Parameter images: Array of UIImages to process
    /// - Returns: Combined text with image order preserved
    func processMailPackage(images: [UIImage]) async throws -> String {
        print("🔍 Starting OCR processing for \(images.count) images...")
        
        var combinedText = ""
        
        for (index, image) in images.enumerated() {
            print("📸 Processing image \(index + 1) of \(images.count)...")
            
            do {
                let text = try await extractText(from: image)
                let imageText = "--- Image \(index + 1) ---\n\(text)\n\n"
                combinedText += imageText
                
                print("✅ Image \(index + 1) processed successfully")
            } catch {
                print("❌ Failed to process image \(index + 1): \(error)")
                // Continue with other images even if one fails
                let errorText = "--- Image \(index + 1) (OCR Failed) ---\n[Text extraction failed: \(error.localizedDescription)]\n\n"
                combinedText += errorText
            }
        }
        
        print("🎯 OCR processing completed. Total text length: \(combinedText.count) characters")
        return combinedText
    }
}

// MARK: - OCR Errors
enum OCRError: Error, LocalizedError {
    case invalidImage
    case noTextFound
    case processingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .noTextFound:
            return "No text found in image"
        case .processingFailed(let error):
            return "OCR processing failed: \(error.localizedDescription)"
        }
    }
}
