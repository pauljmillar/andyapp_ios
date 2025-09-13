//
//  APIService+PushNotifications.swift
//  AndyApp
//
//  Created by Paul Millar on 9/7/25.
//

import Foundation

extension APIService {
    
    // MARK: - FCM Token Management
    
    /// Send FCM token to server for push notifications
    func updateFCMToken(_ token: String) async throws {
        guard let url = URL(string: "https://survey-khaki-chi.vercel.app/api/panelist/fcm-token") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication token
        let authToken = try await ClerkAuthManager.shared.generateJWTToken()
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        let body = ["fcm_token": token]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    /// Remove FCM token from server (for logout)
    func removeFCMToken() async throws {
        guard let url = URL(string: "https://survey-khaki-chi.vercel.app/api/panelist/fcm-token") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        // Add authentication token
        let authToken = try await ClerkAuthManager.shared.generateJWTToken()
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Push Notification Preferences
    
    /// Update push notification preferences
    func updateNotificationPreferences(_ preferences: NotificationPreferences) async throws {
        guard let url = URL(string: "https://survey-khaki-chi.vercel.app/api/panelist/notification-preferences") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication token
        let authToken = try await ClerkAuthManager.shared.generateJWTToken()
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(preferences)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    /// Get push notification preferences
    func getNotificationPreferences() async throws -> NotificationPreferences {
        guard let url = URL(string: "https://survey-khaki-chi.vercel.app/api/panelist/notification-preferences") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authentication token
        let authToken = try await ClerkAuthManager.shared.generateJWTToken()
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(NotificationPreferences.self, from: data)
    }
}

// MARK: - Notification Preferences Model
struct NotificationPreferences: Codable, Equatable {
    var surveys: Bool
    var mailProcessing: Bool
    var pointsEarned: Bool
    var promotions: Bool
    var reminders: Bool
    
    enum CodingKeys: String, CodingKey {
        case surveys
        case mailProcessing = "mail_processing"
        case pointsEarned = "points_earned"
        case promotions
        case reminders
    }
}
