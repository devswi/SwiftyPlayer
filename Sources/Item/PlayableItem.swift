//
//  PlayableItem.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/2.
//

import AVFoundation
import MediaPlayer
import UIKit

public class PlayableItem: NSObject, Playable {

    public let itemResources: [PlayableQuality: ResourceConvertible]

    @objc
    public dynamic var artist: String?

    @objc
    public dynamic var title: String?

    @objc
    public dynamic var album: String?

    @objc
    public dynamic var trackCount: NSNumber?

    @objc
    public dynamic var trackNumber: NSNumber?

    @objc
    public dynamic var artwork: MPMediaItemArtwork?

    public var artworkImageSize: CGSize?

    public required init?(itemResources: [PlayableQuality: ResourceConvertible]) {
        if itemResources.isEmpty {
            return nil
        }
        self.itemResources = itemResources
        super.init()
    }

    public subscript(
        _ quality: PlayableQuality,
        default defaultValue: @autoclosure () -> ResourceConvertible
    ) -> ResourceConvertible {
        itemResources[quality, default: defaultValue()]
    }

    public subscript(_ quality: PlayableQuality) -> ResourceConvertible? {
        itemResources[quality]
    }

}
