# Apogee Tank

A fixed current-target threat HUD for **WoW Forever** (1.60.x, interface 16001). Classic Era is no longer supported. Tank does not depend on another addon or display player health/resources.

## HUD

- One living hostile current target, including before combat. Unknown threat is neutral. No secondary enemy queue, nameplate scanning, or enemy-effect tracking.
- One stance/form/aura slot left of the meter, six selected cooldown slots plus overflow above it, and learned Paladin seals below target health. Spells remain visible outside combat and with no target; an empty stance slot does not shift cooldowns.
- Enemy health/cast strip and reserved raid-marker space on the right; no mob-name label. The existing Forever scale and meter position are preserved.
- **Left-click skull, right-click X, Shift-left-click moon** on the target meter, in or out of combat. Native secure actions set markers subject to Blizzard permissions. Other modifiers do nothing. Cooldowns and Paladin aura/seal icons support native click-to-cast after out-of-combat configuration. Offensive cooldowns acquire an enemy only when no living hostile target is selected.

Threat compares the player with available party members and pets, not an entire raid. Unreadable identity clears target details; native visibility can retain a neutral marking surface for a living hostile target. Native widgets render restricted health, marker indices and opaque cooldown durations without addon arithmetic on those values.

Offensive cooldown clicks check native `[noharm][dead]` conditions at the click to acquire a target. A living attackable target stays selected through cooldown/range failures; changing enemies is a separate player action. Helpful, dual-use and unclassified spells retain direct spell actions. Aura/seal self-casting and native ground-target reticles are unchanged. Offline tests simulate target predicates because the engine macro parser is not in the interface export; native repeat-click and target-transition acceptance remains pending.

With no target, cooldowns natively classified as hostile-unit spells appear gray. They remain clickable and can acquire an enemy. Self/ground spells and unknown classifications retain their existing availability display; cooldown, range and resource failures still apply.

## Minimap and spell picker

Left-click Tank's minimap button outside combat to open the spell picker. Right-drag repositions the button and saves its angle per character. Its default is 190 degrees, outside the lower-left rim, alongside the family's Keybinds/Heals defaults at 225/260 degrees. The shared placement rule clears the minimap's expanded bounds for round or rectangular shapes, with a minimum radius of 110. Existing dragged angles (including the old 135-degree position) remain intact; defaults are never stored as user choices. Resizing and scale/display changes reposition without idle polling, deferring during combat. Drag release does not open the picker. There are no slash commands, key bindings, profiles, or separate settings menus.

The picker contains a scrollable cooldown checklist, Clear followed by Confirm clear, and an isolated animated preview. Paladins also get a Seals checklist: checked seals appear in the HUD row, unchecked seals are hidden. Seal of the Crusader starts unchecked; other learned seals start checked. Seal schema 2 records explicit checked and unchecked choices by family through reloads, new ranks and spellbook reconciliation. Schema 1 did not retain checked-choice provenance, so previously shown Crusader migrates to unchecked; recheck it once to record a persistent opt-in. Other seal choices are preserved. Hidden seals remain available in the spellbook. Clear affects cooldowns only. The window's draggable position lasts only for the session; scale shrinks when needed to fit. Closing, combat and zoning stop preview/dragging and cancel pending opens and clear confirmation.

The preview uses selected spell artwork or generic samples. It never replaces the live HUD, marks enemies, calls observation APIs, or persists synthetic data.

## Discovery and data

Successful player casts are learned only after a confirmed real cooldown or charge recharge. GCD-only spells, stance/form identities, items and pets are excluded. Known Paladin defaults start checked without first-cast discovery: Holy Strike, Judgement, Hammer of Justice, Consecration, Holy Shield and Hammer of the Righteous, in that managed order. Identifiable custom sequences remain unchanged.

Cooldown schema 3 records explicit checkbox choices, preserving opt-ins and opt-outs through reloads and new ranks. Holy Strike/Judgement entries disabled automatically by the previous default-off policy return to checked; recorded explicit opt-outs stay unchecked. Older schema 1/2 ignored entries are treated as user opt-outs. No private saved data is needed to apply this policy.

Stance/form/aura guidance uses native assigned roles (unassigned defaults to damage); there is no manual role selector, rotation coaching or blessing upkeep. Cached numeric countdowns animate without spell-API polling; idle strips sleep. Native timers preserve restricted countdowns; unknown/held states never claim readiness.

`ApogeeTankCooldownsDB` stores selected/unchecked cooldowns, `ApogeeTankSealsDB` stores seal-family visibility opt-outs, and `ApogeeTankUIDB` stores minimap angle, all per character. The obsolete `ApogeeTankEffectsDB` declaration is retained solely to preserve historical data; no runtime code reads or writes it. Clearing cooldowns does not reset seal choices, minimap position or legacy effects. Unsupported future schemas are preserved: a future cooldown schema disables cooldown tracking/picker access, while a future seal schema disables the seal row/checklist without resetting it.

## Paladin seals and active-state limits

Enabled learned seals appear left-to-right as **Fury, Righteousness, Crusader**, followed by the remaining families in their existing order. Unlearned or unchecked seals consume no slot; Crusader remains unchecked by default. Fury uses the existing Forever family reference (1311649) to resolve the localized name, then the learned spellbook supplies the actual rank/ID. No Fury icon appears before it is learned. Native tooltips retain their full spell text and use the same gold footer as Devotion Aura: **TANK** for Fury, **DPS** for Righteousness/Crusader. These are tooltip footers, not permanent text below the icons.

The seal row shows selected learned choices with native tooltips **only outside combat**. Blizzard's secure visibility driver hides its protected buttons in combat and on death, restoring selected seals afterward; combat reload defers button creation. Ordinary timer overlays also hide in combat, with no combat seal-aura reads. Outside combat, clicks self-cast and visibility choices/assignments may update. There is no seal recommendation or role selector. When public aura access identifies the active seal, it receives a native countdown if shown, and other seals dim even when the active seal is unchecked. Restricted or unavailable access clears those indicators without guessing timers.

All HUD spell and marker icons use 22-unit slots and 2-unit gaps at the existing scale. Held threat and target health use warm ivory. The latest cleanup removes redundant timer updates; live flicker resolution still needs confirmation.

## Verification

Reviewed Forever export: **1.60.1.70009**, project 1, interface 16001. Later builds in the same supported family warn if unreviewed; other families do not start. The export check remains strict.

The refreshed 70009 export passes strict freshness verification and the full local suite, including exported secure-action integration. These tests execute current Blizzard Lua with mocked engine inputs; live taint and visual acceptance remain separate. See [the quality review](docs/QUALITY_SWEEP.md).

```powershell
pwsh ./scripts/test-local.ps1 -ForeverExportPath 'C:/Program Files (x86)/World of Warcraft/_classic_beta_/BlizzardInterfaceCode/Interface/AddOns'
pwsh ./scripts/check-wow-api-export.ps1
```

Native secure-action integration reads the local export without redistributing it. Omitted paths print SKIP; invalid supplied paths fail. [Review and live acceptance](docs/HUD_REDESIGN.md) explains what still needs in-game testing. Requested source changes include checked local DEV installation through the central Apogee Forever builder and installer; never copy this child checkout over PROD. Follow `C:/Dev/WoW/ApogeePartyHealthBars/distribution/DUAL_WORKFLOW.md`, preserving its verified backups, transaction chain, saved data and unrecognized files. Only the central owner updates aggregate source pins; documentation-only changes do not repin or reinstall runtime. Publishing and releases remain separately authorized.
