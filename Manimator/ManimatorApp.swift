//
//  ManimatorApp.swift
//  Manimator
//
//  Main entry point. Configures the window with a minimum size and title.
//

import SwiftUI

@main
struct ManimatorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 750)
    }
}
