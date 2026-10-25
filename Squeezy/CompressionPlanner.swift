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
    
    var targetMegabytes: Int {
        switch self {
        case .tiny: 200
        case .balanced: 400
        case .quality: 800
        }
    }
    
    var audioBitrate: Int {
        switch self {
        case .tiny, .balanced: 64_000
        case .quality: 96_000
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
    
    var id: CompressionPreset { preset }
}

nonisolated struct CompressionPlanner {
    private let overheadFactor = 0.95
    private let minimumVideoBitrate = 150_000
    private let maximumSourceRatio = 0.90
    
    func makePlans(
        duration: Double,
        hasAudio: Bool,
        sourceBytes: Int64
    ) -> [CompressionPlan] {
        guard duration.isFinite, duration > 0, sourceBytes > 0 else {
            return []
        }
    
        return CompressionPreset.allCases.map { preset in
            let presetLimit = Int64(preset.targetMegabytes) * 1_000_000
            let sourceLimit = Int64(Double(sourceBytes) * maximumSourceRatio)
            let target = min(presetLimit, sourceLimit)
            
            let audio = hasAudio ? preset.audioBitrate : 0
            
            let availableBits = Double(target) * 8 * overheadFactor
            let videoBitrate = max(0, Int(availableBits / duration) - audio)
            
            let estimatedBytes = Int64(Double(videoBitrate + audio) * duration / 8)
            
            return CompressionPlan(
                preset: preset,
                targetBytes: target,
                videoBitrate: videoBitrate,
                audioBitrate: audio,
                estimatedBytes: estimatedBytes,
                isFeasible: videoBitrate >= minimumVideoBitrate
            )
        }
    }
}
