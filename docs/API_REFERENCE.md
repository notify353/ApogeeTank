# Verified Forever API reference

## Supported client and evidence

WoW Forever is the sole supported runtime: project 1, version family 1.60.x,
interface 16001. The reviewed local export is **1.60.1.70009**. Startup requires
frame creation and restricted-value guards. Later builds within that family
produce one warning per session; other families and interfaces do not start.
A warning is not a claim of verified compatibility.

The initial stale-export blocker was resolved by the owner's code export on
2026-09-24. Current contracts and exported secure actions were rechecked against
70009; strict freshness and the complete local suite pass. The event-only GCD
flag and guarded aura-access requirements remain in force.

Authoritative local export:
`C:/Program Files (x86)/World of Warcraft/_classic_beta_/BlizzardInterfaceCode/Interface/AddOns/`

Tank is independently installable. The Apogee Party Health Bars ancestry and
MIT attribution do not create a runtime dependency on that addon or its APIs.
[Architecture](ARCHITECTURE.md) describes current module ownership;
[HUD validation](HUD_REDESIGN.md) records remaining live acceptance.

## Current API boundaries

- `UnitDocumentation.lua`: target identity, threat, health, casts, assigned roles
  and spellcast events. Ordinary Lua calculations consume only readable values.
  Unknown identity or threat never becomes a fabricated snapshot or safe state.
- `SimpleStatusBarAPIDocumentation.lua`: native health setters accept restricted
  values. Tank passes health directly to native widgets without reading it back.
- `RaidMarkersDocumentation.lua` and `SimpleTextureBaseAPIDocumentation.lua`:
  marker indices can be secret; native `SetSpriteSheetCell(index, 4, 4)` renders
  them without addon arithmetic or persistence.
- `SpellDocumentation.lua`, `SpellSharedDocumentation.lua` and
  `SpellBookDocumentation.lua`: cooldowns, charges, learned spells and events.
  `isOnGCD` is used only during `SPELL_UPDATE_COOLDOWN`; successful casts require
  confirmed real cooldown/recharge before discovery. Native duration objects
  handle opaque or rate-adjusted timers; ordinary animation uses cached state.
- `FrameAPICooldownDocumentation.lua`: native duration-object rendering. Unknown
  or held state never asserts readiness. Missing capabilities fail safely.
- `UnitAuraDocumentation.lua`: aura reads can require access and return secrets.
  Guidance avoids combat aura scans. The seal experiment only presents a publicly
  identified active seal and delegates opaque timers to native widgets; restricted
  or unavailable data clears presentation. Casts never reconstruct seal identity.
- Exported `SecureTemplates.lua` and `SecureStateDriver.lua`: native marker
  actions, hostility remapping, visibility and spell/macro actions. Protected
  geometry and assignments are configured outside combat; combat reload defers
  setup. No restricted snippets or direct addon marking calls are used.

Inherited APIs are retained when the Forever export and current behavior require
them; their age or location in a Blizzard Classic folder is not evidence of an
Era compatibility path. The runtime has no Era branch, nameplate enemy queue,
player health/power bars or enemy-effect tracking. The historical effects store
is declared in the TOC only and is never read, migrated, cleared or written.

## Export freshness and tests

```powershell
pwsh ./scripts/check-wow-api-export.ps1
pwsh ./scripts/test-local.ps1 -ForeverExportPath 'C:/Program Files (x86)/World of Warcraft/_classic_beta_/BlizzardInterfaceCode/Interface/AddOns'
```

The checker defaults to the sole recorded target, `foreverBeta`. Use `-WowRoot`
or `WOW_ROOT` for a different installation. It compares installed build metadata,
TOC interface, recorded provenance and required documentation timestamps.
Missing, older or mismatched exports fail. After refreshing and reviewing the
matching export, `-Record` updates repository metadata only. File timestamps are
a freshness heuristic, not proof of origin or API correctness.

The local suite includes Lua 5.1 parsing, Forever gating, persistence, restricted
values, feature lifecycle and exact exported native secure resolver/action tests
with mocked engine inputs. An omitted export prints SKIP; an invalid supplied
path fails. No Blizzard source is redistributed.

Passing these checks does not prove live taint safety, visual parity, group
permissions or FPS. Remaining in-client checks include combat reload, marker
permissions, cooldown/charge completion and targeting, aura click activation,
seal switching/expiration, flicker and coexistence with other addons. Reported
combat seal detection remains unconfirmed; neutral clickable seals are the
fallback. Requested source changes use the central Apogee Forever DEV builder
and installer after checks and backup verification. Follow
`C:/Dev/WoW/ApogeePartyHealthBars/distribution/DUAL_WORKFLOW.md`; never overwrite
PROD with a child checkout. Documentation-only changes do not repin or reinstall
runtime. Release and publication remain separately authorized.

