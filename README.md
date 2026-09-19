# Apogee Tank

## Runtime compatibility policy

Routine build-number changes within Classic Era 1.15.x (project 2, interface
11509) or Forever beta 1.60.x (project 1, interface 16001) do not disable this
addon. Required capabilities still gate startup. An unreviewed build produces
one warning per session; it is not a claim of tested compatibility. Other
families/interfaces stay unsupported. Existing restricted-value and protected
operation guards remain in force. Optional features keep their own safe
unavailable/fallback paths.

Development export verification remains strict and separate: a changed installed
build needs a fresh matching export and contract review. Runtime tolerance does
not relax export provenance or establish live acceptance. Reviewed beta export:
1.60.1.69913; fresh on 2026-09-17.


A small independent threat HUD for **WoW Classic Era 1.15.9 (interface 11509)**,
with experimental **Forever beta 1.60.1.69913 (interface 16001)** support.
It uses fixed placement and behavior for everyone. There are no profiles, key
bindings, minimap controls or dependencies on other Apogee addons.

## Classic Era combat HUD

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

The two-column picker and debuff/demo behavior below apply to Classic Era.
Forever uses the cooldown-only behavior described in the next section.

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

## Forever beta HUD

Forever shows only the living hostile current target, including before combat,
below player health/power at fixed 2x scale. Names are centered beneath the enemy
meter and health strip; raid markers sit to its left. Enemy rails, debuffs,
reminders and the picker demo are disabled. Existing
debuff selections remain untouched. Shift-left-click on player health opens a
compact cooldown-only picker outside combat. Newly learned cooldowns appear
while it is open; combat closes it and cancels pending opens.

Click the enemy meter to set **skull (left), X (right), or moon (Shift-left)**.
Native secure actions enforce target eligibility and group marking permissions.
Unavailable threat leaves a neutral empty meter. Unreadable identity removes the
observer row, while the native marking button retains a visible neutral meter
for an eligible target. No threat value or identity is guessed.

Native display APIs handle restricted health, power, raid markers and cooldown
durations. Held cooldowns stay dimmed with a question mark; unavailable native
timers also remain unknown. Restricted spell identities are never learned and
unreadable casts are omitted. Precombat sampling follows events; combat keeps
the threat refresh cadence. Era behavior remains separate.

The owner has confirmed native countdowns, markers and secure marking live.
The latest fixes still need live layering, hold/resume, picker discovery and
grouped-threat checks. See [Forever status](docs/FOREVER_BETA_PLAN.md) and the
[API reference](docs/API_REFERENCE.md) for exact coverage and limitations.

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
