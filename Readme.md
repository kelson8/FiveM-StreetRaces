# StreetRaces FiveM

This code came from a forked repo, I cannot remember which one it was.

This is a StreetRaces resource that works with the F5 key.

My fivem-scripts repo: 
* https://github.com/kelson8/fivem-scripts/

So far I have the following items working in the gui:
* Markers for creating races
* Saving races
* Listing races
* Deleting races
* Cancel race
* Load race
* Start race

Still needs done: 
* Leave race
* Unload race - Unload the race if it's not started

What I'm going to try to work on for later:
* Make this read the list of races from the json so the user can just select it from a list for loading, and deleting.
* Add MySql db support with OxMySql since I figured it out in my other resources.

## New additions
Keybind to bring up menu (F5) {I will try to add a config for this later on.}

I disabled the races_cl.lua in the fxmanifest and moved all the functions over to my gui, it started working once I did that.

## Requirements
This project requires ScaleformUI, which can be downloaded from here
* GitHub: https://github.com/manups4e/ScaleformUI/tree/master
* Official ScaleformUI forum page: https://forum.cfx.re/t/scaleformui-a-lightweight-fast-and-fun-api/4836252

## Credits

All credit goes to the below author, I did not create this only expanded onto it. This will be released on github once I have it completed.

Original creator: bepo13

Original repo is here: https://github.com/bepo13/FiveM-StreetRaces