//
//  NativeVStack.swift
//  SwiftNextClient
//
#if canImport(SwiftUI) && (os(iOS) || os(macOS) || targetEnvironment(macCatalyst))
import SwiftUI
import SharedModels

@available(iOS 16.0, macOS 13.0, *)
public struct NativeVStack: View {
    public let spec: VStackSpec
    public let dispatcher: SwiftNextActionDispatcher

    public var body: some View {
        VStack(alignment: spec.alignment.horizontal, spacing: spec.spacing) {
            ForEach(spec.children, id: \.id) { child in
                SwiftNextRenderer(component: child, actionDispatcher: dispatcher)
            }
        }
        .swiftNextPadding(spec.padding)
    }
}
#endif
