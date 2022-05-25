local classes = {}

package.path = GetScriptsDir() .. "MKW/MKW_Pointers.lua"
local pointers = require("MKW_Pointers")

-- general structure reading
local function ReadVec3(ptr)
    local vec3 = {}
    vec3.x = ReadValueFloat(ptr, 0x0)
    vec3.y = ReadValueFloat(ptr, 0x4)
    vec3.z = ReadValueFloat(ptr, 0x8)
    return vec3
end

local function ReadMat34(ptr)
    local mat34 = {}
    mat34.e00 = ReadValueFloat(ptr, 0x0)
    mat34.e01 = ReadValueFloat(ptr, 0x4)
    mat34.e02 = ReadValueFloat(ptr, 0x8)
    mat34.e03 = ReadValueFloat(ptr, 0xC)
    mat34.e10 = ReadValueFloat(ptr, 0x10)
    mat34.e11 = ReadValueFloat(ptr, 0x14)
    mat34.e12 = ReadValueFloat(ptr, 0x18)
    mat34.e13 = ReadValueFloat(ptr, 0x1C)
    mat34.e20 = ReadValueFloat(ptr, 0x20)
    mat34.e21 = ReadValueFloat(ptr, 0x24)
    mat34.e22 = ReadValueFloat(ptr, 0x28)
    mat34.e23 = ReadValueFloat(ptr, 0x2C)
    return mat34
end

local function ReadQuatf(ptr)
    local quatf = {}
    quatf.x = ReadValueFloat(ptr, 0x0)
    quatf.y = ReadValueFloat(ptr, 0x4)
    quatf.z = ReadValueFloat(ptr, 0x8)
    quatf.w = ReadValueFloat(ptr, 0xC)
    return quatf
end

local function ReadJumpPadProperties(ptr)
    local JumpPadProperties = {}
    if ptr == 0 then return {minSpeed = 0, maxSpeed = 0, velY = 0} end
    JumpPadProperties.minSpeed = ReadValueFloat(ptr, 0x0)
    JumpPadProperties.maxSpeed = ReadValueFloat(ptr, 0x4)
    JumpPadProperties.velY = ReadValueFloat(ptr, 0x8)
    return JumpPadProperties
end

local function ReadTrickProperties(ptr)
    local TrickProperties = {}
    if ptr == 0 then return {initialAngleDiff = 0, angleDiffMin = 0, angleDiffMulMin = 0, angleDiffMulDec = 0} end
    TrickProperties.initialAngleDiff = ReadValueFloat(ptr, 0x0)
    TrickProperties.angleDiffMin = ReadValueFloat(ptr, 0x4)
    TrickProperties.angleDiffMulMin = ReadValueFloat(ptr, 0x8)
    TrickProperties.angleDiffMulDec = ReadValueFloat(ptr, 0xC)
    return TrickProperties
end

local function ReadHitboxProperties(ptr)
    local HitboxProperties = {}
    -- this is the only way I can think of to
    -- include an empty vector in the nullptr return
    local pos = {x = 0, y = 0, z = 0}
    if ptr == 0 then return {enable = 0, pos, radius = 0, wallsOnly = 0} end
    HitboxProperties.enable = ReadValue16(ptr, 0x0)
    HitboxProperties.pos = ReadVec3(GetPointerNormal(ptr, 0x4, 0x0))
    HitboxProperties.radius = ReadValueFloat(ptr, 0x10)
    HitboxProperties.wallsOnly = ReadValue16(ptr, 0x14)
    HitboxProperties.tireCollisionIndex = ReadValue16(ptr, 0x16)
    return HitboxProperties
end

local function ReadWheelProperties(ptr)
    local WheelProperties = {}
    -- same situation as ReadHitboxProperties
    local relPos = {x = 0, y = 0, z = 0}
    if ptr == 0 then return {enable = 0, distSuspension = 0, speedSuspension = 0, 
                             slackY = 0, relPos, xRot = 0, wheelRadius = 0, sphereRadius = 0} end
    WheelProperties.enable = ReadValue16(ptr, 0x0)
    WheelProperties.distSuspension = ReadValueFloat(ptr, 0x4)
    WheelProperties.speedSuspension = ReadValueFloat(ptr, 0x8)
    WheelProperties.slackY = ReadValueFloat(ptr, 0xC)
    WheelProperties.relPos = ReadVec3(GetPointerNormal(ptr, 0x10, 0x0))
    WheelProperties.xRot = ReadValueFloat(ptr, 0x1C)
    WheelProperties.wheelRadius = ReadValueFloat(ptr, 0x20)
    WheelProperties.sphereRadius = ReadValueFloat(ptr, 0x24)
    return WheelProperties
end

-- determine how to get the Player index
local function hasGhost()
    local playerType = ReadValue32(pointers.getRacedataPlayer(1), 0x10)
    if playerType == 3 then return true end
    return false
end

local function getPlayerFromHud()
    return ReadValue8(pointers.getRacedata(), 0xb84)
end

local function isValidWheel(playerIdx, wheelIdx, offset)
    if ReadValue32(pointers.getPlayer(playerIdx), 0x0, offset, wheelIdx * 4) == 0 then return false end
    return true
end

-- scope of PlayerHolder
local function createPlayerHolder()
    local PlayerHolder = {}
    local playerHolderPtr = pointers.getPlayerHolder()

    PlayerHolder.playerArray = GetPointerNormal(playerHolderPtr, 0x20, 0x0)
    PlayerHolder.playerCount = ReadValue8(playerHolderPtr, 0x24)
    return PlayerHolder
