# Forever quality sweep — 2026-09-24

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
