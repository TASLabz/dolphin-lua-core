// Copyright 2013 Dolphin Emulator Project
// Licensed under GPLv2
// Refer to the license.txt file included.

// Contributions by luckytyphlosion are
// licensed under GPLv2+

#include <mbedtls/md5.h>
#include <lua.hpp>
#include <lua.h>
#include <luaconf.h>

#include "Common/ChunkFile.h"
#include "Common/CommonPaths.h"
#include "Common/Hash.h"
#include "Common/NandPaths.h"
#include "Common/Thread.h"
#include "Common/Timer.h"
#include "Core/ConfigManager.h"
#include "Core/Core.h"
#include "Core/CoreTiming.h"
#include "Common/FileSearch.h"
#include "Common/FileUtil.h"
#include "Common/StringUtil.h"
#include "Core/Movie.h"
#include "Core/LUA/Lua.h"
#include "Core/NetPlayProto.h"
#include "Core/State.h"
#include "Core/DSP/DSPCore.h"
#include "Core/HW/DVDInterface.h"
#include "Core/HW/EXI_Device.h"
#include "Core/HW/ProcessorInterface.h"
#include "Core/HW/SI.h"
#include "Core/HW/Wiimote.h"
#include "Core/HW/WiimoteEmu/WiimoteEmu.h"
#include "Core/HW/WiimoteEmu/WiimoteHid.h"
#include "Core/HW/WiimoteEmu/Attachment/Classic.h"
#include "Core/HW/WiimoteEmu/Attachment/Nunchuk.h"
#include "Core/IPC_HLE/WII_IPC_HLE_Device_usb.h"
#include "Core/PowerPC/PowerPC.h"
#include "InputCommon/GCPadStatus.h"
#include "VideoCommon/Statistics.h"
#include "VideoCommon/VideoConfig.h"
#include "Core/Host.h"

//#include "DolphinWX/Main.h"
//#include "DolphinWX/Frame.h"

static const int ANY_CONTROLLER = -1;
static const int NUNCHUK = 1;
static const int CLASSIC = 2;

//Lua Functions (C)
int ReadValue8(lua_State* L)
{
	int argc = lua_gettop(L);

	if (argc < 1)
	{
		return 0;
	}
	u8 result = 0;
	// if there's one argument read address from the first argument
	if (argc < 2)
	{
		u32 address = lua_tointeger(L, 1);

		result = Memory::Read_U8(address);

		lua_pushinteger(L, result); // return value
		return 1;                   // number of return values
	}
	// if more than 1 argument, read multilelve pointer
	
	if (Lua::ExecuteMultilevelLoop(L) != 0)
	{
		result =Memory::Read_U8(Lua::ExecuteMultilevelLoop(L));
	}

	lua_pushinteger(L, result);
	return 1; // number of return values
}

int ReadValue16(lua_State* L)
{
	int argc = lua_gettop(L);

	if (argc < 1)
		return 0;

	u16 result = 0;
	// if there's one argument read address from the first argument
	if (argc < 2)
	{
		u32 address = lua_tointeger(L, 1);

		result = Memory::Read_U16(address);

		lua_pushinteger(L, result); // return value
		return 1;
	}
	// if more than 1 argument, read multilelve pointer
	if (Lua::ExecuteMultilevelLoop(L) != 0)
	{
		result = Memory::Read_U16(Lua::ExecuteMultilevelLoop(L));
	}

	lua_pushinteger(L, result);
	return 1; // number of return values
}

int ReadValue32(lua_State* L)
{
	int argc = lua_gettop(L);

	if (argc < 1)
		return 0;

	u32 result = 0;
	// if there's one argument read address from the first argument
	if (argc < 2)
	{
		u32 address = lua_tointeger(L, 1);

		result = Memory::Read_U32(address);

		lua_pushinteger(L, result); // return value
		return 1;
	}
	// if more than 1 argument, read multilelve pointer
	if (Lua::ExecuteMultilevelLoop(L) != 0)
	{
		result = Memory::Read_U32(Lua::ExecuteMultilevelLoop(L));
		// result = Memory::Read_U8(LastOffset);
	}

	lua_pushinteger(L, result); // return value
	return 1; // number of return values
}

int ReadValueFloat(lua_State* L)
{
	int argc = lua_gettop(L);

	if (argc < 1)
		return 0;

	float result = 0;
	// if there's one argument read address from the first argument
	if (argc < 2)
	{
		u32 address = lua_tointeger(L, 1);

		result = PowerPC::Read_F32(address);

		lua_pushnumber(L, result); // return value
		return 1;
	}
	// if more than 1 argument, read multilelve pointer
	if (Lua::ExecuteMultilevelLoop(L) != 0)
	{
		result = PowerPC::Read_F32(Lua::ExecuteMultilevelLoop(L));
	}

	lua_pushnumber(L, result); // return value
	return 1;                   // number of return values
}

int ReadValueString(lua_State* L)
{
	int argc = lua_gettop(L);

	if (argc < 2)
		return 0;
	// can't do the multilevel loop properly unless i'm not lazy
	u32 address = lua_tointeger(L, 1);
	int count = lua_tointeger(L, 2);

	std::string result = PowerPC::Read_String(address, count);

	lua_pushstring(L, result.c_str()); // return value
	return 1; // number of return values
}

//Write Stuff
int WriteValue8(lua_State* L)
{
	if (Movie::IsPlayingInput())
		return 0;
	
	int argc = lua_gettop(L);

	if (argc < 2)
		return 0;

	u32 address = lua_tointeger(L, 1);
	u8 value = lua_tointeger(L, 2);

	Memory::Write_U8(value, address);

	return 0; // number of return values
}

int WriteValue16(lua_State* L)
{
	if (Movie::IsPlayingInput())
		return 0;
	
	int argc = lua_gettop(L);

	if (argc < 2)
		return 0;

	u32 address = lua_tointeger(L, 1);
	u16 value = lua_tointeger(L, 2);

	Memory::Write_U16(value, address);

	return 0; // number of return values
}

int WriteValue32(lua_State* L)
{
	if (Movie::IsPlayingInput())
		return 0;
	
	int argc = lua_gettop(L);

	if (argc < 2)
		return 0;

	u32 address = lua_tointeger(L, 1);
	u32 value = lua_tointeger(L, 2);

	Memory::Write_U32(value, address);

	return 0; // number of return values
}

