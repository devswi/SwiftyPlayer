//
//  MediaPlayerControlViewController.swift
//  Example
//
//  Created by shiwei on 2020/11/18.
//

import AVFoundation
import AVKit
import MediaPlayer
import SwiftyPlayer
import UIKit

enum VideoPlayerGestureDirection {
    case horizontal
    case vertical(isLeft: Bool)

    var isHorizontal: Bool {
        if case .horizontal = self {
            return true
        }
        return false
    }
}

/// 媒体播放器统一的控制页面
///
/// 使用时传入
/// player 与 videoPlayerView 参数，用作播放器实例和播放器承载 View 视图
/// 页面的交互回调定义在 Handlers 结构体的 closure 中
class VideoPlayerControlViewController: UIViewController {
    struct Handlers {
        var willSetPlayableItem: (() -> Void)?
        var willDismissMediaPlayer: (() -> Void)?
        var needUpdateSystemInterface: ((Bool) -> Void)?
        var didUpdatePlaybackProgression: ((_ time: TimeInterval, _ percentageRead: Float) -> Void)?
        var didEndedPlaying: ((PlayableItem) -> Void)?
        var didEnterLandscape: ((Bool) -> Void)?
        var willStartDownloadMedia: (() -> Void)?
    }
    var handlers = Handlers()

    weak var player: Player? {
        didSet {
            player?.delegate = self
        }
    }
    /// 用于 pip
    weak var videoPlayerView: VideoPlayerView?
    /// 是否可以支持离线缓存
    var isDownloadable = true
    /// 是否在 iPad 中支持全屏
    var isFullscrrenSupportedInIPad = true

    @IBOutlet weak var pipButton: StatefulButton!
    @IBOutlet private weak var playbackSpeedButton: UIButton!

    @IBOutlet private weak var forwardButton: StatefulButton!
    @IBOutlet private weak var backwardButton: StatefulButton!
    @IBOutlet private weak var currentTimeLabel: UILabel!
    @IBOutlet private weak var durationTimeLabel: UILabel!
    @IBOutlet private weak var playOrPauseButton: StatefulButton!
    @IBOutlet private weak var slider: UISlider!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    @IBOutlet private weak var clickGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet private weak var doubleClickGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet private weak var panGestureRecognizer: UIPanGestureRecognizer!
    @IBOutlet private weak var coverImageView: UIImageView!

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var pipContainerView: UIView!
    @IBOutlet private weak var fullscreenButton: StatefulButton!
    /// 开启屏幕录制
    @IBOutlet private weak var screenCaptureContainerView: UIView!
    /// 亮度调节
    @IBOutlet weak var brightnessView: UIView!
    @IBOutlet weak var brightnessProgressView: UIProgressView!

    private var isAllComponentsHidden = false
    private var wasPlayingBeforeSeeking = false
    private var isSeeking = false
    private var allControlComponentsHiddenTask: DispatchWorkItem?
    private var speed = PlayerSpeed.x1

    var pictureInPictureController: AVPictureInPictureController?
    var isPipModeEnabled: Bool = false
    var pipPossibleObservation: NSKeyValueObservation?

    // 亮度与音量公差
    let bvTolerance: CGFloat = 0.008

    private var prefersSystemBarHidden = false
    /// notification token
    private var token: Any?

    private let skipSize: Double = 30
    private var isSliding = false

    private var gestureDirection: VideoPlayerGestureDirection?
    private var volumeSlider: UISlider?

