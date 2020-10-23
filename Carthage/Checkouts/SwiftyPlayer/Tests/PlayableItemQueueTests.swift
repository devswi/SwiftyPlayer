//
//  PlayableItemQueueTests.swift
//  BayMediaTests
//
//  Created by shiwei on 2020/6/3.
//

import AVFoundation
@testable import SwiftyPlayer
import XCTest

class PlayableItemQueueTests: XCTestCase {

    let item1 = PlayableItem(itemResources: [.high: URL(string: "https://git.17bdc.com/item")!])!
    let item2 = PlayableItem(itemResources: [.high: URL(string: "https://git.17bdc.com/ios")!])!
    let item3 = PlayableItem(itemResources: [.high: URL(string: "https://git.17bdc.com/ios/BayMedia")!])!

    func testEmptyQueueGivesNilAsPreviousOrNextItem() {
        let queue = PlayableItemQueue(items: [], mode: .normal)
        XCTAssert(queue.nextItem() == nil)
        XCTAssert(queue.nextItemInQueue() == nil)
        XCTAssert(queue.previousItemInQueue() == nil)
    }

    func testQueueInRepeatMode() {
        let queue = PlayableItemQueue(items: [item1, item2, item3], mode: .repeat)
        for _ in 0...100 {
            XCTAssert(queue.nextItem() === item1)
        }
        XCTAssert(queue.nextItemInQueue() === item2)
        for _ in 0...100 {
            XCTAssert(queue.nextItem() === item2)
        }
        XCTAssert(queue.nextItemInQueue() === item3)
        XCTAssertNil(queue.nextItemInQueue())
        for _ in 0...100 {
            XCTAssert(queue.nextItem() === item3)
        }
    }

    func testQueueInRepeatAllMode() {
        let queue = PlayableItemQueue(items: [item1, item2, item3], mode: .repeatAll)
        for _ in 0...100 {
            XCTAssert(queue.nextItem() === item1)
            XCTAssert(queue.nextItem() === item2)
            XCTAssert(queue.nextItem() === item3)
        }
    }

    func testQueueInNormalModeAfterSwitchingItFromRepeatMode() {
        let queue = PlayableItemQueue(items: [item1, item2, item3], mode: .repeat)
        XCTAssertNotNil(queue.nextItem())

        queue.mode = .normal
        XCTAssert(queue.nextItem() === item2)

        let queue2 = PlayableItemQueue(items: [item1], mode: .repeat)
        XCTAssertNotNil(queue2.nextItem())

        queue2.mode = .normal
        XCTAssert(queue2.nextItem() === nil)
    }

    func testQueueInShuffleModeAfterSwitchingItFromNormalMode() {
        let queue = PlayableItemQueue(items: [item1, item2, item3], mode: .normal)
        XCTAssert(queue.nextItem() === item1)

        queue.mode = .shuffle
        for _ in 0...100 {
            XCTAssert(queue.nextItem() !== item1)
        }
        queue.nextPosition = 0
        queue.mode = .normal
    }

    func testQueueInShuffleModeCombinedWithRepeatMode() {
        let queue = PlayableItemQueue(items: [item1, item2, item3], mode: [.repeat, .shuffle])
        let item = queue.nextItem()
        for _ in 0...100 {
            XCTAssert(queue.nextItem() === item)
        }
    }

    func testQueueInShuffleModeCombinedWithRepeatAllMode() {
        let queue = PlayableItemQueue(items: [item1, item2, item3], mode: [.repeatAll, .shuffle])
        let queued = queue.queue

        for _ in 0...100 {
            let q = [queue.nextItem()!, queue.nextItem()!, queue.nextItem()!]
            XCTAssertEqual(queued, q)
        }
    }

    func testAdaptModeWhenQueueIsEmpty() {
        let queue = PlayableItemQueue(items: [], mode: .normal)
        XCTAssertEqual(queue.nextItem(), nil)
        queue.mode = .shuffle
        XCTAssertEqual(queue.nextItem(), nil)
    }

