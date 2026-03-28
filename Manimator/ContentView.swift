//
//  ContentView.swift
//  Manimator
//
//  Main layout: HSplitView with visual canvas (left/center), code editor (right-top),
//  and object inspector (right-bottom). Toolbar with Add, Render, and settings.
//

import SwiftUI
import AVKit

struct ContentView: View {
    @State private var sceneState = SceneState()
    @State private var renderer = ManimRenderer()
    @State private var showAddPanel = false
    @State private var showConsole = false
    @State private var showSettings = false
    @State private var showObjectList = true
    @State private var showTimeline = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content
            HSplitView {
                // Left: Visual Canvas
                VStack(spacing: 0) {
                    // Canvas header
                    HStack {
                        Image(systemName: "paintbrush.pointed")
                            .foregroundStyle(.secondary)
                        Text("Canvas")
                            .font(.headline)
                        Spacer()
                        Text("Manim Coordinates")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(nsColor: .controlBackgroundColor))
                    
                    Divider()
                    
                    // Canvas + video overlay
                    ZStack {
                        DraggableOverlayView(sceneState: sceneState)
                        
                        // Video preview overlay (shown after render)
                        if renderer.videoURL != nil {
                            VideoPreviewOverlay(renderer: renderer)
                        }
                    }
                }
                .frame(minWidth: 400, idealWidth: 600)
                
                // Right: Code + Inspector
                VSplitView {
                    // Code editor (auto-generated or manual)
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .foregroundStyle(.secondary)
                            Text("Generated Code")
                                .font(.headline)
                            Spacer()
                            
                            // Manual/Auto toggle
                            Toggle(isOn: $sceneState.isManualCodeMode) {
                                Text(sceneState.isManualCodeMode ? "Manual" : "Auto")
                                    .font(.caption)
                            }
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .help(sceneState.isManualCodeMode
                                  ? "Code is manually editable. Click 'Reparse' to sync objects."
                                  : "Code auto-generates from visual objects.")
                            
                            if sceneState.isManualCodeMode {
                                Button("Reparse") {
                                    sceneState.parseObjectsFromCode()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(nsColor: .controlBackgroundColor))
                        
                        Divider()
                        
                        TextEditor(text: sceneState.isManualCodeMode
                                   ? $sceneState.generatedCode
                                   : .constant(sceneState.generatedCode))
                            .font(.system(.body, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .background(Color(nsColor: .textBackgroundColor))
                            .disabled(!sceneState.isManualCodeMode)
                            .opacity(sceneState.isManualCodeMode ? 1.0 : 0.8)
                    }
                    .frame(minHeight: 150)
                    
                    // Inspector sidebar
                    if showObjectList {
                        ObjectListView(sceneState: sceneState)
                            .frame(minHeight: 200, idealHeight: 350)
                    }
                }
                .frame(minWidth: 260, idealWidth: 340)
            }
            
            // Timeline
            if showTimeline {
                Divider()
                TimelineView(sceneState: sceneState)
            }
            
            // Console (collapsible)
            if showConsole {
                Divider()
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "terminal")
                            .foregroundStyle(.secondary)
                        Text("Console")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button { renderer.consoleOutput = "" } label: {
                            Image(systemName: "trash").font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    
                    ScrollView {
                        Text(renderer.consoleOutput.isEmpty ? "No output yet." : renderer.consoleOutput)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(renderer.consoleOutput.isEmpty ? .tertiary : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .textSelection(.enabled)
                    }
                }
                .frame(height: 120)
                .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
            }
            
            Divider()
            
            // Bottom toolbar
            HStack(spacing: 12) {
                // Add object
                Button {
                    showAddPanel.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                }
                .buttonStyle(.bordered)
                .popover(isPresented: $showAddPanel) {
                    AddObjectPanel(sceneState: sceneState)
                }
                
                // Duplicate
                Button {
                    if let sel = sceneState.selectedObjectID {
                        sceneState.duplicateObject(id: sel)
                    }
                } label: {
                    Image(systemName: "plus.square.on.square")
                }
                .buttonStyle(.borderless)
                .disabled(sceneState.selectedObjectID == nil)
                .help("Duplicate (⌘D)")
                .keyboardShortcut("d", modifiers: .command)
                
                // Delete
                Button {
                    if let sel = sceneState.selectedObjectID {
                        sceneState.deleteObject(id: sel)
                    }
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .disabled(sceneState.selectedObjectID == nil)
                .help("Delete selected")
                
                Divider().frame(height: 20)
                
                // Render
                Button {
                    sceneState.regenerateCode()
                    renderer.render(code: sceneState.generatedCode, sceneName: sceneState.sceneName)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                        Text("Render")
                    }
                    .font(.system(.body, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(renderer.isRendering || sceneState.objects.isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
                
                Picker("", selection: $renderer.qualityFlag) {
                    Text("Low").tag("-ql")
                    Text("Med").tag("-qm")
                    Text("High").tag("-qh")
                }
                .labelsHidden()
                .frame(width: 80)
                
                if renderer.isRendering {
                    ProgressView()
                        .controlSize(.small)
                    Text(renderer.progress)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(renderer.progress)
                        .font(.caption)
                        .foregroundStyle(renderer.errorMessage != nil ? .red : .secondary)
                }
                
                if let err = renderer.errorMessage {
                    Text(String(err.prefix(60)))
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                        .help(err)
                }
                
                Spacer()
                
                Button { showConsole.toggle() } label: {
                    Image(systemName: showConsole ? "terminal.fill" : "terminal")
                }
                .buttonStyle(.borderless)
                .help("Toggle Console")
                
                Button { showTimeline.toggle() } label: {
                    Image(systemName: "film")
                }
                .buttonStyle(.borderless)
                .help("Toggle Timeline")
                
                Button { showObjectList.toggle() } label: {
                    Image(systemName: "sidebar.right")
                }
                .buttonStyle(.borderless)
                .help("Toggle Inspector")
                
                Button { showSettings.toggle() } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.borderless)
                .popover(isPresented: $showSettings) {
                    SettingsPopover(renderer: renderer, sceneState: sceneState)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .onAppear {
            sceneState.regenerateCode()
        }
    }
}

// MARK: - Video Preview Overlay

struct VideoPreviewOverlay: View {
    @Bindable var renderer: ManimRenderer
    @State private var showVideo = true
    
    var body: some View {
        if showVideo, let url = renderer.videoURL {
            ZStack(alignment: .topTrailing) {
                VideoPlayer(player: AVPlayer(url: url))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(radius: 10)
                    .padding(20)
                
                Button {
                    showVideo = false
                    renderer.videoURL = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .buttonStyle(.borderless)
                .padding(28)
            }
        }
    }
}

// MARK: - Settings Popover

struct SettingsPopover: View {
    @Bindable var renderer: ManimRenderer
    @Bindable var sceneState: SceneState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Scene Name")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("MyScene", text: $sceneState.sceneName)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: sceneState.sceneName) { _, _ in
                        sceneState.regenerateCode()
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Manim Executable Path")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Path", text: $renderer.manimExecutablePath)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Quality")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Quality", selection: $renderer.qualityFlag) {
                    Text("Low (480p15)").tag("-ql")
                    Text("Medium (720p30)").tag("-qm")
                    Text("High (1080p60)").tag("-qh")
                    Text("4K (2160p60)").tag("-qk")
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }
        }
        .padding()
        .frame(width: 320)
    }
}

#Preview {
    ContentView()
        .frame(width: 1200, height: 750)
}
