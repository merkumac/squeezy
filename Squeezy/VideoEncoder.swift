//
//  VideoEncoder.swift
//  Squeezy
//
//  Created by kort on 25/10/2026.
//

import Foundation

nonisolated struct VideoEncoder {
    func encode(inputURL: URL, outputURL: URL, plan: CompressionPlan) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/ffmpeg")
        
        process.arguments = [
            "-hide_banner",
            "-nostdin",
            "-loglevel", "error",
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
        
        try process.run()
        process.waitUntilExit()
        
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let errorText = String(decoding: errorData, as: UTF8.self)
        
        print("FFmpeg stderr:", errorText)
        print("FFmpeg exit code:", process.terminationStatus)
        
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
