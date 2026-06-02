//
//  NativeText.swift
//  SwiftNextClient
//
#if canImport(SwiftUI) && (os(iOS) || os(macOS) || targetEnvironment(macCatalyst))
import SwiftUI
import SharedModels

@available(iOS 16.0, macOS 13.0, *)
public struct NativeText: View {
    public let spec: TextSpec

    public var body: some View {
        Text(spec.content)
            .font(spec.size.swiftUIFont)
            .fontWeight(spec.weight.swiftUIWeight)
            .multilineTextAlignment(spec.alignment.swiftUIAlignment)
            .foregroundColor(spec.color?.resolved ?? .primary)
    }
}
#endif
