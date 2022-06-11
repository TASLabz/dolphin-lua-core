-- TAS Toolkit (Ghost Only Edition)
-- This script plays back the inputs located in "MKW_Ghost_Inputs.csv" without overriding player inputs.

package.path = GetScriptsDir() .. "/MKW/MKW_core.lua"
local core = require("MKW_core")
package.path = GetScriptsDir() .. "/MKW/MKW_ghost_core.lua"
local ghost_core = require("MKW_ghost_core")
package.path = GetScriptsDir() .. "MKW/CSV_Handler.lua"
local csv_handler = require("CSV_Handler")
package.path = GetScriptsDir() .. "MKW/TTK_Lib.lua"
local TTK_Lib = require("TTK_Lib")
package.path = GetScriptsDir() .. "config/TASToolKit_config.lua"
local config = require("TASToolKit_config")

local input_ghost = {}
local input_runner = {}

local runner_loaded = false
local ghost_loaded = false

local prevFrame = core.getFrameOfInput() + 1

-- ###############################

function containsFrame(input_table, frame)
	return input_table[frame] ~= nil
end

-- ###############################

function onScriptStart()
	MsgBox("Script started.")
	
	ghost_loaded, input_ghost = csv_handler.loadCSV(config.textFilePath.ghost)
	
	if (core.isSinglePlayer()) then
		ghost_loaded = false
	end

	MsgBox(string.format("%s", tostring(ghost_loaded)))

	if (ghost_loaded) then
		ghost_core.writeInputsIntoRKG(input_ghost)
	end
end

function onScriptCancel()
	MsgBox("Script ended.")
end

function onScriptUpdate()
	local currentFrame = core.getFrameOfInput() + 1

	if (runner_loaded) then
		if containsFrame(input_runner, currentFrame) then
			TTK_Lib.runInput(input_runner[currentFrame])
		end
	end

	if (prevFrame > currentFrame) or ((prevFrame + 3) < currentFrame) then
		ghost_loaded, input_ghost = csv_handler.loadCSV(config.textFilePath.ghost)
		if (core.isSinglePlayer()) then
			ghost_loaded = false
		end
		if (ghost_loaded) then
			ghost_core.writeInputsIntoRKG(input_ghost)
		end
	end

	prevFrame = currentFrame

end

function onStateLoaded()
	ghost_loaded, input_ghost = csv_handler.loadCSV(config.textFilePath.ghost)
	if (core.isSinglePlayer()) then
		ghost_loaded = false
	end
	if (ghost_loaded) then
		ghost_core.writeInputsIntoRKG(input_ghost)
	end
	
	prevFrame = core.getFrameOfInput() + 1
end

function onStateSaved()

end
