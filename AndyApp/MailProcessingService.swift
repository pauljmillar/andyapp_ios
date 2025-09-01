//
//  MailProcessingService.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import Foundation
import UIKit
import Combine

/// Service that handles the complete mail processing workflow
class MailProcessingService: ObservableObject {
    static let shared = MailProcessingService()
    
    private let ocrService = OCRService.shared
    private let apiService = APIService.shared
    
    private init() {}
    
    /// Processes a complete mail package workflow
    /// - Parameters:
    ///   - images: Array of scanned images
    ///   - mailPackageId: Unique identifier for the mail package
    ///   - timestamp: Timestamp when images were captured
    /// - Returns: Processed MailPackage with analysis
    func processMailPackage(
        images: [UIImage],
        mailPackageId: String,
        timestamp: String
    ) async throws -> MailPackage {
        
        print("🚀 Starting mail package processing workflow...")
        print("📦 Package ID: \(mailPackageId)")
        print("📸 Image count: \(images.count)")
        
        // Step 1: Create initial mail package with "processing" status
        let initialPackage = MailPackage(
            id: mailPackageId,
            timestamp: timestamp,
            createdAt: Date(),
            scanCount: images.count,
            thumbnailPath: nil,
            status: .processing,
            analysis: nil
        )
        
        print("✅ Step 1: Initial package created with processing status")
        
        // Step 2: Perform OCR on all images
        print("🔍 Step 2: Starting OCR processing...")
        let ocrText = try await ocrService.processMailPackage(images: images)
        print("✅ Step 2: OCR completed. Text length: \(ocrText.count) characters")
        
        // Step 3: Call web server for analysis
        print("🌐 Step 3: Calling web server for analysis...")
        let analysisRequest = MailAnalysisRequest(
            mailPackageId: mailPackageId,
            ocrText: ocrText,
            imageCount: images.count,
            timestamp: timestamp
        )
        
        let analysisResponse = try await apiService.analyzeMailPackage(request: analysisRequest)
        
        guard analysisResponse.success, let analysis = analysisResponse.analysis else {
            print("❌ Step 3: Analysis failed - \(analysisResponse.error ?? "Unknown error")")
            throw MailProcessingError.analysisFailed(analysisResponse.error ?? "Unknown error")
        }
        
        print("✅ Step 3: Analysis completed successfully")
        print("🏢 Company: \(analysis.companyName)")
        print("🏭 Industry: \(analysis.industry)")
        print("📝 Offer: \(analysis.offerDescription)")
        print("👤 Recipient: \(analysis.recipientGuess)")
        
        // Step 4: Upload images to S3
        print("☁️ Step 4: Uploading images to S3...")
        let s3Urls = try await apiService.uploadImagesToS3(images: images, mailPackageId: mailPackageId)
        print("✅ Step 4: S3 upload completed. URLs: \(s3Urls)")
        
        // Step 5: Update database with analysis and S3 URLs
        print("🔄 Step 5: Updating database...")
        let dbUpdateSuccess = try await apiService.updateMailPackageInDB(
            mailPackageId: mailPackageId,
            analysis: analysis,
            s3Urls: s3Urls
        )
        
        guard dbUpdateSuccess else {
            print("❌ Step 5: Database update failed")
            throw MailProcessingError.databaseUpdateFailed
        }
        
        print("✅ Step 5: Database updated successfully")
        
        // Step 6: Create final mail package with completed status
        let finalPackage = MailPackage(
            id: mailPackageId,
            timestamp: timestamp,
            createdAt: Date(),
            scanCount: images.count,
            thumbnailPath: s3Urls.first,
            status: .completed,
            analysis: analysis
        )
        
        print("🎯 Mail package processing workflow completed successfully!")
        print("📊 Final status: \(finalPackage.status.rawValue)")
        print("🏢 Company: \(finalPackage.analysis?.companyName ?? "N/A")")
        
        return finalPackage
    }
    
    /// Processes images in background and updates UI via callback
    /// - Parameters:
    ///   - images: Array of scanned images
    ///   - mailPackageId: Unique identifier for the mail package
    ///   - timestamp: Timestamp when images were captured
    ///   - onProgress: Progress callback for UI updates
    ///   - onCompletion: Completion callback with result
    func processMailPackageAsync(
        images: [UIImage],
        mailPackageId: String,
        timestamp: String,
        onProgress: @escaping (String) -> Void,
        onCompletion: @escaping (Result<MailPackage, Error>) -> Void
    ) {
        Task {
            do {
                onProgress("Starting OCR processing...")
                let result = try await processMailPackage(
                    images: images,
                    mailPackageId: mailPackageId,
                    timestamp: timestamp
                )
                
                await MainActor.run {
                    onCompletion(.success(result))
                }
            } catch {
                await MainActor.run {
                    onCompletion(.failure(error))
                }
            }
        }
    }
}

// MARK: - Mail Processing Errors
enum MailProcessingError: Error, LocalizedError {
    case analysisFailed(String)
    case s3UploadFailed
    case databaseUpdateFailed
    case ocrProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .analysisFailed(let reason):
            return "Analysis failed: \(reason)"
        case .s3UploadFailed:
            return "Failed to upload images to S3"
        case .databaseUpdateFailed:
            return "Failed to update database"
        case .ocrProcessingFailed:
            return "OCR processing failed"
        }
    }
}
