// SPDX-FileCopyrightText: 2026 merkumac
// SPDX-License-Identifier: MIT
import Foundation

enum VideoProbeError: LocalizedError {
    case executableNotFound
    case probeFailed(String)
    case invalidVideo

    var errorDescription: String? {
        switch self {
        case .executableNotFound:
            "ffprobe was not found."
        case .probeFailed(let message):
            "ffprobe failed: \(message)"
        case .invalidVideo:
            "No valid video stream was found."
        }
    }
}

nonisolated struct VideoProbe {
    private struct ProbeResult: Decodable {
        let streams: [Stream]
        let format: Format
        
        struct Stream: Decodable {
            let codec_type: String?
            let codec_name: String?
            let width: Int?
            let height: Int?
            let avg_frame_rate: String?
        }
        
        struct Format: Decodable {
            let duration: String?
        }
    }
    
    func inspect(_ url: URL) async throws -> VideoInfo {
        try await Task.detached(priority: .userInitiated) {
            try await inspectVideo(url)
        }.value
    }
    
    private func inspectVideo(_ url: URL) async throws -> VideoInfo {
        guard let executable = Bundle.main.url(
            forResource: "ffprobe",
            withExtension: nil
        ) else {
            throw VideoProbeError.executableNotFound
        }
        
        let process = Process()
        process.executableURL = executable
        process.arguments = [
            "-v", "error",
            "-show_entries",
            "format=duration:stream=codec_type,codec_name,width,height,avg_frame_rate",
            "-of", "json",
            url.path(percentEncoded: false)
        ]
        
        let output = Pipe()
        let errors = Pipe()
        process.standardOutput = output
        process.standardError = errors
        
        try process.run()
        
        let errorTask = Task.detached {
            errors.fileHandleForReading.readDataToEndOfFile()
        }
        
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        
        let errorData = await errorTask.value
        
        guard process.terminationStatus == 0 else {
            let message = String(
                decoding: errorData,
                as: UTF8.self
            )
            throw VideoProbeError.probeFailed(message)
        }
        
        let result = try JSONDecoder().decode(ProbeResult.self, from: data)
        
        guard let video = result.streams.first(where: {
            $0.codec_type == "video"
        }),
        let width = video.width,
        let height = video.height,
        let durationString = result.format.duration,
        let duration = Double(durationString),
        duration.isFinite,
        duration > 0
        else {
            throw VideoProbeError.invalidVideo
        }
        
        let rate = video.avg_frame_rate ?? "0/1"
        let parts = rate.split(separator: "/")
        let numerator = Double(parts.first ?? "") ?? 0
        let denominator = parts.count == 2
            ? (Double(parts[1]) ?? 0)
            : 1
        
        let fps = denominator > 0 ? numerator / denominator : 0
        
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        
        let fileSize = (attributes[.size] as? NSNumber)?.int64Value ?? 0
        
        return VideoInfo(
            url: url,
            duration: duration,
            width: width,
            height: height,
            frameRate: fps,
            codec: video.codec_name ?? "unknown",
            hasAudio: result.streams.contains {
                $0.codec_type == "audio"
            },
            fileSize: fileSize
        )
    }
}
