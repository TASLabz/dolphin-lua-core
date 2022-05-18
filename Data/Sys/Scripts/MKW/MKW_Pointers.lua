local Pointers = {}

function isViable()
  local gameID = GetGameID()
  if gameID == "RMCE01" or gameID == "RMCP01" or gameID == "RMCJ01" or gameID == "RMCK01" then return true end
  return false
end

local function getKMPBasePointer()
  if not isViable() then return 0 end
  ptrTable = { ["RMCP01"] = 0x9BD6E8, ["RMCE01"] = 0x9B8F28, ["RMCJ01"] = 0x9BC748, ["RMCK01"] = 0x9ABD28 }
  local kmpBase =  ptrTable[GetGameID()]
  return GetPointerNormal(pointer, 0x4, 0x0)
end
Pointers.getKMPBasePointer = getKMPBasePointer

local function getInputDataPointer()
  if not isViable() then return 0 end
  ptrTable = { ["RMCP01"] = 0x9BD70C, ["RMCE01"] = 0x9B8F4C, ["RMCJ01"] = 0x9BC76C, ["RMCK01"] = 0x9ABD4C }
  return ptrTable[GetGameID()]
end
Pointers.getInputDataPointer = getInputDataPointer

local function getRaceDataPointer()
  if not isViable() then return 0 end
  ptrTable = { ["RMCP01"] = 0x9BD728, ["RMCE01"] = 0x9B8F68, ["RMCJ01"] = 0x9BC788, ["RMCK01"] = 0x9ABD68 }
  return ptrTable[GetGameID()]
end
Pointers.getRaceDataPointer = getRaceDataPointer

local function getRaceInfoPointer(Offset)
  if not isViable() then return 0 end
  ptrTable = { ["RMCP01"] = 0x9BD730, ["RMCE01"] = 0x9B8F70, ["RMCJ01"] = 0x9BC790, ["RMCK01"] = 0x9ABD70 }
  local pointer = ptrTable[GetGameID()]
  return GetPointerNormal(pointer, 0xC, Offset)
end
Pointers.getRaceInfoPointer = getRaceInfoPointer

local function getInputPointer(Offset)
  return ReadValue32(getRaceInfoPointer(Offset), 0x48, 0x4)
end
Pointers.getInputPointer = getInputPointer

local function getRKSYSPointer()
  if not isViable() then return 0 end
  ptrTable = { ["RMCP01"] = 0x9BD748, ["RMCE01"] = 0x9B8F88, ["RMCJ01"] = 0x9BC7A8, ["RMCK01"] = 0x9ABD88 }
  local pointer = ptrTable[GetGameID()]
  return GetPointerNormal(pointer, 0x14, 0x0)
end
Pointers.getRKSYSPointer = getRKSYSPointer

local function getPlayerPhysicsHolderPointer(Offset)
  if not isViable() then return 0 end
  ptrTable = { ["RMCP01"] = 0x9C18F8, ["RMCE01"] = 0x9BD110, ["RMCJ01"] = 0x9C0958, ["RMCK01"] = 0x9AFF38 }
  local pointer = ptrTable[GetGameID()]
  return GetPointerNormal(pointer, 0xC, 0x10, Offset, 0x0, 0x8, 0x90)
end
Pointers.getPlayerPhysicsHolderPointer = getPlayerPhysicsHolderPointer

local function getPlayerPhysicsPointer(Offset)
  if not isViable() then return 0 end
  ptrTable = { ["RMCP01"] = 0x9C18F8, ["RMCE01"] = 0x9BD110, ["RMCJ01"] = 0x9C0958, ["RMCK01"] = 0x9AFF38 }
  local pointer = ptrTable[GetGameID()]
  return GetPointerNormal(pointer, 0xC, 0x10, Offset, 0x0, 0x8, 0x90, 0x4)
end
Pointers.getPlayerPhysicsPointer = getPlayerPhysicsPointer

local function getPlayerBasePointer(Offset)
  if not isViable() then return 0 end
  ptrTable = { ["RMCP01"] = 0x9C18F8, ["RMCE01"] = 0x9BD110, ["RMCJ01"] = 0x9C0958, ["RMCK01"] = 0x9AFF38 }
  local pointer = ptrTable[GetGameID()]
  return ReadValue32(pointer, 0xC, 0x10, Offset, 0x10, 0x10)
end
Pointers.getPlayerBasePointer = getPlayerBasePointer

local function getPlayerStatsPointer(Offset)
  if not isViable() then return 0 end
  ptrTable = { ["RMCP01"] = 0x9C18F8, ["RMCE01"] = 0x9BD110, ["RMCJ01"] = 0x9C0958, ["RMCK01"] = 0x9AFF38 }
  local pointer = ptrTable[GetGameID()]
  return ReadValue32(pointer, 0x20, 0x0, Offset, 0x0, 0x0, 0x14, 0x0)
end
Pointers.getPlayerStatsPointer = getPlayerStatsPointer

local function getFrameOfInputAddress()
  if not isViable() then return 0 end
  ptrTable = { ["RMCP01"] = 0x9C38C0, ["RMCE01"] = 0x9BF0B8, ["RMCJ01"] = 0x9C2920, ["RMCK01"] = 0x9B1F00 }
  return ptrTable[GetGameID()]
end
Pointers.getFrameOfInputAddress = getFrameOfInputAddress

return Pointers
