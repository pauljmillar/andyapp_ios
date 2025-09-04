import Foundation

struct BuildInfo {
    /// Returns the marketing version (e.g., "1.0")
    static var version: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    /// Returns the build number (e.g., "1", "2", "3")
    static var buildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    /// Returns the full version string (e.g., "0.0.1 (1)")
    static var fullVersion: String {
        return "\(version) (\(buildNumber))"
    }
    
    /// Returns the build date as a string
    static var buildDate: String {
        if let buildDate = Bundle.main.infoDictionary?["CFBuildDate"] as? String {
            return buildDate
        }
        
        // Fallback: try to get from executable path modification date
        if let executablePath = Bundle.main.executablePath {
            let fileManager = FileManager.default
            if let attributes = try? fileManager.attributesOfItem(atPath: executablePath),
               let modificationDate = attributes[.modificationDate] as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                return formatter.string(from: modificationDate)
            }
        }
        
        return "Unknown"
    }
}
