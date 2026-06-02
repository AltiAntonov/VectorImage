<div align="center">
  <h1>VectorImage</h1>
  <p><strong>Dependency-free SVG parsing and rasterization for Apple platforms, with iOS and macOS example apps.</strong></p>
  <p>
    <img src="https://img.shields.io/badge/iOS-15%2B-34C759" alt="iOS 15+">
    <img src="https://img.shields.io/badge/macOS-12%2B-34C759" alt="macOS 12+">
    <img src="https://img.shields.io/badge/License-MIT-34C759" alt="MIT License">
  </p>
  <p>
    <a href="https://swiftpackageindex.com/AltiAntonov/VectorImage">
      <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAltiAntonov%2FVectorImage%2Fbadge%3Ftype%3Dswift-versions" alt="Swift version compatibility">
    </a>
    <a href="https://swiftpackageindex.com/AltiAntonov/VectorImage">
      <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAltiAntonov%2FVectorImage%2Fbadge%3Ftype%3Dplatforms" alt="Platform compatibility">
    </a>
  </p>
  <p>
    <a href="#features">Features</a> ·
    <a href="#installation">Installation</a> ·
    <a href="#quick-start">Quick Start</a> ·
    <a href="#api-surface">API Surface</a> ·
    <a href="#documentation">Documentation</a> ·
    <a href="#supported-svg-subset">Supported SVG Subset</a> ·
    <a href="#known-limitations">Known Limitations</a> ·
    <a href="#performance-guardrails">Performance Guardrails</a> ·
    <a href="#planned">Planned</a> ·
    <a href="#package-layout">Package Layout</a> ·
    <a href="#example-apps">Example Apps</a> ·
    <a href="#testing">Testing</a>
  </p>
</div>

## Features

- dependency-free SVG detection, parsing, and rasterization
- public-SDK-safe implementation with no Apple private framework usage
- focused `VectorImageCore` target for loading and rendering SVGs into `UIImage` or `NSImage`
- real `VectorImageUI` target with a SwiftUI async SVG image view backed by `VectorImageCore`
- documented supported SVG subset with diagnostics for unsupported features
- support for local, file-based, and remote SVG loading
- optional in-memory caching for repeated source-based renders
- in-flight coalescing for identical source-based render requests
- SwiftUI environment configuration for sharing source-rendering policy across async image views
- support for practical SVG fidelity features such as clip paths, group transforms, simple nested SVG containers, gradients, arc commands, focused stylesheet rules, visibility handling, and stroke presentation attributes
- optional `VectorImageAdvanced` preprocessing layer that validates and prepares SVG input for `VectorImageCore`
- fixture-based tests for the initial SVG subset
- included iOS and macOS example apps for manual validation

## Installation

Add `VectorImage` to your Swift Package Manager dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/AltiAntonov/VectorImage.git", from: "1.2.0")
]
```

Then add the core product to your target:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "VectorImageCore", package: "VectorImage")
    ]
)
```

For SwiftUI integration, add the UI product as well:

```swift
.target(
    name: "YourFeature",
    dependencies: [
        .product(name: "VectorImageCore", package: "VectorImage"),
        .product(name: "VectorImageUI", package: "VectorImage")
    ]
)
```

For the optional Advanced preprocessing layer, add `VectorImageAdvanced`:

```swift
.target(
    name: "YourAssetPipeline",
    dependencies: [
        .product(name: "VectorImageAdvanced", package: "VectorImage")
    ]
)
```

## Quick Start

```swift
import UIKit
import VectorImageCore

let data: Data = ...

let result = try VectorImageRenderer.render(
    svgData: data,
    options: .init(size: CGSize(width: 120, height: 120))
)

let image = result.image
```

If you want to preflight content before rendering:

```swift
let isSVG = VectorImageDetector.isSVG(data: data)
```

For SwiftUI integration, `VectorImageUI` now provides `VectorImageAsyncImage` on top of the same core renderer.

