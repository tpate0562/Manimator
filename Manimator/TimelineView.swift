//
//  TimelineView.swift
//  Manimator
//
//  Video-editor style timeline for ordering animations.
//

import SwiftUI

struct TimelineView: View {
    @Bindable var sceneState: SceneState
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "film")
                    .foregroundStyle(.secondary)
                Text("Timeline")
                    .font(.caption)
                    .fontWeight(.bold)
                Spacer()
                
                Button(action: { sceneState.addTimelineStep() }) {
                    Image(systemName: "plus")
                    Text("Add Step")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .top, spacing: 12) {
                    if sceneState.timeline.isEmpty {
                        Text("No animation steps. Click 'Add Step'.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        ForEach(Array(sceneState.timeline.enumerated()), id: \.element.id) { index, step in
                            TimelineStepView(
                                sceneState: sceneState,
                                step: step,
                                index: index
                            )
                        }
                    }
                }
                .padding(12)
            }
        }
        .frame(height: 180)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
    }
}

struct TimelineStepView: View {
    @Bindable var sceneState: SceneState
    let step: TimelineStep
    let index: Int
    
    @State private var showAddPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Step Header
            HStack {
                Text("Step \(index + 1)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(sceneState.selectedStepID == step.id ? Color.white : Color.primary)
                
                Spacer()
                
                Button(action: { sceneState.deleteTimelineStep(id: step.id) }) {
                    Image(systemName: "xmark")
                        .font(.caption2)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(sceneState.selectedStepID == step.id ? Color.white : Color.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(sceneState.selectedStepID == step.id ? Color.accentColor : Color(nsColor: .windowBackgroundColor))
            .contextMenu {
                Button("Duplicate Step") { sceneState.duplicateTimelineStep(id: step.id) }
                Button("Delete Step", role: .destructive) { sceneState.deleteTimelineStep(id: step.id) }
            }
            
            Divider()
            
            // Animations List
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 4) {
                    if step.animations.isEmpty {
                        HStack(spacing: 4) {
                            Text("Wait")
                            TextField("s", value: Binding(
                                get: { step.waitTime },
                                set: { newVal in
                                    if let idx = sceneState.timeline.firstIndex(where: { $0.id == step.id }) {
                                        sceneState.timeline[idx].waitTime = max(0.1, newVal)
                                        sceneState.regenerateCode()
                                    }
                                }
                            ), format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 40)
                            Text("s")
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                    } else {
                        ForEach(step.animations) { anim in
                            AnimationCell(sceneState: sceneState, stepID: step.id, animation: anim)
                        }
                    }
                }
                .padding(6)
            }
            
            Divider()
            
            // Add Animation Button
            Button(action: { showAddPicker.toggle() }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add Animation")
                }
                .font(.caption2)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderless)
            .padding(6)
            .popover(isPresented: $showAddPicker) {
                AddAnimationPopover(sceneState: sceneState, stepID: step.id)
            }
        }
        .frame(width: 160, height: 120)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(sceneState.selectedStepID == step.id ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .onTapGesture {
            sceneState.selectedStepID = step.id
        }
    }
}

struct AnimationCell: View {
    @Bindable var sceneState: SceneState
    let stepID: UUID
    let animation: ManimAnimation
    
    @State private var showEditPopover = false
    
    var body: some View {
        HStack(spacing: 4) {
            // Icon
            Group {
                if let obj = sceneState.objects.first(where: { $0.id == animation.targetObjectID }) {
                    Image(systemName: obj.iconName)
                        .foregroundStyle(obj.swiftUIColor)
                } else {
                    Image(systemName: "questionmark.circle")
                }
            }
            .font(.system(size: 10))
            
            VStack(alignment: .leading, spacing: 1) {
                Text(animation.targetObjectID)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .lineLimit(1)
                
                Text("\(animation.animationType) (\(String(format: "%.1f", animation.duration))s)")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(action: { sceneState.deleteAnimation(stepID: stepID, animationID: animation.id) }) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.red.opacity(0.8))
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .contextMenu {
            Button("Edit Animation...") { showEditPopover = true }
            Button("Delete", role: .destructive) { sceneState.deleteAnimation(stepID: stepID, animationID: animation.id) }
        }
        .popover(isPresented: $showEditPopover) {
            EditAnimationPopover(sceneState: sceneState, stepID: stepID, animation: animation)
        }
    }
}

// MARK: - Reusable Parameter Inputs

struct AnimParamFields: View {
    let animType: String
    let objects: [ManimObject]
    
