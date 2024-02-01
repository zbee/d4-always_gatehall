# Always Gatehall

This script will take you to Gatehall in Diablo 4, the current best town by far,
whenever you press G!

The release assumes your keybinds are as follows:
- `M` for map
- `F` for filters on the map (not currently something you can rebind)
- `enter` to confirm dialogs (to finish the teleport) (not currently something
  you can rebind)
- and `G` to Go to Gatehall! (this does not rely on a keybind in game, but I
  prefer to rebind it to be the same key as my Town Portal hotkey, which it will
  prevent you from pressing and instead take you to gatehall)

I guess technically this is botting and you could get banned for that ... ?
But since it's just teleporting you to Gatehall and would be used irregularly
I don't think it would ever be found or punished.

It only looks at the screen, no memory or files, and doesn't edit anything: it 
just moves your mouse around, and clicks your keybinds.

Of course, it is still use at your own risk.


# Use

- [Download the latest release](https://github.com/zbee/d4-always_gatehall/releases/download/v1/always_gatehall.zip) (if your map is `M` and `G` is fine for Gatehall)
- Extract the `.exe` and the images into a folder where ever
- Run the `.exe` whenever you're grinding Diablo, and press `G` whenever you
  want to go to the best town!

If the keybinds are not acceptable:
- [Download the repository](https://github.com/zbee/d4-always_gatehall/archive/refs/heads/main.zip)
- Extract the `.ahk` and the images into a folder where ever
- Edit the `.ahk` to your keybinds (search for `; Core keybinds` in the file, 
  and edit both the letters in `{M}` and `g::` to be the 2 keys you want)
- Compile the script with AHK2
- Run the `.exe` whenever you're grinding Diablo, and press your hotkey whenever
  you want to go to the best town!


### Functionality

- It will open your map
  - If your map was already open, it will then reopen the map
- If your journal was open, it will close it
- It will get to the world map from whatever map you're on
- Then it will zoom out your map
- Then it will disable Waypoints on your map
- Then it will find the gatehall waypoint
    - If it can't find gate hall it will drag your map to the bottom left, then
      re-search as it drags it towards the top right
- Then it will turn the Waypoints back on
- Then it will TP you to Gatehall if was found
  - If the click fails, it will try up to 2 more times


## Compatibility

This was tested on small and medium text, at 2 different brightness settings
near the default, in Season 3 (obviously. though, hopefully the Gatehall sticks
around), at 16:9 2160p and 21:9 1440p.


## Caveats

If you're in a special map zone that is NOT the overworld that does not show the
"1", "2", etc labels next to the different world areas (only such zone I have
found is Gatehall), then it relies on very specific colors that are dependent on
your brightness settings to click your map to the overworld.

If the script freaks out for some reason (eg, it is scrolling the map but can't
find Gatehall) it will stop working if Diablo loses focus (so: alt-tab) or if
you hold Escape.


## Customization

Keybinds, and colors-searched-for, are both at the top of the script for you to
edit.

Other color tolerances (for the images-searched-for) can be found by searching
the script for ` "*` and increased as necessary.
