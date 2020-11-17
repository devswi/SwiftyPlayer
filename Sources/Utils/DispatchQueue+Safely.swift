//
//  DispatchQueue+Safely.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/10/27.
//

import Foundation

extension DispatchQueue {
    func safeAsync(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else if self == DispatchQueue.main {
            async { block() }
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}