    @Binding var indicateColor: String
    @Binding var useColor: Bool
    @Binding var scaleFactor: Double
    @Binding var flashRadius: Double
    @Binding var flashNumLines: Int
    @Binding var circumscribeShape: String
    @Binding var focusOpacity: Double
    @Binding var waveAmplitude: Double
    @Binding var waveDirection: String
    @Binding var wiggleScale: Double
    @Binding var wiggleCount: Int
    @Binding var shiftDirection: String
    @Binding var fadeScale: Double
    @Binding var growEdge: String
    @Binding var targetX: Double
    @Binding var targetY: Double
    @Binding var targetScale: Double
    @Binding var rotationAngle: Double
    @Binding var transformTargetID: String
    @Binding var useCopy: Bool
    @Binding var changeValue: Double
    
    var body: some View {
        switch animType {
        // --- Indication ---
        case "Indicate":
            Toggle("Custom Color", isOn: $useColor)
                .font(.caption)
            if useColor {
                Picker("Color", selection: $indicateColor) {
                    ForEach(["YELLOW", "RED", "BLUE", "GREEN", "WHITE", "ORANGE", "PINK", "PURPLE"], id: \.self) { Text($0).tag($0) }
                }.font(.caption).labelsHidden()
            }
            paramRow("Scale Factor") { Slider(value: $scaleFactor, in: 0.5...3.0, step: 0.1) }
            Text(String(format: "%.1f", scaleFactor)).font(.caption2).foregroundStyle(.secondary)
            
        case "Flash":
            Toggle("Custom Color", isOn: $useColor).font(.caption)
            if useColor {
                Picker("Color", selection: $indicateColor) {
                    ForEach(["YELLOW", "RED", "BLUE", "GREEN", "WHITE", "ORANGE"], id: \.self) { Text($0).tag($0) }
                }.font(.caption).labelsHidden()
            }
            paramRow("Flash Radius") { Slider(value: $flashRadius, in: 0.1...2.0, step: 0.05) }
            Text(String(format: "%.2f", flashRadius)).font(.caption2).foregroundStyle(.secondary)
            paramRow("Num Lines") {
                Stepper("\(flashNumLines)", value: $flashNumLines, in: 4...32, step: 2).font(.caption)
            }
            
        case "Circumscribe":
            Toggle("Custom Color", isOn: $useColor).font(.caption)
            if useColor {
                Picker("Color", selection: $indicateColor) {
                    ForEach(["YELLOW", "RED", "BLUE", "GREEN", "WHITE"], id: \.self) { Text($0).tag($0) }
                }.font(.caption).labelsHidden()
            }
            paramRow("Shape") {
                Picker("", selection: $circumscribeShape) {
                    ForEach(ManimAnimation.shapeOptions, id: \.self) { Text($0).tag($0) }
                }.labelsHidden()
            }
            
        case "FocusOn":
            Toggle("Custom Color", isOn: $useColor).font(.caption)
            if useColor {
                Picker("Color", selection: $indicateColor) {
                    ForEach(["GREY", "YELLOW", "RED", "BLUE", "WHITE"], id: \.self) { Text($0).tag($0) }
                }.font(.caption).labelsHidden()
            }
            paramRow("Opacity") { Slider(value: $focusOpacity, in: 0.0...1.0, step: 0.05) }
            Text(String(format: "%.2f", focusOpacity)).font(.caption2).foregroundStyle(.secondary)
            
        case "ApplyWave":
            paramRow("Direction") {
                Picker("", selection: $waveDirection) {
                    ForEach(ManimAnimation.directionOptions, id: \.self) { Text($0).tag($0) }
                }.labelsHidden()
            }
            paramRow("Amplitude") { Slider(value: $waveAmplitude, in: 0.05...1.0, step: 0.05) }
            Text(String(format: "%.2f", waveAmplitude)).font(.caption2).foregroundStyle(.secondary)
            
        case "Wiggle":
            paramRow("Scale") { Slider(value: $wiggleScale, in: 1.0...2.0, step: 0.05) }
            Text(String(format: "%.2f", wiggleScale)).font(.caption2).foregroundStyle(.secondary)
            paramRow("Wiggles") {
                Stepper("\(wiggleCount)", value: $wiggleCount, in: 1...20).font(.caption)
            }

        // --- Creation / Removal ---
        case "FadeIn", "FadeOut":
            paramRow("Shift Direction") {
                Picker("", selection: $shiftDirection) {
                    Text("None").tag("NONE")
                    ForEach(ManimAnimation.directionOptions, id: \.self) { Text($0).tag($0) }
                }.labelsHidden()
            }
            paramRow("Scale") { Slider(value: $fadeScale, in: 0.1...3.0, step: 0.1) }
            Text(String(format: "%.1f", fadeScale)).font(.caption2).foregroundStyle(.secondary)
            
        case "GrowFromEdge":
            paramRow("Edge") {
                Picker("", selection: $growEdge) {
                    ForEach(ManimAnimation.edgeOptions, id: \.self) { Text($0).tag($0) }
                }.labelsHidden()
            }
            
        // --- Transform ---
        case "MoveTo":
            paramRow("Target X") { TextField("X", value: $targetX, format: .number).textFieldStyle(.roundedBorder) }
            paramRow("Target Y") { TextField("Y", value: $targetY, format: .number).textFieldStyle(.roundedBorder) }
            paramRow("Scale") { TextField("Scale", value: $targetScale, format: .number).textFieldStyle(.roundedBorder) }
            
        case "Rotate":
            paramRow("Angle (°)") { Slider(value: $rotationAngle, in: -360...360, step: 5) }
            Text(String(format: "%.0f°", rotationAngle)).font(.caption2).foregroundStyle(.secondary)
            
        case "Transform", "ReplacementTransform":
            paramRow("Target Object") {
                Picker("", selection: $transformTargetID) {
                    ForEach(objects) { obj in
                        Text(obj.variableName).tag(obj.id)
                    }
                }.labelsHidden()
            }
            Toggle("Use Copy", isOn: $useCopy).font(.caption)
            
        // --- Numbers ---
        case "ChangeDecimalToValue":
            paramRow("New Value") { TextField("Value", value: $changeValue, format: .number).textFieldStyle(.roundedBorder) }
            
        default:
            EmptyView()
        }
    }
    
