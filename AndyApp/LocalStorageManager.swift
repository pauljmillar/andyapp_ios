//
//  LocalStorageManager.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import Foundation
import UIKit

@MainActor
class LocalStorageManager {
    static let shared = LocalStorageManager()
    
    private init() {}
    
    // MARK: - User-specific storage paths
    private var userStoragePath: String {
        let userId = ClerkAuthManager.shared.currentUser?.id ?? "anonymous"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("users/\(userId)/mail").path
    }
    
    private var mailPackagesPath: String {
        return "\(userStoragePath)/packages.json"
    }
    
    private var ocrDataPath: String {
        return "\(userStoragePath)/ocr_data.json"
    }
    
    // MARK: - Mail Package Management
    func saveMailPackage(_ mailPackage: MailPackage) {
        var packages = getMailPackages()
        
        // Check if package already exists and update it
        if let existingIndex = packages.firstIndex(where: { $0.id == mailPackage.id }) {
            packages[existingIndex] = mailPackage
        } else {
            packages.append(mailPackage)
        }
        
        saveMailPackages(packages)
    }
    
    func getMailPackages() -> [MailPackage] {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: mailPackagesPath)),
              let packages = try? JSONDecoder().decode([MailPackage].self, from: data) else {
            return []
        }
        return packages
    }
    
    private func saveMailPackages(_ packages: [MailPackage]) {
        createUserDirectoryIfNeeded()
        
        do {
            let data = try JSONEncoder().encode(packages)
            try data.write(to: URL(fileURLWithPath: mailPackagesPath))
        } catch {
            print("❌ Failed to save mail packages: \(error)")
        }
    }
    
    // MARK: - Mail Scan Management
    func saveMailScans(images: [UIImage], mailPackageId: String, timestamp: String) async -> [String] {
        createUserDirectoryIfNeeded()
        
        var savedPaths: [String] = []
        
        for (index, image) in images.enumerated() {
            let scanNumber = index + 1
            let fileName = "\(timestamp)_\(scanNumber).jpg"
            let filePath = "\(userStoragePath)/\(fileName)"
            
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                do {
                    try imageData.write(to: URL(fileURLWithPath: filePath))
                    // Store relative path instead of absolute path
                    savedPaths.append(fileName)
                    print("✅ Saved mail scan: \(fileName)")
                } catch {
                    print("❌ Failed to save mail scan \(fileName): \(error)")
                }
            }
        }
        
        return savedPaths
    }
    
    func getMailScanImage(at path: String) -> UIImage? {
        // If path is already absolute, try it first (for backward compatibility)
        if path.hasPrefix("/") {
            if let image = UIImage(contentsOfFile: path) {
                return image
            }
            // If absolute path fails, try to extract filename and use relative path
            let fileName = URL(fileURLWithPath: path).lastPathComponent
            let relativePath = "\(userStoragePath)/\(fileName)"
            return UIImage(contentsOfFile: relativePath)
        }
        
        // Otherwise, treat it as a relative path and construct the full path
        let fullPath = "\(userStoragePath)/\(path)"
        return UIImage(contentsOfFile: fullPath)
    }
    
    // MARK: - Directory Management
    private func createUserDirectoryIfNeeded() {
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: userStoragePath) {
            do {
                try fileManager.createDirectory(atPath: userStoragePath, withIntermediateDirectories: true)
                print("✅ Created user mail directory: \(userStoragePath)")
            } catch {
                print("❌ Failed to create user mail directory: \(error)")
            }
        }
    }
    
    // MARK: - Migration
    func migrateImagePathsIfNeeded() {
        let packages = getMailPackages()
        var needsUpdate = false
        var updatedPackages: [MailPackage] = []
        
        for package in packages {
            var updatedPackage = package
            
            if let imagePaths = package.imagePaths {
                var updatedImagePaths: [String] = []
                
                for path in imagePaths {
                    if path.hasPrefix("/") {
                        // Convert absolute path to relative path
                        let fileName = URL(fileURLWithPath: path).lastPathComponent
                        updatedImagePaths.append(fileName)
                        needsUpdate = true
                        print("🔄 Migrating image path: \(path) -> \(fileName)")
                    } else {
                        updatedImagePaths.append(path)
                    }
                }
                
                updatedPackage = MailPackage(
                    id: package.id,
                    panelistId: package.panelistId,
                    packageName: package.packageName,
                    packageDescription: package.packageDescription,
                    industry: package.industry,
                    brandName: package.brandName,
                    primaryOffer: package.primaryOffer,
                    companyValidated: package.companyValidated,
                    responseIntention: package.responseIntention,
                    nameCheck: package.nameCheck,
                    status: package.status,
                    pointsAwarded: package.pointsAwarded,
                    isApproved: package.isApproved,
                    processingStatus: package.processingStatus,
                    createdAt: package.createdAt,
                    updatedAt: package.updatedAt,
                    s3Key: package.s3Key,
                    imagePaths: updatedImagePaths
                )
            }
            
            updatedPackages.append(updatedPackage)
        }
        
        if needsUpdate {
            saveMailPackages(updatedPackages)
            print("✅ Migrated image paths for \(updatedPackages.count) mail packages")
        }
    }
    
    // MARK: - Cleanup
    func clearUserData() {
        let fileManager = FileManager.default
        
        do {
            if fileManager.fileExists(atPath: userStoragePath) {
                try fileManager.removeItem(atPath: userStoragePath)
                print("✅ Cleared user mail data")
            }
        } catch {
            print("❌ Failed to clear user mail data: \(error)")
        }
    }
    
    // MARK: - OCR Data Management for Background Processing
    
    /// Saves OCR data for background processing
    func saveMailPackageOcrData(_ ocrData: MailPackageOcrData) {
        var allOcrData = getMailPackageOcrData()
        
        // Remove existing data for this package if it exists
        allOcrData.removeAll { $0.mailPackageId == ocrData.mailPackageId }
        
        // Add new data
        allOcrData.append(ocrData)
        
        saveAllOcrData(allOcrData)
    }
    
    /// Gets OCR data for a specific mail package
    func getMailPackageOcrData(for mailPackageId: String) -> MailPackageOcrData? {
        let allOcrData = getMailPackageOcrData()
        return allOcrData.first { $0.mailPackageId == mailPackageId }
    }
    
    /// Gets all OCR data
    private func getMailPackageOcrData() -> [MailPackageOcrData] {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: ocrDataPath)),
              let ocrData = try? JSONDecoder().decode([MailPackageOcrData].self, from: data) else {
            return []
        }
        return ocrData
    }
    
    /// Saves all OCR data
    private func saveAllOcrData(_ ocrData: [MailPackageOcrData]) {
        do {
            try FileManager.default.createDirectory(atPath: userStoragePath, withIntermediateDirectories: true, attributes: nil)
            let data = try JSONEncoder().encode(ocrData)
            try data.write(to: URL(fileURLWithPath: ocrDataPath))
        } catch {
            print("❌ Failed to save OCR data: \(error)")
        }
    }
    
    /// Removes OCR data for a specific mail package
    func removeMailPackageOcrData(for mailPackageId: String) {
        var allOcrData = getMailPackageOcrData()
        allOcrData.removeAll { $0.mailPackageId == mailPackageId }
        saveAllOcrData(allOcrData)
    }
}