end
classes.PlayerHolder = createPlayerHolder()

local function createPlayerSub(playerIdx)
    local PlayerSub = {}
    local ptr = pointers.getPlayerSub(playerIdx)

    PlayerSub.position = ReadValue8(ptr, 0x3C)
    PlayerSub.floorCollisionCount = ReadValue16(ptr, 0x40)

    return PlayerSub
end

local function createPlayerSub10(playerIdx)
    local PlayerSub10 = {}
    local ptr = pointers.getPlayerSubClasses(playerIdx, 0x10)

    PlayerSub10.speedMultiplier = ReadValueFloat(ptr, 0x10)
    PlayerSub10.baseSpeed = ReadValueFloat(ptr, 0x14)
    PlayerSub10.softSpeedLimit = ReadValueFloat(ptr, 0x18)
    PlayerSub10.speed = ReadValueFloat(ptr, 0x20)
    PlayerSub10.lastSpeed = ReadValueFloat(ptr, 0x24)
    PlayerSub10.hardSpeedLimit = ReadValueFloat(ptr, 0x2C)
    PlayerSub10.acceleration = ReadValueFloat(ptr, 0x30)
    PlayerSub10.speedDragMultiplier = ReadValueFloat(ptr, 0x34)
    PlayerSub10.smoothedUp = ReadVec3(GetPointerNormal(ptr, 0x38, 0x0))
    PlayerSub10.up = ReadVec3(GetPointerNormal(ptr, 0x44, 0x0))
    PlayerSub10.landingDir = ReadVec3(GetPointerNormal(ptr, 0x50, 0x0))
    PlayerSub10.dir = ReadVec3(GetPointerNormal(ptr, 0x5C, 0x0))
    PlayerSub10.lastDir = ReadVec3(GetPointerNormal(ptr, 0x68, 0x0))
    PlayerSub10.vel1Dir = ReadVec3(GetPointerNormal(ptr, 0x74, 0x0))
    PlayerSub10.dirDiff = ReadVec3(GetPointerNormal(ptr, 0x8C, 0x0))
    PlayerSub10.hasLandingDir = ReadValue8(ptr, 0x98)
    PlayerSub10.outsideDriftAngle = ReadValueFloat(ptr, 0x9C)
    PlayerSub10.landingAngle = ReadValueFloat(ptr, 0xA0)
    PlayerSub10.outsideDriftLastDir = ReadVec3(GetPointerNormal(ptr, 0xA4, 0x0))
    PlayerSub10.speedRatioCapped = ReadValueFloat(ptr, 0xB0)
    PlayerSub10.speedRatio = ReadValueFloat(ptr, 0xB4)
    PlayerSub10.kclSpeedFactor = ReadValueFloat(ptr, 0xB8)
    PlayerSub10.kclRotFactor = ReadValueFloat(ptr, 0xBC)
    PlayerSub10.kclWheelSpeedFactor = ReadValueFloat(ptr, 0xC0)
    PlayerSub10.kclWheelRotFactor = ReadValueFloat(ptr, 0xC4)
    PlayerSub10.floorCollisionCount = ReadValue16(ptr, 0xC8)
    PlayerSub10.hopStickX = ReadValue32(ptr, 0xCC)
    PlayerSub10.hopFrame = ReadValue32(ptr, 0xD0)
    PlayerSub10.hopUp = ReadVec3(GetPointerNormal(ptr, 0xD4, 0x0))
    PlayerSub10.hopDir = ReadVec3(GetPointerNormal(ptr, 0xE0, 0x0))
    PlayerSub10.slipstreamCharge = ReadValue32(ptr, 0xEC)
    PlayerSub10.divingRot = ReadValueFloat(ptr, 0xF4)
    PlayerSub10.standstillBoostRot = ReadValueFloat(ptr, 0xF8)
    -- driftState = 1: charging mt; 2: mt charged
    PlayerSub10.driftState = ReadValue16(ptr, 0xFC)
    PlayerSub10.mtCharge = ReadValue16(ptr, 0xFE)
    PlayerSub10.smtCharge = ReadValue16(ptr, 0x100)
    PlayerSub10.mtBoostTimer = ReadValue16(ptr, 0x102)
    PlayerSub10.outsideDriftBonus = ReadValueFloat(ptr, 0x104)
    PlayerSub10.zipperBoost = ReadValue16(ptr, 0x12C)
    PlayerSub10.zipperBoostMax = ReadValue16(ptr, 0x12E)
    PlayerSub10.offroadInvincibility = ReadValue16(ptr, 0x148)
    PlayerSub10.ssmtCharge = ReadValue16(ptr, 0x14C)
    PlayerSub10.realTurn = ReadValueFloat(ptr, 0x158)
    PlayerSub10.weightedTurn = ReadValueFloat(ptr, 0x15C)
    PlayerSub10.scale = ReadVec3(GetPointerNormal(ptr, 0x164, 0x0))
    PlayerSub10.shockSpeedMultiplier = ReadValueFloat(ptr, 0x178)
    PlayerSub10.megaScale = ReadValueFloat(ptr, 0x17C)
    PlayerSub10.mushroomTimer = ReadValue16(ptr, 0x188)
    PlayerSub10.starTimer = ReadValue16(ptr, 0x18A)
    PlayerSub10.shockTimer = ReadValue16(ptr, 0x18C)
    PlayerSub10.inkTimer = ReadValue16(ptr, 0x18E)
    PlayerSub10.inkApplied = ReadValue8(ptr, 0x190)
    PlayerSub10.crushTimer = ReadValue16(ptr, 0x192)
    PlayerSub10.megaTimer = ReadValue16(ptr, 0x194)
    PlayerSub10.jumpPadMinSpeed = ReadValueFloat(ptr, 0x1B0)
    PlayerSub10.jumpPadMaxSpeed = ReadValueFloat(ptr, 0x1B4)
    PlayerSub10.jumpPadProperties = ReadJumpPadProperties(GetPointerNormal(ptr, 0x1C0, 0x0, 0x0))
    PlayerSub10.rampBoost = ReadValue16(ptr, 0x1C4)
    PlayerSub10.lastPos = ReadVec3(GetPointerNormal(ptr, 0x1E8, 0x0))
    PlayerSub10.airtime = ReadValue32(ptr, 0x218)
    PlayerSub10.hopVelY = ReadValueFloat(ptr, 0x228)
    PlayerSub10.hopPosY = ReadValueFloat(ptr, 0x22C)
    PlayerSub10.hopGravity = ReadValueFloat(ptr, 0x230)
    -- DrivingDirection = 0: FORWARDS; 1: BRAKING; 2: WAITING_FOR_BACKWARDS; 3: BACKWARDS
    PlayerSub10.drivingDirection = ReadValue32(ptr, 0x248)
    PlayerSub10.backwardsAllowCounter = ReadValue16(ptr, 0x24C)
    -- SpecialFloor = 1: BOOST_PANEL; 2: BOOST_RAMP; 4: JUMP_PAD
    PlayerSub10.specialFloor = ReadValue32(ptr, 0x250)
    PlayerSub10.rawTurn = ReadValueFloat(ptr, 0x288)
    PlayerSub10.ghostStopTimer = ReadValue16(ptr, 0x290)
    PlayerSub10.leanRot = ReadValueFloat(ptr, 0x294)
    PlayerSub10.leanRotCap = ReadValueFloat(ptr, 0x298)
    PlayerSub10.leanRotInc = ReadValueFloat(ptr, 0x29C)
    PlayerSub10.wheelieRot = ReadValueFloat(ptr, 0x2A0)
    PlayerSub10.maxWheelieRot = ReadValueFloat(ptr, 0x2A4)
    PlayerSub10.wheelieFrames = ReadValue32(ptr, 0x2A8)
    PlayerSub10.wheelieCooldown = ReadValue16(ptr, 0x2B6)
    PlayerSub10.wheelieRotDec = ReadValueFloat(ptr, 0x2B8)

    return PlayerSub10
