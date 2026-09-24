# Forever quality sweep — 2026-09-24

## Owner acceptance and integration

After installation of the performance follow-up, the owner reported testing all
five Apogee addons in game and authorized committing, integrating into main and
pushing to GitHub. This is user-reported acceptance of the installed candidate.
It is not an exhaustive per-issue validation record or a measured FPS result;
the specific historical seal-detection and flicker limitations below are retained.
The earlier phase reports describe the checks and publication state at that time.

## Performance follow-up

Reviewed remaining event/animation paths against the completed deep review.
The current 70009 export still passes freshness verification. Its
`SPELL_RANGE_CHECK_UPDATE` payload identifies the affected spell; broad usability
and target events still require full castability refreshes.

Two measured, bounded optimizations were justified:

| Scenario | Before | After | Correctness boundary |
| --- | --- | --- | --- |
| 100 range notifications for one of six selected cooldowns | 1,200 usability/range API calls | 200 calls | Affected spell updates synchronously. Target/usability changes and unreadable/non-numeric identifiers retain full guarded refreshes. Unwatched IDs do no display work; no timer API reads were added. |
| 100 unchanged player-aura events with three allocated seal buttons | 600 desaturation/alpha writes | 0 writes | Only the public dimming boolean is cached. Aura access still occurs on events, unknown state clears immediately, identity changes invalidate artwork state, and failed timers retain their recovery path. |

Both assertions failed against the prior implementation before fixes. Tests
exercise range transitions immediately, unrelated spell preservation, broad
target invalidation, secret identifiers and zoning. Existing seal regressions
cover active/unknown/absent transitions, timer failures, identity changes and
combat geometry guards. The full local suite with the actual 70009 export passes,
including exported secure-action integration and prior regression coverage.

These are deterministic offline call/write counts, not measured FPS gains.
No further justified optimization or additional reproducible bug was established
in this pass. Existing coalesced threat refresh, sleeping idle cooldown drivers,
cached countdown animation, picker closure and fixed secure geometry were retained.
Live seal detection, flicker, taint and in-game performance remain unverified.

The validated follow-up was installed from the same `d5ce/ApogeeTank` worktree
into the verified Forever beta addon directory below. Installed files matched
the preceding installation manifest; no unexpected edits or extra files existed.
All 28 files were backed up and verified, two runtime files were copied, and all
28 installed SHA-256 hashes match the validated source. Latest rollback package:
`C:/Dev/WoW/Backups/ApogeeTank/forever-performance-70009-20260924-152743-a2f7e1`.
Use its `installation-manifest.json` file list for rollback, preserving later edits.
SavedVariables and other addons remain untouched. The game was not operated;
an out-of-combat `/reload` is required to load this follow-up.

## Deep review after family cleanup

Reviewed every shipped Lua module, TOC/load order, assets, local changes, tests,
export provenance, and saved-data boundaries on `codex/forever-cleanup`. The
earlier review below predates this pass and its installed-export result is now
historical.

| Severity | Reproduced finding | Local correction and regression |
| --- | --- | --- |
| P2 | `Core/Cooldowns.lua` trusted `isOnGCD` on login, combat and spellbook refreshes, contrary to the reviewed 69977 contract. Stale true could assert readiness; stale false could classify GCD activity as a real display timer. Two prior assertions required this invalid behavior. | Consume the flag only for `SPELL_UPDATE_COOLDOWN`. Other reads retain native duration delivery and safe unknown handling. `tests/default_cooldowns_spec.lua` now covers readable and opaque stale flags, event-valid GCD exclusion and independent charge classification. |
| P2 | `Cooldowns/Runtime.lua` let any older-rank opt-out override a newer rank explicitly re-enabled in the picker. The next combat exit silently unchecked it again. | Inherit the newest recorded rank's choice. Regression covers initial opt-out inheritance, explicit recheck, later rank upgrade and current-rank opt-out. No schema change or existing selection deletion. |
| P3 | `Seals/Runtime.lua` cached failed timer setters as though no retry was needed. The same active aura could never restore its countdown after a transient failure. | Retry a failed application on the next event; unchanged successful timers still avoid resets. Setter-failure/recovery regression and the existing 100-event write-count check pass. |
| P3 | `Seals/Runtime.lua` treated a failed/unreadable death query as alive and retained active-seal presentation. | Require explicitly readable alive status. Regression clears countdown/dimming on query failure; the fixture now supplies a real alive result instead of silently relying on a missing API. |
| P3 | `Guidance/Runtime.lua` checked death inside refresh but did not register `PLAYER_DEAD`. A missing-aura warning survived death without another aura event. | Register the existing death event. New runtime regression proves warning removal, revival recovery and zoning suppression. |

Each new failure was observed against the pre-fix path before its correction.
Seal mocks now also reject protected geometry writes during combat. These checks
still do not emulate the engine's full taint rules.

