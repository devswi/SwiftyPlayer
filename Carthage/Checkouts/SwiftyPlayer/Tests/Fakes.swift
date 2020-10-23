//
//  Fakes.swift
//  BayMedia
//
//  Created by shiwei on 2020/6/2.
//

import AVFoundation
@testable import SwiftyPlayer
import SystemConfiguration
import UIKit

class FakeEventListener: EventListener {
    var eventClosure: ((Event, EventProducer) -> Void)?

    func onEvent(_ event: Event, generateBy eventProducer: EventProducer) {
        eventClosure?(event, eventProducer)
    }
}

class FakeItem: AVPlayerItem {
    var bufferEmpty = true {
        willSet {
            willChangeValue(for: \.isPlaybackBufferEmpty)
        }
        didSet {
            didChangeValue(for: \.isPlaybackBufferEmpty)
        }
    }

    override var isPlaybackBufferEmpty: Bool {
        bufferEmpty
    }

    var likelyToKeepUp = false {
        willSet {
            willChangeValue(for: \.isPlaybackLikelyToKeepUp)
        }
        didSet {
            didChangeValue(for: \.isPlaybackLikelyToKeepUp)
        }
    }

    override var isPlaybackLikelyToKeepUp: Bool {
        likelyToKeepUp
    }

    var timeRanges: [NSValue] = [] {
        willSet {
            willChangeValue(for: \.loadedTimeRanges)
        }
        didSet {
            didChangeValue(for: \.loadedTimeRanges)
        }
    }

    override var loadedTimeRanges: [NSValue] {
        timeRanges
    }

    var stat: AVPlayerItem.Status = .unknown {
        willSet {
            willChangeValue(for: \.status)
        }
        didSet {
            didChangeValue(for: \.status)
        }
    }

    override var status: AVPlayerItem.Status {
        stat
    }

    var dur = CMTime() {
        willSet {
            willChangeValue(for: \.duration)
        }
        didSet {
            didChangeValue(for: \.duration)
        }
    }

    override var duration: CMTime {
        dur
    }

}

extension Selector {
    fileprivate static let fakePlayerTimerTicked = #selector(FakePlayer.timerTicked(_:))
}

class FakePlayer: AVPlayer {
    var timer: Timer?
    var startDate: Date?
    var observerClosure: ((CMTime) -> Void)?
    var item: FakeItem? {
        willSet {
            willChangeValue(for: \.currentItem)
        }
        didSet {
            didChangeValue(for: \.currentItem)
        }
    }

    override var currentItem: AVPlayerItem? {
        item
    }

    override func addPeriodicTimeObserver(
        forInterval interval: CMTime,
        queue: DispatchQueue?,
        using block: @escaping (CMTime) -> Void
    ) -> Any {
        observerClosure = block
        startDate = Date()
        timer = Timer.scheduledTimer(
            timeInterval: CMTimeGetSeconds(interval),
            target: self,
            selector: .fakePlayerTimerTicked,
            userInfo: nil,
            repeats: false
        )
        return self
    }

    override func removeTimeObserver(_ observer: Any) {
        timer?.invalidate()
        timer = nil
        startDate = nil
        observerClosure = nil
    }

    // swiftlint:disable force_unwrapping identifier_name
    @objc
    fileprivate func timerTicked(_: Timer) {
        let t = fabs(startDate!.timeIntervalSinceNow)
        observerClosure?(CMTime(timeInterval: t))
    }
}

// swiftlint:disable identifier_name
class FakeMetadataItem: AVMetadataItem {
    var _commonKey: AVMetadataKey
    var _value: NSCopying & NSObjectProtocol

    init(commonKey: AVMetadataKey, value: NSCopying & NSObjectProtocol) {
        _commonKey = commonKey
        _value = value
    }

    override var commonKey: AVMetadataKey? {
        _commonKey
    }

    override var value: NSCopying & NSObjectProtocol {
        _value
    }
}
