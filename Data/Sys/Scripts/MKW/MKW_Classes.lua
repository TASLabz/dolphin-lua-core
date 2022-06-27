local Classes = {}

package.path = GetScriptsDir() .. "MKW/MKW_Pointers.lua"
local pointers = require("MKW_Pointers")

-- general structure reading
local function ReadVec3(ptr)
    local vec3 = {}
	-- datatype: float
    vec3.x = GetPointerNormal(ptr, 0x0)
    vec3.y = GetPointerNormal(ptr, 0x4)
    vec3.z = GetPointerNormal(ptr, 0x8)
    return vec3
end

local function ReadMat34(ptr)
	-- datatype: float
    local mat34 = {}
    mat34.e00 = GetPointerNormal(ptr, 0x0)
    mat34.e01 = GetPointerNormal(ptr, 0x4)
    mat34.e02 = GetPointerNormal(ptr, 0x8)
    mat34.e03 = GetPointerNormal(ptr, 0xC)
    mat34.e10 = GetPointerNormal(ptr, 0x10)
    mat34.e11 = GetPointerNormal(ptr, 0x14)
    mat34.e12 = GetPointerNormal(ptr, 0x18)
    mat34.e13 = GetPointerNormal(ptr, 0x1C)
    mat34.e20 = GetPointerNormal(ptr, 0x20)
    mat34.e21 = GetPointerNormal(ptr, 0x24)
    mat34.e22 = GetPointerNormal(ptr, 0x28)
    mat34.e23 = GetPointerNormal(ptr, 0x2C)
    return mat34
end

local function ReadQuatf(ptr)
    -- datatype: float
	local quatf = {}
    quatf.x = GetPointerNormal(ptr, 0x0)
    quatf.y = GetPointerNormal(ptr, 0x4)
    quatf.z = GetPointerNormal(ptr, 0x8)
    quatf.w = GetPointerNormal(ptr, 0xC)
    return quatf
end

local function ReadJumpPadProperties(ptr)
    -- datatype: float
	local JumpPadProperties = {}
    if ptr == 0 then return {minSpeed = 0, maxSpeed = 0, velY = 0} end
    JumpPadProperties.minSpeed = GetPointerNormal(ptr, 0x0)
    JumpPadProperties.maxSpeed = GetPointerNormal(ptr, 0x4)
    JumpPadProperties.velY = GetPointerNormal(ptr, 0x8)
    return JumpPadProperties
end

local function ReadTrickProperties(ptr)
    -- datatype: float
	local TrickProperties = {}
    if ptr == 0 then return {initialAngleDiff = 0, angleDiffMin = 0, angleDiffMulMin = 0, angleDiffMulDec = 0} end
    TrickProperties.initialAngleDiff = GetPointerNormal(ptr, 0x0)
    TrickProperties.angleDiffMin = GetPointerNormal(ptr, 0x4)
    TrickProperties.angleDiffMulMin = GetPointerNormal(ptr, 0x8)
    TrickProperties.angleDiffMulDec = GetPointerNormal(ptr, 0xC)
    return TrickProperties
end

local function ReadHitboxProperties(ptr)
    local HitboxProperties = {}
    -- this is the only way I can think of to
    -- include an empty vector in the nullptr return
    local pos = {x = 0, y = 0, z = 0}
    if ptr == 0 then return {enable = 0, pos, radius = 0, wallsOnly = 0} end
    -- datatype: 2 bytes (ReadValue16)
	HitboxProperties.enable = GetPointerNormal(ptr, 0x0)
	-- datatype: float
    HitboxProperties.pos = ReadVec3(GetPointerNormal(ptr, 0x4, 0x0))
    -- datatype: float
	HitboxProperties.radius = GetPointerNormal(ptr, 0x10)
    -- datatype: 2 bytes (ReadValue16)
	HitboxProperties.wallsOnly = GetPointerNormal(ptr, 0x14)
    -- datatype: 2 bytes (ReadValue16)
	HitboxProperties.tireCollisionIndex = GetPointerNormal(ptr, 0x16)
    return HitboxProperties
end

local function ReadWheelProperties(ptr)
    local WheelProperties = {}
    -- same situation as ReadHitboxProperties
    local relPos = {x = 0, y = 0, z = 0}
    if ptr == 0 then return {enable = 0, distSuspension = 0, speedSuspension = 0, 
                             slackY = 0, relPos, xRot = 0, wheelRadius = 0, sphereRadius = 0} end
    -- datatype: 2 bytes (ReadValue16)
	WheelProperties.enable = GetPointerNormal(ptr, 0x0)
	-- datatype: float
    WheelProperties.distSuspension = GetPointerNormal(ptr, 0x4)
	-- datatype: float
    WheelProperties.speedSuspension = GetPointerNormal(ptr, 0x8)
	-- datatype: float
    WheelProperties.slackY = GetPointerNormal(ptr, 0xC)
	-- datatype: float
    WheelProperties.relPos = ReadVec3(GetPointerNormal(ptr, 0x10, 0x0))
    -- datatype: float
	WheelProperties.xRot = GetPointerNormal(ptr, 0x1C)
	-- datatype: float
    WheelProperties.wheelRadius = GetPointerNormal(ptr, 0x20)
	-- datatype: float
    WheelProperties.sphereRadius = GetPointerNormal(ptr, 0x24)
    return WheelProperties
end

-- determine how to get the Player index
local function hasGhost()
	-- datatype: 4 bytes (ReadValue32)
    local playerType = GetPointerNormal(pointers.getRacedataPlayer(1), 0x10)
    if playerType == 3 then return true end
    return false
end
Classes.hasGhost = hasGhost()

local function getPlayerFromHud()
	-- datatype: 1 byte (ReadValue8)
    return GetPointerNormal(pointers.getRacedata(), 0xb84)
end

local function isValidWheel(playerIdx, wheelIdx, offset)
    -- datatype: 4 bytes (ReadValue32)
	if GetPointerNormal(pointers.getPlayer(playerIdx), 0x0, offset, wheelIdx * 4) == 0 then return false end
    return true
end

-- scope of PlayerHolder
local function createPlayerHolder()
    local PlayerHolder = {}
    local playerHolderPtr = pointers.getPlayerHolder()

    PlayerHolder.playerArray = GetPointerNormal(playerHolderPtr, 0x20, 0x0)
    -- datatype: 1 byte (ReadValue8)
	PlayerHolder.playerCount = GetPointerNormal(playerHolderPtr, 0x24)
    return PlayerHolder
end
Classes.PlayerHolder = createPlayerHolder()

local function createPlayerSub(playerIdx)
    local PlayerSub = {}
    local ptr = pointers.getPlayerSub(playerIdx)
	
	-- datatype: 1 byte (ReadValue8)
    PlayerSub.position = GetPointerNormal(ptr, 0x3C)
	-- datatype: 2 bytes (ReadValue16)
    PlayerSub.floorCollisionCount = GetPointerNormal(ptr, 0x40)

    return PlayerSub
end

