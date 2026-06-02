//
//  ColorToken+SwiftUI.swift
//  SwiftNextClient
//
#if canImport(SwiftUI)
import SwiftUI
import SharedModels

@available(iOS 16.0, macOS 13.0, *)
extension ColorToken {

    /// Resolves either the hex code or the semantic role to a SwiftUI Color.
    var resolved: Color {
        if let hex = hex, let parsed = Color.init(hexString: hex) {
            return parsed
        }
        switch semantic {
        case .primary:     return .primary
        case .secondary:   return .secondary
        case .accent:      return .accentColor
        case .background:
            #if os(iOS)
            return Color(uiColor: .systemBackground)
            #else
            return Color(nsColor: .windowBackgroundColor)
            #endif
        case .foreground:  return .primary
        case .destructive: return .red
        case .none:        return .primary
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
extension Color {
    /// Parses "#RRGGBB" or "#RRGGBBAA" hex strings.
    init?(hexString: String) {
        var s = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6 || s.count == 8,
              let value = UInt64(s, radix: 16) else { return nil }
        let r, g, b, a: Double
        if s.count == 6 {
            r = Double((value & 0xFF0000) >> 16) / 255
            g = Double((value & 0x00FF00) >> 8)  / 255
            b = Double( value & 0x0000FF)        / 255
            a = 1
        } else {
            r = Double((value & 0xFF000000) >> 24) / 255
            g = Double((value & 0x00FF0000) >> 16) / 255
            b = Double((value & 0x0000FF00) >> 8)  / 255
            a = Double( value & 0x000000FF)        / 255
        }
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
#endif
