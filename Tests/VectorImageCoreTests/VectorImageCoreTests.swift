import CoreGraphics
import Foundation
import Testing
@testable import VectorImageCore

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@Test("Detects SVG data")
func detectsSVGData() {
    let data = Data(#"<svg viewBox="0 0 10 10"></svg>"#.utf8)
    #expect(VectorImageDetector.isSVG(data: data))
}

@Test("Rejects non-SVG data")
func rejectsNonSVGData() {
    let data = Data("not an image".utf8)
    #expect(VectorImageDetector.isSVG(data: data) == false)
}

@Test("Renders a simple rectangle fixture")
func rendersRectangleFixture() throws {
    let fixtureURL = try #require(Bundle.module.url(forResource: "simple-rect", withExtension: "svg"))
    let data = try Data(contentsOf: fixtureURL)

    let result = try VectorImageRenderer.render(
        svgData: data,
        options: .init(size: CGSize(width: 120, height: 80))
    )

    #expect(logicalSize(of: result.image).width == 120)
    #expect(logicalSize(of: result.image).height == 80)
    #expect(result.diagnostics.warnings.isEmpty)
}

@Test("Renders inline style attributes on shapes")
func rendersInlineStyleAttributes() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="80" height="80" viewBox="0 0 80 80" fill="none">
          <rect style="fill:#33588B;fill-opacity:1;stroke-linejoin:bevel" width="80" height="80" x="0" y="0"></rect>
        </svg>
        """.utf8
    )

    let result = try VectorImageRenderer.render(svgData: data)

    #expect(logicalSize(of: result.image).width == 80)
    #expect(logicalSize(of: result.image).height == 80)
    #expect(result.diagnostics.warnings.isEmpty)
}

@Test("Missing stroke does not default to black")
func missingStrokeDefaultsToNone() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">
          <path d="M1 1 L19 1 L19 19 L1 19 Z" fill="#F68712" />
        </svg>
        """.utf8
    )

    let parser = SVGParser(data: data)
    let document = try parser.parse()
    let style = try #require(document.nodes.first?.style)

    #expect(style.strokeColor == nil)
    #expect(style.fillColor != nil)
}

@Test("Parses even-odd fill rules")
func parsesEvenOddFillRules() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M0 0 L20 0 L20 20 L0 20 Z M5 5 L15 5 L15 15 L5 15 Z" fill="#FFFFFF" />
        </svg>
        """.utf8
    )

    let parser = SVGParser(data: data)
    let document = try parser.parse()
    let style = try #require(document.nodes.first?.style)

    #expect(style.fillRule == .evenOdd)
}

@Test("Inherits group fill styles")
func inheritsGroupFillStyles() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">
          <g fill="#E10A0A">
            <path d="M0 0 L20 0 L20 20 L0 20 Z" />
          </g>
        </svg>
        """.utf8
    )

    let parser = SVGParser(data: data)
    let document = try parser.parse()
    let style = try #require(document.nodes.first?.style)

    #expect(style.fillColor != nil)
    #expect(style.strokeColor == nil)
}

@Test("Paths without explicit fill still use the SVG default fill color")
func defaultsFillToBlackWhenFillAttributeIsMissing() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
          <path d="M2 2 L22 2 L22 22 L2 22 Z" />
        </svg>
        """.utf8
    )

    let parser = SVGParser(data: data)
    let document = try parser.parse()
    let style = try #require(document.nodes.first?.style)

    #expect(style.fillColor != nil)
    #expect(style.strokeColor == nil)
}

@Test("Applies group transforms to child paths")
func appliesGroupTransforms() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="30" height="20" viewBox="0 0 30 20">
          <g transform="translate(10 4)">
            <path d="M0 0 L10 0 L10 10 L0 10 Z" fill="#000000" />
          </g>
        </svg>
        """.utf8
    )

    let parser = SVGParser(data: data)
    let document = try parser.parse()
    let boundingBox = try #require(document.nodes.first?.path.boundingBoxOfPath)

    #expect(boundingBox.origin.x == 10)
    #expect(boundingBox.origin.y == 4)
    #expect(boundingBox.width == 10)
    #expect(boundingBox.height == 10)
}

