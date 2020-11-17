//
//  Player.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/3.
//

import AVFoundation
import MediaPlayer

/// `Player` 实例用于播放 `PlayableItem`.
public class Player: NSObject, EventListener {

    // MARK: Handlers

    /// 网络状态监听
    let reachability = Reachability()

    // MARK: Event producers

    /// 网络状态监听
    lazy var networkEventProducer: NetworkEventProducer = {
        NetworkEventProducer(reachability: self.reachability)
    }()

    /// 播放器事件发生器
    let playerEventProducer = PlayerEventProducer()

    /// seek 事件发生器
    let seekEventProducer = SeekEventProducer()

    /// 资源质量自适应发生器
    let qualityAdjustmentEventProducer = QualityAdjustmentEventProducer()

    /// 播放资源 item 事件发生器
    let playableItemEventProducer = PlayableItemEventProducer()

    /// 重试事件发生器
    let retryEventProducer = RetryEventProducer()

    // MARK: Player

    /// 播放队列
    var queue: PlayableItemQueue?

    /// 资源播放器
    var player: AVPlayer? {
        didSet {
            player?.volume = volume
            player?.rate = rate
            updatePlayerForBufferingStrategy()
        }
    }

    var avPlayerItem: AVPlayerItem? {
        didSet {
            playerItemDidChanged(old: oldValue, new: avPlayerItem)
        }
    }

    /// 管理 audio session
    ///
    /// 通过 setCategory(_ category:, mode:, options:,notifyOthersOnDeactivation:) 对 AVAudioSession 进行自定义
    ///
    /// Player 持有 AVAudioSession 的配置，在播放时进行设置。
    let audioSession = PlayerAudioSession()

    /// 当前播放的 item 实例
    public internal(set) var currentItem: PlayableItem? {
        didSet {
            if let currentItem = currentItem {
                // Stops the current player
                player?.rate = 0

                // Ensures the audio session got started.
                do {
                    try audioSession.setActive(true)
                } catch {
                    delegate?.player(self, setAudioSessionErrorOccured: error)
                }

                // Sets new state
                let info = currentItem.url(for: currentQuality)
                guard let resource = info.resource else { return }

                if reachability.isReachable() || resource.resourceURL.isOfflineURL {
                    state = .buffering
                } else {
                    stateWhenConnectionLost = .buffering
                    state = .waitingForConnection
                    return
                }

                // Reset special state flags.
                pausedForInterruption = false
                let playerItem: AVPlayerItem
                if let data = currentItem.data { // pre-load
                    playerItem = AVPlayerItem(asset: data)
                    if let currentItemDuration = currentItemDuration, currentItemDuration > 0 {
                        delegate?.player(self, didFindDuration: currentItemDuration, for: currentItem)
                    }
                } else {
                    let asset = AVAsset(url: resource.resourceURL)
                    playerItem = AVPlayerItem(asset: asset)
                }
                playerItem.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithm(
                    rawValue: audioTimePitchAlgorithm.rawValue
                )
                playerItem.preferredForwardBufferDuration = preferredForwardBufferDuration

                avPlayerItem = playerItem

                currentQuality = info.quality
                // 更新控制中心播放信息
                updateNowPlayingInfoCenter()

                // Calls delegate
                if oldValue != currentItem {
                    delegate?.player(self, willStartPlaying: currentItem)
                }
                player?.rate = rate
            } else {
                stop()
            }
        }
    }

    /// 当前播放的 item 是否可以快退
    public var canPlayFastReverse: Bool {
        player?.currentItem?.canPlayFastReverse ?? false
    }

    /// 当前播放的 item 是否可以快进
    public var canPlayFastForward: Bool {
        player?.currentItem?.canPlayFastForward ?? false
    }

    // MARK: Public properties

    /// `PlayerDelegate`
    public weak var delegate: PlayerDelegate?

    /// 定义了网络连接丢失后等待的最大时长
    ///
    /// 默认为 60 秒
    public var maximumConnectionLossTime: TimeInterval = 60

    /// 定义了 boolean 值，播放器是否自适应切换资源质量
    ///
    /// 默认为 `true`.
    public var adjustQualityAutomatically = true

    /// 默认使用的质量
    /// 默认值为 `.medium`.
    public var defaultQuality: PlayableQuality = .medium

    /// 定义了出现播放中断后自动切换质量的时间差
    ///
    /// 默认值为10 分钟
    public var adjustQualityTimeInterval: TimeInterval {
        get {
            qualityAdjustmentEventProducer.adjustQualityTimeInterval
        }
        set {
            qualityAdjustmentEventProducer.adjustQualityTimeInterval = newValue
        }
    }

    /// 定义了调整资源质量前的播放被中断的次数
    ///
    /// 默认为 5 次
    public var adjustQualityAfterInterruptionCount: Int {
        get {
            qualityAdjustmentEventProducer.adjustQualityAfterInterruptionCount
        }
        set {
            qualityAdjustmentEventProducer.adjustQualityAfterInterruptionCount = newValue
        }
    }

