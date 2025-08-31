//
//  AndyAppApp.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import SwiftUI

@main
struct AndyAppApp: App {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    MainTabView()
                } else {
                    SignInView()
                }
            }
            .environmentObject(authManager)
        }
    }
}
