//
//  SVGLayoutNormalizationProcessor.swift
//  VectorImageAdvanced
//
//  Normalizes common SVG layout forms into Core-friendly dimensions and transforms.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

enum SVGLayoutNormalizationProcessor {
    static func process(_ svgText: String) -> (svgText: String, warnings: [String]) {
        var warnings: [String] = []
        var normalized = normalizeRootDimensions(in: svgText, warnings: &warnings)
        normalized = flattenNestedSVGLayout(in: normalized, warnings: &warnings)

        return (normalized, warnings)
    }

    private static func normalizeRootDimensions(in text: String, warnings: inout [String]) -> String {
        guard let rootMatch = svgOpeningTagRegex.firstMatch(
            in: text,
            range: NSRange(text.startIndex..<text.endIndex, in: text)
        ),
              let rootRange = Range(rootMatch.range, in: text),
              let attributeText = captureGroupValue(in: text, match: rootMatch, group: 1) else {
            return text
        }

        let attributes = SVGLayoutAttributeList(attributeText: attributeText)

        guard let viewBox = attributes.value(for: "viewBox").flatMap(SVGViewBox.init(rawValue:)) else {
            return text
        }

        var openingTag = String(text[rootRange])
        var addedMissingDimension = false
        var convertedPercentageDimension = false

        if attributes.value(for: "width") == nil {
            openingTag = replacingOrAddingAttribute("width", value: formatNumber(viewBox.width), in: openingTag)
            addedMissingDimension = true
        } else if let width = attributes.value(for: "width"),
                  let percentage = percentageValue(width) {
            openingTag = replacingOrAddingAttribute(
                "width",
                value: formatNumber(viewBox.width * percentage),
                in: openingTag
            )
            convertedPercentageDimension = true
        }

        if attributes.value(for: "height") == nil {
            openingTag = replacingOrAddingAttribute("height", value: formatNumber(viewBox.height), in: openingTag)
            addedMissingDimension = true
        } else if let height = attributes.value(for: "height"),
                  let percentage = percentageValue(height) {
            openingTag = replacingOrAddingAttribute(
                "height",
                value: formatNumber(viewBox.height * percentage),
                in: openingTag
            )
            convertedPercentageDimension = true
        }

        guard addedMissingDimension || convertedPercentageDimension else {
            return text
        }

        if addedMissingDimension {
            appendUnique("Normalized root SVG dimensions from viewBox", to: &warnings)
        }

        if convertedPercentageDimension {
            appendUnique("Normalized root SVG percentage dimensions from viewBox", to: &warnings)
        }

        var result = text
        result.replaceSubrange(rootRange, with: openingTag)
        return result
    }

