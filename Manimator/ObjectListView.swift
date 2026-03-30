//
//  ObjectListView.swift
//  Manimator
//
//  Object list + inspector panel. Lists all objects; when one is selected,
//  shows all editable properties below.
//

import SwiftUI

struct ObjectListView: View {
    @Bindable var sceneState: SceneState
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundStyle(.secondary)
                Text("Scene Objects")
                    .font(.headline)
                Spacer()
                Text("\(sceneState.objects.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary)
                    .clipShape(Capsule())
                    
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .padding(.leading, 4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            if sceneState.objects.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle.dashed")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text("No objects yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Click + in the toolbar\nto add objects")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        // Object list
                        ForEach(sceneState.objects) { obj in
                            DisclosureGroup(
                                isExpanded: Binding(
                                    get: { sceneState.selectedObjectID == obj.id },
                                    set: { isExpanded in
                                        if isExpanded { sceneState.selectedObjectID = obj.id }
                                        else if sceneState.selectedObjectID == obj.id { sceneState.selectedObjectID = nil }
                                    }
                                )
                            ) {
                                VStack(alignment: .leading, spacing: 12) {
                                    InspectorPanel(sceneState: sceneState, objectID: obj.id)
                                    
                                    Button(action: {
                                        sceneState.duplicateObject(id: obj.id)
                                    }) {
                                        HStack {
                                            Image(systemName: "doc.on.doc")
                                            Text("Duplicate Object")
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                    .padding(.horizontal, 12)
                                    .padding(.bottom, 12)
                                }
                                .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
                                .cornerRadius(8)
                                .padding(.vertical, 4)
                            } label: {
                                ObjectListRow(
                                    object: obj,
                                    isSelected: obj.id == sceneState.selectedObjectID,
                                    onSelect: {
                                        if sceneState.selectedObjectID == obj.id {
                                            sceneState.selectedObjectID = nil
                                        } else {
                                            sceneState.selectedObjectID = obj.id
                                        }
                                    },
                                    onDelete: { sceneState.deleteObject(id: obj.id) }
                                )
                            }
                            .tint(.secondary)
                            .padding(.horizontal, 8)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

// MARK: - Object List Row

struct ObjectListRow: View {
    let object: ManimObject
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(object.swiftUIColor.opacity(0.2))
                    .frame(width: 24, height: 24)
                Image(systemName: object.iconName)
                    .font(.system(size: 10))
                    .foregroundColor(object.swiftUIColor)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(object.variableName)
                    .font(.system(.caption, design: .monospaced, weight: .medium))
                Text(object.typeName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(role: .destructive) { onDelete() } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .opacity(isSelected ? 1 : 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isSelected ? Color.accentColor.opacity(0.12) : .clear)
        )
        .padding(.horizontal, 6)
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
    }
}

// MARK: - Inspector Panel

struct InspectorPanel: View {
    @Bindable var sceneState: SceneState
    let objectID: String
    
    private var object: ManimObject? {
        sceneState.objects.first(where: { $0.id == objectID })
    }
    
    var body: some View {
        if let obj = object {
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(.secondary)
                    Text("Inspector")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                
                // Variable name
                InspectorRow(label: "Name") {
                    StringField(placeholder: "name", value: obj.variableName) { newVal in
                        let clean = newVal.replacingOccurrences(of: " ", with: "_")
                            .lowercased()
                            .filter { $0.isLetter || $0.isNumber || $0 == "_" }
                        if !clean.isEmpty && clean != obj.variableName {
                            sceneState.updateObject(id: objectID) { $0.variableName = clean }
                        }
                    }
                }
                
                // Text content (for text types)
                if obj.isTextType {
                    InspectorRow(label: "Text") {
                        StringField(placeholder: "content", value: obj.text) { newVal in
                            if newVal != obj.text {
                                sceneState.updateObject(id: objectID) { $0.text = newVal }
                            }
                        }
                    }
                }
                
                // Numeric value (for DecimalNumber / Integer)
                if obj.isNumberType {
                    InspectorRow(label: "Value") {
                        HStack(spacing: 6) {
                            NumField(label: "", value: Double(obj.text) ?? 0.0) { v in
                                if obj.typeName == "Integer" {
                                    sceneState.updateObject(id: objectID) { $0.text = "\(Int(v))" }
                                } else {
                                    sceneState.updateObject(id: objectID) { $0.text = String(format: "%.2f", v) }
                                }
                            }
                        }
                    }
                }
                
                // Graph content (for FunctionGraph)
                if obj.isGraphType {
                    InspectorRow(label: "Equation (f(x))") {
                        VStack(alignment: .leading, spacing: 6) {
                            StringField(placeholder: "np.sin(x)", value: obj.equation) { newVal in
                                if newVal != obj.equation {
                                    sceneState.updateObject(id: objectID) { $0.equation = newVal }
                                }
                            }
                            
                            // Math Helper Chips
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    MathChip(label: "sin", insert: "np.sin(x)", objectID: objectID, sceneState: sceneState)
                                    MathChip(label: "cos", insert: "np.cos(x)", objectID: objectID, sceneState: sceneState)
                                    MathChip(label: "tan", insert: "np.tan(x)", objectID: objectID, sceneState: sceneState)
                                    MathChip(label: "x²", insert: "x**2", objectID: objectID, sceneState: sceneState)
                                    MathChip(label: "x³", insert: "x**3", objectID: objectID, sceneState: sceneState)
                                    MathChip(label: "eˣ", insert: "np.exp(x)", objectID: objectID, sceneState: sceneState)
                                    MathChip(label: "√x", insert: "np.sqrt(x)", objectID: objectID, sceneState: sceneState)
                                    MathChip(label: "log", insert: "np.log(x)", objectID: objectID, sceneState: sceneState)
                                }
                            }
                        }
                    }
                    
                    InspectorRow(label: "Dimensions") {
                        HStack(spacing: 6) {
                            NumField(label: "Width", value: obj.graphWidth) { v in
                                sceneState.updateObject(id: objectID) { $0.graphWidth = max(0.1, v) }
                            }
                            NumField(label: "Height", value: obj.graphHeight) { v in
                                sceneState.updateObject(id: objectID) { $0.graphHeight = max(0.1, v) }
                            }
                        }
                    }
                    
                    InspectorRow(label: "X Range") {
                        HStack(spacing: 6) {
                            NumField(label: "Min", value: obj.xRangeMin) { v in
                                sceneState.updateObject(id: objectID) { $0.xRangeMin = v }
                            }
                            NumField(label: "Max", value: obj.xRangeMax) { v in
                                sceneState.updateObject(id: objectID) { $0.xRangeMax = v }
                            }
                        }
                    }
                    
                    InspectorRow(label: "Y Range") {
                        HStack(spacing: 6) {
                            NumField(label: "Min", value: obj.yRangeMin) { v in
                                sceneState.updateObject(id: objectID) { $0.yRangeMin = v }
                            }
                            NumField(label: "Max", value: obj.yRangeMax) { v in
                                sceneState.updateObject(id: objectID) { $0.yRangeMax = v }
                            }
                        }
                    }
                }
                
                // Color
                InspectorRow(label: "Color") {
                    HStack(spacing: 8) {
                        ColorPicker("", selection: Binding(
                            get: {
                                // Try to construct a SwiftUI Color from our string
                                let swiftUICol = obj.swiftUIColor
                                // If the hex string isn't an exact match, swiftUIColor falls back to white.
                                // But since SwiftUI's ColorPicker modifies rgb, we'll store it as hex back to Manim.
                                return swiftUICol
                            },
                            set: { newColor in
                                guard let cgColor = newColor.cgColor else { return }
                                let str = String(format: "\"#%02x%02x%02x\"",
                                                 Int(cgColor.components![0] * 255),
                                                 Int(cgColor.components![1] * 255),
                                                 Int(cgColor.components![2] * 255))
                                sceneState.updateObject(id: objectID) { $0.color = str }
                            }
                        ))
                        .labelsHidden()
                        .frame(width: 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 3) {
                                ForEach(ManimObject.manimColors, id: \.self) { colorName in
                                    Circle()
                                        .fill(colorSwiftUI(colorName))
                                        .frame(width: 16, height: 16)
                                        .overlay(
                                            Circle().stroke(
                                                obj.color == colorName ? .white : .clear,
                                                lineWidth: 2
                                            )
                                        )
                                        .onTapGesture {
                                            sceneState.updateObject(id: objectID) { $0.color = colorName }
                                        }
                                        .help(colorName)
                                }
                            }
                        }
                    }
                }
                
                // Position
                InspectorRow(label: "Position") {
                    HStack(spacing: 6) {
                        NumField(label: "X", value: obj.position.x) { v in
                            sceneState.moveObject(id: objectID, to: CGPoint(x: v, y: obj.position.y))
                        }
                        NumField(label: "Y", value: obj.position.y) { v in
                            sceneState.moveObject(id: objectID, to: CGPoint(x: obj.position.x, y: v))
                        }
                    }
                }
                
                // Scale
                InspectorSlider(label: "Scale", value: obj.scale, range: 0.1...5.0, step: 0.1, format: "%.2f") { v in
                    sceneState.updateObject(id: objectID) { $0.scale = v }
                }
                
                // Rotation
                InspectorSlider(label: "Rotation", value: obj.rotation, range: 0...360, step: 5, format: "%.0f°") { v in
                    sceneState.updateObject(id: objectID) { $0.rotation = v }
                }
                
                // Opacity
                InspectorSlider(label: "Opacity", value: obj.opacity, range: 0...1, step: 0.05, format: "%.2f") { v in
                    sceneState.updateObject(id: objectID) { $0.opacity = v }
                }
                
                // Stroke width
                InspectorSlider(label: "Stroke", value: obj.strokeWidth, range: 0.5...10, step: 0.5, format: "%.1f") { v in
                    sceneState.updateObject(id: objectID) { $0.strokeWidth = v }
                }
                
                Divider().padding(.horizontal, 12)
                
                // Delete
                Button(role: .destructive) {
                    sceneState.deleteObject(id: objectID)
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Object")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal, 12)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }
        }
    }
    
    private func colorSwiftUI(_ name: String) -> Color {
        switch name.uppercased() {
        case "BLUE", "BLUE_A", "BLUE_B", "BLUE_C", "BLUE_D": return .blue
        case "RED", "RED_A", "RED_B", "RED_C", "RED_D": return .red
        case "GREEN", "GREEN_A", "GREEN_B", "GREEN_C", "GREEN_D": return .green
        case "YELLOW": return .yellow
        case "ORANGE": return .orange
        case "PURPLE": return .purple
        case "PINK": return .pink
        case "WHITE": return .white
        case "GRAY", "GREY": return .gray
        case "BLACK": return Color(nsColor: .darkGray)
        case "TEAL": return .teal
        case "GOLD": return .yellow
        case "MAROON": return Color(red: 0.5, green: 0, blue: 0)
        default: return .white
        }
    }
}

// MARK: - Inspector Helpers

struct InspectorRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.tertiary)
            content
        }
        .padding(.horizontal, 12)
    }
}

