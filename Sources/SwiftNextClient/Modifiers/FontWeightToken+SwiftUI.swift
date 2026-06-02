//
//  FontWeightToken+SwiftUI.swift
//  SwiftNextClient
//
#if canImport(SwiftUI)
import SwiftUI
import SharedModels

@available(iOS 16.0, macOS 13.0, *)
extension FontWeightToken {
    var swiftUIWeight: Font.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin:       return .thin
        case .light:      return .light
        case .regular:    return .regular
        case .medium:     return .medium
        case .semibold:   return .semibold
        case .bold:       return .bold
        case .heavy:      return .heavy
        case .black:      return .black
        }
    }
}
#endif
