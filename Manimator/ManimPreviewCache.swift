//
//  ManimPreviewCache.swift
//  Manimator
//
//  Renders Tex/MathTex and FunctionGraph objects via the Manim CLI
//  to transparent-background PNGs, crops to the object bounds,
//  and caches the results for display on the canvas.
//

import SwiftUI
import AppKit
import Observation

struct PreviewResult {
    let image: NSImage
    /// Width of the rendered object in Manim units
    let manimWidth: Double
    /// Height of the rendered object in Manim units
    let manimHeight: Double
}

@Observable
class ManimPreviewCache {
    static let shared = ManimPreviewCache()
    
    /// Completed renders keyed by cache key
    private(set) var cache: [String: PreviewResult] = [:]
    /// Keys currently being rendered
    private(set) var rendering: Set<String> = []
    
    // MARK: - Public API
    
    func cacheKey(for obj: ManimObject) -> String {
        if obj.isTextType {
            return "\(obj.typeName)|\(obj.text)|\(obj.color)"
        } else if obj.isGraphType {
            return "graph|\(obj.equation)|\(obj.xRangeMin)|\(obj.xRangeMax)|\(obj.yRangeMin)|\(obj.yRangeMax)|\(obj.graphWidth)|\(obj.graphHeight)|\(obj.color)"
        }
        return "?"
    }
    
    func preview(for obj: ManimObject) -> PreviewResult? {
        cache[cacheKey(for: obj)]
    }
    
    func isRendering(for obj: ManimObject) -> Bool {
        rendering.contains(cacheKey(for: obj))
    }
    
    /// Request a background render. Safe to call repeatedly; duplicates are ignored.
    func requestRender(for obj: ManimObject) {
        let key = cacheKey(for: obj)
        guard cache[key] == nil, !rendering.contains(key) else { return }
        rendering.insert(key)
        
        let objCopy = obj                       // value-type copy for thread safety
        Task.detached(priority: .userInitiated) { [weak self] in
            let result = await self?.doRender(objCopy)
            await MainActor.run {
                self?.rendering.remove(key)
                if let result { self?.cache[key] = result }
            }
        }
    }
    
    /// Remove cached preview for an object (call when its renderable properties change)
    func invalidate(for obj: ManimObject) {
        cache.removeValue(forKey: cacheKey(for: obj))
    }
    
    // MARK: - Rendering Pipeline
    
    private func doRender(_ obj: ManimObject) async -> PreviewResult? {
        let uuid = UUID().uuidString
        let workDir = "/tmp/manimator_prev/\(uuid)"
        let scriptPath = "\(workDir)/s.py"
        
        defer { try? FileManager.default.removeItem(atPath: workDir) }
        
        do {
            try FileManager.default.createDirectory(atPath: workDir, withIntermediateDirectories: true)
            let script = buildScript(for: obj)
            try script.write(toFile: scriptPath, atomically: true, encoding: .utf8)
            
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            proc.arguments = ["manim", "render", "-s", "-ql", "--transparent",
                              "--disable_caching", "--media_dir", workDir, scriptPath, "P"]
            
            var env = ProcessInfo.processInfo.environment
            let extra = ["/opt/homebrew/bin", "/usr/local/bin",
                         "/Library/TeX/texbin",
                         "/usr/local/texlive/2024/bin/universal-darwin"]
            env["PATH"] = extra.joined(separator: ":") + ":" + (env["PATH"] ?? "")
            proc.environment = env
            
            let outPipe = Pipe()
            let errPipe = Pipe()
            proc.standardOutput = outPipe
            proc.standardError = errPipe
            
            try proc.run()
            proc.waitUntilExit()
            
            guard proc.terminationStatus == 0 else {
                let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                print("[PreviewCache] Render failed:\n\(err.prefix(500))")
                return nil
            }
            
            // Parse DIMS from stdout
            let outStr = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            var mW = 2.0, mH = 1.0
            for line in outStr.split(separator: "\n") {
                if line.hasPrefix("DIMS:") {
                    let nums = line.dropFirst(5).split(separator: ",")
                    if nums.count == 2 {
                        mW = Double(nums[0].trimmingCharacters(in: .whitespaces)) ?? 2.0
                        mH = Double(nums[1].trimmingCharacters(in: .whitespaces)) ?? 1.0
                    }
                }
            }
            
            // Find the rendered PNG recursively
            let workURL = URL(fileURLWithPath: workDir)
            var foundImage: NSImage? = nil
            if let enumerator = FileManager.default.enumerator(at: workURL, includingPropertiesForKeys: nil) {
                while let fileURL = enumerator.nextObject() as? URL {
                    if fileURL.pathExtension == "png" {
                        foundImage = NSImage(contentsOf: fileURL)
                        break
                    }
                }
            }
            guard let image = foundImage else {
                print("[PreviewCache] PNG not found in \(workDir)")
                return nil
            }
            
            // Crop to non-transparent content
            let cropped = image.trimmedToContent(padding: 4)
            return PreviewResult(image: cropped, manimWidth: max(0.1, mW), manimHeight: max(0.1, mH))
            
        } catch {
            print("[PreviewCache] Error: \(error)")
            return nil
        }
    }
    
