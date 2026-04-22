# Loading SVG Sources

Load and render SVG content from data, local files, or remote URLs.

## Overview

``VectorImageSource`` gives you a uniform way to describe where SVG content comes from:

- ``VectorImageSource/data(_:)``
- ``VectorImageSource/fileURL(_:)``
- ``VectorImageSource/remoteURL(_:)``

Use the async source-based rendering APIs when you want the renderer to perform the loading step for you.

## Example

```swift
import UIKit
import VectorImageCore

let source: VectorImageSource = .remoteURL(
    URL(string: "https://example.com/logo.svg")!
)

let result = try await VectorImageRenderer.render(
    from: source,
    options: VectorImageRasterizationOptions(
        size: CGSize(width: 120, height: 120),
        contentMode: .fit
    )
)

let image = result.image
let warnings = result.diagnostics.warnings
```

## Notes

- Remote loading uses ``VectorImageLoader`` under the hood.
- Keep the public `loader` parameter when you need dependency injection, custom `URLSession` behavior, or test control.
- File and remote sources can benefit from ``VectorImageCache`` when you render the same source repeatedly.
- The `.data` case is intentionally not auto-cached because raw bytes do not provide a stable external identity by default.
