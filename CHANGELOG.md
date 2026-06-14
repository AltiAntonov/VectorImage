# Changelog

## 1.3.0

- Added `VectorImageAdvanced` expansion for local `<symbol>` and `<use href="#...">` references.
- Added support for translating expanded local uses with `x` and `y` attributes.
- Added diagnostics for expanded local references, unresolved local references, external use references, and recursive use references.
- Preserved unrelated `<defs>` content while removing expanded local definitions from processed output.
- Updated iOS and macOS example apps with Advanced examples for cleanup, style compatibility, and local use expansion.
- Added Advanced regression tests proving expanded output can render through `VectorImageCore`.

## 1.2.0

- Added `VectorImageAdvanced` style compatibility preprocessing for supported inline `style=""` declarations.
- Added deterministic inlining for simple stylesheet element, class, id, and single compound selectors.
- Preserved SVG precedence so element attributes stay above stylesheet rules and inline style declarations stay above both.
- Removed processed `<style>` blocks from Advanced output while reporting unsupported stylesheet selectors as diagnostics.
- Added Advanced regression tests for inline style normalization, supported stylesheet inlining, precedence, and unsupported selector diagnostics.

## 1.1.0

- Added conservative cleanup in `VectorImageAdvancedProcessor.process(svgData:)` for script elements, SVG event handler attributes, and external resource references.
- Added preprocessing diagnostics that describe cleanup actions before rendering.
- Added `VectorImageAdvancedProcessor.render(svgData:options:)` and `renderImage(svgData:options:)` helpers that preprocess through Advanced, then render through Core.
- Preserved namespace declarations such as `xmlns` while removing unsupported external resource references.
- Added Advanced regression tests for safe cleanup and preprocessing-backed rendering.

## 1.0.0

- Stabilized the public `VectorImageCore` and baseline `VectorImageUI` API surface for the supported SVG subset.
- Defined `VectorImageAdvanced` as an optional preprocessing and compatibility layer that prepares SVG input for `VectorImageCore`.
- Added `VectorImageAdvancedProcessor` and `VectorImageAdvancedResult` as the initial Advanced API shape.
- Added `VectorImageAdvancedTests` coverage for valid SVG pass-through processing, empty data rejection, and non-SVG rejection.
- Updated README and DocC wording for the 1.0 package layout and Advanced module role.

## 0.9.0

- Tightened SVG detection so XML documents are only accepted when they contain an actual SVG tag.
- Added regression coverage for non-SVG XML payloads.
- Added clearer known-limitations documentation ahead of the `1.0.0` API freeze.
- Cleaned stale example-app target descriptions and generated test placeholders.

## 0.8.0

- Added SVG `rotate(...)` transform support, including rotation around an explicit center point.
- Added SVG `skewX(...)` and `skewY(...)` transform support.
- Added regression tests for origin rotation, centered rotation, and skew transform geometry.

## 0.7.0

- Added root `svg` presentation-attribute inheritance for supported render attributes.
- Added `display="none"` handling for supported SVG nodes, including values supplied by focused stylesheet rules.
- Added `visibility="hidden"` and `visibility="collapse"` handling for supported nodes and containers.
- Added simple nested `svg` container support with inherited presentation attributes and `x`/`y` offsets.
- Added regression tests for hidden elements, hidden groups, stylesheet-backed hiding, root inheritance, and nested containers.

## 0.6.0

- Added support for `stroke-linecap`, `stroke-linejoin`, `stroke-miterlimit`, `stroke-dasharray`, and `stroke-dashoffset`.
- Added inherited and stylesheet-backed stroke presentation support for the new stroke attributes.
- Added dashed-stroke rendering coverage to verify visible gaps are rasterized correctly.
- Added regression tests for direct and stylesheet-provided stroke presentation attributes.

## 0.5.0

- Added focused support for SVG `<style>` blocks with practical class, id, and element selectors.
- Added CSS presentation-attribute support for common exported SVG class styles such as `.cls-1 { fill: ... }`.
- Added `currentColor` resolution from inherited SVG `color` attributes.
- Preserved SVG style precedence so element attributes and inline `style` declarations override stylesheet rules.
- Added regression tests for stylesheet class rules, id selectors, CSS comments, and element-attribute precedence.
- Updated supported-subset documentation to clarify the package supports focused SVG styling, not full CSS.

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

- post-`1.0.0`
  Focused non-breaking improvements to `VectorImageAdvanced`, `VectorImageUI`, diagnostics, and fixture coverage.
