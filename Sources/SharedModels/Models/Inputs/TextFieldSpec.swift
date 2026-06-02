//
//  TextFieldSpec.swift
//  SharedModels
//
//  Two-way bound text input. The renderer tracks the value in local
//  state; on submit (or on every keystroke when `submitOnChange` is
//  true) the value is POSTed to `actionRoute`.
//
import Foundation

public struct TextFieldSpec: UIPrimitive {
    public let id: String
    public let placeholder: String
    public let initialValue: String
    public let isSecure: Bool
    public let submitOnChange: Bool
    public let actionRoute: String?

    public init(id: String,
                placeholder: String = "",
                initialValue: String = "",
                isSecure: Bool = false,
                submitOnChange: Bool = false,
                actionRoute: String? = nil) {
        self.id = id
        self.placeholder = placeholder
        self.initialValue = initialValue
        self.isSecure = isSecure
        self.submitOnChange = submitOnChange
        self.actionRoute = actionRoute
    }
}
