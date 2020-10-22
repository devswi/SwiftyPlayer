//
//  Player+SeekEvent.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/4.
//

import Foundation

extension Player {

    /// 处理 seek 事件
    ///
    /// - Parameters:
    ///   - producer: 事件发生器
    ///   - event: seek 事件
    func handleSeekEvent(from producer: EventProducer, with event: SeekEventProducer.SeekEvent) {
        guard let currentItemProgression = currentItemProgression,
              case .changeTime(_, let delta) = seekingBehavior
        else { return }

        switch event {
        case .backward:
            seek(to: currentItemProgression - delta)
        case .forward:
            seek(to: currentItemProgression + delta)
        }
    }

}
