# VectorImageAdvanced

Validate and prepare SVG input before rendering with `VectorImageCore`.

## Overview

`VectorImageAdvanced` is the optional compatibility layer for `VectorImage`.

The module validates incoming SVG data and applies conservative deterministic preprocessing before handing bytes to `VectorImageCore`.

Advanced removes script elements, SVG event handler attributes, and external resource references. It also normalizes supported inline `style=""` declarations, simple stylesheet rules, and local `<symbol>` / `<use href="#...">` references into Core-friendly SVG. Cleanup actions, unsupported stylesheet selectors, unresolved use references, external use references, and recursive use references are surfaced as diagnostics. `VectorImageCore` remains the only renderer.

Use ``VectorImageAdvancedProcessor/process(svgData:)`` when you want to inspect or store preprocessed SVG bytes before rendering. Use ``VectorImageAdvancedProcessor/render(svgData:options:)`` when you want Advanced preprocessing and Core rendering in one call.

## Topics

### Preprocessing

- ``VectorImageAdvancedProcessor``
- ``VectorImageAdvancedResult``

### Module Role

- ``VectorImageAdvancedFeatureSet``
