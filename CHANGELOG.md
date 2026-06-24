# Changelog

All notable changes are documented here. This project adheres to [Semantic Versioning](https://semver.org).

## [Unreleased]

- **Removed large-title support.** The bar fade now targets the standard title only — simpler to use and explain.
- Slimmed the README to the essentials with a single demo GIF.
- Internal: extracted the bar-fade math into a pure, unit-tested helper; removed a vestigial property; added continuous integration.

## [5.3.1]

- Simplified: removed the rotation scroll-preservation machinery (the kit is portrait-oriented) and the fragile large-title collapse-distance refinement.
- The large title now scales with Dynamic Type.
- Documented the portrait orientation and the overscroll vs. pull-to-refresh conflict.

## [5.3.0]

- Derived the layout metrics from the runtime — the content anchor from the view's safe area, the large-title collapse from the bar's measured heights — instead of hardcoded constants.
- Preserved the scroll position across resize.

## [5.2.2] – [5.2.3]

- Coupled the large-title bar fade to the title collapsing into its inline position.
- Read the status bar from the controller's own scene (correct under multi-window) and cached the navigation-bar appearance.

## [5.2.0] – [5.2.1]

- Sized the cover off the view's own bounds so it survives resizing and non-fullscreen scenes.
- Smoothed the large-title fade, fixed the overscroll stretch, and added the README and demo GIFs.
