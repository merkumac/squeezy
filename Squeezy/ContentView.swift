//
//  ContentView.swift
//  Squeezy
//
//  Created by kort on 25/10/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var videoInfo: VideoInfo?
    @State private var isTargeted = false
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    private let probe = VideoProbe()

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "film.stack")
                .font(.system(size:44))
                .foregroundStyle(.secondary)
            
            if isAnalyzing {
                ProgressView("Analyzing video...")
            } else if let info = videoInfo {
                Text(info.url.lastPathComponent)
                    .font(.headline)
                
                LabeledContent("Duration", value: info.durationText)
                LabeledContent("Size", value: info.fileSizeText)
                LabeledContent("Resolution", value: "\(info.width) x \(info.height)")
                LabeledContent("Frame rate", value: String(format: "%.2f FPS", info.frameRate))
                LabeledContent("Codec", value: info.codec)
                LabeledContent("Audio", value: info.hasAudio ? "Yes" : "No")
            } else {
                Text("Drop a video here")
                    .font(.title2.bold())
                
                Text("MP4, MOV or MKV")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .frame(minWidth: 520, minHeight: 340)
    }

    @MainActor
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
