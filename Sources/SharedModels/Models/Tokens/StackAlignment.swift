//
//  StackAlignment.swift
//  SharedModels
//
//  Cross-axis alignment shared by VStack / HStack / ZStack specs.
//
import Foundation

public enum StackAlignment: String, Codable, Hashable, Sendable {
    case leading, center, trailing, top, bottom
}