int WriteValueFloat(lua_State* L)
{
	if (Movie::IsPlayingInput())
		return 0;
	
	int argc = lua_gettop(L);

	if (argc < 2)
		return 0;

	u32 address = lua_tointeger(L, 1);
	double value = lua_tonumber(L, 2);

	PowerPC::Write_F32((float)value, address);

	return 0; // number of return values
}

int WriteValueString(lua_State* L)
{
	if (Movie::IsPlayingInput())
		return 0;
	
	int argc = lua_gettop(L);

	if (argc < 2)
		return 0;

	u32 address = lua_tointeger(L, 1);
	const char* value = lua_tostring(L, 2);

	std::string string = StringFromFormat("%s", value);

	PowerPC::Write_String(string, address);

	return 0; // number of return values
}

int GetPointerNormal(lua_State* L)
{
	int argc = lua_gettop(L);
	// if there are no arguments, don't execute further
	if (argc < 1)
		return 0; // don't pass any return values
	// if there is 1 argument, use the old method
	if (argc < 2)
	{
		u32 address = lua_tointeger(L, 1);
		// Since we don't need to read any offsets we can just do this
		u32 pointer = Lua::readPointer(address, 0x0);
		// return so the function doesn't execute further
		lua_pushinteger(L, pointer); // return value
		return 1;
	}		
	// new method, supports multilevel pointers
	// we need to read the main pointer once, so we can use this one in the for loop
	u32 pointer = Lua::ExecuteMultilevelLoop(L);

	lua_pushinteger(L, pointer); // return value
	return 1; // number of return values
}

int GetGameID(lua_State* L)
{
	lua_pushstring(L, SConfig::GetInstance().GetUniqueID().c_str());
	return 1;
}

int GetScriptsDir(lua_State* L)
{
	lua_pushstring(L, (SYSDATA_DIR "/Scripts/"));
	return 1;
}

int GetWiimoteKey(lua_State* L)
{
	int controller;
	char *key = Lua::iGetWiimoteKey(&controller);
	lua_pushinteger(L, controller);
	lua_pushstring(L, key);
	free(key);
	return 2;
}

int PressButton(lua_State* L)
{
	if (Movie::IsPlayingInput())
		return 0;
	
	int argc = lua_gettop(L);

	if (argc < 1)
		return 0;

	const char* button = lua_tostring(L, 1);
	int controller = ANY_CONTROLLER;

	if (argc > 1)
		controller = lua_tointeger(L, 2);

	Lua::iPressButton(button, controller);

	return 0; // number of return values
}

int ReleaseButton(lua_State* L)
{
	if (Movie::IsPlayingInput())
		return 0;
	
	int argc = lua_gettop(L);

	if (argc < 1)
		return 0;

	const char* button = lua_tostring(L, 1);
	int controller = ANY_CONTROLLER;

	if (argc > 1)
		controller = lua_tointeger(L, 2);

	Lua::iReleaseButton(button, controller);

	return 0; // number of return values
}

static int GenericSet(lua_State *L, void (*f)(int, int))
{
	if (Movie::IsPlayingInput())
		return 0;

	int argc = lua_gettop(L);

	if (argc < 1)
		return 0;

	int val = lua_tointeger(L, 1);
	int controller = ANY_CONTROLLER;

	if (argc > 1)
		controller = lua_tointeger(L, 2);

	f(val, controller);

	return 0;
}

int SetMainStickX(lua_State* L)
{
	return GenericSet(L, Lua::iSetMainStickX);
}
int SetMainStickY(lua_State* L)
{
	return GenericSet(L, Lua::iSetMainStickY);
}

int SetCStickX(lua_State* L)
{
	return GenericSet(L, Lua::iSetCStickX);
}
int SetCStickY(lua_State* L)
{
	return GenericSet(L, Lua::iSetCStickY);
}

int SetIRX(lua_State *L)
{
	return GenericSet(L, Lua::iSetIRX);
}
int SetIRY(lua_State *L)
{
	return GenericSet(L, Lua::iSetIRY);
}

int SetAccelX(lua_State *L)
{
	return GenericSet(L, Lua::iSetAccelX);
}
int SetAccelY(lua_State *L)
{
	return GenericSet(L, Lua::iSetAccelY);
}
int SetAccelZ(lua_State *L)
{
	return GenericSet(L, Lua::iSetAccelZ);
}

int SetNunchukAccelX(lua_State *L)
{
	return GenericSet(L, Lua::iSetNunchukAccelX);
}
int SetNunchukAccelY(lua_State *L)
{
	return GenericSet(L, Lua::iSetNunchukAccelY);
}
int SetNunchukAccelZ(lua_State *L)
{
	return GenericSet(L, Lua::iSetNunchukAccelZ);
}

int SaveState(lua_State* L)
{
	int argc = lua_gettop(L);

	if (argc < 2)
		return 0;

	bool useSlot = false;

	BOOL Slot = lua_toboolean(L, 1);
	int slotID = 0;
	std::string string = "";

	if (Slot)
	{
		useSlot = true;
		slotID = lua_tointeger(L, 2);
	}
	else
	{
		const char* fileName = lua_tostring(L, 2);
		string = StringFromFormat("%s", fileName);
	}

	Lua::iSaveState(useSlot, slotID, string);

	return 0; // number of return values
}

int LoadState(lua_State* L)
{
	if (Movie::IsPlayingInput())
		return 0;
	
	int argc = lua_gettop(L);

	if (argc < 2)
		return 0;

	bool useSlot = false;

	BOOL Slot = lua_toboolean(L, 1);
	int slotID = 0;
	std::string string = "";

	if (Slot)
	{
		useSlot = true;
		slotID = lua_tointeger(L, 2);
	}
	else
	{
		const char* fileName = lua_tostring(L, 2);
		string = StringFromFormat("%s", fileName);
	}

	Lua::iLoadState(useSlot, slotID, string);

	return 0; // number of return values
}

int GetFrameCount(lua_State* L)
{
	int argc = lua_gettop(L);

	lua_pushinteger(L, Movie::g_currentFrame); // return value
	return 1; // number of return values
}

int GetInputFrameCount(lua_State* L)
{
	int argc = lua_gettop(L);

	lua_pushinteger(L, Movie::g_currentInputCount + 1); // return value
	return 1; // number of return values
}

