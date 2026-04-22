//
//  SVGPathParser.swift
//  VectorImageCore
//
//  Parses a pragmatic subset of SVG path commands into Core Graphics paths.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import CoreGraphics
import Foundation

enum SVGPathParser {
    static func parse(_ input: String) throws -> CGPath {
        var tokens = tokenize(input)
        let path = CGMutablePath()

        var index = 0
        var current = CGPoint.zero
        var subpathStart = CGPoint.zero
        var currentCommand: Character?
        var lastCubicControl: CGPoint?
        var lastQuadControl: CGPoint?

        func nextNumber() -> CGFloat? {
            guard index < tokens.count else { return nil }
            switch tokens[index] {
            case .number(let rawValue):
                guard let value = Double(rawValue) else {
                    index += 1
                    return nil
                }
                index += 1
                return CGFloat(value)
            case .command:
                return nil
            }
        }

        func nextArcFlag() -> Bool? {
            guard index < tokens.count else { return nil }

            switch tokens[index] {
            case .command:
                return nil
            case .number(let rawValue):
                guard rawValue.isEmpty == false else {
                    index += 1
                    return nil
                }

                if rawValue.first == "0" || rawValue.first == "1" {
                    let flagCharacter = rawValue.first!
                    let remainder = String(rawValue.dropFirst())
                    if remainder.isEmpty {
                        index += 1
                    } else {
                        tokens[index] = .number(remainder)
                    }
                    return flagCharacter == "1"
                }

                guard let value = Double(rawValue) else {
                    index += 1
                    return nil
                }
                index += 1
                return value != 0
            }
        }

        while index < tokens.count {
            switch tokens[index] {
            case .command(let command):
                currentCommand = command
                index += 1
            case .number:
                guard currentCommand != nil else {
                    throw VectorImageError.invalidXML
                }
            }

            guard let command = currentCommand else { break }

            switch command {
            case "M", "m":
                guard let x = nextNumber(), let y = nextNumber() else { break }
                let point = pointFor(command: command, x: x, y: y, current: current)
                path.move(to: point)
                current = point
                subpathStart = point
                currentCommand = command == "M" ? "L" : "l"
                lastCubicControl = nil
                lastQuadControl = nil
            case "L", "l":
                while let x = nextNumber(), let y = nextNumber() {
                    let point = pointFor(command: command, x: x, y: y, current: current)
                    path.addLine(to: point)
                    current = point
                }
                lastCubicControl = nil
                lastQuadControl = nil
            case "H", "h":
                while let x = nextNumber() {
                    let point = CGPoint(
                        x: command == "H" ? x : current.x + x,
                        y: current.y
                    )
                    path.addLine(to: point)
                    current = point
                }
                lastCubicControl = nil
                lastQuadControl = nil
            case "V", "v":
                while let y = nextNumber() {
                    let point = CGPoint(
                        x: current.x,
                        y: command == "V" ? y : current.y + y
                    )
                    path.addLine(to: point)
                    current = point
                }
                lastCubicControl = nil
                lastQuadControl = nil
            case "C", "c":
                while
                    let x1 = nextNumber(),
                    let y1 = nextNumber(),
                    let x2 = nextNumber(),
                    let y2 = nextNumber(),
                    let x = nextNumber(),
                    let y = nextNumber()
                {
                    let control1 = pointFor(command: command, x: x1, y: y1, current: current)
                    let control2 = pointFor(command: command, x: x2, y: y2, current: current)
                    let end = pointFor(command: command, x: x, y: y, current: current)
                    path.addCurve(to: end, control1: control1, control2: control2)
                    current = end
                    lastCubicControl = control2
                    lastQuadControl = nil
                }
            case "S", "s":
                while
                    let x2 = nextNumber(),
                    let y2 = nextNumber(),
                    let x = nextNumber(),
                    let y = nextNumber()
                {
                    let control1 = reflectedControlPoint(lastCubicControl, current: current)
                    let control2 = pointFor(command: command, x: x2, y: y2, current: current)
                    let end = pointFor(command: command, x: x, y: y, current: current)
                    path.addCurve(to: end, control1: control1, control2: control2)
                    current = end
                    lastCubicControl = control2
                    lastQuadControl = nil
                }
            case "Q", "q":
                while
                    let x1 = nextNumber(),
                    let y1 = nextNumber(),
                    let x = nextNumber(),
                    let y = nextNumber()
                {
                    let control = pointFor(command: command, x: x1, y: y1, current: current)
                    let end = pointFor(command: command, x: x, y: y, current: current)
                    path.addQuadCurve(to: end, control: control)
                    current = end
                    lastQuadControl = control
                    lastCubicControl = nil
                }
            case "T", "t":
                while
                    let x = nextNumber(),
                    let y = nextNumber()
                {
                    let control = reflectedControlPoint(lastQuadControl, current: current)
                    let end = pointFor(command: command, x: x, y: y, current: current)
                    path.addQuadCurve(to: end, control: control)
                    current = end
                    lastQuadControl = control
                    lastCubicControl = nil
                }
            case "A", "a":
                while
                    let rx = nextNumber(),
                    let ry = nextNumber(),
                    let xAxisRotation = nextNumber(),
                    let largeArcFlag = nextArcFlag(),
                    let sweepFlag = nextArcFlag(),
                    let x = nextNumber(),
                    let y = nextNumber()
                {
                    let end = pointFor(command: command, x: x, y: y, current: current)
                    appendArc(
                        to: path,
                        from: current,
                        to: end,
                        rx: rx,
                        ry: ry,
                        xAxisRotation: xAxisRotation,
                        largeArc: largeArcFlag,
                        sweep: sweepFlag
                    )
                    current = end
                    lastCubicControl = nil
                    lastQuadControl = nil
                }
            case "Z", "z":
                path.closeSubpath()
                current = subpathStart
                lastCubicControl = nil
                lastQuadControl = nil
            default:
                throw VectorImageError.unsupportedPathCommand(command)
            }
        }

        return path
    }

