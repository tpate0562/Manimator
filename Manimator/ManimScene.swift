//
//  ManimScene.swift
//  Manimator
//
//  Visual-first data models. Objects are the source of truth;
//  Manim Python code is auto-generated from them.
//  Includes a Timeline model to sequence animations.
//

import SwiftUI
import Observation

// MARK: - Manim Object Model

/// A single Manim object with all visual properties.
struct ManimObject: Identifiable, Hashable, Codable {
    var id: String                          // stable ID = variable name
    var variableName: String                // e.g. "circle_1"
    var typeName: String                    // e.g. "Circle", "FunctionGraph"
    var position: CGPoint = .zero           // Manim coords (origin-center, y-up)
    var color: String = "WHITE"             // stroke / main color
    var fillColor: String? = nil            // fill color (nil = no separate fill)
    var scale: Double = 1.0
    var rotation: Double = 0.0             // degrees
    var opacity: Double = 1.0
    var strokeWidth: Double = 2.0
    var text: String = ""                   // for Text/Tex/MathTex objects
    
    // Properties specific to graphs
    var equation: String = "np.sin(x)"
    var xRangeMin: Double = -5.0
    var xRangeMax: Double = 5.0
    var yRangeMin: Double = -3.0
    var yRangeMax: Double = 3.0
    var graphWidth: Double = 10.0
    var graphHeight: Double = 6.0
    
    enum CodingKeys: String, CodingKey {
        case id, variableName, typeName, position, color, fillColor, scale, rotation, opacity, strokeWidth, text
        case equation, xRangeMin, xRangeMax, yRangeMin, yRangeMax, graphWidth, graphHeight
    }
    
    init(id: String, variableName: String, typeName: String, position: CGPoint = .zero, color: String = "WHITE", fillColor: String? = nil, scale: Double = 1.0, rotation: Double = 0.0, opacity: Double = 1.0, strokeWidth: Double = 2.0, text: String = "", equation: String = "np.sin(x)", xRangeMin: Double = -5.0, xRangeMax: Double = 5.0, yRangeMin: Double = -3.0, yRangeMax: Double = 3.0, graphWidth: Double = 10.0, graphHeight: Double = 6.0) {
        self.id = id
        self.variableName = variableName
        self.typeName = typeName
        self.position = position
        self.color = color
        self.fillColor = fillColor
        self.scale = scale
        self.rotation = rotation
        self.opacity = opacity
        self.strokeWidth = strokeWidth
        self.text = text
        self.equation = equation
        self.xRangeMin = xRangeMin
        self.xRangeMax = xRangeMax
        self.yRangeMin = yRangeMin
        self.yRangeMax = yRangeMax
        self.graphWidth = graphWidth
        self.graphHeight = graphHeight
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.variableName = try container.decode(String.self, forKey: .variableName)
        self.typeName = try container.decode(String.self, forKey: .typeName)
        self.position = try container.decodeIfPresent(CGPoint.self, forKey: .position) ?? .zero
        self.color = try container.decodeIfPresent(String.self, forKey: .color) ?? "WHITE"
        self.fillColor = try container.decodeIfPresent(String.self, forKey: .fillColor)
        self.scale = try container.decodeIfPresent(Double.self, forKey: .scale) ?? 1.0
        self.rotation = try container.decodeIfPresent(Double.self, forKey: .rotation) ?? 0.0
        self.opacity = try container.decodeIfPresent(Double.self, forKey: .opacity) ?? 1.0
        self.strokeWidth = try container.decodeIfPresent(Double.self, forKey: .strokeWidth) ?? 2.0
        self.text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        
        self.equation = try container.decodeIfPresent(String.self, forKey: .equation) ?? "np.sin(x)"
        self.xRangeMin = try container.decodeIfPresent(Double.self, forKey: .xRangeMin) ?? -5.0
        self.xRangeMax = try container.decodeIfPresent(Double.self, forKey: .xRangeMax) ?? 5.0
        self.yRangeMin = try container.decodeIfPresent(Double.self, forKey: .yRangeMin) ?? -3.0
        self.yRangeMax = try container.decodeIfPresent(Double.self, forKey: .yRangeMax) ?? 3.0
        self.graphWidth = try container.decodeIfPresent(Double.self, forKey: .graphWidth) ?? 10.0
        self.graphHeight = try container.decodeIfPresent(Double.self, forKey: .graphHeight) ?? 6.0
    }
    
