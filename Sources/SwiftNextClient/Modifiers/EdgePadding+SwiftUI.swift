//
//  EdgePadding+SwiftUI.swift
//  SwiftNextClient
//
#if canImport(SwiftUI)
import SwiftUI
import SharedModels

@available(iOS 16.0, macOS 13.0, *)
extension View {
    /// Applies a wire-format `EdgePadding` to a SwiftUI view.
    func swiftNextPadding(_ padding: EdgePadding) -> some View {
        self
            .padding(.top,      padding.top)
            .padding(.leading,  padding.leading)
            .padding(.bottom,   padding.bottom)
            .padding(.trailing, padding.trailing)
    }
}
#endif
