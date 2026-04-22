//
//  SVGAttributeParser.swift
//  VectorImageCore
//
//  Normalizes SVG element attributes including inline style declarations.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

enum SVGAttributeParser {
    static func normalizedAttributes(from attributes: [String: String]) -> [String: String] {
        var resolved = attributes

        if let style = attributes["style"] {
            for declaration in style.split(separator: ";") {
                let parts = declaration.split(separator: ":", maxSplits: 1).map {
                    $0.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                guard parts.count == 2, parts[0].isEmpty == false, parts[1].isEmpty == false else {
                    continue
                }
                resolved[parts[0]] = parts[1]
            }
        }

        return resolved
    }
}
