//
//  VideoPlayerGravity.swift
//  SwiftyPlayer
//
//  Created by 施伟 on 2020/9/28.
//

import AVFoundation

public struct VideoPlayerGravity: Hashable, Equatable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension VideoPlayerGravity {
    /// 保留长宽比，在 layer 中自适应
    public static let resizeAspect = VideoPlayerGravity(rawValue: AVLayerVideoGravity.resizeAspect.rawValue)

    /// 保留长宽比，填充满 layer
    public static let resizeAspectFill = VideoPlayerGravity(rawValue: AVLayerVideoGravity.resizeAspectFill.rawValue)

    /// 拉伸以填满 layer
    public static let resize = VideoPlayerGravity(rawValue: AVLayerVideoGravity.resize.rawValue)
}
