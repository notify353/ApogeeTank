# Apogee Tank

A small independent threat HUD for **WoW Classic Era 1.15.9 (interface 11509)**,
with an experimental **Forever beta 1.60.1.69893 (interface 16001)** candidate.
It uses fixed placement and behavior for everyone. There are no profiles, key
bindings, minimap controls or dependencies on other Apogee addons.

## Combat HUD

- Ten stable enemy rows with directional threat lead/recovery meters, severity
  colors, the original thin baby-blue selected-enemy rail and enemy health or
  cast/channel progress.
- Four missing-effect reminders left of each meter, with overflow. Six applied
  debuff slots on the right retain the original rank-aware class columns, stack
  counts, expiration pulses and overflow. A reserved raid-marker slot separates
  the meter from applied effects; the addon never assigns markers.
- Player health/power remain visible outside combat. The active stance sits
  1px left of that cluster, and up to six watched cooldown icons sit 1px right
  during combat. Icons retain 2px spacing between slots.

The HUD never targets, casts or changes nameplate preferences. Enable enemy
nameplates for broad pack coverage; available target chains, focus and mouseover
provide fallback observation. Threat compares the player with observed party
members and pets, not an entire raid. Lost enemies briefly retain a last-seen
warning; known dead enemies and expired history are removed.

## Debuffs and cooldowns to watch

**Shift-left-click the player health bar outside combat** to open the combined
picker: Debuffs on the left, Cooldowns on the right, each with independent
scrolling. There are compact column headings but no window title or footer.
Hover list entries for native spell tooltips. The normal HUD has no tooltips.

Debuffs are learned when your character applies them to a living hostile target.
New identities are checked automatically. Each visible enemy is then evaluated
independently using its complete player-owned aura list. Another player's or
pet's application does not clear your reminder. Unknown reads produce no missing
claim and are retried on the next coalesced threat refresh; successful empty
reads are cached like other successful snapshots.

Cooldowns are learned after a successful player cast when the client confirms a
real cooldown or charge recharge. Global cooldowns alone do not qualify. There
are no duration guesses or spell catalog. Discovery candidates expire after ten
seconds, so cooldowns that start much later may need another use to be learned.
Stance/form spells are excluded using the client-provided stance bar. Items,
pets and passive procs are not tracked.

Cooldown icons show remaining seconds (rounded up to minutes for long timers),
available charges, or a bright ready state. Unknown/held state is dimmed with a
question mark. Sampling follows events; animation renders cached state.

Uncheck an entry to stop watching it. Reobservation and reload preserve that
choice. Identity is the exact spell ID: ranks and similarly named spells are
not merged, and missing reminders have no stack targets or expiry policy.
The applied-debuff column catalog is separate from this learned selection model.

Each column's **Clear** reveals **Confirm clear**. Confirmation forgets only
that list's learned selections and opt-outs. Cancel or closing the window
abandons the reset. Cleared debuffs resume learning on a later gameplay
observation; cleared cooldowns require later casts. Opening the window alone
does not repopulate either list.

The window can be dragged for the session. While it is open, an animated enemy
demo illustrates threat, markers and effects using selected or sample artwork.
Synthetic data is never learned or saved. Closing, combat or zoning ends the
demo. Combat also blocks the shortcut, closes the picker and cancels pending
opens. There are no slash commands or additional modifier shortcuts.

## Character data and compatibility

Only the debuff and cooldown watch lists persist, in separate character-owned
SavedVariables. Version-1 selections migrate to version 2. If either saved list
comes from a newer addon schema, it is preserved untouched and its feature is
disabled with one explanatory chat message. A newer debuff store also disables
the combined picker, which Effects owns; a healthy cooldown tracker still runs.
A newer cooldown store leaves the debuff picker usable. Install a compatible
addon version to use the preserved data; the addon does not reset it for you.

Classic Era remains supported. The exact verified Forever beta build is enabled
for acceptance testing; other beta builds and unknown clients are rejected.
[Forever beta status](docs/FOREVER_BETA_PLAN.md) records the plan and limitations.
Beta player health/power and enemy health use native display APIs that accept
restricted values. Threat comparisons, casts, raid markers and owned debuffs
require readable data: restricted threat removes the row, restricted auras never
assert a missing effect, and restricted casts/markers are omitted. Cooldowns can
still be learned from public real-cooldown flags when the timer is hidden, but
their numeric display becomes the existing dim question mark. Restricted spell
identities are never learned. The beta uses general applied-debuff slots rather
than the unverified Era class-column catalog.

These are implemented fallback behaviors, not demonstrated full combat parity.
No live Tank beta installation or acceptance test has been performed.
Client-specific evidence and export checking are in the [API reference](docs/API_REFERENCE.md).

## Development and validation

Load the repository as `Interface/AddOns/ApogeeTank` in an authorized Era test
installation. This repository does not create or alter client junctions. After
an approved installation change, `/reload` loads the new code. Avoid enabling
two overlapping Threat Control HUDs when comparing the original design.

With Lua 5.1 and PowerShell available:

```powershell
pwsh ./scripts/test-local.ps1
```

This runs Lua parsing, TOC checks, model/observer/runtime/geometry regressions,
export-checker fixtures and whitespace validation. To check the actual local
client export, also run `pwsh ./scripts/check-wow-api-export.ps1` on that machine.
Mocks do not establish pixel rendering, live event ordering or server threat
availability.

In game, check login/reload in and out of combat, target switching, a multi-enemy
party pull, threat loss/recovery, casts/channels, aura ownership and expiry,
nameplate removal, death, zoning and combat exit. Verify persistent unchecks,
both independent clear confirmations, picker restrictions, demo cleanup, stance
switches, and cooldown learning/countdown/readiness. Use the accepted appearance
in [visual style](docs/VISUAL_STYLE.md) as the layout baseline.

For module ownership, public contracts and adding a small feature, see
[architecture](docs/ARCHITECTURE.md). The [code review and resolution record](docs/CODE_QUALITY_REVIEW.md)
explains the bounded reliability and clarity improvements.

MIT licensed; original copyright and provenance retained in `LICENSE` and the
API reference. Reference addons remain independent.
