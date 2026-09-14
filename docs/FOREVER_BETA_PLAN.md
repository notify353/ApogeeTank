# WoW Forever beta compatibility preparation

## Scope and current status

The owner intends to use the Forever beta to develop and test Apogee Tank.
Prepare support alongside Classic Era, preserving Era behavior and appearance.
This document records the implementation sequence; it does not establish
Forever compatibility. No Forever build, interface number, project identifier,
API export, or spell catalog has been verified in this repository yet.

The current startup gate and TOC continue to allow only Era interface 11509.
Keep them intact until the beta has been inspected. Do not guess identifiers,
reuse an Era export as beta evidence, or enable arbitrary out-of-date clients.

## First beta session

1. Locate the installed beta client and record its version, build, interface
   number, project identifier, and export location in `API_REFERENCE.md`.
2. Obtain its matching Blizzard interface export and compare the required
   functions, return fields, event payloads, and UI templates with Era.
3. Record unsupported or changed capabilities before implementing adapters.
   Pay particular attention to unavailable or restricted combat data.
4. Agree on the beta test installation target before creating a junction or
   copying addon files. Existing installations require owner authorization.

## Implementation sequence

- **Client selection:** once identifiers are verified, centralize explicit
  client detection in a narrow Core boundary used by startup and any actual
  client-specific consumers. Keep unknown clients rejected. Update TOC metadata
  using the beta's supported loading mechanism and verified interface value.
- **API boundaries:** compare `Core/UnitAPI.lua`, `Core/Auras.lua`,
  `Core/Cooldowns.lua`, and `Core/Stance.lua`. Adapt only demonstrated differences.
  Check threat, unit identity, health/power, casts/channels, harmful aura ownership,
  cooldown/charge state, GCD classification, and stance/form identity.
- **Feature lifecycle:** verify nameplate, threat, aura, spellcast, cooldown,
  combat, login, zoning, and stance events used by each feature. Preserve
  event-driven sampling and cached countdown rendering.
- **Applied-debuff layout:** keep reserved-slot catalogs owned by `Threat/`.
  If Forever needs different IDs, select a separate verified catalog by client.
  Unknown effects retain the general-slot/overflow behavior. Do not use these
  catalogs to constrain automatic learning or missing-effect detection.
- **Persistence:** retain separate character-owned debuff and cooldown lists,
  with persistent opt-outs and exact spell identities. Verify beta storage
  behavior and character-copy behavior. Do not automatically copy Era saved
  data, merge ranks, or add talent/spec profiles; those are separate decisions.
- **Documentation:** update supported-client claims and the API reference only
  to the level demonstrated by tests and actual beta acceptance checks.

## Validation gates

Run `pwsh ./scripts/test-local.ps1` throughout implementation. Extend the current
Era-only metadata checks and client-gating tests to cover both verified clients
and rejection of unknown builds. Keep Era regression coverage intact.

Add beta-specific fixtures from the verified API contract, covering unavailable
data as well as successful reads. Exercise cooldown initialization, GCD rejection,
charges, held state, candidate expiry, selection changes, and persistent opt-outs.
Check complete player-owned aura coverage independently of visible icon slots.

In each client, test login/reload, combat entry/exit, zoning, multi-enemy pulls,
target/nameplate changes, threat loss/recovery, casts, raid markers, debuff
discovery and coverage, cooldown learning, stance changes, and picker controls.
Check multiple classes and ranks, plus talent changes and lost abilities.
Observe any beta specialization switching before proposing profile behavior.

Record results and remaining limitations per tested build. Mock tests alone do
not establish visual parity, live event ordering, or server threat availability.
Beta patches require rechecking changed contracts. Publishing and releases
remain subject to explicit owner approval.

## Ready now versus deferred

- Ready now: documented scope, ownership, implementation order, and acceptance
  gates; the Era export checker with explicit recording and isolated fixture
  tests; current Era implementation and existing uncommitted work preserved.
- Deferred until beta evidence exists: client identifiers, adapters, catalog
  entries, metadata changes, installation, and any claim of Forever support.
