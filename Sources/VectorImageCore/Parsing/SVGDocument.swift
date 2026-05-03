//
//  SVGDocument.swift
//  VectorImageCore
//
//  Defines the internal SVG document and shape model used by the renderer.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import CoreGraphics

struct SVGDocument {
    let canvasSize: CGSize
    let nodes: [SVGNode]
}

struct SVGNode {
    let path: CGPath
    let style: SVGStyle
    let clipPath: CGPath?
    let clipPathIdentifier: String?
}

struct SVGStyle {
    let fillColor: CGColor?
    let fillGradient: SVGGradient?
    let fillGradientIdentifier: String?
    let strokeColor: CGColor?
    let strokeWidth: CGFloat
    let strokeLineCap: CGLineCap
    let strokeLineJoin: CGLineJoin
    let strokeMiterLimit: CGFloat
    let strokeDashArray: [CGFloat]
    let strokeDashOffset: CGFloat
    let fillRule: SVGFillRule
}

enum SVGFillRule {
    case nonZero
    case evenOdd
}

struct SVGGradient {
    enum Kind {
        case linear(start: CGPoint, end: CGPoint)
        case radial(startCenter: CGPoint, startRadius: CGFloat, endCenter: CGPoint, endRadius: CGFloat)
    }

    let kind: Kind
    let colors: [CGColor]
    let locations: [CGFloat]
}
