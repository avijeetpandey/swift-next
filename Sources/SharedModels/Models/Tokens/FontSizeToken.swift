//
//  FontSizeToken.swift
//  SharedModels
//
//  Semantic + numeric font sizes. The renderer prefers the semantic
//  bucket (Dynamic Type aware) and falls back to the raw point value.
//
import Foundation

public enum FontSizeToken: Codable, Hashable, Sendable {
    case caption, footnote, body, callout, headline, title3, title2, title, largeTitle
    case points(Double)

    private enum CodingKeys: String, CodingKey { case style, points }

    public init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(),
           let raw = try? single.decode(String.self) {
            switch raw {
            case "caption":    self = .caption
            case "footnote":   self = .footnote
            case "body":       self = .body
            case "callout":    self = .callout
            case "headline":   self = .headline
            case "title3":     self = .title3
            case "title2":     self = .title2
            case "title":      self = .title
            case "largeTitle": self = .largeTitle
            default:
                throw DecodingError.dataCorruptedError(
                    in: single, debugDescription: "Unknown font size token \(raw)")
            }
            return
        }
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let pts = try c.decode(Double.self, forKey: .points)
        self = .points(pts)
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .points(let v):
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(v, forKey: .points)
        default:
            var single = encoder.singleValueContainer()
            try single.encode(stringValue)
        }
    }

    private var stringValue: String {
        switch self {
        case .caption:    return "caption"
        case .footnote:   return "footnote"
        case .body:       return "body"
        case .callout:    return "callout"
        case .headline:   return "headline"
        case .title3:     return "title3"
        case .title2:     return "title2"
        case .title:      return "title"
        case .largeTitle: return "largeTitle"
        case .points:     return "points"
        }
    }
}
