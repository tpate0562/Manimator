//
//  ManimatorApp.swift
//  Manimator
//
//  Main entry point. Configures the window with a minimum size and title.
//

import SwiftUI
import UniformTypeIdentifiers

@main
struct ManimatorApp: App {
    @State private var sceneState = SceneState()
    
    var body: some Scene {
        WindowGroup {
            ContentView(sceneState: sceneState)
                .frame(minWidth: 1000, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 750)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New") {
                    sceneState.objects.removeAll()
                    sceneState.timeline.removeAll()
                    sceneState.objectCounters.removeAll()
                    sceneState.sceneName = "MyScene"
                    sceneState.selectedObjectID = nil
                    sceneState.selectedStepID = nil
                    sceneState.regenerateCode()
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("Open...") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.allowedContentTypes = [.json]
                    if panel.runModal() == .OK, let url = panel.url {
                        if let data = try? Data(contentsOf: url) {
                            sceneState.importJSON(data: data)
                        }
                    }
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Button("Save As...") {
                    let panel = NSSavePanel()
                    panel.allowedContentTypes = [.json]
                    panel.nameFieldStringValue = "\(sceneState.sceneName).json"
                    if panel.runModal() == .OK, let url = panel.url {
                        if let data = sceneState.exportJSON() {
                            try? data.write(to: url)
                        }
                    }
                }
                .keyboardShortcut("s", modifiers: .command)
            }
        }
    }
}
