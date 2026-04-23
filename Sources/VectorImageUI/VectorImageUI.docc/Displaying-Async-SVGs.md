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

## Notes

- The view uses the same rasterization options type as `VectorImageCore`.
- Source-based caching is available by passing a ``VectorImageCache`` instance.
- Successful phases also expose diagnostics when the supported SVG subset ignores non-fatal features.
