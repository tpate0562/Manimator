//
//  DraggableOverlayView.swift
//  Manimator
//
//  Primary visual canvas: renders object shapes, supports click-to-select,
//  drag-to-move, Delete key to remove, ⌘D to duplicate.
//

import SwiftUI

struct DraggableOverlayView: View {
    @Bindable var sceneState: SceneState
    
    private let manimXRange: ClosedRange<Double> = -7.1...7.1
    private let manimYRange: ClosedRange<Double> = -4.0...4.0
    
    @State private var draggedObjectID: String? = nil
    @State private var dragCurrentScreenPos: CGPoint = .zero
    @State private var hoverLocation: CGPoint? = nil
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background: click to deselect
                Color.black.opacity(0.85)
                    .onTapGesture {
                        sceneState.selectedObjectID = nil
                    }
                
                // Grid lines
                CanvasGrid(size: geo.size, manimXRange: manimXRange, manimYRange: manimYRange)
                
                // Objects
                ForEach(sceneState.objects) { object in
                    let isDragging = draggedObjectID == object.id
                    let screenPos: CGPoint = isDragging
                        ? dragCurrentScreenPos
                        : manimToScreen(object.position, in: geo.size)
                    let isSelected = object.id == sceneState.selectedObjectID
                    
                    ObjectVisual(object: object, isSelected: isSelected, isDragging: isDragging, canvasSize: geo.size)
                        .position(screenPos)
                        .gesture(
                            DragGesture(minimumDistance: 2, coordinateSpace: .named("canvas"))
                                .onChanged { value in
                                    if draggedObjectID != object.id {
                                        draggedObjectID = object.id
                                        sceneState.selectedObjectID = object.id
                                    }
                                    dragCurrentScreenPos = value.location
                                }
                                .onEnded { value in
                                    let finalManim = screenToManim(value.location, in: geo.size)
                                    sceneState.moveObject(id: object.id, to: finalManim)
                                    draggedObjectID = nil
                                }
                        )
                        .onTapGesture {
                            sceneState.selectedObjectID = object.id
                        }
                }
                
                // Crosshairs
                if let loc = hoverLocation {
                    let manimLoc = screenToManim(loc, in: geo.size)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: loc.y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: loc.y))
                        path.move(to: CGPoint(x: loc.x, y: 0))
                        path.addLine(to: CGPoint(x: loc.x, y: geo.size.height))
                    }
                    .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .allowsHitTesting(false)
                    
                    Text(String(format: "(%.2f, %.2f)", manimLoc.x, manimLoc.y))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(Color.black.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .position(x: loc.x > geo.size.width - 60 ? loc.x - 40 : loc.x + 40,
                                  y: loc.y > geo.size.height - 30 ? loc.y - 20 : loc.y + 20)
                        .allowsHitTesting(false)
                }
            }
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    hoverLocation = location
                case .ended:
                    hoverLocation = nil
                }
            }
        }
        .coordinateSpace(name: "canvas")
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onKeyPress(.delete) {
            if let sel = sceneState.selectedObjectID {
                sceneState.deleteObject(id: sel)
            }
            return .handled
        }
        .onKeyPress(.init(Character(UnicodeScalar(127)))) { // backspace
            if let sel = sceneState.selectedObjectID {
                sceneState.deleteObject(id: sel)
            }
            return .handled
        }
        .focusable()
    }
    
    // MARK: - Coordinate Conversion
    
    private func manimToScreen(_ point: CGPoint, in size: CGSize) -> CGPoint {
        let xSpan = manimXRange.upperBound - manimXRange.lowerBound
        let ySpan = manimYRange.upperBound - manimYRange.lowerBound
        return CGPoint(
            x: ((point.x - manimXRange.lowerBound) / xSpan) * size.width,
            y: ((manimYRange.upperBound - point.y) / ySpan) * size.height
        )
    }
    
    private func screenToManim(_ point: CGPoint, in size: CGSize) -> CGPoint {
        let xSpan = manimXRange.upperBound - manimXRange.lowerBound
        let ySpan = manimYRange.upperBound - manimYRange.lowerBound
        let mx = (point.x / size.width) * xSpan + manimXRange.lowerBound
        let my = manimYRange.upperBound - (point.y / size.height) * ySpan
        return CGPoint(
            x: (mx * 100).rounded() / 100,
            y: (my * 100).rounded() / 100
        )
    }
}

// MARK: - Canvas Grid (subtle reference lines)

struct CanvasGrid: View {
    let size: CGSize
    let manimXRange: ClosedRange<Double>
    let manimYRange: ClosedRange<Double>
    
