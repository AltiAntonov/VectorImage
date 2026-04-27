# Configuring Source Rendering

Control loading, caching, and in-flight request behavior for source-based rendering.

## Overview

Use ``VectorImageConfiguration`` when you want one value that describes how source-based rendering should load SVG data and handle repeated work.

Configuration is useful when:

- multiple views should share the same completed-result cache
- identical concurrent requests should be coalesced
- identical concurrent requests should stay independent because the backend can return changing SVG content
- remote loading needs a custom `URLSession`

## Example

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
    options: VectorImageRasterizationOptions(size: CGSize(width: 120, height: 120))
)

let image = result.image
```

## Policy Notes

- Use ``VectorImageCachePolicy/disabled`` when every completed render should be fresh.
- Use ``VectorImageCachePolicy/enabled(_:)`` when repeated file or remote sources should reuse completed render results.
- Use ``VectorImageInFlightRequestPolicy/coalesceIdenticalRequests`` to avoid duplicate concurrent work.
- Use ``VectorImageInFlightRequestPolicy/disabled`` when identical concurrent requests must not share a result.
