//
//  PlayerState.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/3.
//

import Foundation

/// `Player` 可能产生的错误类型
///
/// - maximumRetryCountHit: 达到了最大重试次数
/// - foundationError: `AVPlayer` 播放报错
/// - itemNotConsideredPlayable: 当前播放的 item 被认定为无法播放
/// - noItemConsideredPlayable: 当前队列中没有可播放的 item
public enum PlayerError: Error {
    case maximumRetryCountHit
    case foundationError(Error)
    case itemNotConsideredPlayable
    case noItemConsideredPlayable
}

/// `PlayerState` 是 `Player` 可能的状态
///
/// - buffering: 缓存中
/// - playing: 播放中
/// - paused: 暂停中
/// - stopped: 被终止
/// - waitingForConnection: 等待网络连接
/// - failed: 播放报错
public enum PlayerState {
    case buffering
    case playing
    case paused
    case stopped
    case waitingForConnection
    case failed(PlayerError)

    /// 是否在缓存中
    public var isBuffering: Bool {
        if case .buffering = self {
            return true
        }
        return false
    }

    /// 是否在播放中
    public var isPlaying: Bool {
        if case .playing = self {
            return true
        }
        return false
    }

    /// 是否被暂停
    public var isPaused: Bool {
        if case .paused = self {
            return true
        }
        return false
    }

    /// 是否被中断
    public var isStopped: Bool {
        if case .stopped = self {
            return true
        }
        return false
    }

    /// 是否在等待网络连接
    public var isWaitingForConnection: Bool {
        if case .waitingForConnection = self {
            return true
        }
        return false
    }

    /// 是否播放失败
    public var isFailed: Bool {
        if case .failed = self {
            return true
        }
        return false
    }

    /// 当前播放失败的错误信息
    public var error: PlayerError? {
        if case .failed(let error) = self {
            return error
        }
        return nil
    }
}

extension PlayerState: Equatable {
    public static func == (lhs: PlayerState, rhs: PlayerState) -> Bool {
        if (lhs.isBuffering && rhs.isBuffering)
            || (lhs.isPlaying && rhs.isPlaying)
            || (lhs.isPaused && rhs.isPaused)
            || (lhs.isStopped && rhs.isStopped)
            || (lhs.isWaitingForConnection && rhs.isWaitingForConnection) {
            return true
        }
        if let e1 = lhs.error, let e2 = rhs.error {
            switch (e1, e2) {
            case (.maximumRetryCountHit, .maximumRetryCountHit):
                return true
            case (.foundationError, .foundationError):
                return true
            default:
                return false
            }
        }
        return false
    }
}
