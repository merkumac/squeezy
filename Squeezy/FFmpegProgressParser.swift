//
//  FFmpegProgressParser.swift
//  Squeezy
//
//  Created by kort on 26/10/2026.
//

import Foundation

nonisolated struct EncodingProgress: Sendable {
    let fraction: Double
    let processedSeconds: Double
    let speed: String
}

nonisolated struct FFmpegProgressParser {
    let duration: Double
    
    private var outTimeMicroseconds: Int64 = 0
    private var speed: String = "-"
    
    mutating func consume(_ line: String) -> EncodingProgress? {
        let parts = line.split(separator: "=", maxSplits: 1)
        
        guard parts.count == 2 else {
            return nil
        }
        
        let key = String(parts[0])
        let value = String(parts[1])
        
        switch key {
        case "out_time_us":
            if let parsed = Int64(value) {
                outTimeMicroseconds = parsed
            }
            
        case "speed":
            speed = value
            
        case "progress":
            guard duration.isFinite, duration > 0 else {
                return nil
            }
            
            let seconds = Double(outTimeMicroseconds) / 1_000_000
            let fraction = min(1, max(0, seconds / duration))
            
            return EncodingProgress(fraction: fraction, processedSeconds: seconds, speed: speed)
            
        default:
            break
        }
        
        return nil
    }
}