end

local function createPlayerSub10_284(playerIdx)
    local PlayerSub10_284 = {}
    local ptr = GetPointerNormal(pointers.getPlayerSubClasses(playerIdx, 0x10), 0x284, 0x0, 0x0)

    PlayerSub10_284.hopVelY = ReadValueFloat(ptr, 0x0)
    PlayerSub10_284.stabilizationFactor = ReadValueFloat(ptr, 0x4)

    return PlayerSub10_284
end

local function createPlayerSub10_2C0(playerIdx)
    local PlayerSub10_2C0 = {}
    local ptr = GetPointerNormal(pointers.getPlayerSubClasses(playerIdx, 0x10), 0x2C0, 0x0, 0x0)

    PlayerSub10_2C0.leanRotIncRace = ReadValueFloat(ptr, 0x4)
    PlayerSub10_2C0.leanRotCapRace = ReadValueFloat(ptr, 0x8)
    PlayerSub10_2C0.driftStickXFactor = ReadValueFloat(ptr, 0xC)
    PlayerSub10_2C0.leanRotMaxDrift = ReadValueFloat(ptr, 0x10)
    PlayerSub10_2C0.leanRotMinDrift = ReadValueFloat(ptr, 0x14)
    PlayerSub10_2C0.leanRotIncCountdown = ReadValueFloat(ptr, 0x18)
    PlayerSub10_2C0.leanRotCapCountdown = ReadValueFloat(ptr, 0x1C)
    PlayerSub10_2C0.maxWheelieFrames = ReadValue16(ptr, 0x2C)

    return PlayerSub10_2C0
end

local function createPlayerSub14(playerIdx)
    local PlayerSub14 = {}
    local ptr = pointers.getPlayerSubClasses(playerIdx, 0x14)

    PlayerSub14.frame = ReadValue32(ptr, 0xC4)

    return PlayerSub14
end

local function createPlayerSub18(playerIdx)
    local PlayerSub18 = {}
    local ptr = pointers.getPlayerSubClasses(playerIdx, 0x18)

    -- SurfaceProperties = 0x1: WALL; 0x2: SOLID_OOB; 0x10: BOOST_RAMP; 0x40: OFFROAD;
    --                     0x100: BOOST_PANEL_OR_RAMP; 0x800: TRICKABLE
    PlayerSub18.surfaceProperties = ReadValue32(ptr, 0x2C)
    PlayerSub18.preRespawnTimer = ReadValue16(ptr, 0x48)
    PlayerSub18.solidOobTimer = ReadValue16(ptr, 0x4A)

    return PlayerSub18
end

