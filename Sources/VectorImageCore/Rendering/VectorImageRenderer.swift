//
//  VectorImageRenderer.swift
//  VectorImageCore
//
//  Renders supported SVG documents into raster images.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import CoreGraphics
import Foundation

/// Rasterizes supported SVG content into a platform image type.
public enum VectorImageRenderer {
    /// Renders an SVG image from raw bytes and returns only the rasterized image.
    ///
    /// This is a convenience wrapper over ``render(svgData:options:)`` for callers that do not
    /// need diagnostics.
    ///
    /// - Parameters:
    ///   - svgData: The SVG payload to parse and render.
    ///   - options: Rasterization options such as target size and scaling mode.
    /// - Returns: A rendered bitmap image.
    /// - Throws: A `VectorImageError` if the data cannot be parsed or rendered.
    public static func renderImage(
        svgData: Data,
        options: VectorImageRasterizationOptions = .init()
    ) throws -> VectorImagePlatformImage {
        try render(svgData: svgData, options: options).image
    }

    /// Renders an SVG image from raw bytes and returns diagnostics collected along the way.
    ///
    /// - Parameters:
    ///   - svgData: The SVG payload to parse and render.
    ///   - options: Rasterization options such as target size and scaling mode.
    /// - Returns: The rendered image and any collected diagnostics.
    /// - Throws: A `VectorImageError` if the data cannot be parsed or rendered.
    public static func render(
        svgData: Data,
        options: VectorImageRasterizationOptions = .init()
    ) throws -> VectorImageRenderResult {
        let parser = SVGParser(data: svgData)
        let document = try parser.parse()

        let targetSize = resolvedTargetSize(for: document, options: options)
        guard targetSize.width > 0, targetSize.height > 0 else {
            throw VectorImageError.invalidDocumentSize
        }

        let scale = options.scale > 0 ? options.scale : 1
        let pixelWidth = max(Int((targetSize.width * scale).rounded(.up)), 1)
        let pixelHeight = max(Int((targetSize.height * scale).rounded(.up)), 1)

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: pixelWidth,
                height: pixelHeight,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: options.opaque
                    ? CGImageAlphaInfo.noneSkipLast.rawValue
                    : CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            throw VectorImageError.invalidDocumentSize
        }

        context.scaleBy(x: scale, y: scale)
        render(
            document: document,
            in: context,
            targetSize: targetSize,
            contentMode: options.contentMode,
            backgroundColor: options.backgroundColor
        )

        guard let cgImage = context.makeImage() else {
            throw VectorImageError.invalidDocumentSize
        }

        let image = VectorImagePlatformFactory.makeImage(cgImage: cgImage, logicalSize: targetSize, scale: scale)