local function createPlayerSub10(playerIdx)
    local PlayerSub10 = {}
    local ptr = pointers.getPlayerSubClasses(playerIdx, 0x10)

	-- datatype: float
    PlayerSub10.speedMultiplier = GetPointerNormal(ptr, 0x10)
    -- datatype: float
	PlayerSub10.baseSpeed = GetPointerNormal(ptr, 0x14)
    -- datatype: float
	PlayerSub10.softSpeedLimit = GetPointerNormal(ptr, 0x18)
    -- datatype: float
	PlayerSub10.speed = GetPointerNormal(ptr, 0x20)
    -- datatype: float
	PlayerSub10.lastSpeed = GetPointerNormal(ptr, 0x24)
    -- datatype: float
	PlayerSub10.hardSpeedLimit = GetPointerNormal(ptr, 0x2C)
    -- datatype: float
	PlayerSub10.acceleration = GetPointerNormal(ptr, 0x30)
    -- datatype: float
	PlayerSub10.speedDragMultiplier = GetPointerNormal(ptr, 0x34)
    -- datatype: float
	PlayerSub10.smoothedUp = ReadVec3(GetPointerNormal(ptr, 0x38, 0x0))
    -- datatype: float
	PlayerSub10.up = ReadVec3(GetPointerNormal(ptr, 0x44, 0x0))
    -- datatype: float
	PlayerSub10.landingDir = ReadVec3(GetPointerNormal(ptr, 0x50, 0x0))
    -- datatype: float
	PlayerSub10.dir = ReadVec3(GetPointerNormal(ptr, 0x5C, 0x0))
    -- datatype: float
	PlayerSub10.lastDir = ReadVec3(GetPointerNormal(ptr, 0x68, 0x0))
    -- datatype: float
	PlayerSub10.vel1Dir = ReadVec3(GetPointerNormal(ptr, 0x74, 0x0))
    -- datatype: float
	PlayerSub10.dirDiff = ReadVec3(GetPointerNormal(ptr, 0x8C, 0x0))
    -- datatype: 1 byte (ReadValue8)
	PlayerSub10.hasLandingDir = GetPointerNormal(ptr, 0x98)
	-- datatype: float
    PlayerSub10.outsideDriftAngle = GetPointerNormal(ptr, 0x9C)
    -- datatype: float
	PlayerSub10.landingAngle = GetPointerNormal(ptr, 0xA0)
    -- datatype: float
	PlayerSub10.outsideDriftLastDir = ReadVec3(GetPointerNormal(ptr, 0xA4, 0x0))
    -- datatype: float
	PlayerSub10.speedRatioCapped = GetPointerNormal(ptr, 0xB0)
    -- datatype: float
	PlayerSub10.speedRatio = GetPointerNormal(ptr, 0xB4)
    -- datatype: float
	PlayerSub10.kclSpeedFactor = GetPointerNormal(ptr, 0xB8)
    -- datatype: float
	PlayerSub10.kclRotFactor = GetPointerNormal(ptr, 0xBC)
    -- datatype: float
	PlayerSub10.kclWheelSpeedFactor = GetPointerNormal(ptr, 0xC0)
    -- datatype: float
	PlayerSub10.kclWheelRotFactor = GetPointerNormal(ptr, 0xC4)
    -- datatype: 2 bytes (ReadValue16)
	PlayerSub10.floorCollisionCount = GetPointerNormal(ptr, 0xC8)
	-- datatype: 4 bytes (ReadValue32)
    PlayerSub10.hopStickX = GetPointerNormal(ptr, 0xCC)
	-- datatype: 4 bytes (ReadValue32)
    PlayerSub10.hopFrame = GetPointerNormal(ptr, 0xD0)
    -- datatype: float
	PlayerSub10.hopUp = ReadVec3(GetPointerNormal(ptr, 0xD4, 0x0))
    -- datatype: float
	PlayerSub10.hopDir = ReadVec3(GetPointerNormal(ptr, 0xE0, 0x0))
	-- datatype: 4 bytes (ReadValue32)
    PlayerSub10.slipstreamCharge = GetPointerNormal(ptr, 0xEC)
    -- datatype: float
	PlayerSub10.divingRot = GetPointerNormal(ptr, 0xF4)
	-- datatype: float
    PlayerSub10.standstillBoostRot = GetPointerNormal(ptr, 0xF8)
    -- driftState = 1: charging mt; 2: mt charged
	-- datatype: 2 bytes (ReadValue16)
    PlayerSub10.driftState = GetPointerNormal(ptr, 0xFC)
    -- datatype: 2 bytes (ReadValue16)
	PlayerSub10.mtCharge = GetPointerNormal(ptr, 0xFE)
    -- datatype: 2 bytes (ReadValue16)
	PlayerSub10.smtCharge = GetPointerNormal(ptr, 0x100)
    -- datatype: 2 bytes (ReadValue16)
	PlayerSub10.mtBoostTimer = GetPointerNormal(ptr, 0x102)
	-- datatype: float
    PlayerSub10.outsideDriftBonus = GetPointerNormal(ptr, 0x104)
	-- datatype: 2 bytes (ReadValue16)
    PlayerSub10.zipperBoost = GetPointerNormal(ptr, 0x12C)
	-- datatype: 2 bytes (ReadValue16)
    PlayerSub10.zipperBoostMax = GetPointerNormal(ptr, 0x12E)
	-- datatype: 2 bytes (ReadValue16)
    PlayerSub10.offroadInvincibility = GetPointerNormal(ptr, 0x148)
	-- datatype: 2 bytes (ReadValue16)
    PlayerSub10.ssmtCharge = GetPointerNormal(ptr, 0x14C)
	-- datatype: float
    PlayerSub10.realTurn = GetPointerNormal(ptr, 0x158)
	-- datatype: float
    PlayerSub10.weightedTurn = GetPointerNormal(ptr, 0x15C)
    PlayerSub10.scale = ReadVec3(GetPointerNormal(ptr, 0x164, 0x0))
	-- datatype: float
    PlayerSub10.shockSpeedMultiplier = GetPointerNormal(ptr, 0x178)
    -- datatype: float
	PlayerSub10.megaScale = GetPointerNormal(ptr, 0x17C)
	-- datatype: 2 bytes (ReadValue16)
    PlayerSub10.mushroomTimer = GetPointerNormal(ptr, 0x188)
    -- datatype: 2 bytes (ReadValue16)
	PlayerSub10.starTimer = GetPointerNormal(ptr, 0x18A)
    -- datatype: 2 bytes (ReadValue16)
	PlayerSub10.shockTimer = GetPointerNormal(ptr, 0x18C)
    -- datatype: 2 bytes (ReadValue16)
	PlayerSub10.inkTimer = GetPointerNormal(ptr, 0x18E)
	-- datatype: 1 byte (ReadValue8)
    PlayerSub10.inkApplied = GetPointerNormal(ptr, 0x190)
    -- datatype: 2 bytes (ReadValue16)
	PlayerSub10.crushTimer = GetPointerNormal(ptr, 0x192)
    -- datatype: 2 bytes (ReadValue16)
	PlayerSub10.megaTimer = GetPointerNormal(ptr, 0x194)
    -- datatype: float
	PlayerSub10.jumpPadMinSpeed = GetPointerNormal(ptr, 0x1B0)
	-- datatype: float
    PlayerSub10.jumpPadMaxSpeed = GetPointerNormal(ptr, 0x1B4)
    PlayerSub10.jumpPadProperties = ReadJumpPadProperties(GetPointerNormal(ptr, 0x1C0, 0x0, 0x0))
    -- datatype: 2 bytes (ReadValue16)
	PlayerSub10.rampBoost = GetPointerNormal(ptr, 0x1C4)
    PlayerSub10.lastPos = ReadVec3(GetPointerNormal(ptr, 0x1E8, 0x0))
    -- datatype: 4 bytes (ReadValue32)
	PlayerSub10.airtime = GetPointerNormal(ptr, 0x218)
	-- datatype: float
    PlayerSub10.hopVelY = GetPointerNormal(ptr, 0x228)
    -- datatype: float
	PlayerSub10.hopPosY = GetPointerNormal(ptr, 0x22C)
	-- datatype: float
    PlayerSub10.hopGravity = GetPointerNormal(ptr, 0x230)
    -- DrivingDirection = 0: FORWARDS; 1: BRAKING; 2: WAITING_FOR_BACKWARDS; 3: BACKWARDS
    -- datatype: 4 bytes (ReadValue32)
	PlayerSub10.drivingDirection = GetPointerNormal(ptr, 0x248)
	-- datatype: 2 bytes (ReadValue16)
    PlayerSub10.backwardsAllowCounter = GetPointerNormal(ptr, 0x24C)
    -- SpecialFloor = 1: BOOST_PANEL; 2: BOOST_RAMP; 4: JUMP_PAD
    -- datatype: 4 bytes (ReadValue32)
	PlayerSub10.specialFloor = GetPointerNormal(ptr, 0x250)
    -- datatype: float
	PlayerSub10.rawTurn = GetPointerNormal(ptr, 0x288)
	-- datatype: 2 bytes (ReadValue16)
    PlayerSub10.ghostStopTimer = GetPointerNormal(ptr, 0x290)
    -- datatype: float
	PlayerSub10.leanRot = GetPointerNormal(ptr, 0x294)
    -- datatype: float
	PlayerSub10.leanRotCap = GetPointerNormal(ptr, 0x298)
    -- datatype: float
	PlayerSub10.leanRotInc = GetPointerNormal(ptr, 0x29C)
    -- datatype: float
	PlayerSub10.wheelieRot = GetPointerNormal(ptr, 0x2A0)
    -- datatype: float
	PlayerSub10.maxWheelieRot = GetPointerNormal(ptr, 0x2A4)
    -- datatype: 4 bytes (ReadValue32)
	PlayerSub10.wheelieFrames = GetPointerNormal(ptr, 0x2A8)
	-- datatype: 2 bytes (ReadValue16)
    PlayerSub10.wheelieCooldown = GetPointerNormal(ptr, 0x2B6)
	-- datatype: float
    PlayerSub10.wheelieRotDec = GetPointerNormal(ptr, 0x2B8)

    return PlayerSub10
