//
//  ManimRenderer.swift
//  Manimator
//
//  Process bridge for executing the Manim CLI tool.
//  Runs rendering asynchronously on a background thread and captures output.
//
//  IMPORTANT: App Sandbox must be DISABLED for Process to work.
//  In Xcode: Target → Signing & Capabilities → remove "App Sandbox"
//  or set ENABLE_APP_SANDBOX = NO in build settings.
//

import Foundation
import Observation

@Observable
class ManimRenderer {
    
    // MARK: - Configuration
    
    /// Path to the Manim executable. Change this if your Homebrew path differs.
    /// Common paths:
    ///   - Apple Silicon: /opt/homebrew/bin/manim
    ///   - Intel Mac:    /usr/local/bin/manim
    var manimExecutablePath: String = "/opt/homebrew/bin/manim"
    
    /// Quality flag for Manim rendering.
    /// -ql = low quality (480p15), -qm = medium (720p30), -qh = high (1080p60)
    var qualityFlag: String = "-ql"
    
    // MARK: - State
    
    var isRendering: Bool = false
    var videoURL: URL? = nil
    var errorMessage: String? = nil
    var consoleOutput: String = ""
    var progress: String = "Ready"
    
    // MARK: - Rendering
    
    /// Render the given Manim code by writing it to a temp file and invoking the CLI.
    /// - Parameters:
    ///   - code: The complete Python source code for the Manim scene.
    ///   - sceneName: The class name of the scene to render (e.g. "MyScene").
    func render(code: String, sceneName: String) {
        // Reset state
        isRendering = true
        errorMessage = nil
        consoleOutput = ""
        progress = "Preparing..."
        videoURL = nil
        
        // Create a unique temporary directory for this render
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("Manimator_\(UUID().uuidString)")
        
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        } catch {
            self.errorMessage = "Failed to create temp directory: \(error.localizedDescription)"
            self.isRendering = false
            self.progress = "Error"
            return
        }
        
        let scriptURL = tempDir.appendingPathComponent("scene.py")
        
        // Write code to the temp file
        do {
            try code.write(to: scriptURL, atomically: true, encoding: .utf8)
        } catch {
            self.errorMessage = "Failed to write script: \(error.localizedDescription)"
            self.isRendering = false
            self.progress = "Error"
            return
        }
        
        self.progress = "Rendering..."
        
        // Run Process on a background thread
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            let process = Process()
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            
            process.executableURL = URL(fileURLWithPath: self.manimExecutablePath)
            process.arguments = [
                self.qualityFlag,
                "--media_dir", tempDir.path,
                scriptURL.path,
                sceneName
            ]
            
            // Set environment to inherit system PATH so Manim can find ffmpeg, latex, etc.
            var env = ProcessInfo.processInfo.environment
            // Ensure Homebrew + LaTeX (MacTeX/TexLive) paths are available
            let extraPaths = [
                "/opt/homebrew/bin",
                "/opt/homebrew/sbin",
                "/usr/local/bin",
                "/Library/TeX/texbin",                          // MacTeX standard symlink
                "/usr/local/texlive/2024/bin/universal-darwin", // TexLive direct path
            ].joined(separator: ":")
            if let existingPath = env["PATH"] {
                env["PATH"] = "\(extraPaths):\(existingPath)"
            } else {
                env["PATH"] = "\(extraPaths):/usr/bin:/bin:/usr/sbin:/sbin"
            }
            process.environment = env
            process.currentDirectoryURL = tempDir
            
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe
            
            do {
                try process.run()
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to launch Manim: \(error.localizedDescription)"
                    self.isRendering = false
                    self.progress = "Error"
                }
                return
            }
            
            // Read stdout
            let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let stdoutString = String(data: stdoutData, encoding: .utf8) ?? ""
            
            // Read stderr
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let stderrString = String(data: stderrData, encoding: .utf8) ?? ""
            
            process.waitUntilExit()
            
            let exitCode = process.terminationStatus
            let combined = "=== STDOUT ===\n\(stdoutString)\n\n=== STDERR ===\n\(stderrString)"
            
            // Print to Xcode console for debugging
            print(combined)
            
            await MainActor.run {
                self.consoleOutput = combined
                
                if exitCode != 0 {
                    self.errorMessage = "Manim exited with code \(exitCode).\n\(stderrString.prefix(500))"
                    self.isRendering = false
                    self.progress = "Render failed"
                    return
                }
                
                // Find the generated video file
                if let videoFile = self.findVideoFile(in: tempDir, sceneName: sceneName) {
                    self.videoURL = videoFile
                    self.progress = "Done ✓"
                } else {
                    self.errorMessage = "Render completed but video file not found in \(tempDir.path)"
                    self.progress = "Video not found"
                }
                
                self.isRendering = false
            }
        }
    }
    
    /// Search for the generated .mp4 video file in the media output directory.
    private func findVideoFile(in tempDir: URL, sceneName: String) -> URL? {
        let fm = FileManager.default
        
        // Manim outputs to: media/videos/scene/<quality>/SceneName.mp4
        // Quality directories: 480p15, 720p30, 1080p60, etc.
        let videosDir = tempDir.appendingPathComponent("videos/scene")
        
        // Try to find the video in any quality subdirectory
        if let qualityDirs = try? fm.contentsOfDirectory(at: videosDir, includingPropertiesForKeys: nil) {
            for dir in qualityDirs {
                let videoFile = dir.appendingPathComponent("\(sceneName).mp4")
                if fm.fileExists(atPath: videoFile.path) {
                    return videoFile
                }
            }
        }
        
        // Fallback: search recursively for any .mp4 file
        if let enumerator = fm.enumerator(at: tempDir, includingPropertiesForKeys: nil) {
            while let fileURL = enumerator.nextObject() as? URL {
                if fileURL.pathExtension == "mp4" {
                    return fileURL
                }
            }
        }
        
        return nil
    }
}
