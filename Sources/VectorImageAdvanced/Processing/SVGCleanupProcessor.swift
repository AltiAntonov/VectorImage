//
//  SVGCleanupProcessor.swift
//  VectorImageAdvanced
//
//  Applies deterministic SVG cleanup before Core rendering.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

enum SVGCleanupProcessor {
    private struct CleanupResult {
        var svgText: String
        var warnings: [String]
    }

    static func process(_ svgText: String) -> (svgText: String, warnings: [String]) {
        var result = CleanupResult(svgText: svgText, warnings: [])

        removeScriptElements(from: &result)
        removeEventHandlerAttributes(from: &result)
        removeExternalResourceAttributes(from: &result)

        return (result.svgText, result.warnings)
    }

    private static func removeScriptElements(from result: inout CleanupResult) {
        let patterns = [
            #"<script\b[^>]*>[\s\S]*?</script\s*>"#,
            #"<script\b[^>]*/\s*>"#
        ]

        for pattern in patterns where containsMatch(pattern, in: result.svgText) {
            result.svgText = replacingMatches(pattern, in: result.svgText, with: "")
            appendUnique("Removed unsupported SVG element: script", to: &result.warnings)
        }
    }

    private static func removeEventHandlerAttributes(from result: inout CleanupResult) {
        let pattern = #"\s+(on[A-Za-z][A-Za-z0-9_-]*)\s*=\s*(?:"[^"]*"|'[^']*')"#
        let attributeNames = captureGroupValues(pattern, in: result.svgText, group: 1)

        guard !attributeNames.isEmpty else {
            return
        }

        result.svgText = replacingMatches(pattern, in: result.svgText, with: "")

        for attributeName in attributeNames {
            appendUnique(
                "Removed unsupported SVG event handler attribute: \(attributeName)",
                to: &result.warnings
            )
        }
    }

    private static func removeExternalResourceAttributes(from result: inout CleanupResult) {
        let pattern = #"\s+([A-Za-z_:][-A-Za-z0-9_:.]*)\s*=\s*(?:"[^"]*(?:https?:\/\/|\/\/)[^"]*"|'[^']*(?:https?:\/\/|\/\/)[^']*')"#
        let matches = matches(pattern, in: result.svgText).filter { match in
            guard let attributeName = captureGroupValue(in: result.svgText, match: match, group: 1) else {
                return false
            }

            return !isNamespaceAttribute(attributeName)
        }
        let attributeNames = matches.compactMap { match in
            captureGroupValue(in: result.svgText, match: match, group: 1)
        }

        guard !attributeNames.isEmpty else {
            return
        }

        result.svgText = removingMatches(matches, from: result.svgText)

        for attributeName in attributeNames {
            appendUnique(
                "Removed unsupported SVG external resource reference: \(attributeName)",
                to: &result.warnings
            )
        }
    }

    private static func containsMatch(_ pattern: String, in text: String) -> Bool {
        makeRegularExpression(pattern).firstMatch(
            in: text,
            range: NSRange(text.startIndex..<text.endIndex, in: text)
        ) != nil
    }

    private static func replacingMatches(_ pattern: String, in text: String, with replacement: String) -> String {
        makeRegularExpression(pattern).stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..<text.endIndex, in: text),
            withTemplate: replacement
        )
    }

    private static func captureGroupValues(_ pattern: String, in text: String, group: Int) -> [String] {
        let regularExpression = makeRegularExpression(pattern)
        let matches = regularExpression.matches(
            in: text,
            range: NSRange(text.startIndex..<text.endIndex, in: text)
        )

        return matches.compactMap { match in
            captureGroupValue(in: text, match: match, group: group)
        }
    }

    private static func matches(_ pattern: String, in text: String) -> [NSTextCheckingResult] {
        makeRegularExpression(pattern).matches(
            in: text,
            range: NSRange(text.startIndex..<text.endIndex, in: text)
        )
    }

    private static func captureGroupValue(in text: String, match: NSTextCheckingResult, group: Int) -> String? {
        guard match.numberOfRanges > group,
              let range = Range(match.range(at: group), in: text) else {
            return nil
        }

        return String(text[range])
    }

    private static func removingMatches(_ matches: [NSTextCheckingResult], from text: String) -> String {
        matches.reversed().reduce(into: text) { partialText, match in
            guard let range = Range(match.range, in: partialText) else {
                return
            }

            partialText.removeSubrange(range)
        }
    }

    private static func isNamespaceAttribute(_ attributeName: String) -> Bool {
        attributeName == "xmlns" || attributeName.hasPrefix("xmlns:")
    }

    private static func makeRegularExpression(_ pattern: String) -> NSRegularExpression {
        // Patterns are static and covered by tests; construction failure is a programmer error.
        try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }

    private static func appendUnique(_ warning: String, to warnings: inout [String]) {
        guard !warnings.contains(warning) else {
            return
        }

        warnings.append(warning)
    }
}
