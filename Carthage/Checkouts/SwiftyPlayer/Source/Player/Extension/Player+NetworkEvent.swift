//
//  Player+NetworkEvent.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/4.
//

extension Player {

    /// 处理网络事件
    ///
    /// - Parameters:
    ///   - producer: 事件发生器
    ///   - event: 网络事件 `NetworkEventProducer.NetworkEvent`
    func handleNetworkEvent(from producer: EventProducer, with event: NetworkEventProducer.NetworkEvent) {
        switch event {
        case .connectionLost:
            guard let currentItem = currentItem, !state.isWaitingForConnection
            else {
                return
            }

            if !(currentItem.itemResources[currentQuality]?.resourceURL.isOfflineURL ?? false) {
                stateWhenConnectionLost = state

                if let currentItem = player?.currentItem, currentItem.isPlaybackBufferEmpty {
                    if case .playing = state {
                        qualityAdjustmentEventProducer.interruptionCount += 1
                    }

                    state = .waitingForConnection
                }
            }
        case .connectionRetrieved:
            guard let lossDate = networkEventProducer.connectionLossDate,
                  let stateWhenLost = stateWhenConnectionLost,
                  resumeAfterConnectionLoss
            else { return }

            let isAllowedToRestart = lossDate.timeIntervalSinceNow < maximumConnectionLossTime
            let wasPlayingBeforeLoss = !stateWhenLost.isStopped

            if isAllowedToRestart && wasPlayingBeforeLoss {
                retryOrPlayNext()
            }
            stateWhenConnectionLost = nil
        case .networkChanged:
            break
        }
    }

}
