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
                control: EncodingControl,
                onProgress: @escaping @Sendable (EncodingProgress) -> Void
    ) throws {
        guard let executable = Bundle.main.url(
            forResource: "ffmpeg",
            withExtension: nil
        ) else {
            throw VideoEncoderError.executableNotFound
        }
        
        let process = Process()
        process.executableURL = executable
        
        var videoFilters: [String] = []
        
        if plan.needsScaling {
            videoFilters = [
                "-vf",
                "scale=\(plan.outputWidth):\(plan.outputHeight)"
            ]
        }
        
        process.arguments = [
            "-hide_banner",
            "-nostdin",
            "-loglevel", "error",
            "-progress", "pipe:1",
            "-nostats",
            "-i", inputURL.path(percentEncoded: false),
            "-map", "0:v:0",
            "-map", "0:a:0?"
            ]
            + videoFilters
            + [
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
        
        let fileManager = FileManager.default
        let outputPath = outputURL.path(percentEncoded: false)
        
        guard !fileManager.fileExists(atPath: outputPath) else {
            throw VideoEncoderError.outputAlreadyExists
        }
        
        try control.run(process)
        
        defer { control.finish() }
        
        defer {
            if control.isCancelled {
                try? fileManager.removeItem(at: outputURL)
            }
        }
        
        let stderrQueue = DispatchQueue(label: "squeezy.ffmpeg.stderr")
        let stderrGroup = DispatchGroup()
        
        let errorOutput = ErrorOutput()
        
        
        stderrGroup.enter()
        stderrQueue.async {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            if !data.isEmpty {
                let message = String(decoding: data, as: UTF8.self)
                errorOutput.store(data)
            }
            
            stderrGroup.leave()
        }
        
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
        
        if control.isCancelled {
            throw CancellationError()
        }
        
        let message = String(decoding: errorOutput.read(), as: UTF8.self)
        
        guard process.terminationStatus == 0 else {
            throw VideoEncoderError.encodingFailed(
                process.terminationStatus,
                message
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
    case encodingFailed(Int32, String)
    case outputMissing
    case outputAlreadyExists
    case executableNotFound
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed(let status, let message):
            "FFmpeg failed with exit code \(status): \(message)."
            
        case .outputMissing:
            "FFmpeg finished but the output file is missing."
            
        case .outputAlreadyExists:
            "Output file already exists."
            
        case .executableNotFound:
            "Bundled FFmpeg executable was not found."
        }
    }
}


nonisolated final class ErrorOutput: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()
    
    func store(_ value: Data) {
        lock.lock()
        defer {lock.unlock() }
        data = value
    }
    
    func read() -> Data {
        lock.lock()
        defer { lock.unlock() }
        return data
    }
}
