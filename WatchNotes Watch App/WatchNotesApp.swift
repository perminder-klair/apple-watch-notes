//
//  WatchNotesApp.swift
//  WatchNotes Watch App
//
//  This is the main entry point for your Apple Watch app.
//  It sets up SwiftData for persistent storage and launches the main view.
//

import SwiftUI
import SwiftData

/// The @main attribute marks this as the app's entry point
/// When the app launches, SwiftUI creates an instance of this struct
@main
struct WatchNotesApp: App {

    /// The body property defines the app's scene hierarchy
    /// For watchOS, we use WindowGroup as the main scene
    var body: some Scene {
        WindowGroup {
            // ContentView is our root view that contains the navigation
            ContentView()
        }
        // modelContainer sets up SwiftData persistence for the Note model
        // This automatically creates a database to store your notes locally
        .modelContainer(for: Note.self)
    }
}
