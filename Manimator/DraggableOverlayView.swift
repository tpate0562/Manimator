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
    
    private var manimXRange: ClosedRange<Double> { sceneState.manimXRange }
    private var manimYRange: ClosedRange<Double> { sceneState.manimYRange }
    
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
                    
                    ObjectVisual(object: object, isSelected: isSelected, isDragging: isDragging, canvasSize: geo.size, manimXRange: manimXRange, manimYRange: manimYRange)
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

// MARK: - Object Visual (type-aware rendering at TRUE Manim size)

struct ObjectVisual: View {
    let object: ManimObject
    let isSelected: Bool
    let isDragging: Bool
    let canvasSize: CGSize
    let manimXRange: ClosedRange<Double>
    let manimYRange: ClosedRange<Double>
    
    /// Pixels per 1 manim unit on each axis
    private var unitX: CGFloat {
        canvasSize.width / (manimXRange.upperBound - manimXRange.lowerBound)
    }
    private var unitY: CGFloat {
        canvasSize.height / (manimYRange.upperBound - manimYRange.lowerBound)
    }
    /// Average unit size (used for shapes that are equal on both axes)
    private var unit: CGFloat { min(unitX, unitY) }
    
    // ── True Manim default sizes (in manim units) ──
    // Circle:        radius = 1  → diameter = 2
    // Square:        side   = 2
    // Rectangle:     width  = 4, height = 2
    // Triangle:      fits in a circle of radius ~1 → bounding ≈ 2
    // RegularPolygon: radius ~1
    // Ellipse:       width ~ 2, height ~ 1
    // Star:          outer radius ~1
    // Dot:           radius = 0.08 (DEFAULT_DOT_RADIUS) → diameter = 0.16
    // Line/Arrow:    default length = 2 (LEFT to RIGHT)
    // Annulus:       outer radius 1, inner radius 0.5
    // Arc:           radius 1
    
    /// Width of the shape **in screen pixels**, before user scale
    private var manimShapeWidth: CGFloat {
        switch object.typeName {
        case "Circle", "Annulus", "Arc":       return 2.0 * unit   // diameter
        case "Dot":                             return 0.16 * unit  // tiny dot
        case "Square":                          return 2.0 * unit
        case "Rectangle":                       return 4.0 * unit
        case "Triangle":                        return 2.0 * unit
        case "RegularPolygon", "Polygon":       return 2.0 * unit
        case "Ellipse":                         return 2.0 * unit
        case "Star":                            return 2.0 * unit
        case "Line", "DashedLine":              return 2.0 * unit
        case "Arrow", "DoubleArrow":            return 2.0 * unit
        default:                                return 2.0 * unit
        }
    }
    
    /// Height of the shape **in screen pixels**, before user scale
    private var manimShapeHeight: CGFloat {
        switch object.typeName {
        case "Circle", "Annulus", "Arc":       return 2.0 * unit
        case "Dot":                             return 0.16 * unit
        case "Square":                          return 2.0 * unit
        case "Rectangle":                       return 2.0 * unit
        case "Triangle":                        return 2.0 * unit
        case "RegularPolygon", "Polygon":       return 2.0 * unit
        case "Ellipse":                         return 1.0 * unit
        case "Star":                            return 2.0 * unit
        case "Line", "DashedLine":              return max(2, object.strokeWidth)
        case "Arrow", "DoubleArrow":            return max(10, object.strokeWidth * 2)
        default:                                return 2.0 * unit
        }
    }
    
    /// Final width after applying user scale
    private var shapeWidth: CGFloat  { manimShapeWidth * object.scale }
    /// Final height after applying user scale
    private var shapeHeight: CGFloat { manimShapeHeight * object.scale }
    
    private var isCircular: Bool {
        ["Circle", "Dot", "Annulus", "Arc"].contains(object.typeName)
    }
    
    /// Whether this object type is rendered via Manim preview
    private var isRenderedType: Bool {
        ["Tex", "MathTex", "FunctionGraph"].contains(object.typeName)
    }
    
    /// For rendered types, read display size from the preview cache
    private var renderedDisplayWidth: CGFloat {
        guard let p = ManimPreviewCache.shared.preview(for: object) else { return unit * 2 * object.scale }
        return CGFloat(p.manimWidth) * unit * object.scale
    }
    private var renderedDisplayHeight: CGFloat {
        guard let p = ManimPreviewCache.shared.preview(for: object) else { return unit * 1 * object.scale }
        return CGFloat(p.manimHeight) * unit * object.scale
    }
    
