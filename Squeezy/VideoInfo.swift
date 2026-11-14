// SPDX-FileCopyrightText: 2026 merkumac
// SPDX-License-Identifier: MIT

import Foundation

struct VideoInfo {
    let url: URL
    let duration: Double
    let width: Int
    let height: Int
    let frameRate: Double
    let codec: String

    let hasAudio: Bool
    let fileSize: Int64

    var durationText: String {
        let seconds = Int(duration)

        return String(
            format: "%02d:%02d:%02d",
            seconds / 3600,
            (seconds % 3600) / 60,
            seconds % 60
        )
    }

    var fileSizeText: String {
        ByteCountFormatter.string(
            fromByteCount: fileSize,
            countStyle: .file
        )
    }
}
