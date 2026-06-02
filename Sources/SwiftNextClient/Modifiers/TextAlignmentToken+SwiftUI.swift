//
//  TextAlignmentToken+SwiftUI.swift
//  SwiftNextClient
//
#if canImport(SwiftUI)
import SwiftUI
import SharedModels

@available(iOS 16.0, macOS 13.0, *)
extension TextAlignmentToken {
    var swiftUIAlignment: TextAlignment {
        switch self {
        case .leading:  return .leading
        case .center:   return .center
        case .trailing: return .trailing
        }
    }
}
#endif
