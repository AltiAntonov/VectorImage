# Changelog

## 0.4.0

- Added SwiftUI environment support for shared `VectorImageConfiguration` values.
- Added a `vectorImageConfiguration(_:)` view modifier for configuring descendant `VectorImageAsyncImage` views.
- Added `reloadID` support to `VectorImageAsyncImage` so callers can explicitly trigger reloads.
- Updated the iOS example app to provide configuration through the SwiftUI environment.
- Added `VectorImageUITests` coverage for environment configuration behavior.

## 0.3.0

- Added `VectorImageConfiguration` for source-based rendering policy.
- Added `VectorImageCachePolicy` to enable or disable completed-result caching through configuration.
- Added `VectorImageInFlightRequestPolicy` to enable or disable identical in-flight request coalescing.
- Added configuration-based `VectorImageRenderer.render` and `renderImage` entry points.
- Added configuration support to `VectorImageAsyncImage`.
- Updated the example apps to use configuration-driven cache policy.
- Added tests for configuration cache policy and coalescing policy behavior.

## 0.2.0

- Added a real `VectorImageUI` module instead of a placeholder target.
- Added `VectorImageAsyncImage` for SwiftUI-based async SVG loading from `Data`, file URLs, and remote URLs.
- Added `VectorImageAsyncImagePhase` and `VectorImageAsyncImageValue` so SwiftUI hosts can react to loading, success, diagnostics, and failure states.
- Added convenience `VectorImageAsyncImage` entry points for source, data, file URL, and remote URL usage.
- Added in-flight coalescing for identical source-based render requests to avoid duplicate concurrent fetch/render work.
- Updated the iOS example app to exercise the new SwiftUI UI layer instead of only manual core rendering.
- Added a dedicated DocC catalog for `VectorImageUI`.

## 0.1.0

- First stable public release of `VectorImageCore`.
- Added dependency-free SVG detection, parsing, and rasterization for iOS 15+ and macOS 12+.
- Added support for raw `Data`, local file URLs, and remote URLs.
- Added optional render-result caching for repeated source-based renders.
- Added async source-based loading and rendering helpers.
- Added support for inline `style` attributes, inherited group styling, group transforms, translated clip paths, and `evenodd` fill rules.
- Added support for smooth SVG path commands used by real-world public SVGs.
- Added deferred `defs` resolution for supported clip paths and gradient fills.
- Added basic linear and radial gradient rendering for the currently supported SVG subset.
- Fixed incorrect default black stroke behaviour when `stroke` is not present.
- Added optional rasterization background color configuration through `VectorImageRasterizationOptions`.
- Added diagnostics for unsupported SVG features.
- Added baseline performance guardrails for render time and memory growth.
- Added `VectorImageExample` for iOS and `VectorImageMacExample` for macOS with inline, asset, and public remote SVG sample rendering screens.
- Added regression tests covering supported SVG rendering, diagnostics, representative fixtures, and cache behavior.
- Included placeholder `VectorImageAdvanced` and `VectorImageUI` targets for future expansion.

## Next Up

- later `0.x`
  Additional hardening or focused feature work can happen before `1.0.0` if the package needs it.
- `1.0.0`
  Reserved for the point where the public API and supported SVG subset are stable enough for long-term maintenance.