    private static func pointFor(command: Character, x: CGFloat, y: CGFloat, current: CGPoint) -> CGPoint {
        if command.isUppercase {
            return CGPoint(x: x, y: y)
        }

        return CGPoint(x: current.x + x, y: current.y + y)
    }

    private static func tokenize(_ input: String) -> [Token] {
        var tokens: [Token] = []
        var buffer = ""
        let commandCharacters = Set("MmLlHhVvCcSsQqTtAaZz")

        func flushNumber() {
            guard !buffer.isEmpty else {
                buffer = ""
                return
            }
            tokens.append(.number(buffer))
            buffer = ""
        }

        for scalar in input.unicodeScalars {
            let char = Character(scalar)

            if commandCharacters.contains(char) {
                flushNumber()
                tokens.append(.command(char))
                continue
            }

            if char == "-" || char == "+" {
                let previous = buffer.last
                if previous != nil, previous != "e", previous != "E" {
                    flushNumber()
                }
                buffer.append(char)
                continue
            }

            if char == "." {
                if buffer.contains("."), buffer.last != "e", buffer.last != "E" {
                    flushNumber()
                }
                buffer.append(char)
                continue
            }

            if char.isNumber || char == "e" || char == "E" {
                buffer.append(char)
                continue
            }

            if char == "," || char.isWhitespace {
                flushNumber()
            }
        }

        flushNumber()
        return tokens
    }

    private enum Token {
        case command(Character)
        case number(String)
    }

    private static func reflectedControlPoint(_ control: CGPoint?, current: CGPoint) -> CGPoint {
        guard let control else { return current }
        return CGPoint(x: current.x * 2 - control.x, y: current.y * 2 - control.y)
    }

