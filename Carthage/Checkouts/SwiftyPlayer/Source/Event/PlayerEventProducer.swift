//
//  PlayerEventProducer.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/4.
//

import AVFoundation

extension Selector {
    fileprivate static let audioSessionInterrupted = #selector(PlayerEventProducer.audioSessionGotInterrupted(note:))
    fileprivate static let audioRouteChanged = #selector(PlayerEventProducer.audioSessionRouteChanged(note:))
    fileprivate static let audioSessionMessedUp = #selector(PlayerEventProducer.audioSessionMessedUp(note:))
    fileprivate static let itemDidEnd = #selector(PlayerEventProducer.playerItemDidEnd(note:))
}

class PlayerEventProducer: NSObject, EventProducer {

    enum PlayerEvent: Event {
        case startedBuffering
        case readyToPlay
        case loadedMoreRange(earliest: CMTime, latest: CMTime)
        case loadedMetadata(metadata: [AVMetadataItem])
        case loadedDuration(duration: CMTime)
        case progressed(time: CMTime)
        case endedPlaying(error: Error?)
        case interruptionBegan(_ wasSuspended: Bool)
        case interruptionEnded(shouldResume: Bool)
        case routeChanged(reason: AVAudioSession.RouteChangeReason)
        case sessionMessedUp
    }

    enum KVOProperty: String, CaseIterable {
        case playbackBufferEmpty = "currentItem.playbackBufferEmpty"
        case playbackLikelyToKeepUp = "currentItem.playbackLikelyToKeepUp"
        case duration = "currentItem.duration"
        case currentItemStatus = "currentItem.status"
        case status
        case loadedItemRanges = "currentItem.loadedItemRanges"
        case timedMetadata = "currentItem.timedMetadata"
    }

    var cachedObservation: [String: NSKeyValueObservation?] = [:]

    /// The player to produce events with.
    var player: AVPlayer? {
        willSet {
            stopProducingEvents()
        }
    }

    var eventListener: EventListener?

    private var timeObserver: Any?

    /// 当前事件发生器是否正在监听
    private var listening = false

    /// 析构时停止监听
    deinit {
        stopProducingEvents()
    }

