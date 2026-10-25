//
//  ContentView.swift
//  Squeezy
//
//  Created by kort on 25/10/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var selectedVideo: URL?
    @State private var isTargeted = false
    @State private var showInvalidFileAlert = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "film.stack")
                .font(.system(size:48))
                .foregroundStyle(.secondary)

            if let video = selectedVideo {
                Text(video.lastPathComponent)
                    .font(.headline)

                Text("Ready to compress")
                    .foregroundStyle(.secondary)
            } else {
                Text("Drop a video here")
                    .font(.title2.bold())

                Text("MP4, MOV, or MKV")
                    .foregroundStyle(.secondary)
            }
        }
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

            _ = provider.loadObject(ofClass: URL.self) {
                url, _ in

                guard let url else {
                    return
                }

                let supportedExtenstions = ["mp4", "mov", "mkv"]
                let isSupported = supportedExtenstions.contains(
                    url.pathExtension.lowercased()
                )

                DispatchQueue.main.async {
                    if isSupported {
                        selectedVideo = url
                    } else {
                        showInvalidFileAlert = true
                    }
                }
            }

            return true
        }
        .alert("Seriously?", isPresented: $showInvalidFileAlert) {
            Button("My bad", role: .cancel) {}
        } message: {
            Text("That's not a video... Maybe try MKV, MOV, or MP4?")
        }
        .frame(minWidth: 520, minHeight: 340)
    }
}

#Preview {
    ContentView()
}
