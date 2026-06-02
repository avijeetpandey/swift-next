//
//  RendererTests.swift
//  UIComponentsTests
//
//  Structural / parsing assertions for the SwiftNext renderer.
//  We exercise the Codable contract end-to-end since SwiftUI snapshot
//  tests would require a host application bundle.
//
import XCTest
import SharedModels
@testable import SwiftNextClient

final class RendererTests: XCTestCase {

    func testFullTreeRoundTrip() throws {
        let original = PagePayload(title: "Home", tree: [
            .vstack(VStackSpec(
                id: "root",
                alignment: .leading,
                spacing: 12,
                padding: EdgePadding(top: 8, leading: 8, bottom: 8, trailing: 8),
                children: [
                    .text(TextSpec(id: "t",
                                   content: "Hello",
                                   size: .largeTitle,
                                   weight: .bold,
                                   alignment: .leading)),
                    .button(ButtonSpec(id: "b", title: "Tap",
                                       style: .primary,
                                       actionRoute: "/actions/tap"))
                ]
            ))
        ])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PagePayload.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testActionRoutePropagatesThroughEnum() {
        let btn = SwiftNextComponent.button(
            ButtonSpec(id: "x", title: "Go", actionRoute: "/r"))
        XCTAssertEqual(btn.actionRoute, "/r")
        XCTAssertEqual(btn.id, "x")
    }

    func testTextFieldDecoding() throws {
        let json = """
        { "type": "textField", "spec": {
            "id": "f", "placeholder": "Name", "initialValue": "",
            "isSecure": false, "submitOnChange": true,
            "actionRoute": "/actions/x" } }
        """.data(using: .utf8)!
        let comp = try JSONDecoder().decode(SwiftNextComponent.self, from: json)
        if case .textField(let spec) = comp {
            XCTAssertEqual(spec.placeholder, "Name")
            XCTAssertTrue(spec.submitOnChange)
        } else {
            XCTFail("Expected textField case")
        }
    }

    func testNetworkEngineBaseURLDefault() {
        let engine = NetworkEngine()
        XCTAssertNotNil(engine.baseURL)
    }
}
