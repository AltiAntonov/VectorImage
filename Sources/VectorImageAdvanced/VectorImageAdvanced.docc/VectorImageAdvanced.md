# VectorImageAdvanced

Validate and prepare SVG input before rendering with `VectorImageCore`.

## Overview

`VectorImageAdvanced` is the optional compatibility layer for `VectorImage`.

The module validates incoming SVG data and applies conservative deterministic cleanup before handing bytes to `VectorImageCore`.

In `1.1.0`, cleanup removes script elements, SVG event handler attributes, and external resource references. Cleanup actions are surfaced as diagnostics. `VectorImageCore` remains the only renderer.

Use ``VectorImageAdvancedProcessor/process(svgData:)`` when you want to inspect or store preprocessed SVG bytes before rendering. Use ``VectorImageAdvancedProcessor/render(svgData:options:)`` when you want Advanced preprocessing and Core rendering in one call.

## Topics

### Preprocessing

- ``VectorImageAdvancedProcessor``
- ``VectorImageAdvancedResult``

### Module Role

- ``VectorImageAdvancedFeatureSet``