int SetScreenText(lua_State* L)
{
	int argc = lua_gettop(L);

	if (argc < 1)
		return 0;

	const char *text = lua_tostring(L, 1);

	std::string screen_text = StringFromFormat("%s", text);
	screen_text.append("\n");

	Statistics::SetString(screen_text);

	return 0;
}

int PauseEmulation(lua_State* L)
{
	int argc = lua_gettop(L);

	Core::SetState(Core::CORE_PAUSE);

	return 0;
}

int SetInfoDisplay(lua_State* L)
{
	int argc = lua_gettop(L);	
	SConfig::GetInstance().m_ShowRAMDisplay = !SConfig::GetInstance().m_ShowRAMDisplay;	
	SConfig::GetInstance().SaveSettings();
	return 0;
}

int SetFrameAndAudioDump(lua_State* L)
{
	int argc = lua_gettop(L);

	bool enableDump = (lua_toboolean(L, 1) != 0);
	SConfig::GetInstance().m_DumpFrames = enableDump;
	SConfig::GetInstance().m_DumpAudio = enableDump;
	//main_frame->GetMenuBar()->FindItem(IDM_TOGGLE_DUMP_FRAMES)->Check(enableDump);
	//main_frame->GetMenuBar()->FindItem(IDM_TOGGLE_DUMP_AUDIO)->Check(enableDump);    
	SConfig::GetInstance().SaveSettings();

	return 0;
}

int MsgBox(lua_State* L)
{
	int argc = lua_gettop(L);

	if (argc < 1)
		return 0;

	const char* text = lua_tostring(L, 1);

	int delay = 5000; //Default: 5 seconds

	if (argc == 2)
	{
		delay = lua_tointeger(L, 2);
	}

	std::string message = StringFromFormat("Lua Msg: %s", text);

	Core::DisplayMessage(message, delay);

	return 0; // number of return values
}

int CancelScript(lua_State* L)
{
	int argc = lua_gettop(L);

	Lua::iCancelCurrentScript();

	return 0; // number of return values
}

void HandleLuaErrors(lua_State* L, int status)
{
	if (status != 0)
	{
		std::string message = StringFromFormat("Lua Error: %s", lua_tostring(L, -1));

		PanicAlertT(message.c_str());

		lua_pop(L, 1); // remove error message
	}
}

namespace Lua
{
	//Dragonbane: Lua Stuff
	static std::list<LuaScript> scriptList;
	static int currScriptID;

    static int currentControllerID;
    static bool UpdateGCC;
	static GCPadStatus PadLocal;
    static u8 *WiimoteData;
    static int WiimoteExt;
    static WiimoteEmu::ReportFeatures WiimoteRptf;
    static const wiimote_key *WiimoteKey;

	const int m_gc_pad_buttons_bitmask[12] = {
		PAD_BUTTON_DOWN, PAD_BUTTON_UP, PAD_BUTTON_LEFT, PAD_BUTTON_RIGHT, PAD_BUTTON_A, PAD_BUTTON_B,
		PAD_BUTTON_X, PAD_BUTTON_Y, PAD_TRIGGER_Z, PAD_TRIGGER_L, PAD_TRIGGER_R, PAD_BUTTON_START
	};

	//LUA Savestate Stuff
	StateEvent m_stateData;

	bool lua_isStateOperation = false;
	bool lua_isStateSaved = false;
	bool lua_isStateLoaded = false;
	bool lua_isStateDone = false;


