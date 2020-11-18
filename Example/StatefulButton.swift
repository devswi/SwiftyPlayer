//
//  StatefulButton.swift
//  Example
//
//  Created by shiwei on 2020/11/18.
//

import UIKit

class StatefulButton: UIButton {
    var isActive: Bool = false {
        didSet {
            setImage(isActive ? activeImage : inactiveImage, for: .normal)
        }
    }

    var activeImage: UIImage?
    var inactiveImage: UIImage? {
        didSet {
            setImage(inactiveImage, for: .normal)
        }
    }
}

