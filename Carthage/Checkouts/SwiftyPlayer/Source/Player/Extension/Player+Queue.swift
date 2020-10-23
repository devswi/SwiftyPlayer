//
//  Player+Queue.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/4.
//

extension Player {

    /// 队列中的所有 item
    public var items: [PlayableItem]? {
        queue?.queue
    }

    /// 当前播放的 item 在队列中的下标
    public var currentItemIndexInQueue: Int? {
        currentItem.flatMap { queue?.items.firstIndex(of: $0) }
    }

    /// 队列中时候有一下个可播放对象
    public var hasNext: Bool {
        queue?.hasNextItem ?? false
    }

    public var hasPrevious: Bool {
        queue?.hasPreviousItem ?? false
    }

    /// 播放一个指定的 `PlayableItem`
    ///
    /// - Parameter item: 需要播放的 `PlayableItem`
    public func play(item: PlayableItem) {
        play(items: [item])
    }

    /// 依据当前的 `PlayMode`，创建播放队列
    ///
    /// - Parameters:
    ///   - items: 需要播放的 `PlayableItem` 数组
    ///   - index: 开始播放的下标，默认从第一个开始播放
    public func play(items: [PlayableItem], startAt index: Int = 0) {
        if !items.isEmpty && index < items.count {
            queue = PlayableItemQueue(items: items, mode: mode)
            if let realIndex = queue?.queue.firstIndex(of: items[index]) {
                queue?.nextPosition = realIndex
            }
            currentItem = queue?.nextItem()
        } else { // 播放队列为空时，终止播放器并清空队列
            stop()
            queue = nil
        }
    }

    /// 播放当前 queue 中，指定下边的 item
    ///
    /// - Parameter index: 指定播放的 item 下标
    public func play(at index: Int) {
        guard let queue = queue, index < queue.queue.count else { return }
        currentItem = queue.queue[index]
    }

    public func add(item: PlayableItem) {
        add(items: [item])
    }

    public func add(items: [PlayableItem]) {
        if let queue = queue {
            queue.add(items: items)
        } else {
            play(items: items)
        }
    }

    public func removeItem(at index: Int) {
        queue?.remove(at: index)
    }

}