struct InspectorSlider: View {
    let label: String
    let value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: String
    let onChange: (Double) -> Void
    
    var body: some View {
        InspectorRow(label: label) {
            HStack(spacing: 6) {
                Slider(value: Binding(
                    get: { value },
                    set: { onChange($0) }
                ), in: range, step: step)
                .controlSize(.small)
                
                Text(String(format: format, value))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
        }
    }
}

struct NumField: View {
    let label: String
    let value: Double
    let onCommit: (Double) -> Void
    @State private var text = ""
    @FocusState private var focused: Bool
    
    var body: some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(.tertiary)
            TextField("0", text: $text)
                .textFieldStyle(.roundedBorder)
                .font(.system(.caption2, design: .monospaced))
                .frame(width: 52)
                .focused($focused)
                .onSubmit { commit() }
                .onChange(of: focused) { _, f in if !f { commit() } }
        }
        .onAppear { text = String(format: "%.2f", value) }
        .onChange(of: value) { _, v in if !focused { text = String(format: "%.2f", v) } }
    }
    
    private func commit() {
        if let v = Double(text) { onCommit(v) }
    }
}

struct StringField: View {
    let placeholder: String
    let value: String
    let onCommit: (String) -> Void
    @State private var text = ""
    @FocusState private var focused: Bool
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.roundedBorder)
            .font(.system(.caption, design: .monospaced))
            .focused($focused)
            .onSubmit { onCommit(text) }
            .onChange(of: focused) { _, f in if !f { onCommit(text) } }
            .onAppear { text = value }
            .onChange(of: value) { _, v in if !focused { text = v } }
    }
}

// MARK: - Math Chip Helper

struct MathChip: View {
    let label: String
    let insert: String
    let objectID: String
    let sceneState: SceneState
    
    var body: some View {
        Button(action: {
            sceneState.updateObject(id: objectID) { $0.equation = insert }
        }) {
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}