end

local function createPlayerSub10_284(playerIdx)
    local PlayerSub10_284 = {}
    local ptr = GetPointerNormal(pointers.getPlayerSubClasses(playerIdx, 0x10), 0x284, 0x0, 0x0)

	-- datatype: float
    PlayerSub10_284.hopVelY = GetPointerNormal(ptr, 0x0)
	-- datatype: float
    PlayerSub10_284.stabilizationFactor = GetPointerNormal(ptr, 0x4)

    return PlayerSub10_284
end

local function createPlayerSub10_2C0(playerIdx)
    local PlayerSub10_2C0 = {}
    local ptr = GetPointerNormal(pointers.getPlayerSubClasses(playerIdx, 0x10), 0x2C0, 0x0, 0x0)

	-- datatype: float
    PlayerSub10_2C0.leanRotIncRace = GetPointerNormal(ptr, 0x4)
	-- datatype: float
    PlayerSub10_2C0.leanRotCapRace = GetPointerNormal(ptr, 0x8)
    -- datatype: float
	PlayerSub10_2C0.driftStickXFactor = GetPointerNormal(ptr, 0xC)
    -- datatype: float
	PlayerSub10_2C0.leanRotMaxDrift = GetPointerNormal(ptr, 0x10)
    -- datatype: float
	PlayerSub10_2C0.leanRotMinDrift = GetPointerNormal(ptr, 0x14)
    -- datatype: float
	PlayerSub10_2C0.leanRotIncCountdown = GetPointerNormal(ptr, 0x18)
    -- datatype: float
	PlayerSub10_2C0.leanRotCapCountdown = GetPointerNormal(ptr, 0x1C)
    -- datatype: 2 bytes (ReadValue16)
	PlayerSub10_2C0.maxWheelieFrames = GetPointerNormal(ptr, 0x2C)

    return PlayerSub10_2C0
end

local function createPlayerSub14(playerIdx)
    local PlayerSub14 = {}
    local ptr = pointers.getPlayerSubClasses(playerIdx, 0x14)

	-- datatype: 4 bytes (ReadValue32)
    PlayerSub14.frame = GetPointerNormal(ptr, 0xC4)

    return PlayerSub14
end

local function createPlayerSub18(playerIdx)
    local PlayerSub18 = {}
    local ptr = pointers.getPlayerSubClasses(playerIdx, 0x18)

    -- SurfaceProperties = 0x1: WALL; 0x2: SOLID_OOB; 0x10: BOOST_RAMP; 0x40: OFFROAD;
    --                     0x100: BOOST_PANEL_OR_RAMP; 0x800: TRICKABLE
    -- datatype: 4 bytes (ReadValue32)
	PlayerSub18.surfaceProperties = GetPointerNormal(ptr, 0x2C)
    -- datatype: 2 bytes (ReadValue16)
	PlayerSub18.preRespawnTimer = GetPointerNormal(ptr, 0x48)
    -- datatype: 2 bytes (ReadValue16)
	PlayerSub18.solidOobTimer = GetPointerNormal(ptr, 0x4A)

    return PlayerSub18
end

local function createPlayerSub1C(playerIdx)
    local PlayerSub1C = {}
    local ptr = pointers.getPlayerSubClasses(playerIdx, 0x1C)

    -- explaining these btifields in comments is a bad idea
    -- just know that they have a ton of depth and are extremely important
    -- datatype: 4 bytes (ReadValue32)
	PlayerSub1C.bitfield0 = GetPointerNormal(ptr, 0x4)
    -- datatype: 4 bytes (ReadValue32)
	PlayerSub1C.bitfield1 = GetPointerNormal(ptr, 0x8)
    -- datatype: 4 bytes (ReadValue32)
	PlayerSub1C.bitfield2 = GetPointerNormal(ptr, 0xC)
	-- datatype: 4 bytes (ReadValue32)
	PlayerSub1C.bitfield3 = GetPointerNormal(ptr, 0x10)
    -- datatype: 4 bytes (ReadValue32)
	PlayerSub1C.bitfield4 = GetPointerNormal(ptr, 0x14)
    -- datatype: 4 bytes (ReadValue32)
	PlayerSub1C.airtime = GetPointerNormal(ptr, 0x1C)
    PlayerSub1C.top = ReadVec3(GetPointerNormal(ptr, 0x28, 0x0))
    -- datatype: 4 bytes (ReadValue32)
	PlayerSub1C.hwgTimer = GetPointerNormal(ptr, 0x6C)
    -- datatype: 4 bytes (ReadValue32)
	PlayerSub1C.boostRampType = GetPointerNormal(ptr, 0x74)
    -- datatype: 4 bytes (ReadValue32)
	PlayerSub1C.jumpPadType = GetPointerNormal(ptr, 0x78)
    -- datatype: 4 bytes (ReadValue32)
	PlayerSub1C.cnptId = GetPointerNormal(ptr, 0x80)
    -- datatype: float
	PlayerSub1C.stickX = GetPointerNormal(ptr, 0x88)
	-- datatype: float
    PlayerSub1C.stickY = GetPointerNormal(ptr, 0x8C)
    -- datatype: 4 bytes (ReadValue32)
	PlayerSub1C.oobWipeState = GetPointerNormal(ptr, 0x90)
    -- datatype: 4 bytes (ReadValue32)
	PlayerSub1C.oobWipeFrame = GetPointerNormal(ptr, 0x94)
	-- datatype: float
    PlayerSub1C.startBoostCharge = GetPointerNormal(ptr, 0x9C)
    -- datatype: float
	PlayerSub1C.startBoostIdx = GetPointerNormal(ptr, 0xA0)
	-- datatype: 2 bytes (ReadValue16)
    PlayerSub1C.trickableTimer = GetPointerNormal(ptr, 0xA6)

    return PlayerSub1C
end

local function createPlayerSub20(playerIdx)
    local PlayerSub20 = {}
    local stick = {}
    local ptr = pointers.getPlayerSubClasses(playerIdx, 0x20)

	-- datatype: float
    stick.x = GetPointerNormal(ptr, 0x14)
	-- datatype: float
    stick.y = GetPointerNormal(ptr, 0x18)
    PlayerSub20.stick = stick
	-- datatype: 4 bytes (ReadValue32)
    PlayerSub20.team = GetPointerNormal(ptr, 0x20)

    return PlayerSub20
end

local function createPlayerBoost(playerIdx)
    local PlayerBoost = {}
    local ptr = GetPointerNormal(pointers.getPlayerSubClasses(playerIdx, 0x10), 0x108, 0x0)

	-- datatype: 2 bytes (ReadValue16)
    PlayerBoost.allMt = GetPointerNormal(ptr, 0x4)
	-- datatype: 2 bytes (ReadValue16)
    PlayerBoost.mushroomAndBoostPanel = GetPointerNormal(ptr, 0x8)
	-- datatype: 2 bytes (ReadValue16)
    PlayerBoost.trickAndZipper = GetPointerNormal(ptr, 0xC)
    -- BoostType: 0x1: ALL_MT; 0x4: MUSHROOM_AND_BOOST_PANEL; 0x10: TRICK_AND_ZIPPER
    -- datatype: 2 bytes (ReadValue16)
	PlayerBoost.boostType = GetPointerNormal(ptr, 0x10)
	-- datatype: float
    PlayerBoost.boostMultiplier = GetPointerNormal(ptr, 0x14)
    -- datatype: float
	PlayerBoost.boostAcceleration = GetPointerNormal(ptr, 0x18)
    -- datatype: float
	PlayerBoost.boostSpeedLimit = GetPointerNormal(ptr, 0x20)

    return PlayerBoost
