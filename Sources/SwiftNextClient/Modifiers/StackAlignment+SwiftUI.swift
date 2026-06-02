//
//  StackAlignment+SwiftUI.swift
//  SwiftNextClient
//
//  Maps wire alignment tokens to SwiftUI's HorizontalAlignment /
//  VerticalAlignment / Alignment values.
//
#if canImport(SwiftUI)
import SwiftUI
import SharedModels

@available(iOS 16.0, macOS 13.0, *)
extension StackAlignment {

    var horizontal: HorizontalAlignment {
        switch self {
        case .leading:  return .leading
        case .trailing: return .trailing
        default:        return .center
        }
    }

    var vertical: VerticalAlignment {
        switch self {
        case .top:    return .top
        case .bottom: return .bottom
        default:      return .center
        }
    }

    var zAlignment: Alignment {
        switch self {
        case .leading:  return .leading
        case .trailing: return .trailing
        case .top:      return .top
        case .bottom:   return .bottom
        case .center:   return .center
        }
    }
}
#endif
