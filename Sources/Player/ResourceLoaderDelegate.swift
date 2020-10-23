//
//  ResourceLoaderDelegate.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/11.
//

import AVFoundation
import Foundation

class ResourceLoaderProcessor: NSObject {

    var isPlayingFromData = false
    var mimeType: String?
    var session: URLSession?
    var mediaData: Data?
    var response: URLResponse?
    var pendingRequests = Set<AVAssetResourceLoadingRequest>()
    weak var owner: CachingPlayerItem?

    func startDataRequest(with url: URL) {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        session?.dataTask(with: url).resume()
    }

    func processPendingRequests() {
        let requestFulfilled = Set<AVAssetResourceLoadingRequest>(pendingRequests.compactMap {
            self.fillInContentInformationRequest($0.contentInformationRequest)
            if self.haveEnoughDataToFulfillRequest($0.dataRequest) {
                $0.finishLoading()
                return $0
            }
            return nil
        })

        _ = requestFulfilled.map { self.pendingRequests.remove($0) }
    }

    func fillInContentInformationRequest(
        _ contentInformationRequest: AVAssetResourceLoadingContentInformationRequest?) {
        if isPlayingFromData, let mediaData = mediaData {
            contentInformationRequest?.contentType = mimeType
            contentInformationRequest?.contentLength = Int64(mediaData.count)
            contentInformationRequest?.isByteRangeAccessSupported = true
            return
        }

        guard let responseUnwrapped = response
        else {
            // have no response from the server yet
            return
        }

        contentInformationRequest?.contentType = responseUnwrapped.mimeType
        contentInformationRequest?.contentLength = responseUnwrapped.expectedContentLength
        contentInformationRequest?.isByteRangeAccessSupported = true
    }

    func haveEnoughDataToFulfillRequest(_ dataRequest: AVAssetResourceLoadingDataRequest?) -> Bool {
        guard let dataRequest = dataRequest
        else {
            return false
        }
        let requestedOffset = Int(dataRequest.requestedOffset)
        let requestedLength = dataRequest.requestedLength
        let currentOffset = Int(dataRequest.currentOffset)

        guard let songDataUnwrapped = mediaData,
              songDataUnwrapped.count > currentOffset
        else { // Don't have any data at all for this request.
            return false
        }

        let bytesToRespond = min(songDataUnwrapped.count - currentOffset, requestedLength)
        let dataToRespond = songDataUnwrapped.subdata(
            in: Range(uncheckedBounds: (currentOffset, currentOffset + bytesToRespond))
        )
        dataRequest.respond(with: dataToRespond)

        return songDataUnwrapped.count >= requestedLength + requestedOffset
    }

}

extension ResourceLoaderProcessor: AVAssetResourceLoaderDelegate {

    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {

        if isPlayingFromData {

        } else if session == nil {
            guard let initialUrl = owner?.url else {
                return false
            }

            startDataRequest(with: initialUrl)
        }

        pendingRequests.insert(loadingRequest)

        return true
    }

    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        pendingRequests.remove(loadingRequest)
    }

}

extension ResourceLoaderProcessor: URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        mediaData?.append(data)
        processPendingRequests()
        if let owner = owner, let bytesDownloaded = mediaData?.count {
            owner.delegate?.playerItem(
                owner,
                didDownloadBytesSoFar: bytesDownloaded,
                outOf: Int(dataTask.countOfBytesExpectedToReceive)
            )
        }
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        mediaData = Data()
        self.response = response
        processPendingRequests()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let owner = owner else { return }
        if let error = error {
            owner.delegate?.playerItem(owner, downloadingFailedWith: error)
            return
        }
        processPendingRequests()
        if let mediaData = mediaData {
            owner.delegate?.playerItem(owner, didFinishDownloadingData: mediaData)
        }
    }

}
