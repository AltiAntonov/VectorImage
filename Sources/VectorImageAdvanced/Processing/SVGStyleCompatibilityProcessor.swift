//
//  SVGStyleCompatibilityProcessor.swift
//  VectorImageAdvanced
//
//  Normalizes a focused subset of SVG style declarations into presentation attributes.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

enum SVGStyleCompatibilityProcessor {
    static func process(_ svgText: String) -> (svgText: String, warnings: [String]) {
        let styleSheet = StyleSheet.parse(from: svgText)
        var warnings = styleSheet.warnings
        var output = removeStyleBlocks(from: svgText)

        output = rewriteStartTags(in: output, rules: styleSheet.rules, warnings: &warnings)

        return (output, warnings)
    }

    private static func removeStyleBlocks(from text: String) -> String {
        replaceMatches(#"<style\b[^>]*>[\s\S]*?</style\s*>"#, in: text, with: "")
    }

    private static func rewriteStartTags(
        in text: String,
        rules: [StyleRule],
        warnings: inout [String]
    ) -> String {
        let regex = makeRegularExpression(#"<([A-Za-z][A-Za-z0-9:_-]*)([^<>]*?)(/?)>"#)
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text))

        return matches.reversed().reduce(into: text) { partialText, match in
            guard let fullRange = Range(match.range, in: partialText),
                  let elementNameRange = Range(match.range(at: 1), in: partialText),
                  let attributeRange = Range(match.range(at: 2), in: partialText),
                  let selfClosingRange = Range(match.range(at: 3), in: partialText) else {
                return
            }

            let elementName = String(partialText[elementNameRange])
            guard elementName.lowercased() != "style" else {
                return
            }

            let attributeText = String(partialText[attributeRange])
            var attributes = SVGAttributeList.parse(attributeText)
            let selfClosing = String(partialText[selfClosingRange])
            var didChangeAttributes = false

            let matchingRules = rules.filter { $0.selector.matches(elementName: elementName, attributes: attributes) }
            if matchingRules.isEmpty == false {
                for rule in matchingRules {
                    for (name, value) in rule.declarations where attributes.value(for: name) == nil {
                        attributes.set(name: name, value: value)
                        didChangeAttributes = true
                    }
                }
                appendUnique("Inlined supported SVG stylesheet rules", to: &warnings)
            }

            if let inlineStyle = attributes.value(for: "style") {
                let declarations = StyleDeclarationParser.parse(inlineStyle)
                if declarations.isEmpty == false {
                    attributes.remove(name: "style")
                    for (name, value) in declarations {
                        attributes.set(name: name, value: value)
                    }
                    didChangeAttributes = true
                    appendUnique("Inlined SVG style declarations from attribute: style", to: &warnings)
                }
            }

            guard didChangeAttributes else {
                return
            }

            let replacement = "<\(elementName)\(attributes.serialized())\(selfClosing)>"
            partialText.replaceSubrange(fullRange, with: replacement)
        }
    }

    private static func replaceMatches(_ pattern: String, in text: String, with replacement: String) -> String {
        makeRegularExpression(pattern).stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..<text.endIndex, in: text),
            withTemplate: replacement
        )
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

private struct StyleSheet {
    let rules: [StyleRule]
    let warnings: [String]

    static func parse(from svgText: String) -> StyleSheet {
        var rules: [StyleRule] = []
        var warnings: [String] = []

        for body in styleBodies(in: svgText) {
            let bodyWithoutComments = removeCSSComments(from: body)
            let parsed = parseRules(inStyleBody: bodyWithoutComments)
            rules.append(contentsOf: parsed.rules)
            warnings.append(contentsOf: parsed.warnings)
        }

        return StyleSheet(rules: rules, warnings: warnings)
    }

    private static func styleBodies(in source: String) -> [String] {
        let regex = try! NSRegularExpression(pattern: #"<style\b[^>]*>([\s\S]*?)</style\s*>"#, options: [.caseInsensitive])
        let matches = regex.matches(in: source, range: NSRange(source.startIndex..<source.endIndex, in: source))

        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: source) else {
                return nil
            }

            return String(source[range])
        }
    }

    private static func removeCSSComments(from source: String) -> String {
        let regex = try! NSRegularExpression(pattern: #"/\*[\s\S]*?\*/"#)
        return regex.stringByReplacingMatches(
            in: source,
            range: NSRange(source.startIndex..<source.endIndex, in: source),
            withTemplate: ""
        )
    }

    private static func parseRules(inStyleBody body: String) -> (rules: [StyleRule], warnings: [String]) {
        var rules: [StyleRule] = []
        var warnings: [String] = []
        var searchStart = body.startIndex

        while let openingBrace = body[searchStart...].firstIndex(of: "{"),
              let closingBrace = body[openingBrace...].firstIndex(of: "}") {
            let selectorText = String(body[searchStart..<openingBrace])
            let declarationText = String(body[body.index(after: openingBrace)..<closingBrace])
            let declarations = StyleDeclarationParser.parse(declarationText)

            for rawSelector in selectorText.split(separator: ",").map(String.init) {
                let selector = StyleSelector(rawValue: rawSelector)
                if selector.isSupported, declarations.isEmpty == false {
                    rules.append(StyleRule(selector: selector, declarations: declarations))
                } else if rawSelector.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                    warnings.append(
                        "Unsupported SVG stylesheet rule preserved as diagnostic: \(rawSelector.trimmingCharacters(in: .whitespacesAndNewlines))"
                    )
                }
            }

            searchStart = body.index(after: closingBrace)
        }

        return (rules, warnings)
    }
}

