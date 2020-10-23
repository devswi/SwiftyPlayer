//
//  PlayableItemTests.swift
//  BayMediaTests
//
//  Created by shiwei on 2020/6/3.
//

import AVFoundation
@testable import SwiftyPlayer
import XCTest

// swiftlint:disable force_unwrapping identifier_name
class PlayableItemTests: XCTestCase {

    func testItemInitializationFailsIfNoValueURLIsGiven() {
        XCTAssertNil(PlayableItem(itemResources: [:]))
    }

    func testItemURLForQuality() {
        let urlLow = URL(string: "https://git.17bdc.com")!
        let urlMedium = URL(string: "https://git.17bdc.com/ios")!
        let urlHigh = URL(string: "https://git.17bdc.com/ios/BayMedia")!

        let itemLowOnly = PlayableItem(itemResources: [.low: urlLow])
        XCTAssertEqual(itemLowOnly?[.low]?.resourceURL, urlLow)
        XCTAssertEqual(itemLowOnly?[.medium, default: urlLow].resourceURL, urlLow)
        XCTAssertEqual(itemLowOnly?[.high, default: urlLow].resourceURL, urlLow)

        let itemMediumOnly = PlayableItem(itemResources: [.medium: urlMedium])
        XCTAssertEqual(itemMediumOnly?[.medium]?.resourceURL, urlMedium)
        XCTAssertEqual(itemMediumOnly?[.low, default: urlMedium].resourceURL, urlMedium)
        XCTAssertEqual(itemMediumOnly?[.high, default: urlMedium].resourceURL, urlMedium)

        let itemLowMediumOnly = PlayableItem(itemResources: [.low: urlLow, .medium: urlMedium])
        XCTAssertEqual(itemLowMediumOnly?[.medium]?.resourceURL, urlMedium)
        XCTAssertEqual(itemLowMediumOnly?[.low]?.resourceURL, urlLow)
        XCTAssertEqual(itemLowMediumOnly?[.high, default: urlMedium].resourceURL, urlMedium)

        let itemFull = PlayableItem(itemResources: [.low: urlLow, .medium: urlMedium, .high: urlHigh])
        XCTAssertEqual(itemFull?[.low]?.resourceURL, urlLow)
        XCTAssertEqual(itemFull?[.medium]?.resourceURL, urlMedium)
        XCTAssertEqual(itemFull?[.high]?.resourceURL, urlHigh)
    }

    func testResourceFileName() {
        let urlLow = URL(string: "https://git.17bdc.com")!
        let urlHigh = URL(string: "https://git.17bdc.com/ios/BayMedia")!
        let urlCustom = MediaResource(
            resourceURL: URL(string: "https://git.17bdc.com/ios/BayMedia/custom")!
        )
        let urlCustomFileName = MediaResource(
            resourceURL: URL(string: "https://git.17bdc.com/ios/BayMedia/custom/file")!,
            fileName: "xxx_file_name"
        )

        let _480Quality = PlayableQuality(480)
        let _720Quality = PlayableQuality(720)
        let _1080Quality = PlayableQuality(1080)
        let _4KQuality = PlayableQuality(4000)

        let items = PlayableItem(
            itemResources:
            [
                _480Quality: urlLow,
                _720Quality: urlHigh,
                _1080Quality: urlCustom,
                _4KQuality: urlCustomFileName,
            ]
        )

        let _480P = items?[_480Quality]?.fileName
        XCTAssertEqual(_480P, "")

        let _720P = items?[_720Quality]?.fileName
        XCTAssertEqual(_720P, "BayMedia")

        let _1080P = items?[_1080Quality]?.fileName
        XCTAssertEqual(_1080P, "custom")

        let _4K = items?[_4KQuality]?.fileName
        XCTAssertEqual(_4K, "xxx_file_name")
    }

    func testParseMetadata() {
        let imageURL = Bundle(for: type(of: self)).url(forResource: "image", withExtension: "png")!
        let imageData = NSData(contentsOf: imageURL)!

        let metaData = [
            FakeMetadataItem(commonKey: .commonKeyTitle, value: "title" as NSString),
            FakeMetadataItem(commonKey: .commonKeyArtist, value: "artist" as NSString),
            FakeMetadataItem(commonKey: .commonKeyAlbumName, value: "album" as NSString),
            FakeMetadataItem(commonKey: .id3MetadataKeyTrackNumber, value: NSNumber(value: 1)),
            FakeMetadataItem(commonKey: .commonKeyArtwork, value: imageData),
        ]

        let item = PlayableItem(itemResources: [.low: URL(string: "https://git.17bdc.com/ios/BayMedia")!])
        item?.parseMetadata(metaData)

        XCTAssertEqual(item?.title, "title")
        XCTAssertEqual(item?.artist, "artist")
        XCTAssertEqual(item?.album, "album")
        XCTAssertEqual(item?.trackNumber?.intValue, 1)
        XCTAssertNotNil(item?.artworkImage)
    }

    func testParseMetadataDoesNotOverrideUserProperties() {
        let item = PlayableItem(itemResources: [.low: URL(string: "https://git.17bdc.com/ios/BayMedia")!])
        item?.title = "title"
        item?.artist = "artist"
        item?.album = "album"
        item?.trackNumber = NSNumber(value: 1)

        let metaData = [
            FakeMetadataItem(commonKey: .commonKeyTitle, value: "abc" as NSString),
            FakeMetadataItem(commonKey: .commonKeyArtist, value: "def" as NSString),
            FakeMetadataItem(commonKey: .commonKeyAlbumName, value: "ghi" as NSString),
            FakeMetadataItem(commonKey: .id3MetadataKeyTrackNumber, value: NSNumber(value: 10)),
        ]
        item?.parseMetadata(metaData)

        XCTAssertEqual(item?.title, "title")
        XCTAssertEqual(item?.artist, "artist")
        XCTAssertEqual(item?.album, "album")
        XCTAssertEqual(item?.trackNumber?.intValue, 1)
    }

}
