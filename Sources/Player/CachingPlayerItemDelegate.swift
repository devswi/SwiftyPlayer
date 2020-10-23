//
//  CachingPlayerItemDelegate.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/11.
//

import AVFoundation
import Foundation

protocol CachingPlayerItemDelegate: AnyObject {

    func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data)

    func playerItem(
        _ playerItem: CachingPlayerItem,
        didDownloadBytesSoFar bytesDownloaded: Int,
        outOf bytesExpected: Int
    )

    func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error)

}

extension CachingPlayerItemDelegate {

    func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data) { }

    func playerItem(
        _ playerItem: CachingPlayerItem,
        didDownloadBytesSoFar bytesDownloaded: Int,
        outOf bytesExpected: Int
    ) { }

    func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error) { }

}