	//Dragonbane: Lua Wrapper Functions
	void iPressButton(const char* button, int controllerID)
	{
	    if (controllerID != currentControllerID && controllerID != ANY_CONTROLLER) // Xander: specify controller
		    return;

		if (!strcmp(button, "A"))
		{
			if (UpdateGCC)
			{
			    PadLocal.button |= m_gc_pad_buttons_bitmask[4];
			    PadLocal.analogA = 0xFF;
			}
		    else if (WiimoteRptf.ext && WiimoteExt == CLASSIC) // See TASInputDlg::GetValues for data setup
			{

			}
			else
			{
			    ((wm_buttons *)(WiimoteData + WiimoteRptf.core))->hex |= WiimoteEmu::Wiimote::BUTTON_A;
			}
		}
		else if (!strcmp(button, "B"))
		{
			if (UpdateGCC)
			{
			    PadLocal.button |= m_gc_pad_buttons_bitmask[5];
			    PadLocal.analogB = 0xFF;
			}
		    else if (WiimoteRptf.ext && WiimoteExt == CLASSIC)
			{

			}
			else
			{
			    ((wm_buttons *)(WiimoteData + WiimoteRptf.core))->hex |= WiimoteEmu::Wiimote::BUTTON_B;
			}
		}
		else if (!strcmp(button, "X"))
		{
			if (UpdateGCC)
			{
			    PadLocal.button |= m_gc_pad_buttons_bitmask[6];
			}
		    else if (WiimoteRptf.ext && WiimoteExt == CLASSIC)
			{

			}
		}
		else if (!strcmp(button, "Y"))
		{
		    if (UpdateGCC)
		    {
				PadLocal.button |= m_gc_pad_buttons_bitmask[7];
			}
		    else if (WiimoteRptf.ext && WiimoteExt == CLASSIC)
			{

			}
		}
		else if (!strcmp(button, "Z"))
		{
		    if (UpdateGCC)
		    {
				PadLocal.button |= m_gc_pad_buttons_bitmask[8];
			}
		    else if (WiimoteRptf.ext && WiimoteExt == NUNCHUK)
			{
			    wm_nc *nunchuk = (wm_nc *)(WiimoteData + WiimoteRptf.ext);
			    WiimoteDecrypt(WiimoteKey, (u8 *)nunchuk, 0, sizeof(wm_nc));
			    nunchuk->bt.hex &= ~WiimoteEmu::Nunchuk::BUTTON_Z;
			    WiimoteEncrypt(WiimoteKey, (u8 *)nunchuk, 0, sizeof(wm_nc));
			}
		}
		else if (!strcmp(button, "L"))
		{
			if (UpdateGCC)
		    {
			    PadLocal.triggerLeft = 255;
			    PadLocal.button |= m_gc_pad_buttons_bitmask[9];
			}
		    else if (WiimoteRptf.ext && WiimoteExt == NUNCHUK)
		    {

		    } 
		}
	    else if (!strcmp(button, "ZL"))
	    {
		    if (WiimoteRptf.ext && WiimoteExt == CLASSIC)
		    {

		    }
	    }
		else if (!strcmp(button, "R"))
		{
		    if (UpdateGCC)
		    {
				PadLocal.triggerRight = 255;
				PadLocal.button |= m_gc_pad_buttons_bitmask[10];
		    }
		    else if (WiimoteRptf.ext && WiimoteExt == NUNCHUK)
		    {

		    } 
		}
	    else if (!strcmp(button, "ZR"))
	    {
		    if (WiimoteRptf.ext && WiimoteExt == CLASSIC)
		    {

		    }
	    }
		else if (!strcmp(button, "Start"))
		{
		    if (UpdateGCC)
				PadLocal.button |= m_gc_pad_buttons_bitmask[11];
		}
	    else if (!strcmp(button, "D-Up") || !strcmp(button, "UP"))
		{
			if (UpdateGCC)
			{
				PadLocal.button |= m_gc_pad_buttons_bitmask[1];
			}
		    else if (WiimoteRptf.ext && WiimoteExt == CLASSIC)
			{

			}
			else
		    {
			    ((wm_buttons *)(WiimoteData + WiimoteRptf.core))->hex |= WiimoteEmu::Wiimote::PAD_UP;
			}
		}
	    else if (!strcmp(button, "D-Down") || !strcmp(button, "DOWN"))
		{
		    if (UpdateGCC)
		    {
			    PadLocal.button |= m_gc_pad_buttons_bitmask[0];
		    }
		    else if (WiimoteRptf.ext && WiimoteExt == CLASSIC)
		    {

		    }
		    else
		    {
			    ((wm_buttons *)(WiimoteData + WiimoteRptf.core))->hex |= WiimoteEmu::Wiimote::PAD_DOWN;
		    }
		}
	    else if (!strcmp(button, "D-Left") || !strcmp(button, "LEFT"))
		{
			if (UpdateGCC)
			{
			    PadLocal.button |= m_gc_pad_buttons_bitmask[2];
		    }
		    else if (WiimoteRptf.ext && WiimoteExt == CLASSIC)
		    {

		    }
		    else
		    {
			    ((wm_buttons *)(WiimoteData + WiimoteRptf.core))->hex |= WiimoteEmu::Wiimote::PAD_LEFT;
		    }
		}
	    else if (!strcmp(button, "D-Right") || !strcmp(button, "RIGHT"))
		{
			if (UpdateGCC)
			{
			    PadLocal.button |= m_gc_pad_buttons_bitmask[3];
		    }
		    else if (WiimoteRptf.ext && WiimoteExt == CLASSIC)
		    {

		    }
		    else
		    {
			    ((wm_buttons *)(WiimoteData + WiimoteRptf.core))->hex |= WiimoteEmu::Wiimote::PAD_RIGHT;
		    }
		}
	    else if (!strcmp(button, "C"))
	    {
		    if (WiimoteRptf.ext && WiimoteExt == NUNCHUK)
		    {
			    wm_nc *nunchuk = (wm_nc *)(WiimoteData + WiimoteRptf.ext);
			    WiimoteDecrypt(WiimoteKey, (u8 *)nunchuk, 0, sizeof(wm_nc));
			    nunchuk->bt.hex &= ~WiimoteEmu::Nunchuk::BUTTON_C;
			    WiimoteEncrypt(WiimoteKey, (u8 *)nunchuk, 0, sizeof(wm_nc));
		    }
	    }
	    else if (!strcmp(button, "Home") || !strcmp(button, "HOME"))
	    {
		    if (WiimoteRptf.ext && WiimoteExt == CLASSIC)
		    {

		    }
		    else
		    {
			    ((wm_buttons *)(WiimoteData + WiimoteRptf.core))->hex |= WiimoteEmu::Wiimote::BUTTON_HOME;
		    }
	    }
	    else if (!strcmp(button, "+"))
	    {
		    if (WiimoteRptf.ext && WiimoteExt == CLASSIC)
		    {

		    }
		    else
		    {
			    ((wm_buttons *)(WiimoteData + WiimoteRptf.core))->hex |= WiimoteEmu::Wiimote::BUTTON_PLUS;
		    }
	    }
	    else if (!strcmp(button, "-"))
	    {
		    if (WiimoteRptf.ext && WiimoteExt == CLASSIC)
		    {

		    }
		    else
		    {
			    ((wm_buttons *)(WiimoteData + WiimoteRptf.core))->hex |= WiimoteEmu::Wiimote::BUTTON_MINUS;
		    }
	    }
	    else if (!strcmp(button, "1"))
	    {
		    if (WiimoteRptf.ext && WiimoteExt == CLASSIC)
		    {
		    }
		    else
		    {
			    ((wm_buttons *)(WiimoteData + WiimoteRptf.core))->hex |= WiimoteEmu::Wiimote::BUTTON_ONE;
		    }
	    }
	    else if (!strcmp(button, "2"))
	    {
		    if (WiimoteRptf.ext && WiimoteExt == CLASSIC)
		    {
		    }
		    else
		    {
			    ((wm_buttons *)(WiimoteData + WiimoteRptf.core))->hex |= WiimoteEmu::Wiimote::BUTTON_TWO;
		    }
	    }
	}
    void iReleaseButton(const char *button, int controllerID)
    {
	    if (controllerID != currentControllerID && controllerID != ANY_CONTROLLER)
		    return;

		if (!strcmp(button, "A"))
		{
			PadLocal.button &= ~m_gc_pad_buttons_bitmask[4];
			PadLocal.analogA = 0x00;

		}
		else if (!strcmp(button, "B"))
		{
			PadLocal.button &= ~m_gc_pad_buttons_bitmask[5];
			PadLocal.analogB = 0x00;
		}
		else if (!strcmp(button, "X"))
		{
		    PadLocal.button &= ~m_gc_pad_buttons_bitmask[6];
		}
		else if (!strcmp(button, "Y"))
		{
			PadLocal.button &= ~m_gc_pad_buttons_bitmask[7];
		}
		else if (!strcmp(button, "Z"))
		{
			PadLocal.button &= ~m_gc_pad_buttons_bitmask[8];
		}
		else if (!strcmp(button, "L"))
		{
		    PadLocal.triggerLeft = 0;
			PadLocal.button &= ~m_gc_pad_buttons_bitmask[9];
		}
		else if (!strcmp(button, "R"))
		{
		    PadLocal.triggerRight = 0;
			PadLocal.button &= ~m_gc_pad_buttons_bitmask[10];
		}
		else if (!strcmp(button, "Start"))
		{
			PadLocal.button &= ~m_gc_pad_buttons_bitmask[11];
		}
	    else if (!strcmp(button, "D-Up"))
		{
			PadLocal.button &= ~m_gc_pad_buttons_bitmask[1];
		}
	    else if (!strcmp(button, "D-Down"))
		{
		    PadLocal.button &= ~m_gc_pad_buttons_bitmask[0];
		}
	    else if (!strcmp(button, "D-Left"))
		{
		    PadLocal.button &= ~m_gc_pad_buttons_bitmask[2];
		}
	    else if (!strcmp(button, "D-Right"))
		{
		    PadLocal.button &= ~m_gc_pad_buttons_bitmask[3];
		}
	}

