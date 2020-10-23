//
//  VideoPlayerView.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/12.
//

import AVFoundation
import UIKit

open class VideoPlayerView: UIView {

    open override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    public var playerLayer: AVPlayerLayer {
        (layer as? AVPlayerLayer) ?? AVPlayerLayer()
    }

    var avPlayer: AVPlayer? {
        get {
            playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }

}
