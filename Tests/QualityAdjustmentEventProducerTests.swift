//
//  QualityAdjustmentEventProducerTests.swift
//  BayMediaTests
//
//  Created by shiwei on 2020/6/3.
//

@testable import SwiftyPlayer
import XCTest

// swiftlint:disable identifier_name
class QualityAdjustmentEventProducerTests: XCTestCase {

    var listener: FakeEventListener!
    var producer: QualityAdjustmentEventProducer!

    override func setUp() {
        super.setUp()
        listener = FakeEventListener()
        producer = QualityAdjustmentEventProducer()
        producer.eventListener = listener
        producer.startProducingEvents()
    }

    override func tearDown() {
        listener = nil
        producer.stopProducingEvents()
        producer = nil
        super.tearDown()
    }

    func testEventListenerGetsCalledWhenInterruptionCountHitsLimit() {
        let e = expectation(description: "Waiting for `onEvent` to get called.")
        listener.eventClosure = { event, producer in
            XCTAssertEqual(
                event as? QualityAdjustmentEventProducer.QualityAdjustmentEvent,
                QualityAdjustmentEventProducer.QualityAdjustmentEvent.goDown
            )
            e.fulfill()
        }

        producer.adjustQualityAfterInterruptionCount = 5
        producer.interruptionCount = producer.adjustQualityAfterInterruptionCount

        waitForExpectations(timeout: 1) { e in
            if let e = e {
                XCTFail(e.localizedDescription)
            }
        }
    }

    func testInterruptionCountIsResetAfterHittingLimit() {
        producer.adjustQualityAfterInterruptionCount = 5
        producer.interruptionCount = producer.adjustQualityAfterInterruptionCount
        XCTAssertEqual(producer.interruptionCount, 0)
    }

    func testEventListenerDoesNotGetCalledWhenInterruptionCountIsIncrementedToLessThanLimits() {
        listener.eventClosure = { event, producer in
            XCTFail("Test Faild " + #function)
        }

        producer.adjustQualityAfterInterruptionCount = 5
        producer.interruptionCount = 1
        producer.interruptionCount = 2
        producer.interruptionCount = 3
        producer.interruptionCount = 4
    }

    func testEventListenerGetsCalledWhenInterruptionShouldGoUp() {
        let e = expectation(description: "Waiting for `onEvent` to get called.")
        listener.eventClosure = { event, producer in
            XCTAssertEqual(
                event as? QualityAdjustmentEventProducer.QualityAdjustmentEvent,
                QualityAdjustmentEventProducer.QualityAdjustmentEvent.goUp
            )
            e.fulfill()
        }

        producer.adjustQualityTimeInterval = 1
        waitForExpectations(timeout: 1.5) { e in
            if let e = e {
                XCTFail(e.localizedDescription)
            }
        }
    }

    // swiftlint:disable line_length
    func testEventListenerGetsCalledImmediatelyWhenAdjustQualityTimeIntervalIsChangedToAValueThatShouldAlreadyHaveBeenFired() {
        let e = expectation(description: "Waiting for `onEvent` to get called.")
        listener.eventClosure = { event, producer in
            XCTAssertEqual(
                event as? QualityAdjustmentEventProducer.QualityAdjustmentEvent,
                QualityAdjustmentEventProducer.QualityAdjustmentEvent.goUp
            )
            e.fulfill()
        }

        producer.adjustQualityTimeInterval = 5
        DispatchQueue.main.asyncAfter(deadline: .now() + .microseconds(200)) {
            self.producer.adjustQualityTimeInterval = 1
        }

        waitForExpectations(timeout: 2.5) { e in
            if let e = e {
                XCTFail(e.localizedDescription)
            }
        }
    }

}