    private func paramRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            content()
        }
    }
}

struct AddAnimationPopover: View {
    @Bindable var sceneState: SceneState
    let stepID: UUID
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedObjectID: String = ""
    @State private var selectedCategory: String = "Creation"
    @State private var selectedAnimType: String = "Create"
    @State private var duration: Double = 1.0
    @State private var rateFunc: String = "smooth"
    @State private var showAdvanced: Bool = false
    
    // Indication
    @State private var indicateColor: String = "YELLOW"
    @State private var useColor: Bool = false
    @State private var scaleFactor: Double = 1.2
    @State private var flashRadius: Double = 0.3
    @State private var flashNumLines: Int = 12
    @State private var circumscribeShape: String = "Rectangle"
    @State private var focusOpacity: Double = 0.2
    @State private var waveAmplitude: Double = 0.2
    @State private var waveDirection: String = "UP"
    @State private var wiggleScale: Double = 1.1
    @State private var wiggleCount: Int = 6
    // Creation/Removal
    @State private var shiftDirection: String = "NONE"
    @State private var fadeScale: Double = 1.0
    @State private var growEdge: String = "DOWN"
    // Transform
    @State private var targetX: Double = 0.0
    @State private var targetY: Double = 0.0
    @State private var targetScale: Double = 1.0
    @State private var rotationAngle: Double = 180.0
    @State private var transformTargetID: String = ""
    @State private var useCopy: Bool = false
    // Composition
    @State private var playMode: String = "parallel"
    @State private var lagRatio: Double = 0.5
    // Numbers
    @State private var changeValue: Double = 0.0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Add Animation")
                    .font(.headline)
                
