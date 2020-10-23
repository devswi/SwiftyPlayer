//
//  Player+RetryEvent.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/4.
//

extension Player {

    /// 自动重试事件
    ///
    /// - Parameters:
    ///   - producer: 事件发生器
    ///   - event: 重试事件 `RetryEventProducer.RetryEvent`
    func handleRetryEvent(
        from producer: EventProducer,
        with event: RetryEventProducer.RetryEvent
    ) {
        switch event {
        case .retryAvailable:
            retryOrPlayNext()
        case .retryFailed:
            state = .failed(.maximumRetryCountHit)
            producer.stopProducingEvents()
        }
    }

}
