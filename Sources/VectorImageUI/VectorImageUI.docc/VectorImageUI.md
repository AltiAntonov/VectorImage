# ``VectorImageUI``

SwiftUI integration for loading and displaying SVG content with `VectorImageCore`.

## Overview

`VectorImageUI` is the app-facing SwiftUI layer in the `VectorImage` package.

Use it when you want to:

- load SVG content from raw `Data`, file URLs, or remote URLs
- render SVGs asynchronously inside SwiftUI
- react to loading, success, diagnostics, and failure states
- share `VectorImageCore` source-rendering configuration with SwiftUI views
- keep SVG parsing and rasterization delegated to `VectorImageCore`

`VectorImageUI` does not replace `VectorImageCore`. It builds on top of it.

## Topics

### Essentials

- <doc:Displaying-Async-SVGs>

### Core Types

- ``VectorImageAsyncImage``
- ``VectorImageAsyncImagePhase``
- ``VectorImageAsyncImageValue``
