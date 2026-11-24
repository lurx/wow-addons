# Forever Crafting (beta)

Profession levelling guides for WoW Forever, on a parchment window. Each guide tells you what to craft or gather next, what to buy, what to keep for later steps and where your trainers are. A craft bar lets you craft the next step with one click.

Created by Lurx. **Beta:** everything works in testing, but expect rough edges. Please report what you find.

## Install

1. Download the latest `ForeverCrafting-<version>.zip` from [Releases](../../releases), or copy the folders from this directory.
2. Put the `ForeverCrafting` folder and the `ForeverCrafting_<Profession>` folders you want into `World of Warcraft/_forever_/Interface/AddOns/`.
3. Start WoW, or type `/reload` if it's already running.
4. Type `/fc` to open the window.

`ForeverCrafting` is the shared core and is always needed. Each profession module only loads on characters that have that profession, so it's safe to install all of them.

## Professions

| Module | Command | Kind |
|---|---|---|
| Alchemy | `/alch` | Crafting |
| Blacksmithing | `/bs` | Crafting |
| Cooking | `/cook` | Crafting |
| Enchanting | `/ench` | Crafting |
| Engineering | `/eng` | Crafting |
| Leatherworking | `/lw` | Crafting |
| Tailoring | `/tail` | Crafting |
| Herbalism | `/herb` | Gathering |
| Mining | `/mine` | Gathering |
| Skinning | `/skin` | Gathering |

## Features

- **Guide:** the next step for your skill, with materials (including what's in your bank), what to keep for later steps, and where the route stops for training.
- **Craft bar:** shows the next craft while you're crafting. One click opens the profession window, selects the recipe and sets the amount the step needs. It shows a progress bar while crafting and warns when you're at your rank cap.
- **Trainers:** the nearest trainer first, with sub-area and coordinates, and a map waypoint (works with TomTom and OpenMap).
- **Recipes and shopping list:** where to learn each recipe, and what to buy for the rest of the route.
- **Gathering guides:** where to gather for your skill, and what each node or mob gives right now.
- **Camping recipes:** where to learn them, shown in the guide when your skill reaches them.
- **Leftovers:** materials and spare tools in your bags and bank that no guide needs any more, with vendor, auction and disenchant values. Information only: it never sells or posts anything.
- **Best value (experimental):** an opt-in hint in Settings comparing vendor, auction and disenchant value.

Prices come from Auctionator or Auc-Advanced when installed. Alt counts use Syndicator when installed, otherwise the addon's own records.

## Reporting a bug

Open an issue with:
- the profession, your skill level, and what you clicked
- what you expected and what happened
- any Lua error text (turn errors on with `/console scriptErrors 1`)
- for craft bar problems, the chat output after `/fc debug`

## Data

Recipe, trainer and drop data comes from Icy Veins, Wowhead and wow-professions.com for WoW Forever. English only for now; the text is set up for translation.

## License

MIT, see [LICENSE](../LICENSE).
