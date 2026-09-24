# Architecture

WoW Forever is the sole supported client. There is no compatibility mode for Classic Era.

| Owner | Responsibility |
| --- | --- |
| Core/Client.lua | Verified Forever version/interface/capability gate and build warning. |
| Core/Access.lua | Reject unreadable values before Lua branching, arithmetic or storage. |
| Core/UnitAPI.lua | Native health/marker sinks and readable enemy casts. |
| Core/Stance.lua | Native current stance/form/aura boundary. |
| Core/Cooldowns.lua | Confirm real player cooldowns and obtain numeric or opaque native timers. |
| Core/ObservedSpellList.lua | Persist observed identities, choices and future-schema guards. |
| Threat/ | Observe only literal target, calculate readable threat, display the fixed meter, own native secure marking. |
| Cooldowns/ | Successful-cast candidates, cached animation, fixed six-icon strip and overflow. |
| Stance/ | Stance/form/aura display and independent native Paladin aura action. |
| Seals/ | OOC learned seal discovery, native self-cast choices and guarded active-aura timer presentation. |
| Guidance/ | Role-aware stance/form/aura suggestions; no seal/blessing upkeep policy. |
| Picker/ | Cooldown checklist, selection callbacks, guarded access, confirm-clear lifecycle. |
| PickerPreview/ | Synthetic display-only picker content, no observation or persistence. |
| Minimap/ | Logo button, tooltip, guarded picker toggle, character-specific drag angle. |
| UI/Style.lua | Shared Forever scale, icon artwork conventions and colors. |
| ApogeeTank.lua | Composition through public feature interfaces. |

The HUD exposes stable stance/cooldown anchors and independent secure-button geometry for stance, cooldowns and seals. The picker consumes cooldown model operations; the minimap consumes only CanConfigure/Toggle. No feature accesses another feature's private frames.

Each target refresh replaces the snapshot. There is no retained enemy queue, nameplate source, aura cache, lost-enemy history or per-enemy accessory contract. Unknown threat stays neutral. Identity changes clear stale details synchronously. Native secure visibility may retain a neutral marking affordance when identity cannot be read.

The protected target button is independently parented and anchored to UIParent. Its fixed geometry matches the meter. Native secure remapping dispatches raidtarget in set mode; no snippets or direct addon marking calls are used. Ordinary UI work does not mutate protected attributes or geometry.

Numeric cooldown animation reads cached state only. Native duration objects go to Blizzard widgets without inspection. Castability-only events do not reread cooldown timers. Unchanged selection snapshots and timer payloads do not reconfigure actions or restart timers. Idle drivers sleep. Combat/world transitions close configuration and stop synthetic previews.

The TOC retains the old effects saved-variable name solely to preserve historical data. No runtime effects module exists. Active persistence is cooldown selection and minimap angle only.