end

local function createPlayerTrick(playerIdx)
    local PlayerTrick = {}
    local ptr = GetPointerNormal(pointers.getPlayerSubClasses(playerIdx, 0x10), 0x258, 0x0, 0x0)

    -- TrickType = 0: STUNT_TRICK_BASIC; 1: BIKE_FLIP_TRICK_NOSE; 2: BIKE_FLIP_TRICK_TAIL;
    --             3: FLIP_TRICK_Y_LEFT; 4: FLIP_TRICK_Y_RIGHT; 5: KART_FLIP_TRICK_Z; 6: BIKE_SIDE_STUNT_TRICK
    -- datatype: 4 bytes (ReadValue32)
	PlayerTrick.trickType = GetPointerNormal(ptr, 0x10)
    -- datatype: 4 bytes (ReadValue32)
	PlayerTrick.category = GetPointerNormal(ptr, 0x14)
	-- datatype: 1 byte (ReadValue8)
    PlayerTrick.nextDirection = GetPointerNormal(ptr, 0x18)
	-- datatype: 2 bytes (ReadValue16)
    PlayerTrick.nextAllowTimer = GetPointerNormal(ptr, 0x1A)
	-- datatype: float
    PlayerTrick.rotDir = GetPointerNormal(ptr, 0x1C)
    PlayerTrick.properties = ReadTrickProperties(GetPointerNormal(ptr, 0x20, 0x0, 0x0))
    -- datatype: float
	PlayerTrick.angle = GetPointerNormal(ptr, 0x24)
	-- datatype: float
    PlayerTrick.angleDiff = GetPointerNormal(ptr, 0x28)
    -- datatype: float
	PlayerTrick.angleDiffMul = GetPointerNormal(ptr, 0x2C)
    -- datatype: float
	PlayerTrick.angleDiffMulDec = GetPointerNormal(ptr, 0x30)
    -- datatype: float
	PlayerTrick.finalAngle = GetPointerNormal(ptr, 0x34)
	-- datatype: 2 bytes (ReadValue16)
    PlayerTrick.cooldown = GetPointerNormal(ptr, 0x38)
	-- datatype: 1 byte (ReadValue8)
    PlayerTrick.boostRampEnabled = GetPointerNormal(ptr, 0x3A)
    PlayerTrick.rot = ReadQuatf(GetPointerNormal(ptr, 0x3C, 0x0))
    
    return PlayerTrick
end

local function createPlayerZipper(playerIdx)
    local PlayerZipper = {}
    local ptr = GetPointerNormal(pointers.getPlayerSubClasses(playerIdx, 0x10), 0x25C, 0x0, 0x0)
	
	-- datatype: 2 bytes (ReadValue16)
    PlayerZipper.nextTimer = GetPointerNormal(ptr, 0x78)
	-- datatype: 1 byte (ReadValue8)
    PlayerZipper.nextInput = GetPointerNormal(ptr, 0x7A)

    return PlayerZipper
end

local function createPlayerParams(playerIdx)
    local PlayerParams = {}
    local ptr = pointers.getPlayerParams(playerIdx)

	-- datatype: 4 bytes (ReadValue32)
    PlayerParams.isBike = GetPointerNormal(ptr, 0x0)
    -- datatype: 4 bytes (ReadValue32)
	PlayerParams.vehicle = GetPointerNormal(ptr, 0x4)
    -- datatype: 4 bytes (ReadValue32)
	PlayerParams.character = GetPointerNormal(ptr, 0x8)
	-- datatype: 2 bytes (ReadValue16)
    PlayerParams.wheelCount0 = GetPointerNormal(ptr, 0xC)
	-- datatype: 2 bytes (ReadValue16)
    PlayerParams.wheelCount1 = GetPointerNormal(ptr, 0xE)
	-- datatype: 1 byte (ReadValue8)
    PlayerParams.playerIdx = GetPointerNormal(ptr, 0x10)
	-- datatype: float
    PlayerParams.wheelCountRecip = GetPointerNormal(ptr, 0x2C)
    -- datatype: float
	PlayerParams.wheelCountPlusOneRecip = GetPointerNormal(ptr, 0x30)
    
    return PlayerParams
end

