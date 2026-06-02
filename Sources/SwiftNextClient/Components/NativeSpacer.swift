//
//  NativeSpacer.swift
//  SwiftNextClient
//
#if canImport(SwiftUI) && (os(iOS) || os(macOS) || targetEnvironment(macCatalyst))
import SwiftUI
import SharedModels

@available(iOS 16.0, macOS 13.0, *)
public struct NativeSpacer: View {
    public let spec: SpacerSpec

    public var body: some View {
        if let min = spec.minLength {
            Spacer(minLength: min)
        } else {
            Spacer()
        }
    }
}
#endif
