//
//  VectorImageRasterizationOptions.swift
//  VectorImageCore
//
//  Defines target size and scaling rules for rasterizing SVG content.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import CoreGraphics

/// Options that control SVG rasterization into a bitmap image.
public struct VectorImageRasterizationOptions: Sendable, Hashable {
    public enum ContentMode: Sendable, Hashable {
        case fit
        case fill
        case stretch
    }

    public let size: CGSize?
    public let scale: CGFloat
    public let contentMode: ContentMode
    public let opaque: Bool
    public let backgroundColor: VectorImageColor?

    public init(
        size: CGSize? = nil,
        scale: CGFloat = 0,
        contentMode: ContentMode = .fit,
        opaque: Bool = false,
        backgroundColor: VectorImageColor? = nil
    ) {
        self.size = size
        self.scale = scale
        self.contentMode = contentMode
        self.opaque = opaque
        self.backgroundColor = backgroundColor
    }
}

public struct VectorImageColor: Sendable, Hashable {
    public let red: CGFloat
    public let green: CGFloat
    public let blue: CGFloat
    public let alpha: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    var cgColor: CGColor {
        CGColor(
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
            components: [red, green, blue, alpha]
        )!
    }
}
