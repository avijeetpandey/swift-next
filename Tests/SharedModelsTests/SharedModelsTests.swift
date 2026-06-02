//
//  SharedModelsTests.swift
//  SharedModelsTests
//
//  Pure-Swift assertions on the wire contract. These tests compile on
//  every platform (no SwiftUI/Vapor dependency).
//
import XCTest
import SharedModels

final class SharedModelsTests: XCTestCase {

    func testFontSizeTokenSemanticEncoding() throws {
        let token = FontSizeToken.headline
        let data = try JSONEncoder().encode(token)
        let s = String(data: data, encoding: .utf8)
        XCTAssertEqual(s, "\"headline\"")
    }

    func testFontSizeTokenPointsEncoding() throws {
        let token = FontSizeToken.points(17)
        let data = try JSONEncoder().encode(token)
        let decoded = try JSONDecoder().decode(FontSizeToken.self, from: data)
        XCTAssertEqual(decoded, token)
    }

    func testNestedStackEncoding() throws {
        let tree = SwiftNextComponent.vstack(VStackSpec(
            id: "root",
            children: [
                .hstack(HStackSpec(id: "row", children: [
                    .text(TextSpec(id: "t", content: "Hi"))
                ]))
            ]
        ))
        let data = try JSONEncoder().encode(tree)
        let back = try JSONDecoder().decode(SwiftNextComponent.self, from: data)
        XCTAssertEqual(tree, back)
    }

    func testColorTokenHexParse() throws {
        let token = ColorToken(hex: "#112233")
        let data = try JSONEncoder().encode(token)
        let back = try JSONDecoder().decode(ColorToken.self, from: data)
        XCTAssertEqual(back, token)
    }

    func testEveryComponentCaseRoundTrips() throws {
        let cases: [SwiftNextComponent] = [
            .vstack(VStackSpec(id: "v", children: [])),
            .hstack(HStackSpec(id: "h", children: [])),
            .zstack(ZStackSpec(id: "z", children: [])),
            .spacer(SpacerSpec(id: "s")),
            .divider(DividerSpec(id: "d")),
            .text(TextSpec(id: "t", content: "x")),
            .textField(TextFieldSpec(id: "tf")),
            .image(ImageSpec(id: "i", url: "https://x/y.png")),
            .button(ButtonSpec(id: "b", title: "Go"))
        ]
        for c in cases {
            let data = try JSONEncoder().encode(c)
            let back = try JSONDecoder().decode(SwiftNextComponent.self, from: data)
            XCTAssertEqual(c, back, "round-trip failed for \(c)")
        }
    }
}
