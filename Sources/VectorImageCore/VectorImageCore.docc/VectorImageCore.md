# ``VectorImageCore``

Dependency-free SVG loading, parsing, diagnostics, and rasterization for iOS 15+ and macOS 12+.

## Overview

`VectorImageCore` is the focused implementation target in the `VectorImage` package. It is intentionally scoped to a documented subset of SVG rather than attempting full browser-grade SVG support.

Use it when you need to:

- detect whether raw bytes look like SVG
- load SVGs from `Data`, local files, or remote URLs
- rasterize SVG content into `UIImage` or `NSImage`
- surface diagnostics for unsupported features
- optionally cache repeated source-based renders

The module does not depend on Apple private SVG frameworks and is safe to integrate in public app or SDK code.

## Topics

### Essentials

- <doc:Rendering-SVGs>
- <doc:Loading-SVG-Sources>
- <doc:Caching-Rendered-Results>

### Core Types

- ``VectorImageDetector``
- ``VectorImageRenderer``
- ``VectorImageSource``
- ``VectorImageRasterizationOptions``
- ``VectorImageCache``
- ``VectorImageColor``