    /// Starts listening to the player events.
    func startProducingEvents() {
        guard let player = player, !listening else {
            return
        }

        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: .audioSessionInterrupted,
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: .audioRouteChanged,
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: .audioSessionMessedUp,
            name: AVAudioSession.mediaServicesWereLostNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: .audioSessionMessedUp,
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: .itemDidEnd,
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
        for property in KVOProperty.allCases {
            retrieveObservation(for: property, player: player)
        }

        // Observing timing event.
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 1, preferredTimescale: timeScale) // 设置每秒回调
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: time,
            queue: .main
        ) { [weak self] time in
            if let self = self {
                self.eventListener?.onEvent(PlayerEvent.progressed(time: time), generateBy: self)
            }
        }

        listening = true
    }

    func stopProducingEvents() {
        guard let player = player, listening else {
            return
        }

        let center = NotificationCenter.default

        center.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        center.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
        center.removeObserver(self, name: AVAudioSession.mediaServicesWereLostNotification, object: nil)
        center.removeObserver(self, name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
        center.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)

        for property in KVOProperty.allCases {
            cachedObservation[property.rawValue].flatMap { $0 }?.invalidate()
        }
        cachedObservation = [:]

        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }

        listening = false
    }

    @objc
    fileprivate func audioSessionGotInterrupted(note: Notification) {
        guard let userInfo = note.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }
        if type == .began {
            if #available(iOS 10.3, *),
               let wasSuspended = userInfo[AVAudioSessionInterruptionWasSuspendedKey] as? NSNumber {
                eventListener?.onEvent(PlayerEvent.interruptionBegan(wasSuspended.boolValue), generateBy: self)
                return
            }
            eventListener?.onEvent(PlayerEvent.interruptionBegan(false), generateBy: self)
        } else {
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            eventListener?.onEvent(
                PlayerEvent.interruptionEnded(shouldResume: options.contains(.shouldResume)),
                generateBy: self
            )
        }
    }

    @objc
    fileprivate func audioSessionRouteChanged(note: Notification) {
        let reason = note.userInfo
            .flatMap { $0[AVAudioSessionRouteChangeReasonKey] as? UInt }
            .flatMap(AVAudioSession.RouteChangeReason.init) ?? .unknown
        eventListener?.onEvent(PlayerEvent.routeChanged(reason: reason), generateBy: self)
    }

    @objc
    fileprivate func audioSessionMessedUp(note: Notification) {
        eventListener?.onEvent(PlayerEvent.sessionMessedUp, generateBy: self)
    }

    @objc
    fileprivate func playerItemDidEnd(note: Notification) {
        eventListener?.onEvent(PlayerEvent.endedPlaying(error: nil), generateBy: self)
    }

    private func retrieveObservation(for kvo: KVOProperty, player: AVPlayer) {
        guard cachedObservation[kvo.rawValue] == nil, let currentItem = player.currentItem else { return }
        var observation: NSKeyValueObservation?
        switch kvo {
        case .playbackBufferEmpty:
            observation = player.observe(
                \.currentItem?.isPlaybackBufferEmpty,
                options: .new
            ) { [weak eventListener, weak self] _, _ in
                guard let self = self, currentItem.isPlaybackBufferEmpty else { return }
                eventListener?.onEvent(PlayerEvent.startedBuffering, generateBy: self)
            }
        case .playbackLikelyToKeepUp:
            observation = player.observe(
                \.currentItem?.isPlaybackLikelyToKeepUp,
                options: .new
            ) { [weak eventListener, weak self] _, _ in
                guard let self = self, currentItem.isPlaybackLikelyToKeepUp else { return }
                eventListener?.onEvent(PlayerEvent.readyToPlay, generateBy: self)
            }
        case .duration:
            observation = player.observe(
                \.currentItem?.duration,
                options: .new
            ) { [weak eventListener, weak self] _, _ in
                guard let self = self else { return }
                let duration = currentItem.duration
                eventListener?.onEvent(PlayerEvent.loadedDuration(duration: duration), generateBy: self)

                let metadata = currentItem.asset.metadata
                eventListener?.onEvent(PlayerEvent.loadedMetadata(metadata: metadata), generateBy: self)
            }
        case .currentItemStatus:
            observation = player.observe(
                \.currentItem?.status,
                options: .new
            ) { [weak eventListener, weak self] _, _ in
                guard let self = self, currentItem.status == .failed else { return }
                eventListener?.onEvent(PlayerEvent.endedPlaying(error: currentItem.error), generateBy: self)
            }
        case .status:
            observation = player.observe(\.status, options: .new) { [weak eventListener, weak self] _, _ in
                guard let self = self, player.status == .readyToPlay else { return }
                eventListener?.onEvent(PlayerEvent.readyToPlay, generateBy: self)

                let duration = currentItem.asset.duration
                eventListener?.onEvent(PlayerEvent.loadedDuration(duration: duration), generateBy: self)

                let metadata = currentItem.asset.metadata
                eventListener?.onEvent(PlayerEvent.loadedMetadata(metadata: metadata), generateBy: self)
            }
        case .loadedItemRanges:
            observation = player.observe(
                \.currentItem?.loadedTimeRanges,
                options: .new
            ) { [weak eventListener, weak self] _, _ in
                guard let self = self else { return }
                if let range = currentItem.loadedTimeRanges.last?.timeRangeValue {
                    eventListener?.onEvent(
                        PlayerEvent.loadedMoreRange(earliest: range.start, latest: range.end),
                        generateBy: self)
                }
            }
        case .timedMetadata:
            observation = player.observe(
                \.currentItem?.timedMetadata,
                options: .new
            ) { [weak eventListener, weak self] _, _ in
                guard let self = self else { return }
                if let metadata = currentItem.timedMetadata {
                    eventListener?.onEvent(PlayerEvent.loadedMetadata(metadata: metadata), generateBy: self)
                }
            }
        }
        cachedObservation[kvo.rawValue] = observation
    }
}