                if sceneState.objects.isEmpty {
                    Text("No objects in scene.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    // Target Object
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Target Object").font(.caption).foregroundStyle(.secondary)
                        Picker("", selection: $selectedObjectID) {
                            ForEach(sceneState.objects) { obj in
                                Text(obj.variableName).tag(obj.id)
                            }
                        }.labelsHidden()
                    }
                    
                    // Category Picker
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ManimAnimation.categories, id: \.name) { cat in
                            Label(cat.name, systemImage: cat.icon).tag(cat.name)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .onChange(of: selectedCategory) { _, newCat in
                        if let cat = ManimAnimation.categories.first(where: { $0.name == newCat }), let first = cat.types.first {
                            selectedAnimType = first
                        }
                    }
                    
                    if selectedCategory == "Composition" {
                        // Composition: step-level settings
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Play Mode").font(.caption).foregroundStyle(.secondary)
                            Picker("", selection: $playMode) {
                                Text("Parallel").tag("parallel")
                                Text("Lagged").tag("lagged")
                                Text("Sequential").tag("sequential")
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            
                            if playMode == "lagged" {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Lag Ratio: \(String(format: "%.2f", lagRatio))").font(.caption).foregroundStyle(.secondary)
                                    Slider(value: $lagRatio, in: 0.0...1.0, step: 0.05)
                                }
                            }
                            
                            Text("Configures how animations in this step play together.")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 4)
                        }
                        
