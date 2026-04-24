//
//  VectorImageConfiguration.swift
//  VectorImageCore
//
//  Defines source-rendering policies that can be shared across Core and UI entry points.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

/// Configuration for source-based SVG loading and rendering.
@available(iOS 15.0, macOS 12.0, *)
public struct VectorImageConfiguration: Sendable, Hashable {
    public var loader: VectorImageLoader
    public var cachePolicy: VectorImageCachePolicy
    public var inFlightRequestPolicy: VectorImageInFlightRequestPolicy

    public init(
        loader: VectorImageLoader = .init(),
        cachePolicy: VectorImageCachePolicy = .disabled,
        inFlightRequestPolicy: VectorImageInFlightRequestPolicy = .coalesceIdenticalRequests
    ) {
        self.loader = loader
        self.cachePolicy = cachePolicy
        self.inFlightRequestPolicy = inFlightRequestPolicy
    }

    public static let `default` = VectorImageConfiguration()
}

/// Completed-result cache policy for source-based rendering.
public enum VectorImageCachePolicy: Sendable, Hashable {
    case disabled
    case enabled(VectorImageCache)

    public static func enabled(countLimit: Int = 100) -> VectorImageCachePolicy {
        .enabled(VectorImageCache(countLimit: countLimit))
    }

    var cache: VectorImageCache? {
        switch self {
        case .disabled:
            nil
        case .enabled(let cache):
            cache
        }
    }
}

/// In-flight request policy for source-based rendering.
public enum VectorImageInFlightRequestPolicy: Sendable, Hashable {
    case coalesceIdenticalRequests
    case disabled
}
