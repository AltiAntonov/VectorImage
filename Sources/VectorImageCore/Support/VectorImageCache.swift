//
//  VectorImageCache.swift
//  VectorImageCore
//
//  Provides a small in-memory image cache for rasterized SVG results.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// A small in-memory cache keyed by string identifiers.
public final class VectorImageCache: @unchecked Sendable, Hashable {
    private let storage = NSCache<NSString, Box>()

    public init(countLimit: Int = 100) {
        storage.countLimit = countLimit
    }

    public func image(forKey key: String) -> VectorImagePlatformImage? {
        storage.object(forKey: key as NSString)?.result.image
    }

    public func renderResult(forKey key: String) -> VectorImageRenderResult? {
        storage.object(forKey: key as NSString)?.result
    }

    public func insert(_ image: VectorImagePlatformImage, forKey key: String) {
        let result = VectorImageRenderResult(image: image, diagnostics: .init())
        storage.setObject(Box(result: result), forKey: key as NSString)
    }

    public func insert(_ result: VectorImageRenderResult, forKey key: String) {
        storage.setObject(Box(result: result), forKey: key as NSString)
    }

    public func removeImage(forKey key: String) {
        storage.removeObject(forKey: key as NSString)
    }

    public func removeAllImages() {
        storage.removeAllObjects()
    }

    public static func == (lhs: VectorImageCache, rhs: VectorImageCache) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

private final class Box {
    let result: VectorImageRenderResult

    init(result: VectorImageRenderResult) {
        self.result = result
    }
}
