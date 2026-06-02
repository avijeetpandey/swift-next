//
//  NativeTextField.swift
//  SwiftNextClient
//
#if canImport(SwiftUI) && (os(iOS) || os(macOS) || targetEnvironment(macCatalyst))
import SwiftUI
import SharedModels

@available(iOS 16.0, macOS 13.0, *)
public struct NativeTextField: View {
    public let spec: TextFieldSpec
    public let dispatcher: SwiftNextActionDispatcher

    @State private var value: String

    public init(spec: TextFieldSpec, dispatcher: SwiftNextActionDispatcher) {
        self.spec = spec
        self.dispatcher = dispatcher
        _value = State(initialValue: spec.initialValue)
    }

    public var body: some View {
        Group {
            if spec.isSecure {
                SecureField(spec.placeholder, text: $value)
            } else {
                TextField(spec.placeholder, text: $value)
            }
        }
        .textFieldStyle(.roundedBorder)
        .onChange(of: value) { newValue in
            guard spec.submitOnChange, let route = spec.actionRoute else { return }
            Task { await dispatcher.dispatch(route: route, value: newValue, payload: nil) }
        }
        .onSubmit {
            guard let route = spec.actionRoute else { return }
            Task { await dispatcher.dispatch(route: route, value: value, payload: nil) }
        }
    }
}
#endif