local function createPlayerStats(playerIdx)
    local PlayerStats = {}
    local acceleration = {}
    local drift = {}
    local kcl = {}
    local items = {}
    local ptr = pointers.getPlayerStats(playerIdx)

    -- WheelCount = 0: 4_WHEELS; 1: 2_WHEELS_HANDLE; 2: 2_WHEELS_BSP; 3: 3_WHEELS
    -- datatype: 4 bytes (ReadValue32)
	PlayerStats.wheelCount = GetPointerNormal(ptr, 0x0)
    -- VehicleType = 0: OUTSIDE_DRIFTING_KART; 1: OUTSIDE_DRIFTING_BIKE; 2: INSIDE_DRIFT
    -- datatype: 4 bytes (ReadValue32)
	PlayerStats.vehicleType = GetPointerNormal(ptr, 0x4)
    -- WeightClass = 0: LIGHT; 1: MEDIUM; 2: HEAVY
    -- datatype: 4 bytes (ReadValue32)
	PlayerStats.weightClass = GetPointerNormal(ptr, 0x8)
	-- datatype: float
    PlayerStats.weight = GetPointerNormal(ptr, 0x10)
	-- datatype: float
    PlayerStats.bumpDeviationLevel = GetPointerNormal(ptr, 0x14)
    -- datatype: float
	PlayerStats.baseSpeed = GetPointerNormal(ptr, 0x18)
    -- datatype: float
	PlayerStats.turningSpeed = GetPointerNormal(ptr, 0x1C)
    -- datatype: float
	PlayerStats.tilt = GetPointerNormal(ptr, 0x20)
    -- acceleration
	-- datatype: float
    acceleration.standardA0 = GetPointerNormal(ptr, 0x24)
    acceleration.standardA1 = GetPointerNormal(ptr, 0x28)
    acceleration.standardA2 = GetPointerNormal(ptr, 0x2C)
    acceleration.standardA3 = GetPointerNormal(ptr, 0x30)
    acceleration.standardT1 = GetPointerNormal(ptr, 0x34)
    acceleration.standardT2 = GetPointerNormal(ptr, 0x38)
    acceleration.standardT3 = GetPointerNormal(ptr, 0x3C)
    acceleration.driftA0 = GetPointerNormal(ptr, 0x40)
    acceleration.driftA1 = GetPointerNormal(ptr, 0x44)
    acceleration.driftA2 = GetPointerNormal(ptr, 0x48)
    PlayerStats.acceleration = acceleration
    -- turning (drift)
	-- datatype: float
    drift.manualHandling = GetPointerNormal(ptr, 0x4C)
    drift.autoHandling = GetPointerNormal(ptr, 0x50)
    drift.handlingReact = GetPointerNormal(ptr, 0x54)
    drift.manualDrift = GetPointerNormal(ptr, 0x58)
    drift.autoDrift = GetPointerNormal(ptr, 0x5C)
    drift.driftReact = GetPointerNormal(ptr, 0x60)
    drift.outsideDriftTargetAngle = GetPointerNormal(ptr, 0x64)
    drift.outsideDriftDecrement = GetPointerNormal(ptr, 0x68)
    PlayerStats.drift = drift
	-- datatype: 4 bytes (ReadValue32)
    PlayerStats.mtDuration = GetPointerNormal(ptr, 0x6C)
    -- KCL flags
	-- datatype: float
    kcl.speed_00 = GetPointerNormal(ptr, 0x70)
    kcl.speed_01 = GetPointerNormal(ptr, 0x74)
    kcl.speed_02 = GetPointerNormal(ptr, 0x78)
    kcl.speed_03 = GetPointerNormal(ptr, 0x7C)
    kcl.speed_04 = GetPointerNormal(ptr, 0x80)
    kcl.speed_05 = GetPointerNormal(ptr, 0x84)
    kcl.speed_06 = GetPointerNormal(ptr, 0x88)
    kcl.speed_07 = GetPointerNormal(ptr, 0x8C)
    kcl.speed_08 = GetPointerNormal(ptr, 0x90)
    kcl.speed_09 = GetPointerNormal(ptr, 0x94)
    kcl.speed_0A = GetPointerNormal(ptr, 0x98)
    kcl.speed_0B = GetPointerNormal(ptr, 0x9C)
    kcl.speed_0C = GetPointerNormal(ptr, 0xA0)
    kcl.speed_0D = GetPointerNormal(ptr, 0xA4)
    kcl.speed_0E = GetPointerNormal(ptr, 0xA8)
    kcl.speed_0F = GetPointerNormal(ptr, 0xAC)
    kcl.speed_10 = GetPointerNormal(ptr, 0xB0)
    kcl.speed_11 = GetPointerNormal(ptr, 0xB4)
    kcl.speed_12 = GetPointerNormal(ptr, 0xB8)
    kcl.speed_13 = GetPointerNormal(ptr, 0xBC)
    kcl.speed_14 = GetPointerNormal(ptr, 0xC0)
    kcl.speed_15 = GetPointerNormal(ptr, 0xC4)
    kcl.speed_16 = GetPointerNormal(ptr, 0xC8)
    kcl.speed_17 = GetPointerNormal(ptr, 0xCC)
    kcl.speed_18 = GetPointerNormal(ptr, 0xD0)
    kcl.speed_19 = GetPointerNormal(ptr, 0xD4)
    kcl.speed_1A = GetPointerNormal(ptr, 0xD8)
    kcl.speed_1B = GetPointerNormal(ptr, 0xDC)
    kcl.speed_1C = GetPointerNormal(ptr, 0xE0)
    kcl.speed_1D = GetPointerNormal(ptr, 0xE4)
    kcl.speed_1E = GetPointerNormal(ptr, 0xE8)
    kcl.speed_1F = GetPointerNormal(ptr, 0xEC)
    kcl.rot_00 = GetPointerNormal(ptr, 0xF0)
    kcl.rot_01 = GetPointerNormal(ptr, 0xF4)
    kcl.rot_02 = GetPointerNormal(ptr, 0xF8)
    kcl.rot_03 = GetPointerNormal(ptr, 0xFC)
    kcl.rot_04 = GetPointerNormal(ptr, 0x100)
    kcl.rot_05 = GetPointerNormal(ptr, 0x104)
    kcl.rot_06 = GetPointerNormal(ptr, 0x108)
    kcl.rot_07 = GetPointerNormal(ptr, 0x10C)
    kcl.rot_08 = GetPointerNormal(ptr, 0x110)
    kcl.rot_09 = GetPointerNormal(ptr, 0x114)
    kcl.rot_0A = GetPointerNormal(ptr, 0x118)
    kcl.rot_0B = GetPointerNormal(ptr, 0x11C)
    kcl.rot_0C = GetPointerNormal(ptr, 0x120)
    kcl.rot_0D = GetPointerNormal(ptr, 0x124)
    kcl.rot_0E = GetPointerNormal(ptr, 0x128)
    kcl.rot_0F = GetPointerNormal(ptr, 0x12C)
    kcl.rot_10 = GetPointerNormal(ptr, 0x130)
    kcl.rot_11 = GetPointerNormal(ptr, 0x134)
    kcl.rot_12 = GetPointerNormal(ptr, 0x138)
    kcl.rot_13 = GetPointerNormal(ptr, 0x13C)
    kcl.rot_14 = GetPointerNormal(ptr, 0x140)
    kcl.rot_15 = GetPointerNormal(ptr, 0x144)
    kcl.rot_16 = GetPointerNormal(ptr, 0x148)
    kcl.rot_17 = GetPointerNormal(ptr, 0x14C)
    kcl.rot_18 = GetPointerNormal(ptr, 0x150)
    kcl.rot_19 = GetPointerNormal(ptr, 0x154)
    kcl.rot_1A = GetPointerNormal(ptr, 0x158)
    kcl.rot_1B = GetPointerNormal(ptr, 0x15C)
    kcl.rot_1C = GetPointerNormal(ptr, 0x160)
    kcl.rot_1D = GetPointerNormal(ptr, 0x164)
    kcl.rot_1E = GetPointerNormal(ptr, 0x168)
    kcl.rot_1F = GetPointerNormal(ptr, 0x16C)
    PlayerStats.kcl = kcl
    -- items (may be slightly wrong)
	-- datatype: float
    items.radiusZ = GetPointerNormal(ptr, 0x170)
	items.radiusX = GetPointerNormal(ptr, 0x174)
	items.distanceY = GetPointerNormal(ptr, 0x178)
	items.offset = GetPointerNormal(ptr, 0x17C)
    PlayerStats.items = items
	-- misc
	-- datatype: float
    PlayerStats.maxNormalAcceleration = GetPointerNormal(ptr, 0x180)
    PlayerStats.megaScale = GetPointerNormal(ptr, 0x184)
    PlayerStats.tireDistance = GetPointerNormal(ptr, 0x188)
    
    return PlayerStats
end

local function createPlayerHitboxes(playerIdx)
    local PlayerHitboxes = {}
    local hitbox = {}
    local cuboids = {}
    local wheels = {}
    local ptr = pointers.getPlayerHitboxes(playerIdx)

	-- datatype: float
    PlayerHitboxes.initialYPos = GetPointerNormal(ptr, 0x0)
    -- unsure of this naming convention, it'll do for now
    -- hitbox spheres and properties
    hitbox.h0 = ReadHitboxProperties(GetPointerNormal(ptr, 0x4, 0x0))
    hitbox.h1 = ReadHitboxProperties(GetPointerNormal(ptr, 0x1C, 0x0))
    hitbox.h2 = ReadHitboxProperties(GetPointerNormal(ptr, 0x34, 0x0))
    hitbox.h3 = ReadHitboxProperties(GetPointerNormal(ptr, 0x4C, 0x0))
    hitbox.h4 = ReadHitboxProperties(GetPointerNormal(ptr, 0x64, 0x0))
    hitbox.h5 = ReadHitboxProperties(GetPointerNormal(ptr, 0x7C, 0x0))
    hitbox.h6 = ReadHitboxProperties(GetPointerNormal(ptr, 0x94, 0x0))
    hitbox.h7 = ReadHitboxProperties(GetPointerNormal(ptr, 0xAC, 0x0))
    hitbox.h8 = ReadHitboxProperties(GetPointerNormal(ptr, 0xC4, 0x0))
    hitbox.h9 = ReadHitboxProperties(GetPointerNormal(ptr, 0xDC, 0x0))
    hitbox.hA = ReadHitboxProperties(GetPointerNormal(ptr, 0xF4, 0x0))
    hitbox.hB = ReadHitboxProperties(GetPointerNormal(ptr, 0x10C, 0x0))
    hitbox.hC = ReadHitboxProperties(GetPointerNormal(ptr, 0x124, 0x0))
    hitbox.hD = ReadHitboxProperties(GetPointerNormal(ptr, 0x13C, 0x0))
    hitbox.hE = ReadHitboxProperties(GetPointerNormal(ptr, 0x154, 0x0))
    hitbox.hF = ReadHitboxProperties(GetPointerNormal(ptr, 0x16C, 0x0))
    PlayerHitboxes.hitbox = hitbox
    -- cuboid dimensions for inertia tensor
    cuboids.c0 = ReadVec3(GetPointerNormal(ptr, 0x184, 0x0))
    cuboids.c1 = ReadVec3(GetPointerNormal(ptr, 0x190, 0x0))
    PlayerHitboxes.cuboids = cuboids
	
	-- datatype: float
    rotSpeed = GetPointerNormal(ptr, 0x19C)
    -- wheel properties
    wheels.w0 = ReadWheelProperties(GetPointerNormal(ptr, 0x1A4, 0x0))
    wheels.w1 = ReadWheelProperties(GetPointerNormal(ptr, 0x1D0, 0x0))
    wheels.w2 = ReadWheelProperties(GetPointerNormal(ptr, 0x1FC, 0x0))
    wheels.w3 = ReadWheelProperties(GetPointerNormal(ptr, 0x228, 0x0))
    PlayerHitboxes.wheels = wheels

    return PlayerHitboxes
