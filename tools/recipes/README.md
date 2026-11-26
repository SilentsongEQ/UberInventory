# Recipe source database

`UberInventory_recipes.lua` is generated from a pinned **Retail** snapshot of
[AllTheThings](https://github.com/ATTWoWAddon/AllTheThings). Players do not need
AllTheThings installed. This is a development-time import, with no network calls
from the addon. The imported data is MIT licensed; retain `ATT-LICENSE.txt` when
redistributing it.

## Rebuild

Node.js and `luaparse` are required. The existing regression-test dependencies can
be used; nothing under this directory is loaded by WoW. From the addon directory:

```powershell
npm.cmd install --prefix "$env:TEMP\ubi-test-tools" --cache "$env:TEMP\ubi-test-cache" --ignore-scripts --no-audit --no-fund luaparse fengari
$env:NODE_PATH = Join-Path $env:TEMP 'ubi-test-tools\node_modules'
node tools/recipes/generate.cjs
node tests/run-tests.cjs
```

The generator downloads only the compiled Retail category files, localization
data, manifest, and license from the pinned commit. It caches those inputs under
the system temporary directory. Supply `--cache <directory>` to choose another
cache; use `--offline` to rebuild exclusively from cached files. No upstream Lua
or downloaded executable is run: constructors are interpreted from the syntax
tree as data. Cached inputs are checked against the previous audit's SHA-256
hashes when the revision is unchanged.

To update, change `source.json` to a full upstream commit SHA, its snapshot date,
and the target Retail interface number. Use a fresh cache for a new revision.
Regenerate and review **both** the database and `audit.json` before releasing.
The generator refuses unexpected license changes and fewer than 1,000 covered
recipe items; tests also enforce the established 5,000-item coverage floor.

## Data and coverage

The initial 2026-11-09 snapshot covers **5,425 of 5,511 identified recipe items**.
That is item coverage, not a guarantee that every acquisition path is present.
The audit lists the 86 unresolved item IDs, unresolved contexts, unsupported
symbolic queries, counts by source kind/availability, input checksums, and
comparison with the old 2010 database. `legacy-coverage.json` contains only the
old item IDs for that comparison; its obsolete source relationships are never
merged into the new output.

`UBI_RecipeSources[itemID]` contains source records with a `kind` and an optional
`id`, `text`, and list of current UI map IDs. Kinds are `vendor`, `quest`, `drop`,
`world`, `object`, `container`, `encounter`, and `other`. Optional restrictions
include faction (`1` Horde, `2` Alliance), race/class IDs, minimum reputation
`{factionID, reputationAmount}`, prerequisite quest IDs, added/removed patch
numbers, upstream availability codes, a conditional flag, and a display status.
Raw availability codes remain provenance data; the UI uses readable status text.

Recipe spell IDs are converted to their explicit recipe **item** IDs. Quest
prerequisites are retained as requirements, never presented as quest rewards.
Multiple locations and merchants remain separate relationships. Historical
sources are marked and sorted after unflagged sources. Absence of a restriction
flag does not prove availability. Generic upstream restrictions are shown as
additional requirements; this addon does not evaluate character eligibility.

NPC, map, quest, encounter, and container names resolve through WoW APIs when
available; object names and exceptional quest names have upstream English
fallbacks. Uncached/secret names show an ID and retry on the next hover. Existing
saved recipe preferences are retained. The drop option also controls treasures,
containers, world drops, and other sources. **No drop rates are stored or shown.**

## Known boundaries and review

- `NeverImplemented`, `Sourceless`, and `Unsorted` categories are excluded.
- Only the simple single `select itemID` symbolic query is expanded. Other
  symbolic queries and dynamic Lua calls are audited rather than guessed.
- Relationships are inferred from explicit source context in the compiled tree.
  This includes NPCs, quest reward children, encounters, objects, containers,
  vendor headers, world-drop headers, and the Black Market Auction House.
- This does not add a general profession-learning guide: trainer/discovery
  recipes without physical recipe item IDs do not belong in inventory tooltips.

Tests cover item/spell ID separation, UTF-8, prerequisites versus rewards,
multiple maps/merchants, faction overrides, removed/future sources, unresolved
queries, deterministic output, source-name cache retries, secret names, display
caps, saved options, and absence of drop rates. In WoW, `/reload`, toggle each
recipe option, and hover a vendor recipe, quest recipe, world-drop recipe,
container source, and historical recipe. Check long location/requirement lines
at your UI scale. Hover again after uncached names have loaded.
