//
//  RetryEventProducerTests.swift
//  BayMediaTests
//
//  Created by shiwei on 2020/6/3.
//

@testable import SwiftyPlayer
import XCTest

class RetryEventProducerTests: XCTestCase {

    var listener: FakeEventListener!
    var producer: RetryEventProducer!

    override func setUp() {
        super.setUp()
        listener = FakeEventListener()
        producer = RetryEventProducer()
        producer.eventListener = listener
    }

    override func tearDown() {
        listener = nil
        producer.stopProducingEvents()
        producer = nil
        super.tearDown()
    }

    // swiftlint:disable identifier_name
    func testEventListenerGetsCalledUntilMaximumRetryCountHit() {
        var receivedRetry = 1
        let maximumRetryCount = 3

        let r = expectation(description: "Waiting for `onEvent` to get called.")
        listener.eventClosure = { event, producer in
            if let event = event as? RetryEventProducer.RetryEvent {
                if event == .retryAvailable {
                    receivedRetry += 1
                } else if event == .retryFailed && receivedRetry == maximumRetryCount {
                    r.fulfill()
                } else {
                    XCTFail("Undefined retry event")
                    r.fulfill()
                }
            }
        }

        producer.retryTimeout = 1
        producer.maximumRetryCount = maximumRetryCount
        producer.startProducingEvents()
        // swiftlint:disable identifier_name
        waitForExpectations(timeout: 5) { e in
            if let e = e {
                XCTFail(e.localizedDescription)
            }
        }
    }

}