        return VectorImageRenderResult(image: image, diagnostics: parser.diagnostics)
    }

    /// Loads and renders an SVG image from a source value and returns only the rasterized image.
    ///
    /// This is a convenience wrapper over ``render(from:loader:options:cache:)`` for callers that
    /// do not need diagnostics.
    ///
    /// - Parameters:
    ///   - source: The source to load bytes from.
    ///   - loader: The loader used to resolve the source into raw bytes.
    ///   - options: Rasterization options such as target size and scaling mode.
    ///   - cache: Optional cache for repeated source-based renders.
    /// - Returns: A rendered bitmap image.
    /// - Throws: A `VectorImageError` or loading error if the source cannot be resolved or rendered.
    @available(iOS 15.0, macOS 12.0, *)
    public static func renderImage(
        from source: VectorImageSource,
        loader: VectorImageLoader = .init(),
        options: VectorImageRasterizationOptions = .init(),
        cache: VectorImageCache? = nil
    ) async throws -> VectorImagePlatformImage {
        try await render(from: source, loader: loader, options: options, cache: cache).image
    }

    /// Loads and renders an SVG image from a source value.
    ///
    /// - Parameters:
    ///   - source: The source to load bytes from.
    ///   - loader: The loader used to resolve the source into raw bytes. This is primarily useful
    ///     for dependency injection, custom URLSession configuration, or tests.
    ///   - options: Rasterization options such as target size and scaling mode.
    /// - Returns: The rendered image and any collected diagnostics.
    /// - Throws: A `VectorImageError` or loading error if the source cannot be resolved or rendered.
    @available(iOS 15.0, macOS 12.0, *)
    public static func render(
        from source: VectorImageSource,
        loader: VectorImageLoader = .init(),
        options: VectorImageRasterizationOptions = .init(),
        cache: VectorImageCache? = nil
    ) async throws -> VectorImageRenderResult {
        if let cacheKey = cacheKey(for: source, options: options),
           let cachedResult = cache?.renderResult(forKey: cacheKey) {
            return cachedResult
        }

        let data = try await loader.loadData(from: source)
        let result = try render(svgData: data, options: options)

        if let cacheKey = cacheKey(for: source, options: options) {
            cache?.insert(result, forKey: cacheKey)
        }

        return result
    }

    private static func cacheKey(
        for source: VectorImageSource,
        options: VectorImageRasterizationOptions
    ) -> String? {
        let sourceKey: String
        switch source {
        case .data:
            return nil
        case .fileURL(let url):
            sourceKey = "file:\(url.absoluteString)"
        case .remoteURL(let url):
            sourceKey = "remote:\(url.absoluteString)"
        }

        return "\(sourceKey)|\(cacheOptionsKey(options))"
    }

    private static func cacheOptionsKey(_ options: VectorImageRasterizationOptions) -> String {
        let sizeKey = options.size.map { "\($0.width)x\($0.height)" } ?? "document"
        let backgroundKey = options.backgroundColor.map {
            "\($0.red),\($0.green),\($0.blue),\($0.alpha)"
        } ?? "none"
        let contentModeKey: String
        switch options.contentMode {
        case .fit:
            contentModeKey = "fit"
        case .fill:
            contentModeKey = "fill"
        case .stretch:
            contentModeKey = "stretch"
        }

        return [
            "size=\(sizeKey)",
            "scale=\(options.scale)",
            "mode=\(contentModeKey)",
            "opaque=\(options.opaque)",
            "background=\(backgroundKey)"
        ].joined(separator: "|")
    }

    private static func resolvedTargetSize(
        for document: SVGDocument,
        options: VectorImageRasterizationOptions
    ) -> CGSize {
        let documentSize = document.canvasSize
        guard let requestedSize = options.size else {
            return documentSize
        }

        switch (requestedSize.width > 0, requestedSize.height > 0) {
        case (true, true):
            return requestedSize
        case (true, false) where documentSize.width > 0:
            let ratio = requestedSize.width / documentSize.width
            return CGSize(width: requestedSize.width, height: documentSize.height * ratio)
        case (false, true) where documentSize.height > 0:
            let ratio = requestedSize.height / documentSize.height
            return CGSize(width: documentSize.width * ratio, height: requestedSize.height)
        default:
            return documentSize
        }
    }

    private static func render(
        document: SVGDocument,
        in context: CGContext,
        targetSize: CGSize,
        contentMode: VectorImageRasterizationOptions.ContentMode,
        backgroundColor: VectorImageColor?
    ) {
        context.saveGState()
        let targetRect = CGRect(origin: .zero, size: targetSize)
        context.clear(targetRect)
        if let backgroundColor {
            context.setFillColor(backgroundColor.cgColor)
            context.fill(targetRect)
        }

        let viewport = CGRect(origin: .zero, size: document.canvasSize)
        let destination = fittedRect(
            sourceSize: viewport.size,
            targetSize: targetSize,
            contentMode: contentMode
        )

        context.translateBy(x: destination.minX, y: destination.maxY)
        context.scaleBy(x: destination.width / viewport.width, y: -(destination.height / viewport.height))
        context.translateBy(x: -viewport.minX, y: -viewport.minY)

        for node in document.nodes {
            draw(node: node, in: context)
        }

        context.restoreGState()
    }

    private static func fittedRect(
        sourceSize: CGSize,
        targetSize: CGSize,
        contentMode: VectorImageRasterizationOptions.ContentMode
    ) -> CGRect {
        guard sourceSize.width > 0, sourceSize.height > 0 else {
            return CGRect(origin: .zero, size: targetSize)
        }

        switch contentMode {
        case .stretch:
            return CGRect(origin: .zero, size: targetSize)
        case .fit, .fill:
            let widthRatio = targetSize.width / sourceSize.width
            let heightRatio = targetSize.height / sourceSize.height
            let scale = contentMode == .fit ? min(widthRatio, heightRatio) : max(widthRatio, heightRatio)
            let size = CGSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
            let origin = CGPoint(
                x: (targetSize.width - size.width) / 2,
                y: (targetSize.height - size.height) / 2
            )
            return CGRect(origin: origin, size: size)
        }
    }

    private static func draw(node: SVGNode, in context: CGContext) {
        context.saveGState()
        if let clipPath = node.clipPath {
            context.addPath(clipPath)
            context.clip()
        }

        let path = node.path
        if let fillGradient = node.style.fillGradient {
            fill(path: path, with: fillGradient, rule: node.style.fillRule, in: context)
        } else if let fillColor = node.style.fillColor {
            fill(path: path, with: fillColor, rule: node.style.fillRule, in: context)
        }

        if let strokeColor = node.style.strokeColor {
            context.setStrokeColor(strokeColor)
            context.setLineWidth(node.style.strokeWidth)
            context.setLineJoin(.miter)
            context.setLineCap(.butt)
            context.addPath(path)
            context.drawPath(using: .stroke)
        }

        context.restoreGState()
    }

    private static func fill(path: CGPath, with color: CGColor, rule: SVGFillRule, in context: CGContext) {
        context.addPath(path)
        context.setFillColor(color)
        if rule == .evenOdd {
            context.fillPath(using: .evenOdd)
        } else {
            context.fillPath()
        }
    }

    private static func fill(path: CGPath, with gradient: SVGGradient, rule: SVGFillRule, in context: CGContext) {
        guard let cgGradient = CGGradient(
            colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
            colors: gradient.colors as CFArray,
            locations: gradient.locations
        ) else {
            return
        }

        context.saveGState()
        context.addPath(path)
        if rule == .evenOdd {
            context.clip(using: .evenOdd)
        } else {
            context.clip()
        }

        switch gradient.kind {
        case .linear(let start, let end):
            context.drawLinearGradient(
                cgGradient,
                start: start,
                end: end,
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )
        case .radial(let startCenter, let startRadius, let endCenter, let endRadius):
            context.drawRadialGradient(
                cgGradient,
                startCenter: startCenter,
                startRadius: startRadius,
                endCenter: endCenter,
                endRadius: endRadius,
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )
        }

        context.restoreGState()
    }
}

/// The result of rendering SVG data.
public struct VectorImageRenderResult {
    public let image: VectorImagePlatformImage
    public let diagnostics: VectorImageDiagnostics

    public init(image: VectorImagePlatformImage, diagnostics: VectorImageDiagnostics) {
        self.image = image
        self.diagnostics = diagnostics
    }
}