    override func viewDidLoad() {
        super.viewDidLoad()

        slider.setThumbImage(UIImage(named: "playhead"), for: .normal)
        playOrPauseButton.activeImage = UIImage(named: "pause")
        playOrPauseButton.inactiveImage = UIImage(named: "play")
        fullscreenButton.activeImage = UIImage(named: "fullscreen_disable")
        fullscreenButton.inactiveImage = UIImage(named: "fullscreen")
        // pip setting
        setPipImage()
        // 暂不上线 pip
        // setupPictureInPicture()
        clickGestureRecognizer.require(toFail: doubleClickGestureRecognizer)
        clickGestureRecognizer.require(toFail: panGestureRecognizer)
        playbackSpeedButton.setAttributedTitle(speed.attributedString, for: .normal)
        if #available(iOS 13.0, *) {
            activityIndicatorView.style = .medium
        } else {
            activityIndicatorView.style = .white
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            fullscreenButton.isHidden = !isFullscrrenSupportedInIPad
        }
        addScreenCaptureNotification()
        brightnessProgressView.progress = Float(UIScreen.main.brightness)
        setSystemVolume()
    }

    deinit {
        pipPossibleObservation?.invalidate()
        if let token = token {
            NotificationCenter.default.removeObserver(token)
        }
    }

    /// 设置
    func setCover(_ url: URL) {
        coverImageView.isHidden = false
//        coverImageView.sd_setImage(with: url)
    }

    func setLandscape(_ isLandscape: Bool) {
        fullscreenButton.isActive = isLandscape
    }

    // MARK: Gesture

    @IBAction private func clickGestureAction(_ gesture: UITapGestureRecognizer) {
        if isAllComponentsHidden {
            setAllControlComponents(hidden: false)
            let isPlaying = player?.state.isPlaying ?? false
            if isPlaying {
                allControlComponentsAutoHide()
            }
        } else {
            setAllControlComponents(hidden: true)
        }
    }

    @IBAction private func doubleClickGestureAction(_ gesture: UITapGestureRecognizer) {
        playOrPauseAction(playOrPauseButton)
    }

    @IBAction private func panGestureAction(_ pan: UIPanGestureRecognizer) {
        let translation = pan.translation(in: pan.view)
        let velocity = pan.velocity(in: pan.view)
        let locationPoint = pan.location(in: pan.view)
        switch pan.state {
        case .began: // gesture began
            let xVelocity = abs(velocity.x)
            let yVelocity = abs(velocity.y)
            let isHorizontal = xVelocity > yVelocity // 是否在水平方向上移动
            if isHorizontal {
                gestureDirection = .horizontal
            } else {
                let isLeft = locationPoint.x < view.bounds.size.width / 2
                gestureDirection = .vertical(isLeft: isLeft)
            }
            panGestureBegan(translation: translation)
        case .changed: // gesture changed
            panGestureDidChanged(translation: translation)
            pan.setTranslation(.zero, in: pan.view)
        case .failed, .ended, .cancelled: // gesture ended or failed or cancelled
            panGestureEnded(translation: translation)
        default:
            break
        }
    }

    // MARK: Button Action

    @IBAction func dismissPlayerAction(_ sender: UIButton) {
        handlers.willDismissMediaPlayer?()
    }

    @IBAction func pipAction(_ sender: StatefulButton) {
        guard let pictureInPictureController = pictureInPictureController else { return }
        if pictureInPictureController.isPictureInPictureActive {
            pictureInPictureController.stopPictureInPicture()
        } else {
            let isPlaying = player?.state.isPlaying ?? false
            if !isPlaying {
                player?.resume()
            }
            pictureInPictureController.startPictureInPicture()
        }
    }

    @IBAction func modifyPlaybackSpeedAction(_ sender: UIButton) {
        cancelAllControlComponentsAutoHide()
        let next = speed.nextSpeed()
        playbackSpeedButton.setAttributedTitle(next.attributedString, for: .normal)
        player?.rate = next.value
        speed = next
        allControlComponentsAutoHide()
    }

    @IBAction func forwardAction(_ sender: UIButton) {
        guard let currentItemProgression = player?.currentItemProgression else { return }
        cancelAllControlComponentsAutoHide()
        let time = currentItemProgression + skipSize
        player?.seek(to: time) { [weak self] _ in
            self?.allControlComponentsAutoHide()
        }
    }

    @IBAction func backwardAction(_ sender: UIButton) {
        guard let currentItemProgression = player?.currentItemProgression else { return }
        cancelAllControlComponentsAutoHide()
        let time = currentItemProgression - skipSize
        player?.seek(to: time) { [weak self] _ in
            self?.allControlComponentsAutoHide()
        }
    }

    @IBAction func playOrPauseAction(_ sender: UIButton) {
        guard let player = player, player.currentItem != nil else {
            handlers.willSetPlayableItem?()
            return
        }
        if player.state.isPlaying {
            playOrPauseButton.isActive = false
            player.pause()
        } else {
            playOrPauseButton.isActive = true
            player.rate = speed.value
            player.resume()
            hideCoverImage()
        }
    }

    @IBAction func playheadDidChanged(_ sender: UISlider) {
        isSeeking = true
        let value = Double(sender.value)
        player?.seek(to: value)
    }

    @IBAction func seekingStart(_ sender: UISlider) {
        startSeeking()
    }

    @IBAction func seekingEnd(_ sender: UISlider) {
        endSeeking()
    }

    @IBAction func playerFullscreenAction(_ sender: StatefulButton) {
        sender.isActive.toggle()
        handlers.didEnterLandscape?(sender.isActive)
    }

    private func setSystemVolume() {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first { $0 is UISlider } as? UISlider
        volumeSlider = slider
    }
}

// MARK: - PlayerDelegate

extension VideoPlayerControlViewController: PlayerDelegate {
    func player(_ player: Player, didFindDuration duration: TimeInterval, for item: PlayableItem) {
        slider.maximumValue = Float(duration)
        durationTimeLabel.text = duration.timeSecond
    }

