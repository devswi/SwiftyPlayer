//
//  ApplicationStatusProducer.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/9/28.
//

import UIKit

extension Selector {
    fileprivate static let willEnterForeground = #selector(ApplicationStatusProducer.willEnterForeground(_:))
    fileprivate static let didBecomeActive = #selector(ApplicationStatusProducer.didBecomeActive(_:))
    fileprivate static let willResignActive = #selector(ApplicationStatusProducer.willResignActive(_:))
    fileprivate static let didEnterBackground = #selector(ApplicationStatusProducer.didEnterBackground(_:))
}

class ApplicationStatusProducer: NSObject, EventProducer {

    enum ApplicationStatusEvent: Event {
        case willEnterForeground
        case didBecomeActive
        case willResignActive
        case didEnterBackground
    }

    /// 当前事件发生器是否正在监听
    private var listening = false

    weak var eventListener: EventListener?

    func startProducingEvents() {
        guard !listening else { return }

        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: .willEnterForeground,
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: .didBecomeActive,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: .didEnterBackground,
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: .willResignActive,
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        listening = true
    }

    func stopProducingEvents() {
        guard listening else { return }

        let center = NotificationCenter.default
        center.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        center.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        center.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        center.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)

        listening = false
    }

    @objc
    fileprivate func willEnterForeground(_ note: Notification) {
        eventListener?.onEvent(ApplicationStatusEvent.willEnterForeground, generateBy: self)
    }

    @objc
    fileprivate func didBecomeActive(_ note: Notification) {
        eventListener?.onEvent(ApplicationStatusEvent.didBecomeActive, generateBy: self)
    }

    @objc
    fileprivate func willResignActive(_ note: Notification) {
        eventListener?.onEvent(ApplicationStatusEvent.willResignActive, generateBy: self)
    }

    @objc
    fileprivate func didEnterBackground(_ note: Notification) {
        eventListener?.onEvent(ApplicationStatusEvent.didEnterBackground, generateBy: self)
    }

}
