//
//  SVGColorParser.swift
//  VectorImageCore
//
//  Parses a focused subset of SVG color string formats.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import CoreGraphics
import Foundation

enum SVGColorParser {
    static func color(
        from value: String?,
        opacity: String?,
        defaultColor: CGColor? = nil,
        currentColor: CGColor? = nil
    ) -> CGColor? {
        guard var value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return defaultColor
        }

        if value == "none" {
            return nil
        }

        value = value.lowercased()
        let alpha = parsedAlpha(opacity)

        if value == "currentcolor" {
            return color(currentColor ?? defaultColor ?? defaultBlack(), applyingAlpha: alpha)
        }

        if let hexColor = hexColor(value, alpha: alpha) {
            return hexColor
        }

        if let rgbColor = rgbColor(value, alpha: alpha) {
            return rgbColor
        }

        if let namedColor = namedColor(value, alpha: alpha) {
            return namedColor
        }

        return defaultColor ?? cgColor(red: 0, green: 0, blue: 0, alpha: alpha)
    }

    static func defaultBlack(alpha: CGFloat = 1) -> CGColor {
        cgColor(red: 0, green: 0, blue: 0, alpha: alpha)
    }

    private static func parsedAlpha(_ opacity: String?) -> CGFloat {
        guard let opacity, let value = Double(opacity) else { return 1 }
        return max(0, min(1, CGFloat(value)))
    }

    private static func hexColor(_ value: String, alpha: CGFloat) -> CGColor? {
        guard value.hasPrefix("#") else { return nil }
        let hex = String(value.dropFirst())

        let resolved: String
        switch hex.count {
        case 3:
            resolved = hex.map { "\($0)\($0)" }.joined()
        case 6:
            resolved = hex
        default:
            return nil
        }

        guard let raw = UInt64(resolved, radix: 16) else { return nil }
        let red = CGFloat((raw & 0xFF0000) >> 16) / 255
        let green = CGFloat((raw & 0x00FF00) >> 8) / 255
        let blue = CGFloat(raw & 0x0000FF) / 255
        return cgColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    private static func rgbColor(_ value: String, alpha: CGFloat) -> CGColor? {
        guard value.hasPrefix("rgb("), value.hasSuffix(")") else { return nil }
        let body = value.dropFirst(4).dropLast()
        let parts = body.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard parts.count == 3 else { return nil }

        let channels = parts.compactMap { Double($0) }
        guard channels.count == 3 else { return nil }

        return cgColor(
            red: CGFloat(channels[0]) / 255,
            green: CGFloat(channels[1]) / 255,
            blue: CGFloat(channels[2]) / 255,
            alpha: alpha
        )
    }

    private static func namedColor(_ value: String, alpha: CGFloat) -> CGColor? {
        let components: (CGFloat, CGFloat, CGFloat, CGFloat)?
        switch value {
        case "black": components = (0, 0, 0, alpha)
        case "white": components = (1, 1, 1, alpha)
        case "red": components = (1, 0, 0, alpha)
        case "green": components = (0, 1, 0, alpha)
        case "blue": components = (0, 0, 1, alpha)
        case "yellow": components = (1, 1, 0, alpha)
        case "gray", "grey": components = (0.5, 0.5, 0.5, alpha)
        case "clear", "transparent": components = (0, 0, 0, 0)
        default: components = nil
        }

        guard let components else { return nil }
        return cgColor(red: components.0, green: components.1, blue: components.2, alpha: components.3)
    }

    private static func cgColor(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> CGColor {
        CGColor(
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
            components: [red, green, blue, alpha]
        )!
    }

    private static func color(_ color: CGColor, applyingAlpha alpha: CGFloat) -> CGColor {
        let components = color.converted(
            to: CGColorSpace(name: CGColorSpace.sRGB)!,
            intent: .defaultIntent,
            options: nil
        )?.components ?? color.components ?? [0, 0, 0, 1]

        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat

        if components.count >= 3 {
            red = components[0]
            green = components[1]
            blue = components[2]
        } else {
            red = components[0]
            green = components[0]
            blue = components[0]
        }

        return cgColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
