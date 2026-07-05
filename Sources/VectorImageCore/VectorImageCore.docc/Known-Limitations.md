# Known Limitations

Understand the intentional boundaries of the focused SVG renderer.

## Overview

`VectorImageCore` is dependency-free and public-SDK-safe by design. It supports a documented SVG subset rather than attempting to match browser rendering behavior.

Important limitations:

- SVG detection requires an actual `<svg>` tag. XML declarations alone are not treated as SVG.
- Raw `.data` sources are not cached automatically because they do not provide a stable external identity.
- Host apps are responsible for network entitlements, app sandbox settings, and custom HTTP policy for remote URLs.
- External resources are not loaded. This includes scripts, external stylesheets, linked images, and remote references inside SVG payloads.
- Text, masks, filters, embedded raster images, full CSS layout, and full browser-grade SVG behavior are outside the supported subset.
- Nested `svg` support is intentionally simple and currently covers inherited presentation attributes plus `x`/`y` offsets, not full nested viewport layout.
- `VectorImageAdvanced` can preprocess supported local `<symbol>` / `<use href="#...">` references and safe layout forms before handing SVG data to Core. External, unresolved, recursive, or unsafe layout references remain unsupported and are reported through diagnostics.