    /// 播放过程被中断的最大重试次数，达到最大次数时播放器 state 会被置为 `.stopped`
    ///
    /// 默认为 10 次
    public var maximumRetryCount: Int {
        get {
            retryEventProducer.maximumRetryCount
        }
        set {
            retryEventProducer.maximumRetryCount = newValue
        }
    }

    /// 重试等待时长，如果重试等待超时，就会取消当前重试，并开始重新尝试请求资源
    /// 默认为 10 秒
    public var retryTimeout: TimeInterval {
        get {
            retryEventProducer.retryTimeout
        }
        set {
            retryEventProducer.retryTimeout = newValue
        }
    }

    /// 是否在中断之后是否继续播放，默认为 `true`
    public var resumeAfterInterruption = true

    /// 网络连接丢失重连后是否继续播放
    /// 默认为 `true`
    public var resumeAfterConnectionLoss = true

    /// 播放器播放循环模式，默认为 `.normal`
    public var mode = PlayMode.normal {
        didSet {
            queue?.mode = mode
        }
    }

    /// 播放器音量
    public var volume: Float = 1 {
        didSet {
            player?.volume = volume
        }
    }

    /// 播放器播放速率，默认值为 1
    public var rate: Float = 1 {
        didSet {
            if case .playing = state {
                player?.rate = rate
                updateNowPlayingInfoCenter()
            }
        }
    }

    /// 播放器播放历史
    public var historic: [PlayableItem] {
        queue?.historic ?? []
    }

    /// 播放器缓存策略
    /// 默认值为 `.defaultBuffering`
    public var bufferingStrategy: PlayerBufferingStrategy = .defaultBuffering {
        didSet {
            updatePlayerForBufferingStrategy()
        }
    }

    /// 自定义播放前缓存时长，默认缓存 30 秒
    public var preferredBufferDurationBeforePlayback: TimeInterval = 30

    /// 当前 item 之后的 `AVPlayerItem` 的提前缓存时长
    public var preferredForwardBufferDuration: TimeInterval = 0

    /// 当前 item 播放结束之后操作
    ///
    /// 默认播放队列中的下一个
    public var actionAtItemEnd: ActionAtItemEnd = .advance {
        didSet {
            player?.actionAtItemEnd = AVPlayer.ActionAtItemEnd(rawValue: actionAtItemEnd.rawValue) ?? .none
        }
    }

    /// 定义了用户执行 seek 操作的行为
    ///
    /// - multiplyRate: 依据给定比率倍速播放
    /// - changeTime: 直接跳转到指定时间
    public enum SeekingBehavior {
        case multiplyRate(Float)
        case changeTime(every: TimeInterval, delta: TimeInterval)

        func handleSeekingStart(player: Player, forward: Bool) {
            switch self {
            case .multiplyRate(let rateMultiplier):
                if forward {
                    player.rate *= rateMultiplier
                } else {
                    player.rate = -(player.rate * rateMultiplier)
                }
            case .changeTime:
                player.seekEventProducer.isBackward = !forward
                player.seekEventProducer.startProducingEvents()
            }
        }

        func handleSeekingEnd(player: Player, forward: Bool) {
            switch self {
            case .multiplyRate(let rateMultiplier):
                player.rate /= rateMultiplier
            case .changeTime:
                player.seekEventProducer.stopProducingEvents()
            }
        }
    }

    /// 定义快进快退播放的行为
    ///
    /// 默认为两倍速快进 `.multiplyRate(2)`.
    public var seekingBehavior: SeekingBehavior = .multiplyRate(2) {
        didSet {
            if case .changeTime(let timeInterval, _) = seekingBehavior {
                seekEventProducer.intervalBetweenEvents = timeInterval
            }
        }
    }

    /// 决定当使用不同速率播放音视频时，通过何种算法解析音频
    public var audioTimePitchAlgorithm: PlayerAudioTimePitchAlgorithm = .timeDomain

    // MARK: Readonly properties

    /// 当前播放器状态 `PlayerState`
    public internal(set) var state: PlayerState = .stopped {
        didSet {
            updateNowPlayingInfoCenter()

            if state != oldValue {
                delegate?.player(self, didChangeStateFrom: oldValue, to: state)
            }
        }
    }

    public internal(set) var currentQuality: PlayableQuality

    /// remote command options
    /// 
    /// 默认支持播放，暂停，上一首，下一首，Stop，脱拽播放进度等指令
    public var remoteCommandOptions: RemoteCommandOptions = .all {
        didSet {
            setupRemoteCommand()
        }
    }

    // MARK: Private properties

    var pausedForInterruption = false

    var qualityIsBeingChanged = false

    var stateBeforeBuffering: PlayerState?

    var stateWhenConnectionLost: PlayerState?

