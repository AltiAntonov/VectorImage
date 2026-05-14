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
    public static let summary = "Optional preprocessing and compatibility layer that prepares SVG input for VectorImageCore."
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
/// The `1.0.0` implementation intentionally validates and forwards SVG bytes without
/// changing them. Future minor releases can add deterministic compatibility passes
/// while preserving this result shape.
public enum VectorImageAdvancedProcessor {
    /// Validates SVG data and returns the bytes that should be rendered by `VectorImageCore`.
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

        return VectorImageAdvancedResult(svgData: svgData)
    }
}
