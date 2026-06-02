//
//  NetworkEngine.swift
//  SwiftNextClient
//
//  Thin URLSession-based fetcher for `PagePayload` JSON. The engine is
//  generic on Codable types so any Server Action response (including
//  fresh trees) can be decoded uniformly.
//
//  Flow:
//      View.task { await NetworkEngine.shared.fetchPage("/pages/home") }
//      → URLSession → JSONDecoder → PagePayload → @State tree → renderer.
//
import Foundation
import SharedModels

public enum NetworkError: Error, Sendable {
    case invalidURL
    case badStatus(Int)
    case decoding(Error)
    case transport(Error)
}

public final class NetworkEngine: @unchecked Sendable {

    public static let shared = NetworkEngine()

    public var baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(baseURL: URL? = nil, session: URLSession = .shared) {
        let resolved = baseURL
            ?? ProcessInfo.processInfo.environment["SWIFTNEXT_API_BASE_URL"]
                .flatMap(URL.init(string:))
            ?? URL(string: "http://localhost:8080")!
        self.baseURL = resolved
        self.session = session

        let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
        let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601
        self.decoder = dec
        self.encoder = enc
    }

    public func fetchPage(_ path: String) async throws -> PagePayload {
        try await get(path)
    }

    public func get<T: Decodable>(_ path: String) async throws -> T {
        let url = try resolve(path)
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        return try await perform(req)
    }

    public func post<T: Decodable>(_ path: String,
                                   body: [String: String]? = nil) async throws -> T {
        let url = try resolve(path)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body = body {
            req.httpBody = try encoder.encode(body)
        }
        return try await perform(req)
    }

    private func resolve(_ path: String) throws -> URL {
        if let absolute = URL(string: path), absolute.scheme != nil {
            return absolute
        }
        guard let url = URL(string: path, relativeTo: baseURL)?.absoluteURL else {
            throw NetworkError.invalidURL
        }
        return url
    }

    private func perform<T: Decodable>(_ req: URLRequest) async throws -> T {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw NetworkError.transport(error)
        }
        if let http = response as? HTTPURLResponse,
           !(200..<300).contains(http.statusCode) {
            throw NetworkError.badStatus(http.statusCode)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decoding(error)
        }
    }
}
