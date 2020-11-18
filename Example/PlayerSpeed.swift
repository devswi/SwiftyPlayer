//
//  PlayerSpeed.swift
//  Example
//
//  Created by shiwei on 2020/11/18.
//

import UIKit

struct PlayerSpeed {
    static let x0_5 = PlayerSpeed(0.5, "<fractions>0.5</fractions><small>x</small>")
    static let x0_75 = PlayerSpeed(0.75, "<fractions>0.75</fractions><small>x</small>")
    static let x1 = PlayerSpeed(1, "<fractions>1</fractions><small>x</small>")
    static let x1_25 = PlayerSpeed(1.25, "<fractions>1.25</fractions><small>x</small>")
    static let x1_5 = PlayerSpeed(1.5, "<fractions>1.5</fractions><small>x</small>")
    static let x2 = PlayerSpeed(2, "<fractions>2</fractions><small>x</small>")

    var attributedString: NSAttributedString? {
        cache[value]
    }

    private var cache: [Float: NSAttributedString] = [:]
    private(set) var value: Float

    private static let speedOptions: [PlayerSpeed] = [
        x0_5,
        x0_75,
        x1,
        x1_25,
        x1_5,
        x2,
    ]

    init(_ value: Float, _ text: String) {
        self.value = value
        let speed = NSMutableAttributedString(
            string: "\(value)",
            attributes: [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            ]
        )
        speed.append(
            NSAttributedString(
                string: "x",
                attributes: [
                    .foregroundColor: UIColor.white,
                    .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                ]
            )
        )
        cache[value] = speed
    }

    func nextSpeed() -> PlayerSpeed {
        let index = PlayerSpeed.speedOptions.firstIndex { $0.value == self.value } ?? 1
        let nextIndex = (index + 1) == PlayerSpeed.speedOptions.count ? 0 : (index + 1)
        let nextSpeed = PlayerSpeed.speedOptions[nextIndex]
        return nextSpeed
    }
}
