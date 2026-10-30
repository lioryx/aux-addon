# Project Guidelines

## Context
- This repository is a Turtle WoW / WoW 1.12 addon. Preserve compatibility with the existing runtime style and APIs, including old WoW globals and Lua patterns such as `module`, `event`, `arg1`, `this`, `setfenv`, and `getfenv`.
- File load order is defined by [aux-addon.toc](../aux-addon.toc). When adding, moving, or splitting Lua files, update the TOC in the correct order.
- Prefer extending existing patterns over modernizing the codebase. Do not introduce newer Lua module systems, addon frameworks, or retail-only WoW API assumptions.

## Architecture
- [aux-addon.lua](../aux-addon.lua) owns addon lifecycle, SavedVariables bootstrap, tab registration, and the staged startup hooks `INIT_UI`, `LOAD`, and `LOAD2`.
- `core/` contains auction-house behavior, scan state machines, history, posting, tooltip hooks, and other direct WoW API integrations.
- `gui/` contains reusable CreateFrame-based widgets, listings, and theme behavior shared by tabs.
- `tabs/<name>/core.lua` usually contains tab behavior and state, while `tabs/<name>/frame.lua` contains UI construction.
- `util/` contains shared helpers such as persistence, filtering, money formatting, scan helpers, and item info utilities.
- Module names do not always match file paths. Verify a file's declared `module` name and existing `require` targets before renaming files or changing imports.

## Conventions
- Register initialization work through `aux.handle.*` callbacks instead of replacing central lifecycle code.
- Reuse existing async/event helpers such as `aux.when`, `aux.thread`, listeners, and `aux.hook` for event-driven behavior.
- Treat auction scans as throttled asynchronous flows. Never assume `QueryAuctionItems` or related auction APIs return complete data immediately.
- Keep SavedVariables changes consistent with the existing `aux.account`, `aux.realm`, `aux.faction`, and `aux.character` scopes.
- Keep UI changes aligned with the existing hand-built CreateFrame style and both supported themes. Prefer extending shared helpers in `gui/` over duplicating widget logic inside a tab.
- Follow the existing tab split and avoid mixing large UI layout blocks into unrelated core logic.

## Validation
- There is no standalone build or automated test suite in this repository. Default validation is in-game manual testing.
- After behavior changes, validate the affected auction-house flow in game, and reload the UI when needed.
- For scan, bid, post, tooltip, or shortcut changes, test at least auction house open/close, the impacted tab workflow, and any related slash commands or bindings.

## References
- See [README.md](../README.md) for feature-level usage and auction query behavior.
- See [README_Geojak.md](../README_Geojak.md) for Turtle-specific changes and historical notes.
