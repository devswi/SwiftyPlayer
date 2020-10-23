//
//  SubtitleTests.swift
//  BayMedia
//
//  Created by shiwei on 2020/6/1.
//

@testable import SwiftyPlayer
import XCTest

// swiftlint:disable force_unwrapping
class SubtitleTests: XCTestCase {

    struct SubtitleSample: SubtitleParsable {
        var subtitle: [AnyHashable: String] = [:]
        var timeRange: Range<TimeInterval>?
    }

    struct Subtitle: SubtitleParsable {
        var subtitle: [AnyHashable: String] = [:]
        var timeRange: Range<TimeInterval>?

        static func separate(subtitle: String) -> SubtitleDict {
            let components = subtitle.components(separatedBy: "\n")
            return SubtitleDict(uniqueKeysWithValues: components.enumerated().map { ( $0 == 0 ? "en" : "cn", $1 ) })
        }
    }

    func testParseSubtitleFromString() {
        let contents = """
        1
        00:00:12,080 --> 00:00:15,123
        This is the first subtitle

        2
        00:00:16,000 --> 00:00:18,000
        Another subtitle demonstrating tags:
        <b>bold</b>, <i>italic</i>, <u>underlined</u>
        <font color="#ff0000">red text</font>

        3
        00:00:20,000 --> 00:00:22,000
        Another subtitle demonstrating position.
        """

        let result: Result<Parser<SubtitleSample>, Error> = SubtitleParser.parse(contents: contents)
        switch result {
        case .success(let parsed):
            XCTAssertEqual(parsed.keys.count, 3)
            let first = parsed["1"]
            XCTAssertNotNil(first)
            let timeRange = first!.timeRange
            XCTAssertNotNil(timeRange)
            XCTAssertEqual(timeRange!.upperBound, 15.123)
            XCTAssertEqual(timeRange!.lowerBound, 12.08)
            let subtitle = first!.subtitle["en"]
            XCTAssertNotNil(subtitle)
            XCTAssertTrue(subtitle == "This is the first subtitle")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testParseSubtitleFromFile() {
        let path = Bundle(for: SubtitleTests.self).url(forResource: "sample", withExtension: "srt")
        XCTAssertNotNil(path)
        let result: Result<Parser<Subtitle>, Error> = SubtitleParser.parse(path: path!)
        switch result {
        case .success(let parsed):
            XCTAssertEqual(parsed.keys.count, 19)
            let thirteen = parsed["13"]
            XCTAssertNotNil(thirteen)
            let timeRange = thirteen!.timeRange
            XCTAssertNotNil(timeRange)
            XCTAssertEqual(timeRange!.upperBound, 54.900)
            XCTAssertEqual(timeRange!.lowerBound, 51.720)
            let en = thirteen!.subtitle["en"]
            XCTAssertNotNil(en)
            XCTAssertTrue(en == "Otherwise, we can send a gift card by mail if you prefer.")
            let cn = thirteen!.subtitle["cn"]
            XCTAssertNotNil(cn)
            XCTAssertTrue(cn == "另外，若您愿意，我们也可以寄一份购物卡。")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testParserRetrive() {
        let contents = """
        1
        00:00:12,080 --> 00:00:15,123
        This is the first subtitle

        2
        00:00:16,983 --> 00:00:18,350
        Another subtitle demonstrating tags:
        <b>bold</b>, <i>italic</i>, <u>underlined</u>
        <font color="#ff0000">red text</font>

        3
        00:00:20,000 --> 00:00:22,000
        Another subtitle demonstrating position.
        """

        let result: Result<Parser<SubtitleSample>, Error> = SubtitleParser.parse(contents: contents)
        if case .success(let parsed) = result {
            let subtitle = parsed.subtitle(contains: 17.0)
            XCTAssertNotNil(subtitle)
            let en = subtitle!.subtitle["en"]
            XCTAssertNotNil(en)
            XCTAssertTrue(en ==
                """
                Another subtitle demonstrating tags:
                <b>bold</b>, <i>italic</i>, <u>underlined</u>
                <font color="#ff0000">red text</font>
                """
            )
            let timeRange = subtitle!.timeRange
            XCTAssertNotNil(timeRange)
            XCTAssertEqual(timeRange!.upperBound, 18.350)
            XCTAssertEqual(timeRange!.lowerBound, 16.983)
        }
    }

}