end

local function createPlayerGpStats(playerIdx)
    local PlayerGpStats = {}
    local ptr = pointers.getPlayerGpStats(playerIdx)

	-- datatype: 1 byte (ReadValue8)
    PlayerGpStats.startBoostSuccessful = GetPointerNormal(ptr, 0x0)
    -- datatype: 4 bytes (ReadValue32)
	PlayerGpStats.mts = GetPointerNormal(ptr, 0x4)
	-- datatype: 4 bytes (ReadValue32)
    PlayerGpStats.offroad = GetPointerNormal(ptr, 0x8)
    -- might be framesInFirst
	-- datatype: 4 bytes (ReadValue32)
    PlayerGpStats._0C = GetPointerNormal(ptr, 0xC)
	-- datatype: 4 bytes (ReadValue32)
    PlayerGpStats.objectCollision = GetPointerNormal(ptr, 0x10)
	-- datatype: 4 bytes (ReadValue32)
    PlayerGpStats.oob = GetPointerNormal(ptr, 0x14)
	-- datatype: 2 bytes (ReadValue16)
    PlayerGpStats._18 = GetPointerNormal(ptr, 0x18)
    
    return PlayerGpStats
end

local function createPlayerPhysicsHolder(playerIdx)
    local PlayerPhysicsHolder = {}
    local ptr = pointers.getPlayerPhysicsHolder(playerIdx)
    
    -- to my knowledge, all values here are from the previous frame
    PlayerPhysicsHolder.pos = ReadVec3(GetPointerNormal(ptr, 0x18, 0x0))
    PlayerPhysicsHolder.conservedSpecialRot = ReadQuatf(GetPointerNormal(ptr, 0x24, 0x0))
    PlayerPhysicsHolder.nonConservedSpecialRot = ReadQuatf(GetPointerNormal(ptr, 0x34, 0x0))
    PlayerPhysicsHolder.specialRot = ReadQuatf(GetPointerNormal(ptr, 0x44, 0x0))
    PlayerPhysicsHolder.mat = ReadMat34(GetPointerNormal(ptr, 0x9C, 0x0))
    PlayerPhysicsHolder.matCol0 = ReadVec3(GetPointerNormal(ptr, 0xCC, 0x0))
    PlayerPhysicsHolder.matCol1 = ReadVec3(GetPointerNormal(ptr, 0xD8, 0x0))
    PlayerPhysicsHolder.matCol2 = ReadVec3(GetPointerNormal(ptr, 0xE4, 0x0))
    PlayerPhysicsHolder.speed = ReadVec3(GetPointerNormal(ptr, 0xF0, 0x0))

    return PlayerPhysicsHolder
end

local function createPlayerPhysics(playerIdx)
    local PlayerPhysics = {}
    local ptr = pointers.getPlayerPhysics(playerIdx)

    -- SCRIPTERS: aim to always read from these values
    PlayerPhysics.inertiaTensor = ReadMat34(GetPointerNormal(ptr, 0x4, 0x0))
    PlayerPhysics.invInertiaTensor = ReadMat34(GetPointerNormal(ptr, 0x34, 0x0))
    -- datatype: float
	PlayerPhysics.rotSpeed = GetPointerNormal(ptr, 0x64)
    PlayerPhysics.pos = ReadVec3(GetPointerNormal(ptr, 0x68, 0x0))
    PlayerPhysics.speed0 = ReadVec3(GetPointerNormal(ptr, 0x74, 0x0))
    PlayerPhysics.acceleration0 = ReadVec3(GetPointerNormal(ptr, 0x80, 0x0))
    PlayerPhysics.rotVec0 = ReadVec3(GetPointerNormal(ptr, 0xA4, 0x0))
    PlayerPhysics.speed2 = ReadVec3(GetPointerNormal(ptr, 0xB0, 0x0))
    PlayerPhysics.rotVec1 = ReadVec3(GetPointerNormal(ptr, 0xBC, 0x0))
    PlayerPhysics.speed3 = ReadVec3(GetPointerNormal(ptr, 0xC8, 0x0))
    PlayerPhysics.speed = ReadVec3(GetPointerNormal(ptr, 0xD4, 0x0))
    -- datatype: float
	PlayerPhysics.speedNorm = GetPointerNormal(ptr, 0xE0)
    PlayerPhysics.rotVec2 = ReadVec3(GetPointerNormal(ptr, 0xE4, 0x0))
    PlayerPhysics.rot = ReadQuatf(GetPointerNormal(ptr, 0xF0, 0x0))
    PlayerPhysics.rot2 = ReadQuatf(GetPointerNormal(ptr, 0x100, 0x0))
    PlayerPhysics.normalAcceleration = ReadVec3(GetPointerNormal(ptr, 0x110, 0x0))
    PlayerPhysics.normalRotVec = ReadVec3(GetPointerNormal(ptr, 0x11C, 0x0))
    PlayerPhysics.specialRot = ReadQuatf(GetPointerNormal(ptr, 0x128, 0x0))
    -- datatype: float
	PlayerPhysics.gravity = GetPointerNormal(ptr, 0x148)
    PlayerPhysics.speed1 = ReadVec3(GetPointerNormal(ptr, 0x14C, 0x0))
    PlayerPhysics.top = ReadVec3(GetPointerNormal(ptr, 0x158, 0x0))
    -- datatype: 1 byte (ReadValue8)
	PlayerPhysics.noGravity = GetPointerNormal(ptr, 0x171)
    -- datatype: 1 byte (ReadValue8)
	PlayerPhysics.inBullet = GetPointerNormal(ptr, 0x174)
    -- datatype: float
	PlayerPhysics.stabilizationFactor = GetPointerNormal(ptr, 0x178)
    -- datatype: float
	PlayerPhysics.speedFix = GetPointerNormal(ptr, 0x17C)
    PlayerPhysics.top_ = ReadVec3(GetPointerNormal(ptr, 0x180, 0x0))
    
    return PlayerPhysics
end

local function createCollisionGroup(ptr)
    local CollisionGroup = {}
    local collisionData = {}
    local ptr = pointers.getCollisionGroup(playerIdx)
    
	-- datatype: 2 bytes (ReadValue16)
    CollisionGroup.bspHitboxCount = GetPointerNormal(ptr, 0x0)
	-- datatype: float
    CollisionGroup.boundingRadius = GetPointerNormal(ptr, 0x4)
    -- datatype: 4 bytes (ReadValue32)
	collisionData.types = GetPointerNormal(ptr, 0x8)
    collisionData.nor = ReadVec3(GetPointerNormal(ptr, 0xC, 0x0))
    collisionData.floorDir = ReadVec3(GetPointerNormal(ptr, 0x18, 0x0))
    collisionData.vel = ReadVec3(GetPointerNormal(ptr, 0x3C, 0x0))
    collisionData.relPos = ReadVec3(GetPointerNormal(ptr, 0x48, 0x0))
    collisionData.movement = ReadVec3(GetPointerNormal(ptr, 0x54, 0x0))
    -- datatype: float
	collisionData.speedFactor = GetPointerNormal(ptr, 0x6C)
    -- datatype: float
	collisionData.rotFactor = GetPointerNormal(ptr, 0x70)
	-- datatype: 4 bytes (ReadValue32)
    collisionData.closestFloorFlags = GetPointerNormal(ptr, 0x74)
    -- datatype: 4 bytes (ReadValue32)
	collisionData.closestFloorSettings = GetPointerNormal(ptr, 0x78)
    -- datatype: 4 bytes (ReadValue32)
	collisionData.intensity = GetPointerNormal(ptr, 0x84)
    CollisionGroup.collisionData = collisionData
    
    return CollisionGroup
end

