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
    
    let ocrService = OCRService.shared
    private let apiService = APIService.shared
    
    private init() {}
    
    // MARK: - Async Processing Support
    
    /// Creates a new mail package and processes images (steps 1-4 only)
    /// This is the synchronous part that returns immediately
    /// - Parameters:
    ///   - images: Array of scanned images
    ///   - timestamp: Timestamp when images were captured
    /// - Returns: Created MailPackage with scanning state
    func createMailPackage(
        images: [UIImage],
        timestamp: String
    ) async throws -> MailPackage {
        
        print("🚀 Starting new mail package creation (async workflow)...")
        print("📸 Image count: \(images.count)")
        
        var mailPackageId: String? = nil
        var allOcrTexts: [String] = []
        
        // Step 1: Process and upload first image (creates new mail package)
        print("📤 Uploading first image (creates new mail package)...")
        let firstImageResult = try await processAndUploadImage(
            image: images[0],
            mailPackageId: nil, // nil for new package
            imageSequence: 1,
            timestamp: timestamp
        )
        allOcrTexts.append(firstImageResult.ocrText)
        
        // Extract mail package ID from the first upload response
        mailPackageId = firstImageResult.mailPackageId
        print("🆔 First image upload completed. Mail package ID: \(mailPackageId ?? "nil")")
        
        // Step 2: Process remaining images if any
        if images.count > 1 {
            print("📤 Uploading \(images.count - 1) additional images...")
            for (index, image) in images.dropFirst().enumerated() {
                let imageSequence = index + 2
                let imageResult = try await processAndUploadImage(
                    image: image,
                    mailPackageId: mailPackageId, // Use extracted ID from first upload
                    imageSequence: imageSequence,
                    timestamp: timestamp
                )
                allOcrTexts.append(imageResult.ocrText)
            }
        }
        
        // Extract mail package ID from first upload
        guard let finalMailPackageId = mailPackageId else {
            throw MailProcessingError.processingFailed("Failed to extract mail package ID from first upload")
        }
        
        print("🆔 Mail package ID extracted: \(finalMailPackageId)")
        
        // Save images locally and get their paths
        let imagePaths = await LocalStorageManager.shared.saveMailScans(
            images: images,
            mailPackageId: finalMailPackageId,
            timestamp: timestamp
        )
        
        // Store OCR texts for background processing
        await storeOcrTextsForBackgroundProcessing(
            mailPackageId: finalMailPackageId,
            ocrTexts: allOcrTexts,
            timestamp: timestamp
        )
        
        // Create a mail package with scanning state
        let scanningPackage = MailPackage(
            id: finalMailPackageId,
            panelistId: "extracted-from-api", // This will come from the actual API response
            packageName: "Mail Package \(timestamp)",
            packageDescription: "Mail package processed on \(timestamp)",
            industry: nil,
            brandName: nil,
            companyValidated: nil,
            responseIntention: nil,
            nameCheck: nil,
            status: "processing",
            pointsAwarded: 0,
            isApproved: false,
            processingStatus: .processing,
            createdAt: Date(),
            updatedAt: Date(),
            s3Key: nil,
            imagePaths: imagePaths,
            asyncProcessingState: .scanning,
            processingStartedAt: Date(),
            processingCompletedAt: nil,
            surveyCompletedAt: nil
        )
        
        return scanningPackage
    }
    
    /// Stores OCR texts for background processing
    /// - Parameters:
    ///   - mailPackageId: ID of the mail package
    ///   - ocrTexts: Array of OCR texts
    ///   - timestamp: Timestamp for the package
    private func storeOcrTextsForBackgroundProcessing(
        mailPackageId: String,
        ocrTexts: [String],
        timestamp: String
    ) async {
        // Store OCR texts in local storage for background processing
        // This will be retrieved by the background processing service
        let ocrData = MailPackageOcrData(
            mailPackageId: mailPackageId,
            ocrTexts: ocrTexts,
            timestamp: timestamp
        )
        
        await LocalStorageManager.shared.saveMailPackageOcrData(ocrData)
        print("💾 OCR texts stored for background processing: \(ocrTexts.count) texts")
    }
    
    /// Creates a new mail package and processes the first scan
    /// - Parameters:
    ///   - images: Array of scanned images
    ///   - timestamp: Timestamp when images were captured
    /// - Returns: Created MailPackage
    func createAndProcessMailPackage(
        images: [UIImage],
        timestamp: String
    ) async throws -> MailPackage {
        
        print("🚀 Starting new mail package creation...")
        print("📸 Image count: \(images.count)")
        
        var mailPackageId: String? = nil
        var allOcrTexts: [String] = []
        
        // Step 1: Process and upload first image (creates new mail package)
        print("📤 Uploading first image (creates new mail package)...")
        let firstImageResult = try await processAndUploadImage(
            image: images[0],
            mailPackageId: nil, // nil for new package
            imageSequence: 1,
            timestamp: timestamp
        )
        allOcrTexts.append(firstImageResult.ocrText)
        
        // Extract mail package ID from the first upload response
        mailPackageId = firstImageResult.mailPackageId
        print("🆔 First image upload completed. Mail package ID: \(mailPackageId ?? "nil")")
        
        // Step 2: Process remaining images if any
        if images.count > 1 {
            print("📤 Uploading \(images.count - 1) additional images...")
            for (index, image) in images.dropFirst().enumerated() {
                let imageSequence = index + 2
                let imageResult = try await processAndUploadImage(
                    image: image,
                    mailPackageId: mailPackageId, // Use extracted ID from first upload
                    imageSequence: imageSequence,
                    timestamp: timestamp
                )
                allOcrTexts.append(imageResult.ocrText)
            }
        }
        
        // Extract mail package ID from first upload
        guard let finalMailPackageId = mailPackageId else {
            throw MailProcessingError.processingFailed("Failed to extract mail package ID from first upload")
        }
        
        print("🆔 Mail package ID extracted: \(finalMailPackageId)")
        
        // Save images locally and get their paths
        let imagePaths = await LocalStorageManager.shared.saveMailScans(
            images: images,
            mailPackageId: finalMailPackageId,
            timestamp: timestamp
        )
        
        // Create a placeholder mail package (will be updated after AI processing)
        let placeholderPackage = MailPackage(
            id: finalMailPackageId,
            panelistId: "extracted-from-api", // This will come from the actual API response
            packageName: "Mail Package \(timestamp)",
            packageDescription: "Mail package processed on \(timestamp)",
            industry: nil,
            brandName: nil,
            companyValidated: nil,
            responseIntention: nil,
            nameCheck: nil,
            status: "processing",
            pointsAwarded: 0,
            isApproved: false,
            createdAt: Date(),
            updatedAt: Date(),
            s3Key: nil,
            imagePaths: imagePaths
        )
        
        return placeholderPackage
    }
    
    /// Processes and uploads a single image within an existing mail package
    /// - Parameters:
    ///   - image: UIImage to process
    ///   - mailPackageId: ID of the mail package (nil for new package)
    ///   - imageSequence: Sequence number of the image
    ///   - timestamp: Timestamp for filename
    /// - Returns: Tuple of (OCR text, mail package ID if created)
    func processAndUploadImage(
        image: UIImage,
        mailPackageId: String?,
        imageSequence: Int,
        timestamp: String
    ) async throws -> (ocrText: String, mailPackageId: String?) {
        
        print("📸 Processing image \(imageSequence) for package \(mailPackageId ?? "nil")")
        
        // Step 1: Perform OCR on the image
        let ocrText = try await ocrService.extractText(from: image)
        print("✅ OCR completed for image \(imageSequence). Text length: \(ocrText.count) characters")
        
        // Step 2: Save image to local storage
        let filename = "\(timestamp)_\(imageSequence).jpg"
        let imageData = image.jpegData(compressionQuality: 0.8) ?? Data()
        let base64Data = imageData.base64EncodedString()
        
        // Step 3: Upload image via API
        let uploadRequest = MailScanUploadRequest(
            mailPackageId: mailPackageId, // nil for new package, existing ID for additional scans
            documentType: "scan",
            imageSequence: imageSequence,
            fileData: base64Data,
            filename: filename,
            mimeType: "image/jpeg",
            metadata: ["timestamp": timestamp, "sequence": "\(imageSequence)"]
        )
        
        print("📤 Uploading image \(imageSequence) with package ID: \(mailPackageId ?? "NEW")")
        let uploadResponse = try await apiService.uploadMailScan(request: uploadRequest)
        
        guard uploadResponse.success else {
            throw MailProcessingError.uploadFailed(uploadResponse.message)
        }
        
        print("✅ Image \(imageSequence) uploaded successfully")
        
                    // Extract mail package ID from response if this is a new package
            var extractedMailPackageId: String? = mailPackageId
            if mailPackageId == nil && uploadResponse.uploadType == "scan" {
                extractedMailPackageId = uploadResponse.scan?.mailpackId
                print("🆔 Extracted new mail package ID: \(extractedMailPackageId ?? "nil")")
            }
        
        return (ocrText: ocrText, mailPackageId: extractedMailPackageId)
    }
    
    /// Completes a mail package by processing all images and calling the AI processing API
    /// - Parameters:
    ///   - mailPackageId: ID of the mail package to complete
    ///   - allOcrTexts: Array of OCR texts in sequence order
    ///   - timestamp: Timestamp for the package
    /// - Returns: ProcessingResult with AI analysis
    func completeMailPackage(
        mailPackageId: String,
        allOcrTexts: [String],
        timestamp: String
    ) async throws -> ProcessingResult {
        
        print("🎯 Completing mail package \(mailPackageId)")
        print("📝 Total OCR texts: \(allOcrTexts.count)")
        
        // Step 1: Combine all OCR texts in sequence order
        let combinedOcrText = allOcrTexts.enumerated().map { index, text in
            "--- Image \(index + 1) ---\n\(text)\n\n"
        }.joined()
        
        print("✅ OCR texts combined. Total length: \(combinedOcrText.count) characters")
        
        // Step 2: Save combined OCR text as document
        let ocrFilename = "\(timestamp)_ocr.txt"
        let ocrData = combinedOcrText.data(using: .utf8) ?? Data()
        let base64Ocr = ocrData.base64EncodedString()
        
        let ocrUploadRequest = MailScanUploadRequest(
            mailPackageId: mailPackageId,
            documentType: "ocr_text",
            imageSequence: nil,
            fileData: base64Ocr,
            filename: ocrFilename,
            mimeType: "text/plain",
            metadata: ["type": "combined_ocr", "image_count": "\(allOcrTexts.count)"]
        )
        
        print("📤 Uploading combined OCR text as document...")
        let ocrUploadResponse = try await apiService.uploadMailScan(request: ocrUploadRequest)
        
        guard ocrUploadResponse.success else {
            throw MailProcessingError.uploadFailed(ocrUploadResponse.message)
        }
        
        print("✅ Combined OCR text uploaded successfully")
        
        // Step 3: Call AI processing API
        print("🤖 Calling AI processing API...")
        print("📝 Input text length: \(combinedOcrText.count)")
        print("📝 Mail package ID: \(mailPackageId)")
        
        let processRequest = ProcessMailPackageRequest(
            inputText: combinedOcrText,
            processingNotes: "Combined OCR text from \(allOcrTexts.count) images"
        )
        
        print("📤 Process request created, calling API...")
        let processingResponse = try await apiService.processMailPackage(mailPackageId: mailPackageId, request: processRequest)
        
        guard processingResponse.success else {
            throw MailProcessingError.processingFailed("AI processing failed")
        }
        
        let result = processingResponse.processingResult
        print("✅ AI processing completed successfully")
        print("🏭 Industry: \(result.industry)")
        print("🎁 Primary Offer: \(result.primaryOffer ?? "None")")
        print("🏢 Brand Name: \(result.brandName ?? "None")")
        print("📊 Response Intention: \(result.responseIntention ?? "None")")
        print("🔍 Name Check: \(result.nameCheck ?? "None")")
        print("⚡ Urgency Level: \(result.urgencyLevel ?? "None")")
        print("💰 Estimated Value: \(result.estimatedValue ?? "None")")
        
        return result
    }
    
    /// Updates a mail package with survey results and final information
    /// - Parameters:
    ///   - mailPackageId: ID of the mail package
    ///   - survey: Survey results from user
    /// - Returns: Updated MailPackage
    func updateMailPackageWithSurvey(
        mailPackageId: String,
        survey: MailPackageSurvey
    ) async throws -> MailPackage {
        
        print("📊 Updating mail package \(mailPackageId) with survey results")
        
        let updateRequest = UpdateMailPackageRequest(
            brandName: survey.brandName ?? "Unknown",
            industry: survey.industry,
            companyValidated: true,
            responseIntention: survey.intentionAnswer,
            nameCheck: survey.recipientAnswer ?? "unknown",
            notes: "Survey completed",
            status: "completed",
            isApproved: true,
            processingNotes: "Survey results processed"
        )
        
        print("📤 Updating mail package with survey results...")
        let updateResponse = try await apiService.updateMailPackage(
            mailPackageId: mailPackageId,
            request: updateRequest
        )
        
        guard updateResponse.success else {
            throw MailProcessingError.updateFailed("Failed to update mail package")
        }
        
        print("✅ Mail package updated successfully with survey results")
        return updateResponse.mailPackage
    }
}

// MARK: - Mail Processing Errors
enum MailProcessingError: Error, LocalizedError {
    case uploadFailed(String)
    case processingFailed(String)
    case updateFailed(String)
    case ocrProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .uploadFailed(let reason):
            return "Upload failed: \(reason)"
        case .processingFailed(let reason):
            return "Processing failed: \(reason)"
        case .updateFailed(let reason):
            return "Update failed: \(reason)"
        case .ocrProcessingFailed:
            return "OCR processing failed"
        }
    }
}
