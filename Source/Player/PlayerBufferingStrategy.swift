//
//  PlayerBufferingStrategy.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/3.
//

import Foundation

/// 播放器缓存策略
@objc
public enum PlayerBufferingStrategy: Int {

    /// 使用默认的 AVPlayer 缓存策略，在播放前会主动缓存
    case defaultBuffering = 0

    /// 为了快速开始播放，使用此策略。
    /// 播放前缓存时长可以通过 `preferredBufferDurationBeforePlayback` 变量来自定义
    case playWhenPreferredBufferDurationFull

    /// 当 `AVPlayerItem` 的缓存不为空就开始播放的简单策略
    case playWhenBufferNotEmpty

}
