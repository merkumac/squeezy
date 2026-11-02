//
//  CompressionPlannerTests.swift
//  Squeezy
//
//  Created by kort on 25/10/2026.
//

import Testing
@testable import Squeezy

struct CompressionPlannerProfileTests {
    private let planner = CompressionPlanner()

    @Test
    func tinyDownscales4K() throws {
        let plans = planner.makePlans(
            duration: 3600,
            hasAudio: true,
            sourceBytes: 8_000_000_000,
            width: 3840,
            height: 2160,
            frameRate: 30
        )

        let tiny = try #require(
            plans.first { $0.preset == .tiny }
        )

        #expect(tiny.outputWidth == 1280)
        #expect(tiny.outputHeight == 720)
    }

    @Test
    func tinyDoesNotUpscale() throws {
        let plans = planner.makePlans(
            duration: 600,
            hasAudio: true,
            sourceBytes: 500_000_000,
            width: 640,
            height: 360,
            frameRate: 30
        )

        let tiny = try #require(
            plans.first { $0.preset == .tiny }
        )

        #expect(tiny.outputWidth == 640)
        #expect(tiny.outputHeight == 360)
    }

    @Test
    func qualityUsesHigherBitrateThanBalanced() throws {
        let plans = planner.makePlans(
            duration: 3600,
            hasAudio: true,
            sourceBytes: 3_000_000_000,
            width: 1920,
            height: 1080,
            frameRate: 30
        )

        let balanced = try #require(
            plans.first { $0.preset == .balanced }
        )
        let quality = try #require(
            plans.first { $0.preset == .quality }
        )

        #expect(quality.videoBitrate > balanced.videoBitrate)
        #expect(quality.outputWidth == 1920)
        #expect(quality.outputHeight == 1080)
    }

    @Test
    func portraitVideoKeepsOrientation() throws {
        let plans = planner.makePlans(
            duration: 600,
            hasAudio: true,
            sourceBytes: 2_000_000_000,
            width: 1080,
            height: 1920,
            frameRate: 30
        )

        let tiny = try #require(
            plans.first { $0.preset == .tiny }
        )

        #expect(tiny.outputWidth == 720)
        #expect(tiny.outputHeight == 1280)
    }
}

