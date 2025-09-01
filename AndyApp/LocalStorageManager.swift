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
    
    // MARK: - Mail Package Management
    func saveMailPackage(_ mailPackage: MailPackage) {
        var packages = getMailPackages()
        packages.append(mailPackage)
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
    func saveMailScans(images: [UIImage], mailPackageId: String, timestamp: String) -> [String] {
        createUserDirectoryIfNeeded()
        
        var savedPaths: [String] = []
        
        for (index, image) in images.enumerated() {
            let scanNumber = index + 1
            let fileName = "\(timestamp)_\(scanNumber).jpg"
            let filePath = "\(userStoragePath)/\(fileName)"
            
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                do {
                    try imageData.write(to: URL(fileURLWithPath: filePath))
                    savedPaths.append(filePath)
                    print("✅ Saved mail scan: \(fileName)")
                } catch {
                    print("❌ Failed to save mail scan \(fileName): \(error)")
                }
            }
        }
        
        return savedPaths
    }
    
    func getMailScanImage(at path: String) -> UIImage? {
        return UIImage(contentsOfFile: path)
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
}