@Test("Parses smooth cubic path commands")
func parsesSmoothCubicCommands() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="40" height="20" viewBox="0 0 40 20">
          <path d="M0 10 C5 0 10 0 15 10 S25 20 30 10" fill="none" stroke="#000000" />
        </svg>
        """.utf8
    )

    let result = try VectorImageRenderer.render(svgData: data)
    #expect(result.diagnostics.warnings.isEmpty)
}

@Test("Parses elliptical arc path commands used by Bootstrap icons")
func parsesEllipticalArcCommands() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
          <path d="M8.5 5.5a.5.5 0 0 0-1 0v3.362l-1.429 2.38a.5.5 0 1 0 .858.515l1.5-2.5A.5.5 0 0 0 8.5 9z"/>
          <path d="M6.5 0a.5.5 0 0 0 0 1H7v1.07a7.001 7.001 0 0 0-3.273 12.474l-.602.602a.5.5 0 0 0 .707.708l.746-.746A6.97 6.97 0 0 0 8 16a6.97 6.97 0 0 0 3.422-.892l.746.746a.5.5 0 0 0 .707-.708l-.601-.602A7.001 7.001 0 0 0 9 2.07V1h.5a.5.5 0 0 0 0-1zm1.038 3.018a6 6 0 0 1 .924 0 6 6 0 1 1-.924 0M0 3.5c0 .753.333 1.429.86 1.887A8.04 8.04 0 0 1 4.387 1.86 2.5 2.5 0 0 0 0 3.5M13.5 1c-.753 0-1.429.333-1.887.86a8.04 8.04 0 0 1 3.527 3.527A2.5 2.5 0 0 0 13.5 1"/>
        </svg>
        """.utf8
    )

    let result = try VectorImageRenderer.render(svgData: data)
    #expect(result.diagnostics.warnings.isEmpty)
}

@Test("Tokenizes compact decimal path values used by SVG icon sets")
func tokenizesCompactDecimalPathValues() throws {
    let path = try SVGPathParser.parse("M8.5 5.5a.5.5 0 0 0-1 0")
    let bounds = path.boundingBoxOfPath

    #expect(abs(bounds.minX - 7.5) < 0.01)
    #expect(abs(bounds.maxX - 8.5) < 0.01)
    #expect(abs(bounds.minY - 5.0) < 0.01)
    #expect(abs(bounds.maxY - 5.5) < 0.01)
}

@Test("Parses compact arc flags used by SVG icon sets")
func parsesCompactArcFlags() throws {
    let path = try SVGPathParser.parse("M23.225 6.252a.478.478 0 00-.923.171")
    let bounds = path.boundingBoxOfPath

    #expect(bounds.width > 0.8)
    #expect(bounds.height > 0.15)
}

