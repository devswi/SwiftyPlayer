//
//  PlayerAudioTimePitchAlgorithm.swift
//  SwiftyPlayer
//
//  Created by 施伟 on 2020/9/27.
//

import AVFoundation

public struct PlayerAudioTimePitchAlgorithm: Hashable, Equatable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension PlayerAudioTimePitchAlgorithm {
    /// 质量低，计算成本低，适用于短暂的快进/快退
    ///
    /// AVFoundation 中的默认属性
    public static let lowQualityZeroLatency = PlayerAudioTimePitchAlgorithm(
        rawValue: AVAudioTimePitchAlgorithm.lowQualityZeroLatency.rawValue
    )

    /// 质量适中，计算成本低，使用于短声音
    ///
    /// SwiftyPlayer 中的默认
    public static let timeDomain = PlayerAudioTimePitchAlgorithm(
        rawValue: AVAudioTimePitchAlgorithm.timeDomain.rawValue
    )

    /// 最高质量，计算成本最高，适合音乐
    public static let spectral = PlayerAudioTimePitchAlgorithm(
        rawValue: AVAudioTimePitchAlgorithm.spectral.rawValue
    )

    /// 高质量，无音高校正，音高随速率变化（用这个，快进会高音、慢进会低音）
    public static let varispeed = PlayerAudioTimePitchAlgorithm(
        rawValue: AVAudioTimePitchAlgorithm.varispeed.rawValue
    )
}