--[[ local function createKartSusPhysics(playerIdx, wheelIdx)
    local KartSusPhysics = {}
    if not (isValidWheel(playerIdx, wheelIdx, 0x8)) then return KartSusPhysics end
    local ptr = GetPointerNormal(pointers.KartSus(playerIdx), wheelIdx * 4, 0x0)

    KartSusPhysics.xMirroredKart = ReadValue32(ptr, 0x18)
    KartSusPhysics.bspWheelIdx = ReadValue32(ptr, 0x1C)
    KartSusPhysics.wheelIdx = ReadValue32(ptr, 0x20)
    KartSusPhysics.topmostPos = ReadVec3(GetPointerNormal(ptr, 0x24, 0x0))
    KartSusPhysics.yDownLimit = ReadValueFloat(ptr, 0x30)
    KartSusPhysics.floorCollision = ReadValue8(ptr, 0x34)
    KartSusPhysics.bottomDir = ReadVec3(GetPointerNormal(ptr, 0x3C, 0x0))

    return KartSusPhysics
end --]]

local function createWheelPhysics(playerIdx, wheelIdx)
    local WheelPhysics = {}
    if not (isValidWheel(playerIdx, wheelIdx, 0x8)) then return WheelPhysics end
    local ptr = GetPointerNormal(pointers.getKartSus(playerIdx), wheelIdx * 4, 0x14, 0x0)

	-- datatype: 4 bytes (ReadValue32)
    WheelPhysics.wheelIdx = GetPointerNormal(ptr, 0x10)
	-- datatype: 4 bytes (ReadValue32)
    WheelPhysics.bspWheelIdx = GetPointerNormal(ptr, 0x14)
    WheelPhysics.realPos = ReadVec3(GetPointerNormal(ptr, 0x20, 0x0))
    WheelPhysics.lastPos = ReadVec3(GetPointerNormal(ptr, 0x2C, 0x0))
    WheelPhysics.lastPosDiff = ReadVec3(GetPointerNormal(ptr, 0x38, 0x0))
    -- datatype: float
	WheelPhysics.yDown = GetPointerNormal(ptr, 0x44)
    WheelPhysics.speed = ReadVec3(GetPointerNormal(ptr, 0x54, 0x0))
    WheelPhysics.aPos = ReadVec3(GetPointerNormal(ptr, 0x60, 0x0))
    WheelPhysics.topmostPos = ReadVec3(GetPointerNormal(ptr, 0x78, 0x0))
    
    return WheelPhysics
end

--[[
    Rather than create PlayerSub10/GhostSub10,
    we will instead create Player.PlayerSub10
    and Ghost.PlayerSub10. This has the side
    effect of forcing Player down here.
--]]
local function createPlayer(playerIdx)
    local Player = {}
    local wheel0 = {}
    local wheel1 = {}
    local wheel2 = {}
    local wheel3 = {}

    -- PlayerSub derivations
    Player.PlayerSub = createPlayerSub(playerIdx)
    Player.PlayerSub10 = createPlayerSub10(playerIdx)
    Player.PlayerSub10_284 = createPlayerSub10_284(playerIdx)
    Player.PlayerSub10_2C0 = createPlayerSub10_2C0(playerIdx)
    Player.PlayerSub14 = createPlayerSub14(playerIdx)
    Player.PlayerSub18 = createPlayerSub18(playerIdx)
    Player.PlayerSub1C = createPlayerSub1C(playerIdx)
    Player.PlayerSub20 = createPlayerSub20(playerIdx)
    Player.PlayerBoost = createPlayerBoost(playerIdx)
    Player.PlayerTrick = createPlayerTrick(playerIdx)
    Player.PlayerZipper = createPlayerZipper(playerIdx)
    
    -- PlayerPointers derivations
    Player.PlayerParams = createPlayerParams(playerIdx)
    Player.PlayerStats = createPlayerStats(playerIdx)
    Player.PlayerHitboxes = createPlayerHitboxes(playerIdx)
    Player.PlayerGpStats = createPlayerGpStats(playerIdx)
    Player.PlayerPhysicsHolder = createPlayerPhysicsHolder(playerIdx)
    Player.PlayerPhysics = createPlayerPhysics(playerIdx)
    Player.CollisionGroup = createCollisionGroup(playerIdx)

    -- wheel0.KartSusPhysics = createKartSusPhysics(playerIdx, 0)
    wheel0.WheelPhysics = createWheelPhysics(playerIdx, 0)
    -- wheel1.KartSusPhysics = createKartSusPhysics(playerIdx, 1)
    wheel1.WheelPhysics = createWheelPhysics(playerIdx, 1)
    -- wheel2.KartSusPhysics = createKartSusPhysics(playerIdx, 2)
    wheel2.WheelPhysics = createWheelPhysics(playerIdx, 2)
    -- wheel3.KartSusPhysics = createKartSusPhysics(playerIdx, 3)
    wheel3.WheelPhysics = createWheelPhysics(playerIdx, 3)

    Player.wheel0 = wheel0
    Player.wheel1 = wheel1
    Player.wheel2 = wheel2
    Player.wheel3 = wheel3
end
if (hasGhost()) then
    Classes.Player = createPlayer(0)
    Classes.Ghost = createPlayer(1)
else
    Classes.Player = createPlayer(getPlayerFromHud())
    Classes.Ghost = nil
end

-- scope of Racedata
local function createRacedataPlayer(scenarioIdx, playerIdx)
    local RacedataPlayer = {}
    local ptr = pointers.getRacedataPlayer(playerIdx, scenarioIdx)
	
	-- datatype: 1 byte (ReadValue8)
    RacedataPlayer.localPlayerNum = GetPointerNormal(ptr, 0x5)
	-- datatype: 1 byte (ReadValue8)
    RacedataPlayer.playerInputIdx = GetPointerNormal(ptr, 0x6)
	-- datatype: 4 bytes (ReadValue32)
    RacedataPlayer.vehicleId = GetPointerNormal(ptr, 0x8)
	-- datatype: 4 bytes (ReadValue32)
    RacedataPlayer.characterId = GetPointerNormal(ptr, 0xC)
    -- PlayerType = 0: REAL_LOCAL; 1: CPU; 3: GHOST; 4: REAL_ONLINE; 5: NONE
    -- datatype: 4 bytes (ReadValue32)
	RacedataPlayer.playerType = GetPointerNormal(ptr, 0x10)
	-- datatype: 4 bytes (ReadValue32)
    RacedataPlayer.team = GetPointerNormal(ptr, 0xCC)
	-- datatype: 4 bytes (ReadValue32)
    RacedataPlayer.controllerId = GetPointerNormal(ptr, 0xD0)
    -- datatype: 2 bytes (ReadValue16)
	RacedataPlayer.previousScore = GetPointerNormal(ptr, 0xD8)
    -- datatype: 2 bytes (ReadValue16)
	RacedataPlayer.gpScore = GetPointerNormal(ptr, 0xDA)
    -- datatype: 2 bytes (ReadValue16)
	RacedataPlayer.gpRankScore = GetPointerNormal(ptr, 0xDE)
	-- datatype: 1 byte (ReadValue8)
    RacedataPlayer.prevFinishPos = GetPointerNormal(ptr, 0xE1)
	-- datatype: 1 byte (ReadValue8)
    RacedataPlayer.finishPos = GetPointerNormal(ptr, 0xE2)
    -- datatype: 2 bytes (ReadValue16)
	RacedataPlayer.rating = GetPointerNormal(ptr, 0xE8)
    
    return RacedataPlayer
end