local function createPlayerSub1C(playerIdx)
    local PlayerSub1C = {}
    local ptr = pointers.getPlayerSubClasses(playerIdx, 0x1C)

    -- explaining these btifields in comments is a bad idea
    -- just know that they have a ton of depth and are extremely important
    PlayerSub1C.bitfield0 = ReadValue32(ptr, 0x4)
    PlayerSub1C.bitfield1 = ReadValue32(ptr, 0x8)
    PlayerSub1C.bitfield2 = ReadValue32(ptr, 0xC)
    PlayerSub1C.bitfield3 = ReadValue32(ptr, 0x10)
    PlayerSub1C.bitfield4 = ReadValue32(ptr, 0x14)
    PlayerSub1C.airtime = ReadValue32(ptr, 0x1C)
    PlayerSub1C.top = ReadVec3(GetPointerNormal(ptr, 0x28, 0x0))
    PlayerSub1C.hwgTimer = ReadValue32(ptr, 0x6C)
    PlayerSub1C.boostRampType = ReadValue32(ptr, 0x74)
    PlayerSub1C.jumpPadType = ReadValue32(ptr, 0x78)
    PlayerSub1C.cnptId = ReadValue32(ptr, 0x80)
    PlayerSub1C.stickX = ReadValueFloat(ptr, 0x88)
    PlayerSub1C.stickY = ReadValueFloat(ptr, 0x8C)
    PlayerSub1C.oobWipeState = ReadValue32(ptr, 0x90)
    PlayerSub1C.oobWipeFrame = ReadValue32(ptr, 0x94)
    PlayerSub1C.startBoostCharge = ReadValueFloat(ptr, 0x9C)
    PlayerSub1C.startBoostIdx = ReadValueFloat(ptr, 0xA0)
    PlayerSub1C.trickableTimer = ReadValue16(ptr, 0xA6)

    return PlayerSub1C
end

local function createPlayerSub20(playerIdx)
    local PlayerSub20 = {}
    local stick = {}
    local ptr = pointers.getPlayerSubClasses(playerIdx, 0x20)

    stick.x = ReadValueFloat(ptr, 0x14)
    stick.y = ReadValueFloat(ptr, 0x18)
    PlayerSub20.stick = stick
    PlayerSub20.team = ReadValue32(ptr, 0x20)

    return PlayerSub20
end

local function createPlayerBoost(playerIdx)
    local PlayerBoost = {}
    local ptr = GetPointerNormal(pointers.getPlayerSubClasses(playerIdx, 0x10), 0x108, 0x0)

    PlayerBoost.allMt = ReadValue16(ptr, 0x4)
    PlayerBoost.mushroomAndBoostPanel = ReadValue16(ptr, 0x8)
    PlayerBoost.trickAndZipper = ReadValue16(ptr, 0xC)
    -- BoostType: 0x1: ALL_MT; 0x4: MUSHROOM_AND_BOOST_PANEL; 0x10: TRICK_AND_ZIPPER
    PlayerBoost.boostType = ReadValue16(ptr, 0x10)
    PlayerBoost.boostMultiplier = ReadValueFloat(ptr, 0x14)
    PlayerBoost.boostAcceleration = ReadValueFloat(ptr, 0x18)
    PlayerBoost.boostSpeedLimit = ReadValueFloat(ptr, 0x20)

    return PlayerBoost
end

local function createPlayerTrick(playerIdx)
    local PlayerTrick = {}
    local ptr = GetPointerNormal(pointers.getPlayerSubClasses(playerIdx, 0x10), 0x258, 0x0, 0x0)

    -- TrickType = 0: STUNT_TRICK_BASIC; 1: BIKE_FLIP_TRICK_NOSE; 2: BIKE_FLIP_TRICK_TAIL;
    --             3: FLIP_TRICK_Y_LEFT; 4: FLIP_TRICK_Y_RIGHT; 5: KART_FLIP_TRICK_Z; 6: BIKE_SIDE_STUNT_TRICK
    PlayerTrick.trickType = ReadValue32(ptr, 0x10)
    PlayerTrick.category = ReadValue32(ptr, 0x14)
    PlayerTrick.nextDirection = ReadValue8(ptr, 0x18)
    PlayerTrick.nextAllowTimer = ReadValue16(ptr, 0x1A)
    PlayerTrick.rotDir = ReadValueFloat(ptr, 0x1C)
    PlayerTrick.properties = ReadTrickProperties(GetPointerNormal(ptr, 0x20, 0x0, 0x0))
    PlayerTrick.angle = ReadValueFloat(ptr, 0x24)
    PlayerTrick.angleDiff = ReadValueFloat(ptr, 0x28)
    PlayerTrick.angleDiffMul = ReadValueFloat(ptr, 0x2C)
    PlayerTrick.angleDiffMulDec = ReadValueFloat(ptr, 0x30)
    PlayerTrick.finalAngle = ReadValueFloat(ptr, 0x34)
    PlayerTrick.cooldown = ReadValue16(ptr, 0x38)
    PlayerTrick.boostRampEnabled = ReadValue8(ptr, 0x3A)
    PlayerTrick.rot = ReadQuatf(GetPointerNormal(ptr, 0x3C, 0x0))
    
    return PlayerTrick
end

local function createPlayerZipper(playerIdx)
    local PlayerZipper = {}
    local ptr = GetPointerNormal(pointers.getPlayerSubClasses(playerIdx, 0x10), 0x25C, 0x0, 0x0)

    PlayerZipper.nextTimer = ReadValue16(ptr, 0x78)
    PlayerZipper.nextInput = ReadValue8(ptr, 0x7A)

    return PlayerZipper
end

