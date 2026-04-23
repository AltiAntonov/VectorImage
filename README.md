<div align="center">
  <h1>VectorImage</h1>
  <p><strong>Dependency-free SVG parsing and rasterization for Apple platforms, with iOS and macOS example apps.</strong></p>
  <p>
    <img src="https://img.shields.io/badge/iOS-15%2B-34C759" alt="iOS 15+">
    <img src="https://img.shields.io/badge/macOS-12%2B-34C759" alt="macOS 12+">
    <img src="https://img.shields.io/badge/License-MIT-34C759" alt="MIT License">
  </p>
  <p>
    <a href="#features">Features</a> ·
    <a href="#installation">Installation</a> ·
    <a href="#quick-start">Quick Start</a> ·
    <a href="#api-surface">API Surface</a> ·
    <a href="#documentation">Documentation</a> ·
    <a href="#supported-svg-subset">Supported SVG Subset</a> ·
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
- support for practical SVG fidelity features such as clip paths, group transforms, gradients, and arc commands
- placeholder `VectorImageAdvanced` target reserved for future expansion
- fixture-based tests for the initial SVG subset
- included iOS and macOS example apps for manual validation

## Installation

Add `VectorImage` to your Swift Package Manager dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/AltiAntonov/VectorImage.git", from: "0.1.0")
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
- `VectorImageCache`
  Optional in-memory cache for repeated source-based renders.

Current public entry points in `VectorImageUI`:

- `VectorImageAsyncImage`
  SwiftUI async SVG view backed by `VectorImageCore`.
- `VectorImageAsyncImagePhase`
  Phase enum for loading, success, and failure states.
- `VectorImageAsyncImageValue`
  Successful render payload with `Image`, platform image, and diagnostics.

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

## Documentation

The package includes DocC catalogs for both public library layers.

- In Xcode, open the package and build documentation for `VectorImageCore` or `VectorImageUI`.
- In Swift Package Index, `.spi.yml` is configured so hosted documentation includes both public modules.

## Supported SVG Subset

`VectorImageCore` is intentionally focused rather than aiming to be a full browser-grade SVG engine.

Currently supported:

- `svg`, `rect`, `circle`, `ellipse`, `line`, `polyline`, `polygon`, `path`, `g`, `defs`, `clipPath`, `linearGradient`, `radialGradient`, `stop`
- basic `fill`, `stroke`, `stroke-width`, `opacity`, `fill-opacity`, `stroke-opacity`
- inline `style="..."`
- `fill-rule="evenodd"`
- simple shape and group transforms: `translate`, `scale`, `matrix`
- clip-path references used by supported grouped assets
- deferred `defs` resolution for supported clip paths and gradients
- basic linear and radial gradient fills used by the supported subset

Currently not supported:

- masks
- filters
- `use`
- text nodes
- the full SVG specification

Unsupported features should fail safely and surface diagnostics rather than crashing.

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

This section tracks what is already included in `0.1.0` and what is planned on the road to `1.0`.

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

### Possible later `0.x` releases

- [ ] Additional hardening releases between `0.2.0` and `1.0.0` if the package needs them
- [ ] Focused feature additions driven by real host-app needs

### Planned for `1.0.0`

- [ ] Stable public API review
- [ ] Production adoption validation in a host app
- [ ] Decide the long-term role of `VectorImageAdvanced`
- [ ] Confidence that the documented supported SVG subset is stable enough for long-term maintenance

## Package Layout

- `VectorImageCore`
  The real implementation target. Contains SVG detection, parsing, diagnostics, and rasterization into `UIImage` or `NSImage`.
- `VectorImageAdvanced`
  Placeholder target for richer SVG feature support in later versions.
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
- rendered sample SVG cards using bundled asset-catalog SVGs and public remote URLs
- diagnostics display for unsupported SVG features that are outside the documented subset
- startup toggle for cache behavior using `--vectorimage-disable-cache`

## Testing

Run the package tests with:

```bash
swift test
```
