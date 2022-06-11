-- This script stores the ghost's inputs into "MKW_Ghost_Inputs.csv".

-- WARNING: This will overwrite any changes you have made to "MKW_Ghost_Inputs.csv", so make sure to create a backup if you want to save your previous progress.

package.path = GetScriptsDir() .. "MKW/CSV_Handler.lua"
local csv_handler = require("CSV_Handler")
package.path = GetScriptsDir() .. "config/TASToolKit_config.lua"
local config = require("TASToolKit_config")
package.path = GetScriptsDir() .. "MKW/TTK_Lib.lua"
local TTK_Lib = require("TTK_Lib")


function onScriptStart()
	MsgBox("Script started.")

	local input_list = TTK_Lib.readFullDecodedRKGData(TTK_Lib.PlayerTypeEnum.ghost)
	
	if (input_list == nil) then
		error("The course has not been loaded!", 0)
	else
		if (csv_handler.writeCSV(config.textFilePath.ghost, input_list) == 1) then
			error(config.textFilePath.ghost .. " is currently locked by another program, so make sure to close it there first.", 0)
		end
	end
	
	CancelScript()
end

function onScriptCancel()
	MsgBox("Script ended.")
end
