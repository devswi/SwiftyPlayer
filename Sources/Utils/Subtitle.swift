//
//  Subtitle.swift
//  SwiftyPlayer
//
//  Created by shiwei on 2020/6/1.
//

import Foundation

/// SRT Parser
public typealias SubtitleDict = [String: String]
public typealias Parser<T> = [String: T]

public protocol SubtitleParsable {
    var subtitle: [AnyHashable: String] { get set }
    var timeRange: Range<TimeInterval>? { get set }

    init()

    static func separate(subtitle: String) -> SubtitleDict
}

extension SubtitleParsable {
    public init(subtitle: [AnyHashable: String], timeRange: Range<TimeInterval>) {
        self.init()
        self.subtitle = subtitle
        self.timeRange = timeRange
    }

    public static func separate(subtitle: String) -> SubtitleDict {
        ["en": subtitle]
    }
}

public enum SubtitleParserError: Error {
    case invalidResource
}

struct Pattern {
    static let index = "^[0-9]+"
    static let timeRange = #"\d{1,2}:\d{1,2}:\d{1,2}[,.]\d{1,3}"#
    static let subtitle = #"(\d+)\n([\d:,.]+)\s+-{2}\>\s+([\d:,.]+)\n([\s\S]*?(?=\n{2,}|$))"#
}

public class SubtitleParser<T> where T: SubtitleParsable {

    public static func parse(path: URL, encoding: String.Encoding = .utf8) -> Result<Parser<T>, Error> {
        do {
            var contents = try String(contentsOf: path, encoding: encoding)
            contents = contents.replacingOccurrences(of: "\n\r\n", with: "\n\n")
            contents = contents.replacingOccurrences(of: "\n\n\n", with: "\n\n")
            contents = contents.replacingOccurrences(of: "\r\n", with: "\n")
            return parse(contents: contents)
        } catch let error {
            return .failure(error)
        }
    }

    public static func parse(contents: String) -> Result<Parser<T>, Error> {
        do {
            let regex = try NSRegularExpression(pattern: Pattern.subtitle, options: .caseInsensitive)
            let range = NSRange(location: 0, length: contents.count)
            let matches = regex.matches(in: contents, options: [], range: range)
            var result: Parser<T> = [:]
            try matches.compactMap {
                Range($0.range, in: contents)
            }.forEach { range in
                let group = String(contents[range])
                let index = try parseIndex(sample: group)
                let timeRangeTuple = try parseTimeRange(sample: group)
                let timeRange = timeRangeTuple.range
                let lastIndex = group.index(timeRangeTuple.lastIndex, offsetBy: 1)
                let contents = group[lastIndex...]
                let subtitles = T.separate(subtitle: String(contents))
                result[index] = T.init(subtitle: subtitles, timeRange: timeRange)
            }
            return .success(result)
        } catch let error {
            return .failure(error)
        }
    }

}

extension SubtitleParser {

    private static func parseIndex(sample: String) throws -> String {
        let regex = try NSRegularExpression(pattern: Pattern.index, options: .caseInsensitive)
        let originalRange = NSRange(location: 0, length: sample.count)
        guard let match = regex.firstMatch(in: sample, options: [], range: originalRange),
              let range = Range(match.range, in: sample)
        else { throw SubtitleParserError.invalidResource }
        return String(sample[range])
    }

    private static func parseTimeRange(sample: String) throws -> (range: Range<TimeInterval>, lastIndex: String.Index) {
        let regex = try NSRegularExpression(pattern: Pattern.timeRange, options: .caseInsensitive)
        let range = NSRange(location: 0, length: sample.count)
        let matches = regex.matches(in: sample, options: [], range: range)
        guard matches.count == 2,
              let from = matches.first,
              let to = matches.last,
              let fromRange = Range(from.range, in: sample),
              let toRange = Range(to.range, in: sample)
        else { throw SubtitleParserError.invalidResource }
        return (range: time(sample[fromRange])..<time(sample[toRange]), lastIndex: toRange.upperBound)
    }

    private static func time(_ timeString: Substring) -> TimeInterval {
        var hour = 0.0, minute = 0.0, second = 0.0, millisecond = 0.0
        let scanner = Scanner(string: String(timeString))
        if #available(iOS 13, *) {
            hour = scanner.scanDouble() ?? 0.0
            _ = scanner.scanString(":")
            minute = scanner.scanDouble() ?? 0.0
            _ = scanner.scanString(":")
            second = scanner.scanDouble() ?? 0.0
            _ = scanner.scanString(",")
            millisecond = scanner.scanDouble() ?? 0.0
        } else {
            scanner.scanDouble(&hour)
            scanner.scanString(":", into: nil)
            scanner.scanDouble(&minute)
            scanner.scanString(":", into: nil)
            scanner.scanDouble(&second)
            scanner.scanString(",", into: nil)
            scanner.scanDouble(&millisecond)
        }
        return hour * 3600 + minute * 60 + second + millisecond / 1000
    }

}

extension Dictionary where Key == String, Value: SubtitleParsable {
    public func subtitle(contains duration: TimeInterval) -> Value? {
        values.first { $0.timeRange?.contains(duration) ?? false }
    }
}
