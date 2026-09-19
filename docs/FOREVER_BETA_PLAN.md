# WoW Forever beta status

## Current behavior (2026-09-19)

Classic Era remains supported with its multi-enemy HUD, applied and missing
player-owned debuffs, two-column picker and synthetic demo. Forever has a
separate, deliberately narrower presentation:

- Only the living hostile current target is observed, including before combat.
  Target changes clear history immediately. Missing threat leaves a neutral,
  empty meter, never fabricated threat or a retained prior enemy.
- Missing/restricted identity suppresses the observer row. The independent
  secure marking button still displays its neutral meter whenever Blizzard's
  living-hostile-target visibility condition is true. This remains a visible
  marking affordance without inventing a GUID or threat value.
- Left-click sets skull, right-click sets X, Shift-left-click sets moon on the
  current target. Other modifier combinations have no action. The native secure
  action button uses set mode, not toggle; Blizzard enforces group permissions.
  No direct addon SetRaidTarget, custom snippet or secure wrapper is used.
- The target row sits below player health/power, at local y=-24. HUD and picker
  roots use fixed 2x scale; the player top anchor stays 55 UIParent units above
  center. Cooldown/stance slots are 36 UIParent units. Names are centered beneath
  the enemy meter and health strip; the reserved raid-marker slot sits to
  the left. Both severity and selected-target rails are absent.
- Native sinks display restricted health, power, raid-marker indices and
  cooldown duration objects. Secrets never enter arithmetic, identity storage
  or persistence. Unreadable casts are omitted. Native display failure clears
  stale presentation. Held cooldowns remain dimmed with a question mark.
- Enemy debuff discovery, icons, reminders and demo are disabled. Existing debuff
  SavedVariables remain untouched. Shift-left-click on player health opens the
  cooldown-only picker outside combat. Learning updates an open picker through
  a revision-change callback. Opt-outs persist; Clear/Confirm clear affects only
  cooldowns. Closing cancels confirmation; combat closes and blocks the picker.
- Precombat sampling is event-driven and coalesced; animation ticks use cached
  data. Combat retains 0.1-second sampling for threat freshness. Unchanged enemy
  names and footer text are not rewritten.

## Verified client boundaries

Reviewed baselines: Era 1.15.9.69722, project 2/interface 11509; Forever
1.60.1.69913, project 1/interface 16001. Core/Client.lua accepts the corresponding
1.15.x and 1.60.x families with startup capabilities present. A different build
number produces one warning per session. Other families/interfaces stay disabled.
Export verification remains strict even though runtime build matching is tolerant.
See [API reference](API_REFERENCE.md) for source contracts and historical findings.

The Forever export confirms conditional restrictions on UnitGUID and threat.
Current-target selection does not bypass those restrictions. Native status bars,
texture sprite cells and duration objects provide display-only paths. Native
harmbutton remapping and raidtarget actions avoid the beta's missing restricted
snippet compiler. Setup is deferred until PLAYER_REGEN_ENABLED on combat reload.
The secure button has only UIParent parent/anchor relationships; dynamic HUD
updates never resize, hide or alter its protected attributes during combat.

## Validation and remaining live checks

The local suite covers both client lifecycles, target switching/clearing,
restricted identity/threat/timers/markers, held timers, open-picker discovery,
saved opt-outs, combat closure, geometry, secure attributes and deferred setup.
Ten unchanged precombat ticks now produce zero threat calls, snapshot rebuilds
or text writes; 100 threat events coalesce into one refresh. These are mock call
counts, not real-client CPU, allocation-byte or FPS measurements.

Portable tests run with `pwsh ./scripts/test-local.ps1`. To additionally execute
the matching client's native secure resolver/action and missing-compiler check:

```powershell
pwsh ./scripts/test-local.ps1 -ForeverExportPath 'C:/Program Files (x86)/World of Warcraft/_classic_beta_/BlizzardInterfaceCode/Interface/AddOns'
pwsh ./scripts/check-wow-api-export.ps1 -Target foreverBeta
pwsh ./scripts/check-wow-api-export.ps1
```

The integration input is also available as APOGEE_FOREVER_EXPORT. Omission prints
an explicit SKIP; an invalid supplied export fails. Client source is not copied
into this repository. No mock can establish Blizzard's taint or secret engine.

The owner confirmed native countdowns, native markers and snippet-free marking
live before this review. After these fixes, reload outside combat and verify
meter layering/clicks with readable and restricted targets, all three marking
gestures in combat, cooldown hold/resume and discovery while the picker is open.
Verify threat freshness on grouped pulls, casts, zoning and target recovery;
repeat Era visual acceptance. Class/rank/talent coverage and actual CPU/FPS
profiling remain in-game work. No game reload is performed by local tests.

## Durable installation and rollback

The beta junction at
C:/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns/ApogeeTank
points to C:/Dev/WoW/ApogeeTank-ForeverBeta. Preserve that durable worktree and the
independent Era checkout at C:/Dev/WoW/ApogeeTank. Other client installations and
character SavedVariables are not modified by this work.

External backups under C:/Dev/WoW/ApogeeTank-Backups include the original
2026-09-17-beta-closeout Git bundle, source ZIP, checksums and rollback directions,
plus a complete source copy and working patch taken before the 2026-09-19 review
fixes. Use a new stable checkout for rollback; never recursively delete a junction
target or overwrite unexpected files. Git revert provides a reviewable source
rollback after integration. No release or tag is part of this update.