    // MARK: - Script Generation
    
    private func buildScript(for obj: ManimObject) -> String {
        if obj.isTextType { return buildTexScript(obj) }
        if obj.isGraphType { return buildGraphScript(obj) }
        return ""
    }
    
    private func buildTexScript(_ obj: ManimObject) -> String {
        // For Tex/MathTex: use triple-quoted raw strings so backslashes
        // (\frac, \sum, etc.) and quotes pass through to LaTeX untouched.
        // For Text: use a regular triple-quoted string (no raw prefix needed).
        let constructor: String
        switch obj.typeName {
        case "Text":
            constructor = "Text(\"\"\"\(obj.text)\"\"\", color=\(obj.color))"
        case "Tex":
            constructor = "Tex(r\"\"\"\(obj.text)\"\"\", color=\(obj.color))"
        default: // MathTex
            constructor = "MathTex(r\"\"\"\(obj.text)\"\"\", color=\(obj.color))"
        }
        
        return """
from manim import *
import numpy as np

class P(Scene):
    def construct(self):
        obj = \(constructor)
        self.add(obj)
        print(f"DIMS:{obj.width},{obj.height}")
"""
    }
    
    private func buildGraphScript(_ obj: ManimObject) -> String {
        let xi = max(1.0, (obj.xRangeMax - obj.xRangeMin) / 5)
        let yi = max(1.0, (obj.yRangeMax - obj.yRangeMin) / 5)
        return """
from manim import *
import numpy as np

class P(Scene):
    def construct(self):
        axes = Axes(
            x_range=[\(obj.xRangeMin), \(obj.xRangeMax), \(String(format:"%.1f",xi))],
            y_range=[\(obj.yRangeMin), \(obj.yRangeMax), \(String(format:"%.1f",yi))],
            x_length=\(String(format:"%.1f",obj.graphWidth)),
            y_length=\(String(format:"%.1f",obj.graphHeight))
        )
        graph = axes.plot(lambda x: \(obj.equation), color=\(obj.color))
        group = VGroup(axes, graph)
        self.add(group)
        print(f"DIMS:{group.width},{group.height}")
"""
    }
}

// MARK: - NSImage Cropping Extension

extension NSImage {
    /// Crop to the tightest bounding box of non-transparent pixels.
    func trimmedToContent(padding: Int = 2) -> NSImage {
        guard let tiffData = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let cgImage = bitmap.cgImage else { return self }
        
        let w = cgImage.width
        let h = cgImage.height
        guard w > 0, h > 0 else { return self }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bpp = 4
        let bpr = w * bpp
        var pixels = [UInt8](repeating: 0, count: h * bpr)
        
        guard let ctx = CGContext(data: &pixels, width: w, height: h,
                                  bitsPerComponent: 8, bytesPerRow: bpr,
                                  space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return self }
        
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
        
        var minX = w, minY = h, maxX = 0, maxY = 0
        for y in 0..<h {
            for x in 0..<w {
                if pixels[y * bpr + x * bpp + 3] > 10 {
                    minX = min(minX, x); minY = min(minY, y)
                    maxX = max(maxX, x); maxY = max(maxY, y)
                }
            }
        }
        guard maxX > minX, maxY > minY else { return self }
        
        let cropRect = CGRect(
            x: max(0, minX - padding),
            y: max(0, minY - padding),
            width: min(w, maxX - minX + 1 + 2 * padding),
            height: min(h, maxY - minY + 1 + 2 * padding)
        )
        guard let cropped = cgImage.cropping(to: cropRect) else { return self }
        return NSImage(cgImage: cropped, size: NSSize(width: cropRect.width, height: cropRect.height))
    }
}
