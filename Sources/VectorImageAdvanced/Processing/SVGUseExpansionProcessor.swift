//
//  SVGUseExpansionProcessor.swift
//  VectorImageAdvanced
//
//  Expands deterministic local SVG <use> references before Core rendering.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

enum SVGUseExpansionProcessor {
    static func process(_ svgText: String) -> (svgText: String, warnings: [String]) {
        var warnings: [String] = []
        var expandedDefinitionIDs = Set<String>()
        let definitions = SVGDefinitionCollector.collect(from: svgText)
        var expanded = expandUses(
            in: svgText,
            definitions: definitions,
            stack: [],
            expandedDefinitionIDs: &expandedDefinitionIDs,
            warnings: &warnings
        )
        expanded = removeExpandedDefinitions(from: expanded, ids: expandedDefinitionIDs)

        return (expanded, warnings)
    }

    private static func expandUses(
        in text: String,
        definitions: [String: SVGDefinition],
        stack: [String],
        expandedDefinitionIDs: inout Set<String>,
        warnings: inout [String]
    ) -> String {
        useRegex.matches(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text))
            .reversed()
            .reduce(into: text) { partialText, match in
                guard let fullRange = Range(match.range, in: partialText),
                      let attributeText = captureGroupValue(in: partialText, match: match, group: 1)
                        ?? captureGroupValue(in: partialText, match: match, group: 2) else {
                    return
                }

                let attributes = SVGUseAttributeList(attributeText: attributeText)

                guard let href = attributes.value(for: "href") ?? attributes.value(for: "xlink:href") else {
                    appendUnique("Unsupported SVG use reference could not be resolved: missing href", to: &warnings)
                    partialText.replaceSubrange(fullRange, with: "")
                    return
                }

                guard href.hasPrefix("#") else {
                    appendUnique("Unsupported external SVG use reference: \(href)", to: &warnings)
                    partialText.replaceSubrange(fullRange, with: "")
                    return
                }

                let id = String(href.dropFirst())

                guard stack.contains(id) == false else {
                    appendUnique("Unsupported recursive SVG use reference: #\(id)", to: &warnings)
                    partialText.replaceSubrange(fullRange, with: "")
                    return
                }

                guard let definition = definitions[id] else {
                    appendUnique("Unsupported SVG use reference could not be resolved: #\(id)", to: &warnings)
                    partialText.replaceSubrange(fullRange, with: "")
                    return
                }

                var content = definition.renderableContent
                content = expandUses(
                    in: content,
                    definitions: definitions,
                    stack: stack + [id],
                    expandedDefinitionIDs: &expandedDefinitionIDs,
                    warnings: &warnings
                )
                content = applyingUseAttributes(attributes, to: content)
                expandedDefinitionIDs.insert(id)
                appendUnique("Expanded local SVG use reference: #\(id)", to: &warnings)
                partialText.replaceSubrange(fullRange, with: content)
            }
    }

    private static func applyingUseAttributes(_ useAttributes: SVGUseAttributeList, to content: String) -> String {
        let x = useAttributes.value(for: "x")
        let y = useAttributes.value(for: "y")

        guard x != nil || y != nil else {
            return content
        }

        let translate = "translate(\(x ?? "0") \(y ?? "0"))"

        guard let firstTagMatch = openingTagRegex.firstMatch(
            in: content,
            range: NSRange(content.startIndex..<content.endIndex, in: content)
        ),
              let tagRange = Range(firstTagMatch.range, in: content),
              let tagName = captureGroupValue(in: content, match: firstTagMatch, group: 1),
              let attributeText = captureGroupValue(in: content, match: firstTagMatch, group: 2) else {
            return #"<g transform="\#(translate)">\#(content)</g>"#
        }

        let attributes = SVGUseAttributeList(attributeText: attributeText)
        let existingTransform = attributes.value(for: "transform")
        let replacementTransform = existingTransform.map { "\(translate) \($0)" } ?? translate
        let originalTag = String(content[tagRange])
        let replacementTag: String

        if attributes.contains("transform") {
            replacementTag = transformAttributeRegex.stringByReplacingMatches(
                in: originalTag,
                range: NSRange(originalTag.startIndex..<originalTag.endIndex, in: originalTag),
                withTemplate: #" transform="\#(replacementTransform)""#
            )
        } else if originalTag.hasSuffix("/>") {
            replacementTag = String(originalTag.dropLast(2)) + " transform=\"\(replacementTransform)\" />"
        } else {
            replacementTag = "<\(tagName)\(attributeText) transform=\"\(replacementTransform)\">"
        }

        var result = content
        result.replaceSubrange(tagRange, with: replacementTag)
        return result
    }

    private static func removeExpandedDefinitions(from text: String, ids: Set<String>) -> String {
        guard ids.isEmpty == false else {
            return text
        }

        return defsRegex.matches(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text))
            .reversed()
            .reduce(into: text) { partialText, match in
                guard let fullRange = Range(match.range, in: partialText),
                      let innerContent = captureGroupValue(in: partialText, match: match, group: 1) else {
                    return
                }

                let cleanedInnerContent = removeDefinitionElements(from: innerContent, ids: ids)

                if cleanedInnerContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    partialText.replaceSubrange(fullRange, with: "")
                } else {
                    partialText.replaceSubrange(fullRange, with: "<defs>\(cleanedInnerContent)</defs>")
                }
            }
    }

    private static func removeDefinitionElements(from text: String, ids: Set<String>) -> String {
        definitionElementRegex.matches(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text))
            .reversed()
            .reduce(into: text) { partialText, match in
                guard let fullRange = Range(match.range, in: partialText),
                      let attributeText = captureGroupValue(in: partialText, match: match, group: 2) else {
                    return
                }

                let attributes = SVGUseAttributeList(attributeText: attributeText)

                guard let id = attributes.value(for: "id"), ids.contains(id) else {
                    return
                }

                partialText.replaceSubrange(fullRange, with: "")
            }
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

    private static let useRegex = makeRegularExpression(#"<use\b([^>]*)>\s*</use\s*>|<use\b([^>]*)/\s*>"#)
    private static let defsRegex = makeRegularExpression(#"<defs\b[^>]*>([\s\S]*?)</defs\s*>"#)
    private static let definitionElementRegex = makeRegularExpression(#"<(symbol|g)\b([^>]*)>[\s\S]*?</\1\s*>"#)
    private static let openingTagRegex = makeRegularExpression(#"<([A-Za-z_:][-A-Za-z0-9_:.]*)([^>]*)>"#)
    private static let transformAttributeRegex = makeRegularExpression(#"\s+transform\s*=\s*(?:"[^"]*"|'[^']*')"#)

    private static func makeRegularExpression(_ pattern: String) -> NSRegularExpression {
        // Patterns are static and covered by tests; construction failure is a programmer error.
        try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }
}

private struct SVGDefinition {
    let tagName: String
    let attributeText: String
    let innerContent: String

    var renderableContent: String {
        if tagName.caseInsensitiveCompare("symbol") == .orderedSame {
            innerContent
        } else {
            "<\(tagName)\(attributeText)>\(innerContent)</\(tagName)>"
        }
    }
}

private enum SVGDefinitionCollector {
    static func collect(from svgText: String) -> [String: SVGDefinition] {
        definitionRegex.matches(in: svgText, range: NSRange(svgText.startIndex..<svgText.endIndex, in: svgText))
            .reduce(into: [:]) { definitions, match in
                guard let tagName = captureGroupValue(in: svgText, match: match, group: 1),
                      let attributeText = captureGroupValue(in: svgText, match: match, group: 2),
                      let innerContent = captureGroupValue(in: svgText, match: match, group: 3) else {
                    return
                }

                let attributes = SVGUseAttributeList(attributeText: attributeText)

                guard let id = attributes.value(for: "id") else {
                    return
                }

                definitions[id] = SVGDefinition(
                    tagName: tagName,
                    attributeText: attributeText,
                    innerContent: innerContent
                )
            }
    }

    private static func captureGroupValue(in text: String, match: NSTextCheckingResult, group: Int) -> String? {
        guard match.numberOfRanges > group,
              let range = Range(match.range(at: group), in: text) else {
            return nil
        }

        return String(text[range])
    }

    private static let definitionRegex = makeRegularExpression(#"<(symbol|g)\b([^>]*)>([\s\S]*?)</\1\s*>"#)

    private static func makeRegularExpression(_ pattern: String) -> NSRegularExpression {
        // Patterns are static and covered by tests; construction failure is a programmer error.
        try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }
}

private struct SVGUseAttributeList {
    private var attributes: [String: String] = [:]

    init(attributeText: String) {
        let text = attributeText
        let matches = Self.attributeRegex.matches(
            in: text,
            range: NSRange(text.startIndex..<text.endIndex, in: text)
        )

        for match in matches {
            guard let name = Self.captureGroupValue(in: text, match: match, group: 1),
                  let value = Self.captureGroupValue(in: text, match: match, group: 2) ?? Self.captureGroupValue(in: text, match: match, group: 3) else {
                continue
            }

            attributes[name] = value
        }
    }

    func value(for name: String) -> String? {
        attributes[name]
    }

    func contains(_ name: String) -> Bool {
        attributes[name] != nil
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
