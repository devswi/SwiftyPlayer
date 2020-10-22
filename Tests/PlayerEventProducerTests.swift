//
//  PlayerEventProducerTests.swift
//  BayMediaTests
//
//  Created by shiwei on 2020/6/4.
//

import AVFoundation
@testable import SwiftyPlayer
import MediaPlayer
import XCTest

// swiftlint:disable identifier_name
class PlayerEventProducerTests: XCTestCase {

    var listener: FakeEventListener!
    var producer: PlayerEventProducer!
    var player: FakePlayer!
    var item: FakeItem!

    override func setUp() {
        super.setUp()
        listener = FakeEventListener()
        player = FakePlayer()
        item = FakeItem(url: URL(string: "https://www.shanbay.com")!)
        player.item = item
        producer = PlayerEventProducer()
        producer.player = player
        producer.eventListener = listener
        producer.startProducingEvents()
    }

    override func tearDown() {
        listener = nil
        player = nil
        item = nil
        producer.stopProducingEvents()
        producer = nil
        super.tearDown()
    }

    func testEventListenerGetsCalledWhenTimeObserverGetsCalled() {
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if case PlayerEventProducer.PlayerEvent.progressed = event {
                e.fulfill()
            }
        }

        waitForExpectations(timeout: 5) { e in
            self.producer.player = nil

            if let e = e {
                XCTFail(e.localizedDescription)
            }
        }
    }

    func testEventListenerGetsCalledWhenPlayerEndsPlaying() {
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if case PlayerEventProducer.PlayerEvent.endedPlaying = event {
                e.fulfill()
            }
        }

        NotificationCenter.default.post(name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)

        waitForExpectations(timeout: 1) { e in
            if let e = e {
                XCTFail(e.localizedDescription)
            }
        }
    }

    func testEventListenerGetsCalledWhenServiceReset() {
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if case PlayerEventProducer.PlayerEvent.sessionMessedUp = event {
                e.fulfill()
            }
        }

        NotificationCenter.default.post(
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: AVAudioSession.sharedInstance()
        )

        waitForExpectations(timeout: 1) { e in
            if let e = e {
                XCTFail(e.localizedDescription)
            }
        }
    }

    func testEventListenerGetsCalledWhenServiceGotLost() {
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if case PlayerEventProducer.PlayerEvent.sessionMessedUp = event {
                e.fulfill()
            }
        }

        NotificationCenter.default.post(
            name: AVAudioSession.mediaServicesWereLostNotification,
            object: AVAudioSession.sharedInstance()
        )

        waitForExpectations(timeout: 1) { e in
            if let e = e {
                XCTFail(e.localizedDescription)
            }
        }
    }

    func testEventListenerGetsCalledWhenRouteChanged() {
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if case PlayerEventProducer.PlayerEvent.routeChanged(let reason) = event {
                if reason == .unknown { e.fulfill() }
            }
        }

        NotificationCenter.default.post(
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )

        waitForExpectations(timeout: 1) { e in
            if let e = e {
                XCTFail(e.localizedDescription)
            }
        }
    }

    func testEventListenerGetsCalledWhenInterruptionBeginsAndWasSuspended() {
        if #available(iOS 10.3, *) {
            let expectationBegins = expectation(description: "Waiting for `onEvent` to get called")
            listener.eventClosure = { event, producer in
                if case PlayerEventProducer.PlayerEvent.interruptionBegan(let wasSuspended) = event, wasSuspended {
                    expectationBegins.fulfill()
                }
            }

            NotificationCenter.default.post(
                name: AVAudioSession.interruptionNotification,
                object: player,
                userInfo: [
                    AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue,
                    AVAudioSessionInterruptionWasSuspendedKey: true
                ]
            )

            waitForExpectations(timeout: 1) { e in
                if let e = e {
                    XCTFail(e.localizedDescription)
                }
            }
        }
    }

    func testEventListenerGetsCalledWhenInterruptionBeginsAndEnds() {
        let expectationBegins = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if case PlayerEventProducer.PlayerEvent.interruptionBegan = event {
                expectationBegins.fulfill()
            }
        }

        NotificationCenter.default.post(
            name: AVAudioSession.interruptionNotification,
            object: player,
            userInfo: [
                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue,
            ]
        )

        let expectationEnds = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if case PlayerEventProducer.PlayerEvent.interruptionEnded(let shouldResume) = event {
                if shouldResume {
                    expectationEnds.fulfill()
                }
            }
        }

        NotificationCenter.default.post(
            name: AVAudioSession.interruptionNotification,
            object: player,
            userInfo: [
                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
                AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume.rawValue,
            ]
        )

        waitForExpectations(timeout: 1) { e in
            if let e = e {
                XCTFail(e.localizedDescription)
            }
        }
    }

    func testEventListenerGetsCalledWhenItemDurationIsAvailable() {
        let originalDuration: TimeInterval = 10

        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if case PlayerEventProducer.PlayerEvent.loadedDuration(let duration) = event {
                if duration.timeIntervalValue == originalDuration {
                    e.fulfill()
                } else {
                    XCTFail("Loaded duration \(duration) not equal to original \(originalDuration)")
                }
            }
        }

        item.dur = CMTime(timeInterval: originalDuration)
        XCTAssertEqual(item.duration.timeIntervalValue, originalDuration)
        XCTAssertNil(CMTime(value: 0, timescale: 1, flags: [], epoch: 0).timeIntervalValue)

        waitForExpectations(timeout: 1) { e in
            if let e = e {
                XCTFail(e.localizedDescription)
            }
        }
    }

    func testEventListenerGetsCalledWhenItemBufferEmpty() {
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if case PlayerEventProducer.PlayerEvent.startedBuffering = event {
                e.fulfill()
            }
        }

        item.bufferEmpty = true

        waitForExpectations(timeout: 1) { e in
            if let e = e {
                XCTFail(e.localizedDescription)
            }
        }
    }

    func testEventListenerGetsCalledWhenItemBufferIsReadyToPlay() {
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if case PlayerEventProducer.PlayerEvent.readyToPlay = event {
                e.fulfill()
            }
        }

        item.likelyToKeepUp = true

        waitForExpectations(timeout: 1) { e in
            if let e = e {
                XCTFail(e.localizedDescription)
            }
        }
    }

    func testEventListenerDoesNotGetCalledWhenItemStatusChangesToAnyOtherThanError() {
        listener.eventClosure = { event, producer in
            guard case PlayerEventProducer.PlayerEvent.progressed = event else {
                XCTFail("wrong event")
                return
            }
        }

        item.stat = AVPlayerItem.Status.unknown
        item.stat = AVPlayerItem.Status.readyToPlay
    }

    func testEventListenerGetsCalledWhenItemStatusChangesToError() {
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if case PlayerEventProducer.PlayerEvent.endedPlaying = event {
                e.fulfill()
            }
        }

        item.stat = AVPlayerItem.Status.failed

        waitForExpectations(timeout: 1) { e in
            if let e = e {
                XCTFail(e.localizedDescription)
            }
        }
    }

    func testEventListenerGetsCalledWhenNewItemRangesAreAvailable() {
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if case PlayerEventProducer.PlayerEvent.loadedMoreRange = event {
                e.fulfill()
            }
        }

        item.timeRanges = [
            NSValue(timeRange: CMTimeRange(start: CMTime(), duration: CMTime(timeInterval: 10))),
        ]

        waitForExpectations(timeout: 1) { e in
            if let e = e {
                XCTFail(e.localizedDescription)
            }
        }
    }

    func testEventListenerDoesNotGetCalledWhenItemLikelyToKeepUpChangesToFalse() {
        listener.eventClosure = { event, producer in
            guard case PlayerEventProducer.PlayerEvent.progressed = event else {
                XCTFail("wrong event")
                return
            }
        }

        item.likelyToKeepUp = false
        item.likelyToKeepUp = false
    }

}
