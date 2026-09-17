# Code quality review and resolutions

Reviewed 2026-09-17 against `da049bbf5f9f4825aa685af4c0c7390c739661ca`.
The worktree and installed source matched that baseline. The user then authorized
fixes and documentation. Changes below are prepared in the isolated worktree;
the installed runtime remains on the baseline pending separate approval.

## Assessment

Tank is a sound small-addon example after this bounded cleanup. It retains its
small composition root, feature-owned event lifecycles, exact identity model,
private addon namespace and narrow public accessory contracts. No framework or
UI redesign was needed. The accepted rail, transparent name area, icon styling,
stance and cooldown spacing are unchanged.

Review covered every TOC module, tests, scripts and documentation. Current
Keybinds client/storage/UI helpers were read-only design references; its
uncommitted work was preserved. No source addon, client junction or installed
character data was modified.

## Findings and disposition

### P2: Unavailable aura data could stay cached after the reader recovered — fixed

Baseline evidence: `Threat/Observer.lua:119`, `:128`, `:133`, `:172`.
A failed read produced a cache entry with nil player auras. Subsequent refreshes
reused it until invalidation, suppressing reminders/applied icons even if the
reader became available. An in-memory reproduction confirmed one API read over
two refreshes, followed by recovery only after explicit invalidation.

The observer now caches only successful snapshots. Nil remains unknown and
retries on the existing coalesced combat refresh, at most once per observed GUID
per refresh; there is no new polling driver. Successful empty lists remain cached.
`tests/aura_recovery_spec.lua` covers repeated unavailability, recovery without
an aura event, successful caching and empty-result caching. Live incidence of
transient API failure was not measured.

### P2 on downgrade: Newer character schemas could be rewritten as version 2 — fixed

Baseline evidence: `Core/ObservedSpellList.lua:17`; SavedVariable assignments in
`Effects/Runtime.lua:67` and `Cooldowns/Runtime.lua:86`.
A synthetic version-99 store was accepted, converted to version 2 and lost its
unknown field in the replacement store. Supported version-2 and legacy data
were not implicated.

The shared loader now returns `nil, reason` for newer schemas before normalization.
Runtimes preserve the original SavedVariable, keep the affected driver inactive,
and print one explanatory message. A rejected effects store disables debuff
reminders and the Effects-owned picker; an otherwise healthy cooldown tracker
still runs. A rejected cooldown store does not prevent the debuff picker.
This is deliberate failure behavior, not automatic migration or reset.

`tests/persistence_runtime_spec.lua` creates fresh drivers for all four healthy/
rejected-store combinations. It checks table identity and preserved contents,
independent startup, later combat/aura/cooldown/zoning events, public refresh/
clear calls, sleeping rejected drivers and one message per affected feature.
Model tests retain version-1 migration, version-2 reload, opt-outs and Clear
behavior, and now cover rejection plus copied watched entries.

### P3: Shared selection model contained missing-effect policy — fixed

Baseline evidence: `Core/ObservedSpellList.lua:120`, `Effects/Model.lua:2`.
Core now owns neutral spell identity, watched/ignored selections, copied entries,
revisions and persistence. Effects owns `GetMissing` and its exact player-owned
presence policy. Cooldown models no longer carry an irrelevant coverage method.
The existing ownership/missing-effect tests still run against the feature model.

The combined picker uses named dependencies instead of six positional arguments.
It remains owned by Effects and accesses only the supplied cooldown selection
operations. Extracting a generic picker registry for two fixed columns was
intentionally deferred; it would add more indirection than useful separation.

### P3: Unused refresh/color exports obscured the intended lifecycle — fixed

Baseline evidence: `Threat/Hud.lua:515`, `:522`, `:583`, `:645` and
`Threat/Observer.lua:253`. Repository-wide searches found no consumers for
`RefreshPlayer`, `RefreshUnit`, `GetPlayerHealthColor` or `IsObservedUnit`.
These were removed, along with the always-true `ShouldShow` hook. The runtime
continues to use its single coalesced HUD refresh path.

Stable public anchors/callbacks and tested snapshot metadata remain. Historical
geometry constants still contributing to layout were not deleted or adjusted.
No abandoned outline or tab construction remains in the current HUD.

### P3: README contradicted the current addon — fixed

Baseline evidence: `README.md:6`, `:34`, `:63`, `:77`, `:123`, `:129`, `:132`, `:171`.
The rewritten README describes both learned lists, the draggable side-by-side
picker, per-column clear confirmation, combat-only cooldown HUD and current
installation/verification expectations. [Architecture](ARCHITECTURE.md) documents
module ownership, public contracts, nil versus empty reads, initialization
failure, and a small-feature extension recipe. API/visual notes and changelog
were updated. Baseline line references above intentionally describe reviewed
code, not the moved lines in the fixed version.

## Strengths retained and remaining limits

- Startup stays small and features remain independent. Effects receives complete
  owned auras and refreshes with row assignment, avoiding cross-enemy reminders.
  The synthetic demo never enters discovery or persistence.
- Cooldown sampling is event-driven; countdown rendering reuses cached state and
  skips unchanged writes. Stance and cooldowns share the player-status anchor.
- Keybinds demonstrates useful named API/storage/UI boundaries and a future-schema
  guard. Tank borrows these principles without copying secure actions, settings
  machinery or a centralized event framework.
- API isolation is intentionally partial. Some threat/identity/nameplate calls
  remain in feature code and legacy health colors remain in the unit helper.
  Move only actual compatibility differences before supporting another client.
- The large whole-addon runtime test shares a fake world across scenarios.
  Its local-only `IsShown` and no-op `SetAllPoints` cannot prove inherited
  visibility, clipping or real draw order. New persistence cases use fresh
  fixtures; splitting the established integration suite is optional follow-up,
  not required to ship these fixes.
- Snapshot `victim`/`worst` metadata, the size of the HUD module and unused cooldown
  rate metadata were reviewed but left alone. No demonstrated current Era defect
  justified changing their behavior or porting a new timing model in this pass.

## Validation and next step

Run `pwsh ./scripts/test-local.ps1`: all eight Lua specs, Lua 5.1 parsing, TOC
checks, export-checker fixtures and whitespace validation pass. The actual
local Era export check also passes for build 1.15.9.69722 / interface 11509;
that is freshness metadata, not proof of all API signatures or another client.
New regressions were checked against the pre-fix observer/shared model to ensure
they detect the reviewed failures.

No remaining verified functional finding from this review is left unfixed.
The documented structural limits are bounded follow-ups, not a demand for a
framework rewrite. Review/approve behavioral installation next. After approval,
perform live reload, target/aura, picker, cooldown and combat/zoning checks; mock
results do not establish visual or live-event acceptance.
