//
//  ContentView.swift
//  Squeezy
//
//  Created by kort on 25/10/2026.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    
    // Mark: - State
    
    @State private var videoInfo: VideoInfo?
    @State private var isTargeted = false
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var selectedPreset: CompressionPreset = .balanced
    @State private var isCompressing = false
    @State private var encodingControl: EncodingControl?
    @State private var outputURL: URL?
    @State private var encodingProgress: EncodingProgress?
    
    private let probe = VideoProbe()

    // MARK: - View
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "film.stack")
                .font(.system(size:44))
                .foregroundStyle(.secondary)
            
            if isAnalyzing {
                ProgressView("Analyzing video...")
            } else if let info = videoInfo {
                Text(info.url.lastPathComponent)
                    .font(.headline)
                
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), alignment: .leading),
                        GridItem(.flexible(), alignment: .leading)
                    ],
                    alignment: .leading,
                    spacing: 12
                ) {
                    LabeledContent("Duration", value: info.durationText)
                    LabeledContent("Size", value: info.fileSizeText)
                    
                    LabeledContent("Resolution", value: "\(info.width) x \(info.height)")
                    LabeledContent("Frame rate", value: String(format: "%.2f FPS", info.frameRate))
                    
                    LabeledContent("Codec", value: info.codec)
                    LabeledContent("Audio", value: info.hasAudio ? "Yes" : "No")
                }
                .font(.callout)
                
                Divider()
                    .padding(.vertical, 8)
                
                Text("Choose compression")
                    .font(.headline)
                
                let plans = CompressionPlanner().makePlans(
                    duration: info.duration,
                    hasAudio: info.hasAudio,
                    sourceBytes: info.fileSize,
                    width: info.width,
                    height: info.height,
                    frameRate: info.frameRate
                )
                
                ForEach(plans) { plan in
                    CompressionProfileRow(
                        plan: plan,
                        isSelected: selectedPreset == plan.preset
                    ) {
                        selectedPreset = plan.preset
                    }
                }
                
                Button(isCompressing ? "Compressing..." : "Compress") {
                    guard let plan = plans.first(where: {
                        $0.preset == selectedPreset
                    }) else {
                        return
                    }
                    
                    Task {
                        await compressedVideo(info, plan: plan)
                    }
                }
                .disabled(isCompressing || isAnalyzing)
                
                if isCompressing, let encodingProgress {
                    VStack(alignment: .leading, spacing: 8) {
                        ProgressView(value: encodingProgress.fraction).progressViewStyle(.linear)
                        
                        HStack {
                            Text(
                                encodingProgress.fraction, format: .percent.precision(.fractionLength(0))
                            )
                            
                            Spacer()
                            
                            Text(encodingProgress.speed).foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            etaView(duration: info.duration, progress: encodingProgress)
                            
                            Spacer()
                            
                            Button("Cancel", role: .cancel) {
                                encodingControl?.cancel()
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 8)
                }
                
                if let outputURL {
                    Text("Saved: \(outputURL.lastPathComponent)")
                        .foregroundStyle(.green)
                }
            } else {
                Text("Drop a video here")
                    .font(.title2.bold())
                
                Text("MP4, MOV or MKV")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isTargeted ? .blue : .gray.opacity(0.4),
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
                .padding(20)
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else {
                return false
            }

            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                
                Task { @MainActor in
                    await handleFile(url)
                }
            }

            return true
        }
        .alert("Squeezy says no!", isPresented: $showError) {
            Button("My bad", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .frame(minWidth: 600)
        .focusedSceneValue(\.openVideo) {
            openVideo()
        }
    }
    
    //  MARK: - View Components
    
    @ViewBuilder
    private func etaView(duration: Double, progress: EncodingProgress) -> some View {
        let remaining = CompressionETA.remainingSeconds(
            duration: duration,
            processedSeconds: progress.processedSeconds,
            speed: progress.speed
        )
        
        Label(
            remaining.map { CompressionETA.formatted($0) }
                ?? "Estimating time remaining...",
            systemImage: "clock"
        )
        .font(.callout)
        .foregroundStyle(.secondary)
    }

    // MARK: - Actions
    
    @MainActor
    private func compressedVideo(
        _ info: VideoInfo,
        plan: CompressionPlan
    ) async {
        guard !isCompressing else { return }

        let input = info.url
        guard let output = chooseOutputURL(for: input) else {
            return
        }
        
        let temporaryOutput = output
            .deletingLastPathComponent()
            .appendingPathComponent(".squeezy-\(UUID().uuidString).mp4")
        
        encodingProgress = nil
        outputURL = nil
        isCompressing = true
        
        defer {
            isCompressing = false
            encodingControl = nil
        }
        
        let control = EncodingControl()
        encodingControl = control
    
        do {
            let encoder = VideoEncoder()
            
            try await Task.detached {
                try encoder.encode(
                    inputURL: input,
                    outputURL: temporaryOutput,
                    plan: plan,
                    duration: info.duration,
                    control: control
                ) {
                    progress in Task { @MainActor in
                        guard !control.isCancelled else { return }
                        self.encodingProgress = progress
                    }
                }
            }.value
            
            guard !control.isCancelled else {
                throw CancellationError()
            }
            
            guard !FileManager.default.fileExists(atPath: output.path(percentEncoded: false)
            ) else {
                throw CocoaError(.fileWriteFileExists)
            }
            
            try FileManager.default.moveItem(
                at: temporaryOutput,
                to: output
            )
            
            outputURL = output
            
        } catch is CancellationError {
            encodingProgress = nil
        } catch {
            presentError(error.localizedDescription)
        }
        
        try? FileManager.default.removeItem(at: temporaryOutput)
    }
    
    private func chooseOutputURL(for input: URL) -> URL? {
        let panel = NSSavePanel()
        
        panel.title = "Save compressed video"
        panel.nameFieldStringValue = input.deletingPathExtension().lastPathComponent + "-squeezy.mp4"
        panel.allowedContentTypes = [.mpeg4Movie]
        panel.canCreateDirectories = true
        
        guard panel.runModal() == .OK else {
            return nil
        }
        
        guard let url = panel.url else {
            return nil
        }
        
        guard url.standardizedFileURL != input.standardizedFileURL else {
            presentError("Cannot overwrite the original video.")
            return nil
        }
        
        return panel.url
    }
    
    private func openVideo() {
        let panel = NSOpenPanel()
        
        panel.allowedContentTypes = [
            .mpeg4Movie,
            .quickTimeMovie,
            UTType(filenameExtension: "mkv")!
        ]
        
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        guard panel.runModal() == .OK,
              let url = panel.url else { return }
        
        Task { await handleFile(url) }
    }
    
    private func handleFile(_ url: URL) async {
        guard !isAnalyzing else { return }
        
        print("URL:", url)
        print("PATH:", url.path)
        print("IS FILE URL:", url.isFileURL)

        let supported = ["mp4", "mov", "mkv"]

        guard supported.contains(url.pathExtension.lowercased()) else {
            presentError("That's not a video...")
            return
        }

        isAnalyzing = true
        videoInfo = nil
    
        let scoped = url.startAccessingSecurityScopedResource()
        defer {
            if scoped {
                url.stopAccessingSecurityScopedResource()
            }
            isAnalyzing = false
        }

        do {
            videoInfo = try await probe.inspect(url)
        } catch {
            presentError(error.localizedDescription)
        }
    }

    private func presentError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
