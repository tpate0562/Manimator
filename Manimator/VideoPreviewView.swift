//
//  VideoPreviewView.swift
//  Manimator
//
//  AVPlayer-based video preview with auto-play when a new URL is set.
//  Shows a placeholder when no video is loaded.
//

import SwiftUI
import AVKit

struct VideoPreviewView: View {
    var videoURL: URL?
    @State private var player: AVPlayer? = nil
    
    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                // Placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.85))
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "play.rectangle")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("No video loaded")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("Write your Manim code and click Render")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    )
            }
        }
        .onChange(of: videoURL) { _, newURL in
            if let url = newURL {
                let newPlayer = AVPlayer(url: url)
                self.player = newPlayer
                newPlayer.play()
            } else {
                self.player = nil
            }
        }
    }
}
