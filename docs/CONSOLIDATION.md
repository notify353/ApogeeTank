# Local consolidation handoff — 2026-09-24

## Inventory and ownership

Canonical checkout: C:/Dev/WoW/ApogeeTank, clean main at 90c6e200e12814168c199e781ffa0f8b10e83fd6 before integration. Remote origin is https://github.com/notify353/ApogeeTank.git; live remote main matched that base during inventory.

One additional Tank workspace exists: C:/Users/nickm/.codex/worktrees/tank-threat-centered/ApogeeTank, branch codex/threat-centered-hud, originally at the same base. Its tracked edits, removals, and untracked feature/tests/docs/preview files belong to the threat-centered task. No stashes, pre-existing local-only commits, or ignored files were found in either Tank checkout. No other Tank directory was found under Codex worktrees.

The external chronological record remains at C:/Users/nickm/.codex/worktrees/tank-threat-centered/task-record.md. Historical mockups remain in C:/Users/nickm/.codex/visualizations/2026/09/24/01a0d340-7e75-76f3-9bba-8aa5d41f1694 (paladin-hud.html, threat-centered-review.html/json); they are superseded review artifacts, not unmerged implementation. The reproducible preview generator and template are included in source. No external artifact or workspace was deleted.

## Intended integrated scope

The owner explicitly narrowed support to Forever only and approved the HUD redesign, minimap picker, independent secure marking/casting, known Paladin cooldown defaults, neutral learned seal row, guarded seal countdown experiment, and flicker cleanup. All are retained. Original exclusions were superseded by those later explicit requests. A Tank/DPS selector was discussed but never implemented or settled; it is not added by consolidation. There is no open product decision required to preserve the current behavior.

The task titled Fix Warrior Bloodrage detection made no Tank code changes. Its initial discovery investigation remained inconclusive; the user redirected the task to Apogee Keybinds. The final requested implementation attempts Bloodrage before Defensive Stance on every assigned stance press, in the defensive-bloodrage/ApogeeKeybinds worktree. That work belongs to the Keybinds integrator. This handoff does not claim Bloodrage cooldown discovery in Tank was fixed.

## Verification and runtime limits

Run scripts/test-local.ps1 with the Forever export and scripts/check-wow-api-export.ps1. Reviewed export is build 1.60.1.69977/interface 16001. Tests include actual exported secure resolver/actions and no-target guard, mock lifecycle/geometry, persistence, class slots, countdowns, picker/preview isolation and update-count stress checks. These do not prove live taint freedom or frame-rate performance.

The owner confirmed offensive no-target acquisition works after removing the button-level target guard. Combat seal detection did not work in the reported live test; neutral clickable seals remain the fallback. The latest flicker cleanup was installed and hash-verified earlier, but visual improvement after that cleanup is not yet confirmed. Remaining live checks: cooldown/charge completion and target/GCD transitions, seal switching/expiration, aura activation in combat, marking permissions/taint, combat reload, and other-addon coexistence.

## Preservation and next steps

Local consolidation is authorized; push, release, installation, worktree deletion and conversation archival are not part of this operation. The installed Forever addon is an ordinary copied directory, not a link to the temporary worktree; installations and SavedVariables remain untouched. Earlier installation backups remain under C:/Dev/WoW/Backups/ApogeeTank, most recently forever-flicker-cleanup-20260924-082309.

Once committed and fast-forwarded into main, the Paladin task can be archived without losing implementation or its recorded limits. The Bloodrage task is safe to archive only after its Keybinds work is accounted for there. Retain the temporary Tank worktree/branch until separately approved cleanup. Local integration is not remote backup.
