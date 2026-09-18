# WoW Forever beta compatibility plan and candidate status

## Verified baseline

The source checkout and this feature branch start at e970bde, including the
combined picker, cooldown learning, stance display and recovery improvements.
Both checkouts were clean before implementation. Classic Era remains supported.
The owner approved beta-only installation and subsequent durable closeout.
Era and other addon installations remain unchanged.

On 2026-09-17 the owner-provided runtime diagnostics reported beta version
1.60.1, build 69893, interface 16001, WOW_PROJECT_ID 1 (CLASSIC is 2).
The installed WowB.exe reports 1.60.1.69893. The matching beta interface export
is newer than that executable. Both target export checks pass; timestamps are
a freshness heuristic, not proof of API availability in every gameplay context.

## Implementation plan and completed work

1. **Client selection:** Core/Client.lua retains the Era project/interface gate
   and admits only beta version 1.60.1, build 69893, interface 16001, project 1,
   with the secret-value guards present. The TOC declares both interfaces.
   Unknown beta patches remain disabled until their contracts are checked.
2. **Read boundaries:** Core/Access.lua rejects unreadable values before Lua
   comparison, arithmetic, table indexing, sorting or persistence. Unit reads,
   threat observation, aura ownership, casts, cooldowns and stance use it.
   Failed calls remain unavailable. No internal or secure combat-log reader is
   used. Tank does not need combat-log attribution for its existing features.
3. **Display:** native beta status bars receive health/power directly through
   documented secret-accepting setters. Player health retains its threshold
   colors through a display-only color curve. Enemy health retains its fixed
   color. Era geometry and rendering remain unchanged. No native secret values
   are read back, decoded or used for discovery.
4. **Features:** retain nameplate observation, target fallback, all event
   lifecycles, picker layout, combat closure, demo cleanup, stance display,
   independent clears and character opt-outs. Beta combat transitions clear
   observation caches. Restricted threat discards cached rows immediately;
   readable data can recover on subsequent refreshes. Beta applied debuffs use
   six general slots and overflow until a beta class catalog is verified.
5. **Cooldown learning:** successful readable player spell identities still
   require confirmed real cooldowns or recharge. The exported NeverSecret
   isActive/isOnGCD/maxCharges flags permit classification even when timers
   are secret. Numeric timers/charges remain unknown in that case; no duration
   guess or fixed catalog is introduced.
6. **Validation:** full local suite, new secret/unavailable fixtures, beta TOC
   startup and transition smoke, both export checks, and beta export-checker
   failure fixtures. See API_REFERENCE.md for exact source contracts.

## Remaining parity limits

| Feature | Candidate behavior | Unverified or unavailable behavior |
| --- | --- | --- |
| Player health/power | Native display with fixed geometry and picker anchor | Live colors, native secret propagation and protected-frame behavior |
| Enemy threat | Original comparison when all returned values are readable | Restricted values cannot support lead/recovery math; rows are removed |
| Enemy health | Native health display on visible beta rows | Rows still depend on usable threat and identity |
| Casts and markers | Original display for readable values | Restricted casts/markers omitted; no native restricted cast timer yet |
| Own debuffs and missing effects | Complete readable own-aura set; exact identity and opt-outs | Restricted aura reads/ownership produce unknown, never absence |
| Cooldowns | Existing numeric timers when readable; public classification can learn hidden timers | Restricted spell IDs cannot be learned; hidden timers/charges show question marks |
| Stance and picker | Same shared lifecycle and controls | Live class/rank changes, tooltip/template appearance and combat transitions |
| Applied debuff columns | General beta slots and overflow | Era class/rank catalog has not been verified for beta |

The implementation is a reviewable beta candidate, not full supported combat
parity. Mock secret sentinels exercise guards but cannot reproduce the client's
secret-value engine, taint system, timing or server threat availability.

## Durable installation and rollback

The beta addon junction is:
C:/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns/ApogeeTank

Its durable target is C:/Dev/WoW/ApogeeTank-ForeverBeta on
codex/forever-beta-durable, a manually created Git worktree sharing the primary
repository's Git history. It is outside Codex-managed worktrees. Preserve this
directory and C:/Dev/WoW/ApogeeTank; neither depends on the archived task.

The exact tested code remains d3c1197 (player-health fix), following ebb0ff6
(beta candidate). Closeout changes documentation only. Before the link switch,
all 45 tracked files were verified byte-for-byte against the installed source.
After the switch, all installed files were SHA256-verified against the durable
checkout and recorded in the external verification manifest.

External rollback/preservation directory:
C:/Dev/WoW/ApogeeTank-Backups/2026-09-17-beta-closeout

It contains a verified complete-history Git bundle, exact d3c1197 source ZIP,
a closeout bundle, SHA256 file manifest, and rollback instructions. These
artifacts do not depend on the disposable Codex worktree. Restore a new stable
checkout from the bundle or ZIP if needed, verify it, and switch only the beta
junction. Never recursively delete a junction target or overwrite an unexpected
path. Keep character SavedVariables untouched.

The prior managed worktree at C:/Users/nickm/.codex/worktrees/d2bd/ApogeeTank
is no longer an installation dependency. Its task may be archived after final
verification. The primary Era checkout remains at e970bde; no release, push,
game restart/reload or live acceptance was performed during closeout.

## Remaining live acceptance

Confirm the corrected own health bar after reload and Shift-left-click it
outside combat to open the picker. Verify combat closes and blocks the picker.
The rejected old color call and successful corrected unit-API color transform
were tested live, but those diagnostics do not establish reloaded HUD or mouse
interaction acceptance. Grouped threat updates/lead/recovery remain untested.

In beta, test login/reload, entering/exiting combat, zoning, multi-enemy party
pulls, target/nameplate changes, threat loss/recovery, casts, markers, owned-aura
discovery and missing reminders, cooldown learning/GCD rejection/charges,
stance changes and picker/clear/demo controls. Record exactly which APIs are
readable in each situation and any Lua errors. Repeat Era acceptance for visual
parity. Multiple classes/ranks and talent changes remain required.

Installation, publishing and release remain subject to explicit owner approval.
