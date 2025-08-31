//
//  AndyAppApp.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import SwiftUI

@main
struct AndyAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
