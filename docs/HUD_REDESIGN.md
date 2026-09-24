> The original redesign below has follow-up changes: 22-unit icons, stance left, clickable cooldowns above, learned seals below, warm ivory health/threat, and no mob name. README.md and CONSOLIDATION.md describe the final scope.

# Threat-centered HUD review

Implemented on `codex/threat-centered-hud`. No client installation or publication is part of this delivery.

## Layout and ownership

The HUD owns fixed stance and cooldown anchors above the original first enemy meter position. There are no player health/power frames. Enemy health and casts remain. Forever is the only supported client. There is one current-target row and no secondary queue or enemy-effect tracking. Unknown threat is neutral.

A separate UIParent secure button shares the fixed meter geometry. Native hostility remapping and visibility select living hostile targets; left, right, and Shift-left set skull, X, and moon respectively. Unsupported modifiers do nothing. Protected setup waits until combat ends after a combat reload. Dynamic presentation never reparents or moves this button.

The spell strip remains visible without a target and outside combat. Empty stance space does not move cooldowns. Numeric countdown animation reads cached state; ready strips sleep. Native restricted countdown rendering remains delegated to Blizzard.

## Picker and persistence

The upper-left minimap button opens the picker outside combat. Right-drag saves its angle in the separate character-specific `ApogeeTankUIDB`. Cooldown choices remain intact; legacy effects data is preserved untouched by retaining only its saved-variable declaration; clearing a list never clears minimap position.

The picker contains its own labeled display-only preview. It cannot mark targets, observe spells, discover effects, or save synthetic data. Closing, combat, and zoning stop it. The picker has one scrolling Cooldowns list. Clear reveals Confirm clear, canceled on closure. Picker position remains session-only; scale shrinks only to fit the screen.

## Reproducible review preview

Run from this checkout with Lua 5.1 available:

```powershell
pwsh ./scripts/preview-hud.ps1 -OutputPath C:/path/to/threat-centered-review.html
```

The output HTML is standalone and opens locally. Its state buttons show Forever picker, combat, and no-target states. Layout snapshots are captured from the actual addon Lua in the test harness. Artwork placeholders, approximate fonts, and simulated native bars are explicit review limitations. The in-game picker preview animates; browser snapshots represent selected moments.

## Local verification

Run the entire suite with the local Forever export:

```powershell
pwsh ./scripts/test-local.ps1 -ForeverExportPath 'C:/Program Files (x86)/World of Warcraft/_classic_beta_/BlizzardInterfaceCode/Interface/AddOns'
pwsh ./scripts/check-wow-api-export.ps1 -Target foreverBeta
```

Reviewed export: Forever 1.60.1.69977. Integration exercises its native raid-target action, including repeated set behavior. Regression tests cover target ownership/identity, neutral precombat threat, fixed anchors, marker guards, deferred secure setup, minimap persistence, picker and preview lifecycle, cooldown states and class stances/forms/auras. Era is explicitly rejected at startup.

Final local verification: the Forever-only suite passes with native export integration enabled, and the installed 1.60.1.69977 export freshness check passes. Browser review uses the simplified Forever-only captures.

## Live acceptance after separate installation approval

Mocks and export checks do not establish live taint safety, native rendering parity, group permission behavior, or coexistence with other addons. Test Forever after separately approved installation:

- Set skull/X/moon before and during combat, repeat each marker, try unsupported modifiers and insufficient group permissions. Test friendly, dead, and missing targets, rapid switches, and reload during combat; inspect taint/errors.
- Check health/cast updates and stale identity removal. Exercise unreadable target data and neutral native visibility.
- Open the minimap picker with no target, drag and reload, verify scrolling/clear confirmation and immediate spell selection updates. Interrupt pending opens, dragging, preview and clear confirmations with combat and zoning; nothing should reopen automatically.
- Test Warrior stance, Druid form, Paladin aura and no active stance/form; compare six-plus cooldowns, charges, held/unknown states and countdown completion in/out of combat.
- Enable the separate health addon alongside Tank. Confirm no duplicate player bars, usable screen fit at the Forever scale, minimap button separation and click/drag behavior. Reposition Tank's minimap button if another addon occupies its default quadrant.

Several test builds were installed with explicit owner authorization. This local consolidation performs no installation or publication. See CONSOLIDATION.md for the current handoff and remaining live checks.
