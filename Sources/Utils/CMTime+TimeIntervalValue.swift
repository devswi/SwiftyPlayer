//
//  CMTime+TimeIntervalValue.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/4.
//

import CoreMedia

extension CMTime {

    init(timeInterval: TimeInterval) {
        self.init(seconds: timeInterval, preferredTimescale: 1000000000)
    }

    var timeIntervalValue: TimeInterval? {
        if flags.contains(.valid) {
            let seconds = CMTimeGetSeconds(self)
            if !seconds.isNaN {
                return TimeInterval(seconds)
            }
        }
        return nil
    }

}
