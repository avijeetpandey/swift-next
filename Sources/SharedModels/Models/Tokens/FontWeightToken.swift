//
//  FontWeightToken.swift
//  SharedModels
//
//  Wire-safe font weight, mapped to SwiftUI's `Font.Weight` on the
//  client side by the renderer.
//
import Foundation

public enum FontWeightToken: String, Codable, Hashable, Sendable {
    case ultraLight, thin, light, regular, medium, semibold, bold, heavy, black
}
