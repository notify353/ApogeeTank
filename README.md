# Apogee Tank

A standalone, fixed multi-enemy threat HUD for **WoW Classic Era 1.15.9 (11509)**.
Extracted from Apogee Party Health Bars with the existing appearance and threat
behavior preserved. No dependency on that addon, profiles, key bindings, or
minimap button. The only configurable feature is a small character-owned
observed-effect watch list.

## Included

- Ten stable enemy rows, directional threat lead/recovery meters, original
  severity colors, current-target highlight, and existing raid-marker display.
- Enemy health strips, cast/channel progress, and protected-cast coloring.
- Six player-applied debuff slots per enemy, rank-aware class columns, stack
  counts, expiration pulses, and debuff overflow.
- Compact player health and active power above the threat meters.
- Lost-enemy promotion, enemy overflow, and short last-seen retention.

Everyone gets the same placement, scale, thresholds, and update cadence. The
player strip stays visible outside combat; enemy rows appear during combat.
The HUD is passive: it never targets, casts, assigns markers, changes bindings,
or changes nameplate preferences. Enable enemy nameplates in WoW for broad pack
coverage. Without them, observation is limited to available target chains,
focus, and mouseover. It measures the player's threat against observed party
members and pets; it is not a raid-wide threat meter.

## Effects to watch

1. Apply a debuff to a living enemy you are targeting. Only effects applied by
   your character are discovered and automatically checked for watching;
   other players' and pets' effects are ignored.
2. Out of combat, **Shift-left-click Apogee Tank's player health bar** to open
   the compact checklist. Uncheck an effect to stop
   watching it, or check it again to resume. There are no titles, instructions,
   counters, or footer in the window.
3. Each displayed living enemy gets its own missing-effect icons immediately
   left of its threat meter. Once your own application is present, the missing icon
   disappears and the existing applied-debuff display shows it on the right.
   Another player's application does not clear the reminder, even with the same
   effect ID. The player health/power strip no longer has missing-effect icons.

Missing effects are evaluated separately for every visible enemy, including
off-target enemies. Four icons fit beside each meter; a `+N` tooltip lists
additional missing effects without overlapping adjacent rows. The complete
owned-aura snapshot determines coverage, including effects beyond the right
lane's visible slots. No reminders remain for stale/dead/unavailable enemies
or after their rows disappear on combat exit.

Raid-marker **display** sits outside each row on the far left. Missing effects
occupy the gap between the enemy name and threat meter. Automatic marking and Dungeon Guide marker assignment were
not extracted; Apogee Tank never sets or clears raid markers.

Learned effect identities (ID, name, icon) and unchecked choices survive reloads,
separately for each character. Applying an unchecked effect again leaves it off.
Existing selections from the earlier manual-selection version are preserved.
The list remains available without a target. There is no watch-list selection
limit; each row uses visible overflow for long reminder lists. Escape or the
close button dismisses the picker.
Combat blocks opening and automatically closes the picker. Normal clicks and
other button/modifier combinations do nothing. A queued opening is cancelled
when combat begins and is not reopened afterward. There is no slash command.

**Clear All** forgets this character's watched effects and unchecked choices,
immediately empties the list and reminders, and resets its scroll position.
Learning resumes with the next target/aura observation during gameplay;
simply opening or closing the cleared window does not repopulate it.

This feature contains no predefined spell catalog, spell-to-debuff mapping,
rank equivalence, stack target, expiration warning, immunity prediction, or
cast recommendation. It checks exact effect presence only. A new rank or a
different effect with the same name is learned separately when observed; uncheck
older ranks if you no longer want reminders for them. Hover an entry to inspect
its effect ID. Unknown aura state produces no missing claim.
The original per-enemy threat HUD debuff columns retain their separate fixed
catalog and player-owned display policy.

Ability cooldown lanes, party frames, actions, dungeon guides, and broader
maintained-effect suggestions remain outside this scope.

## Development installation

The Classic Era AddOns junction points at this checkout. Reload after code
changes. Apogee Party Health Bars is unchanged; if its Threat Control is also
enabled, the two HUDs occupy the same position. Disable its Threat Control
manually when testing this standalone version.

The previously created Anniversary junction remains, but Anniversary is not
supported: the TOC declares only Era, and the runtime refuses other clients
even when loading out-of-date addons. No future WoW client support is claimed.

## Validate

With Lua 5.1 and PowerShell installed, run:

```powershell
pwsh ./scripts/test-local.ps1
```

The tests check observer behavior, presentation calculations, standalone TOC
loading, events, aura ownership, combat transitions, client gating, observed
effect discovery, watch-list persistence, selection UI, and missing reminders. They
cannot prove actual in-game rendering or server threat availability.

In Classic Era, check solo login, a multi-enemy party pull, threat loss/recovery,
target switching, enemy casts/channels, debuff stacks/expiration, death,
nameplate toggles, combat exit, zoning, and reload during combat. Compare the
HUD appearance with the original using one enabled HUD at a time.
For the watch list, apply a debuff and confirm automatic selection, then switch
to an enemy missing it. Confirm another player's application does not clear the
reminder. Uncheck it, reload, and apply it again to verify it stays off. Use
Clear All to erase the choices, then verify learning starts fresh. Confirm no
reminder on dead/friendly targets. Test two enemies with different coverage,
an off-target aura update, row removal/reuse, and an existing raid marker.
Check Shift-left-click outside combat; the health bar has no hover tooltip. Verify
ordinary clicks do nothing, combat closes the picker, combat clicks cannot open
it, and combat exit restores the shortcut without reopening the window.

## Ownership

- `Core/UnitAPI.lua`: the narrow unit/casting/power compatibility boundary and colors.
- `Core/Auras.lua`: shared harmful-aura read boundary; unavailable is distinct from empty.
- `Threat/DebuffData.lua`: fixed class-specific debuff columns.
- `Threat/Observer.lua`: enemy observation and threat snapshots.
- `Threat/Hud.lua`: the original presentation, stripped of settings and demos.
- `Threat/Runtime.lua`: threat events, aura ownership, and one update driver.
- `Effects/Model.lua`: session discoveries, character watch list, and exact presence rules.
- `Effects/View.lua`: fixed picker window and passive missing-effect icons.
- `Effects/Runtime.lua`: effect feature events, persistence, and combat-gated picker access;
  per-enemy coverage via the HUD's public row snapshots.
- `ApogeeTank.lua`: Era gate and composition through the HUD's public row contract.

Source provenance and authoritative API references are in `docs/API_REFERENCE.md`.
MIT licensed; original copyright retained in `LICENSE`.

Opening the checklist also shows an animated, labeled demo of enemy threat,
markers, and missing/applied effects. Drag the window background to move it
aside; its position is session-only. Watched effects supply the demo icons,
or labeled sample icons appear when the list is empty. Demo data is never
learned or saved. Closing the window or entering combat removes the demo.
