//
//  Player+PlayerEvent.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/4.
//

import CoreMedia

extension Player {

    /// 处理播放器事件
    ///
    /// - Parameters:
    ///   - producer: 事件发生器
    ///   - event: 播放器事件
    func handlePlayerEvent(from producer: EventProducer, with event: PlayerEventProducer.PlayerEvent) {
        switch event {
        case .endedPlaying(error: let error):
            if let error = error {
                state = .failed(.foundationError(error))
            } else if let currentItem = currentItem {
                delegate?.player(self, didEndedPlaying: currentItem)
                endedPlayingItem()
            }
        case .interruptionBegan(let wasSuspended) where !wasSuspended:
            pausedForInterruption = true
            if state.isPlaying || state.isBuffering {
                pause()
            }
        case .interruptionEnded(shouldResume: let shouldResume) where pausedForInterruption:
            if resumeAfterInterruption && shouldResume {
                resume()
            }
            pausedForInterruption = false
        case .loadedDuration(duration: let time):
            if let currentItem = currentItem, let time = time.timeIntervalValue {
                updateNowPlayingInfoCenter()
                delegate?.player(self, didFindDuration: time, for: currentItem)
            }
        case .loadedMetadata(metadata: let metadata):
            if let currentItem = currentItem, !metadata.isEmpty {
                currentItem.parseMetadata(metadata)
                delegate?.player(self, didUpdateEmptyMetadataOn: currentItem, withData: metadata)
            }
        case .loadedMoreRange:
            if let currentItem = currentItem, let currentItemLoadedRange = currentItemLoadedRange {
                delegate?.player(self, didLoad: currentItemLoadedRange, for: currentItem)

                if bufferingStrategy == .playWhenPreferredBufferDurationFull && state == .buffering,
                   let currentItemLoadedAhead = currentItemLoadedAhead,
                   currentItemLoadedAhead.isNormal,
                   currentItemLoadedAhead >= self.preferredBufferDurationBeforePlayback {
                    playImmediately()
                }
            }
        case .progressed(time: let time):
            if let currentItemProgression = time.timeIntervalValue,
               let item = player?.currentItem,
               item.status == .readyToPlay {
                if state.isBuffering || state.isPaused {
                    if shouldResumePlaying {
                        stateBeforeBuffering = nil
                        state = .playing
                        player?.rate = rate
                    } else {
                        player?.rate = 0
                        state = .paused
                    }
                }

                let itemDuration = currentItemDuration ?? 0
                let percentage = (itemDuration > 0 ? Float(currentItemProgression / itemDuration) * 100 : 0)
                delegate?.player(self, didUpdateProgressionTo: currentItemProgression, percentageRead: percentage)
            }
        case .readyToPlay:
            if shouldResumePlaying {
                stateBeforeBuffering = nil
            }
            retryEventProducer.stopProducingEvents()
        case .routeChanged(let reason):
            // 当输出路径变更时 （例如：耳机插拔）暂停播放
            if reason == .oldDeviceUnavailable {
                if let currentItemTimebase = player?.currentItem?.timebase,
                   CMTimebaseGetRate(currentItemTimebase) == 1 {
                    state = .paused
                }
            }
        case .sessionMessedUp:
            do {
                try audioSession.setActive(true)
            } catch {
                delegate?.player(self, setAudioSessionErrorOccured: error)
            }
            state = .stopped
            qualityAdjustmentEventProducer.interruptionCount += 1
            retryOrPlayNext()
        case .startedBuffering:
            if case .playing = state, !qualityIsBeingChanged {
                qualityAdjustmentEventProducer.interruptionCount -= 1
            }

            stateBeforeBuffering = state
            if reachability.isReachable() ||
                (currentItem?.itemResources[currentQuality]?.resourceURL.isOfflineURL ?? false) {
                state = .buffering
            } else {
                state = .waitingForConnection
            }
        default:
            break
        }
    }

    private func endedPlayingItem() {
        if case .advance = actionAtItemEnd {
            nextOrStop()
        } else {
            pause()
            if case .pause = actionAtItemEnd {
                seek(to: 0)
            }
        }
    }

}