## Historical diagnostic records

The records below describe superseded implementations and exports. Their Era,
player-bar, name-label and multi-enemy behavior is not supported or tested by the
current addon. Keep them as diagnostic history, not implementation instructions.

## Historical beta preparation: 1.60.1.69893 (2026-09-17)

This section records the original preparation and hotfix evidence, not current
feature scope. [Forever status](FOREVER_BETA_PLAN.md) defines current behavior.

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


## Forever native cooldown countdown (2026-09-19)

The screenshot's question marks are text labels over spell textures. The view
previously mapped every unknown numeric timer to `?`, even when the spell had
been learned successfully. A restricted-timer fixture reproduces that path;
a screenshot alone cannot identify the exact live API return that triggered it.
No character SavedVariables were read or reset to implement this fix.

The 1.60.1.69913 beta SpellDocumentation export provides
C_Spell.GetSpellCooldownDuration(spellIdentifier, ignoreGCD) and
C_Spell.GetSpellChargeDuration(spellIdentifier), returning LuaDurationObject.
FrameAPICooldownDocumentation supplies SetCooldownFromDurationObject, countdown
font/visibility controls and swipe/edge/bling controls. The exported
Blizzard_AuraContainer/Blizzard_CustomAuraButton.lua also passes opaque duration
objects to this native setter. This is a display route, not permission to inspect
restricted numeric values. The setter is protected and called with error handling;
a rejected application keeps unknown presentation rather than asserting readiness.

When numeric timing is unreadable, Forever now passes the appropriate duration
object to a native cooldown child. Ordinary spells request ignoreGCD=true; charge
spells use their recharge duration. Lua never reads duration-object values, and
objects are never persisted. Existing event-based sampling supplies the objects;
countdown ticks do not call spell APIs or reset native timers. Readable positive
charge counts retain their label; unknown charge counts use the native recharge
countdown. Returning to readable numeric timing hides the native child. Era's
numeric display, discovery rules, cooldown picker and saved selections are unchanged.

The export checker now includes FrameAPICooldownDocumentation. Regression tests
cover opaque spell/charge duration delivery, GCD exclusion, public charge counts,
no tick polling, rejected-setter fallback, recovery and return to numeric timing.
Live acceptance remains required: reload, cast each selected cooldown in combat,
verify native numbers advance and clear, exercise charge abilities if available,
and report any remaining question mark with the spell name from the picker.


## Forever native raid-marker display (2026-09-19)

The shared GetRaidTargetIndex wrapper strips unreadable values from observer
snapshots. Consequently, the original marker renderer hides a valid marker when
its index is restricted. RAID_TARGET_UPDATE was already registered and requests
a coalesced HUD refresh; its event wiring was not the missing display path.

The matching beta RaidMarkersDocumentation marks GetRaidTargetIndex SecretReturns.
SimpleTextureBaseAPIDocumentation explicitly permits SetSpriteSheetCell's cell
argument when tainted and adds the TexCoords secret aspect. Exported Mainline
TargetFrame.lua implements SetRaidTargetIconTexture with SetSpriteSheetCell(index,
4, 4). Forever now uses this native texture method directly inside a protected
call, passing the target's raw index without comparison, arithmetic, persistence
or snapshot storage. Readable nil or a failed native call hides the marker.
Marker updates, clear and API recovery reuse the existing event refresh path.
No marker assignment API is called. Era retains its original rendering.

The exact 14px marker slot and right-side mob-name anchor remain unchanged.
Tests cover readable/restricted marker delivery, nil clearing, setter failure and
recovery, target clear and name spacing. Native acceptance still requires reload
and viewing an already marked hostile target in and out of combat; mock tests
cannot establish actual secret propagation on the client.

Rollback: C:/Dev/WoW/ApogeeTank-Backups/2026-09-19-native-marker-104450


## Forever target-row clicks and precombat visibility (2026-09-19)

The owner explicitly authorized three user-driven marker assignments on the
current target's threat meter: left skull (8), right cross (7), Shift-left moon
(5). The export's ChatFrameConstants.lua maps the named icon tags to these IDs.
The initial direct mouse-up implementation was blocked live both in and out of
combat. Calling an API from Blizzard's trusted handler did not establish addon
permission, and pcall does not change execution privilege. That addon call has
been removed entirely.

The matching SecureTemplates.lua/XML export provides SecureActionButtonTemplate
and SECURE_ACTIONS.raidtarget with action=set (not toggle). Marking now uses an
independent protected Button parented and anchored only to UIParent, aligned with
the fixed scaled target meter. It is configured out of combat, or deferred to
PLAYER_REGEN_ENABLED if loaded under lockdown. Dynamic HUD refreshes never
reparent, resize, hide or mutate its secure attributes during combat.

