# VectorImageAdvanced

Validate and prepare SVG input before rendering with `VectorImageCore`.

## Overview

`VectorImageAdvanced` is the optional compatibility layer for `VectorImage`.

In `1.0.0`, the module establishes the public preprocessing result shape and validates that incoming data is SVG. It intentionally forwards valid SVG bytes unchanged so `VectorImageCore` remains the only renderer.

Future minor releases can add deterministic preprocessing passes here without expanding Core's responsibilities.

## Topics

### Preprocessing

- ``VectorImageAdvancedProcessor``
- ``VectorImageAdvancedResult``

### Module Role

- ``VectorImageAdvancedFeatureSet``
