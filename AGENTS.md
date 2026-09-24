# Apogee Tank working rules

- Support **WoW Forever only**, currently project 1, version family 1.60.x and interface 16001. Classic Era support was explicitly removed by the owner. Verify APIs/events against the local Forever Blizzard interface export; see `docs/FOREVER_BETA_PLAN.md`.
- This repository is independent. Other Apogee addons are read-only reference material, never dependencies or edit targets.
- Preserve the existing Forever HUD scale and meter screen position unless a visual change is requested. No player health/power bars. One current-target meter retains enemy health/casts and a reserved marker slot, with no mob-name label; there are no secondary enemies or enemy-effect lanes.
- Keep the stance/form/aura slot immediately left of the threat meter, opposite the raid marker. Keep six cooldown slots with overflow above the meter, including outside combat and with no target. Stance movement must not shift cooldowns or preparation reminders.
- Marking is user-driven through native secure actions: left skull, right X, Shift-left moon, in/out of combat. Literal target, native hostility remapping/visibility, set mode, no restricted snippets or direct addon marking calls. Protected geometry is independent of ordinary HUD updates; defer setup on combat reload.
- Keep each feature's logic/display/lifecycle in its own folder. Core holds narrow API/data boundaries, not feature policy. Use the private addon table and a small `ApogeeTank.lua` composition point.
- Everyone gets the same behavior. Do not add settings, profiles, key bindings, SavedVariables, or movable surfaces beyond the authorized exceptions below.
- Cooldowns learn successful player casts with confirmed real cooldowns/charge recharge, no catalog or guessed duration threshold. No item/pet cooldown tracking or rotation advice. APIs live in Core/Cooldowns.lua; selection data in Core/ObservedSpellList.lua; display/lifecycle in Cooldowns/.
- Picker/ owns the cooldown-only checklist and guarded toggle interface. Left-click the minimap button outside combat opens it. Clear reveals Confirm clear; closure cancels confirmation. Preserve opt-outs and future schemas. No health-bar gesture or slash command.
- Authorized picker exception: session-only draggable position, screen-fit scaling and an isolated labeled animated preview inside the window. Synthetic data never reaches observation, persistence, live HUD or secure controls. Closing, combat and zoning stop preview and cancel pending opens.
- Authorized minimap exception: Tank logo with round Blizzard styling, right-drag angle persisted per character in ApogeeTankUIDB. Combat/zoning block access and stop drag. Clearing cooldowns never resets minimap angle.
- Preserve historical ApogeeTankEffectsDB only through its TOC declaration; do not read, migrate, clear or write it. Enemy-effect code is removed.
- Verify working directory, branch, remote and uncommitted changes before edits. Use short-lived feature branches, preserve user changes and keep modifications scoped.
- Run `pwsh ./scripts/test-local.ps1` for code changes, supplying the Forever export for native integration. Report remaining live checks honestly; mocks cannot establish native visual parity or taint safety.
- Do not install, publish, release or alter client installations without the owner's authorization. Keep source/third-party license notices intact.

- Authorized stance-equivalent guidance: Guidance/ owns Paladin aura, Warrior stance and Druid form reminders only. No seal, blessing, shout, Mark/Gift or Righteous Fury upkeep advice belongs in Tank. Native assigned roles drive policy; explicit NONE defaults to damage. Unreadable roles or auras remain unknown. No manual role settings, casting, cancellation, saved catalogs or combat spellbook polling.

- Authorized Paladin aura action: left-click a verified inactive aura shield to cast its learned spell through the native non-toggling aura macro action, including in combat after out-of-combat configuration. Its protected UIParent geometry is fixed and separate from live frames. No role toggle or automatic casting.

- Authorized Paladin cooldown defaults: known Holy Strike, Hammer of Justice, Judgement, Consecration, Holy Shield and Hammer of the Righteous appear without first-cast discovery. Native APIs still supply actual timers; persistent opt-outs remain respected, including across ranks. Cooldown strip starts at the threat bar left edge.

- Authorized cooldown click casting: six visible live cooldown slots use native secure actions. Offensive spells acquire an enemy through native target-and-cast macros only when the current target is absent, friendly or dead; helpful and unclassified spells retain direct spell actions. Configure only outside combat and keep both displayed and protected spell identities fixed during combat. No automatic casts; no clickable synthetic previews. Combat reload defers creation until combat ends.

- Authorized seal choice row: Seals/ owns all learned Paladin seal families below the threat/health stack, left-aligned with cooldowns at the same icon size/gap. Native tooltips and secure self-cast buttons work in combat after OOC setup. This is a neutral choice row, not seal recommendations, role selection, missing-buff coaching or guessed timers. No persistence or combat aura/spellbook polling.

- Authorized seal activity experiment: event-driven, guarded combat aura access may show a native countdown on a publicly identified active seal and gray other seals. Unknown/restricted state clears presentation; never reconstruct timers or identity from casts. Secure actions remain unchanged in combat.
