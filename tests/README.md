# Regression checks

Run from the addon folder in PowerShell. Test dependencies can stay outside the
addon; none are loaded by WoW:

```powershell
npm.cmd install --prefix "$env:TEMP\ubi-test-tools" --cache "$env:TEMP\ubi-test-cache" --ignore-scripts --no-audit --no-fund luaparse fengari
$env:NODE_PATH = Join-Path $env:TEMP 'ubi-test-tools\node_modules'
node tests/run-tests.cjs
```

The runner checks first-party Lua syntax, embedded XML/binding handlers, TOC
references, version metadata, the scrolling controller, and the five review
regressions, plus currency catalog grouping, unavailable metadata, optional/alt
currency rows, and token scrollbar bounds. Inventory tests extract the current production function bodies
using the Lua parser and run them with mocked WoW APIs.

The mocks cannot verify native rendering, clipping, mouse targeting, or tooltip
appearance. In WoW, reload the addon and check scrolling and dragging, filter
changes, ordinary/pet tooltips, modified clicks, and item tint after scrolling
between unusable items and pets. Also check literal searches (`[`, `%`, `.`),
same-name alts across realms, and sent/returned mail counts. Cache preservation
and delayed loading are covered deterministically by the regression suite.