local function createPlayerParams(playerIdx)
    local PlayerParams = {}
    local ptr = pointers.getPlayerParams(playerIdx)

    PlayerParams.isBike = ReadValue32(ptr, 0x0)
    PlayerParams.vehicle = ReadValue32(ptr, 0x4)
    PlayerParams.character = ReadValue32(ptr, 0x8)
    PlayerParams.wheelCount0 = ReadValue16(ptr, 0xC)
    PlayerParams.wheelCount1 = ReadValue16(ptr, 0xE)
    PlayerParams.playerIdx = ReadValue8(ptr, 0x10)
    PlayerParams.wheelCountRecip = ReadValueFloat(ptr, 0x2C)
    PlayerParams.wheelCountPlusOneRecip = ReadValueFloat(ptr, 0x30)
    
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
    PlayerStats.wheelCount = ReadValue32(ptr, 0x0)
    -- VehicleType = 0: OUTSIDE_DRIFTING_KART; 1: OUTSIDE_DRIFTING_BIKE; 2: INSIDE_DRIFT
    PlayerStats.vehicleType = ReadValue32(ptr, 0x4)
    -- WeightClass = 0: LIGHT; 1: MEDIUM; 2: HEAVY
    PlayerStats.weightClass = ReadValue32(ptr, 0x8)
    PlayerStats.weight = ReadValueFloat(ptr, 0x10)
    PlayerStats.bumpDeviationLevel = ReadValueFloat(ptr, 0x14)
    PlayerStats.baseSpeed = ReadValueFloat(ptr, 0x18)
    PlayerStats.turningSpeed = ReadValueFloat(ptr, 0x1C)
    PlayerStats.tilt = ReadValueFloat(ptr, 0x20)
    -- acceleration
    acceleration.standardA0 = ReadValueFloat(ptr, 0x24)
    acceleration.standardA1 = ReadValueFloat(ptr, 0x28)
    acceleration.standardA2 = ReadValueFloat(ptr, 0x2C)
    acceleration.standardA3 = ReadValueFloat(ptr, 0x30)
    acceleration.standardT1 = ReadValueFloat(ptr, 0x34)
    acceleration.standardT2 = ReadValueFloat(ptr, 0x38)
    acceleration.standardT3 = ReadValueFloat(ptr, 0x3C)
    acceleration.driftA0 = ReadValueFloat(ptr, 0x40)
    acceleration.driftA1 = ReadValueFloat(ptr, 0x44)
    acceleration.driftA2 = ReadValueFloat(ptr, 0x48)
    PlayerStats.acceleration = acceleration
    -- turning (drift)
    drift.manualHandling = ReadValueFloat(ptr, 0x4C)
    drift.autoHandling = ReadValueFloat(ptr, 0x50)
    drift.handlingReact = ReadValueFloat(ptr, 0x54)
    drift.manualDrift = ReadValueFloat(ptr, 0x58)
    drift.autoDrift = ReadValueFloat(ptr, 0x5C)
    drift.driftReact = ReadValueFloat(ptr, 0x60)
    drift.outsideDriftTargetAngle = ReadValueFloat(ptr, 0x64)
    drift.outsideDriftDecrement = ReadValueFloat(ptr, 0x68)
    PlayerStats.drift = drift
    PlayerStats.mtDuration = ReadValue32(ptr, 0x6C)
    -- KCL flags
    kcl.speed_00 = ReadValueFloat(ptr, 0x70)
    kcl.speed_01 = ReadValueFloat(ptr, 0x74)
    kcl.speed_02 = ReadValueFloat(ptr, 0x78)
    kcl.speed_03 = ReadValueFloat(ptr, 0x7C)
    kcl.speed_04 = ReadValueFloat(ptr, 0x80)
    kcl.speed_05 = ReadValueFloat(ptr, 0x84)
    kcl.speed_06 = ReadValueFloat(ptr, 0x88)
    kcl.speed_07 = ReadValueFloat(ptr, 0x8C)
    kcl.speed_08 = ReadValueFloat(ptr, 0x90)
    kcl.speed_09 = ReadValueFloat(ptr, 0x94)
    kcl.speed_0A = ReadValueFloat(ptr, 0x98)
    kcl.speed_0B = ReadValueFloat(ptr, 0x9C)
    kcl.speed_0C = ReadValueFloat(ptr, 0xA0)
    kcl.speed_0D = ReadValueFloat(ptr, 0xA4)
    kcl.speed_0E = ReadValueFloat(ptr, 0xA8)
    kcl.speed_0F = ReadValueFloat(ptr, 0xAC)
    kcl.speed_10 = ReadValueFloat(ptr, 0xB0)
    kcl.speed_11 = ReadValueFloat(ptr, 0xB4)
    kcl.speed_12 = ReadValueFloat(ptr, 0xB8)
    kcl.speed_13 = ReadValueFloat(ptr, 0xBC)
    kcl.speed_14 = ReadValueFloat(ptr, 0xC0)
    kcl.speed_15 = ReadValueFloat(ptr, 0xC4)
    kcl.speed_16 = ReadValueFloat(ptr, 0xC8)
    kcl.speed_17 = ReadValueFloat(ptr, 0xCC)
    kcl.speed_18 = ReadValueFloat(ptr, 0xD0)
    kcl.speed_19 = ReadValueFloat(ptr, 0xD4)
    kcl.speed_1A = ReadValueFloat(ptr, 0xD8)
    kcl.speed_1B = ReadValueFloat(ptr, 0xDC)
    kcl.speed_1C = ReadValueFloat(ptr, 0xE0)
    kcl.speed_1D = ReadValueFloat(ptr, 0xE4)
    kcl.speed_1E = ReadValueFloat(ptr, 0xE8)
    kcl.speed_1F = ReadValueFloat(ptr, 0xEC)
    kcl.rot_00 = ReadValueFloat(ptr, 0xF0)
    kcl.rot_01 = ReadValueFloat(ptr, 0xF4)
    kcl.rot_02 = ReadValueFloat(ptr, 0xF8)
    kcl.rot_03 = ReadValueFloat(ptr, 0xFC)
    kcl.rot_04 = ReadValueFloat(ptr, 0x100)
    kcl.rot_05 = ReadValueFloat(ptr, 0x104)
    kcl.rot_06 = ReadValueFloat(ptr, 0x108)
    kcl.rot_07 = ReadValueFloat(ptr, 0x10C)
    kcl.rot_08 = ReadValueFloat(ptr, 0x110)
    kcl.rot_09 = ReadValueFloat(ptr, 0x114)
    kcl.rot_0A = ReadValueFloat(ptr, 0x118)
    kcl.rot_0B = ReadValueFloat(ptr, 0x11C)
    kcl.rot_0C = ReadValueFloat(ptr, 0x120)
    kcl.rot_0D = ReadValueFloat(ptr, 0x124)
    kcl.rot_0E = ReadValueFloat(ptr, 0x128)
    kcl.rot_0F = ReadValueFloat(ptr, 0x12C)
    kcl.rot_10 = ReadValueFloat(ptr, 0x130)
    kcl.rot_11 = ReadValueFloat(ptr, 0x134)
    kcl.rot_12 = ReadValueFloat(ptr, 0x138)
    kcl.rot_13 = ReadValueFloat(ptr, 0x13C)
    kcl.rot_14 = ReadValueFloat(ptr, 0x140)
    kcl.rot_15 = ReadValueFloat(ptr, 0x144)
    kcl.rot_16 = ReadValueFloat(ptr, 0x148)
    kcl.rot_17 = ReadValueFloat(ptr, 0x14C)
    kcl.rot_18 = ReadValueFloat(ptr, 0x150)
    kcl.rot_19 = ReadValueFloat(ptr, 0x154)
    kcl.rot_1A = ReadValueFloat(ptr, 0x158)
    kcl.rot_1B = ReadValueFloat(ptr, 0x15C)
    kcl.rot_1C = ReadValueFloat(ptr, 0x160)
    kcl.rot_1D = ReadValueFloat(ptr, 0x164)
    kcl.rot_1E = ReadValueFloat(ptr, 0x168)
    kcl.rot_1F = ReadValueFloat(ptr, 0x16C)
    PlayerStats.kcl = kcl
    -- misc (items may be slightly wrong)
    items.radiusZ = ReadValueFloat(ptr, 0x170)
    items.radiusX = ReadValueFloat(ptr, 0x174)
    items.distanceY = ReadValueFloat(ptr, 0x178)
    items.offset = ReadValueFloat(ptr, 0x17C)
    PlayerStats.items = items
    PlayerStats.maxNormalAcceleration = ReadValueFloat(ptr, 0x180)
    PlayerStats.megaScale = ReadValueFloat(ptr, 0x184)
    PlayerStats.tireDistance = ReadValueFloat(ptr, 0x188)
    
    return PlayerStats
