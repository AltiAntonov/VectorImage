# ``VectorImageCore``

Dependency-free SVG loading, parsing, diagnostics, and rasterization for iOS 15+ and macOS 12+.

## Overview

`VectorImageCore` is the focused implementation target in the `VectorImage` package. It is intentionally scoped to a documented subset of SVG rather than attempting full browser-grade SVG support.

Use it when you need to:

- detect whether raw bytes look like SVG
- load SVGs from `Data`, local files, or remote URLs
- rasterize SVG content into `UIImage` or `NSImage`
- surface diagnostics for unsupported features
- configure source-based loading, caching, and in-flight request behavior
- optionally cache repeated source-based renders
- render practical exported-SVG styles, including inline styles and focused class/id/element rules from `<style>` blocks
- render common stroke presentation attributes such as line caps, joins, miter limits, and dashes

The module does not depend on Apple private SVG frameworks and is safe to integrate in public app or SDK code. It supports a focused SVG subset and does not aim to be a browser-grade SVG/CSS engine.

## Topics

### Essentials

- <doc:Rendering-SVGs>
- <doc:Loading-SVG-Sources>
- <doc:Configuring-Source-Rendering>
- <doc:Caching-Rendered-Results>

### Core Types

- ``VectorImageDetector``
- ``VectorImageRenderer``
- ``VectorImageSource``
- ``VectorImageRasterizationOptions``
- ``VectorImageConfiguration``
- ``VectorImageCachePolicy``
- ``VectorImageInFlightRequestPolicy``
- ``VectorImageCache``
- ``VectorImageColor``