                        Button("Apply to Step") {
                            if let stepIdx = sceneState.timeline.firstIndex(where: { $0.id == stepID }) {
                                sceneState.timeline[stepIdx].playMode = playMode
                                sceneState.timeline[stepIdx].lagRatio = lagRatio
                                sceneState.regenerateCode()
                            }
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    } else {
                        // Animation type list
                        let currentTypes = ManimAnimation.categories.first(where: { $0.name == selectedCategory })?.types ?? []
                        VStack(alignment: .leading, spacing: 1) {
                            ForEach(currentTypes, id: \.self) { type in
                                Button(action: { selectedAnimType = type }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: selectedAnimType == type ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(selectedAnimType == type ? .blue : .secondary)
                                            .font(.system(size: 11))
                                        Text(type)
                                            .font(.caption)
                                        Spacer()
                                    }
                                    .padding(.vertical, 2)
                                    .padding(.horizontal, 4)
                                    .background(selectedAnimType == type ? Color.accentColor.opacity(0.1) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        // Dynamic parameter inputs
                        AnimParamFields(
                            animType: selectedAnimType,
                            objects: sceneState.objects,
                            indicateColor: $indicateColor,
                            useColor: $useColor,
                            scaleFactor: $scaleFactor,
                            flashRadius: $flashRadius,
                            flashNumLines: $flashNumLines,
                            circumscribeShape: $circumscribeShape,
                            focusOpacity: $focusOpacity,
                            waveAmplitude: $waveAmplitude,
                            waveDirection: $waveDirection,
                            wiggleScale: $wiggleScale,
                            wiggleCount: $wiggleCount,
                            shiftDirection: $shiftDirection,
                            fadeScale: $fadeScale,
                            growEdge: $growEdge,
                            targetX: $targetX,
                            targetY: $targetY,
                            targetScale: $targetScale,
                            rotationAngle: $rotationAngle,
                            transformTargetID: $transformTargetID,
                            useCopy: $useCopy,
                            changeValue: $changeValue
                        )
                        
                        // Duration
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Duration: \(String(format: "%.1f", duration))s").font(.caption).foregroundStyle(.secondary)
                            Slider(value: $duration, in: 0.1...10, step: 0.1)
                        }
                        
                        // Advanced
                        DisclosureGroup("Advanced", isExpanded: $showAdvanced) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Rate Function").font(.caption).foregroundStyle(.secondary)
                                Picker("", selection: $rateFunc) {
                                    ForEach(ManimAnimation.rateFunctions, id: \.self) { rf in
                                        Text(rf).tag(rf)
                                    }
                                }.labelsHidden()
                            }
                        }
                        .font(.caption)
                        
                        // Add button
                        Button("Add") { addAnimation() }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .padding()
        }
        .frame(width: 450)
        .frame(maxHeight: 520)
        .onAppear {
            if let first = sceneState.objects.first {
                selectedObjectID = first.id
                transformTargetID = first.id
            }
            // Load existing step composition settings
            if let step = sceneState.timeline.first(where: { $0.id == stepID }) {
                playMode = step.playMode
                lagRatio = step.lagRatio
            }
        }
    }
    
    private func addAnimation() {
        guard !selectedObjectID.isEmpty else { return }
        var anim = ManimAnimation(targetObjectID: selectedObjectID, animationType: selectedAnimType, duration: duration)
        anim.rateFunc = rateFunc
        
        switch selectedAnimType {
        case "Indicate":
            if useColor { anim.indicateColor = indicateColor }
            anim.indicateScaleFactor = scaleFactor
        case "Flash":
            if useColor { anim.indicateColor = indicateColor }
            anim.flashRadius = flashRadius
            anim.flashNumLines = flashNumLines
        case "Circumscribe":
            if useColor { anim.indicateColor = indicateColor }
            anim.circumscribeShape = circumscribeShape
        case "FocusOn":
            if useColor { anim.indicateColor = indicateColor }
            anim.focusOnOpacity = focusOpacity
        case "ApplyWave":
            anim.waveDirection = waveDirection
            anim.waveAmplitude = waveAmplitude
        case "Wiggle":
            anim.wiggleScaleValue = wiggleScale
            anim.wiggleCount = wiggleCount
        case "FadeIn", "FadeOut":
            anim.shiftDirection = shiftDirection == "NONE" ? nil : shiftDirection
            anim.fadeScale = fadeScale
        case "GrowFromEdge":
            anim.growEdge = growEdge
        case "MoveTo":
            anim.targetX = targetX
            anim.targetY = targetY
            anim.targetScale = targetScale
        case "Rotate":
            anim.rotationAngle = rotationAngle
        case "Transform", "ReplacementTransform":
            anim.transformTargetID = transformTargetID
            anim.useCopy = useCopy
        case "ChangeDecimalToValue":
            anim.changeValue = changeValue
        default: break
        }
        
        sceneState.addAnimation(anim, toStepID: stepID)
        dismiss()
    }
}

struct EditAnimationPopover: View {
    @Bindable var sceneState: SceneState
    let stepID: UUID
    let animation: ManimAnimation
    @Environment(\.dismiss) private var dismiss
    
    @State private var duration: Double = 1.0
    @State private var rateFunc: String = "smooth"
    // Indication
    @State private var indicateColor: String = "YELLOW"
    @State private var useColor: Bool = false
    @State private var scaleFactor: Double = 1.2
    @State private var flashRadius: Double = 0.3
    @State private var flashNumLines: Int = 12
    @State private var circumscribeShape: String = "Rectangle"
    @State private var focusOpacity: Double = 0.2
    @State private var waveAmplitude: Double = 0.2
    @State private var waveDirection: String = "UP"
    @State private var wiggleScale: Double = 1.1
    @State private var wiggleCount: Int = 6
    // Creation/Removal
    @State private var shiftDirection: String = "NONE"
    @State private var fadeScale: Double = 1.0
    @State private var growEdge: String = "DOWN"
    // Transform
    @State private var targetX: Double = 0.0
    @State private var targetY: Double = 0.0
    @State private var targetScale: Double = 1.0
    @State private var rotationAngle: Double = 180.0
    @State private var transformTargetID: String = ""
    @State private var useCopy: Bool = false
    // Numbers
    @State private var changeValue: Double = 0.0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Edit")
                        .font(.headline)
                    Text(animation.animationType)
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
                
