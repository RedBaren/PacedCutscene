# PacedCutscene

An Ashita v4 addon for HorizonXI that automatically advances NPC dialog and cutscenes at a comfortable reading pace instead of skipping everything instantly.

## Installation

Drop the `PacedCutscene` folder into your `/addons/` directory, then load it in-game:

```
/addon load PacedCutscene
```

## Commands

All commands use the `/pcs` prefix.
```
|  Command                | What it does |
|                         |
| `/pcs help`             | Show all commands and current settings |
| `/pcs on`               | Turn on auto-advancing |
| `/pcs off`              | Turn off auto-advancing |
| `/pcs delay <seconds>`  | Set how long each dialog box stays on screen (0.3 - 10.0) |
| `/pcs skip`             | Toggle whether lines with item/key item prompts are auto-advanced |
```
## Examples
```
- `/pcs delay 2`    - Wait 2 seconds before advancing each dialog line
- `/pcs delay 0.5`  - Speed things up to half a second per line
- `/pcs skip`       - Allow auto-advancing through item reward prompts (off by default)
```
## Default Settings

- **Auto-advance:** On
- **Delay:** 1.0 second
- **Skip item prompts:** Off (pauses on lines that mention items so you can see what you received)

## Ignored NPCs

Some NPCs are skipped to avoid freezes or timing issues:

- Geomantic Reservoir
- Paintbrush of Souls
- Stone Picture Frame

## Credits

- Based on Enternity by Hypnotoad & atom0s
- Dialog advance method by atom0s (from the balloon addon)
