//
//  Player+Control.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/4.
//

import AVFoundation
import CoreMedia
import UIKit

extension Player {

    /// 播放继续
    public func resume() {
        // Ensure pause flag is no longer set
        pausedForInterruption = false

        player?.rate = rate

        // 当前状态为 `.buffering` 时，不能切换状态到 `.playing`
        if !state.isPlaying && !state.isBuffering {
            state = .playing
        }

        retryEventProducer.startProducingEvents()
    }

    /// 暂停播放
    public func pause() {
        player?.rate = 0
        state = .paused

        retryEventProducer.stopProducingEvents()
    }

    /// 立即开始播放当前 `AVPlayerItem`
    public func playImmediately() {
        state = .playing
        player?.playImmediately(atRate: rate)

        retryEventProducer.stopProducingEvents()
    }

    /// 播放队列中的前一个，首次点击先重复播放当前 item，再次确定才跳转上一首
    public func previous() {
        if let previousItem = queue?.previousItemInQueue() {
            currentItem = previousItem
        } else {
            seek(to: 0)
        }
    }

    /// 播放队列中的下一个
    public func next() {
        currentItem = queue?.nextItemInQueue()
    }

    /// 播放队列中的下一个，如果队列中没有下一个了则终止播放器
    public func nextOrStop() {
        if let nextItem = queue?.nextItem() {
            currentItem = nextItem
        } else {
            stop()
        }
    }

    /// 停止播放器并清空播放队列
    @objc
    public func stop() {
        retryEventProducer.stopProducingEvents()

        if player != nil {
            player?.pause()
            player?.replaceCurrentItem(with: nil)
            player = nil
        }
        if currentItem != nil {
            currentItem = nil
        }
        if queue != nil {
            queue = nil
        }
        state = .stopped
        if !AVAudioSession.sharedInstance().isOtherAudioPlaying {
            do {
                try audioSession.setActive(false)
            } catch {
                delegate?.player(self, setAudioSessionErrorOccured: error)
            }
        }
    }

    /// 跳转播放
    ///
    /// - Parameters:
    ///   - time: 需要跳转播放的时间点
    ///   - byAdaptingTimeToFitSeekableRanges: 在需要跳转到未缓存区域时，自适应回到到可跳转区域，默认值为 false
    ///   - toleranceBefore: 允许的误差范围 -
    ///   - toleranceAfter: 允许的误差范围 +
    ///   - completionHandler: 跳转播放完成回调
    public func seek(
        to time: TimeInterval,
        byAdaptingTimeToFitSeekableRanges: Bool = false,
        toleranceBefore: CMTime = CMTime.positiveInfinity,
        toleranceAfter: CMTime = CMTime.positiveInfinity,
        completionHandler: ((Bool) -> Void)? = nil
    ) {
        guard let earliest = currentItemSeekableRange?.earliest,
              let latest = currentItemSeekableRange?.latest
        else {
            seekSafely(
                to: time,
                toleranceBefore: toleranceBefore,
                toleranceAfter: toleranceAfter,
                completionHandler: completionHandler
            )
            return
        }

        if !byAdaptingTimeToFitSeekableRanges || (time >= earliest && time <= latest) {
            seekSafely(
                to: time,
                toleranceBefore: toleranceBefore,
                toleranceAfter: toleranceBefore,
                completionHandler: completionHandler
            )
        } else if time < earliest {
            seekToSeekableRangeStart(padding: 1, completionHandler: completionHandler)
        } else if time > latest {
            seekToSeekableRangeEnd(padding: 1, completionHandler: completionHandler)
        }
    }

    /// Moves the playback cursor within a specified time bound.
    ///
    /// Seek to request sample accurate seeking which may incur additional decoding delay.
    ///
    /// - Parameters:
    ///   - time
    ///   - byAdaptingTimeToFitSeekableRanges
    ///   - completionHandler
    public func seekAccurately(
        to time: TimeInterval,
        byAdaptingTimeToFitSeekableRanges: Bool = false,
        completionHandler: ((Bool) -> Void)? = nil
    ) {
        seek(
            to: time,
            byAdaptingTimeToFitSeekableRanges: byAdaptingTimeToFitSeekableRanges,
            toleranceBefore: .zero,
            toleranceAfter: .zero,
            completionHandler: completionHandler
        )
    }

    /// 尽可能回退跳转播放
    ///
    /// - Parameters:
    ///   - padding: 时间间隔
    ///   - completionHandler: 跳转播放完成回调
    public func seekToSeekableRangeStart(padding: TimeInterval, completionHandler: ((Bool) -> Void)? = nil) {
        guard let range = currentItemSeekableRange
        else {
            completionHandler?(false)
            return
        }
        let position = min(range.latest, range.earliest + padding)
        seekSafely(to: position, completionHandler: completionHandler)
    }

    /// 尽可能向前跳转播放
    ///
    /// - Parameters:
    ///   - padding: 时间间隔
    ///   - completionHandler: 跳转播放完成回调
    public func seekToSeekableRangeEnd(padding: TimeInterval, completionHandler: ((Bool) -> Void)? = nil) {
        guard let range = currentItemSeekableRange
        else {
            completionHandler?(false)
            return
        }
        let position = max(range.earliest, range.latest - padding)
        seekSafely(to: position, completionHandler: completionHandler)
    }

}

extension Player {

    fileprivate func seekSafely(
        to time: TimeInterval,
        toleranceBefore: CMTime = CMTime.positiveInfinity,
        toleranceAfter: CMTime = CMTime.positiveInfinity,
        completionHandler: ((Bool) -> Void)?
    ) {
        guard let completionHandler = completionHandler
        else {
            player?.seek(
                to: CMTime(timeInterval: time),
                toleranceBefore: toleranceBefore,
                toleranceAfter: toleranceAfter
            )
            updateNowPlayingInfoCenter()
            return
        }
        guard player?.currentItem?.status == .readyToPlay
        else {
            completionHandler(false)
            return
        }
        player?.seek(
            to: CMTime(timeInterval: time),
            toleranceBefore: toleranceBefore,
            toleranceAfter: toleranceAfter
        ) { [weak self] finished in
            completionHandler(finished)
            self?.updateNowPlayingInfoCenter()
        }
    }

}
