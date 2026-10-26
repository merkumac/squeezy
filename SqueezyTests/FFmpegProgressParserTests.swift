//
//  FFmpegProgressParserTests.swift
//  Squeezy
//
//  Created by kort on 26/10/2026.
//

import XCTest
@testable import Squeezy

final class FFmpegProgressParserTests: XCTestCase {
    func testParsesProgressRecord() {
        var parser = FFmpegProgressParser(duration: 30)

        XCTAssertNil(parser.consume("out_time_us=15000000"))
        XCTAssertNil(parser.consume("speed=2.5x"))

        let progress = parser.consume("progress=continue")

        XCTAssertNotNil(progress)
        XCTAssertEqual(progress?.fraction, 0.5)
        XCTAssertEqual(progress?.processedSeconds, 15)
        XCTAssertEqual(progress?.speed, "2.5x")
    }

    func testClampsProgress() {
        var parser = FFmpegProgressParser(duration: 30)

        _ = parser.consume("out_time_us=35000000")

        let progress = parser.consume("progress=end")

        XCTAssertEqual(progress?.fraction, 1)
    }

    func testRejectsInvalidDuration() {
        var parser = FFmpegProgressParser(duration: 0)

        _ = parser.consume("out_time_us=15000000")

        XCTAssertNil(parser.consume("progress=continue"))
    }
}
