//
//  NativeHStack.swift
//  SwiftNextClient
//
#if canImport(SwiftUI) && (os(iOS) || os(macOS) || targetEnvironment(macCatalyst))
import SwiftUI
import SharedModels

@available(iOS 16.0, macOS 13.0, *)
public struct NativeHStack: View {
    public let spec: HStackSpec
    public let dispatcher: SwiftNextActionDispatcher

    public var body: some View {
        HStack(alignment: spec.alignment.vertical, spacing: spec.spacing) {
            ForEach(spec.children, id: \.id) { child in
                SwiftNextRenderer(component: child, actionDispatcher: dispatcher)
            }
        }
        .swiftNextPadding(spec.padding)
    }
}
#endif