```swift
import SwiftUI
import VectorImageUI

struct LogoView: View {
    let url: URL

    var body: some View {
        VectorImageAsyncImage(
            url: url,
            options: .init(size: CGSize(width: 120, height: 120))
        ) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if let error = phase.error {
                Text(error.localizedDescription)
            } else {
                ProgressView()
            }
        }
    }
}
```

## API Surface

Current public entry points in `VectorImageCore`:

- `VectorImageDetector.isSVG(data:)`
  Quick preflight check for raw bytes.
- `VectorImageRenderer.renderImage(svgData:options:)`
  Convenience helper that returns only the rendered image for raw SVG data.
- `VectorImageRenderer.render(svgData:options:)`
  Render raw SVG `Data` into an image plus diagnostics.
- `VectorImageRenderer.renderImage(from:loader:options:cache:)`
  Convenience helper that returns only the rendered image for a `VectorImageSource`.
- `VectorImageRenderer.render(from:loader:options:cache:)`
  Async rendering from a `VectorImageSource` into an image plus diagnostics.
- `VectorImageRenderer.renderImage(from:configuration:options:)`
  Convenience helper that returns only the rendered image using source-rendering configuration.
- `VectorImageRenderer.render(from:configuration:options:)`
  Async rendering from a `VectorImageSource` using source-rendering configuration.
- `VectorImageCache`
  Optional in-memory cache for repeated source-based renders.
- `VectorImageConfiguration`
  Source-rendering configuration for loader, cache, and in-flight request policies.
- `VectorImageCachePolicy`
  Enables or disables completed-result caching for source-based renders.
- `VectorImageInFlightRequestPolicy`
  Enables or disables coalescing for identical in-flight source-based renders.

Current public entry points in `VectorImageUI`:

- `VectorImageAsyncImage`
  SwiftUI async SVG view backed by `VectorImageCore`. Default loader/cache initializers read `EnvironmentValues.vectorImageConfiguration`; explicit loader, cache, or configuration initializers keep using the values passed to that view.
- `VectorImageAsyncImagePhase`
  Phase enum for loading, success, and failure states.
- `VectorImageAsyncImageValue`
  Successful render payload with `Image`, platform image, and diagnostics.
- `EnvironmentValues.vectorImageConfiguration`
  Default `VectorImageConfiguration` used by descendant `VectorImageAsyncImage` views.
- `View.vectorImageConfiguration(_:)`
  SwiftUI modifier for setting shared source-rendering configuration.

Current public entry points in `VectorImageAdvanced`:

- `VectorImageAdvancedProcessor.process(svgData:)`
  Validates, conservatively cleans, and normalizes supported style declarations before rendering with `VectorImageCore`.
- `VectorImageAdvancedProcessor.render(svgData:options:)`
  Preprocesses SVG bytes, renders through `VectorImageCore`, and returns the rendered image plus combined diagnostics.
- `VectorImageAdvancedProcessor.renderImage(svgData:options:)`
  Convenience helper that preprocesses SVG bytes, renders through `VectorImageCore`, and returns only the image.
- `VectorImageAdvancedResult`
  Preprocessing result containing SVG bytes plus non-fatal diagnostics.
- `VectorImageAdvancedFeatureSet.summary`
  Short module-role summary for package/demo surfaces.

Use the API in two layers:

- `render(...)`
  The full-result API. Use this when you want diagnostics, warnings, or the clearest picture of what the renderer did.
- `renderImage(...)`
  The convenience API. Use this when you only need the rasterized image and do not care about diagnostics.

The methods are also paired across two input styles:

- `svgData`
  Use this when you already have the SVG payload in memory.
- `from source`
  Use this when you want the renderer to resolve `.data`, `.fileURL`, or `.remoteURL` for you.

### Prepare SVG data with `VectorImageAdvanced`

