# Classic Era API reference

## Export freshness check

Run `pwsh ./scripts/check-wow-api-export.ps1` to compare the installed Era build,
recorded metadata, TOC interface, and required exported documentation files.
It fails if files are absent or predate the client executable. Use `-WowRoot`
or `WOW_ROOT` for a nonstandard installation directory.

After refreshing the matching client's interface export, run the same command
with `-Record` to update `docs/wow-api-export.json`. Recording validates first
and writes only repository metadata; it does not export files, launch WoW,
change installations, or update the TOC. `recordedOn` is the recording date,
not proof of when Blizzard's export was generated.

This checks export freshness, not API signatures or runtime compatibility.
File timestamps are a heuristic and cannot prove which build produced an export.
Continue reviewing the exported contracts and testing in-game.

Only Era is configured. Add a Forever target's verified product, directory,
executable, build, and interface when the beta is available, then use `-Target`.
An unknown target fails rather than falling back to Era.

The fixture tests run through `test-local.ps1` without requiring WoW. Run the
live export check separately on a machine with the client installed.

## Verified source

The source checkout's read-only export checker passed for Classic Era build
1.15.9.69722 and interface 11509 during extraction on 2026-09-13.

Authoritative local export:
`C:/Program Files (x86)/World of Warcraft/_classic_era_/BlizzardInterfaceCode/Interface/AddOns/`

References under `Blizzard_APIDocumentationGenerated`:

- `UnitDocumentation.lua`: threat arguments and return values; health, power,
  identity, casting/channeling, combat, unit and spellcast event payloads.
- `UnitAuraDocumentation.lua`: indexed harmful-aura reads and UNIT_AURA.
- `NamePlateDocumentation.lua` and `NamePlateManagerDocumentation.lua`:
  visible-nameplate enumeration and unit-added/removed events.
- `Blizzard_NamePlates` exported Lua: nameplate unit-token lifecycle.
- `Blizzard_UIPanelTemplates/Shared/UIPanelSpellButtonFrame.lua` and Classic
  exported panel XML: effect tooltips, check buttons, and scroll-frame templates.
- `RestrictedActionsDocumentation.lua`: InCombatLockdown; exported Classic
  AutoComplete and UI panel templates: modifier-key and mouse-up usage.

The observed-effect feature shares the indexed harmful-aura read boundary and
filters sourceUnit with UnitIsUnit(sourceUnit, "player") for both discovery and
coverage. Player aliases count; other players, pets, and unknown casters do not.
UNIT_AURA, target changes, and world transitions request discovery; health,
faction and flag events refresh presentation without discovery reads. Unknown
reads never become absence assertions. Only the
learned effect identities and explicit opt-outs persist through a character-specific
SavedVariable. New own effects are automatically watched. Clear All mutates this
saved table in place and cancels pending discovery until the next gameplay event.

Per-enemy missing reminders consume the threat observer's complete normalized
player-owned aura set through the HUD's public row snapshot/callback contract.
They do not infer absence from the six visible right-side icons. Aura read
unavailability remains nil, distinct from a successful empty read. Row changes
refresh the accessory synchronously to avoid carrying one enemy's reminders
onto a recycled row. Successful reads, including empty lists, are cached until
invalidated. Unavailable reads retry on the existing coalesced threat refresh;
there is no additional per-enemy polling driver.

Picker access is a plain mouse-up handler on the existing player health bar,
not a saved key binding or secure action. Only Shift-left-click without Ctrl/Alt
is accepted. Combat-event state, InCombatLockdown, and UnitAffectingCombat gate
both the gesture and deferred opening; combat also closes the picker and guards
its mutation callbacks. The threat HUD owns the frame's mouse/tooltip scripts,
and the effects feature connects through its public click-handler contract.

Threat lead is 100 minus the closest observed challenger's scaled percentage.
Recovery deficit is 100 minus the player's scaled percentage. These preserve
the source HUD's policy; neither value predicts seconds or attacks to aggro.

The HUD, observer, color policy, fixed debuff mapping, and regression cases were
extracted from the local Apogee Party Health Bars checkout. The original source
is unchanged. Existing rank IDs remain in the compact column lookup to preserve
column behavior; only actually observed player-owned auras are rendered. This
lookup does not enable another client or load the source effect-reminder engine.

Refresh and validate the matching local export before API changes following a
client patch. Reassess the explicit interface gate at that time. Future clients
require their own verified export; this addon makes no assumptions about them.

Cooldown learning uses SpellDocumentation.lua and SpellSharedDocumentation.lua:
C_Spell.GetSpellInfo, GetSpellCooldown and GetSpellCharges. The isOnGCD field
is only trusted inside SPELL_UPDATE_COOLDOWN, as the export requires. Successful
player spell IDs come from UnitDocumentation.lua's UNIT_SPELLCAST_SUCCEEDED.
SPELL_UPDATE_CHARGES supplies charge updates. No fixed GCD spell ID or duration
threshold is used. Ordinary countdown ticks make no spell API calls.
