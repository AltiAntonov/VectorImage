//
//  VectorImageDiagnostics.swift
//  VectorImageCore
//
//  Captures non-fatal parsing and rendering diagnostics for SVG documents.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// Non-fatal warnings collected while parsing or rendering SVG content.
public struct VectorImageDiagnostics: Equatable, Sendable {
    public private(set) var warnings: [String]

    public init(warnings: [String] = []) {
        self.warnings = warnings
    }

    mutating func append(_ warning: String) {
        warnings.append(warning)
    }
}
