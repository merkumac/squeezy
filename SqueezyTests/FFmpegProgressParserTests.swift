//
//  FFmpegProgressParserTests.swift
//  Squeezy
//
//  Created by merkumac on 26/10/2026.
//

import Testing
@testable import Squeezy

struct FFmpegProgressParserTests {

    @Test func parsesProgressRecord() {
        var parser = FFmpegProgressParser(duration: 30)

        #expect(parser.consume("out_time_us=15000000") == nil)
        #expect(parser.consume("speed=2.5x") == nil)

        let progress = parser.consume("progress=continue")

        #expect(progress != nil)
        #expect(progress?.fraction == 0.5)
        #expect(progress?.processedSeconds == 15)
        #expect(progress?.speed == "2.5x")
    }


    @Test func clampsProgress() {
        var parser = FFmpegProgressParser(duration: 30)

        _ = parser.consume("out_time_us=35000000")

        let progress = parser.consume("progress=end")

        #expect(progress?.fraction == 1)
    }


    @Test func rejectsInvalidDuration() {
        var parser = FFmpegProgressParser(duration: 0)

        _ = parser.consume("out_time_us=15000000")

        #expect(parser.consume("progress=continue") == nil)
    }
}
