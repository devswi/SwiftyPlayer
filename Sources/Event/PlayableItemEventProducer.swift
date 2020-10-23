//
//  PlayableItemEventProducer.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/2.
//

import Foundation

class PlayableItemEventProducer: NSObject, EventProducer {

    /// `PlayableItemEvent` 当前播放 item 信息变化事件
    ///
    /// - artistUpdated: `artist` was updated.
    /// - titleUpdated: `title` was updated.
    /// - albumUpdated: `album` was updated.
    /// - trackCountUpdated: `trackCount` was updated.
    /// - trackNumberUpdated: `trackNumber` was updated.
    /// - artworkUpdated: `artwork` was updated.
    enum PlayableItemEvent: String, CaseIterable, Event {
        case artistUpdated = "artist"
        case titleUpdated = "title"
        case albumUpdated = "album"
        case trackCountUpdated = "trackCount"
        case trackNumberUpdated = "trackNumber"
        case artworkUpdated = "artwork"
    }

    var cachedObservation: [String: NSKeyValueObservation?] = [:]

    var item: PlayableItem? {
        willSet {
            stopProducingEvents()
        }
    }

    weak var eventListener: EventListener?

    /// 当前事件发生器是否正在监听
    private var listening = false

    /// 析构时停止监听
    deinit {
        stopProducingEvents()
    }

    /// 开始监听
    func startProducingEvents() {
        guard let item = item, !listening else {
            return
        }

        // Observing PlayableItem's property
        for event in PlayableItemEvent.allCases {
            retrieveObservation(for: event, item: item)
        }

        listening = true
    }

    /// 停止监听
    func stopProducingEvents() {
        // Unobserving PlayableItem's property
        for event in PlayableItemEvent.allCases {
            cachedObservation[event.rawValue].flatMap { $0 }?.invalidate()
        }

        listening = false
    }

    private func retrieveObservation(for event: PlayableItemEvent, item: PlayableItem) {
        guard cachedObservation[event.rawValue] == nil else { return }
        let observation: NSKeyValueObservation?
        switch event {
        case .artistUpdated:
            observation = item.observe(\.artist, options: .new) { [weak eventListener, weak self] _, _  in
                guard let self = self else { return }
                eventListener?.onEvent(event, generateBy: self)
            }
        case .titleUpdated:
            observation = item.observe(\.title, options: .new) { [weak eventListener, weak self] _, _ in
                guard let self = self else { return }
                eventListener?.onEvent(event, generateBy: self)
            }
        case .albumUpdated:
            observation = item.observe(\.album, options: .new) { [weak eventListener, weak self] _, _ in
                guard let self = self else { return }
                eventListener?.onEvent(event, generateBy: self)
            }
        case .trackCountUpdated:
            observation = item.observe(\.trackNumber, options: .new) { [weak eventListener, weak self] _, _ in
                guard let self = self else { return }
                eventListener?.onEvent(event, generateBy: self)
            }
        case .trackNumberUpdated:
            observation = item.observe(\.trackNumber, options: .new) { [weak eventListener, weak self] _, _ in
                guard let self = self else { return }
                eventListener?.onEvent(event, generateBy: self)
            }
        case .artworkUpdated:
            observation = item.observe(\.artwork, options: .new) { [weak eventListener, weak self] _, _ in
                guard let self = self else { return }
                eventListener?.onEvent(event, generateBy: self)
            }
        }
        cachedObservation[event.rawValue] = observation
    }

}
