//
//  SeekEventProducer.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/2.
//

import Foundation

extension Selector {
    fileprivate static let timerTicked = #selector(SeekEventProducer.timerTicked(_:))
}

/// `SeekEvent` generate from `SeekEventProducer`
class SeekEventProducer: EventProducer {

    /// `SeekEvent` 
    ///
    /// - backward: The event describes a seek backward in time.
    /// - forward: The event describes a seek forward in time.
    enum SeekEvent: Event {
        case backward
        case forward
    }

    /// The listener that will be alerted a new event occured.
    weak var eventListener: EventListener?

    /// 当前事件发生器是否正在监听
    private var listening = false

    /// seek 事件是否回退
    var isBackward = false

    /// 距离上一次重试的等待延迟，默认为 10 秒
    var intervalBetweenEvents: TimeInterval = 10

    private var timer: Timer?

    /// stop listening
    deinit {
        stopProducingEvents()
    }

    func startProducingEvents() {
        guard !listening else {
            return
        }
        restartTimer()
        listening = true
    }

    func stopProducingEvents() {
        guard listening else {
            return
        }

        timer?.invalidate()
        timer = nil

        listening = false
    }

    private func restartTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            timeInterval: intervalBetweenEvents,
            target: self,
            selector: .timerTicked,
            userInfo: nil,
            repeats: false
        )
    }

    @objc
    fileprivate func timerTicked(_: AnyObject) {
        let event: SeekEvent = isBackward ? .backward : .forward
        eventListener?.onEvent(event, generateBy: self)
        restartTimer()
    }

}