Startup remains a small composition point with one Forever TOC, existing packaged
logo, no addon dependencies, private module state and Tank-prefixed named frames.
Saved cooldown schemas, opt-outs and copied identities retain their existing
guards; future schemas remain untouched. The historical effects store is still
TOC-only. Minimap persistence stays separate. Preview isolation, target clearing,
event coalescing, cached animation, combat-frozen cooldown identities, native
target acquisition and combat-reload deferral were inspected. No additional
actionable defect was confirmed in those paths. Cross-addon coexistence is a
source-boundary review here, not a multi-addon live-client test.

### Verification after the current export refresh

The owner refreshed the beta code export on 2026-09-24. Independent verification
confirms installed beta **1.60.1.70009**, interface **16001**. `WowB.exe` is dated
22:04:15 UTC; reviewed generated contracts are dated 22:12:54 UTC and secure Lua
22:12:55 UTC. The earlier stale 69977 export blocker is resolved. Provenance was
recorded only after reviewing the refreshed contracts and passing freshness
validation. Runtime warning baseline and test fixtures now use 70009. Required
freshness files now include aura, secrecy-predicate and death-event contracts.

Current `SpellSharedDocumentation.lua` still explicitly limits `isOnGCD` to
`SPELL_UPDATE_COOLDOWN`; classification flags remain public and charge recharge
is independently classified. `SpellDocumentation.lua` retains duration objects
and the `ignoreGCD` argument. The held GCD fix is therefore supported by current
contracts. `UnitAuraDocumentation.lua` retains aura-access/non-secret identity
requirements; `SecretPredicateAPIDocumentation.lua` retains the spell-aura secrecy
predicate. `DeathInfoDocumentation.lua` confirms `PLAYER_DEAD`; native health,
marker and cooldown rendering contracts retain the reviewed boundaries. No
additional API-dependent source fix was required. This is a targeted contract
review against prior recorded evidence, not a byte-for-byte diff of full exports.

Both `pwsh ./scripts/check-wow-api-export.ps1` and the complete
`pwsh ./scripts/test-local.ps1 -ForeverExportPath <matching AddOns directory>` pass.
The suite includes Lua 5.1 parsing, all regressions, standalone TOC execution,
export-checker fixtures and whitespace checks. Native integration was enabled:
tests load and execute the refreshed Blizzard secure resolver/actions, attribute
driver resolver and click dispatcher. They cover marker mappings/repeated set,
the absent-target guard and offensive acquisition path, native macro dispatch,
aura macro delivery and click timing. Direct spell assignments are covered by
configuration tests and source review. No Blizzard code is redistributed.
Engine calls, macro-condition parsing and permissions remain mocked; these are
current-export Lua integration tests, not an in-game taint or casting test.

Combat seal readability is still unconfirmed and the earlier live report of
failed detection remains unresolved. No unrestricted aura reader, cast-derived
timer or guessed identity has been introduced. Neutral clickable seals remain
the safe fallback.

Remaining live checks: combat reload and taint, marker permissions, helpful and
offensive targeting with absent/friendly/dead/hostile targets, cooldown and charge
completion, aura activation and death/revival, seal changes/expiration, flicker,
and coexistence with the other independently installed Apogee addons. No commit,
integration, push or release was performed during this review.

### Authorized local installation

The owner's standing workflow now includes local Forever installation after
checks. On 2026-09-24 the validated package from
`C:/Users/nickm/.codex/worktrees/d5ce/ApogeeTank` was installed into
`C:/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns/ApogeeTank`.
The actual destination is an ordinary directory, with no linked package paths,
unexpected edits or unrecognized files. All 28 prior package files were backed up
and verified before copying seven changed files. SHA-256 verification confirms
all 28 installed package files match this worktree.

Rollback package:
`C:/Dev/WoW/Backups/ApogeeTank/forever-quality-70009-20260924-152144-7ea1a5`.
Its `installation-manifest.json` records source, destination and before/after
hashes. Restore only the manifest-listed files from that backup to reverse this
installation; preserve any later edits before doing so. SavedVariables, other
addons and the client executable were not touched. No game operation or restart
was performed. An out-of-combat `/reload` is needed to load these files; the live
checks above remain outstanding.

## Earlier threat-centered review

Audit of the installed threat-centered, Forever-only revision. Existing uncommitted redesign work is preserved; fixes are on the same feature branch.

## Fixed findings

