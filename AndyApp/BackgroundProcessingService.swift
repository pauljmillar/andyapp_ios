//
//  BackgroundProcessingService.swift
//  AndyApp
//
//  Created by Paul Millar on 9/15/25.
//

import Foundation
import UIKit
import Combine

/// Service that manages background processing of mail packages
/// Handles the asynchronous execution of steps 5-7 (AI processing)
class BackgroundProcessingService: ObservableObject {
    static let shared = BackgroundProcessingService()
    
    // MARK: - Published Properties
    @Published var processingQueue: [String] = [] // Mail package IDs
    @Published var isProcessing = false
    @Published var processingStatus: [String: BackgroundProcessingStatus] = [:] // packageId -> status
    
    // MARK: - Private Properties
    private let mailProcessingService = MailProcessingService.shared
    private let apiService = APIService.shared
    private var processingTask: Task<Void, Never>?
    private let queue = DispatchQueue(label: "background.processing", qos: .background)
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Queues a mail package for background processing
    /// - Parameter mailPackageId: ID of the mail package to process
    func queueMailPackage(_ mailPackageId: String) async {
        print("🔄 Queueing mail package \(mailPackageId) for background processing")
        
        await MainActor.run {
            // Add to queue if not already present
            if !self.processingQueue.contains(mailPackageId) {
                self.processingQueue.append(mailPackageId)
                self.processingStatus[mailPackageId] = .queued
            }
        }
        
        // Start processing if not already running
        await startProcessingIfNeeded()
    }
    
    /// Gets the current processing status for a mail package
    /// - Parameter mailPackageId: ID of the mail package
    /// - Returns: Current processing status
    func getProcessingStatus(for mailPackageId: String) -> BackgroundProcessingStatus {
        return processingStatus[mailPackageId] ?? .unknown
    }
    
    /// Removes a mail package from the processing queue
    /// - Parameter mailPackageId: ID of the mail package to remove
    func removeFromQueue(_ mailPackageId: String) async {
        await MainActor.run {
            self.processingQueue.removeAll { $0 == mailPackageId }
            self.processingStatus.removeValue(forKey: mailPackageId)
        }
    }
    
    // MARK: - Private Methods
    
    /// Starts processing if not already running
    private func startProcessingIfNeeded() async {
        guard !isProcessing else { return }
        
        await MainActor.run {
            self.isProcessing = true
        }
        
        // Start background processing task
        processingTask = Task {
            await processQueue()
        }
    }
    
    /// Processes the queue of mail packages
    private func processQueue() async {
        while !processingQueue.isEmpty {
            let packageId = await getNextPackageToProcess()
            guard let packageId = packageId else { break }
            
            await processMailPackage(packageId)
        }
        
        await MainActor.run {
            self.isProcessing = false
        }
    }
    
    /// Gets the next package to process from the queue
    private func getNextPackageToProcess() async -> String? {
        return await MainActor.run {
            guard !self.processingQueue.isEmpty else { return nil }
            return self.processingQueue.removeFirst()
        }
    }
    
