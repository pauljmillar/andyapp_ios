//
//  PushNotificationManager.swift
//  AndyApp
//
//  Created by Paul Millar on 9/7/25.
//

import Foundation
import FirebaseMessaging
import UserNotifications
import UIKit

class PushNotificationManager: ObservableObject {
    static let shared = PushNotificationManager()
    
    @Published var fcmToken: String?
    @Published var isPermissionGranted = false
    
    private init() {}
    
    // MARK: - Permission Management
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            await MainActor.run {
                self.isPermissionGranted = granted
            }
            
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            
            return granted
        } catch {
            print("❌ Error requesting notification permission: \(error)")
            return false
        }
    }
    
    // MARK: - Token Management
    func getFCMToken() async -> String? {
        do {
            let token = try await Messaging.messaging().token()
            await MainActor.run {
                self.fcmToken = token
            }
            return token
        } catch {
            print("❌ Error getting FCM token: \(error)")
            return nil
        }
    }
    
    func sendTokenToServer(_ token: String) async {
        // TODO: Implement API call to your backend
        // This should send the FCM token to your server so it can send push notifications
        
        print("📤 Sending FCM token to server: \(token)")
        
        // Example implementation:
        // do {
        //     try await APIService.shared.updateFCMToken(token)
        //     print("✅ FCM token sent to server successfully")
        // } catch {
        //     print("❌ Failed to send FCM token: \(error)")
        // }
    }
    
    // MARK: - Local Notifications
    func scheduleLocalNotification(
        title: String,
        body: String,
        timeInterval: TimeInterval,
        userInfo: [String: Any] = [:]
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling local notification: \(error)")
            } else {
                print("✅ Local notification scheduled successfully")
            }
        }
    }
    
    // MARK: - Notification Categories
    func setupNotificationCategories() {
        // Survey notification action
        let surveyAction = UNNotificationAction(
            identifier: "SURVEY_ACTION",
            title: "Take Survey",
            options: [.foreground]
        )
        
        // Mail notification action
        let mailAction = UNNotificationAction(
            identifier: "MAIL_ACTION",
            title: "View Mail",
            options: [.foreground]
        )
        
        // Survey category
        let surveyCategory = UNNotificationCategory(
            identifier: "SURVEY_CATEGORY",
            actions: [surveyAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Mail category
        let mailCategory = UNNotificationCategory(
            identifier: "MAIL_CATEGORY",
            actions: [mailAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            surveyCategory,
            mailCategory
        ])
    }
    
    // MARK: - Notification Handling
    func handleNotificationTap(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        
        // Extract custom data and handle navigation
        if let surveyId = userInfo["survey_id"] as? String {
            handleSurveyNotification(surveyId: surveyId)
        } else if let mailPackageId = userInfo["mail_package_id"] as? String {
            handleMailNotification(mailPackageId: mailPackageId)
        } else if let points = userInfo["points"] as? String {
            handlePointsNotification(points: points)
        }
    }
    
    private func handleSurveyNotification(surveyId: String) {
        print("📋 Navigate to survey: \(surveyId)")
        // TODO: Implement navigation to specific survey
        // You can use NotificationCenter to post a notification that your views can observe
        NotificationCenter.default.post(
            name: .navigateToSurvey,
            object: nil,
            userInfo: ["surveyId": surveyId]
        )
    }
    
    private func handleMailNotification(mailPackageId: String) {
        print("📬 Navigate to mail package: \(mailPackageId)")
        // TODO: Implement navigation to specific mail package
        NotificationCenter.default.post(
            name: .navigateToMailPackage,
            object: nil,
            userInfo: ["mailPackageId": mailPackageId]
        )
    }
    
    private func handlePointsNotification(points: String) {
        print("⭐ Points notification: \(points)")
        // TODO: Implement points notification handling
        NotificationCenter.default.post(
            name: .pointsNotification,
            object: nil,
            userInfo: ["points": points]
        )
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let navigateToSurvey = Notification.Name("navigateToSurvey")
    static let navigateToMailPackage = Notification.Name("navigateToMailPackage")
    static let pointsNotification = Notification.Name("pointsNotification")
}
