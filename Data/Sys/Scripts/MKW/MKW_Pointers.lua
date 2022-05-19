local Pointers = {}

function isViable()
  local gameID = GetGameID()
  if gameID == "RMCE01" or gameID == "RMCP01" or gameID == "RMCJ01" or gameID == "RMCK01" then return true end
  return false
end

-- global pointers
local function getPlayerHolder()
  if not isViable() then return 0 end
  ptrTable = { ["RMCP01"] = 0x9C18F8, ["RMCE01"] = 0x9BD110, ["RMCJ01"] = 0x9C0958, ["RMCK01"] = 0x9AFF38 }
  return ptrTable[GetGameID()]
end
Pointers.getPlayerHolder = getPlayerHolder

local function getRacedata()
  if not isViable() then return 0 end
  ptrTable = { ["RMCP01"] = 0x9BD728, ["RMCE01"] = 0x9B8F68, ["RMCJ01"] = 0x9BC788, ["RMCK01"] = 0x9ABD68 }
  return ptrTable[GetGameID()]
end
Pointers.getRacedata = getRacedata

local function getRaceinfo()
  if not isViable() then return 0 end
  ptrTable = { ["RMCP01"] = 0x9BD730, ["RMCE01"] = 0x9B8F70, ["RMCJ01"] = 0x9BC790, ["RMCK01"] = 0x9ABD70 }
  return ptrTable[GetGameID()]
end
Pointers.getRaceinfo = getRaceinfo

local function getKmpHolder()
  if not isViable() then return 0 end
  ptrTable = { ["RMCP01"] = 0x9BD6E8, ["RMCE01"] = 0x9B8F28, ["RMCJ01"] = 0x9BC748, ["RMCK01"] = 0x9ABD28 }
  return ptrTable[GetGameID()]
end
Pointers.getKmpHolder = getKmpHolder

local function getKclHolder()
  if not isViable() then return 0 end
  ptrTable = { ["RMCP01"] = 0x9C3C10, ["RMCE01"] = 0x9BF408, ["RMCJ01"] = 0x9C2C70, ["RMCK01"] = 0x9B2250 }
  return ptrTable[GetGameID()]
end
Pointers.getKclHolder = getKclHolder

local function getInputManager()
  if not isViable() then return 0 end
  ptrTable = { ["RMCP01"] = 0x9BD70C, ["RMCE01"] = 0x9B8F4C, ["RMCJ01"] = 0x9BC76C, ["RMCK01"] = 0x9ABD4C }
  return ptrTable[GetGameID()]
end
Pointers.getInputManager = getInputManager

local function getSaveManager()
  if not isViable() then return 0 end
  ptrTable = { ["RMCP01"] = 0x9BD748, ["RMCE01"] = 0x9B8F88, ["RMCJ01"] = 0x9BC7A8, ["RMCK01"] = 0x9ABD88 }
  return ptrTable[GetGameID()]
end
Pointers.getSaveManager = getSaveManager

local function getFrameOfInput()
  if not isViable() then return 0 end
  ptrTable = { ["RMCP01"] = 0x9C38C0, ["RMCE01"] = 0x9BF0B8, ["RMCJ01"] = 0x9C2920, ["RMCK01"] = 0x9B1F00 }
  return ptrTable[GetGameID()]
end
Pointers.getFrameOfInput = getFrameOfInput

-- scope of PlayerHolder
local function getPlayer(playerIdx)
  playerIdx = playerIdx or 0
  return GetPointerNormal(getPlayerHolder(), 0x20, playerIdx * 0x4, 0x0)
end
Pointers.getPlayer = getPlayer

local function getPlayerSub(playerIdx)
  playerIdx = playerIdx or 0
  return GetPointerNormal(getPlayer(playerIdx), 0x10, 0x0)
end
Pointers.getPlayerSub = getPlayerSub

local function getPlayerSubClasses(playerIdx, offset)
  playerIdx = playerIdx or 0
  offset = offset or 10
  return GetPointerNormal(getPlayerSub(playerIdx), offset, 0x0)
end
Pointers.getPlayerSubClasses = getPlayerSubClasses

local function getPlayerParams(playerIdx)
  playerIdx = playerIdx or 0
  return GetPointerNormal(getPlayer(playerIdx), 0x0, 0x0, 0x0)
end
Pointers.getPlayerParams = getPlayerParams

local function getPlayerStats(playerIdx)
  playerIdx = playerIdx or 0
  return GetPointerNormal(getPlayerParams(playerIdx), 0x14, 0x0, 0x0)
