//
//  NotificationSettingsView.swift
//  AndyApp
//
//  Created by Paul Millar on 9/7/25.
//

import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @StateObject private var pushManager = PushNotificationManager.shared
    @State private var preferences = NotificationPreferences(
        surveys: true,
        mailProcessing: true,
        pointsEarned: true,
        promotions: false,
        reminders: true
    )
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                // Permission Status Section
                Section {
                    HStack {
                        Image(systemName: pushManager.isPermissionGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(pushManager.isPermissionGranted ? .green : .red)
                        
                        VStack(alignment: .leading) {
                            Text("Push Notifications")
                                .font(AppTypography.body)
                            Text(pushManager.isPermissionGranted ? "Enabled" : "Disabled")
                                .font(AppTypography.caption1)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        if !pushManager.isPermissionGranted {
                            Button("Enable") {
                                Task {
                                    await requestPermission()
                                }
                            }
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.primaryGreen)
                        }
                    }
                    
                    if let token = pushManager.fcmToken {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Device Token")
                                .font(AppTypography.caption1)
                                .foregroundColor(AppColors.textSecondary)
                            
                            Text(token)
                                .font(AppTypography.caption2)
                                .foregroundColor(AppColors.textSecondary)
                                .lineLimit(2)
                        }
                    }
                } header: {
                    Text("Status")
                }
                
                // Notification Preferences Section
                if pushManager.isPermissionGranted {
                    Section {
                        Toggle("Survey Notifications", isOn: $preferences.surveys)
                            .font(AppTypography.body)
                        
                        Toggle("Mail Processing Updates", isOn: $preferences.mailProcessing)
                            .font(AppTypography.body)
                        
                        Toggle("Points Earned", isOn: $preferences.pointsEarned)
                            .font(AppTypography.body)
                        
                        Toggle("Promotions & Offers", isOn: $preferences.promotions)
                            .font(AppTypography.body)
                        
                        Toggle("Reminders", isOn: $preferences.reminders)
                            .font(AppTypography.body)
                    } header: {
                        Text("Notification Types")
                    } footer: {
                        Text("Choose which types of notifications you'd like to receive.")
                    }
                }
                
                // Test Notifications Section
                if pushManager.isPermissionGranted {
                    Section {
                        Button("Send Test Notification") {
                            sendTestNotification()
                        }
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.primaryGreen)
                        
                        Button("Send Survey Reminder") {
                            sendSurveyReminder()
                        }
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.primaryGreen)
                    } header: {
                        Text("Test Notifications")
                    } footer: {
                        Text("Send test notifications to verify everything is working.")
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadPreferences()
            }
            .onChange(of: preferences) { newValue in
                savePreferences()
            }
            .alert("Notification Settings", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func requestPermission() async {
        let granted = await pushManager.requestPermission()
        
        if granted {
            // Get FCM token and send to server
            if let token = await pushManager.getFCMToken() {
                await pushManager.sendTokenToServer(token)
            }
        }
    }
    
    private func loadPreferences() {
        Task {
            do {
                let prefs = try await APIService.shared.getNotificationPreferences()
                await MainActor.run {
                    self.preferences = prefs
                }
            } catch {
                print("❌ Failed to load notification preferences: \(error)")
                // Keep default preferences
            }
        }
    }
    
    private func savePreferences() {
        Task {
            do {
                try await APIService.shared.updateNotificationPreferences(preferences)
                await MainActor.run {
                    self.alertMessage = "Notification preferences updated successfully!"
                    self.showingAlert = true
                }
            } catch {
                await MainActor.run {
                    self.alertMessage = "Failed to update preferences: \(error.localizedDescription)"
                    self.showingAlert = true
                }
            }
        }
    }
    
    private func sendTestNotification() {
        pushManager.scheduleLocalNotification(
            title: "Test Notification",
            body: "This is a test notification from AndyApp!",
            timeInterval: 2.0
        )
    }
    
    private func sendSurveyReminder() {
        pushManager.scheduleLocalNotification(
            title: "New Survey Available!",
            body: "Complete a quick survey and earn 50 points.",
            timeInterval: 3.0,
            userInfo: ["survey_id": "test_survey_123"]
        )
    }
}

#Preview {
    NotificationSettingsView()
}