`VectorImageAdvanced` is optional. It validates SVG input and applies conservative deterministic preprocessing before rendering. `VectorImageCore` remains the renderer.

Advanced removes script elements, SVG event handler attributes, and external resource references from the input SVG. It also normalizes supported inline `style=""` declarations and simple stylesheet rules into presentation attributes. Cleanup and unsupported stylesheet selectors are reported as diagnostics.

```swift
import VectorImageAdvanced
import VectorImageCore

let processed = try VectorImageAdvancedProcessor.process(svgData: data)

let result = try VectorImageRenderer.render(
    svgData: processed.svgData,
    options: .init(size: CGSize(width: 120, height: 120))
)

let warnings = processed.diagnostics.warnings + result.diagnostics.warnings
```

If you want Advanced preprocessing and Core rendering in one call:

```swift
import VectorImageAdvanced

let result = try VectorImageAdvancedProcessor.render(
    svgData: data,
    options: .init(size: CGSize(width: 120, height: 120))
)

let image = result.image
let warnings = result.diagnostics.warnings
```

### Detect and render from raw `Data`

```swift
import UIKit
import VectorImageCore

let data: Data = ...
let isSVG = VectorImageDetector.isSVG(data: data)

guard isSVG else {
    throw VectorImageError.notSVG
}

let result = try VectorImageRenderer.render(
    svgData: data,
    options: .init(size: CGSize(width: 120, height: 120))
)

let image = result.image
let warnings = result.diagnostics.warnings
```

If you only want the image:

```swift
let image = try VectorImageRenderer.renderImage(
    svgData: data,
    options: .init(size: CGSize(width: 120, height: 120))
)
```

### Render from a `VectorImageSource`

```swift
import UIKit
import VectorImageCore

let source: VectorImageSource = .remoteURL(
    URL(string: "https://example.com/logo.svg")!
)

let cache = VectorImageCache(countLimit: 64)

let result = try await VectorImageRenderer.render(
    from: source,
    options: .init(size: CGSize(width: 120, height: 120)),
    cache: cache
)

let image = result.image
let warnings = result.diagnostics.warnings
```

The source-based API keeps `loader` public so clients can inject a custom `URLSession`, loader policy, or test double when needed. In the common case, the default loader is enough and you can omit it.

If you only want the image:

```swift
let image = try await VectorImageRenderer.renderImage(
    from: source,
    options: .init(size: CGSize(width: 120, height: 120)),
    cache: cache
)
```

### Configure source-based rendering

```swift
import Foundation
import VectorImageCore

let configuration = VectorImageConfiguration(
    loader: VectorImageLoader(session: .shared),
    cachePolicy: .enabled(countLimit: 64),
    inFlightRequestPolicy: .coalesceIdenticalRequests
)

let result = try await VectorImageRenderer.render(
    from: .remoteURL(URL(string: "https://example.com/logo.svg")!),
    configuration: configuration,
    options: .init(size: CGSize(width: 120, height: 120))
)
```

Use `.disabled` for `cachePolicy` when the same source may return changing SVG content and you always want a fresh completed render. Use `.disabled` for `inFlightRequestPolicy` when identical concurrent requests must not share the same in-flight load/render task.

Supported `VectorImageSource` cases:

- `.data(Data)`
- `.fileURL(URL)`
- `.remoteURL(URL)`

### `VectorImageSource.data`

```swift
import VectorImageCore

let data: Data = ...
let source: VectorImageSource = .data(data)
```

### `VectorImageSource.fileURL`

```swift
import Foundation
import VectorImageCore

let fileURL = Bundle.main.url(forResource: "logo", withExtension: "svg")!
let source: VectorImageSource = .fileURL(fileURL)
```

### `VectorImageSource.remoteURL`

```swift
import Foundation
import VectorImageCore

let url = URL(string: "https://example.com/logo.svg")!
let source: VectorImageSource = .remoteURL(url)
```

