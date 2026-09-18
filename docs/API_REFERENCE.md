# Verified client API reference

## Runtime compatibility policy

Routine build-number changes within Classic Era 1.15.x (project 2, interface
11509) or Forever beta 1.60.x (project 1, interface 16001) do not disable this
addon. Required capabilities still gate startup. An unreviewed build produces
one warning per session; it is not a claim of tested compatibility. Other
families/interfaces stay unsupported. Existing restricted-value and protected
operation guards remain in force. Optional features keep their own safe
unavailable/fallback paths.

Development export verification remains strict and separate: a changed installed
build needs a fresh matching export and contract review. Runtime tolerance does
not relax export provenance or establish live acceptance. Reviewed beta export:
1.60.1.69913; fresh on 2026-09-17. Earlier exact-build statements below describe
historical candidates and are superseded by this policy.


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

Era is the default target. Use -Target foreverBeta for the independently
recorded beta export. An unknown target fails rather than falling back to Era.

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


## Forever beta 1.60.1.69893 (2026-09-17)

Runtime identifiers supplied by the owner's beta diagnostics: version 1.60.1,
build 69893, interface 16001, project 1 (CLASSIC is 2). This is why project 1
alone is never sufficient to enable the addon. The beta executable's UTC write
time was 2026-09-17 11:30:43; UnitDocumentation.lua was 21:01:44. The live
checker passed for every required file on both clients after implementation.

Authoritative beta root:
C:/Program Files (x86)/World of Warcraft/_classic_beta_/BlizzardInterfaceCode/Interface/AddOns/

Verified generated contracts and exported callers:

- UnitDocumentation.lua: UnitDetailedThreatSituation has conditional secret
  threat values; GUID/name/creature type have identity restrictions; UnitIsUnit
  has comparison restrictions. UnitHealth is secret, UnitHealthMax and power
  have conditional restrictions. Cast/channel tuples have spellcast restrictions.
  UNIT_SPELLCAST_SUCCEEDED carries unit, cast GUID, spell ID and optional cast
  bar ID, and can carry restricted values.
- UnitAuraDocumentation.lua: GetAuraDataByIndex requires unit aura access and
  may return secret data. Full aura fields and sourceUnit are checked before
  normalization; failed ownership comparison invalidates the complete read.
- SpellDocumentation.lua and SpellSharedDocumentation.lua: cooldown/charge
  structs can contain secret numeric fields. isEnabled, isActive, isOnGCD and
  maxCharges are NeverSecret. isOnGCD is trusted only while handling
  SPELL_UPDATE_COOLDOWN. Charges use isActive to confirm actual recharge.
- SpellBookDocumentation.lua confirms cooldown and charge events. All literal
  events registered in Threat, Effects, Cooldowns and Stance were found in the
  beta generated export. Existing event-driven sampling remains intact.
- NamePlateDocumentation.lua confirms GetNamePlates. Exported nameplate
  lifecycle uses namePlateUnitToken. Shared ActionBar/StanceBar.lua and
  ActionButtonUtil.lua confirm GetNumShapeshiftForms and the icon/active/
  castable/spellID GetShapeshiftFormInfo tuple.
- RaidMarkersDocumentation.lua: GetRaidTargetIndex has secret returns.
- SimpleStatusBarAPIDocumentation.lua: SetMinMaxValues, SetValue and
  SetStatusBarColor explicitly accept secret arguments when tainted.
  Blizzard_UnitFrame/Shared/CompactUnitFrame.lua passes health/max health to
  these native setters. Tank uses this display-only route; no native status-bar
  values or aspects are read back.
- CurveUtilDocumentation.lua, LuaColorCurveObjectAPIDocumentation.lua and
  LuaCurveObjectBaseAPIDocumentation.lua confirm color-curve construction,
  step interpolation. Pass the curve directly to UnitHealthPercent(unit, true,
  curve), then send the returned color's GetRGBA to SetStatusBarColor.
  Live diagnostics showed EvaluateUnpacked(UnitHealthPercent(unit)) fails in
  addon execution because its secret argument requires untainted execution.
  The corrected unit-API transform succeeded in the same live beta session.
- SharedXML Backdrop.xml, Mainline/SharedUIPanelTemplates.xml,
  SecureScrollTemplates.xml and Shared/Button/CheckButtonTemplates.xml confirm
  all five picker templates. Shared ChatFrameFilters.lua demonstrates
  canaccessvalue guards on restricted payloads.

The runtime-confirmed absence of C_CombatLog.GetCurrentEventInfo is recorded
as context, not a Tank dependency. Internal/secure combat-log readers are not
used. No external web API reference substitutes for this client's export.

Run both:
    pwsh ./scripts/check-wow-api-export.ps1
    pwsh ./scripts/check-wow-api-export.ps1 -Target foreverBeta

Local tests pass for guarded reads, unavailable recovery, native display sinks,
both TOC startup paths and existing feature regressions. The beta candidate is
installed; the player-health color failure and corrected API call were checked
live. Reloaded HUD visual parity, picker interaction, protected-frame behavior
and party-combat acceptance remain pending. See FOREVER_BETA_PLAN.md for the
durable installation, rollback and per-feature limits.


### Player health hotfix

On 2026-09-17 live testing found the player health bar missing, including its
Shift-click picker target. The failed direct curve evaluation was inside the
same pcall as health painting; its false return hid the entire parent.
Coloring now uses the verified unit-API transform and a separate failure
boundary. Optional color failure uses neutral gray. A failed health read hides
only the native fill; the existing background/click target remains available.
Era rendering is unchanged. Regression coverage reproduces the rejected curve
method, color/read failures, recovery, mouse pass-through and picker combat rules.
The full corrected HUD still needs the user's reload and visual/Shift-click check.
Group threat behavior remains unverified.
