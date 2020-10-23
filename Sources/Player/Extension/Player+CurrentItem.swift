//
//  Player+CurrentItem.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/4.
//

import Foundation

public typealias TimeRange = (earliest: TimeInterval, latest: TimeInterval)

extension Player {

    /// 当前 `AVPlayerItem` 的播放进度
    public var currentItemProgression: TimeInterval? {
        player?.currentItem?.currentTime().timeIntervalValue
    }

    /// 当前 `AVPlayerItem` 的总时长
    public var currentItemDuration: TimeInterval? {
        player?.currentItem?.duration.timeIntervalValue
    }

    /// 当前 `AVPlayerItem`  可跳转播放的时间段
    public var currentItemSeekableRange: TimeRange? {
        let range = player?.currentItem?.seekableTimeRanges.last?.timeRangeValue
        if let start = range?.start.timeIntervalValue, let end = range?.end.timeIntervalValue {
            return (start, end)
        }
        if let currentItemProgression = currentItemProgression {
            // if there is no start and end point of seekable range
            // return the current time, so no seeking possible
            return (currentItemProgression, currentItemProgression)
        }
        // cannot seek at all
        return nil
    }

    /// 当前 `AVPlayerItem` 已经加载的时间段
    public var currentItemLoadedRange: TimeRange? {
        let range = player?.currentItem?.loadedTimeRanges.last?.timeRangeValue
        if let start = range?.start.timeIntervalValue, let end = range?.end.timeIntervalValue {
            return (start, end)
        }
        return nil
    }

    /// 当前 `AVPlayerItem` 提前加载的时间段
    public var currentItemLoadedAhead: TimeInterval? {
        if let loadedRange = currentItemLoadedRange,
           let currentTime = player?.currentTime(),
           loadedRange.earliest <= currentTime.seconds {
            return loadedRange.latest - currentTime.seconds
        }
        return nil
    }

}
