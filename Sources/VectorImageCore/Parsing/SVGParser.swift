//
//  SVGParser.swift
//  VectorImageCore
//
//  Parses a focused SVG subset into the internal document model.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import CoreGraphics
import Foundation

final class SVGParser: NSObject {
    private let data: Data
    private var nodes: [SVGNode] = []
    private var clipPathsByID: [String: CGPath] = [:]
    private var groupClipPathReferenceStack: [String?] = [nil]
    private var groupTransformStack: [CGAffineTransform] = [.identity]
    private var inheritedStyleAttributesStack: [[String: String]] = [[:]]
    private var gradientsByID: [String: SVGGradient] = [:]
    private var canvasWidth: CGFloat?
    private var canvasHeight: CGFloat?
    private var viewBox: CGRect?
    private(set) var diagnostics = VectorImageDiagnostics()
    private var parsingError: (any Error)?
    private var isInsideDefinitions = false
    private var currentClipPathDefinitionID: String?
    private var currentGradientDefinitionKind: GradientDefinitionKind?
    private var currentGradientDefinitionID: String?
    private var currentGradientStops: [GradientStop] = []

    init(data: Data) {
        self.data = data
    }

    func parse() throws -> SVGDocument {
        guard !data.isEmpty else {
            throw VectorImageError.emptyData
        }

        guard VectorImageDetector.isSVG(data: data) else {
            throw VectorImageError.notSVG
        }

        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = false
        parser.shouldResolveExternalEntities = false

        guard parser.parse() else {
            throw parsingError ?? parser.parserError ?? VectorImageError.invalidXML
        }

        let size = resolvedCanvasSize()
        guard size.width > 0, size.height > 0 else {
            throw VectorImageError.invalidDocumentSize
        }

        let resolvedNodes = nodes.map { node in
            let resolvedFillGradient = node.style.fillGradient
                ?? node.style.fillGradientIdentifier.flatMap { gradientsByID[$0] }
            return SVGNode(
                path: node.path,
                style: SVGStyle(
                    fillColor: resolvedFillGradient == nil ? node.style.fillColor : nil,
                    fillGradient: resolvedFillGradient,
                    fillGradientIdentifier: node.style.fillGradientIdentifier,
                    strokeColor: node.style.strokeColor,
                    strokeWidth: node.style.strokeWidth,
                    fillRule: node.style.fillRule
                ),
                clipPath: node.clipPath ?? node.clipPathIdentifier.flatMap { clipPathsByID[$0] },
                clipPathIdentifier: node.clipPathIdentifier
            )
        }

        return SVGDocument(canvasSize: size, nodes: resolvedNodes)
    }

    private func resolvedCanvasSize() -> CGSize {
        if let width = canvasWidth, let height = canvasHeight, width > 0, height > 0 {
            return CGSize(width: width, height: height)
        }

        if let viewBox {
            return viewBox.size
        }

        return .zero
    }

