//
//  TimeInterval+Second.swift
//  Example
//
//  Created by shiwei on 2020/11/18.
//

import Foundation

extension TimeInterval {
    var timeSecond: String {
        let second = Int(self)
        if second < 60 {
            return String(format: "00:%02d", second)
        } else if second >= 60 && second < 3600 {
            return String(format: "%02d:%02d", second / 60, second % 60)
        } else {
            return String(format: "%02d:%02d:%02d", second / 3600, second % 3600 / 60, second % 60)
        }
    }
}