    func player(_ player: Player, didChangeStateFrom from: PlayerState, to state: PlayerState) {
        let isPlaying = state.isPlaying
        playOrPauseButton.isActive = isPlaying
        if isPlaying {
            allControlComponentsAutoHide()
            hideCoverImage()
        }
        let isPaused = state.isPaused
        if isPaused {
            setAllControlComponents(hidden: false)
            cancelAllControlComponentsAutoHide()
        }
        let isBuffering = state.isBuffering
        playOrPauseButton.isHidden = isBuffering
        activityIndicatorView.isHidden = !isBuffering
        if isBuffering {
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
        if case .failed(let error) = state {
            print(error.localizedDescription)
        }
    }

    func player(_ player: Player, didUpdateProgressionTo time: TimeInterval, percentageRead: Float) {
        if !isSeeking {
            slider.value = Float(time)
        }
        currentTimeLabel.text = time.timeSecond
        handlers.didUpdatePlaybackProgression?(time, percentageRead)
    }

    func player(_ player: Player, didEndedPlaying item: PlayableItem) {
        handlers.didEndedPlaying?(item)
    }
}

// MARK: UIGestureRecognizerDelegate

extension VideoPlayerControlViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if otherGestureRecognizer !== clickGestureRecognizer &&
            otherGestureRecognizer !== doubleClickGestureRecognizer &&
            otherGestureRecognizer !== panGestureRecognizer {
            return false
        }
        if gestureRecognizer.numberOfTouches >= 2 { return false }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view === screenCaptureContainerView { return false }
        return true
    }
}

// MARK: Private

extension VideoPlayerControlViewController {
    private func setPipImage() {
        if #available(iOS 13.0, *) {
            let startImage = AVPictureInPictureController.pictureInPictureButtonStartImage
            let stopImage = AVPictureInPictureController.pictureInPictureButtonStopImage
            pipButton.activeImage = stopImage
            pipButton.inactiveImage = startImage
        }
    }

    // MARK: - Control Components Animation

    func setAllControlComponents(hidden isHidden: Bool) {
        guard isHidden != isAllComponentsHidden else { return }
        let alpha: CGFloat = isHidden ? 0 : 1
        if !isHidden {
            self.handlers.needUpdateSystemInterface?(isHidden)
        }
        UIView.animate(
            withDuration: 0.3,
            delay: !isHidden ? 0.1 : 0.0,
            animations: {
                self.containerView.alpha = alpha
            },
            completion: { _ in
                if isHidden {
                    self.handlers.needUpdateSystemInterface?(isHidden)
                }
                self.isAllComponentsHidden = isHidden
            }
        )
    }

    func allControlComponentsAutoHide() {
        cancelAllControlComponentsAutoHide()
        allControlComponentsHiddenTask = DispatchWorkItem { [weak self] in // fix: memory leak!!!
            self?.setAllControlComponents(hidden: true)
        }
        if let task = allControlComponentsHiddenTask {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: task) // 5 秒之后自动隐藏
        }
    }

    func cancelAllControlComponentsAutoHide() {
        allControlComponentsHiddenTask?.cancel()
    }

    // MARK: - Seeking

    private func startSeeking() {
        wasPlayingBeforeSeeking = player?.state.isPlaying ?? false
        isSeeking = true
        player?.pause()
        cancelAllControlComponentsAutoHide()
    }

    private func endSeeking() {
        isSeeking = false
        if wasPlayingBeforeSeeking {
            player?.resume()
            allControlComponentsAutoHide()
        }
    }

    // MARK: - Notification

    private func addScreenCaptureNotification() {
        if #available(iOS 11.0, *) {
            let isCaptured = UIScreen.main.isCaptured
            screenCaptureContainerView.isHidden = !isCaptured
            containerView.isHidden = isCaptured
            if isCaptured {
                player?.pause()
            }
            // 监听屏幕录制
            token = NotificationCenter.default.addObserver(
                forName: UIScreen.capturedDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                let isCaptured = UIScreen.main.isCaptured
                self.screenCaptureContainerView.isHidden = !isCaptured
                self.containerView.isHidden = isCaptured
                if isCaptured {
                    self.player?.pause()
                }
            }
        }
    }

    // MARK: - Pan
    /// Pan 手势开始执行
    /// - Parameter isHorizontal: 是否在水平方向
    private func panGestureBegan(translation: CGPoint) {
        guard let direction = gestureDirection else { return }
        let isHorizontal = direction.isHorizontal
        if case .vertical(let isLeft) = direction, isLeft {
            beginSettingBrightness()
        } else if isHorizontal {
            setAllControlComponents(hidden: false)
            startSeeking()
        }
    }

    private func panGestureDidChanged(translation: CGPoint) {
        guard let direction = gestureDirection else { return }
        let isHorizontal = direction.isHorizontal
        if case .vertical(let isLeft) = direction, isLeft {
            setBrightness(translation.y)
        } else if isHorizontal {
            let duration = slider.maximumValue // 视频时长
            let scale: Float = duration / Float(view.frame.width)
            let seekTime = Float(translation.x) * scale + slider.value
            slider.value = seekTime
            playheadDidChanged(slider)
        } else { // 调节音量
            var volume = volumeSlider?.value ?? player?.volume ?? 0.0
            if translation.y < 0 { // 向上
                volume += Float(bvTolerance)
            } else {
                volume -= Float(bvTolerance)
            }
            volumeSlider?.value = volume
        }
    }

    private func panGestureEnded(translation: CGPoint) {
        guard let direction = gestureDirection else { return }
        let isHorizontal = direction.isHorizontal
        if case .vertical(let isLeft) = direction, isLeft {
            stopSettingBrightness()
        } else if isHorizontal {
            endSeeking()
        }
    }

    private func hideCoverImage() {
        if !coverImageView.isHidden {
            coverImageView.isHidden = true
        }
    }
}
