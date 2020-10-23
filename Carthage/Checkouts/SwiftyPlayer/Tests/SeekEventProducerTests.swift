//
//  SeekEventProducerTests.swift
//  BayMedia
//
//  Created by shiwei on 2020/6/2.
//

@testable import SwiftyPlayer
import XCTest

// swiftline:disable force_unwrapping
class SeekEventProducerTests: XCTestCase {
    var listener: FakeEventListener!
    var producer: SeekEventProducer!

    override func setUp() {
        super.setUp()
        listener = FakeEventListener()
        producer = SeekEventProducer()
        producer.eventListener = listener
    }

    override func tearDown() {
        listener = nil
        producer.stopProducingEvents()
        producer = nil
        super.tearDown()
    }

    func testEventListenerGetsCalledAtRegularTimeIntervals() {
        var calls = [Date]()
        let interval = 1

        // swiftlint:disable identifier_name
        let r = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            calls.append(Date())

            if calls.count == 2 {
                let diff = Int(calls[1].timeIntervalSince1970 - calls[0].timeIntervalSince1970)
                XCTAssertEqual(diff, interval)

                r.fulfill()
            }
        }

        producer.intervalBetweenEvents = TimeInterval(interval)
        producer.startProducingEvents()
        // swiftlint:disable identifier_name
        waitForExpectations(timeout: 5) { e in
            if let e = e {
                XCTFail(e.localizedDescription)
            }
        }
    }

    func testEventsAreBackwardWhenAskedFor() {
        let r = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            XCTAssertEqual(event as? SeekEventProducer.SeekEvent, .backward)
            r.fulfill()
        }

        producer.intervalBetweenEvents = TimeInterval(1)
        producer.isBackward = true
        producer.startProducingEvents()

        // swiftlint:disable identifier_name
        waitForExpectations(timeout: 5) { e in
            if let e = e {
                XCTFail(e.localizedDescription)
            }
        }
    }

    // swiftlint:disable identifier_name
    func testEventsAreForwardWhenAskedFor() {
        let r = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            XCTAssertEqual(event as? SeekEventProducer.SeekEvent, .forward)
            r.fulfill()
        }

        producer.intervalBetweenEvents = TimeInterval(1)
        producer.isBackward = false
        producer.startProducingEvents()

        waitForExpectations(timeout: 5) { e in
            if let e = e {
                XCTFail(e.localizedDescription)
            }
        }
    }
}