Current `VectorImageRasterizationOptions` parameters:

- `size`
- `scale`
- `contentMode`
  Supported values: `.fit`, `.fill`, `.stretch`
- `opaque`
- `backgroundColor`

### `VectorImageRasterizationOptions`

```swift
import CoreGraphics
import VectorImageCore

let options = VectorImageRasterizationOptions(
    size: CGSize(width: 160, height: 80),
    scale: 2,
    contentMode: .fit,
    opaque: false,
    backgroundColor: VectorImageColor(
        red: 1,
        green: 1,
        blue: 1,
        alpha: 1
    )
)
```

Not currently provided as first-class package APIs:

- asset-catalog lookup by image name
- SF Symbols / `systemImage`

Those remain intentionally outside the first-class package surface so the public API stays focused on SVG loading and rendering rather than general app resource lookup.

### `VectorImageCache`

```swift
import VectorImageCore

let cache = VectorImageCache(countLimit: 64)

let result = try await VectorImageRenderer.render(
    from: .remoteURL(URL(string: "https://example.com/logo.svg")!),
    options: .init(size: CGSize(width: 120, height: 120)),
    cache: cache
)

let image = result.image
```

Pass `nil` to disable caching for source-based renders when you want to inspect fetch or memory behavior directly.

Source-based rendering also coalesces identical in-flight requests. If two callers ask for the same `VectorImageSource` with the same `VectorImageRasterizationOptions` and loader identity while the first render is still running, they await the same render task instead of starting duplicate network or file work. This is separate from `VectorImageCache`: coalescing prevents duplicate concurrent work, while caching stores completed render results for later calls.

The coalescing key includes the loader identity, so custom `VectorImageLoader` instances with different `URLSession` policies are not merged together.

### SwiftUI shared configuration

```swift
import SwiftUI
import VectorImageCore
import VectorImageUI

struct LogoListView: View {
    let urls: [URL]

    private let configuration = VectorImageConfiguration(
        cachePolicy: .enabled(countLimit: 64),
        inFlightRequestPolicy: .coalesceIdenticalRequests
    )

    var body: some View {
        List(urls, id: \.self) { url in
            VectorImageAsyncImage(
                url: url,
                options: .init(size: CGSize(width: 96, height: 96))
            ) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    ProgressView()
                }
            }
        }
        .vectorImageConfiguration(configuration)
    }
}
```

Use `reloadID` when the source is the same but the host app needs to force a reload, for example after a manual refresh action:

```swift
@State private var reloadID = 0

VectorImageAsyncImage(
    url: url,
    reloadID: reloadID
) { phase in
    if let image = phase.image {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
    } else {
        ProgressView()
    }
}

Button("Reload") {
    reloadID += 1
}
```

## Documentation

The package includes DocC catalogs for all public library layers.

- In Xcode, open the package and build documentation for `VectorImageCore`, `VectorImageAdvanced`, or `VectorImageUI`.
- In Swift Package Index, `.spi.yml` is configured so hosted documentation includes all public modules.

## Supported SVG Subset

`VectorImageCore` is intentionally focused rather than aiming to be a full browser-grade SVG engine.

Currently supported:

- `svg`, `rect`, `circle`, `ellipse`, `line`, `polyline`, `polygon`, `path`, `g`, `defs`, `clipPath`, `linearGradient`, `radialGradient`, `stop`
- basic `fill`, `stroke`, `stroke-width`, `opacity`, `fill-opacity`, `stroke-opacity`
- stroke presentation attributes: `stroke-linecap`, `stroke-linejoin`, `stroke-miterlimit`, `stroke-dasharray`, `stroke-dashoffset`
- inline `style="..."`
- focused `<style>` block rules for practical class, id, and element selectors
- `currentColor` resolved from inherited SVG `color` attributes
- visibility controls for supported render nodes: `display="none"`, `visibility="hidden"`, `visibility="collapse"`
- `fill-rule="evenodd"`
- simple shape and group transforms: `translate`, `scale`, `rotate`, `skewX`, `skewY`, `matrix`
- simple nested `svg` containers with inherited presentation attributes and `x`/`y` offsets
- clip-path references used by supported grouped assets
- deferred `defs` resolution for supported clip paths and gradients
- basic linear and radial gradient fills used by the supported subset

