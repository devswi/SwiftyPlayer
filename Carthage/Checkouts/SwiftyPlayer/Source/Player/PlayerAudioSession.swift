//
//  PlayerAudioSession.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/9/25.
//

import AVFoundation
import AVKit

/// 对 AVAudioSession 的映射
///
/// 统一对 AVAudioSession 的设置
public class PlayerAudioSession: NSObject {

    var category: AVAudioSession.Category = .playback
    var mode: AVAudioSession.Mode = .default
    var options: AVAudioSession.CategoryOptions = []
    var activeOptions: AVAudioSession.SetActiveOptions = .notifyOthersOnDeactivation

    /// 对 AVAudioSession.Category 的映射，命名与使用场景与系统保持一致
    public struct Category: Hashable, Equatable, RawRepresentable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    /// 对 AVAudioSession.Mode 的映射，命名与使用场景与系统保持一致
    public struct Mode: Hashable, Equatable, RawRepresentable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    /// 对 AVAudioSession.CategoryOptions 的映射，命名与使用场景与系统保持一致
    public struct CategoryOptions: OptionSet {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
    }

    /// 设置 PlayerAudioSession 的 category/mode/options，本质是对 AVAudioSession 单例的修改
    ///
    /// - Parameters:
    ///   - category: PlayerAudioSession.Category 同 AVAudioSession.Category
    ///   - mode: PlayerAudioSession.Mode 同 AVAudioSession.Mode
    ///   - options: PlayerAudioSession.CategoryOptions 同 AVAudioSession.CategoryOptions
    ///   - notifyOthersOnDeactivation: 是否在取消 active 状态时通知其他 App
    func setCategory(
        _ category: PlayerAudioSession.Category,
        mode: PlayerAudioSession.Mode,
        options: PlayerAudioSession.CategoryOptions,
        notifyOthersOnDeactivation: Bool
    ) {
        // category
        self.category = PlayerAudioSession.Category.systemCategory(from: category)
        self.mode = PlayerAudioSession.Mode.systemMode(from: mode)
        self.options = PlayerAudioSession.CategoryOptions.systemOptions(from: options)
        // notifyOthersOnDeactivation
        var options: AVAudioSession.SetActiveOptions = []
        if notifyOthersOnDeactivation {
            options.insert(.notifyOthersOnDeactivation)
        }
        self.activeOptions = options
    }

    /// 设置 AudioSession 的激活与否，本质是对 AVAudioSession 单例的修改
    ///
    /// - Parameter active: 是否激活当前 app 的 audio session
    func setActive(_ active: Bool) throws {
        let session = AVAudioSession.sharedInstance()
        if #available(iOS 11, *) {
            try session.setCategory(category, mode: mode, policy: .default, options: options)
        } else {
            try session.setCategory(category, mode: mode, options: options)
        }
        try session.setActive(active, options: activeOptions)
    }

}

extension PlayerAudioSession.Category {
    /// 只支持音频播放，会随着静音键和屏幕关闭而静音，并且不会中断其他应用的音频播放，无法后台播放
    public static let ambient = PlayerAudioSession.Category(rawValue: AVAudioSession.Category.ambient.rawValue)

    /// 系统默认 Category，与 ambient 类似，不同之处在于会中断其他应用的音频播放，无法后台播放
    public static let soloAmbient = PlayerAudioSession.Category(rawValue: AVAudioSession.Category.soloAmbient.rawValue)

    /// 只支持播放，不会随着静音键和屏幕关闭而静音，可在后台播放
    public static let playback = PlayerAudioSession.Category(rawValue: AVAudioSession.Category.playback.rawValue)

    /// 只提供单纯的录音功能，不支持播放
    public static let record = PlayerAudioSession.Category(rawValue: AVAudioSession.Category.record.rawValue)

    /// 提供录音和播放功能，音频默认输出为听筒（在没有其他外界设备的情况下）
    public static let playAndRecord = PlayerAudioSession.Category(
        rawValue: AVAudioSession.Category.playAndRecord.rawValue
    )

    /// 支持音频播放和录制，允许多条音频流不同输入和输出（例如通过不同端口同时输出音频）
    public static let multiRoute = PlayerAudioSession.Category(rawValue: AVAudioSession.Category.multiRoute.rawValue)

    fileprivate static func systemCategory(from category: PlayerAudioSession.Category) -> AVAudioSession.Category {
        AVAudioSession.Category(rawValue: category.rawValue)
    }
}

extension PlayerAudioSession.Mode {
    /// 默认使用场景
    public static let `default` = PlayerAudioSession.Mode(rawValue: AVAudioSession.Mode.default.rawValue)

