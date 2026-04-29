# Tests

Local-first test fixtures for ai-harness-toolset.

- No cloud dependency.
- No global config mutation.
- No commit / push from tests.
- A test runner is not bundled in the first seed.

## Fixtures

- `fixtures/meta-with-bom.json` — must start with `EF BB BF`.
- `fixtures/meta-without-bom.json` — must not start with `EF BB BF`.
