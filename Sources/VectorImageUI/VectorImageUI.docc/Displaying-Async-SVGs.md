# Displaying Async SVGs

Load SVG content asynchronously in SwiftUI using `VectorImageAsyncImage`.

## Overview

``VectorImageAsyncImage`` is the main SwiftUI entry point in `VectorImageUI`.

It supports:

- raw SVG bytes through `.data`
- local SVG files through `.fileURL`
- remote SVGs through `.remoteURL`

The view resolves the source, renders through ``VectorImageRenderer``, and exposes the result through ``VectorImageAsyncImagePhase``.

## Example

```swift
import SwiftUI
import VectorImageCore
import VectorImageUI

struct RemoteLogoView: View {
    let url: URL

    var body: some View {
        VectorImageAsyncImage(
            url: url,
            options: .init(size: CGSize(width: 160, height: 160))
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

Use configuration when SwiftUI views should share source-rendering policy:

```swift
let configuration = VectorImageConfiguration(
    cachePolicy: .enabled(countLimit: 64),
    inFlightRequestPolicy: .coalesceIdenticalRequests
)

List(urls, id: \.self) { url in
    VectorImageAsyncImage(
        url: url,
        options: .init(size: CGSize(width: 160, height: 160))
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
```

Pass `configuration:` directly when only one image should use a custom policy:

```swift
VectorImageAsyncImage(
    url: url,
    configuration: configuration,
    options: .init(size: CGSize(width: 160, height: 160))
) { phase in
    if let image = phase.image {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
    } else {
        ProgressView()
    }
}
```

Use `reloadID` to force a reload when the source value itself has not changed:

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

## Notes

- The view uses the same rasterization options type as `VectorImageCore`.
- Source-based caching is available by passing a ``VectorImageCache`` instance.
- Configuration-based source rendering is available by passing a ``VectorImageConfiguration``.
- Shared SwiftUI configuration is available through `EnvironmentValues.vectorImageConfiguration` and `View.vectorImageConfiguration(_:)`.
- Successful phases also expose diagnostics when the supported SVG subset ignores non-fatal features.