	u32 readPointer(u32 startAddress, u32 offset)
	{
	    u32 pointer = Memory::Read_U32(startAddress) + offset;
	    // check if pointer is not in the mem1 or mem2
	    if (Lua::IsInMEMArea(pointer))
	    {
			if ((pointer > 0x80000000 && pointer < 0x81800000) || (pointer > 0x90000000 && pointer < 0x94000000))
			{
				pointer -= 0x80000000;
			}

			return pointer;
	    }
		else return 0;
	}

	u32 normalizePointer(u32 pointer)
	{
		if ((pointer > 0x80000000 && pointer < 0x81800000) || (pointer > 0x90000000 && pointer < 0x94000000))
		{
			pointer -= 0x80000000;
		}
		return pointer;
	}

	u32 ExecuteMultilevelLoop(lua_State *L)
    {
	    int argc = lua_gettop(L);
	    u32 mainPointer = lua_tointeger(L, 1);
	    // we need to read the main pointer once, so we can use this one in the for loop
	    u32 pointer = mainPointer;

	    for (int i = 2; i <= argc; ++i)
	    {
		    // read offsets
		    u32 offset = lua_tointeger(L, i);
		    // dedicated function to read the offsets and pointer
		    pointer = readPointer(pointer, offset);
		    if ((pointer == 0) || (pointer == offset))
		    {
			    pointer = 0;
			    break;			    
		    }
	    }
		return pointer;	    
    }

