# Stance-equivalent guidance

Tank owns Warrior stance, Druid form and Paladin aura presentation and reminders. It does not recommend applying seals, blessings, shouts, Mark/Gift of the Wild or Righteous Fury. No changes to other addons are included.

Native TANK, HEALER and DAMAGER assignments select policy. Explicit NONE uses damage; failed or restricted role reads remain unknown. Paladins get a missing-aura reminder (Concentration preferred for healing when learned, Devotion otherwise). A supported active aura satisfies it. Tank Warriors get Defensive Stance reminders; tank Druids get bear-form reminders. Damage Druid builds are not inferred from role alone.

The active stance/form/aura spell icon remains immediately left of the threat meter, opposite the raid marker. It is active-state context, not a role badge. Cooldowns and guidance retain their separate positions above the meter.

Reminders check learned spells and readable beneficial player auras outside combat. Combat shows unavailable status rather than stale missing-state claims. No aura API polling on animation ticks, automatic casting, settings or persistence is added. Spell families resolve using localized native spell names. Live class, role-change and placement checks remain necessary; mock tests cannot prove live API readability.

Paladin aura reminders use a fixed shield icon in the left slot: desaturated and dimmed when the learned recommended aura is missing, full color when an aura is active. The tooltip names the aura and its guidance role. There is no Activate aura text. Left-clicking the aura casts the learned spell through a native secure macro button using non-toggling aura syntax, including in combat. Configuration is frozen during combat; the preconfigured spell and shield remain available. Reloading in combat defers button creation until combat ends. Unreadable aura state stops the missing-state pulse but retains a neutral gray click affordance. The footer is guidance, not an assigned-role indicator. Unknown or restricted observations do not produce a gray missing-state claim.

Aura hover uses the native spell tooltip. Devotion adds a prominent TANK footer; Concentration uses HEALER and Retribution uses DPS. These are guidance labels, not native role assignments or exclusive-use restrictions.

A verified missing Paladin aura gently pulses the gray shield between 55% and 85% opacity over 1.8 seconds. Activation, unknown state, hiding or zoning stops the pulse. Animation uses cached display state only and performs no aura/spell polling.

Missing-aura emphasis includes a two-pixel amber border pulsing from 40% to 100% opacity, alongside the gray shield pulse. The border disappears when active or unknown.

Paladin cooldown defaults are Holy Strike, Hammer of Justice, Judgement, Consecration, Holy Shield and Hammer of the Righteous, added once the character knows them without requiring a first cast. Highest known ranks are seeded outside combat on login, spellbook/world updates and combat exit. Explicit family opt-outs are respected. Clear removes the list immediately; defaults can return on these subsequent refresh events. Native cooldown reads supply all timing. Holy Strike rank identities were cross-checked against https://www.60.tools/spellbook/paladin.

Offensive cooldown clicks acquire an enemy with native targeting when there is no living hostile target, then cast the localized spell. An existing living hostile target is preserved. Helpful or unreadable spell classifications retain direct native spell actions. Macro configuration remains frozen in combat. Aura clicks use native non-toggling syntax to avoid switching an active aura off. Live targeting, repeated aura clicks and combat taint checks remain required.

The owner subsequently authorized a neutral learned-seal choice row below target health, matching cooldown size and spacing. It lists Righteousness, Crusader, Fury, Command, Justice, Light and Wisdom when learned, using localized family names and learned spellbook identities. Hover shows the native tooltip; left-click self-casts through native secure spell actions. No active-state assertion, countdown, pulse, role selector or seal recommendation is made. Combat freezes spell identities and discovery resumes on combat exit. The picker preview reads cached seal artwork only and creates no actions. Fury reference ID 1311649 was cross-checked with https://www.60.tools/spellbook/paladin; the live client supplies names and artwork.

Authorized active-seal test: on player aura events, first check native spell-aura secrecy. Only a publicly identified active seal receives a native duration-object countdown (readable real duration/expiration fallback). Other seal icons desaturate and dim but remain clickable. Unknown state restores neutral icons and clears all timers. No guessed durations, cast-derived state, or animation-tick API polling. Live Forever combat readability remains unconfirmed.
