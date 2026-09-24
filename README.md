# Apogee Tank

A fixed current-target threat HUD for **WoW Forever** (1.60.x, interface 16001). Classic Era is no longer supported. Tank does not depend on another addon or display player health/resources.

## HUD

- One living hostile current target, including before combat. Unknown threat is neutral. No secondary enemy queue, nameplate scanning, or enemy-effect tracking.
- One stance/form/aura slot left of the meter, six selected cooldown slots plus overflow above it, and learned Paladin seals below target health. Spells remain visible outside combat and with no target; an empty stance slot does not shift cooldowns.
- Enemy health/cast strip and reserved raid-marker space on the right; no mob-name label. The existing Forever scale and meter position are preserved.
- **Left-click skull, right-click X, Shift-left-click moon** on the target meter, in or out of combat. Native secure actions set markers subject to Blizzard permissions. Other modifiers do nothing. Cooldowns and Paladin aura/seal icons support native click-to-cast after out-of-combat configuration. Offensive cooldowns acquire an enemy only when no living hostile target is selected.

Threat compares the player with available party members and pets, not an entire raid. Unreadable identity clears target details; native visibility can retain a neutral marking surface for a living hostile target. Native widgets render restricted health, marker indices and opaque cooldown durations without addon arithmetic on those values.

## Minimap and cooldown picker

Left-click Tank's minimap button outside combat to open the cooldown picker. Right-drag repositions the button and saves its angle per character; the default is upper-left. There are no slash commands, key bindings, profiles, or settings menus.

The picker contains a scrollable cooldown checklist, Clear followed by Confirm clear, and an isolated animated preview. Unchecking persists across reobservation/reload. The window's draggable position lasts only for the session; scale shrinks when needed to fit. Closing, combat and zoning stop preview/dragging and cancel pending opens and clear confirmation.

The preview uses selected spell artwork or generic samples. It never replaces the live HUD, marks enemies, calls observation APIs, or persists synthetic data.

## Discovery and data

Successful player casts are learned only after a confirmed real cooldown or charge recharge. GCD-only spells, stance/form identities, items and pets are excluded. Known Paladin Holy Strike, Hammer of Justice, Judgement, Consecration, Holy Shield and Hammer of the Righteous are explicit defaults, respecting opt-outs. Stance/form/aura guidance uses native assigned roles (unassigned defaults to damage); there is no manual role selector, rotation coaching or blessing upkeep. Cached numeric countdowns animate without spell-API polling; idle strips sleep. Native timers preserve restricted countdowns; unknown/held states never claim readiness.

`ApogeeTankCooldownsDB` stores selected/unchecked spells and `ApogeeTankUIDB` stores minimap angle. The obsolete `ApogeeTankEffectsDB` declaration is retained solely to preserve historical data; no runtime code reads or writes it. Clearing cooldowns does not reset minimap position or legacy effects. Unsupported future cooldown schemas are preserved and tracking/picker access stays disabled rather than resetting them.

## Paladin seals and active-state limits

The seal row shows learned choices with native tooltips. Clicks self-cast in and out of combat; spell assignments update only outside combat. There is no seal recommendation or role selector. When public aura access identifies the active seal, it receives a native countdown and other seals dim. Restricted or unavailable access clears those indicators without guessing timers. The owner reported that combat detection did not work in the live test; neutral clickable icons are the fallback.

All HUD spell and marker icons use 22-unit slots and 2-unit gaps at the existing scale. Held threat and target health use warm ivory. The latest cleanup removes redundant timer updates; live flicker resolution still needs confirmation.

## Verification

Reviewed Forever export: **1.60.1.70009**, project 1, interface 16001. Later builds in the same supported family warn if unreviewed; other families do not start. The export check remains strict.

The refreshed 70009 export passes strict freshness verification and the full local suite, including exported secure-action integration. These tests execute current Blizzard Lua with mocked engine inputs; live taint and visual acceptance remain separate. See [the quality review](docs/QUALITY_SWEEP.md).

```powershell
pwsh ./scripts/test-local.ps1 -ForeverExportPath 'C:/Program Files (x86)/World of Warcraft/_classic_beta_/BlizzardInterfaceCode/Interface/AddOns'
pwsh ./scripts/check-wow-api-export.ps1
```

Native secure-action integration reads the local export without redistributing it. Omitted paths print SKIP; invalid supplied paths fail. [Review and live acceptance](docs/HUD_REDESIGN.md) explains what still needs in-game testing. Requested addon changes include local Forever installation after checks, with a verified backup and preservation of saved data and unrecognized files. Publishing and releases remain separately authorized.
