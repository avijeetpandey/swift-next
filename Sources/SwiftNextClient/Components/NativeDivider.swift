//
//  NativeDivider.swift
//  SwiftNextClient
//
#if canImport(SwiftUI) && (os(iOS) || os(macOS) || targetEnvironment(macCatalyst))
import SwiftUI
import SharedModels

@available(iOS 16.0, macOS 13.0, *)
public struct NativeDivider: View {
    public let spec: DividerSpec
    public var body: some View { Divider() }
}
#endif
