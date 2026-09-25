# Forever beta status

## Threat-centered HUD (2026-09-24)

Reviewed local export: **1.60.1.70009**, project 1, interface 16001. Forever is the
only supported runtime; Classic Era code and export target have been removed.

- Player health/power bars have been removed. The fixed stance/form/aura slot and
  six selected cooldowns plus overflow remain visible in and out of combat.
- The living hostile current-target meter retains its previous screen coordinates
  and 2x scale. It retains enemy health/casts, no mob-name label, and a reserved
  raid-marker slot on the right. There are no secondary enemy rows on Forever.
- Left skull, right X, Shift-left moon work through native secure actions in and
  out of combat. The protected target button has only UIParent relationships;
  ordinary display changes do not change protected attributes or geometry.
- Unreadable identity clears observer details. Native visibility retains a neutral
  marking affordance for an eligible hostile target without a fabricated GUID.
  Unknown threat is empty/neutral. Native cooldown/health/marker display paths
  remain guarded; held/unavailable timers remain unknown.
- Enemy debuff discovery/reminders have been removed and saved debuff lists remain
  untouched. The minimap opens a cooldown-only picker outside combat. Its preview
  is isolated inside the picker, contains no secure controls, and never learns.
- Right-drag minimap placement persists in ApogeeTankUIDB. Combat/zoning stop drag,
  close the picker, stop preview, and cancel pending opens/clear confirmations.
- Precombat samples are event-driven; combat retains the existing 0.1-second
  observer cadence. Numeric cooldown animation also works outside combat without
  polling spell APIs. Ready/idle cooldowns sleep.

## Verification and acceptance

See [redesign validation](HUD_REDESIGN.md). Portable tests cover the Forever TOC,
restricted values, target changes, preview isolation, persistence and lifecycle.
Forever exported native marking dispatch is exercised when its matching path
is passed to test-local.ps1. Mock native integration does not prove live taint
safety, font layout, or FPS.

The owner confirmed the earlier native marking/countdown implementation live.
This redesign requires a new approved installation and acceptance pass; those
older confirmations are not acceptance of this geometry or picker.

## Installation and rollback

Requested Tank source changes include checked local DEV installation without a
separate install prompt, exclusively through the central Apogee Forever builder
and installer. Follow
`C:/Dev/WoW/ApogeePartyHealthBars/distribution/DUAL_WORKFLOW.md`.
Never copy a child checkout over PROD or use the one-time retrofit option for
routine development. The central owner alone updates reviewed aggregate pins;
documentation-only Tank commits do not repin or reinstall runtime. Preserve the
central transaction/rollback chain, unrecognized files, character data and
historical backups. Do not operate or restart the game; report the required
reload and live acceptance. Publishing and releases remain separately authorized.
