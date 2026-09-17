# Changelog

## Unreleased

- Recover unavailable aura reads on the next coalesced refresh while caching
  successful empty results. Preserve future-version character lists without
  rewriting them; disable affected tracking with one explanatory message.
- Keep missing-effect policy in Effects, shared selection persistence in Core,
  use named picker dependencies, and remove unused refresh/color entry points.
- Rewrite usage and architecture documentation around the current independent
  addon, its public contracts and accepted visual layout.

- Place Debuffs on the left and Cooldowns on the right in settings.

- Coalesce player-bar updates with the HUD refresh, sleep the threat update
  driver while idle, and avoid aura discovery scans on target health changes.

- Display the active stance icon left of the player health/power strip.

- Reuse cooldown reads within an event and avoid resending unchanged icon,
  countdown-text, and opacity values during display updates.

- Hide cooldown icons and overflow outside combat while keeping the player bars visible.

- Remove normal HUD reminder and overflow tooltips; keep spell tooltips in settings only.

- Show native spell tooltips over picker icons and names without extra addon text.

- Replace the picker toggle with side-by-side cooldown/debuff columns and
  separate, confirmed clear controls below each list.

- Center cooldown icons on the full player health/power strip and equalize raid
  marker gaps against the visible enemy bar edge.

- Exclude stance-bar spells from cooldown learning and remove already learned
  stances using the client-provided spell identities.

- Add learned player cooldowns, independent persisted selections, a picker list
  switch, and event-driven timers beside the player health bar.

- Show a repeating cast on the first demo enemy.

- Reserve the position immediately right of enemy bars for raid markers,
  before the applied debuffs with matching compact gaps; missing reminders stay on the left.

- Skip unchanged checklist rebuilds during HUD updates; normalize source line
  endings and include staged changes in local whitespace validation.

- Increase the enemy HUD from five to ten visible rows, retaining stable slots,
  lost-threat promotion, and overflow.

- Remove the player-health-bar shortcut tooltip; keep Shift-left-click access.

- Use tanking spell artwork instead of question marks for empty-watch-list demos,
  without adding sample spells to learned effects.

- Make the picker draggable and show an isolated animated HUD demo while open.

- Move missing-effect reminders beside each enemy threat meter, with four icons
  and overflow; move raid markers to the outer left edge.

- Extract the fixed multi-enemy threat HUD into a standalone Classic Era addon.
- Add `/atank` to select observed target debuffs for a character-specific watch
  list. Show passive icons when selected exact effects are missing from the
  current living hostile target. Discovery and coverage accept only the player's
  own debuffs; other players, pets, and unknown casters do not count.
- Auto-check newly observed own effects and preserve explicit unchecked choices
  across observations and reloads. Remove the watch-list title, explanations,
  count, and footer; retain the compact central checklist.
- Add Clear All to forget learned effects and unchecked choices for this
  character, clear reminders immediately, and resume learning on new gameplay
  observations. Opening the cleared window alone does not relearn effects.
- Move missing-effect reminders from the player strip to each enemy row's outer
  left edge. Keep applied debuffs on the right and existing raid-marker display
  untouched. Use complete per-enemy aura snapshots, independent coverage, and a
  six-icon lane with overflow; clear reminders when rows disappear or are reused.
- Replace `/atank` with Shift-left-click on the player health bar outside combat,
  with a short hover hint. Combat disables the gesture, closes the picker,
  cancels pending opens, and prevents late checkbox/Clear All callbacks.
