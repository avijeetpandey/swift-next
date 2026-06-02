//
//  NativeImage.swift
//  SwiftNextClient
//
#if canImport(SwiftUI) && (os(iOS) || os(macOS) || targetEnvironment(macCatalyst))
import SwiftUI
import SharedModels

@available(iOS 16.0, macOS 13.0, *)
public struct NativeImage: View {
    public let spec: ImageSpec

    public var body: some View {
        Group {
            if let url = URL(string: spec.url) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:               ProgressView()
                    case .success(let image):  image.resizable().scaledToFit()
                    case .failure:             Color.gray.opacity(0.2)
                    @unknown default:          EmptyView()
                    }
                }
            } else {
                Color.gray.opacity(0.2)
            }
        }
        .frame(width: spec.width.map { CGFloat($0) },
               height: spec.height.map { CGFloat($0) })
        .accessibilityLabel(spec.accessibilityLabel ?? "")
    }
}
#endif
