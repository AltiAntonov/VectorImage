//
//  SVGTransformParser.swift
//  VectorImageCore
//
//  Parses a focused subset of SVG transform functions into affine transforms.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import CoreGraphics
import Foundation

enum SVGTransformParser {
    static func parse(_ value: String?) -> CGAffineTransform? {
        guard let value else { return nil }

        var transform = CGAffineTransform.identity
        var matchedAny = false

        for (name, parameters) in transformFunctions(in: value) {
            matchedAny = true

            let nextTransform: CGAffineTransform
            switch name {
            case "translate":
                let tx = parameters[safe: 0] ?? 0
                let ty = parameters[safe: 1] ?? 0
                nextTransform = .init(translationX: tx, y: ty)
            case "scale":
                let sx = parameters[safe: 0] ?? 1
                let sy = parameters[safe: 1] ?? sx
                nextTransform = .init(scaleX: sx, y: sy)
            case "matrix":
                guard parameters.count == 6 else { continue }
                nextTransform = CGAffineTransform(
                    a: parameters[0],
                    b: parameters[1],
                    c: parameters[2],
                    d: parameters[3],
                    tx: parameters[4],
                    ty: parameters[5]
                )
            default:
                continue
            }

            // SVG transform lists are applied in document order, while
            // CoreGraphics concatenation applies the right-hand transform first.
            transform = nextTransform.concatenating(transform)
        }

        return matchedAny ? transform : nil
    }

    private static func parseParameters(_ input: String) -> [CGFloat] {
        input
            .split(whereSeparator: { $0 == "," || $0 == " " || $0 == "\n" || $0 == "\t" })
            .compactMap { Double($0) }
            .map { CGFloat($0) }
    }

    private static func transformFunctions(in input: String) -> [(String, [CGFloat])] {
        var functions: [(String, [CGFloat])] = []
        var currentIndex = input.startIndex

        while currentIndex < input.endIndex {
            while currentIndex < input.endIndex, input[currentIndex].isWhitespace {
                currentIndex = input.index(after: currentIndex)
            }

            let nameStart = currentIndex
            while currentIndex < input.endIndex, input[currentIndex].isLetter {
                currentIndex = input.index(after: currentIndex)
            }

            guard nameStart < currentIndex else { break }
            let name = String(input[nameStart..<currentIndex])

            while currentIndex < input.endIndex, input[currentIndex].isWhitespace {
                currentIndex = input.index(after: currentIndex)
            }

            guard currentIndex < input.endIndex, input[currentIndex] == "(" else { break }
            currentIndex = input.index(after: currentIndex)
            let parameterStart = currentIndex

            while currentIndex < input.endIndex, input[currentIndex] != ")" {
                currentIndex = input.index(after: currentIndex)
            }

            guard currentIndex < input.endIndex else { break }
            let parameterString = String(input[parameterStart..<currentIndex])
            functions.append((name, parseParameters(parameterString)))
            currentIndex = input.index(after: currentIndex)
        }

        return functions
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
