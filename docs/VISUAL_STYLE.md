# Tank visual style

`UI/Style.lua` owns the palette, icon crop/insets and typography used by the
threat HUD, missing reminders, cooldown view and shared picker. It is local to
Tank; Apogee Keybinds is a read-only design reference, not a runtime dependency.

Combat slots remain 18px with 2px gaps and a 1px inset (16px artwork). This keeps
the ten-enemy layout, four missing reminders, six applied effects and overflow
within their existing footprint. The picker uses 24px slots with 2px insets,
18px header strips, 9px headings and 24px-high action buttons. Enemy rows remain
24px high; severity colors, target indication and fixed HUD anchors are unchanged.

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
