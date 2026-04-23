//
//  VectorImageAsyncImagePhase.swift
//  VectorImageUI
//
//  Defines phase values emitted by the SwiftUI async SVG view.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import SwiftUI
import VectorImageCore

/// A successful async SVG render packaged for SwiftUI consumption.
public struct VectorImageAsyncImageValue {
    public let image: Image
    public let platformImage: VectorImagePlatformImage
    public let diagnostics: VectorImageDiagnostics

    public init(
        image: Image,
        platformImage: VectorImagePlatformImage,
        diagnostics: VectorImageDiagnostics
    ) {
        self.image = image
        self.platformImage = platformImage
        self.diagnostics = diagnostics
    }
}

/// Load state for ``VectorImageAsyncImage``.
public enum VectorImageAsyncImagePhase {
    case empty
    case success(VectorImageAsyncImageValue)
    case failure(any Error)

    public var image: Image? {
        switch self {
        case .success(let value):
            value.image
        case .empty, .failure:
            nil
        }
    }

    public var diagnostics: VectorImageDiagnostics? {
        switch self {
        case .success(let value):
            value.diagnostics
        case .empty, .failure:
            nil
        }
    }

    public var error: (any Error)? {
        switch self {
        case .failure(let error):
            error
        case .empty, .success:
            nil
        }
    }
}
