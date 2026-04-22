# Rendering SVGs

Render SVG content when you already have the SVG bytes available in memory.

## Overview

Use ``VectorImageRenderer`` directly with raw `Data` when your app already owns the payload or when you want the simplest synchronous rendering path.

The canonical synchronous API is ``VectorImageRenderer/render(svgData:options:)``. It always returns the image plus diagnostics so callers can choose whether to inspect warnings or ignore them.

## Example

```swift
import UIKit
import VectorImageCore

let data: Data = ...

guard VectorImageDetector.isSVG(data: data) else {
    throw VectorImageError.notSVG
}

let result = try VectorImageRenderer.render(
    svgData: data,
    options: VectorImageRasterizationOptions(
        size: CGSize(width: 120, height: 120),
        scale: 2,
        contentMode: .fit,
        opaque: false
    )
)

let image = result.image
let warnings = result.diagnostics.warnings
```

## Notes

- Prefer rendering off the main thread and handing the resulting platform image to the UI layer.
- Diagnostics are non-fatal warnings about unsupported content or ignored features in the current supported subset.
