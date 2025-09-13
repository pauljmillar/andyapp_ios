//
//  NotificationDelegate.swift
//  AndyApp
//
//  Created by Paul Millar on 9/7/25.
//

import Foundation
import FirebaseMessaging
import UserNotifications
import UIKit

class NotificationDelegate: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    private override init() {
        super.init()
    }
    
    // MARK: - APNS Token Handling
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("📱 APNS device token received: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
        
        // Set the APNS token for Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
        
        // Now we can get the FCM token
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ Error getting FCM token: \(error)")
            } else if let token = token {
                print("🔥 FCM Registration Token: \(token)")
                // Send token to server
                self.sendTokenToServer(token)
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
    }
    
    // MARK: - MessagingDelegate
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔥 FCM Registration Token: \(fcmToken ?? "No token")")
        
        // Send token to your server
        if let token = fcmToken {
            sendTokenToServer(token)
        }
    }
    
    private func sendTokenToServer(_ token: String) {
        // TODO: Send FCM token to your backend server
        // This allows your server to send push notifications to this device
        print("📤 Sending FCM token to server: \(token)")
        
        // Example API call to your backend:
        // APIService.shared.updateFCMToken(token) { result in
        //     switch result {
        //     case .success:
        //         print("✅ FCM token sent to server successfully")
        //     case .failure(let error):
        //         print("❌ Failed to send FCM token: \(error)")
        //     }
        // }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    // Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("📱 Received notification in foreground: \(notification.request.content.title)")
        
        // Show notification even when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }
    
    // Handle notification taps
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("👆 User tapped notification: \(response.notification.request.content.title)")
        
        // Handle notification tap - navigate to relevant screen
        handleNotificationTap(response.notification)
        
        completionHandler()
    }
    
    private func handleNotificationTap(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        
        // Extract custom data from notification
        if let surveyId = userInfo["survey_id"] as? String {
            // Navigate to specific survey
            print("📋 Navigate to survey: \(surveyId)")
            // TODO: Implement navigation to survey
        } else if let mailPackageId = userInfo["mail_package_id"] as? String {
            // Navigate to mail package
            print("📬 Navigate to mail package: \(mailPackageId)")
            // TODO: Implement navigation to mail package
        } else {
            // Default navigation
            print("🏠 Navigate to home")
            // TODO: Implement default navigation
        }
    }
}
