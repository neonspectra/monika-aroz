# ArozOS Source

Developer documentation has moved to the `docs/` directory at the repository root:

- [Architecture](../docs/architecture.md) — request routing, filesystem layers, AGI execution model
- [Apps and Subservices](../docs/developers/apps-and-subservices.md) — webapp and subservice development
- [AGI Reference](../docs/developers/agi-reference.md) — complete server-side scripting API (moved from `agi-doc.md`)

## Development Notes

- Start each module with `{ModuleName}Init()` function, e.g. `WiFiInit()`
- Put your function in `mod/` (if possible) and call it in the main program
- Do not change the sequence in the `startup()` function unless necessary
- When in doubt, add startup flags