end

local function createPlayerHitboxes(playerIdx)
    local PlayerHitboxes = {}
    local hitbox = {}
    local cuboids = {}
    local wheels = {}
    local ptr = pointers.getPlayerHitboxes(playerIdx)

    PlayerHitboxes.initialYPos = ReadValueFloat(ptr, 0x0)
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

    rotSpeed = ReadValueFloat(ptr, 0x19C)
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

    PlayerGpStats.startBoostSuccessful = ReadValue8(ptr, 0x0)
    PlayerGpStats.mts = ReadValue32(ptr, 0x4)
    PlayerGpStats.offroad = ReadValue32(ptr, 0x8)
    -- might be framesInFirst
    PlayerGpStats._0C = ReadValue32(ptr, 0xC)
    PlayerGpStats.objectCollision = ReadValue32(ptr, 0x10)
    PlayerGpStats.oob = ReadValue32(ptr, 0x14)
    PlayerGpStats._18 = ReadValue16(ptr, 0x18)
    
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
    PlayerPhysics.rotSpeed = ReadValueFloat(ptr, 0x64)
    PlayerPhysics.pos = ReadVec3(GetPointerNormal(ptr, 0x68, 0x0))
    PlayerPhysics.speed0 = ReadVec3(GetPointerNormal(ptr, 0x74, 0x0))
    PlayerPhysics.acceleration0 = ReadVec3(GetPointerNormal(ptr, 0x80, 0x0))
    PlayerPhysics.rotVec0 = ReadVec3(GetPointerNormal(ptr, 0xA4, 0x0))
    PlayerPhysics.speed2 = ReadVec3(GetPointerNormal(ptr, 0xB0, 0x0))
    PlayerPhysics.rotVec1 = ReadVec3(GetPointerNormal(ptr, 0xBC, 0x0))
    PlayerPhysics.speed3 = ReadVec3(GetPointerNormal(ptr, 0xC8, 0x0))
    PlayerPhysics.speed = ReadVec3(GetPointerNormal(ptr, 0xD4, 0x0))
    PlayerPhysics.speedNorm = ReadValueFloat(ptr, 0xE0)
    PlayerPhysics.rotVec2 = ReadVec3(GetPointerNormal(ptr, 0xE4, 0x0))
    PlayerPhysics.rot = ReadQuatf(GetPointerNormal(ptr, 0xF0, 0x0))
    PlayerPhysics.rot2 = ReadQuatf(GetPointerNormal(ptr, 0x100, 0x0))
    PlayerPhysics.normalAcceleration = ReadVec3(GetPointerNormal(ptr, 0x110, 0x0))
    PlayerPhysics.normalRotVec = ReadVec3(GetPointerNormal(ptr, 0x11C, 0x0))
    PlayerPhysics.specialRot = ReadQuatf(GetPointerNormal(ptr, 0x128, 0x0))
    PlayerPhysics.gravity = ReadValueFloat(ptr, 0x148)
    PlayerPhysics.speed1 = ReadVec3(GetPointerNormal(ptr, 0x14C, 0x0))
    PlayerPhysics.top = ReadVec3(GetPointerNormal(ptr, 0x158, 0x0))
    PlayerPhysics.noGravity = ReadValue8(ptr, 0x171)
    PlayerPhysics.inBullet = ReadValue8(ptr, 0x174)
    PlayerPhysics.stabilizationFactor = ReadValueFloat(ptr, 0x178)
    PlayerPhysics.speedFix = ReadValueFloat(ptr, 0x17C)
    PlayerPhysics.top_ = ReadVec3(GetPointerNormal(ptr, 0x180, 0x0))
    
    return PlayerPhysics
