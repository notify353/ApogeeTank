# Apogee Tank working rules

- This repository is independent. Do not modify Apogee Party Health Bars when
  extracting features; treat that checkout as read-only source material.
- Target Classic Era only until the owner explicitly expands support. Verify
  APIs and events against the current local Era Blizzard interface export.
- Preserve the existing threat HUD appearance unless a visual change is requested.
- Everyone gets the same behavior. Do not add settings, profiles, SavedVariables,
  movable configuration surfaces, or key bindings without an explicit request.
- Authorized exception: `Effects/` owns a small character-specific watch list and
  compact picker opened by Shift-left-click on Apogee Tank's player health bar
  outside combat. No health-bar hover tooltip or slash command. Combat blocks opening,
  closes the picker, and cancels pending opens. Learned effect identities and
  explicit unchecked choices persist.
  Newly observed own effects are auto-checked; an explicit uncheck survives
  reobservation and reload. Clear All erases both lists, with learning resuming on
  subsequent gameplay observations. Keep the picker titleless and footerless,
  with just the checklist, Clear All, and close controls. No predefined
  spell list, profiles, equivalent-effect rules, stack targets, or expiry warnings
  belong in this first missing-effect feature. Discover only player-owned debuffs;
  only the player's own application clears a reminder. Pets and unknown casters
  do not count. Preserve explicitly selected identities when changing this policy.
- Missing effects belong immediately left of each enemy threat meter, with four
  visible icons and overflow. Applied effects remain on the right; raid markers
  sit outside the row on the far left. Use
  the public row snapshot/callback contract and complete owned-aura lists, never
  the truncated visible debuff slots, to determine missing effects. No automatic
  marker assignment is included.
- Keep each feature's logic, display, data, and event lifecycle in its own folder.
  `Threat/` owns the first feature. New features must not reach into its internals.
- `Core/` holds narrow genuinely shared client boundaries, not feature policy.
  Add shared abstractions only when actual consumers need them.
- `ApogeeTank.lua` is the small composition point. Use the private addon table
  passed by WoW; no dependency on Apogee Party Health Bars globals or frames.
- Port only the necessary behavior and tests. Do not import an entire framework
  to satisfy one helper dependency. Keep fixed feature constants with their owner.
- Verify working directory, branch, remote, and uncommitted changes before edits.
  Work on short-lived feature branches and preserve user changes.
- Run `pwsh ./scripts/test-local.ps1` for code changes. Report the remaining
  in-game acceptance checks honestly; mock tests cannot establish visual parity.
- Do not publish, release, or alter existing client installations without the
  owner's authorization. Keep third-party/source license notices intact.

- Authorized picker exception: draggable window with session-only position and
  an animated HUD demo while open outside combat. Synthetic effects never enter
  discovery or persistence; closing, combat, and zoning stop the demo.