    /// 支持网络电话
    public static let voiceChat = PlayerAudioSession.Mode(rawValue: AVAudioSession.Mode.voiceChat.rawValue)

    /// 适用于游戏类应用，支持使用 GameKit 使用的语音聊天服务
    public static let gameChat = PlayerAudioSession.Mode(rawValue: AVAudioSession.Mode.gameChat.rawValue)

    /// 视频录像
    public static let videoRecording = PlayerAudioSession.Mode(rawValue: AVAudioSession.Mode.videoRecording.rawValue)

    /// 正在执行音频输入或输出的测量
    public static let measurement = PlayerAudioSession.Mode(rawValue: AVAudioSession.Mode.measurement.rawValue)

    /// 一种模式，指示您的应用正在播放电影内容。
    public static let moviePlayback = PlayerAudioSession.Mode(rawValue: AVAudioSession.Mode.moviePlayback.rawValue)

    /// 表明 App 支持在线视频会议
    public static let videoChat = PlayerAudioSession.Mode(rawValue: AVAudioSession.Mode.videoChat.rawValue)

    /// 一种用于连续语音音频的模式，当另一个应用播放简短的音频提示时暂停音频。
    public static let spokenAudio = PlayerAudioSession.Mode(rawValue: AVAudioSession.Mode.spokenAudio.rawValue)

    /// 文字转语音
    @available(iOS 12.0, *)
    public static let voicePrompt = PlayerAudioSession.Mode(rawValue: AVAudioSession.Mode.voicePrompt.rawValue)

    fileprivate static func systemMode(from mode: PlayerAudioSession.Mode) -> AVAudioSession.Mode {
        AVAudioSession.Mode(rawValue: mode.rawValue)
    }
}

extension PlayerAudioSession.CategoryOptions {
    /// 支持与其他 App 音频混合
    public static var mixWithOthers = PlayerAudioSession.CategoryOptions(
        rawValue: AVAudioSession.CategoryOptions.mixWithOthers.rawValue
    )

    /// 当前 App 播放资源时，调低其他 App 的音频音量
    public static var duckOthers = PlayerAudioSession.CategoryOptions(
        rawValue: AVAudioSession.CategoryOptions.duckOthers.rawValue
    )

    /// 支持蓝牙音频输入
    public static var allowBluetooth = PlayerAudioSession.CategoryOptions(
        rawValue: AVAudioSession.CategoryOptions.allowBluetooth.rawValue
    )

    /// 设置默认输出音频为扬声器
    public static var defaultToSpeaker = PlayerAudioSession.CategoryOptions(
        rawValue: AVAudioSession.CategoryOptions.defaultToSpeaker.rawValue
    )

    /// 如果音频是断断续续出现的，例如导航应用，设置此 Options
    public static var interruptSpokenAudioAndMixWithOthers = PlayerAudioSession.CategoryOptions(
        rawValue: AVAudioSession.CategoryOptions.interruptSpokenAudioAndMixWithOthers.rawValue
    )

    /// 支持 Advanced Audio Distribution Profile (A2DP) 蓝牙音频输入
    public static var allowBluetoothA2DP = PlayerAudioSession.CategoryOptions(
        rawValue: AVAudioSession.CategoryOptions.allowBluetoothA2DP.rawValue
    )

    /// 允许音频串流到 AirPlay 设备
    public static var allowAirPlay = PlayerAudioSession.CategoryOptions(
        rawValue: AVAudioSession.CategoryOptions.allowAirPlay.rawValue
    )

    fileprivate static func systemOptions(
        from options: PlayerAudioSession.CategoryOptions
    ) -> AVAudioSession.CategoryOptions {
        var freeOptions: AVAudioSession.CategoryOptions = []
        if options.contains(.mixWithOthers) {
            freeOptions.insert(.mixWithOthers)
        }
        if options.contains(.duckOthers) {
            freeOptions.insert(.duckOthers)
        }
        if options.contains(.allowBluetooth) {
            freeOptions.insert(.allowBluetooth)
        }
        if options.contains(.defaultToSpeaker) {
            freeOptions.insert(.defaultToSpeaker)
        }
        if options.contains(.interruptSpokenAudioAndMixWithOthers) {
            freeOptions.insert(.interruptSpokenAudioAndMixWithOthers)
        }
        if options.contains(.allowBluetoothA2DP) {
            freeOptions.insert(.allowBluetoothA2DP)
        }
        if options.contains(.allowAirPlay) {
            freeOptions.insert(.allowAirPlay)
        }
        return freeOptions
    }
}
