//
//  JustVideoPlayerViewController.swift
//  Example
//
//  Created by shiwei on 2020/10/22.
//

import AVFoundation
import AVKit
import CoreMedia
import SwiftyPlayer
import UIKit

extension UIDevice {
    func setOrientation(_ orientation: UIInterfaceOrientation) {
        setValue(orientation.rawValue, forKey: "orientation")
    }
}

class JustVideoPlayerViewController: UIViewController {
    private(set) var isCompleted = false

    let url = URL(string: "https://mov.bn.netease.com/open-movie/nos/mp4/2017/12/04/SD3SUEFFQ_hd.mp4")

    struct Handlers {
        var syncMediaProgression: ((Bool, Double) -> Void)?
    }
    var handlers = Handlers()

    @IBOutlet private weak var videoPlayerView: VideoPlayerView!

    private var playableItem: PlayableItem? {
        didSet {
            if let item = playableItem {
                player.play(item: item)
            }
        }
    }

    private lazy var player: VideoPlayer = {
        let player = VideoPlayer()
        player.actionAtItemEnd = .pause
        player.setCategory(.playback)
        player.videoPlayerView = videoPlayerView
        return player
    }()

    private var controlViewController: VideoPlayerControlViewController?
    private var prefersSystemBarHidden = false

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        .fade
    }

    override var prefersStatusBarHidden: Bool {
        prefersSystemBarHidden
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        prefersSystemBarHidden
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let url = url {
            playableItem = PlayableItem(itemResources: [.medium: url])
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let child = segue.destination as? VideoPlayerControlViewController {
            controlViewController = child
            child.isDownloadable = false
            child.isFullscrrenSupportedInIPad = false
            child.player = player
            child.videoPlayerView = videoPlayerView
            child.handlers.didEnterLandscape = { [weak self] isLandscape in
                self?.updateAppearanceWhenRotation(isLandscape)
                UIDevice.current.setOrientation(isLandscape ? .landscapeRight : .portrait)
            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let isLandscape = UIDevice.current.orientation.isLandscape
        controlViewController?.setLandscape(isLandscape)
        updateAppearanceWhenRotation(isLandscape)
    }

    private func updateAppearanceWhenRotation(_ isLandscape: Bool) {
        prefersSystemBarHidden = isLandscape
        UIView.animate(withDuration: 0.3) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
        if #available(iOS 11.0, *) {
            setNeedsUpdateOfHomeIndicatorAutoHidden()
        }
    }
}