    // MARK: - Static Data
    
    static let shapeTypes = [
        "Circle", "Square", "Rectangle", "Triangle",
        "RegularPolygon", "Polygon", "Ellipse", "Star",
        "Dot", "Annulus", "Arc",
    ]
    
    static let lineTypes = [
        "Line", "Arrow", "DoubleArrow", "DashedLine",
    ]
    
    static let textTypes = [
        "Text", "Tex", "MathTex",
    ]
    
    static let graphTypes = [
        "FunctionGraph"
    ]
    
    static let numberTypes = [
        "DecimalNumber", "Integer",
    ]
    
    static var allTypes: [String] { shapeTypes + lineTypes + textTypes + graphTypes + numberTypes }
    
    static let manimColors = [
        "WHITE", "GRAY", "BLACK",
        "RED", "GREEN", "BLUE", "YELLOW",
        "ORANGE", "PURPLE", "PINK", "TEAL",
        "GOLD", "MAROON",
        "RED_A", "RED_B", "RED_C", "RED_D",
        "GREEN_A", "GREEN_B", "GREEN_C", "GREEN_D",
        "BLUE_A", "BLUE_B", "BLUE_C", "BLUE_D",
    ]
    
    /// SF Symbol for the object type
    var iconName: String {
        switch typeName.lowercased() {
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
    
    /// SwiftUI Color from Manim color name or Custom Hex
    var swiftUIColor: Color {
        if color.hasPrefix("\"#") && color.hasSuffix("\"") {
            let hex = String(color.dropFirst(2).dropLast(1))
            if let uiColor = NSColor(hexString: hex) {
                return Color(nsColor: uiColor)
            }
        }
        switch color.uppercased() {
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
    
    var isTextType: Bool { Self.textTypes.contains(typeName) }
    var isLineType: Bool { Self.lineTypes.contains(typeName) }
    var isGraphType: Bool { Self.graphTypes.contains(typeName) }
    var isNumberType: Bool { Self.numberTypes.contains(typeName) }
}

// MARK: - Animation Timeline Models

struct AnimationCategory: Hashable {
    let name: String
    let icon: String
    let types: [String]
}

struct ManimAnimation: Identifiable, Hashable, Codable {
    let id = UUID()
    var targetObjectID: String
    var animationType: String
    var duration: Double = 1.0
    
    // MoveTo parameters
    var targetX: Double = 0.0
    var targetY: Double = 0.0
    var targetScale: Double = 1.0
    
    // Indication parameters
    var indicateColor: String? = nil
    var indicateScaleFactor: Double = 1.2
    var flashRadius: Double = 0.3
    var flashNumLines: Int = 12
    var circumscribeShape: String = "Rectangle"
    var focusOnOpacity: Double = 0.2
    var waveAmplitude: Double = 0.2
    var waveDirection: String = "UP"
    var wiggleScaleValue: Double = 1.1
    var wiggleCount: Int = 6
    
    // Creation / Removal parameters
    var shiftDirection: String? = nil
    var fadeScale: Double = 1.0
    var growEdge: String = "DOWN"
    
    // Transform parameters
    var rotationAngle: Double = 180.0
    var transformTargetID: String? = nil
    
    // Numbers parameters
    var changeValue: Double = 0.0
    
    // Rate function
    var rateFunc: String = "smooth"
    
    // MARK: - Categories
    
    static let categories: [AnimationCategory] = [
        AnimationCategory(name: "Creation", icon: "sparkles", types: [
            "Create", "FadeIn", "Write", "DrawBorderThenFill",
            "GrowFromCenter", "GrowFromEdge", "SpinInFromNothing",
            "FadeOut", "Uncreate", "ShrinkToCenter"
        ]),
        AnimationCategory(name: "Indication", icon: "hand.point.up.left.fill", types: [
            "Indicate", "Flash", "Circumscribe", "FocusOn", "ApplyWave", "Wiggle"
        ]),
        AnimationCategory(name: "Transform", icon: "arrow.triangle.2.circlepath", types: [
            "MoveTo", "Rotate", "Transform", "ReplacementTransform"
        ]),
        AnimationCategory(name: "Composition", icon: "square.stack.3d.up", types: []),
        AnimationCategory(name: "Numbers", icon: "number", types: [
            "ChangeDecimalToValue"
        ]),
    ]
    
    static let types: [String] = categories.flatMap { $0.types }
    
    static let rateFunctions = [
        "smooth", "linear", "rush_into", "rush_from",
        "there_and_back", "double_smooth", "running_start"
    ]
    
    static let directionOptions = ["UP", "DOWN", "LEFT", "RIGHT"]
    static let edgeOptions = ["UP", "DOWN", "LEFT", "RIGHT"]
    static let shapeOptions = ["Rectangle", "Circle"]
    
    static func category(for type: String) -> String {
        for cat in categories where cat.types.contains(type) {
            return cat.name
        }
        return "Creation"
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case targetObjectID, animationType, duration
        case targetX, targetY, targetScale
        case indicateColor, indicateScaleFactor
        case flashRadius, flashNumLines
        case circumscribeShape, focusOnOpacity
        case waveAmplitude, waveDirection
        case wiggleScaleValue, wiggleCount
        case shiftDirection, fadeScale, growEdge
        case rotationAngle, transformTargetID
        case changeValue, rateFunc
    }
    
    init(targetObjectID: String, animationType: String, duration: Double = 1.0) {
        self.targetObjectID = targetObjectID
        self.animationType = animationType
        self.duration = duration
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.targetObjectID = try c.decode(String.self, forKey: .targetObjectID)
        self.animationType = try c.decode(String.self, forKey: .animationType)
        self.duration = try c.decodeIfPresent(Double.self, forKey: .duration) ?? 1.0
        self.targetX = try c.decodeIfPresent(Double.self, forKey: .targetX) ?? 0.0
        self.targetY = try c.decodeIfPresent(Double.self, forKey: .targetY) ?? 0.0
        self.targetScale = try c.decodeIfPresent(Double.self, forKey: .targetScale) ?? 1.0
        self.indicateColor = try c.decodeIfPresent(String.self, forKey: .indicateColor)
        self.indicateScaleFactor = try c.decodeIfPresent(Double.self, forKey: .indicateScaleFactor) ?? 1.2
        self.flashRadius = try c.decodeIfPresent(Double.self, forKey: .flashRadius) ?? 0.3
        self.flashNumLines = try c.decodeIfPresent(Int.self, forKey: .flashNumLines) ?? 12
        self.circumscribeShape = try c.decodeIfPresent(String.self, forKey: .circumscribeShape) ?? "Rectangle"
        self.focusOnOpacity = try c.decodeIfPresent(Double.self, forKey: .focusOnOpacity) ?? 0.2
        self.waveAmplitude = try c.decodeIfPresent(Double.self, forKey: .waveAmplitude) ?? 0.2
        self.waveDirection = try c.decodeIfPresent(String.self, forKey: .waveDirection) ?? "UP"
        self.wiggleScaleValue = try c.decodeIfPresent(Double.self, forKey: .wiggleScaleValue) ?? 1.1
        self.wiggleCount = try c.decodeIfPresent(Int.self, forKey: .wiggleCount) ?? 6
        self.shiftDirection = try c.decodeIfPresent(String.self, forKey: .shiftDirection)
        self.fadeScale = try c.decodeIfPresent(Double.self, forKey: .fadeScale) ?? 1.0
        self.growEdge = try c.decodeIfPresent(String.self, forKey: .growEdge) ?? "DOWN"
        self.rotationAngle = try c.decodeIfPresent(Double.self, forKey: .rotationAngle) ?? 180.0
        self.transformTargetID = try c.decodeIfPresent(String.self, forKey: .transformTargetID)
        self.changeValue = try c.decodeIfPresent(Double.self, forKey: .changeValue) ?? 0.0
        self.rateFunc = try c.decodeIfPresent(String.self, forKey: .rateFunc) ?? "smooth"
    }
}

struct TimelineStep: Identifiable, Codable {
    let id = UUID()
    var animations: [ManimAnimation] = []
    var waitTime: Double = 1.0
    var playMode: String = "parallel"  // "parallel", "lagged", "sequential"
    var lagRatio: Double = 0.5
    
    init(animations: [ManimAnimation] = [], waitTime: Double = 1.0) {
        self.animations = animations
        self.waitTime = waitTime
    }
    
    enum CodingKeys: String, CodingKey {
        case animations, waitTime, playMode, lagRatio
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.animations = try c.decodeIfPresent([ManimAnimation].self, forKey: .animations) ?? []
        self.waitTime = try c.decodeIfPresent(Double.self, forKey: .waitTime) ?? 1.0
        self.playMode = try c.decodeIfPresent(String.self, forKey: .playMode) ?? "parallel"
        self.lagRatio = try c.decodeIfPresent(Double.self, forKey: .lagRatio) ?? 0.5
    }
}

// MARK: - Aspect Ratio

enum AspectRatioChoice: String, CaseIterable, Identifiable {
    case sixteenByNine = "16:9"
    case fourByThree = "4:3"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    /// Aspect ratio as width/height
    var ratio: Double {
        switch self {
        case .sixteenByNine: return 16.0 / 9.0
        case .fourByThree: return 4.0 / 3.0
        case .custom: return 16.0 / 9.0   // fallback, overridden by custom values
        }
    }
}

// MARK: - Scene State (Source of Truth)

struct SceneStateDTO: Codable {
    var sceneName: String
    var objects: [ManimObject]
    var timeline: [TimelineStep]
}

@Observable
class SceneState {
    /// The canonical list of objects. This is the source of truth.
    var objects: [ManimObject] = []
    
    /// The chronological steps of animations in the scene.
    var timeline: [TimelineStep] = []
    
    var selectedObjectID: String? = nil
    var selectedStepID: UUID? = nil
    
    var sceneName: String = "MyScene"
    
    /// Auto-generated code (read-only unless user switches to manual)
    var generatedCode: String = ""
    
    /// When true, user is editing code manually (disable auto-generation)
    var isManualCodeMode: Bool = false
    
    /// Counter for auto-naming objects
    var objectCounters: [String: Int] = [:]
    
    // MARK: - Aspect Ratio
    
    var aspectRatioChoice: AspectRatioChoice = .sixteenByNine
    /// Custom width ratio component (only used when aspectRatioChoice == .custom)
    var customRatioW: Double = 16.0
    /// Custom height ratio component
    var customRatioH: Double = 9.0
    
    /// The effective aspect ratio (width/height)
    var effectiveAspectRatio: Double {
        switch aspectRatioChoice {
        case .sixteenByNine, .fourByThree:
            return aspectRatioChoice.ratio
        case .custom:
            return customRatioH > 0 ? customRatioW / customRatioH : 16.0 / 9.0
        }
    }
    
    /// Manim Y range is always ±4 (FRAME_HEIGHT = 8)
    var manimYRange: ClosedRange<Double> { -4.0...4.0 }
    
    /// Manim X range derived from aspect ratio: halfWidth = 4 * aspectRatio
    var manimXRange: ClosedRange<Double> {
        let halfW = 4.0 * effectiveAspectRatio
        return -halfW...halfW
    }
    
    init() {
        // Initialize with one empty wait step for convenience
        timeline.append(TimelineStep(waitTime: 1.0))
    }
    
    // MARK: - Serialization
    
    func exportJSON() -> Data? {
        let dto = SceneStateDTO(sceneName: sceneName, objects: objects, timeline: timeline)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(dto)
    }
    
    func importJSON(data: Data) {
        if let dto = try? JSONDecoder().decode(SceneStateDTO.self, from: data) {
            self.sceneName = dto.sceneName
            self.objects = dto.objects
            self.timeline = dto.timeline
            
            self.objectCounters.removeAll()
            for obj in self.objects {
                let baseName = obj.typeName.lowercased()
                let current = self.objectCounters[baseName] ?? 0
                self.objectCounters[baseName] = current + 1
            }
            
            self.selectedObjectID = nil
            self.selectedStepID = nil
            self.regenerateCode()
        }
    }
    
    // MARK: - Object Management
    
    func addObject(type: String) {
        let baseName = type.lowercased()
        let count = (objectCounters[baseName] ?? 0) + 1
        objectCounters[baseName] = count
        let varName = "\(baseName)_\(count)"
        
        let jitterX = Double.random(in: -0.5...0.5)
        let jitterY = Double.random(in: -0.5...0.5)
        
        var obj = ManimObject(
            id: varName,
            variableName: varName,
            typeName: type,
            position: CGPoint(x: jitterX, y: jitterY),
            color: "BLUE"
        )
        
        if ManimObject.textTypes.contains(type) {
            obj.text = "Hello"
            obj.color = "WHITE"
        }
        if type == "Dot" {
            obj.scale = 1.0
            obj.color = "YELLOW"
        }
        if ManimObject.lineTypes.contains(type) {
            obj.color = "WHITE"
        }
        if ManimObject.graphTypes.contains(type) {
            obj.color = "GREEN"
        }
        if ManimObject.numberTypes.contains(type) {
            obj.text = "0"  // initial numeric value
            obj.color = "WHITE"
        }
        
        objects.append(obj)
        selectedObjectID = varName
        regenerateCode()
    }
    
    func deleteObject(id: String) {
        objects.removeAll { $0.id == id }
        if selectedObjectID == id {
            selectedObjectID = nil
        }
        
        // Remove object from all timeline steps
        for i in 0..<timeline.count {
            timeline[i].animations.removeAll { $0.targetObjectID == id }
        }
        
        regenerateCode()
    }
    
    func duplicateObject(id: String) {
        guard let source = objects.first(where: { $0.id == id }) else { return }
        let baseName = source.typeName.lowercased()
        let count = (objectCounters[baseName] ?? 0) + 1
        objectCounters[baseName] = count
        let varName = "\(baseName)_\(count)"
        
        var copy = source
        copy.id = varName
        copy.variableName = varName
        copy.position.x += 0.5
        copy.position.y -= 0.5
        
        objects.append(copy)
        selectedObjectID = varName
        regenerateCode()
    }
    
    func moveObject(id: String, to position: CGPoint) {
        guard let idx = objects.firstIndex(where: { $0.id == id }) else { return }
        objects[idx].position = position
        regenerateCode()
    }
    
    func updateObject(id: String, _ mutate: (inout ManimObject) -> Void) {
        guard let idx = objects.firstIndex(where: { $0.id == id }) else { return }
        let oldID = objects[idx].id
        mutate(&objects[idx])
        objects[idx].id = objects[idx].variableName
        
        // If variable name changed, update timeline references
        if oldID != objects[idx].id {
            for i in 0..<timeline.count {
                for j in 0..<timeline[i].animations.count {
                    if timeline[i].animations[j].targetObjectID == oldID {
                        timeline[i].animations[j].targetObjectID = objects[idx].id
                    }
                }
            }
        }
        regenerateCode()
    }
    
    // MARK: - Timeline CRUD
    
    func addTimelineStep() {
        let step = TimelineStep(waitTime: 1.0)
        timeline.append(step)
        selectedStepID = step.id
        regenerateCode()
    }
    
    func duplicateTimelineStep(id: UUID) {
        guard let idx = timeline.firstIndex(where: { $0.id == id }) else { return }
        var copy = timeline[idx]
        copy.animations = copy.animations.map { src in
            var a = ManimAnimation(targetObjectID: src.targetObjectID, animationType: src.animationType, duration: src.duration)
            a.targetX = src.targetX; a.targetY = src.targetY; a.targetScale = src.targetScale
            a.indicateColor = src.indicateColor; a.indicateScaleFactor = src.indicateScaleFactor
            a.flashRadius = src.flashRadius; a.flashNumLines = src.flashNumLines
            a.circumscribeShape = src.circumscribeShape; a.focusOnOpacity = src.focusOnOpacity
            a.waveAmplitude = src.waveAmplitude; a.waveDirection = src.waveDirection
            a.wiggleScaleValue = src.wiggleScaleValue; a.wiggleCount = src.wiggleCount
            a.shiftDirection = src.shiftDirection; a.fadeScale = src.fadeScale; a.growEdge = src.growEdge
            a.rotationAngle = src.rotationAngle; a.transformTargetID = src.transformTargetID
            a.changeValue = src.changeValue; a.rateFunc = src.rateFunc
            return a
        }
        timeline.insert(copy, at: idx + 1)
        selectedStepID = copy.id
        regenerateCode()
    }
    
    func deleteTimelineStep(id: UUID) {
        timeline.removeAll { $0.id == id }
        if selectedStepID == id {
            selectedStepID = timeline.last?.id
        }
        regenerateCode()
    }
    
    func moveTimelineStep(from source: IndexSet, to destination: Int) {
        timeline.move(fromOffsets: source, toOffset: destination)
        regenerateCode()
    }
    
    func addAnimation(_ anim: ManimAnimation, toStepID stepID: UUID) {
        guard let stepIdx = timeline.firstIndex(where: { $0.id == stepID }) else { return }
        timeline[stepIdx].animations.append(anim)
        regenerateCode()
    }
    
    func deleteAnimation(stepID: UUID, animationID: UUID) {
        guard let stepIdx = timeline.firstIndex(where: { $0.id == stepID }) else { return }
        timeline[stepIdx].animations.removeAll { $0.id == animationID }
        regenerateCode()
    }
    
    func updateAnimationDuration(stepID: UUID, animationID: UUID, duration: Double) {
        guard let stepIdx = timeline.firstIndex(where: { $0.id == stepID }),
              let animIdx = timeline[stepIdx].animations.firstIndex(where: { $0.id == animationID }) else { return }
        timeline[stepIdx].animations[animIdx].duration = duration
        regenerateCode()
    }
    
    func updateAnimationType(stepID: UUID, animationID: UUID, type: String) {
        guard let stepIdx = timeline.firstIndex(where: { $0.id == stepID }),
              let animIdx = timeline[stepIdx].animations.firstIndex(where: { $0.id == animationID }) else { return }
        timeline[stepIdx].animations[animIdx].animationType = type
        regenerateCode()
    }
    
    // MARK: - Code Generation
    
    func regenerateCode() {
        guard !isManualCodeMode else { return }
        
        var lines: [String] = []
        lines.append("from manim import *")
        // Need math library for graphing
        lines.append("import numpy as np")
        lines.append("")
        lines.append("class \(sceneName)(Scene):")
        lines.append("    def construct(self):")
        
        if objects.isEmpty && timeline.isEmpty {
            lines.append("        pass")
        } else {
            // 1. Object creations
            for obj in objects {
                if obj.isGraphType {
                    let axesVar = "\(obj.variableName)_axes"
                    let graphVar = "\(obj.variableName)_graph"
                    
                    lines.append("        \(axesVar) = Axes(")
                    let xInterval = max(1.0, (obj.xRangeMax - obj.xRangeMin) / 5)
                    let yInterval = max(1.0, (obj.yRangeMax - obj.yRangeMin) / 5)
                    
                    lines.append("            x_range=[\(obj.xRangeMin), \(obj.xRangeMax), \(String(format: "%.1f", xInterval))],")
                    lines.append("            y_range=[\(obj.yRangeMin), \(obj.yRangeMax), \(String(format: "%.1f", yInterval))],")
                    lines.append("            x_length=\(String(format: "%.1f", obj.graphWidth)),")
                    lines.append("            y_length=\(String(format: "%.1f", obj.graphHeight))")
                    lines.append("        )")
                    lines.append("        \(graphVar) = \(axesVar).plot(lambda x: \(obj.equation), color=\(obj.color))")
                    lines.append("        \(obj.variableName) = VGroup(\(axesVar), \(graphVar))")
                    
                    if obj.position.x != 0 || obj.position.y != 0 {
                        let x = String(format: "%.2f", obj.position.x)
                        let y = String(format: "%.2f", obj.position.y)
                        lines.append("        \(obj.variableName).move_to([\(x), \(y), 0])")
                    }
                    if abs(obj.scale - 1.0) > 0.01 {
                        lines.append("        \(obj.variableName).scale(\(String(format: "%.2f", obj.scale)))")
                    }
                    if abs(obj.rotation) > 0.1 {
                        let rad = String(format: "%.4f", obj.rotation * .pi / 180.0)
                        lines.append("        \(obj.variableName).rotate(\(rad))")
                    }
                    if abs(obj.opacity - 1.0) > 0.01 {
                        lines.append("        \(obj.variableName).set_opacity(\(String(format: "%.2f", obj.opacity)))")
                    }
                    lines.append("")
                    continue
                }
                
                lines.append("        \(generateCreationLine(obj))")
                
                if obj.position.x != 0 || obj.position.y != 0 {
                    let x = String(format: "%.2f", obj.position.x)
                    let y = String(format: "%.2f", obj.position.y)
                    lines.append("        \(obj.variableName).move_to([\(x), \(y), 0])")
                }
                if abs(obj.scale - 1.0) > 0.01 {
                    lines.append("        \(obj.variableName).scale(\(String(format: "%.2f", obj.scale)))")
                }
                if abs(obj.rotation) > 0.1 {
                    let rad = String(format: "%.4f", obj.rotation * .pi / 180.0)
                    lines.append("        \(obj.variableName).rotate(\(rad))")
                }
                if abs(obj.opacity - 1.0) > 0.01 {
                    lines.append("        \(obj.variableName).set_opacity(\(String(format: "%.2f", obj.opacity)))")
                }
                if abs(obj.strokeWidth - 2.0) > 0.1 {
                    lines.append("        \(obj.variableName).set_stroke(width=\(String(format: "%.1f", obj.strokeWidth)))")
                }
                lines.append("")
            }
            
            // 2. Timeline playing
            lines.append("        # --- Timeline ---")
            for (index, step) in timeline.enumerated() {
                lines.append("        # Step \(index + 1)")
                if step.animations.isEmpty {
                    lines.append("        self.wait(\(String(format: "%.1f", step.waitTime)))")
                } else {
                    let maxDuration = step.animations.map { $0.duration }.max() ?? 1.0
                    var animStrings: [String] = []
                    
                    for anim in step.animations {
                        guard objects.contains(where: { $0.id == anim.targetObjectID }) else { continue }
                        let obj = anim.targetObjectID
                        let f = { (v: Double) in String(format: "%.2f", v) }
                        var animStr = ""
                        
                        switch anim.animationType {
                        // --- Creation / Removal (no extra params) ---
                        case "Create", "Write", "DrawBorderThenFill", "GrowFromCenter",
                             "SpinInFromNothing", "Uncreate", "ShrinkToCenter":
                            animStr = "\(anim.animationType)(\(obj))"
                            
                        case "FadeIn":
                            var args = [obj]
                            if let dir = anim.shiftDirection { args.append("shift=\(dir)") }
                            if abs(anim.fadeScale - 1.0) > 0.01 { args.append("scale=\(f(anim.fadeScale))") }
                            animStr = "FadeIn(\(args.joined(separator: ", ")))"
                            
                        case "FadeOut":
                            var args = [obj]
                            if let dir = anim.shiftDirection { args.append("shift=\(dir)") }
                            if abs(anim.fadeScale - 1.0) > 0.01 { args.append("scale=\(f(anim.fadeScale))") }
                            animStr = "FadeOut(\(args.joined(separator: ", ")))"
                            
                        case "GrowFromEdge":
                            animStr = "GrowFromEdge(\(obj), edge=\(anim.growEdge))"
                            
                        // --- Indication ---
                        case "Indicate":
                            var args = [obj]
                            if let c = anim.indicateColor { args.append("color=\(c)") }
                            if abs(anim.indicateScaleFactor - 1.2) > 0.01 { args.append("scale_factor=\(f(anim.indicateScaleFactor))") }
                            animStr = "Indicate(\(args.joined(separator: ", ")))"
                            
                        case "Flash":
                            var args = [obj]
                            if let c = anim.indicateColor { args.append("color=\(c)") }
                            if abs(anim.flashRadius - 0.3) > 0.01 { args.append("flash_radius=\(f(anim.flashRadius))") }
                            if anim.flashNumLines != 12 { args.append("num_lines=\(anim.flashNumLines)") }
                            animStr = "Flash(\(args.joined(separator: ", ")))"
                            
                        case "Circumscribe":
                            var args = [obj]
                            if let c = anim.indicateColor { args.append("color=\(c)") }
                            if anim.circumscribeShape != "Rectangle" { args.append("shape=\(anim.circumscribeShape)") }
                            animStr = "Circumscribe(\(args.joined(separator: ", ")))"
                            
                        case "FocusOn":
                            var args = [obj]
                            if let c = anim.indicateColor { args.append("color=\(c)") }
                            if abs(anim.focusOnOpacity - 0.2) > 0.01 { args.append("opacity=\(f(anim.focusOnOpacity))") }
                            animStr = "FocusOn(\(args.joined(separator: ", ")))"
                            
                        case "ApplyWave":
                            var args = [obj]
                            if anim.waveDirection != "UP" { args.append("direction=\(anim.waveDirection)") }
                            if abs(anim.waveAmplitude - 0.2) > 0.01 { args.append("amplitude=\(f(anim.waveAmplitude))") }
                            animStr = "ApplyWave(\(args.joined(separator: ", ")))"
                            
                        case "Wiggle":
                            var args = [obj]
                            if abs(anim.wiggleScaleValue - 1.1) > 0.01 { args.append("scale_value=\(f(anim.wiggleScaleValue))") }
                            if anim.wiggleCount != 6 { args.append("n_wiggles=\(anim.wiggleCount)") }
                            animStr = "Wiggle(\(args.joined(separator: ", ")))"
                            
                        // --- Transform ---
                        case "MoveTo":
                            var moveCmd = "\(obj).animate.move_to([\(f(anim.targetX)), \(f(anim.targetY)), 0])"
                            if abs(anim.targetScale - 1.0) > 0.01 {
                                moveCmd += ".scale(\(f(anim.targetScale)))"
                            }
                            animStr = moveCmd
                            
                        case "Rotate":
                            let rad = String(format: "%.4f", anim.rotationAngle * .pi / 180.0)
                            animStr = "Rotate(\(obj), angle=\(rad))"
                            
                        case "Transform":
                            let target = anim.transformTargetID ?? obj
                            animStr = "Transform(\(obj), \(target))"
                            
                        case "ReplacementTransform":
                            let target = anim.transformTargetID ?? obj
                            animStr = "ReplacementTransform(\(obj), \(target))"
                            
                        // --- Numbers ---
                        case "ChangeDecimalToValue":
                            animStr = "ChangeDecimalToValue(\(obj), \(f(anim.changeValue)))"
                            
                        default:
                            animStr = "\(anim.animationType)(\(obj))"
                        }
                        
                        // Append rate_func to class-based animations if non-default
                        if anim.rateFunc != "smooth" && !animStr.contains(".animate.") && animStr.hasSuffix(")") {
                            animStr = String(animStr.dropLast()) + ", rate_func=\(anim.rateFunc))"
                        }
                        
                        animStrings.append(animStr)
                    }
                    
                    if !animStrings.isEmpty {
                        let rt = String(format: "%.1f", maxDuration)
                        // Check for non-default rate_func on .animate-style anims
                        let animateRF = step.animations.first(where: { $0.rateFunc != "smooth" && $0.animationType == "MoveTo" })?.rateFunc
                        var playExtras = "run_time=\(rt)"
                        if let rf = animateRF { playExtras += ", rate_func=\(rf)" }
                        
                        let inner = animStrings.joined(separator: ", ")
                        switch step.playMode {
                        case "lagged":
                            lines.append("        self.play(LaggedStart(\(inner), lag_ratio=\(String(format: "%.2f", step.lagRatio))), \(playExtras))")
                        case "sequential":
                            lines.append("        self.play(Succession(\(inner)), \(playExtras))")
                        default:
                            lines.append("        self.play(\(inner), \(playExtras))")
                        }
                    } else {
                        lines.append("        self.wait(\(String(format: "%.1f", step.waitTime)))")
                    }
                }
                lines.append("")
            }
        }
        
        generatedCode = lines.joined(separator: "\n")
    }
    
    private func generateCreationLine(_ obj: ManimObject) -> String {
        var args: [String] = []
        
        switch obj.typeName {
        case "Text":
            args.append("\"\(obj.text)\"")
            if obj.color != "WHITE" { args.append("color=\(obj.color)") }
        case "Tex", "MathTex":
            args.append("r\"\(obj.text)\"")
            if obj.color != "WHITE" { args.append("color=\(obj.color)") }
        case "Line", "Arrow", "DoubleArrow", "DashedLine":
            args.append("LEFT")
            args.append("RIGHT")
            if obj.color != "WHITE" { args.append("color=\(obj.color)") }
        case "RegularPolygon":
            args.append("n=6")
            if obj.color != "WHITE" { args.append("color=\(obj.color)") }
        case "DecimalNumber":
            let numVal = Double(obj.text) ?? 0.0
            args.append(String(format: "%.2f", numVal))
            if obj.color != "WHITE" { args.append("color=\(obj.color)") }
        case "Integer":
            let intVal = Int(obj.text) ?? 0
            args.append("\(intVal)")
            if obj.color != "WHITE" { args.append("color=\(obj.color)") }
        default:
            if obj.color != "WHITE" { args.append("color=\(obj.color)") }
        }
        
        if let fill = obj.fillColor {
            args.append("fill_color=\(fill)")
            args.append("fill_opacity=\(String(format: "%.2f", obj.opacity))")
        }
        
        return "\(obj.variableName) = \(obj.typeName)(\(args.joined(separator: ", ")))"
    }
    
    // MARK: - Parse from manual code
    
    func parseObjectsFromCode() {
        // Skip for now, to keep the MVP visual editor simple.
        // It's much harder to parse complex timelines and equations bidirectionally.
        print("Bidirectional parsing not fully supported for Timeline/Graphs yet.")
    }
}

// MARK: - NSColor Hex Extension
extension NSColor {
    convenience init?(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

