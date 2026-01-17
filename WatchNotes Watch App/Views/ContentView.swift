//
//  ContentView.swift
//  WatchNotes Watch App
//
//  This is the root view that sets up navigation for the app.
//  It wraps NotesListView in a NavigationStack for screen transitions.
//

import SwiftUI

/// ContentView serves as the root container for navigation
/// NavigationStack manages the "stack" of views as you navigate deeper
struct ContentView: View {

    var body: some View {
        // NavigationStack enables navigation between views
        // Views can use NavigationLink to push new screens onto the stack
        NavigationStack {
            NotesListView()
        }
    }
}

// MARK: - Preview

/// #Preview lets you see this view in Xcode's canvas without running the app
#Preview {
    ContentView()
}