    private static func flattenNestedSVGLayout(in text: String, warnings: inout [String]) -> String {
        let rootLowerBound = svgOpeningTagRegex.firstMatch(
            in: text,
            range: NSRange(text.startIndex..<text.endIndex, in: text)
        )?.range.location

        return nestedSVGRegex.matches(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text))
            .reversed()
            .reduce(into: text) { partialText, match in
                guard match.range.location != rootLowerBound,
                      let fullRange = Range(match.range, in: partialText),
                      let attributeText = captureGroupValue(in: partialText, match: match, group: 1),
                      let innerContent = captureGroupValue(in: partialText, match: match, group: 2) else {
                    return
                }

                let attributes = SVGLayoutAttributeList(attributeText: attributeText)

                guard let viewBox = attributes.value(for: "viewBox").flatMap(SVGViewBox.init(rawValue:)),
                      let width = numericValue(attributes.value(for: "width")),
                      let height = numericValue(attributes.value(for: "height")),
                      let x = numericValue(attributes.value(for: "x") ?? "0"),
                      let y = numericValue(attributes.value(for: "y") ?? "0"),
                      width > 0,
                      height > 0,
                      viewBox.width > 0,
                      viewBox.height > 0 else {
                    appendUnique("Unsupported nested SVG layout could not be normalized", to: &warnings)
                    return
                }

                let scaleX = width / viewBox.width
                let scaleY = height / viewBox.height
                let transform = "translate(\(formatNumber(x)) \(formatNumber(y))) scale(\(formatNumber(scaleX)) \(formatNumber(scaleY)))"
                let replacement = #"<g transform="\#(transform)">\#(innerContent)</g>"#

                partialText.replaceSubrange(fullRange, with: replacement)
                appendUnique("Flattened nested SVG layout into transform", to: &warnings)
            }
    }

    private static func replacingOrAddingAttribute(_ name: String, value: String, in openingTag: String) -> String {
        let pattern = #"\s+\#(NSRegularExpression.escapedPattern(for: name))\s*=\s*(?:"[^"]*"|'[^']*')"#
        let regex = makeRegularExpression(pattern)
        let range = NSRange(openingTag.startIndex..<openingTag.endIndex, in: openingTag)

        if regex.firstMatch(in: openingTag, range: range) != nil {
            return regex.stringByReplacingMatches(
                in: openingTag,
                range: range,
                withTemplate: #" \#(name)="\#(value)""#
            )
        }

        guard openingTag.hasSuffix("/>") else {
            return String(openingTag.dropLast()) + #" \#(name)="\#(value)">"#
        }

        return String(openingTag.dropLast(2)) + #" \#(name)="\#(value)" />"#
    }

    private static func numericValue(_ value: String?) -> Double? {
        guard let value else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasSuffix("%") == false else {
            return nil
        }

        return Double(trimmed)
    }

    private static func percentageValue(_ value: String) -> Double? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.hasSuffix("%") else {
            return nil
        }

        let numericPart = String(trimmed.dropLast())

        guard let numeric = Double(numericPart), numeric >= 0 else {
            return nil
        }

        return numeric / 100
    }

    private static func formatNumber(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }

        return String(format: "%.6f", value)
            .replacingOccurrences(of: #"0+$"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
    }

    private static func captureGroupValue(in text: String, match: NSTextCheckingResult, group: Int) -> String? {
        guard match.numberOfRanges > group,
              let range = Range(match.range(at: group), in: text) else {
            return nil
        }

        return String(text[range])
    }

    private static func appendUnique(_ warning: String, to warnings: inout [String]) {
        guard warnings.contains(warning) == false else {
            return
        }

        warnings.append(warning)
    }

    private static let svgOpeningTagRegex = makeRegularExpression(#"<svg\b([^>]*)>"#)
    private static let nestedSVGRegex = makeRegularExpression(#"<svg\b([^>]*)>((?:(?!<svg\b)[\s\S])*?)</svg\s*>"#)

    private static func makeRegularExpression(_ pattern: String) -> NSRegularExpression {
        // Patterns are static and covered by tests; construction failure is a programmer error.
        try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }
}

private struct SVGViewBox {
    let minX: Double
    let minY: Double
    let width: Double
    let height: Double

    init?(rawValue: String) {
        let components = rawValue
            .replacingOccurrences(of: ",", with: " ")
            .split(separator: " ")
            .compactMap { Double($0) }

        guard components.count == 4,
              components[2] > 0,
              components[3] > 0 else {
            return nil
        }

        minX = components[0]
        minY = components[1]
        width = components[2]
        height = components[3]
    }
}

private struct SVGLayoutAttributeList {
    private var attributes: [String: String] = [:]

    init(attributeText: String) {
        SVGLayoutAttributeList.attributeRegex.matches(
            in: attributeText,
            range: NSRange(attributeText.startIndex..<attributeText.endIndex, in: attributeText)
        ).forEach { match in
            guard let name = SVGLayoutAttributeList.captureGroupValue(in: attributeText, match: match, group: 1),
                  let value = SVGLayoutAttributeList.captureGroupValue(in: attributeText, match: match, group: 2)
                    ?? SVGLayoutAttributeList.captureGroupValue(in: attributeText, match: match, group: 3) else {
                return
            }

            attributes[name.lowercased()] = value
        }
    }

    func value(for name: String) -> String? {
        attributes[name.lowercased()]
    }

    private static func captureGroupValue(in text: String, match: NSTextCheckingResult, group: Int) -> String? {
        guard match.numberOfRanges > group,
              let range = Range(match.range(at: group), in: text) else {
            return nil
        }

        return String(text[range])
    }

    private static let attributeRegex = makeRegularExpression(#"([A-Za-z_:][-A-Za-z0-9_:.]*)\s*=\s*(?:"([^"]*)"|'([^']*)')"#)

    private static func makeRegularExpression(_ pattern: String) -> NSRegularExpression {
        // Patterns are static and covered by tests; construction failure is a programmer error.
        try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }
}