    func testHasNextInQueue() {
        let queue = PlayableItemQueue(items: [item1, item2, item3], mode: .normal)
        XCTAssertTrue(queue.hasNextItem)
        XCTAssertNotNil(queue.nextItem())
        XCTAssertTrue(queue.hasNextItem)
        XCTAssertNotNil(queue.nextItem())
        XCTAssertTrue(queue.hasNextItem)
        XCTAssertNotNil(queue.nextItem())
        XCTAssertFalse(queue.hasNextItem)

        queue.mode = .repeat
        for _ in 0...100 {
            XCTAssertNotNil(queue.nextItem())
            XCTAssertTrue(queue.hasNextItem)
        }

        queue.mode = .repeatAll
        for _ in 0...100 {
            XCTAssertNotNil(queue.nextItem())
            XCTAssertTrue(queue.hasNextItem)
        }

        let queue2 = PlayableItemQueue(items: [], mode: .normal)
        XCTAssertFalse(queue2.hasNextItem)
        queue2.mode = .repeatAll
        XCTAssertFalse(queue2.hasNextItem)
        queue2.mode = .repeat
        XCTAssertFalse(queue2.hasNextItem)
    }

    func testPreviousInNormalMode() {
        let queue = PlayableItemQueue(items: [item1, item2, item3], mode: .normal)
        XCTAssertFalse(queue.hasPreviousItem)
        XCTAssertNil(queue.previousItemInQueue())
        XCTAssertNotNil(queue.nextItem())
        XCTAssertNotNil(queue.nextItem())
        XCTAssertTrue(queue.hasPreviousItem)
        XCTAssert(queue.previousItemInQueue() === item1)
    }

    func testPreviousInRepeatMode() {
        let queue = PlayableItemQueue(items: [item1, item2, item3], mode: .repeat)
        XCTAssertTrue(queue.hasPreviousItem)

        XCTAssertNil(queue.previousItemInQueue())

        queue.mode = .normal
        XCTAssertTrue(queue.nextItem() === item1)

        queue.mode = .repeat
        XCTAssertNil(queue.previousItemInQueue())
    }

    func testPreviousInRepeatAllMode() {
        let queue = PlayableItemQueue(items: [item1, item2, item3], mode: .repeatAll)
        for _ in 0...100 {
            XCTAssertTrue(queue.hasPreviousItem)
            XCTAssertTrue(queue.previousItemInQueue() === item3)
            XCTAssertTrue(queue.previousItemInQueue() === item2)
            XCTAssertTrue(queue.previousItemInQueue() === item1)
        }
    }

    func testAddItemInQueue() {
        let queue = PlayableItemQueue(items: [item1, item2], mode: .normal)
        queue.add(items: [item3])
        XCTAssertEqual(queue.queue, [item1, item2, item3])
    }

    func testRemoveItemInQueue() {
        let queue = PlayableItemQueue(items: [item1, item2, item3])
        queue.remove(at: 2)
        XCTAssertEqual(queue.queue, [item1, item2])
    }

    func testEmptyQueueHasNoPreviousNorNextItem() {
        let queue = PlayableItemQueue(items: [])
        XCTAssertFalse(queue.hasPreviousItem)
        XCTAssertFalse(queue.hasNextItem)
    }

    // MARK: - Historic
    func testQueueInNormalModeAndHistoric() {
        let queue = PlayableItemQueue(items: [item1, item2, item3], mode: .normal)
        XCTAssertEqual(queue.historic.count, 0)
        XCTAssert(queue.nextItem() === item1)

        XCTAssertEqual(queue.historic.count, 1)
        XCTAssert(queue.historic[0] === item1)

        XCTAssert(queue.nextItem() === item2)
        XCTAssert(queue.nextItem() === item3)
        XCTAssert(queue.nextItem() === nil)
        XCTAssert(queue.nextItem() === nil)

        XCTAssertEqual(queue.historic.count, 3)
        XCTAssert(queue.historic[1] === item2)
        XCTAssert(queue.historic[2] === item3)
    }

    func testQueueInRepeatAllModeAndHistoric() {
        let queue = PlayableItemQueue(items: [item1, item2, item3], mode: .repeatAll)
        XCTAssert(queue.nextItem() === item1)
        XCTAssert(queue.nextItem() === item2)
        XCTAssert(queue.nextItem() === item3)
        XCTAssert(queue.nextItem() === item1)

        XCTAssertEqual(queue.historic.count, 3)
        XCTAssert(queue.historic[0] === item2)
        XCTAssert(queue.historic[1] === item3)
        XCTAssert(queue.historic[2] === item1)
    }

    func testQueueInRepeatModeAndHistoric() {
        let queue = PlayableItemQueue(items: [item1, item2, item3], mode: .repeat)
        XCTAssert(queue.nextItemInQueue() === item1)
        for _ in 0...100 {
            XCTAssert(queue.nextItem() === item1)
        }

        XCTAssertEqual(queue.historic.count, 1)
        XCTAssert(queue.historic[0] === item1)
    }

}
