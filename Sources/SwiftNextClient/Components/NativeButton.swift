//
//  NativeButton.swift
//  SwiftNextClient
//
#if canImport(SwiftUI) && (os(iOS) || os(macOS) || targetEnvironment(macCatalyst))
import SwiftUI
import SharedModels

@available(iOS 16.0, macOS 13.0, *)
public struct NativeButton: View {
    public let spec: ButtonSpec
    public let dispatcher: SwiftNextActionDispatcher

    public var body: some View {
        Button(spec.title) {
            guard let route = spec.actionRoute else { return }
            Task { await dispatcher.dispatch(route: route, value: nil, payload: spec.actionPayload) }
        }
        .applyStyle(spec.style)
    }
}

@available(iOS 16.0, macOS 13.0, *)
private extension View {
    @ViewBuilder
    func applyStyle(_ style: ButtonSpec.Style) -> some View {
        switch style {
        case .primary:     self.buttonStyle(.borderedProminent)
        case .secondary:   self.buttonStyle(.bordered)
        case .plain:       self.buttonStyle(.plain)
        case .destructive: self.buttonStyle(.borderedProminent).tint(.red)
        }
    }
}
#endif