	void iSetMainStickX(int xVal, int controllerID)
    {
	    if (controllerID != currentControllerID && controllerID != ANY_CONTROLLER)
		    return;

		if (UpdateGCC)
		{
		    PadLocal.stickX = xVal;
		}
		else if (WiimoteRptf.ext && WiimoteExt == NUNCHUK)
	    {
		    wm_nc *nunchuk = (wm_nc *)(WiimoteData + WiimoteRptf.ext);
		    WiimoteDecrypt(WiimoteKey, (u8 *)nunchuk, 0, sizeof(wm_nc));
		    nunchuk->jx = xVal;
		    WiimoteEncrypt(WiimoteKey, (u8 *)nunchuk, 0, sizeof(wm_nc));
		}
	    else if (WiimoteRptf.ext && WiimoteExt == CLASSIC)
		{
			// JL x
		}
	}
    void iSetMainStickY(int yVal, int controllerID)
	{
	    if (controllerID != currentControllerID && controllerID != ANY_CONTROLLER)
		    return;

	    if (UpdateGCC)
	    {
			PadLocal.stickY = yVal;
	    }
	    else if (WiimoteRptf.ext && WiimoteExt == NUNCHUK)
	    {
		    wm_nc *nunchuk = (wm_nc *)(WiimoteData + WiimoteRptf.ext);
		    WiimoteDecrypt(WiimoteKey, (u8 *)nunchuk, 0, sizeof(wm_nc));
		    nunchuk->jy = yVal;
		    WiimoteEncrypt(WiimoteKey, (u8 *)nunchuk, 0, sizeof(wm_nc));
	    }
	    else if (WiimoteRptf.ext && WiimoteExt == CLASSIC)
	    {
		    // JL y
	    }
	}
    void iSetCStickX(int xVal, int controllerID)
	{
	    if (controllerID != currentControllerID && controllerID != ANY_CONTROLLER)
		    return;

	    if (UpdateGCC)
	    {
			PadLocal.substickX = xVal;
		}
	    else if (WiimoteRptf.ext && WiimoteExt == CLASSIC)
		{
			// JR x
		}
	}
    void iSetCStickY(int yVal, int controllerID)
	{
	    if (controllerID != currentControllerID && controllerID != ANY_CONTROLLER)
		    return;

	    if (UpdateGCC)
	    {
			PadLocal.substickY = yVal;
	    }
	    else if (WiimoteRptf.ext && WiimoteExt == CLASSIC)
	    {
		    // JR y
	    }
	}
    static void SetIR(int xVal, int yVal, int controllerID)
	{
	    if (controllerID != currentControllerID && controllerID != ANY_CONTROLLER)
		    return;

	    u16 x[4];
	    x[0] = xVal;
	    x[1] = x[0] + 100;
	    x[2] = x[0] - 10;
	    x[3] = x[1] + 10;
	    u16 y = yVal;

	    if ((WiimoteRptf.ext ? WiimoteRptf.ext : WiimoteRptf.size) - WiimoteRptf.ir == 10)
	    {
		    memset(WiimoteData + WiimoteRptf.ir, 0xFF, sizeof(wm_ir_basic) * 2);
		    wm_ir_basic *ir_data = (wm_ir_basic *)(WiimoteData + WiimoteRptf.ir);
		    for (unsigned int i = 0; i < 2; ++i)
		    {
			    if (x[i * 2] < 1024 && y < 768)
			    {
				    ir_data[i].x1 = static_cast<u8>(x[i * 2]);
				    ir_data[i].x1hi = x[i * 2] >> 8;

				    ir_data[i].y1 = static_cast<u8>(y);
				    ir_data[i].y1hi = y >> 8;
			    }
			    if (x[i * 2 + 1] < 1024 && y < 768)
			    {
				    ir_data[i].x2 = static_cast<u8>(x[i * 2 + 1]);
				    ir_data[i].x2hi = x[i * 2 + 1] >> 8;

				    ir_data[i].y2 = static_cast<u8>(y);
				    ir_data[i].y2hi = y >> 8;
			    }
		    }
		}
		else // assumes reporting mode 3 (not 5)
		{
			memset(WiimoteData + WiimoteRptf.ir, 0xFF, sizeof(wm_ir_extended) * 4);
			wm_ir_extended *const ir_data = (wm_ir_extended *)(WiimoteData + WiimoteRptf.ir);
			for (unsigned int i = 0; i < 4; ++i)
			{
			    if (x[i] < 1024 && y < 768)
			    {
				    ir_data[i].x = static_cast<u8>(x[i]);
				    ir_data[i].xhi = x[i] >> 8;

				    ir_data[i].y = static_cast<u8>(y);
					ir_data[i].yhi = y >> 8;

				    ir_data[i].size = 10;
			    }
		    }
		}
	   
	}
    void iSetIRX(int xVal, int controllerID)
    {
	    if (!UpdateGCC && WiimoteRptf.ir)
	    {
		    u8 *irdata = (WiimoteData + WiimoteRptf.ir);
		    int y = irdata[1] + ((irdata[2] & 0xC0) << 2);
		    SetIR(xVal, y, controllerID);
	    }
    }
    void iSetIRY(int yVal, int controllerID)
	{
	    if (!UpdateGCC && WiimoteRptf.ir)
		{
		    u8 *irdata = (WiimoteData + WiimoteRptf.ir);
		    int x = irdata[0] + ((irdata[2] & 0x30) << 4); // read first x coord
		    SetIR(x, yVal, controllerID);
		}
	}
    void iSetAccelX(int xVal, int controllerID)
    {
	    if (UpdateGCC || (controllerID != currentControllerID && controllerID != ANY_CONTROLLER))
		    return;

	    wm_accel *dt = (wm_accel *)(WiimoteData + WiimoteRptf.accel);
	    wm_buttons *but = (wm_buttons *)(WiimoteData + WiimoteRptf.core);
	    dt->x = xVal >> 2;
	    but->acc_x_lsb = xVal & 0x3;
    }
    void iSetAccelY(int yVal, int controllerID)
    {
	    if (UpdateGCC || (controllerID != currentControllerID && controllerID != ANY_CONTROLLER))
		    return;

	    wm_accel *dt = (wm_accel *)(WiimoteData + WiimoteRptf.accel);
	    wm_buttons *but = (wm_buttons *)(WiimoteData + WiimoteRptf.core);
	    dt->y = yVal >> 2;
	    but->acc_y_lsb = yVal >> 1 & 0x1;
    }
    void iSetAccelZ(int zVal, int controllerID)
    {
	    if (UpdateGCC || (controllerID != currentControllerID && controllerID != ANY_CONTROLLER))
		    return;

	    wm_accel *dt = (wm_accel *)(WiimoteData + WiimoteRptf.accel);
	    wm_buttons *but = (wm_buttons *)(WiimoteData + WiimoteRptf.core);
	    dt->z = zVal >> 2;
	    but->acc_z_lsb = zVal >> 1 & 0x1;
    }
    void iSetNunchukAccelX(int xVal, int controllerID)
    {
	    if (UpdateGCC || (controllerID != currentControllerID && controllerID != ANY_CONTROLLER))
		    return;

	    if (WiimoteRptf.ext && WiimoteExt == NUNCHUK)
	    {
		    wm_nc *nunchuk = (wm_nc *)(WiimoteData + WiimoteRptf.ext);
		    WiimoteDecrypt(WiimoteKey, (u8 *)nunchuk, 0, sizeof(wm_nc));
		    nunchuk->ax = xVal >> 2;
		    nunchuk->bt.acc_x_lsb = xVal & 0x3;
		    WiimoteEncrypt(WiimoteKey, (u8 *)nunchuk, 0, sizeof(wm_nc));
	    }
    }
    void iSetNunchukAccelY(int yVal, int controllerID)
    {
	    if (UpdateGCC || (controllerID != currentControllerID && controllerID != ANY_CONTROLLER))
		    return;

	    if (WiimoteRptf.ext && WiimoteExt == NUNCHUK)
	    {
		    wm_nc *nunchuk = (wm_nc *)(WiimoteData + WiimoteRptf.ext);
		    WiimoteDecrypt(WiimoteKey, (u8 *)nunchuk, 0, sizeof(wm_nc));
		    nunchuk->ay = yVal >> 2;
		    nunchuk->bt.acc_y_lsb = yVal & 0x3;
		    WiimoteEncrypt(WiimoteKey, (u8 *)nunchuk, 0, sizeof(wm_nc));
	    }
    }
    void iSetNunchukAccelZ(int zVal, int controllerID)
    {
	    if (UpdateGCC || (controllerID != currentControllerID && controllerID != ANY_CONTROLLER))
		    return;

		if (WiimoteRptf.ext && WiimoteExt == NUNCHUK)
		{
		    wm_nc *nunchuk = (wm_nc *)(WiimoteData + WiimoteRptf.ext);
		    WiimoteDecrypt(WiimoteKey, (u8 *)nunchuk, 0, sizeof(wm_nc));
		    nunchuk->az = zVal >> 2;
		    nunchuk->bt.acc_z_lsb = zVal & 0x3;
		    WiimoteEncrypt(WiimoteKey, (u8 *)nunchuk, 0, sizeof(wm_nc));
		}
    }
	char *iGetWiimoteKey(int *controllerID)
	{	
		*controllerID = currentControllerID;
		char *key = (char *)malloc(48 * sizeof(char));
	    key[0] = 0; // empty string on gcc update calls
	    if (!UpdateGCC)
		{
		    sprintf(key, "%02X %02X %02X %02X %02X %02X %02X %02X ", WiimoteKey->ft[0], WiimoteKey->ft[1],
		            WiimoteKey->ft[2], WiimoteKey->ft[3], WiimoteKey->ft[4], WiimoteKey->ft[5], WiimoteKey->ft[6],
		            WiimoteKey->ft[7]);
		    sprintf(key + 24, "%02X %02X %02X %02X %02X %02X %02X %02X", WiimoteKey->sb[0], WiimoteKey->sb[1],
		            WiimoteKey->sb[2], WiimoteKey->sb[3], WiimoteKey->sb[4], WiimoteKey->sb[5], WiimoteKey->sb[6],
		            WiimoteKey->sb[7]);
		}
	    return key;
	}
	int GetIR(lua_State *L) {
	    int x = -1;
	    int y = -1;
	    int controller = ANY_CONTROLLER;
	    if (lua_gettop(L) > 0)
		    controller = lua_tointeger(L, 1);
		if (!UpdateGCC && (controller == currentControllerID || controller == ANY_CONTROLLER))
		{
		    u8 *irdata = WiimoteData + WiimoteRptf.ir;
		    x = irdata[0] + ((irdata[2] & 0x30) << 4); // read first x coord
		    y = irdata[1] + ((irdata[2] & 0xC0) << 2);
		}
	    lua_pushinteger(L, x);
	    lua_pushinteger(L, y);
		return 2;
	}
	void iSaveState(bool toSlot, int slotID, std::string fileName)
	{
		m_stateData.doSave = true;
		m_stateData.useSlot = toSlot;
		m_stateData.slotID = slotID;
		m_stateData.fileName = fileName;	

		lua_isStateSaved = false;
		lua_isStateLoaded = false;
		lua_isStateDone = false;
		lua_isStateOperation = true;

		if (currScriptID != -1)
		{
			int n = 0;

			for (std::list<LuaScript>::iterator it = scriptList.begin(); it != scriptList.end(); ++it)
			{
				if (currScriptID == n)
				{
					it->wantsSavestateCallback = true;
					break;
				}

				++n;
			}
		}

		Host_UpdateMainFrame();
	}
	void iLoadState(bool fromSlot, int slotID, std::string fileName)
	{
		m_stateData.doSave = false;
		m_stateData.useSlot = fromSlot;
		m_stateData.slotID = slotID;
		m_stateData.fileName = fileName;

		lua_isStateSaved = false;
		lua_isStateLoaded = false;
		lua_isStateDone = false;
		lua_isStateOperation = true;

		if (currScriptID != -1)
		{
			int n = 0;

			for (std::list<LuaScript>::iterator it = scriptList.begin(); it != scriptList.end(); ++it)
			{
				if (currScriptID == n)
				{
					it->wantsSavestateCallback = true;
					break;
				}

				++n;
			}
		}

		Host_UpdateMainFrame();
	}
	void iCancelCurrentScript()
	{
		int n = 0;

		for (std::list<LuaScript>::iterator it = scriptList.begin(); it != scriptList.end(); ++it)
		{
			if (currScriptID == n)
			{
				it->requestedTermination = true;
				break;
			}

			++n;
		}
	}