private struct StyleRule {
    let selector: StyleSelector
    let declarations: [(name: String, value: String)]
}

private struct StyleSelector {
    let elementName: String?
    let id: String?
    let classes: Set<String>
    let isSingleCompoundSelector: Bool

    var isSupported: Bool {
        isSingleCompoundSelector && (elementName != nil || id != nil || classes.isEmpty == false)
    }

    init(rawValue: String) {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        isSingleCompoundSelector = trimmed.contains { character in
            character.isWhitespace || character == ">" || character == "+" || character == "~" || character == "[" || character == ":" || character == "*"
        } == false && trimmed.hasPrefix("@") == false

        var elementName: String?
        var id: String?
        var classes = Set<String>()
        var token = ""
        var mode: SelectorMode = .element

        func flushToken() {
            guard token.isEmpty == false else { return }
            switch mode {
            case .element:
                elementName = token
            case .id:
                id = token
            case .class:
                classes.insert(token)
            }
            token = ""
        }

        for character in trimmed {
            switch character {
            case ".":
                flushToken()
                mode = .class
            case "#":
                flushToken()
                mode = .id
            case " ", "\n", "\t", ">", "+", "~", "[", ":", "*":
                flushToken()
                mode = .element
                token = ""
            default:
                token.append(character)
            }
        }
        flushToken()

        self.elementName = elementName
        self.id = id
        self.classes = classes
    }

    func matches(elementName: String, attributes: SVGAttributeList) -> Bool {
        if let selectorElementName = self.elementName, selectorElementName != elementName {
            return false
        }

        if let id, attributes.value(for: "id") != id {
            return false
        }

        let elementClasses = Set((attributes.value(for: "class") ?? "").split(whereSeparator: \.isWhitespace).map(String.init))
        return classes.isSubset(of: elementClasses)
    }

    private enum SelectorMode {
        case element
        case id
        case `class`
    }
}

private enum StyleDeclarationParser {
    static func parse(_ source: String) -> [(name: String, value: String)] {
        source.split(separator: ";").compactMap { declaration in
            let parts = declaration.split(separator: ":", maxSplits: 1).map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            guard parts.count == 2, parts[0].isEmpty == false, parts[1].isEmpty == false else {
                return nil
            }

            return (name: parts[0], value: parts[1])
        }
    }
}

private struct SVGAttributeList {
    private var attributes: [(name: String, value: String)]

    static func parse(_ source: String) -> SVGAttributeList {
        let regex = try! NSRegularExpression(
            pattern: #"([A-Za-z_:][-A-Za-z0-9_:.]*)\s*=\s*("[^"]*"|'[^']*')"#
        )
        let matches = regex.matches(in: source, range: NSRange(source.startIndex..<source.endIndex, in: source))
        let attributes = matches.compactMap { match -> (name: String, value: String)? in
            guard let nameRange = Range(match.range(at: 1), in: source),
                  let valueRange = Range(match.range(at: 2), in: source) else {
                return nil
            }

            let quotedValue = String(source[valueRange])
            return (name: String(source[nameRange]), value: String(quotedValue.dropFirst().dropLast()))
        }

        return SVGAttributeList(attributes: attributes)
    }

    func value(for name: String) -> String? {
        attributes.last { $0.name == name }?.value
    }

    mutating func set(name: String, value: String) {
        if let index = attributes.lastIndex(where: { $0.name == name }) {
            attributes[index].value = value
        } else {
            attributes.append((name: name, value: value))
        }
    }

    mutating func remove(name: String) {
        attributes.removeAll { $0.name == name }
    }

    func serialized() -> String {
        guard attributes.isEmpty == false else {
            return ""
        }

        return attributes.map { attribute in
            #" \#(attribute.name)="\#(escaped(attribute.value))""#
        }.joined()
    }

    private func escaped(_ value: String) -> String {
        value.replacingOccurrences(of: "\"", with: "&quot;")
    }
}