    /// Effective height for label offset (uses rendered size for rendered types)
    private var effectiveHeight: CGFloat {
        isRenderedType ? renderedDisplayHeight : shapeHeight
    }
    private var effectiveWidth: CGFloat {
        isRenderedType ? renderedDisplayWidth : shapeWidth
    }
    
    var body: some View {
        ZStack {
            // Selection ring
            if isSelected {
                RoundedRectangle(cornerRadius: isCircular ? effectiveWidth / 2 : 4)
                    .stroke(Color.yellow, lineWidth: 2)
                    .frame(width: effectiveWidth + 8, height: effectiveHeight + 8)
                    .opacity(0.7)
            }
            
            // Main shape
            if isRenderedType {
                shapeView
                    .rotationEffect(.degrees(object.rotation))
            } else {
                shapeView
                    .frame(width: shapeWidth, height: shapeHeight)
                    .foregroundStyle(object.swiftUIColor.opacity(object.opacity))
                    .rotationEffect(.degrees(object.rotation))
            }
            
            // Variable-name label
            Text(object.variableName)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Capsule().fill(Color.black.opacity(0.7)))
                .offset(y: effectiveHeight / 2 + 12)
        }
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .shadow(color: .black.opacity(isDragging ? 0.6 : 0.3), radius: isDragging ? 8 : 4)
        .animation(.easeOut(duration: 0.12), value: isDragging)
    }
    
    @ViewBuilder
    private var shapeView: some View {
        switch object.typeName {
        case "Circle", "Annulus", "Arc":
            Circle()
        case "Dot":
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
            LineShapeView(isDashed: object.typeName == "DashedLine", strokeWidth: object.strokeWidth)
        case "Arrow", "DoubleArrow":
            ArrowShape()
        case "Text":
            TextObjectView(text: object.text, color: object.swiftUIColor, manimUnit: unit, userScale: object.scale)
        case "Tex", "MathTex", "FunctionGraph":
            RenderedPreviewView(object: object, unit: unit)
        default:
            Circle()
        }
    }
}

/// A proper line shape with optional dashing, rendered as a path
struct LineShapeView: View {
    let isDashed: Bool
    let strokeWidth: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
            }
            .stroke(style: StrokeStyle(lineWidth: strokeWidth, dash: isDashed ? [6, 4] : []))
        }
    }
}

// MARK: - Manim-Rendered Preview (Tex, MathTex, FunctionGraph)

struct RenderedPreviewView: View {
    let object: ManimObject
    let unit: CGFloat        // pixels per manim unit
    
    private var cache: ManimPreviewCache { .shared }
    
    private var preview: PreviewResult? {
        cache.preview(for: object)
    }
    
    private var displayWidth: CGFloat {
        guard let p = preview else { return unit * 2 * object.scale }
        return CGFloat(p.manimWidth) * unit * object.scale
    }
    private var displayHeight: CGFloat {
        guard let p = preview else { return unit * 1 * object.scale }
        return CGFloat(p.manimHeight) * unit * object.scale
    }
    
    var body: some View {
        Group {
            if let p = preview {
                Image(nsImage: p.image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: displayWidth, height: displayHeight)
            } else if cache.isRendering(for: object) {
                renderingPlaceholder
            } else {
                renderingPlaceholder
                    .onAppear {
                        cache.requestRender(for: object)
                    }
            }
        }
        .onChange(of: cache.cacheKey(for: object)) { _, newKey in
            // When object properties change, invalidate and re-render
            if cache.preview(for: object) == nil {
                cache.requestRender(for: object)
            }
        }
    }
    
    private var renderingPlaceholder: some View {
        VStack(spacing: 6) {
            ProgressView()
                .controlSize(.small)
                .tint(.white)
            Text("Rendering...")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(width: unit * 2, height: unit * 0.8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.05))
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
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
    var manimUnit: CGFloat = 50
    var userScale: Double = 1.0
    
    /// Manim's default text renders at roughly 0.5 manim units tall for the font.
    /// We approximate this so the text feels proportional.
    private var fontSize: CGFloat {
        // Manim default text height ≈ 0.5 units; scale by user's scale()
        let base = manimUnit * 0.48 * userScale
        return max(8, min(base, 120))   // clamp to readable range
    }
    
    var body: some View {
        Text(text.isEmpty ? "Text" : text)
            .font(.system(size: fontSize, weight: .medium))
            .foregroundColor(color)
            .lineLimit(nil)
            .fixedSize()
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
    }
}