	//Main Functions
	static void RegisterGeneralLuaFunctions(lua_State* luaState)
	{
		//Make C functions available to Lua programs
		lua_register(luaState, "ReadValue8", ReadValue8);
		lua_register(luaState, "ReadValue16", ReadValue16);
		lua_register(luaState, "ReadValue32", ReadValue32);
		lua_register(luaState, "ReadValueFloat", ReadValueFloat);
		lua_register(luaState, "ReadValueString", ReadValueString);
		lua_register(luaState, "GetPointerNormal", GetPointerNormal);

		lua_register(luaState, "WriteValue8", WriteValue8);
		lua_register(luaState, "WriteValue16", WriteValue16);
		lua_register(luaState, "WriteValue32", WriteValue32);
		lua_register(luaState, "WriteValueFloat", WriteValueFloat);
		lua_register(luaState, "WriteValueString", WriteValueString);

		lua_register(luaState, "GetGameID", GetGameID);
	    lua_register(luaState, "GetScriptsDir", GetScriptsDir);

		lua_register(luaState, "PressButton", PressButton);
		lua_register(luaState, "ReleaseButton", ReleaseButton);
		lua_register(luaState, "SetMainStickX", SetMainStickX);
		lua_register(luaState, "SetMainStickY", SetMainStickY);
		lua_register(luaState, "SetCStickX", SetCStickX);
		lua_register(luaState, "SetCStickY", SetCStickY);

	    lua_register(luaState, "GetWiimoteKey", GetWiimoteKey); // Xander: wiimote + extension controls
	    lua_register(luaState, "SetIRX", SetIRX);
	    lua_register(luaState, "SetIRY", SetIRY);
	    lua_register(luaState, "GetIR", Lua::GetIR);
	    lua_register(luaState, "SetAccelX", SetAccelX);
	    lua_register(luaState, "SetAccelY", SetAccelY);
	    lua_register(luaState, "SetAccelZ", SetAccelZ);
	    lua_register(luaState, "SetNunchukAccelX", SetNunchukAccelX);
	    lua_register(luaState, "SetNunchukAccelY", SetNunchukAccelY);
	    lua_register(luaState, "SetNunchukAccelZ", SetNunchukAccelZ);

		lua_register(luaState, "SaveState", SaveState);
		lua_register(luaState, "LoadState", LoadState);

		lua_register(luaState, "GetFrameCount", GetFrameCount);
		lua_register(luaState, "GetInputFrameCount", GetInputFrameCount);
		lua_register(luaState, "MsgBox", MsgBox);
		
		lua_register(luaState, "SetScreenText", SetScreenText);
		lua_register(luaState, "PauseEmulation", PauseEmulation);
		lua_register(luaState, "SetInfoDisplay", SetInfoDisplay); 

		// added by luckytyphlosion
		lua_register(luaState, "SetFrameAndAudioDump", SetFrameAndAudioDump);
	}

	void Init()
	{
		//For Pad manipulation
		memset(&PadLocal, 0, sizeof(PadLocal));

		//Auto launch Scripts that start with _


	    std::vector<std::string> rFilenames = DoFileSearch({".lua"}, {SYSDATA_DIR "/Scripts"});

		if (rFilenames.size() > 0)
		{
			for (u32 i = 0; i < rFilenames.size(); i++)
			{
				std::string FileName;
				SplitPath(rFilenames[i], nullptr, &FileName, nullptr);

				if (!FileName.substr(0, 1).compare("_"))
				{
					LoadScript(FileName + ".lua");
				}
			}
		}
	}

