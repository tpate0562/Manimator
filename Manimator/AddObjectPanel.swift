//
//  AddObjectPanel.swift
//  Manimator
//
//  Categorized palette for adding Manim objects to the scene.
//

import SwiftUI

struct AddObjectPanel: View {
    @Bindable var sceneState: SceneState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Add Object")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Shapes
                    ObjectCategory(title: "Shapes", icon: "square.on.circle") {
                        ObjectGrid(types: ManimObject.shapeTypes, sceneState: sceneState, dismiss: dismiss)
                    }
                    
                    // Lines & Arrows
                    ObjectCategory(title: "Lines & Arrows", icon: "line.diagonal") {
                        ObjectGrid(types: ManimObject.lineTypes, sceneState: sceneState, dismiss: dismiss)
                    }
                    
                    // Text
                    ObjectCategory(title: "Text", icon: "textformat") {
                        ObjectGrid(types: ManimObject.textTypes, sceneState: sceneState, dismiss: dismiss)
                    }
                    
                    // Graphs
                    ObjectCategory(title: "Graphs", icon: "chart.xyaxis.line") {
                        ObjectGrid(types: ManimObject.graphTypes, sceneState: sceneState, dismiss: dismiss)
                    }
                    
                    // Numbers
                    ObjectCategory(title: "Numbers", icon: "number") {
                        ObjectGrid(types: ManimObject.numberTypes, sceneState: sceneState, dismiss: dismiss)
                    }
                }
                .padding(16)
            }
        }
        .frame(width: 280, height: 460)
    }
}

// MARK: - Category Section

struct ObjectCategory<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            content
        }
    }
}

// MARK: - Grid of Type Buttons

struct ObjectGrid: View {
    let types: [String]
    @Bindable var sceneState: SceneState
    let dismiss: DismissAction
    
    let columns = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(types, id: \.self) { typeName in
                Button {
                    sceneState.addObject(type: typeName)
                    dismiss()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: iconFor(typeName))
                            .font(.system(size: 18))
                            .frame(height: 22)
                        Text(typeName)
                            .font(.caption2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func iconFor(_ type: String) -> String {
        switch type.lowercased() {
        case "circle": return "circle"
        case "square": return "square"
        case "rectangle": return "rectangle"
        case "triangle": return "triangle"
        case "regularpolygon", "polygon": return "hexagon"
        case "ellipse": return "oval"
        case "star": return "star"
        case "dot": return "circle.fill"
        case "annulus": return "circle.circle"
        case "arc": return "arc"
        case "line", "dashedline": return "line.diagonal"
        case "arrow": return "arrow.right"
        case "doublearrow": return "arrow.left.arrow.right"
        case "text", "tex", "mathtex": return "textformat"
        case "functiongraph": return "chart.xyaxis.line"
        case "decimalnumber", "integer": return "number"
        default: return "cube"
        }
    }
}
