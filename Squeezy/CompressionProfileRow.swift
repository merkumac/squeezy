//
//  CompressionProfileRow.swift
//  Squeezy
//
//  Created by kort on 25/10/2026.
//

import SwiftUI

struct CompressionProfileRow: View {
    let plan: CompressionPlan
    let isSelected: Bool
    let onSelect: () -> Void
    
    private var bitrateText: String {
        "Video: \(plan.videoBitrate / 1000) kb/s"
    }
    
    private var sizeText: String {
        ByteCountFormatter.string(fromByteCount: plan.estimatedBytes, countStyle: .file)
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(
                    systemName: isSelected ? "largecircle.fill.circle" : "circle"
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.preset.rawValue)
                        .font(.headline)
                    
                    Text(bitrateText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(sizeText)
                        .font(.headline)
                    
                    if !plan.isFeasible {
                        Label(
                            "Very low bitrate",
                            systemImage: "exclamation.triangle"
                        )
                        .font(.caption)
                        .foregroundStyle(.orange)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isSelected
                        ? Color.accentColor.opacity(0.12)
                        : Color.gray.opacity(0.08)
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(!plan.isFeasible)
    }
}
