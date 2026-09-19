# Architecture and extension guide

`ApogeeTank.lua` uses Core/Client.lua's gate and wires feature entry points through the
private addon table passed by WoW. It creates no feature policy. The TOC loads
definitions before this startup file; unsupported clients do not start drivers.

## Ownership

| Module | Responsibility |
| --- | --- |
| `UI/Style.lua` | Shared palette, fonts and cropped inset icons; no placement or feature policy. |
| `Core/Client.lua`, `Core/Access.lua` | Explicit verified-client selection and guarded ordinary Lua reads. |
| `Core/UnitAPI.lua` | Unit normalization, health/power colors and display-only native beta health/power sinks. |
| `Core/Auras.lua` | Harmful-aura reading and exact player ownership; nil means unavailable. |
| `Core/Cooldowns.lua`, `Core/Stance.lua` | Cooldown/charge and stance client reads. |
| `Core/ObservedSpellList.lua` | Exact spell identity, watched/ignored persistence, migration, version guard and revisions. |
| `Threat/Observer.lua` | Source deduplication, threat classification, aura cache and short history. |
| `Threat/DebuffData.lua` | Existing class/rank columns for applied effects only. |
| `Threat/Hud.lua` | Stable row assignment, presentation, fixed frames and public accessory anchors. |
| `Threat/Runtime.lua` | Threat events and coalesced refresh; asleep outside combat when idle. |
| `Threat/Demo.lua` | Temporary synthetic HUD presentation; never observation or saved data. |
| `Effects/Model.lua` | Missing-effect policy over the shared selection model. |
| `Effects/View.lua` | Missing reminder lanes and the combined two-column picker. |
| `Effects/Runtime.lua` | Debuff discovery, combat-gated access, persistence and row accessory updates. |
| `Cooldowns/Runtime.lua`, `Cooldowns/View.lua` | Candidate discovery, sampled state, combat visibility and cached countdown rendering. |
| `Stance/Runtime.lua` | Small event-driven stance icon; shared icon styling and fixed player-cluster anchor. |

Some threat/identity/nameplate APIs remain directly in the observer and runtime.
Core is a narrow shared boundary, not a claim that all client APIs are wrapped.
Add compatibility adapters only for demonstrated differences and actual callers.
Keep fixed feature limits with their owners; do not make all constants settings.

## Contracts worth copying

- `ObservedSpellList.Create(saved)` returns a model or `nil, reason` for a newer
  schema. Callers must not replace SavedVariables on failure. Supported input
  produces a normalized store; `GetSaved()` exposes the owned table solely for
  persistence. `Clear()` preserves that table identity.
- `Observe(spells)` accepts qualified `{spellId, name, icon}` identities; the
  feature decides what qualifies. `GetWatched()` and `GetEntries()` return copies.
  `SetWatched`, `Forget`, and `Clear` update the revision used by views to avoid
  rebuilding unchanged lists. Exact IDs and explicit opt-outs are preserved.
- `EffectsModel.GetMissing(auras, validTarget)` owns presence policy. Nil aura
  data suppresses claims; `{}` means known empty. Only full player-owned data
  belongs here, never visible icon slots. Unknown observer reads retry at the
  existing 0.1-second combat refresh cadence; successful results stay cached
  until invalidated. This adds no independent polling driver.
- `ThreatHud.GetEnemyRows()` exposes row/meter anchors, GUID, liveness and complete
  player auras. `SetRowsChangedHandler` has one consumer, Effects, and refreshes
  accessories with the same row assignment. Do not retain or mutate those
  snapshots, or inspect private marker/icon fields in another feature.
- `GetPlayerStatusAnchor` gives stance and cooldowns a shared positioning boundary.
  `SetPlayerClickHandler` lets Effects own the picker gesture while the HUD owns
  the health frame's mouse script. Neither is a saved binding or secure action.
- `EffectsView.Create(options)` takes named models/callbacks. Effects deliberately
  owns the existing combined picker; it uses the cooldown runtime's `GetModel`,
  `Refresh`, `Clear` and `SetChangedHandler` methods rather than its frames or
  driver state. Cooldown revision changes notify the picker without polling.
  Forever supplies only the cooldown column and disables effects/demo. A future
  third consumer may justify a separate picker module; today a generic settings
  framework would add indirection without a need.

## Add one feature without expanding the framework

1. Give the feature its own folder. Separate nontrivial decisions/data from
   frame construction and event lifecycle; tiny features can stay in one file.
2. Reuse a shared helper only when its contract fits. Add a narrow helper for
   actual multiple consumers, not possible future users.
3. Expose a small feature entry point returning only operations needed by other
   consumers. Use named dependencies for multiple callbacks; wire them in startup.
4. Add its definitions to the TOC before composition. Verify the Era export
   before API-dependent work. Do not enable another client by guessing identifiers.
5. Test decisions with pure fixtures, then test event/state/geometry contracts
   through a small fresh mock runtime. Keep the existing whole-addon integration
   test as complementary coverage. Rendering still needs an in-game check.

Any new saved setting, profile, binding or movable HUD surface requires explicit
scope approval. Preserve the accepted fixed layout when making internal changes.
