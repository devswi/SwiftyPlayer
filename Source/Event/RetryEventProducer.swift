//
//  RetryEventProducer.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/3.
//

import UIKit

extension Selector {
    fileprivate static let timerTicked = #selector(RetryEventProducer.timerTicked(_:))
}

/// 自动重试事件 `RetryEventProducer`
class RetryEventProducer: NSObject, EventProducer {

    /// - retryAvailable: A retry available.
    /// - retryFailed: Retrying is no longer an option.
    enum RetryEvent: Event {
        case retryAvailable
        case retryFailed
    }

    private var timer: Timer?

    /// 当前事件发生器是否正在监听
    private var listening = false

    /// 中断后重试的计数器
    private var retryCount = 0

    /// 最大重试次数，默认 3
    var maximumRetryCount = 3

    /// 每次重试的事件间隔，默认 10 秒
    var retryTimeout: TimeInterval = 10

    weak var eventListener: EventListener?

    /// 析构时停止监听
    deinit {
        stopProducingEvents()
    }

    /// Starts listening to the player events.
    func startProducingEvents() {
        guard !listening else {
            return
        }

        retryCount = 0

        restartTimer()
        listening = true
    }

    func stopProducingEvents() {
        guard !listening else {
            return
        }

        timer?.invalidate()
        timer = nil

        listening = false
    }

    private func restartTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            timeInterval: retryTimeout,
            target: self,
            selector: .timerTicked,
            userInfo: nil,
            repeats: false
        )
    }

    @objc
    fileprivate func timerTicked(_: AnyObject) {
        retryCount += 1

        if retryCount < maximumRetryCount {
            eventListener?.onEvent(RetryEvent.retryAvailable, generateBy: self)

            restartTimer()
        } else {
            eventListener?.onEvent(RetryEvent.retryFailed, generateBy: self)
        }
    }

}
