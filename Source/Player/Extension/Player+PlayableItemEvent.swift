//
//  Player+PlayableItemEvent.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/4.
//

extension Player {

    /// 当前播放 item 事件
    ///
    /// - Parameters:
    ///   - producer: 事件发生器
    ///   - event: 当前播放的 item 事件 `PlayableItemEventProducer.PlayableItemEvent`
    func handlePlayableItemEvent(
        from producer: EventProducer,
        with event: PlayableItemEventProducer.PlayableItemEvent
    ) {
        updateNowPlayingInfoCenter()
    }

}
