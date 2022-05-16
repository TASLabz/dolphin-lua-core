# Dolphin Lua Core (custom Dolphin build)

This project adds Lua support and TAStudio interface in the revision 5.0 of Dolphin Emulator. The Lua API is based on Dragonbane0's Zelda Edition, which can be found [here](https://github.com/dragonbane0/dolphin).

## Lua Core

### Running scripts

To run already implemented Lua scripts, go to `Tools` - `Execute Script`. In the new window, select the desired script (note that only Lua scripts in `Scripts` folder are shown in the list) and click on `Start` whenever you want to execute it. To stop the script execution, click on `Cancel`.

**Important**: Please note that closing the `Execute Script` window does NOT stop the script execution. You have to click on `Cancel` while the desired script is selected to do so.

### Writing new scripts

You can write new scripts following the template of `Example.lua` (or any other implemented script) and save them in `Scripts` folder of the build. Dolphin will automatically recognize them after that.

Available functions:

```
ReadValue8(memoryAddress as Number) //Reads 1 Byte from the address
ReadValue16(memoryAddress as Number) //Reads 2 Byte from the address
ReadValue32(memoryAddress as Number) //Reads 4 Byte from the address
ReadValueFloat(memoryAddress as Number)  //Reads 4 Bytes as a Float from the address
ReadValueString(memoryAddress as Number, length as Number) //Reads "length" amount of characters from the address as a String

WriteValue8(memoryAddress as Number, value as Number) //Writes 1 Byte to the address
WriteValue16(memoryAddress as Number, value as Number) //Writes 2 Byte to the address
WriteValue32(memoryAddress as Number, value as Number) //Writes 4 Byte to the address
WriteValueFloat(memoryAddress as Number, value as Number)  //Writes 4 Bytes as a Float to the address
WriteValueString(memoryAddress as Number, text as String) //Writes the string to the address

GetPointerNormal(memoryAddress as Number) //Reads the pointer address from the memory, checks if its valid and if so returns the normal address. You can use this function for example to get Links Pointer from the address 0x3ad860. To the return value you simply need to add the offset 0x34E4 and then do a ReadValueFloat with the resulting address to get Links speed (in TWW)

SaveState(useSlot as Boolean, slotID/stateName as Number/String) //Saves the current state in the indicated slot number or fileName
LoadState(useSlot as Boolean, slotID/stateName as Number/String) //Loads the state from the indicated slot number or fileName

GetFrameCount() //Returns the current visual frame count. Can use this and a global variable for example to check for frame advancements and how long the script is running in frames

GetInputFrameCount() //Returns the current input frame count

MsgBox(message as String, delayMS as Number) //Dolphin will show the indicated message in the upper-left corner for the indicated length (in milliseconds). Default length is 5 seconds
SetScreenText(message as String) //Displays Text on Screen
RenderText(text, start_x, start_y, colour, size) // Displays custom text on screen. (0,0) is the top left. Colour is the hex code 0xRRGGBB. The regular size is 11.

CancelScript() //Cancels the script
```

For the following input/controller functions:
- ControllerID corresponds to the controller you want to press inputs on
- 0 to 3 correspond to GameCube controllers 1 to 4
- 4 to 7 correspond to WiiMotes 1 to 4
- This parameter is optional. If no ID is given (or -1), the function will apply to all controllers
- The Classic Controller is currently unsupported
- If the specified controller doesn't have the specified button, or the button is an invalid string, then the function call will be ignored
- For the IR functions, (0, 0) is the top-right of the screen
- Functions with input ranges have undefined behavior when provided inputs outside that range

```
PressButton(Button, ControllerID)
-- Presses a button for the next input poll
-- Button is one of the following: "A", "B", "X", "Y", "Z", "L", "ZL", "R", "ZR", "Start", "UP" or "D-Up", "DOWN" or "D-Down", "LEFT" or "D-Left", "RIGHT" or "D-Right", "C", "+", "-", "HOME", "1", "2"
- For GameCube controllers, "L" and "R" set the shoulder button analog to 255.

ReleaseButton(Button, ControllerID)
-- Ensures the button is not pressed on the next input poll

GetWiimoteKey(ControllerID)
-- Returns the controller for the current input poll and a string containing its extension decryption key
-- The key will be all 0s if the Wiimote does not have an extension
-- e.g. cID, key = GetWiimoteKey(4)

SetIRX(X, ControllerID)
SetIRY(Y, ControllerID)
-- Sets the IR X/Y value of the provided controller
-- X/Y is an integer between 0 and 1023 (inclusive)

GetIR(ControllerID)
-- Returns the IR coordinates of the specified controller if the current input poll corresponds to that controller, otherwise it returns nil
-- e.g. x, y = GetIR(4)

SetAccelX(X, ControllerID)
SetAccelY(Y, ControllerID)
SetAccelZ(Z, ControllerID)
-- Sets the corresponding accelerometer values for the given Wiimote
-- X/Y/Z is an integer between 0 and 1023 (inclusive)

GetAccel(ControllerID)
-- Returns the accelerometer data for the specified controller if the current input poll corresponds to that controller, otherwise it returns nil
-- e.g. x, y, z = GetAccel(ControllerID)

SetNunchuckAccelX(X, ControllerID)
SetNunchuckAccelY(Y, ControllerID)
SetNunchuckAccelZ(Z, ControllerID)
-- Sets the corresponding accelerometer values for the nuncheck extension of the provided Wiimote (if present)
-- X/Y/Z is an integer between 0 and 1023 (inclusive) where 512 represents no acceleration

GetNunchuckAccel(ControllerID)
-- Returns the accelerometer data for the nunchuck extension of the provided Wiimote (if present)

SetMainStickX(X, ControllerID)
SetMainStickY(Y, ControllerID)
-- Sets the X/Y coordinate for the main control stick
-- For Wiimotes, this sets the nunchuck stick (if present)
-- X/Y is an integer between 0 and 255 (inclusive)

SetCStickX(X, ControllerID)
SetCStickY(Y, ControllerID)
-- Sets the X/Y coordinate for the secondary control stick
-- X/Y is an integer between 0 and 255 (inclusive)

SetIRBytes(ControllerID, bytes, ...)
-- Input as many bytes as you want to override
-- NOTE: ControllerID is NOT optional for this function
-- If you attempt to write more bytes than the controller sends, it will write the maximum amount of bytes possible
-- e.g. SetIRBytes(4, 0xFF, 0xA0)
-- Returns the number of bytes written (for one controller)
```

Implemented callbacks:

```
function onScriptStart()
    -- called when Start button is pressed
end

function onScriptCancel()
    -- called when Cancel button is pressed or if CancelScript() is executed
end

function onScriptUpdate()
	-- called once every frame
end

function onStateLoaded()
	-- called when a savestate was loaded successfully by the Lua script
end

function onStateSaved()
	-- called when a savestate was saved successfully by the Lua script
end
```

### Implemented features

* Input read/write in real time.
* When savestates are loaded, the inputs before it are populated automatically.
* Button input manipulation (set, clear and toggle).
* Stick input manipulation (TAS Input style).
* Insert blank inputs.
* Copy/Paste inputs.

### TODO

- Completely rewrite this readme

NOTE: If you want to build this version: Use Microsoft Visual Studio 2017 without any upgrades or use Microsoft Visual Studio 2015 Update 2 and Windows 10 SDK 10.0.10586.0