@Test("Parses elliptical arc path commands used by Simple Icons Meta")
func parsesSimpleIconsMetaPath() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
          <path d="M6.915 4.03c-1.968 0-3.683 1.28-4.871 3.113C.704 9.208 0 11.883 0 14.449c0 .706.07 1.369.21 1.973a6.624 6.624 0 0 0 .265.86 5.297 5.297 0 0 0 .371.761c.696 1.159 1.818 1.927 3.593 1.927 1.497 0 2.633-.671 3.965-2.444.76-1.012 1.144-1.626 2.663-4.32l.756-1.339.186-.325c.061.1.121.196.183.3l2.152 3.595c.724 1.21 1.665 2.556 2.47 3.314 1.046.987 1.992 1.22 3.06 1.22 1.075 0 1.876-.355 2.455-.843a3.743 3.743 0 0 0 .81-.973c.542-.939.861-2.127.861-3.745 0-2.72-.681-5.357-2.084-7.45-1.282-1.912-2.957-2.93-4.716-2.93-1.047 0-2.088.467-3.053 1.308-.652.57-1.257 1.29-1.82 2.05-.69-.875-1.335-1.547-1.958-2.056-1.182-.966-2.315-1.303-3.454-1.303zm10.16 2.053c1.147 0 2.188.758 2.992 1.999 1.132 1.748 1.647 4.195 1.647 6.4 0 1.548-.368 2.9-1.839 2.9-.58 0-1.027-.23-1.664-1.004-.496-.601-1.343-1.878-2.832-4.358l-.617-1.028a44.908 44.908 0 0 0-1.255-1.98c.07-.109.141-.224.211-.327 1.12-1.667 2.118-2.602 3.358-2.602zm-10.201.553c1.265 0 2.058.791 2.675 1.446.307.327.737.871 1.234 1.579l-1.02 1.566c-.757 1.163-1.882 3.017-2.837 4.338-1.191 1.649-1.81 1.817-2.486 1.817-.524 0-1.038-.237-1.383-.794-.263-.426-.464-1.13-.464-2.046 0-2.221.63-4.535 1.66-6.088.454-.687.964-1.226 1.533-1.533a2.264 2.264 0 0 1 1.088-.285z"/>
        </svg>
        """.utf8
    )

    let result = try VectorImageRenderer.render(svgData: data)
    #expect(result.diagnostics.warnings.isEmpty)
}

@Test("Renders default-filled icon paths into visible pixels")
func rendersDefaultFilledIconPaths() throws {
    let data = Data(
        """
        <svg role="img" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"/>
        </svg>
        """.utf8
    )

    let result = try VectorImageRenderer.render(
        svgData: data,
        options: .init(
            size: CGSize(width: 96, height: 96),
            backgroundColor: VectorImageColor(red: 1, green: 1, blue: 1, alpha: 1)
        )
    )

    #expect(result.diagnostics.warnings.isEmpty)
    #expect(nonTransparentPixelCount(in: result.image) > 0)
}

@Test("Parses radial gradient fills used by supported assets")
func parsesRadialGradientFills() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="36" height="16" viewBox="0 0 36 16">
          <path d="M10.221 3.00043L6.19619 12.9996H8.52421L9.16931 11.2592H13.5165L14.1616 12.9996H16.5035L12.4648 3.00043H10.221Z" fill="url(#paint0)" />
          <defs>
            <radialGradient id="paint0" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(22.5114 81.5888) scale(97.8607 96.3834)">
              <stop offset="0.47" stop-color="#E8E8E8"/>
              <stop offset="0.61" stop-color="#B3B3B3"/>
              <stop offset="0.82" stop-color="white"/>
            </radialGradient>
          </defs>
        </svg>
        """.utf8
    )

    let result = try VectorImageRenderer.render(svgData: data)
    #expect(result.diagnostics.warnings.isEmpty)
}

@Test("Applies SVG transform lists in document order")
func appliesTransformListsInDocumentOrder() throws {
    let transform = try #require(
        SVGTransformParser.parse("translate(22.5114 81.5888) scale(97.8607 96.3834)")
    )

    let center = CGPoint(x: 0, y: 0).applying(transform)
    let radiusPoint = CGPoint(x: 1, y: 0).applying(transform)

    #expect(abs(center.x - 22.5114) < 0.0001)
    #expect(abs(center.y - 81.5888) < 0.0001)
    #expect(abs(radiusPoint.x - 120.3721) < 0.0001)
    #expect(abs(radiusPoint.y - 81.5888) < 0.0001)
}

@Test("Collects diagnostics for unsupported elements")
func reportsUnsupportedElements() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100">
          <mask id="m">
            <rect width="100" height="100" fill="white" />
          </mask>
          <rect width="100" height="100" fill="#2563EB" mask="url(#m)" />
        </svg>
        """.utf8
    )

    let result = try VectorImageRenderer.render(svgData: data)

    #expect(logicalSize(of: result.image).width == 100)
    #expect(logicalSize(of: result.image).height == 100)
    #expect(result.diagnostics.warnings.isEmpty == false)
}

@Test("Applies transforms on SVG shapes")
func appliesShapeTransforms() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">
          <rect width="10" height="10" transform="translate(5 4)" fill="#FF6600" />
        </svg>
        """.utf8
    )

    let parser = SVGParser(data: data)
    let document = try parser.parse()
    let boundingBox = try #require(document.nodes.first?.path.boundingBoxOfPath)

    #expect(boundingBox.origin.x == 5)
    #expect(boundingBox.origin.y == 4)
    #expect(boundingBox.width == 10)
    #expect(boundingBox.height == 10)
}

