# Minimal upstream fixes

Base: amap_map 1.0.15, published by https://github.com/kuloud/amap_map . Apache-2.0 license retained. Runtime sources and required resources are unmodified except these fixes:

- Android MapController camera#move: return success after accepting the camera update, so its Dart Future completes and callers/closed sheets are not left pending. This acknowledges the request, not the end of animation.
- Android ConvertUtil.location2Map: validate latitude rather than altitude against ±90°. A valid location must not be dropped merely for altitude above90m.

Revert the path override when an upstream release contains these fixes. This is a dependency patch, not a new platform implementation.