    private func parseSize(_ value: String?) -> CGFloat? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = trimmed.filter { $0.isNumber || $0 == "." || $0 == "-" }
        guard let number = Double(filtered) else { return nil }
        return CGFloat(number)
    }

    private func parseViewBox(_ value: String?) -> CGRect? {
        guard let value else { return nil }
        let parts = value
            .split(whereSeparator: { $0 == " " || $0 == "," || $0 == "\n" || $0 == "\t" })
            .compactMap { Double($0) }
        guard parts.count == 4 else { return nil }
        return CGRect(x: parts[0], y: parts[1], width: parts[2], height: parts[3])
    }

    private func style(attributes: [String: String]) -> SVGStyle {
        let effectiveAttributes = mergedAttributes(for: attributes)
        let fillGradientIdentifier = resolvedFillGradientIdentifier(from: effectiveAttributes)
        let fillGradient = fillGradientIdentifier.flatMap { gradientsByID[$0] }
        let fill = fillGradientIdentifier == nil ? resolvedFillColor(from: effectiveAttributes) : nil
        let stroke = SVGColorParser.color(
            from: effectiveAttributes["stroke"],
            opacity: effectiveAttributes["stroke-opacity"] ?? effectiveAttributes["opacity"],
            defaultColor: nil
        )
        let strokeWidth = parseSize(effectiveAttributes["stroke-width"]) ?? 1
        let fillRule: SVGFillRule = effectiveAttributes["fill-rule"] == "evenodd" ? .evenOdd : .nonZero
        return SVGStyle(
            fillColor: fill,
            fillGradient: fillGradient,
            fillGradientIdentifier: fillGradientIdentifier,
            strokeColor: stroke,
            strokeWidth: strokeWidth,
            fillRule: fillRule
        )
    }

    private func resolvedFillGradientIdentifier(from attributes: [String: String]) -> String? {
        guard let fillValue = attributes["fill"],
              let gradientID = paintServerReference(from: fillValue) else {
            return nil
        }

        return gradientID
    }

    private func resolvedFillColor(from attributes: [String: String]) -> CGColor? {
        return SVGColorParser.color(
            from: attributes["fill"],
            opacity: attributes["fill-opacity"] ?? attributes["opacity"],
            defaultColor: SVGColorParser.defaultBlack()
        )
    }

    private func appendNode(path: CGPath, attributes: [String: String]) {
        let transformedPath = transformed(path: path, attributes: attributes)
        nodes.append(
            SVGNode(
                path: transformedPath,
                style: style(attributes: attributes),
                clipPath: nil,
                clipPathIdentifier: resolvedClipPathReference(from: attributes)
            )
        )
    }

    private func mergedAttributes(for attributes: [String: String]) -> [String: String] {
        var merged = inheritedStyleAttributesStack.last ?? [:]
        for (key, value) in attributes {
            merged[key] = value
        }
        return merged
    }

    private func inheritableStyleAttributes(from attributes: [String: String]) -> [String: String] {
        let inheritableKeys = [
            "fill",
            "fill-opacity",
            "stroke",
            "stroke-opacity",
            "stroke-width",
            "opacity",
            "fill-rule"
        ]

        var merged = inheritedStyleAttributesStack.last ?? [:]
        for key in inheritableKeys {
            if let value = attributes[key] {
                merged[key] = value
            }
        }
        return merged
    }

    private func clipPathReference(from value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("url(#"), trimmed.hasSuffix(")") else { return nil }
        return String(trimmed.dropFirst(5).dropLast())
    }

    private func paintServerReference(from value: String?) -> String? {
        clipPathReference(from: value)
    }

    private func resolvedClipPathReference(from attributes: [String: String]) -> String? {
        clipPathReference(from: attributes["clip-path"]) ?? groupClipPathReferenceStack.last ?? nil
    }

    private func storeClipPathIfNeeded(_ path: CGPath, attributes: [String: String]) {
        guard let currentClipPathDefinitionID else { return }
        clipPathsByID[currentClipPathDefinitionID] = transformed(path: path, attributes: attributes)
    }

    private func transformed(path: CGPath, attributes: [String: String]) -> CGPath {
        var transform = groupTransformStack.last ?? .identity
        if let localTransform = SVGTransformParser.parse(attributes["transform"]) {
            transform = transform.concatenating(localTransform)
        }

        guard transform.isIdentity == false else { return path }

        return path.copy(using: &transform) ?? path
    }

    private func storeGradientIfNeeded() {
        guard let currentGradientDefinitionID,
              let currentGradientDefinitionKind,
              currentGradientStops.isEmpty == false else { return }

        let sortedStops = currentGradientStops.sorted { $0.offset < $1.offset }
        gradientsByID[currentGradientDefinitionID] = SVGGradient(
            kind: currentGradientDefinitionKind.makeKind(),
            colors: sortedStops.map(\.color),
            locations: sortedStops.map(\.offset)
        )
    }

    private struct GradientStop {
        let offset: CGFloat
        let color: CGColor
    }

    private enum GradientDefinitionKind {
        case linear(x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat, transform: CGAffineTransform)
        case radial(cx: CGFloat, cy: CGFloat, r: CGFloat, fx: CGFloat?, fy: CGFloat?, transform: CGAffineTransform)

        func makeKind() -> SVGGradient.Kind {
            switch self {
            case .linear(let x1, let y1, let x2, let y2, let transform):
                let start = CGPoint(x: x1, y: y1).applying(transform)
                let end = CGPoint(x: x2, y: y2).applying(transform)
                return .linear(start: start, end: end)
            case .radial(let cx, let cy, let r, let fx, let fy, let transform):
                let startCenter = CGPoint(x: fx ?? cx, y: fy ?? cy).applying(transform)
                let endCenter = CGPoint(x: cx, y: cy).applying(transform)
                let radiusPoint = CGPoint(x: cx + r, y: cy).applying(transform)
                let endRadius = max(hypot(radiusPoint.x - endCenter.x, radiusPoint.y - endCenter.y), 0.001)
                return .radial(startCenter: startCenter, startRadius: 0, endCenter: endCenter, endRadius: endRadius)
            }
        }
    }
}