Currently not supported:

- masks
- filters
- `use`
- text nodes
- embedded raster images
- external CSS stylesheets
- percentage-based layout and viewport units beyond the simple values already covered by tests
- advanced nested `svg` viewport scaling and clipping
- full CSS selector support
- the full SVG specification

Unsupported features should fail safely and surface diagnostics rather than crashing.

## Known Limitations

`VectorImageCore` is a focused renderer, not a browser SVG engine. The supported subset is intentionally limited to keep the package dependency-free, public-SDK-safe, and predictable for app integration.

Important limitations:

- SVG detection requires an actual `<svg>` tag. XML declarations alone are not treated as SVG.
- `VectorImageSource.data` is not cached automatically because raw bytes do not provide a stable external identity.
- Remote loading uses `URLSession`; host apps remain responsible for network entitlements, app sandbox settings, and custom HTTP policy.
- The renderer does not execute scripts, load external resources, or resolve external stylesheets.
- Text, masks, filters, `use`, embedded raster images, and full CSS layout are outside the supported subset.
- `VectorImageAdvanced` performs conservative cleanup and focused style compatibility only. It is not a browser compatibility layer and does not resolve external resources.

## Performance Guardrails

The package is intended to stay lightweight and predictable for app integration.

Current guardrails for `VectorImageCore`:

- parsing and rasterization should be safe to run off the main thread
- repeated renders should not show unbounded resident memory growth
- representative small fixtures should stay within baseline render-time budgets
- unsupported features should produce diagnostics rather than expensive fallback behaviour

The test suite includes baseline performance checks for:

- average render time of a simple fixture
- average render time of a representative compound fixture
- approximate resident memory growth during repeated rendering

These are baseline guardrails, not strict cross-machine benchmarks.

## Planned

This section tracks what is already included in the public release line.

### `0.1.0` foundation

- [x] Dependency-free SVG detection, parsing, and rasterization
- [x] Public-SDK-safe implementation with no private Apple SVG framework usage
- [x] iOS 15 minimum deployment target
- [x] macOS 12 minimum deployment target for `VectorImageCore`
- [x] Support for `Data`, file URLs, and remote URLs
- [x] Async source-based render helpers
- [x] Support for a focused SVG subset used by current fixtures
- [x] Support for inline `style` attributes
- [x] Support for simple shape and group transforms: `translate`, `scale`, `matrix`
- [x] Support for translated clip paths used by representative fixtures
- [x] Support for basic linear and radial gradient fills used by current fixtures
- [x] Support for `fill-rule="evenodd"`
- [x] Diagnostics for unsupported SVG features
- [x] Example iOS app with inline, asset, and public remote SVG samples
- [x] Regression tests for representative fixtures
- [x] Baseline performance guardrails for render time and memory growth
- [x] Placeholder `VectorImageAdvanced` and `VectorImageUI` modules reserved for future work

### Planned for `0.2.0`

- [x] Real `VectorImageUI` module instead of a placeholder
- [x] SwiftUI async image view for SVG sources
- [x] Core in-flight coalescing for identical source-based render requests

### Planned for `0.3.0`

- [x] Source-rendering configuration object
- [x] Configurable completed-result cache policy
- [x] Configurable in-flight request coalescing policy
- [x] Configuration support in `VectorImageUI`
- [x] Tests for cache and coalescing policy behavior

### Planned for `0.4.0`

- [x] SwiftUI environment configuration for `VectorImageAsyncImage`
- [x] Explicit reload trigger through `reloadID`
- [x] iOS example app using shared environment configuration
- [x] Swift Testing coverage for `VectorImageUI` environment behavior