@Test("Supports translated clip paths used by remote logos")
func supportsTranslatedClipPaths() throws {
    let data = Data(
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="57" height="16" viewBox="0 0 57 16">
          <g clip-path="url(#clip0)">
            <rect width="56.84" height="16" fill="#141211" />
          </g>
          <defs>
            <clipPath id="clip0">
              <rect width="40.5485" height="8.65021" transform="translate(2.58716 3.68555)" />
            </clipPath>
          </defs>
        </svg>
        """.utf8
    )

    let parser = SVGParser(data: data)
    let document = try parser.parse()
    let clipPath = try #require(document.nodes.first?.clipPath)
    let boundingBox = clipPath.boundingBoxOfPath

    #expect(boundingBox.origin.x == 2.58716)
    #expect(boundingBox.origin.y == 3.68555)
    #expect(boundingBox.width == 40.5485)
    #expect(boundingBox.height == 8.65021)
}

@Test("Renders representative standalone SVG fixtures without crashing")
func rendersRepresentativeStandaloneFixtures() throws {
    let fixtures = [
        "simple-rect",
        "compound-mark",
        "rings-and-arcs",
        "unsupported-gradient"
    ]

    for fixture in fixtures {
        let fixtureURL = try #require(Bundle.module.url(forResource: fixture, withExtension: "svg"))
        let data = try Data(contentsOf: fixtureURL)

        #expect(VectorImageDetector.isSVG(data: data))

        let result = try VectorImageRenderer.render(svgData: data)
        let size = logicalSize(of: result.image)

        #expect(size.width > 0)
        #expect(size.height > 0)
    }
}

@available(iOS 15.0, macOS 12.0, *)
@Test("Caches repeated remote renders when cache is enabled")
func cachesRepeatedRemoteRenders() async throws {
    let url = URL(string: "https://example.com/test.svg")!
    URLProtocolStub.configure(
        url: url,
        payload: Data(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 40 40">
              <rect width="40" height="40" fill="#111111" />
            </svg>
            """.utf8
        )
    )

    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    let session = URLSession(configuration: configuration)
    let loader = VectorImageLoader(session: session)
    let cache = VectorImageCache(countLimit: 10)
    let source = VectorImageSource.remoteURL(url)
    let options = VectorImageRasterizationOptions(size: CGSize(width: 40, height: 40))

    let first = try await VectorImageRenderer.render(from: source, loader: loader, options: options, cache: cache)
    let second = try await VectorImageRenderer.render(from: source, loader: loader, options: options, cache: cache)
    let requestCount = URLProtocolStub.requestCount(for: url)

    #expect(logicalSize(of: first.image).width == 40)
    #expect(logicalSize(of: second.image).width == 40)
    #expect(requestCount == 1)
}

@available(iOS 15.0, macOS 12.0, *)
@Test("Coalesces concurrent identical remote renders without requiring cache")
func coalescesConcurrentRemoteRenders() async throws {
    let url = URL(string: "https://example.com/concurrent.svg")!
    URLProtocolStub.configure(
        url: url,
        payload: Data(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">
              <circle cx="24" cy="24" r="20" fill="#0055FF" />
            </svg>
            """.utf8
        ),
        delay: 0.05
    )

    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    let session = URLSession(configuration: configuration)
    let loader = VectorImageLoader(session: session)
    let source = VectorImageSource.remoteURL(url)
    let options = VectorImageRasterizationOptions(size: CGSize(width: 48, height: 48))

    async let first = VectorImageRenderer.render(from: source, loader: loader, options: options, cache: nil)
    async let second = VectorImageRenderer.render(from: source, loader: loader, options: options, cache: nil)

    let (firstResult, secondResult) = try await (first, second)
    let requestCount = URLProtocolStub.requestCount(for: url)

    #expect(logicalSize(of: firstResult.image).width == 48)
    #expect(logicalSize(of: secondResult.image).width == 48)
    #expect(requestCount == 1)
}

@available(iOS 15.0, macOS 12.0, *)
@Test("Configuration cache policy reuses completed remote renders")
func configurationCachePolicyReusesCompletedRemoteRenders() async throws {
    let url = URL(string: "https://example.com/configuration-cache.svg")!
    URLProtocolStub.configure(
        url: url,
        payload: Data(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 40 40">
              <rect width="40" height="40" fill="#118855" />
            </svg>
            """.utf8
        )
    )

    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    let session = URLSession(configuration: configuration)
    let vectorConfiguration = VectorImageConfiguration(
        loader: VectorImageLoader(session: session),
        cachePolicy: .enabled(countLimit: 10)
    )
    let source = VectorImageSource.remoteURL(url)
    let options = VectorImageRasterizationOptions(size: CGSize(width: 40, height: 40))

    _ = try await VectorImageRenderer.render(from: source, configuration: vectorConfiguration, options: options)
    _ = try await VectorImageRenderer.render(from: source, configuration: vectorConfiguration, options: options)

    let requestCount = URLProtocolStub.requestCount(for: url)
    #expect(requestCount == 1)
}

