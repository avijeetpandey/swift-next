//
//  NativeZStack.swift
//  SwiftNextClient
//
#if canImport(SwiftUI) && (os(iOS) || os(macOS) || targetEnvironment(macCatalyst))
import SwiftUI
import SharedModels

@available(iOS 16.0, macOS 13.0, *)
public struct NativeZStack: View {
    public let spec: ZStackSpec
    public let dispatcher: SwiftNextActionDispatcher

    public var body: some View {
        ZStack(alignment: spec.alignment.zAlignment) {
            ForEach(spec.children, id: \.id) { child in
                SwiftNextRenderer(component: child, actionDispatcher: dispatcher)
            }
        }
        .swiftNextPadding(spec.padding)
    }
}
#endif
