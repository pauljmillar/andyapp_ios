import UIKit
import FirebaseMessaging
import UserNotifications
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set messaging delegate
        Messaging.messaging().delegate = NotificationDelegate.shared
        
        // Set notification center delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        return true
    }
    
    // MARK: - APNS Token Handling
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("📱 APNS device token received in AppDelegate: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
        
        // Set the APNS token for Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
        
        // Wait a moment for Firebase to process the APNS token, then get FCM token
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Messaging.messaging().token { token, error in
                if let error = error {
                    print("❌ Error getting FCM token: \(error)")
                } else if let token = token {
                    print("🔥 FCM Registration Token: \(token)")
                    // Send token to server
                    Task {
                        await NotificationDelegate.shared.sendTokenToServer(token)
                    }
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
    }
    
    // MARK: - URL Scheme Handling for Google Sign-In
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}