    var body: some View {
        Canvas { context, canvasSize in
            let xSpan = manimXRange.upperBound - manimXRange.lowerBound
            let ySpan = manimYRange.upperBound - manimYRange.lowerBound
            
            // Center crosshair
            let centerX = ((-manimXRange.lowerBound) / xSpan) * canvasSize.width
            let centerY = ((manimYRange.upperBound) / ySpan) * canvasSize.height
            
            let gridColor = Color.white.opacity(0.08)
            let axisColor = Color.white.opacity(0.2)
            
            // Draw integer grid lines
            for x in Int(manimXRange.lowerBound)...Int(manimXRange.upperBound) {
                let screenX = ((Double(x) - manimXRange.lowerBound) / xSpan) * canvasSize.width
                var path = Path()
                path.move(to: CGPoint(x: screenX, y: 0))
                path.addLine(to: CGPoint(x: screenX, y: canvasSize.height))
                context.stroke(path, with: .color(x == 0 ? axisColor : gridColor), lineWidth: x == 0 ? 1 : 0.5)
            }
            for y in Int(manimYRange.lowerBound)...Int(manimYRange.upperBound) {
                let screenY = ((manimYRange.upperBound - Double(y)) / ySpan) * canvasSize.height
                var path = Path()
                path.move(to: CGPoint(x: 0, y: screenY))
                path.addLine(to: CGPoint(x: canvasSize.width, y: screenY))
                context.stroke(path, with: .color(y == 0 ? axisColor : gridColor), lineWidth: y == 0 ? 1 : 0.5)
            }
            
            // Origin dot
            let originPath = Path(ellipseIn: CGRect(x: centerX - 3, y: centerY - 3, width: 6, height: 6))
            context.fill(originPath, with: .color(.white.opacity(0.3)))
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Object Visual (type-aware rendering)

struct ObjectVisual: View {
    let object: ManimObject
    let isSelected: Bool
    let isDragging: Bool
    let canvasSize: CGSize
    
    private var baseSize: CGFloat {
        let unit = min(canvasSize.width / 14.2, canvasSize.height / 8.0)
        return unit * object.scale
    }
    
    var body: some View {
        ZStack {
            // Selection ring
            if isSelected {
                RoundedRectangle(cornerRadius: isCircular ? shapeWidth / 2 : 4)
                    .stroke(Color.yellow, lineWidth: 2)
                    .frame(width: shapeWidth + 10, height: shapeHeight + 10)
                    .opacity(0.7)
            }
            
            // Main shape
            shapeView
                .frame(width: shapeWidth, height: shapeHeight)
                .foregroundStyle(object.swiftUIColor.opacity(object.opacity))
                .rotationEffect(.degrees(object.rotation))
            
            // Label
            Text(object.variableName)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Capsule().fill(Color.black.opacity(0.7)))
                .offset(y: shapeHeight / 2 + 12)
        }
        .scaleEffect(isDragging ? 1.1 : 1.0)
        .shadow(color: .black.opacity(isDragging ? 0.6 : 0.3), radius: isDragging ? 8 : 4)
        .animation(.easeOut(duration: 0.12), value: isDragging)
    }
    
    private var isCircular: Bool {
        ["Circle", "Dot", "Annulus", "Arc"].contains(object.typeName)
    }
    
    private var shapeWidth: CGFloat {
        switch object.typeName {
        case "Rectangle": return baseSize * 1.6
        case "Line", "Arrow", "DoubleArrow", "DashedLine": return baseSize * 2
        case "Ellipse": return baseSize * 1.4
        default: return baseSize
        }
    }
    
    private var shapeHeight: CGFloat {
        switch object.typeName {
        case "Rectangle": return baseSize
        case "Line", "Arrow", "DoubleArrow", "DashedLine": return 4
        case "Ellipse": return baseSize * 0.8
        default: return baseSize
        }
    }
    
    @ViewBuilder
    private var shapeView: some View {
        switch object.typeName {
        case "Circle", "Annulus", "Arc", "Dot":
            Circle()
        case "Square":
            RoundedRectangle(cornerRadius: 2)
        case "Rectangle":
            RoundedRectangle(cornerRadius: 2)
        case "Triangle":
            TriangleShape()
        case "RegularPolygon", "Polygon":
            HexagonShape()
        case "Ellipse":
            Ellipse()
        case "Star":
            StarShape()
        case "Line", "DashedLine":
            Rectangle()
        case "Arrow", "DoubleArrow":
            ArrowShape()
        case "Text", "Tex", "MathTex":
            TextObjectView(text: object.text, color: object.swiftUIColor)
        default:
            Circle()
        }
    }
}

// MARK: - Custom Shapes

struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX, cy = rect.midY
        let r = min(rect.width, rect.height) / 2
        for i in 0..<6 {
            let angle = Double(i) * .pi / 3 - .pi / 2
            let pt = CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle))
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX, cy = rect.midY
        let outerR = min(rect.width, rect.height) / 2
        let innerR = outerR * 0.4
        for i in 0..<10 {
            let angle = Double(i) * .pi / 5 - .pi / 2
            let r = i % 2 == 0 ? outerR : innerR
            let pt = CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle))
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}

struct ArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let headSize = min(rect.height * 1.5, rect.width * 0.15)
        // Shaft
        path.move(to: CGPoint(x: rect.minX, y: midY))
        path.addLine(to: CGPoint(x: rect.maxX - headSize, y: midY))
        // Head
        path.move(to: CGPoint(x: rect.maxX, y: midY))
        path.addLine(to: CGPoint(x: rect.maxX - headSize, y: midY - headSize))
        path.move(to: CGPoint(x: rect.maxX, y: midY))
        path.addLine(to: CGPoint(x: rect.maxX - headSize, y: midY + headSize))
        return path
    }
}

struct TextObjectView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text.isEmpty ? "Text" : text)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.3))
            )
    }
}