Native harmbutton remapping assigns skull/cross/moon virtual buttons only when
Blizzard's secure resolver determines the current target is attackable at click
time. Numeric buttons have no action; unsupported modifiers explicitly disable
remapping. Each virtual button uses built-in raidtarget/action=set. AnyDown plus
useOnKeyDown activates at press and targets literal target. RegisterStateDriver
owns living-hostile-target visibility using [@target,harm,nodead]; no custom
_onstate script, restricted snippet, secure wrapper, addon OnClick replacement,
programmatic click, macro or direct SetRaidTarget call is registered.
The button owns a visible neutral meter beneath the ordinary HUD. It remains
fixed at the target meter and follows native secure target eligibility even
without readable observer identity. No synthetic identity is created. Group/raid
permissions remain enforced by Blizzard. Player-health Shift-left-click is separate.

Forever now observes and displays a living hostile target outside combat too.
No readable threat produces an unknown row with an empty meter, health/name and
native raid marker, rather than a fabricated lost/safe value. The empty meter is
still clickable. Selection events refresh immediately; precombat health, casts,
flags, faction, name and threat changes request coalesced event refreshes.
Animation uses cached data; combat retains the 0.1-second sampling interval.
No target/friendly/dead targets hide the row; player/cooldown lifecycle and Era's
combat-only multi-enemy behavior stay unchanged.

Regression coverage includes all three secure marker IDs, no-op modifiers,
set mode (no toggle-off), current-target secure guard, deferred lockdown setup,
precombat no-threat acquisition/clear/friendly/dead targets, and combat transitions.
Live acceptance: reload, select a hostile target before combat, use each gesture,
confirm marker changes with proper group permissions, repeat during combat, and
verify player-bar Shift-left-click still opens only the cooldown picker.
Rollback: C:/Dev/WoW/ApogeeTank-Backups/2026-09-19-marker-clicks-111102

Secure-marking correction rollback:
C:/Dev/WoW/ApogeeTank-Backups/2026-09-19-secure-marking-111535
Local tests validate configuration and safe lifecycle, not Blizzard secure
execution or live combat permission. Reload outside combat and test each gesture,
then repeat in combat with group marking permissions. If the secure path is still
blocked, stop using the gesture and report the blocked-action event; do not fall
back to direct calls.


### Live snippet-compiler failure and native-only correction

The screenshot on 2026-09-19 points to RestrictedExecution.lua:79 inside
BuildRestrictedClosure. That exact line calls loadstring_untainted to compile the
body, before invoking the snippet. This is evidence of an absent compiler
function, not evidence that SecureCmdOptionParse is absent inside the snippet.
The latter is explicitly listed in RestrictedEnvironment.lua's copied allowlist,
though an allowlist alone cannot prove runtime availability. Changing a snippet
body cannot repair this earlier compiler failure.

Removed SecureHandlerWrapScript and SecureHandlerBaseTemplate entirely. The
matching SecureTemplates.lua GetConvertedButtonUnitAndActionType handles
harmbutton remapping using UnitCanAttack and rejects nonexistent units; the
built-in raidtarget action performs setting. SecureStateDriver.lua resolves
visibility through its native resolver and never calls BuildRestrictedClosure.
The native visibility driver, including its normal update cadence, owns dead
and missing-target hiding. No addon shortcut replaces that protected state.

The UI test now fails immediately if any restricted wrapper is registered.
When APOGEE_FOREVER_EXPORT (or test-local.ps1 -ForeverExportPath) explicitly
names the matching export's AddOns directory, it also loads the exact exported
BuildRestrictedClosure with its compiler absent and reproduces the screenshot's
failure even for an empty/simple body. It then executes the exact exported native
button resolver and raidtarget action with mocked engine inputs in an environment
containing neither loadstring_untainted nor SecureCmdOptionParse. Three mappings,
unsupported modifiers, friendly/no target and non-toggling set pass. This tests
the actual Lua boundary; it still cannot reproduce the live client's taint engine.
An omitted export prints SKIP, and an invalid supplied path fails. Portable
configuration/lifecycle tests always run. No Blizzard source is redistributed.

Rollback: C:/Dev/WoW/ApogeeTank-Backups/2026-09-19-snippet-free-marking-112150
The owner subsequently confirmed native-only marking live. After the review
fixes, reload outside combat and repeat gestures and combat marking with normal
group permissions, checking the new neutral-meter layering under restricted
identity. The missing-compiler dependency remains removed.
