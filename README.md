# SmartHide - 3.3.5

Hide your stuff during combat.

For World of Warcraft **3.3.5 (Wrath of the Lich King)**.

<img width="435" height="268" alt="bild" src="https://github.com/user-attachments/assets/23b4ef47-506e-4842-9bfa-d34ae98bd0bb" />


## What it does

SmartHide hides/shows groups of UI frames accordingly.
Each group can be toggled independently, and your
choices are saved per character.

### Frame groups

| Group | What it hides |
|---|---|
| **Player / Target Frames** | 
| **Action Bar cluster** | 
| **Minimap** | 
| **Party Frames** | 

## Usage

### Slash command

```
/smarthide                  - show current on/off status for all groups
/smarthide status           - same as above
/smarthide options          - open the options panel
/smarthide toggle <key>     - flip a group on/off
/smarthide on <key>         - turn a group on
/smarthide off <key>        - turn a group off
```

Valid keys: `unitframes`, `actionbars`, `minimap`, `partyframes`

### Options panel

Open **Interface → AddOns → SmartHide**, or run `/smarthide options`. Check
the boxes for whichever groups you want hidden during combat. Changes apply
immediately — no `/reload` required.

## Installation

1. Download/clone this repository.
2. Copy the folder into your WoW `Interface/AddOns/` directory.
3. Rename folder to `SmartHide`.
4. Make sure SmartHide is checked in the AddOns list before logging in.

## Author

[WasabiMoe](https://github.com/WasabiMoe)
