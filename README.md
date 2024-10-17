# GSS Mod Manager
Mod Manager for Grocery Store Simulator built using Godot.

### [Video tutorial on how to use](https://youtu.be/LgSaEsA-7F8)
### [Download](https://github.com/nieboczek/gss-mod-manager/releases/latest)
## How to contribute
### Prerequisites:
- Godot 4.3.stable

Fork the repository and apply changes.  
After you're done making changes, you can make a pull request.

To test you will need the latest release, unzip it and grab 7z.exe, 7z.dll and the UE4SS folder.
Then put it into where you built your release.

# Notes
When installing a mod, don't open non-mod zip files, they will be unpacked and land in your mods folder.

# Config standard
Your config should be named `config.lua`, other names will not be detected.
Your config should start with
```lua
local config = {
```

## Annotations
Each field in the config object **MUST** have the following annotations
```lua
	--@description Key that needs to be pressed with the modifier keys to trigger the money addition
	--@type Key
	--@default Key.F1
	key = Key.F2,
	...
```
You can add more description annotations for new lines
```lua
	--@description line1
	--@description line2
	-- normal comments are ignored
	...
```
When using integers or floats you may specify a range
```lua
	--@type float range=0.001..6.999
	--@default 7
	-- you will get an error for having an invalid default value
	pizza = 0,
	-- you will also get an error for having an invalid value
	...
```
Floats can have a max precision
```lua
	--@type float range=1..2 precision=2
	--@default 1.000
	-- you will get an error for invalid value above
	...
```

Enums (just a list of strings, and the user has to select one) will be coming soon!

If you have any questions ask them on the [GSS Modding Community Discord server](https://discord.gg/5ENg4XGpPZ) or [in GitHub issues](https://github.com/nieboczek/gss-mod-manager)

### Example config
```lua
local config = {
	--@description Amount of cash to add when keybind is pressed.
	--@description Specify multiple "--@description"s to make a new line
	--@description or make it clear to read when editing manually, required field
	--@type float precision=2
	--@default 1000
	-- normal comments will be ignored. you can add ranges to numbers, e.g. "--@type float range=0.1..0.6"
	-- precision=2 means a float cannot have more than 2 numbers after a dot
	-- type & default fields are required, default is here to be able to reset to defaults
	-- name for this variable will be "Add Cash Amount"
	add_cash_amount = 4242.42,
	--@description Key that needs to be pressed with the modifier keys to trigger the money addition
	--@type Key
	--@default Key.F1
	-- name for this variable will be "Key"
	key = Key.PAUSE,
	--@description Modifier keys that need to be pressed with the key to trigger the money addition
	--@type list[ModifierKey]
	--@default { ModifierKey.CONTROL }
	-- list[x] and dict[x] are instead of table[x]
	-- name for this variable will be "Modifier Keys"
	modifier_keys = {ModifierKey.CONTROL,ModifierKey.ALT}
}
return config
```
