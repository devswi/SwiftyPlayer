//
//  VideoPlayerControlViewController+Pip.swift
//  Example
//
//  Created by shiwei on 2020/11/18.
//

import AVFoundation
import AVKit

extension VideoPlayerControlViewController {
    func setupPictureInPicture() {
        // Ensure PiP is supported by current device.
        if AVPictureInPictureController.isPictureInPictureSupported(), let videoPlayerView = videoPlayerView {
            // Create a new controller, passing the reference to the AVPlayerLayer.
            pictureInPictureController = AVPictureInPictureController(playerLayer: videoPlayerView.playerLayer)
            pictureInPictureController?.delegate = self
            pipPossibleObservation = pictureInPictureController?.observe(
                \AVPictureInPictureController.isPictureInPicturePossible,
                options: [.initial, .new]
            ) { [weak self] _, change in
                // Update the PiP button's enabled state.
                self?.pipButton.isEnabled = change.newValue ?? false
            }
        } else {
            // PiP isn't supported by the current device. Disable the PiP button.
            pipButton.isEnabled = false
        }
    }
}

// MARK: - AVPictureInPictureControllerDelegate

extension VideoPlayerControlViewController: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("stop pip")
        let isPaused = player?.state.isPaused ?? true
        if isPaused {
            player?.pause()
        }
        setAllControlComponents(hidden: false)
        cancelAllControlComponentsAutoHide()
    }

    func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        print("start pip")
    }

    func pictureInPictureControllerWillStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        isPipModeEnabled = false
        videoPlayerView?.isHidden = false
        containerView.isHidden = false
        pipContainerView.isHidden = true
    }

    func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        videoPlayerView?.isHidden = true
        containerView.isHidden = true
        pipContainerView.isHidden = false
        isPipModeEnabled = true
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error) {
        print(error.localizedDescription)
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(true)
    }
}
