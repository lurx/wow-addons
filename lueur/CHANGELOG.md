# Changelog: Lueur retail port

Changes against **Lueur 1.4.0** by Armytille ([CurseForge](https://www.curseforge.com/wow/addons/lueur), file `Lueur-1.4.0.zip`, Oct 21, 2026).
Tested on World of Warcraft Retail 12.1.5 (Midnight). Not tested on Classic Era or Forever after these changes, though every change is meant to leave those clients as they were.

Comments added to the code are in French, to match the original. Each one is tagged `(port retail)`.

## 1.4.0-retail3

### `Lueur.toc`
- `## Interface:` now also lists retail: `120007, 120100, 120105, 120107` (12.0.7 to 12.1.7), next to the original `11509, 16001`.
- `## Version:` is `1.4.0-retail3`. Added an `## X-Port:` line crediting the original.

### `Lueur.lua`
- **Lumber category (new).** Housing lumber trees use the `crosshair_axe_64` cursor, which Lueur sorted into "other". Added a `lumber` category:
  - a default colour, `{ 0.80, 0.55, 0.30 }`, shown by default for each character;
  - a place in `CATEGORY_ORDER`, after `herb`;
  - an `{ "axe", "lumber" }` entry in `CURSOR_KEYWORDS`;
  - in `Classify`, the same handling as `ore` and `herb`: the quest and container checks are skipped.
- **"All" is now the base for every category.**
  - `SetOption` with no category no longer clears the categories' own values.
  - `SetOption` for a category always stores the value. It no longer drops a value that happens to equal the "All" value.
  - New `ns.IsOverridden(key, category)` and `ns.SetOverride(key, category, on)` drive the new "Override All" checkboxes in the menu.
- **Professions on retail.** `Trained()` also asks `GetProfessions()` / `GetProfessionInfo()`, matching skill lines 182 (Herbalism) and 186 (Mining). This check can only answer yes, so an empty list right after login never hides anything.
- **Detection range.** The maximum goes from 15 to 40 yards on retail (build `>= 120000`), and stays 15 elsewhere. *Experimental:* we have not yet measured how far retail actually keeps the soft-interact target.
- **Nameplate edge clamping.** On retail, `nameplateOtherTopInset` and `nameplateLargeTopInset` are added to `MANAGED_CVARS` and set to `-1` in `ApplyCVars`. *Known issue:* both CVars were removed in Midnight, so this does nothing on 12.1.5. The working CVar is `nameplateTopInset`, which 12.1.5 restored. This is planned for the next update.
- No new top-level locals: `Lueur.lua` is still at 198, and Lua 5.1 allows 200 per chunk. Values that needed a home went into `ns`, a table field or an inline expression.

### `Menu.lua`
- **"Override All" checkboxes.** On a category's appearance page, each setting has a small checkbox to its left (new `AddOverride` helper). Ticked means the category keeps its own value; unticked means it follows "All". Changing a setting there ticks its box. The checkboxes cover Effect, Size, Intensity, Vertical offset, Pass behind my character, Fade with the nameplate, Show the name, Show the icon, Text size and Font.
- To make room, the appearance controls moved 22 px right, the four on/off options now take one row each instead of two per row, and the window is 60 px taller (`HEIGHT` 496 to 556).
- **Minimap page hidden** when `ns.NodesFailure()` reports that the client can't read minimap dots. Retail is such a client, and the page there only held settings that did nothing. It stays visible on clients where the feature works.
- **Tab icons.** The `LargeSideTabButtonTemplate` icon stays empty on retail, so `ns.DrawTab` draws over it: the Beam effect's icon in gold for the objects page, `INV_Misc_Wrench_01` for the settings page. On the Classic fallback tab, which shows its own icon, nothing changes.
- Lumber gets the `INV_Axe_01` icon in the object list.

### `Preview.lua`
- **Models stand on the stone circle.** When the dressing-room background atlas is present, the camera is shifted along its up vector each frame so that the model's base stays at 10% of the view's height, at any rotation or zoom. Right-drag panning stops the pinning until the next category or model.
- **Front of the floor drawn over the model.** The lower part of the same atlas is redrawn above the model, so anything below the circle looks buried. Ore models are sunk by 30% of their height (`SINK`), like a half-buried rock in the game.
- **Retail nameplate height.** Retail places a node's nameplate about 2.2 yards above the top of the model, not 2 yards above its base as in Classic. This was estimated from screenshots of three nodes. Classic and Forever keep the original height.
- *Limitation:* there's no lumber model, since we don't know a file ID, so the Lumber preview shows its "no model" note.

### `Nodes.lua`
- On retail, `Skill()` returns no skill, so node difficulty colours are off there. Classic thresholds such as Mithril 175 don't apply to retail's per-expansion skills.

### `Locales/*.lua` (all five languages)
- New strings: `CATEGORY_LUMBER`, `CATEGORY_LUMBER_TIP`, `NAME_LUMBER`, `SAMPLE_LUMBER`, `OVERRIDE`, `OVERRIDE_TIP`.
- Rewrote `SCOPE_ALL_TIP` and `SCOPE_ONE_TIP` for the new "All is the base" behaviour.
- Added local command words for lumber: `bois`, `holz`, `madera`. The `/lueur` help line now lists `lumber`.
- The French, German, Spanish and Russian lumber strings are our own translations. `SAMPLE_LUMBER` ("Arden Lumber") may not match the game's name for that tree in those languages.

### `LICENSE` (new)
- The 1.4.0 zip has no license file. This is the MIT text from the CurseForge listing, with Armytille's copyright and a line for the port's changes.

## Tried and dropped
- **`nameplateOtherAtBase = 1`** moved node nameplates to the node's base, but it moved enemy nameplates to their feet too, so it was rejected.
- **A fixed −280 retail default for the vertical offset.** The gap between a node and its nameplate depends a lot on distance and camera angle, so no single value matched. Offsets are left to the player, per category.

## Planned
- Replace the removed `nameplateOtherTopInset` / `nameplateLargeTopInset` with `nameplateTopInset`.
- For 12.1.7: manage `nameplateMaxVerticalDistance` and `nameplateMaxVerticalDistanceAtMaxRange` (set to 0), so nodes above or below the player keep their nameplate and glow.
- For 12.1.7: make `GUIDObject` accept non-numeric server and spawn ID fields, since those parts of game object GUIDs are being obfuscated.
- Set the retail range cap from a real measurement.
