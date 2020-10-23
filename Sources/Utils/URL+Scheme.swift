//
//  URL+Scheme.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/11.
//

import Foundation

extension URL {
    func withScheme(_ scheme: String) -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.scheme = scheme
        return components?.url
    }
}