local function createRacedataSettings(scenarioIdx)
    local RacedataSettings = {}
    local hudPlayers = {}
    local ptr = pointers.getRacedataSettings(scenarioIdx)
	
	-- datatype: 4 bytes (ReadValue32)
    RacedataSettings.courseId = GetPointerNormal(ptr, 0x0)
	-- datatype: 4 bytes (ReadValue32)
    RacedataSettings.engineClass = GetPointerNormal(ptr, 0x4)
	-- datatype: 4 bytes (ReadValue32)
    RacedataSettings.gameMode = GetPointerNormal(ptr, 0x8)
	-- datatype: 4 bytes (ReadValue32)
    RacedataSettings.gameType = GetPointerNormal(ptr, 0xC)
	-- datatype: 4 bytes (ReadValue32)
    RacedataSettings.battleType = GetPointerNormal(ptr, 0x10)
	-- datatype: 4 bytes (ReadValue32)
    RacedataSettings.cpuMode = GetPointerNormal(ptr, 0x14)
    -- datatype: 4 bytes (ReadValue32)
	RacedataSettings.itemMode = GetPointerNormal(ptr, 0x18)
    -- hud players
	-- datatype: 1 byte (ReadValue8)
	hudPlayers.i0 = GetPointerNormal(ptr, 0x1C)
    hudPlayers.i1 = GetPointerNormal(ptr, 0x1D)
    hudPlayers.i2 = GetPointerNormal(ptr, 0x1E)
    hudPlayers.i3 = GetPointerNormal(ptr, 0x1F)
    RacedataSettings.hudPlayers = hudPlayers
	-- datatype: 4 bytes (ReadValue32)
    RacedataSettings.cupId = GetPointerNormal(ptr, 0x20)
	-- datatype: 1 byte (ReadValue8)
    RacedataSettings.raceNumber = GetPointerNormal(ptr, 0x24)
	-- datatype: 1 byte (ReadValue8)
    RacedataSettings.lapCount = GetPointerNormal(ptr, 0x25)
    -- datatype: 4 bytes (ReadValue32)
	RacedataSettings.modeFlags = GetPointerNormal(ptr, 0x28)
    -- datatype: 4 bytes (ReadValue32)
	RacedataSettings.seed0 = GetPointerNormal(ptr, 0x2C)
    -- datatype: 4 bytes (ReadValue32)
	RacedataSettings.seed1 = GetPointerNormal(ptr, 0x30)

    return RacedataSettings
end

local function createRacedataScenario(scenarioIdx)
    local RacedataScenario = {}
    local players = {}
    local ptr = pointers.getRacedataScenario(scenarioIdx)

	-- datatype: 1 byte (ReadValue8)
    RacedataScenario.playerCount = GetPointerNormal(ptr, 0x4)
	-- datatype: 1 byte (ReadValue8)
    RacedataScenario.hudCount = GetPointerNormal(ptr, 0x5)
	-- datatype: 1 byte (ReadValue8)
    RacedataScenario.localPlayerCount = GetPointerNormal(ptr, 0x6)
    -- datatype: 1 byte (ReadValue8)
	RacedataScenario.hudCount2 = GetPointerNormal(ptr, 0x7)
    
    players.p0 = createRacedataPlayer(scenarioIdx, 0x0)
    players.p1 = createRacedataPlayer(scenarioIdx, 0x1)
    players.p2 = createRacedataPlayer(scenarioIdx, 0x2)
    players.p3 = createRacedataPlayer(scenarioIdx, 0x3)
    players.p4 = createRacedataPlayer(scenarioIdx, 0x4)
    players.p5 = createRacedataPlayer(scenarioIdx, 0x5)
    players.p6 = createRacedataPlayer(scenarioIdx, 0x6)
    players.p7 = createRacedataPlayer(scenarioIdx, 0x7)
    players.p8 = createRacedataPlayer(scenarioIdx, 0x8)
    players.p9 = createRacedataPlayer(scenarioIdx, 0x9)
    players.pA = createRacedataPlayer(scenarioIdx, 0xA)
    players.pB = createRacedataPlayer(scenarioIdx, 0xB)
    RacedataScenario.players = players

    RacedataScenario.settings = createRacedataSettings(scenarioIdx)

    return RacedataScenario
end

local function createRacedata()
    local Racedata = {}
    
    Racedata.scenario0 = createRacedataScenario(0)
    Racedata.scenario1 = createRacedataScenario(1)
    Racedata.scenario2 = createRacedataScenario(2)
    return Racedata
end
Classes.Racedata = createRacedata()

-- scope of Raceinfo
local function createRaceinfoPlayer(playerIdx)
    local RaceinfoPlayer = {}
	-- datatype: 4 bytes (ReadValue32)
    if GetPointerNormal(pointers.getRaceinfo, 0xC, playerIdx * 4) == 0 then return RaceinfoPlayer end
    local ptr = pointers.getRaceinfoPlayer(playerIdx)
	
	-- datatype: 1 byte (ReadValue8)
    RaceinfoPlayer.idx = GetPointerNormal(ptr, 0x8)
	-- datatype: 2 bytes (ReadValue16)
    RaceinfoPlayer.checkpointId = GetPointerNormal(ptr, 0xA)
	-- datatype: float
    RaceinfoPlayer.raceCompletion = GetPointerNormal(ptr, 0xC)
    -- datatype: float
	RaceinfoPlayer.raceCompletionMax = GetPointerNormal(ptr, 0x10)
    -- datatype: float
	RaceinfoPlayer.checkpointFactor = GetPointerNormal(ptr, 0x14)
    -- datatype: float
	RaceinfoPlayer.checkpointStartLapCompletion = GetPointerNormal(ptr, 0x18)
    -- datatype: float
	RaceinfoPlayer.lapCompletion = GetPointerNormal(ptr, 0x1C)
    -- datatype: 1 byte (ReadValue8)
	RaceinfoPlayer.position = GetPointerNormal(ptr, 0x20)
    -- datatype: 1 byte (ReadValue8)
	RaceinfoPlayer.respawn = GetPointerNormal(ptr, 0x21)
	-- datatype: 2 bytes (ReadValue16)
    RaceinfoPlayer.battleScore = GetPointerNormal(ptr, 0x22)
    -- datatype: 2 bytes (ReadValue16)
	RaceinfoPlayer.currentLap = GetPointerNormal(ptr, 0x24)
	-- datatype: 1 byte (ReadValue8)
    RaceinfoPlayer.maxLap = GetPointerNormal(ptr, 0x26)
	-- datatype: 1 byte (ReadValue8)
    RaceinfoPlayer.maxKcp = GetPointerNormal(ptr, 0x27)
	-- datatype: 4 bytes (ReadValue32)
    RaceinfoPlayer.frameCounter = GetPointerNormal(ptr, 0x2C)
	-- datatype: 4 bytes (ReadValue32)   
    RaceinfoPlayer.framesInFirstPlace = GetPointerNormal(ptr, 0x30)
    -- datatype: 4 bytes (ReadValue32)
	RaceinfoPlayer.flags = GetPointerNormal(ptr, 0x38)

    return RaceinfoPlayer
end

local function createRaceinfo()
    local Raceinfo = {}
    local players = {}
    local ptr = pointers.getRaceinfo()

    players.p0 = createRaceinfoPlayer(0x0)
    players.p1 = createRaceinfoPlayer(0x1)
    players.p2 = createRaceinfoPlayer(0x2)
    players.p3 = createRaceinfoPlayer(0x3)
    players.p4 = createRaceinfoPlayer(0x4)
    players.p5 = createRaceinfoPlayer(0x5)
    players.p6 = createRaceinfoPlayer(0x6)
    players.p7 = createRaceinfoPlayer(0x7)
    players.p8 = createRaceinfoPlayer(0x8)
    players.p9 = createRaceinfoPlayer(0x9)
    players.pA = createRaceinfoPlayer(0xA)
    players.pB = createRaceinfoPlayer(0xB)
    Raceinfo.players = players
	-- datatype: 2 bytes (ReadValue16)
    Raceinfo.introTimer = GetPointerNormal(ptr, 0x1E)
	-- datatype: 4 bytes (ReadValue32)
    Raceinfo.timer = GetPointerNormal(ptr, 0x20)
	-- datatype: 4 bytes (ReadValue32)
    Raceinfo.stage = GetPointerNormal(ptr, 0x28)
	-- datatype: 1 byte (ReadValue8)
    Raceinfo.spectatorMode = GetPointerNormal(ptr, 0x2D)
	-- datatype: 1 byte (ReadValue8)
    Raceinfo.canCountdownStart = GetPointerNormal(ptr, 0x2E)
	-- datatype: 1 byte (ReadValue8)
    Raceinfo.cutSceneMode = GetPointerNormal(ptr, 0x2F)

    return Raceinfo
end
Classes.Raceinfo = createRaceinfo()