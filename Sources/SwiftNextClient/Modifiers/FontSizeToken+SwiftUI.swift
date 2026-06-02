//
//  FontSizeToken+SwiftUI.swift
//  SwiftNextClient
//
#if canImport(SwiftUI)
import SwiftUI
import SharedModels

@available(iOS 16.0, macOS 13.0, *)
extension FontSizeToken {
    var swiftUIFont: Font {
        switch self {
        case .caption:    return .caption
        case .footnote:   return .footnote
        case .body:       return .body
        case .callout:    return .callout
        case .headline:   return .headline
        case .title3:     return .title3
        case .title2:     return .title2
        case .title:      return .title
        case .largeTitle: return .largeTitle
        case .points(let v): return .system(size: v)
        }
    }
}
#endif
