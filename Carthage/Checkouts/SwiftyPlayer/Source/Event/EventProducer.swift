//
//  EventProducer.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/2.
//

import Foundation

/// `Event` 表明了可能发生的事件类型
public protocol Event { }

/// `EventListener` 监听了由 `EventProducer` 发生的事件
public protocol EventListener: AnyObject {
    /// 当事件发生时被调用
    ///
    /// - Parameters:
    ///   - event: 发生的事件类型
    ///   - eventProducer: 事件发生器
    func onEvent(_ event: Event, generateBy eventProducer: EventProducer)
}

/// `EventProducer` 处理发生的事件
public protocol EventProducer: AnyObject {
    /// 新事件发生时被通知的监听器
    var eventListener: EventListener? { get set }

    /// 开始监听事件的产生
    func startProducingEvents()

    /// 停止监听事件的产生
    func stopProducingEvents()
}
