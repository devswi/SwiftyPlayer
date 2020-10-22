//
//  MPNowPlayingInfoCenter+PlayableItem.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/4.
//

import MediaPlayer

extension MPNowPlayingInfoCenter {

    func update(with item: PlayableItem, duration: TimeInterval?, progression: TimeInterval?, playbackRate: Float) {
        var info = [String: Any]()
        if let title = item.title {
            info[MPMediaItemPropertyTitle] = title
        }
        if let artist = item.artist {
            info[MPMediaItemPropertyArtist] = artist
        }
        if let album = item.album {
            info[MPMediaItemPropertyAlbumTitle] = album
        }
        if let trackCount = item.trackCount {
            info[MPMediaItemPropertyAlbumTrackCount] = trackCount
        }
        if let trackNumber = item.trackNumber {
            info[MPMediaItemPropertyAlbumTrackNumber] = trackNumber
        }
        if let artwork = item.artwork {
            info[MPMediaItemPropertyArtwork] = artwork
        }
        if let duration = duration {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }
        if let progression = progression {
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = progression
        }
        info[MPNowPlayingInfoPropertyPlaybackRate] = playbackRate

        nowPlayingInfo = info
    }

}
