//
//  NetworkEventProducer.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/4.
//

import Foundation

extension Selector {
    fileprivate static let reachabilityStatusChanged = #selector(NetworkEventProducer.reachabilityStatusChanged(note:))
}

/// `NetworkEventProducer` 在网络状态发生变化时发出 `NetworkEvent`
class NetworkEventProducer: NSObject, EventProducer {

    /// `NetworkEvent` 是一个网络状态监听
    ///
    /// - networkChanged: 网络类型变更
    /// - connectionRetrieved: 网络连接成功
    /// - connectionLost: 网络连接丢失
    enum NetworkEvent: Event {
        case networkChanged
        case connectionRetrieved
        case connectionLost
    }

    let reachability: Reachability

    /// 连接丢失时间点
    private(set) var connectionLossDate: NSDate?

    weak var eventListener: EventListener?

    /// 当前事件发生器是否正在监听
    private var listening = false

    ///
    private var lastStatus: Reachability.NetworkStatus

    init(reachability: Reachability) {
        lastStatus = reachability.currentReachabilityStatus
        self.reachability = reachability

        if lastStatus == .none {
            connectionLossDate = NSDate()
        }
    }

    ///stop produce events
    deinit {
        stopProducingEvents()
    }

    func startProducingEvents() {
        guard !listening else {
            return
        }

        lastStatus = reachability.currentReachabilityStatus

        NotificationCenter.default.addObserver(
            self,
            selector: .reachabilityStatusChanged,
            name: .ReachabilityChanged,
            object: reachability
        )
        reachability.startNotifier()

        listening = true
    }

    func stopProducingEvents() {
        guard listening else {
            return
        }

        NotificationCenter.default.removeObserver(
            self,
            name: .ReachabilityChanged,
            object: reachability
        )
        reachability.stopNotifier()

        listening = false
    }

    @objc
    fileprivate func reachabilityStatusChanged(note: Notification) {
        let newStatus = reachability.currentReachabilityStatus
        if newStatus != lastStatus {
            if newStatus == .none {
                connectionLossDate = NSDate()
                eventListener?.onEvent(NetworkEvent.connectionLost, generateBy: self)
            } else if lastStatus == .none {
                eventListener?.onEvent(NetworkEvent.connectionRetrieved, generateBy: self)
                connectionLossDate = nil
            } else {
                eventListener?.onEvent(NetworkEvent.networkChanged, generateBy: self)
            }
            lastStatus = newStatus
        }
    }

}
