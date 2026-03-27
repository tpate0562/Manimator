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
            
            Divider()
            
            // Animations List
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 4) {
                    if step.animations.isEmpty {
                        Text("Wait \(String(format: "%.1f", step.waitTime))s")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
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
    }
}

struct AddAnimationPopover: View {
    @Bindable var sceneState: SceneState
    let stepID: UUID
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedObjectID: String = ""
    @State private var selectedAnimType: String = "Create"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Animation")
                .font(.headline)
            
            if sceneState.objects.isEmpty {
                Text("No objects in scene.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target Object")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("", selection: $selectedObjectID) {
                        ForEach(sceneState.objects) { obj in
                            Text(obj.variableName).tag(obj.id)
                        }
                    }
                    .labelsHidden()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Animation Type")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("", selection: $selectedAnimType) {
                        ForEach(ManimAnimation.types, id: \.self) { t in
                            Text(t).tag(t)
                        }
                    }
                    .labelsHidden()
                }
                
                Button("Add") {
                    if !selectedObjectID.isEmpty {
                        sceneState.addAnimation(toStepID: stepID, targetObjectID: selectedObjectID, animationType: selectedAnimType)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding()
        .frame(width: 220)
        .onAppear {
            if let first = sceneState.objects.first {
                selectedObjectID = first.id
            }
        }
    }
}
