//
//  PlayMode.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/2.
//

import Foundation

/// Player repeat mode configuration
public struct PlayMode: OptionSet {

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// 在 `.normal` 模式下，会按照给定队列播放，播放到最后时会终止
    public static let normal: PlayMode = []

    /// 在 `.shuffle` 模式下，会随机播放队列中的资源
    public static let shuffle = PlayMode(rawValue: 1)

    /// 在 `.repeat` 模式下，会重复播放当前 item
    public static let `repeat` = PlayMode(rawValue: 1 << 1)

    /// 在 `.repeatAll` 模式下，会持续播放播放队列中的 item
    public static let repeatAll = PlayMode(rawValue: 1 << 2)

}