@available(iOS 15.0, macOS 12.0, *)
@Test("Configuration cache policy can disable completed-result caching")
func configurationCachePolicyCanDisableCompletedResultCaching() async throws {
    let url = URL(string: "https://example.com/configuration-cache-disabled.svg")!
    URLProtocolStub.configure(
        url: url,
        payload: Data(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 40 40">
              <rect width="40" height="40" fill="#AA3311" />
            </svg>
            """.utf8
        )
    )

    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    let session = URLSession(configuration: configuration)
    let vectorConfiguration = VectorImageConfiguration(
        loader: VectorImageLoader(session: session),
        cachePolicy: .disabled
    )
    let source = VectorImageSource.remoteURL(url)
    let options = VectorImageRasterizationOptions(size: CGSize(width: 40, height: 40))

    _ = try await VectorImageRenderer.render(from: source, configuration: vectorConfiguration, options: options)
    _ = try await VectorImageRenderer.render(from: source, configuration: vectorConfiguration, options: options)

    let requestCount = URLProtocolStub.requestCount(for: url)
    #expect(requestCount == 2)
}

@available(iOS 15.0, macOS 12.0, *)
@Test("Configuration in-flight policy can disable request coalescing")
func configurationInFlightPolicyCanDisableRequestCoalescing() async throws {
    let url = URL(string: "https://example.com/configuration-coalescing-disabled.svg")!
    URLProtocolStub.configure(
        url: url,
        payload: Data(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">
              <circle cx="24" cy="24" r="20" fill="#6633AA" />
            </svg>
            """.utf8
        ),
        delay: 0.05
    )

    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    let session = URLSession(configuration: configuration)
    let vectorConfiguration = VectorImageConfiguration(
        loader: VectorImageLoader(session: session),
        inFlightRequestPolicy: .disabled
    )
    let source = VectorImageSource.remoteURL(url)
    let options = VectorImageRasterizationOptions(size: CGSize(width: 48, height: 48))

    async let first = VectorImageRenderer.render(from: source, configuration: vectorConfiguration, options: options)
    async let second = VectorImageRenderer.render(from: source, configuration: vectorConfiguration, options: options)

    _ = try await (first, second)

    let requestCount = URLProtocolStub.requestCount(for: url)
    #expect(requestCount == 2)
}

private func logicalSize(of image: VectorImagePlatformImage) -> CGSize {
#if canImport(UIKit)
    image.size
#elseif canImport(AppKit)
    image.size
#endif
}

private func nonTransparentPixelCount(in image: VectorImagePlatformImage) -> Int {
    guard let cgImage = cgImage(from: image) else { return 0 }

    let width = cgImage.width
    let height = cgImage.height
    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

    guard let context = CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        return 0
    }

    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    var visiblePixels = 0
    for index in stride(from: 3, to: pixels.count, by: bytesPerPixel) {
        if pixels[index] > 0 {
            visiblePixels += 1
        }
    }

    return visiblePixels
}

private func cgImage(from image: VectorImagePlatformImage) -> CGImage? {
#if canImport(UIKit)
    image.cgImage
#elseif canImport(AppKit)
    var proposedRect = CGRect(origin: .zero, size: image.size)
    return image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil)
#endif
}

private final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) private static var requestCounts: [String: Int] = [:]
    nonisolated(unsafe) private static var responsePayloads: [String: Data] = [:]
    nonisolated(unsafe) private static var responseDelays: [String: TimeInterval] = [:]
    private static let lock = NSLock()

    static func configure(url: URL, payload: Data, delay: TimeInterval = 0) {
        let key = url.absoluteString
        lock.withLock {
            requestCounts[key] = 0
            responsePayloads[key] = payload
            responseDelays[key] = delay
        }
    }

    static func requestCount(for url: URL) -> Int {
        lock.withLock {
            requestCounts[url.absoluteString] ?? -1
        }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let key = request.url?.absoluteString ?? "https://example.com"
        let stubResponse = Self.lock.withLock {
            Self.requestCounts[key, default: 0] += 1
            return (
                payload: Self.responsePayloads[key] ?? Data(),
                delay: Self.responseDelays[key] ?? 0
            )
        }
        if stubResponse.delay > 0 {
            Thread.sleep(forTimeInterval: stubResponse.delay)
        }
        let response = HTTPURLResponse(
            url: request.url ?? URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "image/svg+xml"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stubResponse.payload)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
