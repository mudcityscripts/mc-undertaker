# MC Undertaker Script

Bury dead players at undertaker PEDs, teleport them to a morgue with a Death PED encounter,
and release them after a configurable time. Supports QB-Core, ox_inventory, ox_lib, and ps-adminmenu.


**Author**: Developed by [mc-scripts]  
**Version**: 1.2

## Features
- Undertaker PEDs at Paleto Bay and Vinewood Cemeteries to bury dead players.
- Teleports buried players to a morgue (default: IAA basement, compatible with custom MLOs).
- Creepy Death PED in the morgue automatically revives players after a short animation.
- Configurable morgue timer with on-screen countdown (default: 60 seconds for testing).
- Wipes player inventory on burial using `ox_inventory` (toggleable).
- Roleplay elements: burial animation, morgue experience, and release to Pillbox Hospital.
- Configurable PED spawn hours, burial cost, and morgue coordinates.
- Compatible with `qb-ambulancejob` for proper revive mechanics.

## Installation
1. Add `mc-undertaker` folder to your server’s `resources` directory.
2. Add `ensure mc-undertaker` to `server.cfg`.
3. (Optional) Install a morgue MLO or use the default coords and lock the doors to the room.
4. (Optional) Add ambient sounds or customize the morgue experience by editing `client.lua`.

## Configuration
- Edit `config.lua` to adjust:
  - `Config.MorgueTime`: Time players spend in the morgue (default: 600 for 10mins).
  - `Config.BurialCost`: Cost to bury a player (default: $1,000,000).set high enough to prevent abuse but low enough so anyone has access for fairness
  - `Config.Peds`: Locations and models of undertaker PEDs.
  - `Config.MorgueCoords`: Coordinates for the morgue (default: IAA basement).
  - `Config.DeathPed`: Model and coordinates of the Death PED in the morgue.
  - `Config.ClearInventory`: Toggle inventory wipe on burial (default: true).