//
//  URL+Offline.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/4.
//

import Foundation

extension URL {
    var isOfflineURL: Bool {
        isFileURL || scheme == "ipod-library" || host == "localhost" || host == "127.0.0.1"
    }
}