end

local function createCollisionGroup(ptr)
    local CollisionGroup = {}
    local collisionData = {}
    local ptr = pointers.getCollisionGroup(playerIdx)
    
    CollisionGroup.bspHitboxCount = ReadValue16(ptr, 0x0)
    CollisionGroup.boundingRadius = ReadValueFloat(ptr, 0x4)
    collisionData.types = ReadValue32(ptr, 0x8)
    collisionData.nor = ReadVec3(GetPointerNormal(ptr, 0xC, 0x0))
    collisionData.floorDir = ReadVec3(GetPointerNormal(ptr, 0x18, 0x0))
    collisionData.vel = ReadVec3(GetPointerNormal(ptr, 0x3C, 0x0))
    collisionData.relPos = ReadVec3(GetPointerNormal(ptr, 0x48, 0x0))
    collisionData.movement = ReadVec3(GetPointerNormal(ptr, 0x54, 0x0))
    collisionData.speedFactor = ReadValueFloat(ptr, 0x6C)
    collisionData.rotFactor = ReadValueFloat(ptr, 0x70)
    collisionData.closestFloorFlags = ReadValue32(ptr, 0x74)
    collisionData.closestFloorSettings = ReadValue32(ptr, 0x78)
    collisionData.intensity = ReadValue32(ptr, 0x84)
    CollisionGroup.collisionData = collisionData
    
    return CollisionGroup
end

local function createKartSusPhysics(playerIdx, wheelIdx)
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
end

local function createWheelPhysics(playerIdx, wheelIdx)
    local WheelPhysics = {}
    if not (isValidWheel(playerIdx, wheelIdx, 0x8)) then return WheelPhysics end
    local ptr = GetPointerNormal(pointers.getKartSus(playerIdx), wheelIdx * 4, 0x14, 0x0)

    WheelPhysics.wheelIdx = ReadValue32(ptr, 0x10)
    WheelPhysics.bspWheelIdx = ReadValue32(ptr, 0x14)
    WheelPhysics.realPos = ReadVec3(GetPointerNormal(ptr, 0x20, 0x0))
    WheelPhysics.lastPos = ReadVec3(GetPointerNormal(ptr, 0x2C, 0x0))
    WheelPhysics.lastPosDiff = ReadVec3(GetPointerNormal(ptr, 0x38, 0x0))
    WheelPhysics.yDown = ReadValueFloat(ptr, 0x44)
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

    Player.wheel0.KartSusPhysics = createKartSusPhysics(playerIdx, 0)
    Player.wheel0.WheelPhysics = createWheelPhysics(playerIdx, 0)
    Player.wheel1.KartSusPhysics = createKartSusPhysics(playerIdx, 1)
    Player.wheel1.WheelPhysics = createWheelPhysics(playerIdx, 1)
    Player.wheel2.KartSusPhysics = createKartSusPhysics(playerIdx, 2)
    Player.wheel2.WheelPhysics = createWheelPhysics(playerIdx, 2)
    Player.wheel3.KartSusPhysics = createKartSusPhysics(playerIdx, 3)
    Player.wheel3.WheelPhysics = createWheelPhysics(playerIdx, 3)
end
if (hasGhost()) then
    classes.Player = createPlayer(0)
    classes.Ghost = createPlayer(1)
else
    classes.Player = createPlayer(getPlayerFromHud())
    classes.Ghost = nil
end

