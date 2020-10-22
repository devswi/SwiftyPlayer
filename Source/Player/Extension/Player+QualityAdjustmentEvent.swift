//
//  Player+QualityAdjustmentEvent.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/4.
//

import AVFoundation

extension Player {

    /// 切换资源质量事件
    ///
    /// - Parameters:
    ///   - producer: 事件发生器
    ///   - event: 资源切换事件 `QualityAdjustmentEventProducer.QualityAdjustmentEvent`
    func handleQualityEvent(
        from producer: EventProducer,
        with event: QualityAdjustmentEventProducer.QualityAdjustmentEvent
    ) {
        guard adjustQualityAutomatically, let quality = retrieveQuality(isGoUp: event == .goUp)
        else { return }

        changeQuality(to: quality)
    }

    func updatePlayerItemForBufferingStrategy(_ playerItem: AVPlayerItem) {
        playerItem.preferredForwardBufferDuration = preferredForwardBufferDuration
    }

    private func changeQuality(to newQuality: PlayableQuality) {
        guard let url = currentItem?.itemResources[newQuality]?.resourceURL else { return }

        let cip = currentItemProgression
        let item = AVPlayerItem(url: url)
        self.updatePlayerItemForBufferingStrategy(item)

        qualityIsBeingChanged = true
        avPlayerItem = item // replace current av player
        if let cip = cip {
            player?.seek(to: CMTime(timeInterval: cip))
        }
        qualityIsBeingChanged = false

        currentQuality = newQuality
    }

    private func retrieveQuality(isGoUp: Bool) -> PlayableQuality? {
        guard let currentItem = currentItem else { return nil }
        let keys = currentItem.itemResources.keys.sorted { $0.rawValue < $1.rawValue }

        guard let index = keys.firstIndex(of: currentQuality) else { return nil }
        if isGoUp {
            if (index + 1) < keys.count {
                return keys[index + 1]
            }
        } else {
            if (index - 1) >= 0 {
                return keys[index - 1]
            }
        }

        return nil
    }

}
