# Whetstone
> A floating bar showing the current rank and cap of your professions and weapon skills.

Built for Classic Era, WoW Forever, and TBC Anniversary, where skills level slowly and caps depend on your rank and character level. _Taintless, fast, and small!_

## Features

### Skill Tiles
- One tile per profession, secondary skill, and weapon skill
- Current rank, cap, and bonuses from racials and gear, such as `(+5)`
- Compact tiles with a thin progress bar, or full-height bars with the text on top
- Horizontal or vertical layout, with a configurable number of tiles per line

### Skill States
Each tile is coloured by the state of its skill:

- Levelling: below the current cap
- Ready: you meet the skill and level requirements for the next rank
- Capped: at the cap, and the next rank is still out of reach
- Maxed: nothing left to gain

### Weapon Skills
- Defense is always shown
- Other weapon skills show while the weapon is equipped, or after gaining a point this session
- Unarmed shows while your hands are empty
- Optionally show every weapon skill at all times

### Tooltips
- Points left until the cap and points gained this session
- The next rank, its skill and level requirements, and where to learn it
- The trainer, vendor, or quest giver for your faction, for Expert and Artisan crafting ranks and secondary skills. On TBC Anniversary every capital city trainer teaches Expert and Artisan, so only secondary skills name one
- Specialization trainers for Blacksmithing, Engineering, and Leatherworking once you reach the skill
- Artisan Enchanting names Annora, inside the Uldaman dungeon, without a waypoint

### Waypoints
Left-click a tile to mark the next rank's trainer:

- With [TomTom](https://www.curseforge.com/wow/addons/tomtom), a TomTom waypoint
- Without TomTom, on WoW Forever, a map pin link in chat. Click the link to place the pin

### Alerts
- Flash on skill-up
- Sound and chat message when a skill becomes capped or ready to train

## Configuration

Access the configuration panel via `/whet`, by right-clicking the bar, or through Options → AddOns.

### Display
- Toggle icons, names, progress bars, and bonuses
- Hide secondary skills, weapon skills, capped skills, maxed skills, or any individual skill
- Combat focus: weapon skills in combat, professions and secondary skills out of combat

### Appearance
- Scale, tile spacing, background opacity, and border
- Bar texture, font, and font size

Textures and fonts registered with [LibSharedMedia](https://www.curseforge.com/wow/addons/libsharedmedia-3-0) show up in the lists. The library is optional.

### Behaviour
- Drag the bar to move it, then lock it in place
- Hide in combat

## Chat Commands

- `/whet`: Opens the configuration panel
- `/whet lock`: Stops the bar from being dragged
- `/whet unlock`: Lets the bar be dragged
- `/whet show`: Shows the bar
- `/whet hide`: Hides the bar
- `/whet reset`: Moves the bar back to its default position
- `/whet scan`: Rescans your skills

`/whetstone` works as well.

## Support & Connect

- GitHub: [AvyAddons](https://github.com/AvyAddons)
- Twitter: [@Avyiel7](https://twitter.com/Avyiel7)
- Patreon: [Avyiel](https://patreon.com/avyiel)
- PayPal: [https://paypal.me/lvienna](https://paypal.me/lvienna)