end
Pointers.getPlayerStats = getPlayerStats

local function getPlayerHitboxes(playerIdx)
  playerIdx = playerIdx or 0
  return GetPointerNormal(getPlayerParams(playerIdx), 0x14, 0x4, 0x0)
end
Pointers.getPlayerHitboxes = getPlayerHitboxes

local function getKartBody(playerIdx)
  playerIdx = playerIdx or 0
  return GetPointerNormal(getPlayer(playerIdx), 0x0, 0x8, 0x0)
end
Pointers.getKartBody = getKartBody

local function getPlayerPhysicsHolder(playerIdx)
  playerIdx = playerIdx or 0
  return GetPointerNormal(getKartBody(playerIdx), 0x90, 0x0)
end
Pointers.getPlayerPhysicsHolder = getPlayerPhysicsHolder

local function getPlayerPhysics(playerIdx)
  playerIdx = playerIdx or 0
  return GetPointerNormal(getPlayerPhysicsHolder(playerIdx), 0x4, 0x0)
end
Pointers.getPlayerPhysics = getPlayerPhysics

local function getCollisionGroup(playerIdx)
  playerIdx = playerIdx or 0
  return GetPointerNormal(getPlayerPhysicsHolder(playerIdx), 0x8, 0x0)
end
Pointers.getCollisionGroup = getCollisionGroup

local function getKartSus(playerIdx, wheelIdx)
  playerIdx = playerIdx or 0
  wheelIdx = wheelIdx or 0
  return GetPointerNormal(getPlayer(playerIdx), 0x0, 0xC, wheelIdx * 0x4, 0x0)
end
Pointers.getKartSus = getKartSus

local function getKartTire(playerIdx, wheelIdx)
  playerIdx = playerIdx or 0
  wheelIdx = wheelIdx or 0
  return GetPointerNormal(getPlayer(playerIdx), 0x0, 0x10, wheelIdx * 0x4, 0x0)
end
Pointers.getKartTire = getKartTire

local function getPlayerModel(playerIdx)
  playerIdx = playerIdx or 0
  return GetPointerNormal(getPlayer(playerIdx), 0x0, 0x14, 0x0)
end
Pointers.getPlayerModel = getPlayerModel

-- scope of Racedata
local function getRacedataScenario(scenarioIdx)
  scenarioIdx = scenarioIdx or 0
  return GetPointerNormal(getRacedata(), 0x20 + (0xBF0 * scenarioIdx), 0x0)
end
Pointers.getRacedataScenario = getRacedataScenario

local function getRacedataPlayer(playerIdx, scenarioIdx)
  scenarioIdx = scenarioIdx or 0
  playerIdx = playerIdx or 0
  return GetPointerNormal(getRacedataScenario(scenarioIdx), 0x8 + (0xF0 * playerIdx), 0x0)
end
Pointers.getRacedataPlayer = getRacedataPlayer

local function getRacedataSettings(scenarioIdx)
  scenarioIdx = scenarioIdx or 0
  return GetPointerNormal(getRacedataScenario(scenarioIdx), 0xB48, 0x0)
end
Pointers.getRacedataSettings = getRacedataSettings

-- scope of Raceinfo
local function getRaceinfoPlayer(playerIdx)
  playerIdx = playerIdx or 0
  return GetPointerNormal(getRaceinfo(), 0xC, playerIdx, 0x0)
end
Pointers.getRaceinfoPlayer = getRaceinfoPlayer

local function getController(playerIdx)
  playerIdx = playerIdx or 0
  return GetPointerNormal(getRaceinfoPlayer(playerIdx), 0x48, 0x4, 0x0)
end
Pointers.getController = getController

local function getTimerManager()
  return GetPointerNormal(getRaceinfo(), 0x14, 0x0)
end
Pointers.getTimerManager = getTimerManager

-- scope of KmpHolder
local function getRawKmpFile()
  return GetPointerNormal(getKmpHolder(), 0x4, 0x0, 0x0)
end
Pointers.getRawKmpFile = getRawKmpFile

-- scope of KclHolder
local function getKclInfo()
  return GetPointerNormal(getKclHolder(), 0x0, 0x0)
end
Pointers.getKclInfo = getKclInfo

-- scope of SaveManager
local function getRawSavePointer()
  return GetPointerNormal(getSaveManager(), 0x14, 0x0)
end
Pointers.getRawSave = getRawSave

return Pointers