                // Duration
                VStack(alignment: .leading, spacing: 2) {
                    Text("Duration: \(String(format: "%.1f", duration))s").font(.caption).foregroundStyle(.secondary)
                    Slider(value: $duration, in: 0.1...10, step: 0.1)
                }
                
                // Dynamic parameter inputs
                AnimParamFields(
                    animType: animation.animationType,
                    objects: sceneState.objects,
                    indicateColor: $indicateColor,
                    useColor: $useColor,
                    scaleFactor: $scaleFactor,
                    flashRadius: $flashRadius,
                    flashNumLines: $flashNumLines,
                    circumscribeShape: $circumscribeShape,
                    focusOpacity: $focusOpacity,
                    waveAmplitude: $waveAmplitude,
                    waveDirection: $waveDirection,
                    wiggleScale: $wiggleScale,
                    wiggleCount: $wiggleCount,
                    shiftDirection: $shiftDirection,
                    fadeScale: $fadeScale,
                    growEdge: $growEdge,
                    targetX: $targetX,
                    targetY: $targetY,
                    targetScale: $targetScale,
                    rotationAngle: $rotationAngle,
                    transformTargetID: $transformTargetID,
                    useCopy: $useCopy,
                    changeValue: $changeValue
                )
                
                // Rate function
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rate Function").font(.caption).foregroundStyle(.secondary)
                    Picker("", selection: $rateFunc) {
                        ForEach(ManimAnimation.rateFunctions, id: \.self) { rf in
                            Text(rf).tag(rf)
                        }
                    }.labelsHidden()
                }
                
                Button("Save") { saveAnimation() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
        }
        .frame(width: 260)
        .frame(maxHeight: 420)
        .onAppear { loadFromAnimation() }
    }
    
    private func loadFromAnimation() {
        duration = animation.duration
        rateFunc = animation.rateFunc
        targetX = animation.targetX
        targetY = animation.targetY
        targetScale = animation.targetScale
        indicateColor = animation.indicateColor ?? "YELLOW"
        useColor = animation.indicateColor != nil
        scaleFactor = animation.indicateScaleFactor
        flashRadius = animation.flashRadius
        flashNumLines = animation.flashNumLines
        circumscribeShape = animation.circumscribeShape
        focusOpacity = animation.focusOnOpacity
        waveAmplitude = animation.waveAmplitude
        waveDirection = animation.waveDirection
        wiggleScale = animation.wiggleScaleValue
        wiggleCount = animation.wiggleCount
        shiftDirection = animation.shiftDirection ?? "NONE"
        fadeScale = animation.fadeScale
        growEdge = animation.growEdge
        rotationAngle = animation.rotationAngle
        transformTargetID = animation.transformTargetID ?? sceneState.objects.first?.id ?? ""
        useCopy = animation.useCopy
        changeValue = animation.changeValue
    }
    
    private func saveAnimation() {
        guard let stepIdx = sceneState.timeline.firstIndex(where: { $0.id == stepID }),
              let animIdx = sceneState.timeline[stepIdx].animations.firstIndex(where: { $0.id == animation.id }) else { return }
        
        var a = sceneState.timeline[stepIdx].animations[animIdx]
        a.duration = duration
        a.rateFunc = rateFunc
        a.targetX = targetX; a.targetY = targetY; a.targetScale = targetScale
        a.indicateColor = useColor ? indicateColor : nil
        a.indicateScaleFactor = scaleFactor
        a.flashRadius = flashRadius; a.flashNumLines = flashNumLines
        a.circumscribeShape = circumscribeShape
        a.focusOnOpacity = focusOpacity
        a.waveAmplitude = waveAmplitude; a.waveDirection = waveDirection
        a.wiggleScaleValue = wiggleScale; a.wiggleCount = wiggleCount
        a.shiftDirection = shiftDirection == "NONE" ? nil : shiftDirection
        a.fadeScale = fadeScale; a.growEdge = growEdge
        a.rotationAngle = rotationAngle
        a.transformTargetID = transformTargetID
        a.useCopy = useCopy
        a.changeValue = changeValue
        
        sceneState.timeline[stepIdx].animations[animIdx] = a
        sceneState.regenerateCode()
        dismiss()
    }
}
