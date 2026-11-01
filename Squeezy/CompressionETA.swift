//
//  CompressionETA.swift
//  Squeezy
//
//  Created by kort on 02/11/2026.
//

import Foundation

nonisolated struct CompressionETA {
    static func remainingSeconds(
        duration: Double,
        processedSeconds: Double,
        speed: String
    ) -> Double? {
        let value = speed
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "x", with: "")
        
        guard let multiplier = Double(value),
              multiplier.isFinite,
              multiplier > 0,
              duration.isFinite,
              processedSeconds.isFinite,
              duration > 0 else {
            return nil
        }
        
        let remaining = max(0, duration - processedSeconds)
        return remaining / multiplier
    }
    
    static func formatted(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else {
            return "Estimating..."
        }
        
        if seconds < 60 {
            return "Less than a minute remaining"
        }
        
        let minutes = Int(ceil(seconds / 60))
        
        if minutes < 60 {
            return "About \(minutes) min remaining"
        }
        
        let hours = minutes / 60
        let remainder = minutes % 60
        
        if remainder == 0 {
            return "About \(hours) hr remaining"
        }
        
        return "About \(hours) hr \(remainder) min remaining"
    }
}
