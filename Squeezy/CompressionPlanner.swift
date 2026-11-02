//
//  CompressionPlanner.swift
//  Squeezy
//
//  Created by kort on 25/10/2026.
//

import Foundation

nonisolated enum CompressionPreset: String, CaseIterable, Identifiable {
    case tiny = "Tiny"
    case balanced = "Balanced"
    case quality = "Quality"
    
    var id: String { rawValue }
    
    var audioBitrate: Int {
        switch self {
        case .tiny: 64_000
        case .balanced: 80_000
        case .quality: 96_000
        }
    }
    
    var bitsPerPixelPerFrame: Double {
        switch self {
        case .tiny: 0.018
        case .balanced: 0.030
        case .quality: 0.050
        }
    }
}

nonisolated struct CompressionPlan: Identifiable {
    let preset: CompressionPreset
    let targetBytes: Int64
    let videoBitrate: Int
    let audioBitrate: Int
    let estimatedBytes: Int64
    let isFeasible: Bool
    let outputWidth: Int
    let outputHeight: Int
    
    var id: CompressionPreset { preset }
}

nonisolated struct CompressionPlanner {
    private let overheadFactor = 0.95
    private let minimumVideoBitrate = 150_000
    private let maximumSourceRatio = 0.90
    
    func makePlans(
        duration: Double,
        hasAudio: Bool,
        sourceBytes: Int64,
        width: Int,
        height: Int,
        frameRate: Double
    ) -> [CompressionPlan] {
        guard duration.isFinite, duration > 0, sourceBytes > 0,
              width > 0, height > 0, frameRate.isFinite, frameRate > 0 else {
            return []
        }
    
        return CompressionPreset.allCases.map { preset in
            let dimensions = outputDimensions(
                width: width,
                height: height,
                preset: preset
            )
            
            let pixelsPerSecond = Double(dimensions.width) * Double(dimensions.height) * frameRate
            
            let calculatedBitrate = pixelsPerSecond * preset.bitsPerPixelPerFrame
            
            let videoBitrate = Int(min(max(calculatedBitrate, 250_000), 12_000_000))
            
            let audioBitrate = hasAudio ? preset.audioBitrate : 0
            
            let estimatedBytes = Int64((Double(videoBitrate + audioBitrate) * duration / 8) * 1.03)
            
            return CompressionPlan(
                preset: preset,
                targetBytes: estimatedBytes,
                videoBitrate: videoBitrate,
                audioBitrate: audioBitrate,
                estimatedBytes: estimatedBytes,
                isFeasible: true,
                outputWidth: dimensions.width,
                outputHeight: dimensions.height
            )
        }
    }
    
    private func outputDimensions(
        width: Int, height: Int,
        preset: CompressionPreset
    ) -> (width: Int, height: Int) {
        guard preset == .tiny else {
            return (width, height)
        }
        
        let landscape = width >= height
        let maxWidth = landscape ? 1280 : 720
        let maxHeight = landscape ? 720 : 1280
        
        let scale = min(1.0,
            min(
                Double(maxWidth) / Double(width),
                Double(maxHeight) / Double(height)
            )
        )
        
        let outputWidth = max(2, Int(Double(width) * scale) / 2 * 2)
        let outputHeight = max(2, Int(Double(height) * scale) / 2 * 2)
        
        return (outputWidth, outputHeight)
    }
}
