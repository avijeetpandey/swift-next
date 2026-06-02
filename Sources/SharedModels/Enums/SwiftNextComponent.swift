//
//  SwiftNextComponent.swift
//  SharedModels
//
//  ┌──────────────────────────────────────────────────────────────────┐
//  │  THE COMPONENT REGISTRY                                          │
//  ├──────────────────────────────────────────────────────────────────┤
//  │  This enum is the single source of truth for every UI node that  │
//  │  can travel from the server to an Apple device. It is fully      │
//  │  recursive — `vstack`, `hstack` and `zstack` cases hold arrays   │
//  │  of further `SwiftNextComponent` values, which means complex     │
//  │  view hierarchies can be expressed as plain JSON.                │
//  │                                                                  │
//  │  Wire format:                                                    │
//  │    { "type": "vstack",                                           │
//  │      "id":   "root",                                             │
//  │      "spec": { "spacing": 12, "alignment": "leading",            │
//  │                "children": [ … ] } }                             │
//  └──────────────────────────────────────────────────────────────────┘
//
//  Flow:
//      Vapor route ──▶ encode([SwiftNextComponent]) ──▶ HTTP/JSON
//                                                ──▶ NetworkEngine
//                                                ──▶ SwiftNextRenderer
//                                                ──▶ Native SwiftUI view
//
import Foundation

/// The closed registry of every component the SwiftNext renderer can
/// materialise. Adding a new visual primitive is a *deliberate* act
/// that requires touching: (1) this enum, (2) the renderer's switch,
/// (3) a dedicated Native* SwiftUI wrapper.
public enum SwiftNextComponent: UIPrimitive {

    // MARK: Layout primitives
    case vstack(VStackSpec)
    case hstack(HStackSpec)
    case zstack(ZStackSpec)
    case spacer(SpacerSpec)
    case divider(DividerSpec)

    // MARK: Text & inputs
    case text(TextSpec)
    case textField(TextFieldSpec)

    // MARK: Media & actions
    case image(ImageSpec)
    case button(ButtonSpec)

    // MARK: - UIPrimitive

    public var id: String {
        switch self {
        case .vstack(let s):     return s.id
        case .hstack(let s):     return s.id
        case .zstack(let s):     return s.id
        case .spacer(let s):     return s.id
        case .divider(let s):    return s.id
        case .text(let s):       return s.id
        case .textField(let s):  return s.id
        case .image(let s):      return s.id
        case .button(let s):     return s.id
        }
    }

    public var actionRoute: String? {
        switch self {
        case .button(let s):     return s.actionRoute
        case .textField(let s):  return s.actionRoute
        case .image(let s):      return s.actionRoute
        case .vstack(let s):     return s.actionRoute
        case .hstack(let s):     return s.actionRoute
        case .zstack(let s):     return s.actionRoute
        case .text(let s):       return s.actionRoute
        case .spacer, .divider:  return nil
        }
    }

    // MARK: - Codable (tagged union, "type" + "spec")

    private enum CodingKeys: String, CodingKey { case type, spec }

    private enum Kind: String, Codable {
        case vstack, hstack, zstack, spacer, divider
        case text, textField, image, button
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try c.decode(Kind.self, forKey: .type)
        switch kind {
        case .vstack:    self = .vstack(try c.decode(VStackSpec.self, forKey: .spec))
        case .hstack:    self = .hstack(try c.decode(HStackSpec.self, forKey: .spec))
        case .zstack:    self = .zstack(try c.decode(ZStackSpec.self, forKey: .spec))
        case .spacer:    self = .spacer(try c.decode(SpacerSpec.self, forKey: .spec))
        case .divider:   self = .divider(try c.decode(DividerSpec.self, forKey: .spec))
        case .text:      self = .text(try c.decode(TextSpec.self, forKey: .spec))
        case .textField: self = .textField(try c.decode(TextFieldSpec.self, forKey: .spec))
        case .image:     self = .image(try c.decode(ImageSpec.self, forKey: .spec))
        case .button:    self = .button(try c.decode(ButtonSpec.self, forKey: .spec))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .vstack(let s):     try c.encode(Kind.vstack, forKey: .type);    try c.encode(s, forKey: .spec)
        case .hstack(let s):     try c.encode(Kind.hstack, forKey: .type);    try c.encode(s, forKey: .spec)
        case .zstack(let s):     try c.encode(Kind.zstack, forKey: .type);    try c.encode(s, forKey: .spec)
        case .spacer(let s):     try c.encode(Kind.spacer, forKey: .type);    try c.encode(s, forKey: .spec)
        case .divider(let s):    try c.encode(Kind.divider, forKey: .type);   try c.encode(s, forKey: .spec)
        case .text(let s):       try c.encode(Kind.text, forKey: .type);      try c.encode(s, forKey: .spec)
        case .textField(let s):  try c.encode(Kind.textField, forKey: .type); try c.encode(s, forKey: .spec)
        case .image(let s):      try c.encode(Kind.image, forKey: .type);     try c.encode(s, forKey: .spec)
        case .button(let s):     try c.encode(Kind.button, forKey: .type);    try c.encode(s, forKey: .spec)
        }
    }
}
