//
//  PagePayload+Content.swift
//  SwiftNextServer
//
//  Adopts Vapor's `Content` protocol on the wire-level payload so it
//  can be returned directly from route closures. Lives in the server
//  module to keep `SharedModels` framework-free.
//
import Vapor
import SharedModels

extension PagePayload: Content {}
extension SwiftNextComponent: Content {}
