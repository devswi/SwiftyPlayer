//
//  ResourceConvertible.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/2.
//

import Foundation

/// Represents an media resource at a certain url and a given file name.
public protocol ResourceConvertible {

    /// The target media url.
    var resourceURL: URL { get }

    /// The file name used in cached.
    var fileName: String { get }
}

/// URL conforms to `ResourceConvertible` in SwiftyPlayer.
/// The `lastPatgComponent` of this url is used as `fileName`. And the url itself will be used as `resourceURL`
/// If you need customize the url and/or file name, use `MediaResource` instead.
extension URL: ResourceConvertible {
    public var resourceURL: URL { self }
    public var fileName: String { resourceURL.lastPathComponent }
}

/// Resource is a simple combination of `resourceURL` and `fileName`.
public struct MediaResource: ResourceConvertible {

    /// Creates an media resource.
    ///
    /// - Parameters:
    ///   - resourceURL: The target media URL from where the image can be played.
    ///   - fileName: The file name. If `nil`,
    ///               SwiftyPlayer will use the `lastPathComponent` of `resourceURL` as the file name.
    public init(resourceURL: URL, fileName: String? = nil) {
        self.resourceURL = resourceURL
        self.fileName = fileName ?? resourceURL.lastPathComponent
    }

    /// The file name used in cached.
    public let resourceURL: URL

    /// The target media url.
    public let fileName: String

}
