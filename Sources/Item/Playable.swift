//
//  Playable.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/2.
//

import AVFoundation
import MediaPlayer
import UIKit

/// `PlayableQuality`
public struct PlayableQuality: Hashable, Equatable, RawRepresentable {

    public let rawValue: UInt

    public init(_ rawValue: UInt) {
        self.rawValue = rawValue
    }

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
}

extension PlayableQuality {

    public static let low = PlayableQuality(rawValue: 0)

    public static let medium = PlayableQuality(rawValue: 500)

    public static let high = PlayableQuality(rawValue: 999)

}

public typealias ItemResource = (quality: PlayableQuality, resource: ResourceConvertible?)

public protocol Playable: AnyObject, Equatable {

    var itemResources: [PlayableQuality: ResourceConvertible] { get }

    // MARK: Additional properties

    /// The artist of the item.
    ///
    /// This can change over time which is why the property is dynamic. It enables KVO on the property.
    dynamic var artist: String? { get set }

    /// The title of the item.
    ///
    /// This can change over time which is why the property is dynamic. It enables KVO on the property.
    dynamic var title: String? { get set }

    /// The album of the item.
    ///
    /// This can change over time which is why the property is dynamic. It enables KVO on the property.
    dynamic var album: String? { get set }

    /// The track count of the item's album.
    ///
    /// This can change over time which is why the property is dynamic. It enables KVO on the property.
    dynamic var trackCount: NSNumber? { get set }

    /// The track number of the item in this album.
    ///
    /// This can change over time which is why the property is dynamic. It enables KVO on the property.
    dynamic var trackNumber: NSNumber? { get set }

    /// The artwork image of the item.
    ///
    /// This can change over time which is why the property is dynamic. It enables KVO on the property.
    dynamic var artwork: MPMediaItemArtwork? { get set }

    /// The artwork image of the item.
    var artworkImage: UIImage? { get set }

    var artworkImageSize: CGSize? { get set }

    init?(itemResources: [PlayableQuality: ResourceConvertible])

    func url(for quality: PlayableQuality) -> ItemResource

}

extension Playable {

    public var artworkImage: UIImage? {
        get {
            artwork?.image(at: artworkImageSize ?? CGSize(width: 512, height: 512))
        }
        set {
            artworkImageSize = newValue?.size
            artwork = newValue.map { image in
                MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            }
        }
    }

    public func url(for quality: PlayableQuality) -> ItemResource {
        (quality: quality, resource: itemResources[quality])
    }

    public func parseMetadata(_ items: [AVMetadataItem]) {
        items.forEach {
            if let commonKey = $0.commonKey {
                switch commonKey {
                case .commonKeyTitle where title == nil:
                    title = $0.value as? String
                case .commonKeyArtist where artist == nil:
                    artist = $0.value as? String
                case .commonKeyAlbumName where album == nil:
                    album = $0.value as? String
                case .id3MetadataKeyTrackNumber where trackNumber == nil:
                    trackNumber = $0.value as? NSNumber
                case .commonKeyArtwork where artwork == nil:
                    artworkImage = ($0.value as? Data).flatMap { UIImage(data: $0) }
                default:
                    break
                }
            }
        }
    }

    // Equatable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        let lhsKeys = lhs.itemResources.keys
        let rhsKeys = rhs.itemResources.keys
        // `itemResources`'s keys not equal
        if lhsKeys.count != rhsKeys.count { return false }
        return lhsKeys.allSatisfy {
            lhs.itemResources[$0]?.fileName == rhs.itemResources[$0]?.fileName
        }
    }

}