    var shouldResumePlaying: Bool {
        !state.isPaused
            && (stateWhenConnectionLost.map { !$0.isPaused } ?? true)
            && (stateBeforeBuffering.map { !$0.isPaused } ?? true)
    }

    var remoteCommandCache: [RemoteCommandOptions: Any?] = [:]

    // MARK: Initialization

    public override init() {
        currentQuality = defaultQuality
        super.init()
        setupRemoteCommand()
        playerEventProducer.eventListener = self
        networkEventProducer.eventListener = self
        playableItemEventProducer.eventListener = self
        qualityAdjustmentEventProducer.eventListener = self
    }

    deinit {
        stop()
    }

    /// 设置 PlayerAudioSession 的 category/mode/options，本质是对 AVAudioSession 单例的修改
    ///
    /// - Parameters:
    ///   - category: PlayerAudioSession.Category 同 AVAudioSession.Category
    ///   - mode: PlayerAudioSession.Mode 同 AVAudioSession.Mode
    ///   - options: PlayerAudioSession.CategoryOptions 同 AVAudioSession.CategoryOptions
    ///   - notifyOthersOnDeactivation: 是否在 deactive 后通知其他 AudioSession 默认为 true
    public func setCategory(
        _ category: PlayerAudioSession.Category,
        mode: PlayerAudioSession.Mode = .default,
        options: PlayerAudioSession.CategoryOptions = [],
        notifyOthersOnDeactivation: Bool = true
    ) {
        audioSession.setCategory(
            category,
            mode: mode,
            options: options,
            notifyOthersOnDeactivation: notifyOthersOnDeactivation
        )
    }

    /// Preload specified `PlayableItme`
    public func preload(item: PlayableItem) {
        if item.data != nil {
            return
        }

        let info = item.url(for: currentQuality)
        guard let resource = info.resource else { return }

        let asset = AVURLAsset(url: resource.resourceURL)
        let keys = ["playable", "tracks"]
        asset.loadValuesAsynchronously(forKeys: keys) {
            for key in keys {
                if case .failed = asset.statusOfValue(forKey: key, error: nil) {
                    return
                }
            }
            DispatchQueue.main.safeAsync {
                item.data = asset
            }
        }
    }

    /// 对于 `EventListener` 的实现，处理多种事件的监听
    ///
    /// - Parameters:
    ///   - event: 处理的事件
    ///   - eventProducer: 事件发生器
    public func onEvent(_ event: Event, generateBy eventProducer: EventProducer) {
        if let event = event as? NetworkEventProducer.NetworkEvent {
            handleNetworkEvent(from: eventProducer, with: event)
        } else if let event = event as? PlayerEventProducer.PlayerEvent {
            handlePlayerEvent(from: eventProducer, with: event)
        } else if let event = event as? PlayableItemEventProducer.PlayableItemEvent {
            handlePlayableItemEvent(from: eventProducer, with: event)
        } else if let event = event as? QualityAdjustmentEventProducer.QualityAdjustmentEvent {
            handleQualityEvent(from: eventProducer, with: event)
        } else if let event = event as? RetryEventProducer.RetryEvent {
            handleRetryEvent(from: eventProducer, with: event)
        } else if let event = event as? SeekEventProducer.SeekEvent {
            handleSeekEvent(from: eventProducer, with: event)
        }
    }

}

// MARK: Utility methods

extension Player {

    /// 更新当前播放 item 的`MPNowPlayingInfoCenter`信息
    func updateNowPlayingInfoCenter() {
        if let item = currentItem {
            MPNowPlayingInfoCenter.default().update(
                with: item,
                duration: currentItemDuration,
                progression: currentItemProgression,
                playbackRate: rate
            )
        }  else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        }
    }

    func retryOrPlayNext() {
        guard !state.isPlaying else {
            retryEventProducer.stopProducingEvents()
            return
        }

        let cip = currentItemProgression
        let ci = currentItem
        currentItem = ci
        if let cip = cip {
            player?.seek(to: CMTime(timeInterval: cip))
        }
    }

    func updatePlayerForBufferingStrategy() {
        player?.automaticallyWaitsToMinimizeStalling = bufferingStrategy != .playWhenBufferNotEmpty
    }

    private func playerItemDidChanged(old: AVPlayerItem?, new: AVPlayerItem?) {
        if old != nil { // stop produce events
            playableItemEventProducer.item = nil
            playerEventProducer.stopProducingEvents()
            networkEventProducer.stopProducingEvents()
            playableItemEventProducer.stopProducingEvents()
            qualityAdjustmentEventProducer.stopProducingEvents()
        }

        guard let item = new else { return }
        if player == nil {
            player = AVPlayer(playerItem: item)
        } else {
            player?.replaceCurrentItem(with: item)
        }

        playerEventProducer.player = player
        playableItemEventProducer.item = currentItem
        playerEventProducer.startProducingEvents()
        networkEventProducer.startProducingEvents()
        playableItemEventProducer.startProducingEvents()
        qualityAdjustmentEventProducer.startProducingEvents()
    }
}