    private static func appendArc(
        to path: CGMutablePath,
        from start: CGPoint,
        to end: CGPoint,
        rx: CGFloat,
        ry: CGFloat,
        xAxisRotation: CGFloat,
        largeArc: Bool,
        sweep: Bool
    ) {
        guard start != end else { return }

        var rx = abs(rx)
        var ry = abs(ry)
        guard rx > 0, ry > 0 else {
            path.addLine(to: end)
            return
        }

        let phi = xAxisRotation * .pi / 180
        let cosPhi = cos(phi)
        let sinPhi = sin(phi)

        let dx2 = (start.x - end.x) / 2
        let dy2 = (start.y - end.y) / 2
        let x1Prime = cosPhi * dx2 + sinPhi * dy2
        let y1Prime = -sinPhi * dx2 + cosPhi * dy2

        let rx2 = rx * rx
        let ry2 = ry * ry
        let x1Prime2 = x1Prime * x1Prime
        let y1Prime2 = y1Prime * y1Prime

        let radiiScale = x1Prime2 / rx2 + y1Prime2 / ry2
        if radiiScale > 1 {
            let scale = sqrt(radiiScale)
            rx *= scale
            ry *= scale
        }

        let adjustedRX2 = rx * rx
        let adjustedRY2 = ry * ry
        let numerator = adjustedRX2 * adjustedRY2
            - adjustedRX2 * y1Prime2
            - adjustedRY2 * x1Prime2
        let denominator = adjustedRX2 * y1Prime2 + adjustedRY2 * x1Prime2
        let factor = denominator == 0 ? 0 : sqrt(max(0, numerator / denominator))
        let signedFactor = (largeArc == sweep ? -1 : 1) * factor

        let centerPrime = CGPoint(
            x: signedFactor * ((rx * y1Prime) / ry),
            y: signedFactor * (-(ry * x1Prime) / rx)
        )
        let center = CGPoint(
            x: cosPhi * centerPrime.x - sinPhi * centerPrime.y + (start.x + end.x) / 2,
            y: sinPhi * centerPrime.x + cosPhi * centerPrime.y + (start.y + end.y) / 2
        )

        let startVector = CGPoint(
            x: (x1Prime - centerPrime.x) / rx,
            y: (y1Prime - centerPrime.y) / ry
        )
        let endVector = CGPoint(
            x: (-x1Prime - centerPrime.x) / rx,
            y: (-y1Prime - centerPrime.y) / ry
        )

        let startAngle = vectorAngle(from: CGPoint(x: 1, y: 0), to: startVector)
        var deltaAngle = vectorAngle(from: startVector, to: endVector)
        if sweep == false, deltaAngle > 0 {
            deltaAngle -= 2 * .pi
        } else if sweep, deltaAngle < 0 {
            deltaAngle += 2 * .pi
        }

        let segmentCount = max(Int(ceil(abs(deltaAngle) / (.pi / 2))), 1)
        let angleStep = deltaAngle / CGFloat(segmentCount)

        for index in 0..<segmentCount {
            let theta1 = startAngle + CGFloat(index) * angleStep
            let theta2 = theta1 + angleStep
            appendArcSegment(
                to: path,
                center: center,
                rx: rx,
                ry: ry,
                cosPhi: cosPhi,
                sinPhi: sinPhi,
                theta1: theta1,
                theta2: theta2
            )
        }
    }

    private static func appendArcSegment(
        to path: CGMutablePath,
        center: CGPoint,
        rx: CGFloat,
        ry: CGFloat,
        cosPhi: CGFloat,
        sinPhi: CGFloat,
        theta1: CGFloat,
        theta2: CGFloat
    ) {
        let delta = theta2 - theta1
        let alpha = (4 / 3) * tan(delta / 4)

        let start = pointOnEllipse(
            center: center,
            rx: rx,
            ry: ry,
            cosPhi: cosPhi,
            sinPhi: sinPhi,
            angle: theta1
        )
        let end = pointOnEllipse(
            center: center,
            rx: rx,
            ry: ry,
            cosPhi: cosPhi,
            sinPhi: sinPhi,
            angle: theta2
        )
        let startDerivative = ellipseDerivative(
            rx: rx,
            ry: ry,
            cosPhi: cosPhi,
            sinPhi: sinPhi,
            angle: theta1
        )
        let endDerivative = ellipseDerivative(
            rx: rx,
            ry: ry,
            cosPhi: cosPhi,
            sinPhi: sinPhi,
            angle: theta2
        )

        let control1 = CGPoint(
            x: start.x + alpha * startDerivative.x,
            y: start.y + alpha * startDerivative.y
        )
        let control2 = CGPoint(
            x: end.x - alpha * endDerivative.x,
            y: end.y - alpha * endDerivative.y
        )

        path.addCurve(to: end, control1: control1, control2: control2)
    }

    private static func pointOnEllipse(
        center: CGPoint,
        rx: CGFloat,
        ry: CGFloat,
        cosPhi: CGFloat,
        sinPhi: CGFloat,
        angle: CGFloat
    ) -> CGPoint {
        let cosAngle = cos(angle)
        let sinAngle = sin(angle)
        return CGPoint(
            x: center.x + cosPhi * rx * cosAngle - sinPhi * ry * sinAngle,
            y: center.y + sinPhi * rx * cosAngle + cosPhi * ry * sinAngle
        )
    }

    private static func ellipseDerivative(
        rx: CGFloat,
        ry: CGFloat,
        cosPhi: CGFloat,
        sinPhi: CGFloat,
        angle: CGFloat
    ) -> CGPoint {
        let cosAngle = cos(angle)
        let sinAngle = sin(angle)
        return CGPoint(
            x: -cosPhi * rx * sinAngle - sinPhi * ry * cosAngle,
            y: -sinPhi * rx * sinAngle + cosPhi * ry * cosAngle
        )
    }

    private static func vectorAngle(from start: CGPoint, to end: CGPoint) -> CGFloat {
        let cross = start.x * end.y - start.y * end.x
        let dot = start.x * end.x + start.y * end.y
        return atan2(cross, dot)
    }
}