| Finding | Correction / evidence |
| --- | --- |
| Held spells with positive charge counts looked ready. | Held state now wins over charge display; new view regression reproduced the failure before the fix. |
| A readable available charge disappeared when its recharge timer was unavailable. | Preserve the known charge count without guessing the timer; new view regression reproduced the failure. |
| Unclassified active cooldowns reused old readiness. | Retain only a still-running confirmed timer; otherwise show unknown. The previous test incorrectly asserted reuse of readiness and now guards against it. |
| Numeric timers ignored non-default spell/charge rates. | Delegate rate-adjusted timers to native duration objects. New API regressions cover both spell and charge rates; no guessed Lua rate formula or animation polling added. |
| An unreadable/failed death-status query was treated as alive. | Require an explicitly readable false death status before presenting details. Tests reproduce both secret and error cases and verify recovery. Native secure visibility still owns the marking surface. |
| Picker tooltips remained visible after closure or row reassignment. | Clear only tooltips owned by picker rows/hover regions on close, hiding or rebinding. Closing regression reproduced the stale tooltip. |
| Minimap combat handling hid tooltips owned by unrelated UI. | Check ownership before hiding; test keeps an unrelated tooltip visible across combat entry. |
| Late stance events still read APIs after world exit. | Gate stance updates until entering the world; regression verifies no read during zoning and restoration afterward. |
| Preview raid-marker crop used an obsolete 4-by-2 layout. | Use native SetSpriteSheetCell(8, 4, 4), matching Forever's exported SetRaidTargetIconTexture. |
| Saved spells without artwork rendered blank cooldown icons. | Use the same question-mark artwork fallback as the picker; covered by the view test. |

## Verification and limits

Full Lua 5.1 suite passes, including the exported Forever secure resolver/action integration. Installed export freshness is verified at 1.60.1.69977. Whitespace checks pass. Spell animation still uses cached state and native duration objects; no new spell polling was added.

The audit also reviewed protected-button geometry/lifecycle, target clearing, native health and marker sinks, picker confirmation/preview isolation, persistence, and minimap dragging. No additional confirmed defect was established in those paths.

This is a source and regression-test sweep, not a claim of bug-free live behavior. The engine's taint rules, actual rendering, group permissions and the user's reported in-game symptoms still require live verification. Exact symptoms/error text were requested; none were available during this sweep.

- Fixed native cooldown desaturation being cleared by usability/range refreshes: presentation now keeps a separate classification from the event-gated discovery flag. Regression coverage exercises a running native timer across both event types and completion.

Live feedback follow-up: cooldown classification now survives target/usability refreshes, including GCD-only timers; discovery remains gated separately. Offensive click macros use a native attribute driver to select plain cast versus target-and-cast payloads, matching the Keybinds Forever routing pattern. Tests cover both payloads through the exported driver resolver and native macro action, but cannot prove live parser behavior or taint safety.

Second targeting follow-up: match Keybinds on-screen button configuration with LeftButtonUp/useOnKeyDown=false and native drivers for type1, spell and macrotext, instead of mixing direct type writes and a payload-only driver. Export test now executes the actual click phase handler for ordinary and secure mouse input. Live success remains unconfirmed until the owner retests.

Confirmed no-target cause: SecureTemplates.GetConvertedButtonUnitAndActionType returns before dispatch when a button declares unit=target and that unit does not exist. Acquisition macro buttons now omit unit; direct spell buttons retain target. Regression executes this exported guard, reproduces the old rejection, and verifies the corrected macro reaches dispatch with no target. Prior click-phase/driver changes alone did not fix the live issue.

Live seal-row startup fix: corrected STATUS_HEIGHT to the actual HUD-local STATUS_BAR_HEIGHT constant. Seal lifecycle regression now calls the real ThreatHud.GetSealGeometry rather than a geometry stub, exercising Paladin seal creation after combat reload and verifying first/second slot position.

## Live flicker cleanup, September 24

- Range, usability and target events update castability only; cooldown/charge events own timer observations. A 100-iteration paired event burst performs zero cooldown API reads.
- Native timer caching keys on the duration object instead of a freshly allocated state table. A 100-state replacement test performs zero native timer resets; failed setters can recover on subsequent observations.
- Public GCD-only/idle classification no longer turns restricted timestamps into unknown displays. Unclassified activity cannot reuse an indefinitely old native timer.
- Running native and numeric cooldowns use consistent opacity. Fixed spell assignments are rebuilt only when the selection snapshot changes or visibility is restored, not every animation tick.
- Seal numeric timers prefer the actual public expiration/duration pair and do not restart on unrelated aura events. A 100-event burst leaves the timer setter count unchanged. Secure seal configuration changes only when spell identity changes. Death/zoning clear seal timer presentation.
- Repeated identical aura suggestions and unknown-state notifications no longer reset tooltip/action setup. Guidance filters restricted unit-event identifiers before comparison.
- Reviewed update loops in threat, picker/preview, minimap, stance, cooldowns and seals. Existing idle threat and preview closure checks remain in the full suite. No new frame-tick API polling or restricted-state reconstruction added.

These are mock call-count and exported-native-source regressions, not live frame-rate profiling or proof that all observed flicker is gone. Combat seal detection remains unconfirmed and neutral when unavailable. Recheck rapid target changes, GCDs, running cooldown completion, seals, and combat transitions in game.