extension SVGParser: XMLParserDelegate {
    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        let attributes = SVGAttributeParser.normalizedAttributes(from: attributeDict)

        switch elementName {
        case "svg":
            canvasWidth = parseSize(attributes["width"])
            canvasHeight = parseSize(attributes["height"])
            viewBox = parseViewBox(attributes["viewBox"])
        case "rect":
            let x = parseSize(attributes["x"]) ?? 0
            let y = parseSize(attributes["y"]) ?? 0
            let width = parseSize(attributes["width"]) ?? 0
            let height = parseSize(attributes["height"]) ?? 0
            guard width > 0, height > 0 else { return }
            let rx = parseSize(attributes["rx"]) ?? 0
            let ry = parseSize(attributes["ry"]) ?? rx
            let rect = CGRect(x: x, y: y, width: width, height: height)
            let path: CGPath
            if rx > 0 || ry > 0 {
                let cornerSize = CGSize(width: min(rx, width / 2), height: min(ry, height / 2))
                path = CGPath(
                    roundedRect: rect,
                    cornerWidth: cornerSize.width,
                    cornerHeight: cornerSize.height,
                    transform: nil
                )
            } else {
                path = CGPath(rect: rect, transform: nil)
            }
            if currentClipPathDefinitionID != nil {
                storeClipPathIfNeeded(path, attributes: attributes)
            } else if isInsideDefinitions == false {
                appendNode(path: path, attributes: attributes)
            }
        case "circle":
            let cx = parseSize(attributes["cx"]) ?? 0
            let cy = parseSize(attributes["cy"]) ?? 0
            let r = parseSize(attributes["r"]) ?? 0
            guard r > 0 else { return }
            let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
            let path = CGPath(ellipseIn: rect, transform: nil)
            if currentClipPathDefinitionID != nil {
                storeClipPathIfNeeded(path, attributes: attributes)
            } else if isInsideDefinitions == false {
                appendNode(path: path, attributes: attributes)
            }
        case "ellipse":
            let cx = parseSize(attributes["cx"]) ?? 0
            let cy = parseSize(attributes["cy"]) ?? 0
            let rx = parseSize(attributes["rx"]) ?? 0
            let ry = parseSize(attributes["ry"]) ?? 0
            guard rx > 0, ry > 0 else { return }
            let rect = CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2)
            let path = CGPath(ellipseIn: rect, transform: nil)
            if currentClipPathDefinitionID != nil {
                storeClipPathIfNeeded(path, attributes: attributes)
            } else if isInsideDefinitions == false {
                appendNode(path: path, attributes: attributes)
            }
        case "line":
            let x1 = parseSize(attributes["x1"]) ?? 0
            let y1 = parseSize(attributes["y1"]) ?? 0
            let x2 = parseSize(attributes["x2"]) ?? 0
            let y2 = parseSize(attributes["y2"]) ?? 0
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x1, y: y1))
            path.addLine(to: CGPoint(x: x2, y: y2))
            if currentClipPathDefinitionID != nil {
                storeClipPathIfNeeded(path, attributes: attributes)
            } else if isInsideDefinitions == false {
                appendNode(path: path, attributes: attributes)
            }
        case "polyline", "polygon":
            let points = (attributes["points"] ?? "")
                .split(whereSeparator: { $0 == " " || $0 == "," || $0 == "\n" || $0 == "\t" })
                .compactMap { Double($0) }
            guard points.count >= 4 else { return }
            let path = CGMutablePath()
            path.move(to: CGPoint(x: points[0], y: points[1]))
            var index = 2
            while index + 1 < points.count {
                path.addLine(to: CGPoint(x: points[index], y: points[index + 1]))
                index += 2
            }
            if elementName == "polygon" {
                path.closeSubpath()
            }
            if currentClipPathDefinitionID != nil {
                storeClipPathIfNeeded(path, attributes: attributes)
            } else if isInsideDefinitions == false {
                appendNode(path: path, attributes: attributes)
            }
        case "path":
            guard let pathData = attributes["d"], !pathData.isEmpty else { return }
            do {
                let path = try SVGPathParser.parse(pathData)
                if currentClipPathDefinitionID != nil {
                    storeClipPathIfNeeded(path, attributes: attributes)
                } else if isInsideDefinitions == false {
                    appendNode(path: path, attributes: attributes)
                }
            } catch VectorImageError.unsupportedPathCommand(let command) {
                diagnostics.append("Unsupported path command: \(command)")
            } catch {
                diagnostics.append("Invalid path data ignored.")
            }
        case "g":
            groupClipPathReferenceStack.append(resolvedClipPathReference(from: attributes))
            let parentTransform = groupTransformStack.last ?? .identity
            let localTransform = SVGTransformParser.parse(attributes["transform"]) ?? .identity
            groupTransformStack.append(parentTransform.concatenating(localTransform))
            inheritedStyleAttributesStack.append(inheritableStyleAttributes(from: attributes))
        case "defs":
            isInsideDefinitions = true
        case "clipPath":
            currentClipPathDefinitionID = attributes["id"]
        case "linearGradient":
            currentGradientDefinitionID = attributes["id"]
            currentGradientDefinitionKind = .linear(
                x1: parseSize(attributes["x1"]) ?? 0,
                y1: parseSize(attributes["y1"]) ?? 0,
                x2: parseSize(attributes["x2"]) ?? 1,
                y2: parseSize(attributes["y2"]) ?? 0,
                transform: SVGTransformParser.parse(attributes["gradientTransform"]) ?? .identity
            )
            currentGradientStops = []
        case "radialGradient":
            currentGradientDefinitionID = attributes["id"]
            currentGradientDefinitionKind = .radial(
                cx: parseSize(attributes["cx"]) ?? 0,
                cy: parseSize(attributes["cy"]) ?? 0,
                r: parseSize(attributes["r"]) ?? 1,
                fx: parseSize(attributes["fx"]),
                fy: parseSize(attributes["fy"]),
                transform: SVGTransformParser.parse(attributes["gradientTransform"]) ?? .identity
            )
            currentGradientStops = []
        case "stop":
            guard currentGradientDefinitionID != nil else { return }
            let offset = parseGradientOffset(attributes["offset"])
            let colorValue = attributes["stop-color"] ?? attributes["color"]
            let opacity = attributes["stop-opacity"] ?? attributes["opacity"]
            if let color = SVGColorParser.color(from: colorValue, opacity: opacity, defaultColor: nil) {
                currentGradientStops.append(GradientStop(offset: offset, color: color))
            }
        case "mask", "filter", "use", "text":
            diagnostics.append("Unsupported SVG element ignored: \(elementName)")
        default:
            break
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        switch elementName {
        case "g":
            if groupClipPathReferenceStack.count > 1 {
                groupClipPathReferenceStack.removeLast()
            }
            if groupTransformStack.count > 1 {
                groupTransformStack.removeLast()
            }
            if inheritedStyleAttributesStack.count > 1 {
                inheritedStyleAttributesStack.removeLast()
            }
        case "clipPath":
            currentClipPathDefinitionID = nil
        case "linearGradient", "radialGradient":
            storeGradientIfNeeded()
            currentGradientDefinitionKind = nil
            currentGradientDefinitionID = nil
            currentGradientStops = []
        case "defs":
            isInsideDefinitions = false
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: any Error) {
        parsingError = parseError
    }

    private func parseGradientOffset(_ value: String?) -> CGFloat {
        guard let value else { return 0 }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasSuffix("%") {
            let raw = String(trimmed.dropLast())
            return CGFloat((Double(raw) ?? 0) / 100)
        }
        return CGFloat(Double(trimmed) ?? 0)
    }
}
