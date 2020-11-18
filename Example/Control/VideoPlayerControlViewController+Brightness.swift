//
//  VideoPlayerControlViewController+Brightness.swift
//  Example
//
//  Created by shiwei on 2020/11/18.
//

import UIKit

extension VideoPlayerControlViewController {

    func beginSettingBrightness() {
        guard brightnessView.alpha == 0 else {
            return
        }
        brightnessAnimation(false)
    }

    func setBrightness(_ translationY: CGFloat) {
        var brightness = UIScreen.main.brightness
        if translationY < 0 { // 向上
            brightness += bvTolerance
        } else {
            brightness -= bvTolerance
        }
        brightnessProgressView.setProgress(Float(brightness), animated: true)
        UIScreen.main.brightness = brightness
    }

    func stopSettingBrightness() {
        guard brightnessView.alpha == 1 else {
            return
        }
        brightnessAnimation(true)
    }

    private func brightnessAnimation(_ isHidden: Bool) {
        UIView.animate(withDuration: 0.3) { [self] in
            brightnessView.alpha = isHidden ? 0.0 : 1.0
        }
    }

}
