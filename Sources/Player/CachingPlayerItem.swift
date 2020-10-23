//
//  CachingPlayerItem.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/11.
//

import AVFoundation
import Foundation

class CachingPlayerItem: AVPlayerItem {

    let resourceLoaderProcessor = ResourceLoaderProcessor()
    let url: URL
    let initialScheme: String?
    var fileExtension: String?

    weak var delegate: CachingPlayerItemDelegate?

    private let cachingPlayerItemScheme = "com.shanbay.media.scheme"

    init?(url: URL, fileExtension: String? = nil) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let scheme = components.scheme,
              var urlWithCustomScheme = url.withScheme(cachingPlayerItemScheme)
        else { return nil }

        self.url = url
        self.initialScheme = scheme
        if let ext = fileExtension {
            urlWithCustomScheme.deletePathExtension()
            urlWithCustomScheme.appendPathComponent(ext)
            self.fileExtension = ext
        }

        let asset = AVURLAsset(url: urlWithCustomScheme)
        asset.resourceLoader.setDelegate(resourceLoaderProcessor, queue: DispatchQueue.main)
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)

        resourceLoaderProcessor.owner = self
    }

    init?(data: Data, mimeType: String, fileExtension: String) {
        guard let fakeUrl = URL(string: cachingPlayerItemScheme + "://whatever/file.\(fileExtension)")
        else {
            return nil
        }

        self.url = fakeUrl
        self.initialScheme = nil

        resourceLoaderProcessor.mediaData = data
        resourceLoaderProcessor.isPlayingFromData = true
        resourceLoaderProcessor.mimeType = mimeType

        let asset = AVURLAsset(url: fakeUrl)
        asset.resourceLoader.setDelegate(resourceLoaderProcessor, queue: DispatchQueue.main)
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
        resourceLoaderProcessor.owner = self
    }

    func download() {
        if resourceLoaderProcessor.session == nil {
            resourceLoaderProcessor.startDataRequest(with: url)
        }
    }

}