	void Shutdown()
	{
		// Kill all Scripts
		for (std::list<LuaScript>::iterator it = scriptList.begin(); it != scriptList.end(); ++it)
		{
			if (it->hasStarted)
			{
				lua_close(it->luaState);
			}
		}

		scriptList.clear();
	}

	bool IsInMEMArea(u32 pointer)
	{
	    if ((pointer > 0x80000000 && pointer < 0x81800000) || (pointer > 0x90000000 && pointer < 0x94000000))
	    {
			return true;
	    }
	    else if ((pointer > 0x0 && pointer < 0x1800000) || (pointer > 0x10000000 && pointer < 0x14000000))
	    {
		    
			return true;
	    }
		else
		{		   
		    return false;
		}
		    
	}

	void LoadScript(std::string fileName)
	{
		LuaScript newScript;

		newScript.wantsSavestateCallback = false;
		newScript.requestedTermination = false;
		newScript.hasStarted = false;
		newScript.fileName = fileName;

		scriptList.push_back(newScript);
	}

	void TerminateScript(std::string fileName)
	{
		for (std::list<LuaScript>::iterator it = scriptList.begin(); it != scriptList.end(); ++it) //could this crash when an entry is deleted by the CPU thread during this?
		{
			if (it->fileName == fileName)
			{
				it->requestedTermination = true;
				break;
			}
		}
	}

	bool IsScriptRunning(std::string fileName)
	{
		for (std::list<LuaScript>::iterator it = scriptList.begin(); it != scriptList.end(); ++it)
		{
			if (it->fileName == fileName)
			{
				return true;
			}
		}

		return false;
	}

	//Called every time a controller is updated (same as fps if there is only 1 gcc)
    static void UpdateScripts(int controllerID, GCPadStatus *PadStatus, u8 *data, WiimoteEmu::ReportFeatures *rptf, int ext, const wiimote_key *key)
	{
		if (!Core::IsRunningAndStarted())
			return;

		//Update stored copies
	    currentControllerID = controllerID;
	    UpdateGCC = data == nullptr;
	    if (UpdateGCC)
	    {
		    PadLocal = *PadStatus;
	    }
	    else
	    {
		    WiimoteData = data;
		    WiimoteExt = ext;
		    WiimoteRptf = *rptf;
		    WiimoteKey = key;
	    }

		//Iterate through all the loaded LUA Scripts
		int n = 0;
		std::list<LuaScript>::iterator it = scriptList.begin();

		while (it != scriptList.end())
		{ 
			int status = 0;
			currScriptID = n; //Update Script ID for Wrapper Functions

			if (it->hasStarted == false) //Start Script
			{
				//Create new LUA State
				it->luaState = luaL_newstate();

				//Open standard LUA libraries
				luaL_openlibs(it->luaState);

				//Register C Functions
				RegisterGeneralLuaFunctions(it->luaState);

				//Unique to normal Scripts
				lua_register(it->luaState, "CancelScript", CancelScript);

				std::string file = SYSDATA_DIR "/Scripts/" + it->fileName;

				status = luaL_dofile(it->luaState, file.c_str());

				if (status == 0)
				{
					//Execute Start function
					lua_getglobal(it->luaState, "onScriptStart");

					status = lua_pcall(it->luaState, 0, LUA_MULTRET, 0);
				}

				if (status != 0)
				{
					HandleLuaErrors(it->luaState, status);
					lua_close(it->luaState);

					it = scriptList.erase(it);
					--n;
				}
				else
				{
					it->hasStarted = true;
				}
			}
			else if (it->requestedTermination) //Cancel Script and delete the entry from the list
			{
				lua_getglobal(it->luaState, "onScriptCancel");

				status = lua_pcall(it->luaState, 0, LUA_MULTRET, 0);

				if (status != 0)
				{
					HandleLuaErrors(it->luaState, status);
				}

				lua_close(it->luaState);

				status = -1;
				it = scriptList.erase(it);
				--n;
			}
			else //Update Script
			{
				//LUA Callbacks first (so Update can already react to it)
				if (it->wantsSavestateCallback && lua_isStateOperation)
				{
					if (lua_isStateSaved)
					{
						//Saved State Callback
						it->wantsSavestateCallback = false;

						lua_getglobal(it->luaState, "onStateSaved");

						status = lua_pcall(it->luaState, 0, LUA_MULTRET, 0);

						if (status != 0)
						{
							HandleLuaErrors(it->luaState, status);
							lua_close(it->luaState);

							it = scriptList.erase(it);
							--n;
						}

						lua_isStateOperation = false;
						lua_isStateSaved = false;
						lua_isStateLoaded = false;
					}
					else if (lua_isStateLoaded)
					{
						//Loaded State Callback
						it->wantsSavestateCallback = false;

						lua_getglobal(it->luaState, "onStateLoaded");

						status = lua_pcall(it->luaState, 0, LUA_MULTRET, 0);

						if (status != 0)
						{
							HandleLuaErrors(it->luaState, status);
							lua_close(it->luaState);

							it = scriptList.erase(it);
							--n;
						}

						lua_isStateOperation = false;
						lua_isStateSaved = false;
						lua_isStateLoaded = false;
					}
				}

				//Call normal Update function
				if (status == 0)
				{
					lua_getglobal(it->luaState, "onScriptUpdate");

					status = lua_pcall(it->luaState, 0, LUA_MULTRET, 0);

					if (status != 0)
					{
						HandleLuaErrors(it->luaState, status);
						lua_close(it->luaState);

						it = scriptList.erase(it);
						--n;
					}
				}
			}

			if (status == 0) //Next item in the list if no deletion took place
				++it;

			++n;
		}

		//Send changed Pad back (if this call was not for a wiimote)
	    if (UpdateGCC)
		    *PadStatus = PadLocal;
	}

	void UpdateScripts(GCPadStatus *PadStatus, int controllerID)
    {
	    UpdateScripts(controllerID, PadStatus, nullptr, nullptr, 0, nullptr);
    }

    // Note: if a classic controller extension is used, pressing buttons will set the buttons of the extension
    void UpdateScripts(u8 *data, WiimoteEmu::ReportFeatures rptf, int controllerID, int ext, const wiimote_key key)
    {
	    UpdateScripts(controllerID + 4, nullptr, data, &rptf, ext, &key);
    }
}
