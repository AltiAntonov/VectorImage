//
//  VectorImageDetector.swift
//  VectorImageCore
//
//  Detects whether bytes or URLs appear to represent SVG content.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// Utility helpers for preflighting SVG inputs.
public enum VectorImageDetector {
    /// Returns `true` when the bytes appear to contain SVG XML.
    public static func isSVG(data: Data) -> Bool {
        guard !data.isEmpty else { return false }
        guard let text = String(data: data.prefix(512), encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return false
        }

        return text.contains("<svg") || text.hasPrefix("<?xml")
    }

    /// Returns `true` when the bytes or URL hint appear to describe SVG content.
    public static func isSVG(data: Data, url: URL?) -> Bool {
        if isSVG(data: data) {
            return true
        }

        guard let url else { return false }
        return url.pathExtension.lowercased() == "svg"
    }

    /// Returns `true` when the URL likely points to SVG content.
    public static func isSVG(url: URL) -> Bool {
        url.pathExtension.lowercased() == "svg"
    }
}
