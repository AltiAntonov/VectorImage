//
//  SVGStyleSheet.swift
//  VectorImageCore
//
//  Parses a focused subset of SVG CSS presentation rules.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

struct SVGStyleSheet {
    private let rules: [Rule]

    init(data: Data) {
        let source = String(decoding: data, as: UTF8.self)
        rules = Self.parseRules(from: source)
    }

    func mergedAttributes(for attributes: [String: String], elementName: String) -> [String: String] {
        let normalizedAttributes = SVGAttributeParser.normalizedAttributes(from: attributes)
        let matchingRules = rules.filter { $0.matches(attributes: normalizedAttributes, elementName: elementName) }
        guard matchingRules.isEmpty == false else {
            return normalizedAttributes
        }

        var merged: [String: String] = [:]
        for rule in matchingRules {
            for (key, value) in rule.declarations {
                merged[key] = value
            }
        }
        for (key, value) in normalizedAttributes {
            merged[key] = value
        }
        return merged
    }

    private static func parseRules(from source: String) -> [Rule] {
        var rules: [Rule] = []
        for body in styleBodies(in: source) {
            let bodyWithoutComments = removeCSSComments(from: body)
            rules.append(contentsOf: parseRules(inStyleBody: bodyWithoutComments))
        }
        return rules
    }

    private static func styleBodies(in source: String) -> [String] {
        var bodies: [String] = []
        var searchStart = source.startIndex

        while let openingRange = source.range(of: "<style", range: searchStart..<source.endIndex),
              let openingEnd = source.range(of: ">", range: openingRange.upperBound..<source.endIndex),
              let closingRange = source.range(of: "</style>", options: [.caseInsensitive], range: openingEnd.upperBound..<source.endIndex) {
            bodies.append(String(source[openingEnd.upperBound..<closingRange.lowerBound]))
            searchStart = closingRange.upperBound
        }

        return bodies
    }

    private static func removeCSSComments(from source: String) -> String {
        var output = ""
        var index = source.startIndex

        while index < source.endIndex {
            if source[index...].hasPrefix("/*"),
               let closingRange = source.range(of: "*/", range: source.index(index, offsetBy: 2)..<source.endIndex) {
                index = closingRange.upperBound
            } else {
                output.append(source[index])
                index = source.index(after: index)
            }
        }

        return output
    }

    private static func parseRules(inStyleBody body: String) -> [Rule] {
        var rules: [Rule] = []
        var searchStart = body.startIndex

        while let openingBrace = body[searchStart...].firstIndex(of: "{"),
              let closingBrace = body[openingBrace...].firstIndex(of: "}") {
            let selectorText = String(body[searchStart..<openingBrace])
            let declarationText = String(body[body.index(after: openingBrace)..<closingBrace])
            let declarations = SVGAttributeParser.normalizedAttributes(from: parseDeclarations(declarationText))

            if declarations.isEmpty == false {
                let selectors = selectorText
                    .split(separator: ",")
                    .map { Selector(rawValue: String($0)) }
                    .filter(\.isSupported)
                for selector in selectors {
                    rules.append(Rule(selector: selector, declarations: declarations))
                }
            }

            searchStart = body.index(after: closingBrace)
        }

        return rules
    }

    private static func parseDeclarations(_ source: String) -> [String: String] {
        var declarations: [String: String] = [:]

        for declaration in source.split(separator: ";") {
            let parts = declaration.split(separator: ":", maxSplits: 1).map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            guard parts.count == 2, parts[0].isEmpty == false, parts[1].isEmpty == false else {
                continue
            }
            declarations[parts[0]] = parts[1]
        }

        return declarations
    }

    private struct Rule {
        let selector: Selector
        let declarations: [String: String]

        func matches(attributes: [String: String], elementName: String) -> Bool {
            selector.matches(attributes: attributes, elementName: elementName)
        }
    }

    private struct Selector {
        let elementName: String?
        let id: String?
        let classes: Set<String>
        let isSingleCompoundSelector: Bool

        var isSupported: Bool {
            isSingleCompoundSelector && (elementName != nil || id != nil || classes.isEmpty == false)
        }

        init(rawValue: String) {
            let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            isSingleCompoundSelector = trimmed.contains(where: { character in
                character.isWhitespace || character == ">" || character == "+" || character == "~" || character == "[" || character == ":" || character == "*"
            }) == false

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
                    break
                default:
                    token.append(character)
                }
            }
            flushToken()

            self.elementName = elementName
            self.id = id
            self.classes = classes
        }

        func matches(attributes: [String: String], elementName: String) -> Bool {
            if let selectorElementName = self.elementName, selectorElementName != elementName {
                return false
            }

            if let id, attributes["id"] != id {
                return false
            }

            let elementClasses = Set((attributes["class"] ?? "").split(whereSeparator: \.isWhitespace).map(String.init))
            return classes.isSubset(of: elementClasses)
        }
    }

    private enum SelectorMode {
        case element
        case id
        case `class`
    }
}
