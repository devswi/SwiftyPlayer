//
//  VideoPlayer+ApplicationStatusEvent.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/9/28.
//

import Foundation

extension VideoPlayer {

    /// 处理应用处于前后台状态事件
    ///
    /// - Parameters:
    ///   - producer: 事件发生器
    ///   - event: 应用前后台状态事件 `ApplicationStatusProducer.ApplicationStatusEvent`
    func handleApplicationStatusEvent(
        from producer: EventProducer,
        with event: ApplicationStatusProducer.ApplicationStatusEvent
    ) {
        switch event {
        case .willEnterForeground,
             .didBecomeActive:
            if isBackgroundPlaybackSupported {
                videoPlayerView?.avPlayer = player
            } else {
                if let state = stateBeforeEnterBackground {
                    let isPlaying = state.isPlaying
                    if isPlaying {
                        resume()
                    }
                    stateBeforeEnterBackground = nil
                }
            }
        case .willResignActive:
            if isBackgroundPlaybackSupported {
                videoPlayerView?.avPlayer = nil
            } else {
                stateBeforeEnterBackground = state
                if state.isPlaying || state.isBuffering {
                    pause()
                }
            }
        case .didEnterBackground where isBackgroundPlaybackSupported && videoPlayerView?.avPlayer != nil:
            videoPlayerView?.avPlayer = nil
        default:
            break
        }
    }

}
