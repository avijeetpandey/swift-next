//
//  SwiftNextRenderer.swift
//  SwiftNextClient
//
//  ┌──────────────────────────────────────────────────────────────────┐
//  │  THE RENDERING LOOP                                              │
//  ├──────────────────────────────────────────────────────────────────┤
//  │  Server JSON → [SwiftNextComponent] → SwiftNextRenderer →        │
//  │  Native* SwiftUI views → pixels on the user's screen.            │
//  │                                                                  │
//  │  This view is the ONLY place where the closed enum is switched.  │
//  │  Adding a new case in `SharedModels.SwiftNextComponent` will     │
//  │  produce a compile-time error here, guaranteeing the renderer    │
//  │  is exhaustive.                                                  │
//  └──────────────────────────────────────────────────────────────────┘
//
#if canImport(SwiftUI) && (os(iOS) || os(macOS) || targetEnvironment(macCatalyst))
import SwiftUI
import SharedModels

@available(iOS 16.0, macOS 13.0, *)
public struct SwiftNextRenderer: View {

    public let component: SwiftNextComponent
    public let actionDispatcher: SwiftNextActionDispatcher

    public init(component: SwiftNextComponent,
                actionDispatcher: SwiftNextActionDispatcher) {
        self.component = component
        self.actionDispatcher = actionDispatcher
    }

    public var body: some View {
        switch component {
        case .vstack(let s):     NativeVStack(spec: s, dispatcher: actionDispatcher)
        case .hstack(let s):     NativeHStack(spec: s, dispatcher: actionDispatcher)
        case .zstack(let s):     NativeZStack(spec: s, dispatcher: actionDispatcher)
        case .spacer(let s):     NativeSpacer(spec: s)
        case .divider(let s):    NativeDivider(spec: s)
        case .text(let s):       NativeText(spec: s)
        case .textField(let s):  NativeTextField(spec: s, dispatcher: actionDispatcher)
        case .image(let s):      NativeImage(spec: s)
        case .button(let s):     NativeButton(spec: s, dispatcher: actionDispatcher)
        }
    }
}

/// Convenience wrapper that renders a full `[SwiftNextComponent]` tree.
@available(iOS 16.0, macOS 13.0, *)
public struct SwiftNextTree: View {

    public let components: [SwiftNextComponent]
    public let actionDispatcher: SwiftNextActionDispatcher

    public init(components: [SwiftNextComponent],
                actionDispatcher: SwiftNextActionDispatcher) {
        self.components = components
        self.actionDispatcher = actionDispatcher
    }

    public var body: some View {
        ForEach(components, id: \.id) { node in
            SwiftNextRenderer(component: node, actionDispatcher: actionDispatcher)
        }
    }
}
#endif
