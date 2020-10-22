//
//  QualityAdjustmentEventProducer.swift
//  SwiftyPlayerTests
//
//  Created by shiwei on 2020/6/3.
//

import Foundation

extension Selector {
    fileprivate static let timerTicked = #selector(QualityAdjustmentEventProducer.timerTicked(_:))
}

/// `QualityAdjustmentEvent` 代表了当某些中断发生时需要变更资源质量的事件
/// `QualityAdjustmentEventProducer` 用于处理这些事件
class QualityAdjustmentEventProducer: NSObject, EventProducer {

    /// `QualityAdjustmentEvent`
    ///
    /// - goDown: 降低质量
    /// - goUp: 提升质量
    enum QualityAdjustmentEvent: Event {
        case goDown
        case goUp
    }

    private var timer: Timer?

    /// 当前事件发生器是否正在监听
    private var listening = false

    weak var eventListener: EventListener?

    /// 中断次数计数器，决定是否需要降低资源质量的标识
    var interruptionCount = 0 {
        didSet {
            checkInterruptionCount()
        }
    }

    /// 检测中断等待的事件间隔，默认 10 分钟
    var adjustQualityTimeInterval: TimeInterval = 10 * 60 {
        didSet {
            if let timer = timer, listening {
                let delta = adjustQualityTimeInterval - oldValue
                let newFireDate = timer.fireDate.addingTimeInterval(delta)
                let timeInterval = newFireDate.timeIntervalSinceNow

                timer.invalidate()

                if timeInterval < 1 {
                    timerTicked(timer)
                } else {
                    self.timer = Timer.scheduledTimer(
                        timeInterval: timeInterval,
                        target: self,
                        selector: .timerTicked,
                        userInfo: nil,
                        repeats: false
                    )
                }
            }
        }
    }

    /// 最大允许的中断次数，默认 5 次
    var adjustQualityAfterInterruptionCount = 5 {
        didSet {
            checkInterruptionCount()
        }
    }

    /// 析构时停止监听
    deinit {
        stopProducingEvents()
    }

    /// Starts listening to the player events.
    func startProducingEvents() {
        guard !listening else {
            return
        }

        resetState()
        listening = true
    }

    /// Stop listening to the player events.
    func stopProducingEvents() {
        guard listening else {
            return
        }

        timer?.invalidate()
        timer = nil
        listening = false
    }

    private func resetState() {
        interruptionCount = 0

        timer?.invalidate()
        timer = Timer.scheduledTimer(
            timeInterval: adjustQualityTimeInterval,
            target: self,
            selector: .timerTicked,
            userInfo: nil,
            repeats: false
        )
    }

    private func checkInterruptionCount() {
        if interruptionCount >= adjustQualityAfterInterruptionCount && listening {
            // Now, need to stop the timer.
            timer?.invalidate()

            // Calls the listener
            eventListener?.onEvent(QualityAdjustmentEvent.goDown, generateBy: self)

            resetState()
        }
    }

    @objc
    fileprivate func timerTicked(_: AnyObject) {
        if interruptionCount == 0 {
            eventListener?.onEvent(QualityAdjustmentEvent.goUp, generateBy: self)

            resetState()
        }
    }

}
