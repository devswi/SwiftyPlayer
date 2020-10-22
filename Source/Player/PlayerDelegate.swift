//
//  PlayerDelegate.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/3.
//

import AVFoundation

public typealias Metadata = [AVMetadataItem]

/// 播放事件代理
public protocol PlayerDelegate: AnyObject {

    /// 播放器状态变更时的事件回调
    ///
    /// - Parameters:
    ///   - player: 当前播放器资源
    ///   - from: 之前的 state
    ///   - to: 新的 state
    func player(_ player: Player, didChangeStateFrom from: PlayerState, to state: PlayerState)

    /// 当一个新的 item 即将开始播放的事件回调
    ///
    /// - Parameters:
    ///   - player: 当前播放器资源
    ///   - item: 将要播放的 item
    func player(_ player: Player, willStartPlaying item: PlayableItem)

    /// 设置 AVAudioSession 时报错
    ///
    /// - Parameters:
    ///   - player: 当前播放器资源
    ///   - error: AudioSession 设置 category&mode&options 以及 active 时报错
    func player(_ player: Player, setAudioSessionErrorOccured error: Error?)

    /// 播放器播放进度变更时的回调
    ///
    /// - Parameters:
    ///   - player: 当前播放器资源
    ///   - time: 当前播放时间
    ///   - percentageRead: 当前播放进度，可用于 UISlider 更新
    func player(_ player: Player, didUpdateProgressionTo time: TimeInterval, percentageRead: Float)

    /// 获取到播放资源总时长的回调
    ///
    /// - Parameters:
    ///   - player: 当前播放器资源
    ///   - duration: 当前 item 的总时长
    ///   - item: 当前播放的 item
    func player(_ player: Player, didFindDuration duration: TimeInterval, for item: PlayableItem)

    /// 当 metadata 更新的时的回调
    ///
    /// - Parameters:
    ///   - player: 当前播放器资源
    ///   - item: 当前播放的 item
    ///   - data: metadata 信息
    func player(_ player: Player, didUpdateEmptyMetadataOn item: PlayableItem, withData data: Metadata)

    /// 播放资源加载回调，包括服务器资源和本地资源
    ///
    /// - Parameters:
    ///   - player: 当前播放器资源
    ///   - range: 播放器加载的资源时长
    ///   - item: 当前播放的 item
    func player(_ player: Player, didLoad range: TimeRange, for item: PlayableItem)

    /// 当前 item 播放完毕时回调，是否需要继续播放下一个
    ///
    /// - Parameters:
    ///   - player: 当前播放器资源
    ///   - item: 当前播放的 item
    func player(_ player: Player, didEndedPlaying item: PlayableItem)

}

extension PlayerDelegate {

    public func player(_ player: Player, didChangeStateFrom from: PlayerState, to state: PlayerState) { }

    public func player(_ player: Player, willStartPlaying item: PlayableItem) { }

    public func player(_ player: Player, setAudioSessionErrorOccured error: Error?) { }

    public func player(_ player: Player, didUpdateProgressionTo time: TimeInterval, percentageRead: Float) { }

    public func player(_ player: Player, didFindDuration duration: TimeInterval, for item: PlayableItem) { }

    public func player(_ player: Player, didUpdateEmptyMetadataOn item: PlayableItem, withData data: Metadata) { }

    public func player(_ player: Player, didLoad range: TimeRange, for item: PlayableItem) { }

    public func player(_ player: Player, didEndedPlaying item: PlayableItem) { }

}
