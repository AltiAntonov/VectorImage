//
//  VectorImageAdvanced.swift
//  VectorImageAdvanced
//
//  Declares the optional advanced SVG preprocessing layer for VectorImage.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation
import VectorImageCore

/// Describes the role of the optional advanced SVG compatibility layer.
public enum VectorImageAdvancedFeatureSet {
    /// Returns a short description of the target's role.
    public static let summary = "Optional preprocessing layer for cleanup, style compatibility, and local SVG reference expansion before VectorImageCore rendering."
}

/// Result produced by the advanced SVG preprocessing pipeline.
public struct VectorImageAdvancedResult: Equatable, Sendable {
    /// SVG bytes after preprocessing.
    public let svgData: Data

    /// Non-fatal diagnostics collected while preprocessing.
    public let diagnostics: VectorImageDiagnostics

    /// Creates an advanced preprocessing result.
    ///
    /// - Parameters:
    ///   - svgData: SVG bytes after preprocessing.
    ///   - diagnostics: Non-fatal preprocessing diagnostics.
    public init(svgData: Data, diagnostics: VectorImageDiagnostics = .init()) {
        self.svgData = svgData
        self.diagnostics = diagnostics
    }
}

/// Prepares SVG data for rendering by `VectorImageCore`.
///
/// The processor applies conservative, deterministic cleanup before handing bytes to Core.
public enum VectorImageAdvancedProcessor {
    /// Validates and prepares SVG data before rendering through `VectorImageCore`.
    ///
    /// - Parameter svgData: Raw SVG bytes.
    /// - Returns: A result containing SVG bytes and preprocessing diagnostics.
    /// - Throws: `VectorImageError.emptyData` when the input is empty, or
    ///   `VectorImageError.notSVG` when the input does not contain an SVG root.
    public static func process(svgData: Data) throws -> VectorImageAdvancedResult {
        guard !svgData.isEmpty else {
            throw VectorImageError.emptyData
        }

        guard VectorImageDetector.isSVG(data: svgData) else {
            throw VectorImageError.notSVG
        }

        guard let svgText = String(data: svgData, encoding: .utf8) else {
            throw VectorImageError.invalidUTF8
        }

        let cleanup = SVGCleanupProcessor.process(svgText)

        guard let processedData = cleanup.svgText.data(using: .utf8) else {
            throw VectorImageError.invalidUTF8
        }

        return VectorImageAdvancedResult(
            svgData: processedData,
            diagnostics: VectorImageDiagnostics(warnings: cleanup.warnings)
        )
    }

    /// Preprocesses and renders SVG data through `VectorImageCore`.
    ///
    /// - Parameters:
    ///   - svgData: Raw SVG bytes.
    ///   - options: Rasterization options such as target size and scaling mode.
    /// - Returns: The rendered image and combined preprocessing/rendering diagnostics.
    /// - Throws: A `VectorImageError` if preprocessing or rendering fails.
    public static func render(
        svgData: Data,
        options: VectorImageRasterizationOptions = .init()
    ) throws -> VectorImageRenderResult {
        let processed = try process(svgData: svgData)
        let rendered = try VectorImageRenderer.render(svgData: processed.svgData, options: options)

        return VectorImageRenderResult(
            image: rendered.image,
            diagnostics: VectorImageDiagnostics(
                warnings: processed.diagnostics.warnings + rendered.diagnostics.warnings
            )
        )
    }

    /// Preprocesses and renders SVG data through `VectorImageCore`, returning only the image.
    ///
    /// This is a convenience wrapper over ``render(svgData:options:)`` for callers that do not
    /// need diagnostics.
    ///
    /// - Parameters:
    ///   - svgData: Raw SVG bytes.
    ///   - options: Rasterization options such as target size and scaling mode.
    /// - Returns: A rendered bitmap image.
    /// - Throws: A `VectorImageError` if preprocessing or rendering fails.
    public static func renderImage(
        svgData: Data,
        options: VectorImageRasterizationOptions = .init()
    ) throws -> VectorImagePlatformImage {
        try render(svgData: svgData, options: options).image
    }
}
