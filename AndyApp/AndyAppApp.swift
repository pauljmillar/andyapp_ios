//
//  AndyAppApp.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
struct AndyAppApp: App {
    @StateObject private var authManager = ClerkAuthManager.shared
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Set up push notifications
        setupPushNotifications()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    MainTabView()
                } else {
                    ClerkSignInView()
                }
            }
            .environmentObject(authManager)
        }
    }
    
    // MARK: - Push Notifications Setup
    private func setupPushNotifications() {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Push notification permission granted")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("❌ Push notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        
        // Set messaging delegate
        Messaging.messaging().delegate = NotificationDelegate.shared
        
        // Set notification center delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
}

