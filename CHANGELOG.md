# Changelog

## Unreleased — Forever only

- Default Seal of the Crusader to unchecked while keeping its checkbox available; seal schema 2 preserves explicit family opt-ins and opt-outs through ranks and reloads.
- Hide the complete seal strip during combat through native secure visibility; restore selected seals outside combat and suppress combat timer overlays/aura reads.
- Gray verified hostile-target cooldowns when no target exists, retaining click-to-acquire and existing cooldown/range/resource visuals without dimming self/ground spells by range guesses.
- Default Holy Strike and Judgement to unchecked while keeping them available in the cooldown picker; migrate recognizable old automatic selections and record explicit choices for reload/rank persistence.
- Check offensive target acquisition at each click with native `[noharm][dead]`, retaining living attackable targets during rapid repeats and failed casts; preserve direct actions for dual-use, helpful or unclassified spells.
- Order known Paladin defaults Holy Strike, Judgement, then Hammer of Justice, including later learning and recognized saved default sequences; preserve opt-outs, identifiable custom orders and non-default slots.
- Add a Paladin Seals checklist beside cooldowns, with per-character family visibility opt-outs that survive ranks and reloads; keep native casting on shown seals, combat/zoning guards, and cooldown Clear independent.
- Limit cooldown range notifications to the affected spell and skip unchanged seal-artwork writes, preserving synchronous updates and guarded aura reads.
- Review refreshed Forever 1.60.1.70009 contracts and native secure integration; update the reviewed build and export provenance.
- Honor event-scoped GCD classification and latest-rank cooldown selections; recover failed seal timers, clear unknown seal eligibility, and clear guidance on death.
- Standardize author metadata and current Forever API guidance; preserve historical diagnostic records and source attribution.
- Use a threat-centered HUD without player bars or mob names, with warm ivory threat/health and consistent 22-unit icons.
- Add independent native spell actions, offensive target acquisition, Paladin known-spell defaults and learned seal choices.
- Add guarded seal activity/countdown presentation; combat aura readability remains limited.
- Reduce cooldown/stance/seal update churn and preserve native restricted timer boundaries.
- Record local consolidation and outstanding live acceptance in docs/CONSOLIDATION.md.

- Remove Classic Era support, multi-enemy observation/queue and enemy-effect code.
- Move cooldown-only configuration into Picker/ and preserve legacy effect data untouched.
- Keep the threat-centered Forever HUD, native secure marking, cooldowns and minimap access.


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
