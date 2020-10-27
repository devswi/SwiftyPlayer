//
//  Player+RemoteCommand.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/9/22.
//

import AVFoundation
import MediaPlayer

public struct RemoteCommandOptions: OptionSet, Hashable {

    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

}

extension RemoteCommandOptions {

    public static let play = RemoteCommandOptions(rawValue: 1 << 0)

    public static let pause = RemoteCommandOptions(rawValue: 1 << 1)

    public static let previousTrack = RemoteCommandOptions(rawValue: 1 << 2)

    public static let nextTrack = RemoteCommandOptions(rawValue: 1 << 3)

    public static let stop = RemoteCommandOptions(rawValue: 1 << 4)

    public static let changePlaybackPosition = RemoteCommandOptions(rawValue: 1 << 5)

    public static let all: RemoteCommandOptions = [
        .play,
        .pause,
        .previousTrack,
        .nextTrack,
        .stop,
        .changePlaybackPosition,
    ]

}

// MARK: Remote Command

extension Player {
    /// 设置远程控制指令
    ///
    /// 默认了支持播放/暂停/上一首/下一首/修改播放进度
    ///
    /// 如果想要实现自定义的面板，可以在 `MPRemoteCommandCenter` 单例中自定义
    func setupRemoteCommand() {
        let commandCenter = MPRemoteCommandCenter.shared()
        setupRemoteCommand(
            .play,
            command: commandCenter.playCommand
        ) { [unowned self] _ -> MPRemoteCommandHandlerStatus in
            let isPaused = self.state.isPaused
            if isPaused {
                self.resume()
                return .success
            }
            return .commandFailed
        }
        setupRemoteCommand(
            .pause,
            command: commandCenter.pauseCommand
        ) { [unowned self] _ -> MPRemoteCommandHandlerStatus in
            let isPlaying = self.state.isPlaying
            if isPlaying {
                self.pause()
                return .success
            }
            return .commandFailed
        }
        setupRemoteCommand(
            .previousTrack,
            command: commandCenter.previousTrackCommand
        ) { [unowned self] _ -> MPRemoteCommandHandlerStatus in
            if self.hasPrevious {
                self.previous()
                return .success
            }
            return .commandFailed
        }
        setupRemoteCommand(
            .nextTrack,
            command: commandCenter.nextTrackCommand
        ) { [unowned self] _ -> MPRemoteCommandHandlerStatus in
            if self.hasNext {
                self.next()
                return .success
            }
            return .commandFailed
        }
        setupRemoteCommand(
            .stop,
            command: commandCenter.stopCommand
        ) { [unowned self] _ -> MPRemoteCommandHandlerStatus in
            if self.player != nil {
                self.stop()
                return .success
            }
            return .commandFailed
        }
        setupRemoteCommand(
            .changePlaybackPosition,
            command: commandCenter.changePlaybackPositionCommand
        ) { [unowned self] event -> MPRemoteCommandHandlerStatus in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.player?.seek(to: CMTime(timeInterval: event.positionTime)) { [weak self] success in
                guard let self = self else { return }
                if success {
                    self.player?.rate = self.rate
                    self.updateNowPlayingInfoCenter()
                }
            }
            return .success
        }

        DispatchQueue.main.safeAsync {
            // Register to receive events
            UIApplication.shared.beginReceivingRemoteControlEvents()
        }
    }

    private func setupRemoteCommand(
        _ option: RemoteCommandOptions,
        command: MPRemoteCommand,
        handler: @escaping (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
    ) {
        guard remoteCommandOptions.contains(option)
        else {
            if let target = remoteCommandCache[option] {
                command.removeTarget(target)
                remoteCommandCache[option] = nil
            }
            return
        }
        if remoteCommandCache[option] == nil {
            let target = command.addTarget(handler: handler)
            remoteCommandCache[option] = target
        }
    }
}
