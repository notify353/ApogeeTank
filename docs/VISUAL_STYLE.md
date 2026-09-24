# Current Tank visual style

Forever only. All live stance/aura, cooldown, seal and raid-marker icons use 22-unit squares, matching the 16-unit threat bar plus 1-unit gap and 5-unit target-health strip. Gaps are 2 units. Stance/aura sits left, marker right, both centered on the full stack. Cooldowns align with the threat bar left edge above; seals align below target health. No player bars or mob-name label remain.

Held threat and target health use warm ivory (0.91, 0.89, 0.84); warning colors remain distinct and unknown threat is neutral. Paladin aura uses a shield with amber pulse only for a confirmed missing aura. Cooldowns desaturate while cooling down or unusable. Seal active-state styling is conditional on readable aura data; unknown state is neutral. Native spell tooltips accompany clickable spells.

The minimap opens the cooldown picker with its isolated preview. All live appearance and taint acceptance remain in-game checks. The historical notes below record superseded iterations and are not current layout requirements.

---

> Current scope (2026-09-24): Forever only. Era, multi-enemy queues and enemy-effect tracking have been removed. Historical findings below are retained as records; current behavior is documented in README.md, ARCHITECTURE.md and HUD_REDESIGN.md.

# Tank visual style

`UI/Style.lua` owns the palette, icon crop/insets and typography used by the
threat HUD, missing reminders, cooldown view, stance icon and shared picker. It is local to
Tank; Apogee Keybinds is a read-only design reference, not a runtime dependency.

Combat slots remain 18px with 2px gaps and a 1px inset (16px artwork). This keeps
the ten-enemy layout, four missing reminders, six applied effects and overflow
within their existing footprint. The picker uses 24px slots with 2px insets,
18px header strips, 9px headings and 24px-high action buttons. Enemy rows remain
24px high; severity colors, target indication and fixed HUD anchors are unchanged.

The final selected-enemy treatment is the original 3px-wide, full-row-height
baby-blue rail at 95% opacity, with a deliberate 4px gap from the meter. Enemy
names remain over the world with no full-row background. Stance and cooldown
slots are 18px and sit 1px from the left and right of the player-status cluster;
cooldowns retain 2px gaps between slots. These accepted dimensions are retained
through the code-quality cleanup; rejected perimeter and end-cap experiments
are not part of the current rendering code.

Local validation: `pwsh ./scripts/test-local.ps1` exercises the TOC, mock UI,
selection persistence, combat restrictions, independent clear confirmations,
demo lifecycle and cooldown rendering. The local Era export checker passes for
build 1.15.9.69722 / interface 11509. Font sizing uses the exported UI's existing
GetFont/SetFont pattern; this pass adds no gameplay API or event dependencies.

In-game acceptance remains required:

- Inspect ten enemies over light and dark scenery at the player's UI scale:
  names, stack counts, cooldown times and both overflow labels must stay readable.
- Check the reserved raid-marker space, four missing icons and six applied icons
  alongside threat, target, health and cast indicators.
- Open the side-by-side picker with Shift-left-click outside combat; inspect
  long names, scrolling, header/close spacing and both clear confirmations.
- Drag the picker and inspect the animated demo; close it and enter combat or
  zone to confirm the existing dismissal behavior visually.

Mock checks do not establish live appearance or visual parity with Keybinds.

## Selected-enemy rail correction

The reported screenshot came from the client junction targeting the source
checkout at `6d2b260`, before this styling branch was installed. The migrated
rail was anchored inside the meters. Although tagged OVERLAY, it belonged to
the parent row and was covered by the child meter frames, leaving blue fragments
visible in the gaps. The original Party Health Bars HUD at `2b3bd7e` placed the
rail at the outer row edge. Its current checkout has removed that module, so
comparison used read-only Git history.

Restore that outer edge and place the raid marker 2px beyond it. Applied icons
follow the marker, shifting that accessory lane 7px right while the meters,
missing reminders and HUD anchor remain fixed. Mock regression checks establish
non-overlapping bounds and selection clearing/restoration; the previous rail
placement fails the new geometry assertion. In game, verify a continuous blue
rail beside both bars when targeting, including marked enemies and active casts.

Held threat uses soft ivory (RGB 0.91, 0.89, 0.84) in both the live meter and picker preview. Unknown threat remains neutral gray, and warning/lost-threat colors remain distinct. Target health uses the same warm ivory in both native and ordinary rendering, including the picker preview.

The target meter has no mob-name label in either the live HUD or picker preview. Threat, target health/cast information and marker placement remain fixed.

Stance/form/aura, cooldown and raid-marker icons share the 22-unit icon size, matching the 16-unit threat bar, 1-unit gap and 5-unit target-health strip. Stance and marker are vertically centered on that full stack with matching 2-unit gaps on its left and right. The protected aura hit area follows the same size and center; warning borders stay inside the tile.

Live cooldown icons show the native spell tooltip on hover, using the exact displayed spell identity. Leaving, hiding or rebinding the icon clears only its own tooltip. Picker previews remain non-interactive.

Cooldown artwork desaturates while a confirmed cooldown is running, with no amber border or pulse. Ready spells and spells with an available charge retain color.

Live cooldown icons support left-click native spell casting, including combat, using the current target. Visible slots and protected spell assignments stay fixed for the fight; new discoveries appear after combat. Synthetic previews remain non-interactive.

Native spell usability and range also desaturate cooldown artwork when the client reports the spell cannot be used. Usability, target and native range events refresh this state; animation ticks do not poll spell APIs. Unavailable range data is not treated as out of range.