    /// Processes a single mail package through steps 5-7
    private func processMailPackage(_ mailPackageId: String) async {
        print("🚀 Starting background processing for mail package \(mailPackageId)")
        
        await MainActor.run {
            self.processingStatus[mailPackageId] = .processing
            
            // Notify UI of status change
            NotificationCenter.default.post(
                name: NSNotification.Name("MailPackageStatusUpdated"),
                object: nil,
                userInfo: ["mailPackageId": mailPackageId, "status": "processing"]
            )
        }
        
        do {
            // Step 5-7: AI Processing
            // Get the stored OCR texts for this mail package
            guard let ocrData = await LocalStorageManager.shared.getMailPackageOcrData(for: mailPackageId) else {
                throw MailProcessingError.processingFailed("No OCR data found for package \(mailPackageId)")
            }
            
            print("📝 Found OCR data for package \(mailPackageId): \(ocrData.ocrTexts.count) texts")
            
            // Process the mail package with AI
            let processingResult = try await mailProcessingService.completeMailPackage(
                mailPackageId: mailPackageId,
                allOcrTexts: ocrData.ocrTexts,
                timestamp: ocrData.timestamp
            )
            
            print("🤖 AI processing completed for package \(mailPackageId)")
            print("🏭 Industry: \(processingResult.industry)")
            print("🎁 Primary Offer: \(processingResult.primaryOffer ?? "None")")
            
            // Update the mail package with processing results
            await updateMailPackageWithProcessingResult(
                mailPackageId: mailPackageId,
                processingResult: processingResult
            )
            
            // Clean up OCR data as it's no longer needed
            await LocalStorageManager.shared.removeMailPackageOcrData(for: mailPackageId)
            
            // Mark as ready for survey
            await MainActor.run {
                self.processingStatus[mailPackageId] = .readyForSurvey
                
                // Notify UI of status change
                NotificationCenter.default.post(
                    name: NSNotification.Name("MailPackageStatusUpdated"),
                    object: nil,
                    userInfo: ["mailPackageId": mailPackageId, "status": "readyForSurvey"]
                )
            }
            
            print("✅ Background processing completed for package \(mailPackageId)")
            
        } catch {
            print("❌ Background processing failed for package \(mailPackageId): \(error)")
            await MainActor.run {
                self.processingStatus[mailPackageId] = .failed
            }
        }
    }
    
    /// Updates a mail package with AI processing results
    private func updateMailPackageWithProcessingResult(
        mailPackageId: String,
        processingResult: ProcessingResult
    ) async {
        // Get the current mail package from local storage
        let packages = await LocalStorageManager.shared.getMailPackages()
        guard let packageIndex = packages.firstIndex(where: { $0.id == mailPackageId }) else {
            print("❌ Could not find mail package \(mailPackageId) for update")
            return
        }
        
        var updatedPackage = packages[packageIndex]
        
        // Create updated package with processing results
        let processedPackage = MailPackage(
            id: updatedPackage.id,
            panelistId: updatedPackage.panelistId,
            packageName: updatedPackage.packageName,
            packageDescription: updatedPackage.packageDescription,
            industry: processingResult.industry,
            brandName: processingResult.brandName,
            primaryOffer: processingResult.primaryOffer,
            companyValidated: updatedPackage.companyValidated,
            responseIntention: updatedPackage.responseIntention,
            nameCheck: updatedPackage.nameCheck,
            status: updatedPackage.status,
            pointsAwarded: updatedPackage.pointsAwarded,
            isApproved: updatedPackage.isApproved,
            processingStatus: updatedPackage.processingStatus,
            createdAt: updatedPackage.createdAt,
            updatedAt: Date(), // Update timestamp
            s3Key: updatedPackage.s3Key,
            imagePaths: updatedPackage.imagePaths,
            asyncProcessingState: .readyForSurvey,
            processingStartedAt: updatedPackage.processingStartedAt,
            processingCompletedAt: Date(),
            surveyCompletedAt: nil
        )
        
        // Save the updated package
        await LocalStorageManager.shared.saveMailPackage(processedPackage)
        
        // Notify the UI that a mail package has been updated
        await MainActor.run {
            NotificationCenter.default.post(
                name: NSNotification.Name("MailPackageUpdated"),
                object: nil,
                userInfo: ["mailPackageId": mailPackageId]
            )
        }
        
        print("✅ Updated mail package \(mailPackageId) with processing results")
    }
}

// MARK: - Background Processing Status Enum
enum BackgroundProcessingStatus: String, CaseIterable {
    case unknown = "unknown"
    case queued = "queued"
    case processing = "processing"
    case readyForSurvey = "readyForSurvey"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .queued:
            return "Queued"
        case .processing:
            return "Processing..."
        case .readyForSurvey:
            return "Ready for Survey"
        case .failed:
            return "Failed"
        }
    }
    
    var isCompleted: Bool {
        return self == .readyForSurvey
    }
    
    var isFailed: Bool {
        return self == .failed
    }
    
    var isInProgress: Bool {
        return self == .queued || self == .processing
    }
}
