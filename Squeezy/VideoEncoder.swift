//
//  VideoEncoder.swift
//  Squeezy
//
//  Created by kort on 25/10/2026.
//

import Foundation

nonisolated struct VideoEncoder {
    func encode(inputURL: URL,
                outputURL: URL,
                plan: CompressionPlan,
                duration: Double,
                onProgress: @escaping @Sendable (EncodingProgress) -> Void
    ) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/ffmpeg")
        
        process.arguments = [
            "-hide_banner",
            "-nostdin",
            "-loglevel", "error",
            "-progress", "pipe:1",
            "-nostats",
            "-i", inputURL.path(percentEncoded: false),
            "-map", "0:v:0",
            "-map", "0:a?",
            "-c:v", "hevc_videotoolbox",
            "-b:v", String(plan.videoBitrate),
            "-tag:v", "hvc1",
            "-c:a", "aac",
            "-b:a", String(plan.audioBitrate),
            "-movflags", "+faststart",
            "-n",
            outputURL.path(percentEncoded: false)
        ]
        
        let errorPipe = Pipe()
        process.standardError = errorPipe
        
        let progressPipe = Pipe()
        process.standardOutput = progressPipe
        
        let stderrQueue = DispatchQueue(label: "squeezy.ffmpeg.stderr")
        let stderrGroup = DispatchGroup()
        
        stderrGroup.enter()
        stderrQueue.async {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            if !data.isEmpty {
                let message = String(decoding: data, as: UTF8.self)
                print("FFmpeg:", message)
            }
            
            stderrGroup.leave()
        }
        
        try process.run()
        
        var parser = FFmpegProgressParser(duration: duration)
        var buffer = Data()
        
        while true {
            let chunk = progressPipe.fileHandleForReading.availableData
            
            if chunk.isEmpty {
                break
            }
            
            buffer.append(chunk)
            
            while let newline = buffer.firstIndex(of: 10) {
                let line = String(decoding: buffer.prefix(upTo: newline), as: UTF8.self)
                buffer.removeSubrange(...newline)
                
                if let progress = parser.consume(line) {
                    onProgress(progress)
                }
            }
        }
        
        process.waitUntilExit()
        stderrGroup.wait()
        
        guard process.terminationStatus == 0 else {
            throw VideoEncoderError.encodingFailed(
                process.terminationStatus
            )
        }
        
        guard FileManager.default.fileExists(
            atPath: outputURL.path(percentEncoded: false)
        ) else {
            throw VideoEncoderError.outputMissing
        }
    }
}

nonisolated enum VideoEncoderError: LocalizedError {
    case encodingFailed(Int32)
    case outputMissing
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed(let status):
            "FFmpeg failed with exit code \(status)."
            
        case .outputMissing:
            "FFmpeg finished but the output file is missing."
        }
    }
}