-- scope of Racedata
local function createRacedataPlayer(scenarioIdx, playerIdx)
    local RacedataPlayer = {}
    local ptr = pointers.getRacedataPlayer(playerIdx, scenarioIdx)

    RacedataPlayer.localPlayerNum = ReadValue8(ptr, 0x5)
    RacedataPlayer.playerInputIdx = ReadValue8(ptr, 0x6)
    RacedataPlayer.vehicleId = ReadValue32(ptr, 0x8)
    RacedataPlayer.characterId = ReadValue32(ptr, 0xC)
    -- PlayerType = 0: REAL_LOCAL; 1: CPU; 3: GHOST; 4: REAL_ONLINE; 5: NONE
    RacedataPlayer.playerType = ReadValue32(ptr, 0x10)
    RacedataPlayer.team = ReadValue32(ptr, 0xCC)
    RacedataPlayer.controllerId = ReadValue32(ptr, 0xD0)
    RacedataPlayer.previousScore = ReadValue16(ptr, 0xD8)
    RacedataPlayer.gpScore = ReadValue16(ptr, 0xDA)
    RacedataPlayer.gpRankScore = ReadValue16(ptr, 0xDE)
    RacedataPlayer.prevFinishPos = ReadValue8(ptr, 0xE1)
    RacedataPlayer.finishPos = ReadValue8(ptr, 0xE2)
    RacedataPlayer.rating = ReadValue16(ptr, 0xE8)
    
    return RacedataPlayer
end

local function createRacedataSettings(scenarioIdx)
    local RacedataSettings = {}
    local ptr = pointers.getRacedataSettings(scenarioIdx)

    RacedataSettings.courseId = ReadValue32(ptr, 0x0)
    RacedataSettings.engineClass = ReadValue32(ptr, 0x4)
    RacedataSettings.gameMode = ReadValue32(ptr, 0x8)
    RacedataSettings.gameType = ReadValue32(ptr, 0xC)
    RacedataSettings.battleType = ReadValue32(ptr, 0x10)
    RacedataSettings.cpuMode = ReadValue32(ptr, 0x14)
    RacedataSettings.itemMode = ReadValue32(ptr, 0x18)
    RacedataSettings.hudPlayers.i0 = ReadValue8(ptr, 0x1C)
    RacedataSettings.hudPlayers.i1 = ReadValue8(ptr, 0x1D)
    RacedataSettings.hudPlayers.i2 = ReadValue8(ptr, 0x1E)
    RacedataSettings.hudPlayers.i3 = ReadValue8(ptr, 0x1F)
    RacedataSettings.cupId = ReadValue32(ptr, 0x20)
    RacedataSettings.raceNumber = ReadValue8(ptr, 0x24)
    RacedataSettings.lapCount = ReadValue8(ptr, 0x25)
    RacedataSettings.modeFlags = ReadValue32(ptr, 0x28)
    RacedataSettings.seed0 = ReadValue32(ptr, 0x2C)
    RacedataSettings.seed1 = ReadValue32(ptr, 0x30)

    return RacedataSettings
end

local function createRacedataScenario(scenarioIdx)
    local RacedataScenario = {}
    local players = {}
    local ptr = pointers.getRacedataScenario(scenarioIdx)

    RacedataScenario.playerCount = ReadValue8(ptr, 0x4)
    RacedataScenario.hudCount = ReadValue8(ptr, 0x5)
    RacedataScenario.localPlayerCount = ReadValue8(ptr, 0x6)
    RacedataScenario.hudCount2 = ReadValue8(ptr, 0x7)
    
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
classes.Racedata = createRacedata()

-- scope of Raceinfo
local function createRaceinfoPlayer(playerIdx)
    local RaceinfoPlayer = {}
    if ReadValue32(pointers.getRaceinfo, 0xC, playerIdx * 4) == 0 then return RaceinfoPlayer end
    local ptr = pointers.getRaceinfoPlayer(playerIdx)

    RaceinfoPlayer.idx = ReadValue8(ptr, 0x8)
    RaceinfoPlayer.checkpointId = ReadValue16(ptr, 0xA)
    RaceinfoPlayer.raceCompletion = ReadValueFloat(ptr, 0xC)
    RaceinfoPlayer.raceCompletionMax = ReadValueFloat(ptr, 0x10)
    RaceinfoPlayer.checkpointFactor = ReadValueFloat(ptr, 0x14)
    RaceinfoPlayer.checkpointStartLapCompletion = ReadValueFloat(ptr, 0x18)
    RaceinfoPlayer.lapCompletion = ReadValueFloat(ptr, 0x1C)
    RaceinfoPlayer.position = ReadValue8(ptr, 0x20)
    RaceinfoPlayer.respawn = ReadValue8(ptr, 0x21)
    RaceinfoPlayer.battleScore = ReadValue16(ptr, 0x22)
    RaceinfoPlayer.currentLap = ReadValue16(ptr, 0x24)
    RaceinfoPlayer.maxLap = ReadValue8(ptr, 0x26)
    RaceinfoPlayer.maxKcp = ReadValue8(ptr, 0x27)
    RaceinfoPlayer.frameCounter = ReadValue32(ptr, 0x2C)
    RaceinfoPlayer.framesInFirstPlace = ReadValue32(ptr, 0x30)
    RaceinfoPlayer.flags = ReadValue32(ptr, 0x38)

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
    Raceinfo.introTimer = ReadValue16(ptr, 0x1E)
    Raceinfo.timer = ReadValue32(ptr, 0x20)
    Raceinfo.stage = ReadValue32(ptr, 0x28)
    Raceinfo.spectatorMode = ReadValue8(ptr, 0x2D)
    Raceinfo.canCountdownStart = ReadValue8(ptr, 0x2E)
    Raceinfo.cutSceneMode = ReadValue8(ptr, 0x2F)

    return Raceinfo
end
classes.Raceinfo = createRaceinfo()