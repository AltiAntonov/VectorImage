//
//  VectorImageLoader.swift
//  VectorImageCore
//
//  Loads SVG bytes from data, file URLs, or remote URLs.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// Loads raw bytes for vector image sources.
@available(iOS 15.0, macOS 12.0, *)
public struct VectorImageLoader: Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func loadData(from source: VectorImageSource) async throws -> Data {
        switch source {
        case .data(let data):
            return data
        case .fileURL(let url):
            return try Data(contentsOf: url)
        case .remoteURL(let url):
            let (data, _) = try await session.data(from: url)
            return data
        }
    }
}
