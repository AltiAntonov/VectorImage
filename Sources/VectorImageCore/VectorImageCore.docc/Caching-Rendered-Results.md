# Caching Rendered Results

Reuse rendered results for repeated source-based renders.

## Overview

``VectorImageCache`` is an optional in-memory cache for the async source-based rendering path.

It helps when:

- the same remote URL is requested multiple times
- the same file URL is rendered repeatedly
- a host app re-renders the same source during view refreshes or repeated loads

Source-based rendering also coalesces identical in-flight requests. If multiple callers request the same source with the same rasterization options and loader identity while the first render is still running, they await the same render task instead of starting duplicate network or file work.

Caching and coalescing solve different problems:

- coalescing avoids duplicate concurrent work
- caching reuses a completed render result for later calls

## Example

```swift
import VectorImageCore

let cache = VectorImageCache(countLimit: 64)
let source = VectorImageSource.remoteURL(
    URL(string: "https://example.com/logo.svg")!
)

let result = try await VectorImageRenderer.render(
    from: source,
    options: VectorImageRasterizationOptions(size: CGSize(width: 160, height: 80)),
    cache: cache
)

let image = result.image
```

## Notes

- Pass `nil` for `cache` to disable caching.
- The cache key includes both the source identity and rasterization options.
- In-flight coalescing remains active even when `cache` is `nil`.
- The in-flight coalescing key includes source identity, rasterization options, and loader identity.
- The current cache is intentionally lightweight and in-memory only.
