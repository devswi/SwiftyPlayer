//
//  PlayableItemQueue.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/2.
//

import Foundation

/// `PlayableItemQueue` 处理播放队列
class PlayableItemQueue {
    /// 原始队列数据
    var items: [PlayableItem]

    /// 实际播放的播放队列
    var queue: [PlayableItem]

    /// 队列中的播放历史
    var historic: [PlayableItem]

    /// 队列中下一个 position
    var nextPosition = 0

    var currentPosition = 0

    var currentItem: PlayableItem? {
        guard currentPosition < queue.count else {
            return nil
        }
        return queue[currentPosition]
    }

    /// 播放循环模式
    var mode: PlayMode = .normal {
        didSet {
            adaptQueue(oldMode: oldValue)
        }
    }

    /// 初始化播放队列
    ///
    /// - Parameters:
    ///   - items: 待播放的 item 数组
    ///   - mode: 模仿模式，默认为 `.normal`
    init(items: [PlayableItem], mode: PlayMode = .normal) {
        self.items = items
        self.mode = mode
        queue = mode.contains(.shuffle) ? items.shuffled() : items
        historic = []
    }

}

extension PlayableItemQueue {

    var hasNextItem: Bool {
        if !queue.isEmpty &&
            (nextPosition < queue.count || mode.contains(.repeat) || mode.contains(.repeatAll)) {
            return true
        }
        return false
    }

    var hasPreviousItem: Bool {
        if !queue.isEmpty
            && (nextPosition > 0 || mode.contains(.repeat) || mode.contains(.repeatAll)) {
            return true
        }
        return false
    }

    /// 当前播放的 item 的后一个元素，播放队列的下一个，只用于当前播放结束，自动播放下一个的情况
    ///
    /// - Returns: 当前队列中后一个元素
    func nextItem() -> PlayableItem? {
        nextItem(isInteraction: false)
    }

    /// 播放器使用的 next item，严格依据播放队列返回下一个，只用于用户交互
    ///
    /// 严格依据 `PlayerMode` 返回循环模式的 next
    func nextItemInQueue() -> PlayableItem? {
        nextItem(isInteraction: true)
    }

    /// 当前播放的 item 的前一个元素，严格依据播放队列返回前一个，只用于用户交互
    ///
    /// 播放器没有自动上一个的操作!!! 这不符合交互逻辑
    ///
    /// - Returns: 当前队列中前一个播放 item
    func previousItemInQueue() -> PlayableItem? {
        guard !queue.isEmpty else {
            return nil
        }

        var previousPosition = currentPosition - 1

        if mode.contains(.repeatAll) && previousPosition < 0 {
            previousPosition = queue.count - 1
        }

        if previousPosition >= 0 {
            let item = queue[previousPosition]
            nextPosition = currentPosition
            currentPosition = previousPosition
            addHistoric(item: item)
            return item
        }
        return nil
    }

    func adaptQueue(oldMode: PlayMode) {
        // Early exit if queue is empty
        guard !queue.isEmpty else {
            return
        }

        if !oldMode.contains(.repeatAll) && mode.contains(.repeatAll) {
            nextPosition = nextPosition % queue.count
        }

        if oldMode.contains(.shuffle) && !mode.contains(.shuffle) {
            queue = items
            if let last = historic.last, let index = queue.firstIndex(of: last) {
                nextPosition = index + 1
            }
        } else if mode.contains(.shuffle) && !oldMode.contains(.shuffle) {
            let alreadyPlayed = queue.prefix(upTo: nextPosition)
            let leftovers = queue.suffix(from: nextPosition)
            queue = Array(alreadyPlayed).shuffled() + Array(leftovers).shuffled()
        }
    }

    func add(items: [PlayableItem]) {
        self.items.append(contentsOf: items)
        self.queue.append(contentsOf: items)
    }

    func remove(at index: Int) {
        let item = queue.remove(at: index)
        if let index = items.firstIndex(of: item) {
            items.remove(at: index)
        }
    }

    private func addHistoric(item: PlayableItem) {
        if let index = historic.firstIndex(of: item) {
            historic.append(historic.remove(at: index))
        } else {
            historic.append(item)
        }
    }

    private func nextItem(isInteraction: Bool) -> PlayableItem? {
        guard !queue.isEmpty else {
            return nil
        }

        if !isInteraction && mode.contains(.repeat) && currentPosition < queue.count {
            let item = queue[currentPosition]
            nextPosition = currentPosition + 1
            addHistoric(item: item)
            return item
        }

        if mode.contains(.repeatAll) && nextPosition >= queue.count {
            nextPosition = 0
        }

        if nextPosition < queue.count {
            let item = queue[nextPosition]
            currentPosition = nextPosition
            nextPosition = currentPosition + 1
            addHistoric(item: item)
            return item
        }
        return nil
    }

}

// MARK: - Array+Shuffle

extension Array {
    /// 将队列中元素随机排列后返回新的数组
    ///
    /// - Returns: 随机后的新数组
    func shuffled() -> [Element] {
        sorted { _, _ in
            // swiftlint:disable legacy_random
            arc4random() % 2 == 0
        }
    }
}