### Planned for `0.5.0`

- [x] Focused SVG `<style>` block support
- [x] Practical class selector support for exported SVGs using `.cls-*` rules
- [x] CSS id and element selector support for presentation attributes
- [x] `currentColor` resolution from inherited SVG `color` attributes
- [x] Regression tests for stylesheet precedence and comments
- [x] Supported-subset documentation updated for stylesheet behavior

### Planned for `0.6.0`

- [x] `stroke-linecap`
- [x] `stroke-linejoin`
- [x] `stroke-miterlimit`
- [x] `stroke-dasharray`
- [x] `stroke-dashoffset`
- [x] Regression tests for parsed and rendered stroke presentation behavior

### Planned for `0.7.0`

- [x] Root `svg` presentation-attribute inheritance
- [x] `display="none"` and stylesheet-backed hidden-node handling
- [x] `visibility="hidden"` and `visibility="collapse"` handling for supported nodes
- [x] Simple nested `svg` container support with `x`/`y` offsets
- [x] Regression tests for hidden elements, hidden groups, root inheritance, and nested containers

### Planned for `0.8.0`

- [x] `rotate(angle)` transform support
- [x] `rotate(angle cx cy)` transform support
- [x] `skewX(angle)` and `skewY(angle)` transform support
- [x] Regression tests for the new transform geometry

### Included in `0.9.0`

- [x] Senior pre-1.0 API, docs, examples, concurrency, and test review
- [x] SVG detector tightened so XML alone is not accepted as SVG
- [x] Known limitations documented in README and DocC
- [x] Stale example-app text and generated test placeholders cleaned up

### Planned for `1.0.0`

- [x] Stable public API review
- [x] Production adoption validation checkpoint for host-app integration
- [x] Define `VectorImageAdvanced` as an optional preprocessing and compatibility layer
- [x] Initial `VectorImageAdvancedProcessor` and `VectorImageAdvancedResult` API shape
- [x] Confidence that the documented supported SVG subset is stable enough for long-term maintenance

### Included in `1.1.0`

- [x] Conservative Advanced cleanup for script elements
- [x] Conservative Advanced cleanup for SVG event handler attributes
- [x] Conservative Advanced cleanup for external resource references
- [x] Advanced preprocessing diagnostics for cleanup actions
- [x] Advanced render and renderImage helpers backed by Core

### Included in `1.2.0`

- [x] Advanced inline `style=""` declaration normalization
- [x] Advanced stylesheet inlining for simple element, class, id, and compound selectors
- [x] Attribute precedence preserved during Advanced style preprocessing
- [x] Unsupported stylesheet selector diagnostics

## Package Layout

- `VectorImageCore`
  The real implementation target. Contains SVG detection, parsing, diagnostics, and rasterization into `UIImage` or `NSImage`.
- `VectorImageAdvanced`
  Optional preprocessing and compatibility layer that validates, cleans, and normalizes supported SVG style input before handing it to `VectorImageCore`.
- `VectorImageUI`
  SwiftUI integration target with async SVG image loading built on `VectorImageCore`.

## Example Apps

The repository includes two example applications:

- `Example/VectorImageExample`
  iOS sample app
- `Example/VectorImageMacExample`
  macOS sample app

Current demo coverage:

- local package integration for `VectorImageCore`, `VectorImageAdvanced`, and `VectorImageUI`
- iOS demo coverage for `VectorImageAsyncImage` using inline SVGs and public remote URLs
- iOS demo coverage for shared `VectorImageUI` environment configuration
- rendered sample SVG cards using bundled asset-catalog SVGs and public remote URLs
- diagnostics display for unsupported SVG features that are outside the documented subset
- startup toggle for cache behavior using `--vectorimage-disable-cache`

## Testing

Run the package tests with:

```bash
swift test
```
