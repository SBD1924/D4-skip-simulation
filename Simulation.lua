-------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------PARAMETERS-----------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
local MAXFRAME            = 1200      -- giving up after this many frames
local MAXSLASHES          = 6         -- max number of sword slashes to change the RNG
local MAXMOVESTOWARDSLINK = 2         -- max number of times Link stands in a specific spot to change enemy movement
local FRAMESPERSLASH      = 8         -- how long one sword slash will at least take
local MinRNi, MaxRNi      = 557, 4756 -- range of RNG seeds
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------END OF PARAMETERS-------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------




local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local format = string.format



local function DisplayTime(Time)
    if Time >= 3600 then return format("%d h %d min", Time // 3600, (Time % 3600) // 60) end
    if Time >= 60 then return format("%d min %.0f s", Time // 60, Time % 60) end
    return format("%.2f s", Time)
end


-- how much Blue's position changes in one frame based on its direction
local BlueXChange = {0x.18, 0x.30, 0x.47, 0x.5A, 0x.6A, 0x.76, 0x.7D, 0x.80, 0x.7D, 0x.76, 0x.6A, 0x.5A, 0x.47, 0x.30, 0x.18, 0x.00,
-0x.18, -0x.30, -0x.47, -0x.5A, -0x.6A, -0x.76, -0x.7D, -0x.80, -0x.7D, -0x.76, -0x.6A, -0x.5A, -0x.47, -0x.30, -0x.18,}
BlueXChange[0] = 0x.00
local BlueYChange = {-0x.7D, -0x.76, -0x.6A, -0x.5A, -0x.47, -0x.30, -0x.18, 0x.00, 0x.18, 0x.30, 0x.47, 0x.5A, 0x.6A, 0x.76, 0x.7D,
0x.80, 0x.7D, 0x.76, 0x.6A, 0x.5A, 0x.47, 0x.30, 0x.18, 0x.00, -0x.18, -0x.30, -0x.47, -0x.5A, -0x.6A, -0x.76, -0x.7D,}
BlueYChange[0] = -0x.80


-- These tables are used whenever an enemy rolls a new direction and counter. Input is the index of the current RNG.
local RNAnd18       = {} -- for Green's direction
local RNAnd3FPlus30 = {} -- for Green's counter
local HAnd1F        = {} -- for Blue's direction
local RNAnd30Plus20 = {} -- for Blue's counter
local RNAnd30Plus21 = {} -- Blue's counter + 1 to account for the one frame after choosing a direction where Blue doesn't move
local LAnd0FEquals1 = {} -- determines if Blue moves towards Link
do
    local RNG2, RNG1 = 0x3A, 0x7B
    for i = 1, MinRNi - 1 do
        RNG2 = (3 * RNG2 + ((3 * RNG1) >> 8)) & 0xFF
        RNG1 = (RNG2 + RNG1) & 0xFF
    end
    
    for i = MinRNi - 1, MaxRNi + 2 * ceil(MAXFRAME / 0x30) + 4 * ceil(MAXFRAME / 0x20) + MAXSLASHES do -- upper bound for the number of RNG changes
        local L = 3 * RNG1
        LAnd0FEquals1[i] = L & 0x0F ~= 1 -- negating this happens to be more convenient later
        RNG2 = (3 * RNG2 + (L >> 8)) & 0xFF
        HAnd1F[i] = RNG2 & 0x1F
        RNG1 = (RNG2 + RNG1) & 0xFF
        RNAnd18[i + 1] = RNG1 & 0x18 -- shift this by one so Green can roll direction and counter using the same seed
        RNAnd3FPlus30[i] = (RNG1 & 0x3F) + 0x2F -- minus 1 to make it consistent with Blue's counter
        RNAnd30Plus20[i] = (RNG1 & 0x30) + 0x20
        RNAnd30Plus21[i] = RNAnd30Plus20[i] + 1
    end
end


-- This table holds the room's collision.
-- Input is direction + position.
-- Output is how to bounce off the wall.
local BlueCollision = {}
for Direction = 0, 0x1F do
    BlueCollision[Direction] = {}
    for X = 0x16, 0xEA do
        BlueCollision[Direction][X] = {}
    end
end
do
    --Up
    for Direction = 0x19, 0x27 do
        local Direction = Direction & 0x1F
        for X = 0x17, 0x39 do
            BlueCollision[Direction][X][0x53] = (0x30 - Direction) & 0x1F
        end
        for X = 0x3C, 0x49 do
            BlueCollision[Direction][X][0x61] = (0x30 - Direction) & 0x1F
            BlueCollision[Direction][X][0x62] = (0x30 - Direction) & 0x1F
            BlueCollision[Direction][X][0x63] = (0x30 - Direction) & 0x1F
        end
        for X = 0x4C, 0x59 do
            BlueCollision[Direction][X][0x71] = (0x30 - Direction) & 0x1F
            BlueCollision[Direction][X][0x72] = (0x30 - Direction) & 0x1F
            BlueCollision[Direction][X][0x73] = (0x30 - Direction) & 0x1F
        end
        for X = 0x5C, 0x94 do
            BlueCollision[Direction][X][0x81] = (0x30 - Direction) & 0x1F
            BlueCollision[Direction][X][0x82] = (0x30 - Direction) & 0x1F
            BlueCollision[Direction][X][0x83] = (0x30 - Direction) & 0x1F
        end
        for X = 0x97, 0xA4 do
            BlueCollision[Direction][X][0x71] = (0x30 - Direction) & 0x1F
            BlueCollision[Direction][X][0x72] = (0x30 - Direction) & 0x1F
            BlueCollision[Direction][X][0x73] = (0x30 - Direction) & 0x1F
        end
        for X = 0xA7, 0xB4 do
            BlueCollision[Direction][X][0x61] = (0x30 - Direction) & 0x1F
            BlueCollision[Direction][X][0x62] = (0x30 - Direction) & 0x1F
            BlueCollision[Direction][X][0x63] = (0x30 - Direction) & 0x1F
        end
        for X = 0xB7, 0xD9 do
            BlueCollision[Direction][X][0x53] = (0x30 - Direction) & 0x1F
        end
        for X = 0xDC, 0xE9 do
            BlueCollision[Direction][X][0x71] = (0x30 - Direction) & 0x1F
            BlueCollision[Direction][X][0x72] = (0x30 - Direction) & 0x1F
            BlueCollision[Direction][X][0x73] = (0x30 - Direction) & 0x1F
        end
    end
    for Direction = 0x00, 0x07 do
        BlueCollision[Direction][0x16][0x53] = 0x10 - Direction
        BlueCollision[Direction][0x94][0x80] = 0x10 - Direction
        BlueCollision[Direction][0x95][0x73] = 0x10 - Direction
        BlueCollision[Direction][0x96][0x71] = 0x10 - Direction
        BlueCollision[Direction][0x96][0x72] = 0x10 - Direction
        BlueCollision[Direction][0x96][0x73] = 0x10 - Direction
        BlueCollision[Direction][0xA4][0x70] = 0x10 - Direction
        BlueCollision[Direction][0xA5][0x63] = 0x10 - Direction
        BlueCollision[Direction][0xA6][0x61] = 0x10 - Direction
        BlueCollision[Direction][0xA6][0x62] = 0x10 - Direction
        BlueCollision[Direction][0xA6][0x63] = 0x10 - Direction
        BlueCollision[Direction][0xB4][0x60] = 0x10 - Direction
        BlueCollision[Direction][0xB5][0x53] = 0x10 - Direction
        BlueCollision[Direction][0xB6][0x53] = 0x10 - Direction
    end
    for Direction = 0x19, 0x20 do
        local Direction = Direction & 0x1F
        BlueCollision[Direction][0x3A][0x53] = (0x30 - Direction) & 0x1F
        BlueCollision[Direction][0x3B][0x53] = (0x30 - Direction) & 0x1F
        BlueCollision[Direction][0x3C][0x60] = (0x30 - Direction) & 0x1F
        BlueCollision[Direction][0x4A][0x61] = (0x30 - Direction) & 0x1F
        BlueCollision[Direction][0x4A][0x62] = (0x30 - Direction) & 0x1F
        BlueCollision[Direction][0x4A][0x63] = (0x30 - Direction) & 0x1F
        BlueCollision[Direction][0x4B][0x63] = (0x30 - Direction) & 0x1F
        BlueCollision[Direction][0x4C][0x70] = (0x30 - Direction) & 0x1F
        BlueCollision[Direction][0x5A][0x71] = (0x30 - Direction) & 0x1F
        BlueCollision[Direction][0x5A][0x72] = (0x30 - Direction) & 0x1F
        BlueCollision[Direction][0x5A][0x73] = (0x30 - Direction) & 0x1F
        BlueCollision[Direction][0x5B][0x73] = (0x30 - Direction) & 0x1F
        BlueCollision[Direction][0x5C][0x80] = (0x30 - Direction) & 0x1F
        BlueCollision[Direction][0xDA][0x53] = (0x30 - Direction) & 0x1F
        BlueCollision[Direction][0xDB][0x53] = (0x30 - Direction) & 0x1F
        BlueCollision[Direction][0xDC][0x70] = (0x30 - Direction) & 0x1F
        BlueCollision[Direction][0xEA][0x71] = (0x30 - Direction) & 0x1F
        BlueCollision[Direction][0xEA][0x72] = (0x30 - Direction) & 0x1F
        BlueCollision[Direction][0xEA][0x73] = (0x30 - Direction) & 0x1F
    end
    
    --Right
    for Direction = 0x01, 0x0F do
        for Y = 0x54, 0x60 do
            BlueCollision[Direction][0x3A][Y] = 0x20 - Direction
            BlueCollision[Direction][0x3B][Y] = 0x20 - Direction
        end
        for Y = 0x64, 0x70 do
            BlueCollision[Direction][0x4A][Y] = 0x20 - Direction
            BlueCollision[Direction][0x4B][Y] = 0x20 - Direction
        end
        for Y = 0x74, 0x80 do
            BlueCollision[Direction][0x5A][Y] = 0x20 - Direction
            BlueCollision[Direction][0x5B][Y] = 0x20 - Direction
        end
        for Y = 0x54, 0x70 do
            BlueCollision[Direction][0xDA][Y] = 0x20 - Direction
            BlueCollision[Direction][0xDB][Y] = 0x20 - Direction
        end
        for Y = 0x7B, 0x98 do
            BlueCollision[Direction][0xDA][Y] = 0x20 - Direction
            BlueCollision[Direction][0xDB][Y] = 0x20 - Direction
        end
        for Y = 0x74, 0x78 do
            BlueCollision[Direction][0xEA][Y] = 0x20 - Direction
        end
    end
    for Direction = 0x01, 0x08 do
        BlueCollision[Direction][0xDA][0x99] = 0x20 - Direction
        BlueCollision[Direction][0xDB][0x99] = 0x20 - Direction
        BlueCollision[Direction][0xDC][0x7B] = 0x20 - Direction
        BlueCollision[Direction][0xEA][0x79] = 0x20 - Direction
        BlueCollision[Direction][0xEA][0x7A] = 0x20 - Direction
    end
    for Direction = 0x08, 0x0F do
        BlueCollision[Direction][0x3A][0x53] = 0x20 - Direction
        BlueCollision[Direction][0x3B][0x53] = 0x20 - Direction
        BlueCollision[Direction][0x3C][0x60] = 0x20 - Direction
        BlueCollision[Direction][0x4A][0x61] = 0x20 - Direction
        BlueCollision[Direction][0x4A][0x62] = 0x20 - Direction
        BlueCollision[Direction][0x4A][0x63] = 0x20 - Direction
        BlueCollision[Direction][0x4B][0x63] = 0x20 - Direction
        BlueCollision[Direction][0x4C][0x70] = 0x20 - Direction
        BlueCollision[Direction][0x5A][0x71] = 0x20 - Direction
        BlueCollision[Direction][0x5A][0x72] = 0x20 - Direction
        BlueCollision[Direction][0x5A][0x73] = 0x20 - Direction
        BlueCollision[Direction][0x5B][0x73] = 0x20 - Direction
        BlueCollision[Direction][0x5C][0x80] = 0x20 - Direction
        BlueCollision[Direction][0xDA][0x53] = 0x20 - Direction
        BlueCollision[Direction][0xDB][0x53] = 0x20 - Direction
        BlueCollision[Direction][0xDC][0x70] = 0x20 - Direction
        BlueCollision[Direction][0xEA][0x71] = 0x20 - Direction
        BlueCollision[Direction][0xEA][0x72] = 0x20 - Direction
        BlueCollision[Direction][0xEA][0x73] = 0x20 - Direction
    end
    
    --Down
    for Direction = 0x09, 0x17 do
        for X = 0x17, 0xD9 do
            BlueCollision[Direction][X][0x99] = (0x30 - Direction) & 0x1F
        end
        for X = 0xDC, 0xE9 do
            BlueCollision[Direction][X][0x79] = (0x30 - Direction) & 0x1F
            BlueCollision[Direction][X][0x7A] = (0x30 - Direction) & 0x1F
        end
    end
    for Direction = 0x09, 0x10 do
        BlueCollision[Direction][0x16][0x99] = 0x10 - Direction
    end
    for Direction = 0x10, 0x17 do
        BlueCollision[Direction][0xDA][0x99] = (0x30 - Direction) & 0x1F
        BlueCollision[Direction][0xDB][0x99] = (0x30 - Direction) & 0x1F
        BlueCollision[Direction][0xDC][0x7B] = (0x30 - Direction) & 0x1F
        BlueCollision[Direction][0xEA][0x79] = (0x30 - Direction) & 0x1F
        BlueCollision[Direction][0xEA][0x7A] = (0x30 - Direction) & 0x1F
    end
    
    --Left
    
    -- when bouncing off a left wall, for two specific directions the resulting direction is calculated incorrectly by the game
    local function BounceLeft(Direction)
        if Direction == 0x16 then return 0x09
        elseif Direction == 0x17 then return 0x08
        else return 0x20 - Direction end
    end
    
    for Direction = 0x11, 0x1F do
        for Y = 0x54, 0x98 do
            BlueCollision[Direction][0x16][Y] = BounceLeft(Direction)
        end
        for Y = 0x74, 0x80 do
            BlueCollision[Direction][0x95][Y] = BounceLeft(Direction)
            BlueCollision[Direction][0x96][Y] = BounceLeft(Direction)
        end
        for Y = 0x64, 0x70 do
            BlueCollision[Direction][0xA5][Y] = BounceLeft(Direction)
            BlueCollision[Direction][0xA6][Y] = BounceLeft(Direction)
        end
        for Y = 0x54, 0x60 do
            BlueCollision[Direction][0xB5][Y] = BounceLeft(Direction)
            BlueCollision[Direction][0xB6][Y] = BounceLeft(Direction)
        end
    end
    for Direction = 0x11, 0x18 do
        BlueCollision[Direction][0x16][0x53] = BounceLeft(Direction)
        BlueCollision[Direction][0x94][0x80] = BounceLeft(Direction)
        BlueCollision[Direction][0x95][0x73] = BounceLeft(Direction)
        BlueCollision[Direction][0x96][0x71] = BounceLeft(Direction)
        BlueCollision[Direction][0x96][0x72] = BounceLeft(Direction)
        BlueCollision[Direction][0x96][0x73] = BounceLeft(Direction)
        BlueCollision[Direction][0xA4][0x70] = BounceLeft(Direction)
        BlueCollision[Direction][0xA5][0x63] = BounceLeft(Direction)
        BlueCollision[Direction][0xA6][0x61] = BounceLeft(Direction)
        BlueCollision[Direction][0xA6][0x62] = BounceLeft(Direction)
        BlueCollision[Direction][0xA6][0x63] = BounceLeft(Direction)
        BlueCollision[Direction][0xB4][0x60] = BounceLeft(Direction)
        BlueCollision[Direction][0xB5][0x53] = BounceLeft(Direction)
        BlueCollision[Direction][0xB6][0x53] = BounceLeft(Direction)
    end
    for Direction = 0x18, 0x1F do
        BlueCollision[Direction][0x16][0x99] = 0x20 - Direction
    end
    
    --Up-Right
    for Direction = 0x01, 0x07 do
        BlueCollision[Direction][0x3A][0x53] = Direction ~ 0x10
        BlueCollision[Direction][0x3B][0x53] = Direction ~ 0x10
        BlueCollision[Direction][0x3C][0x60] = Direction ~ 0x10
        BlueCollision[Direction][0x4A][0x61] = Direction ~ 0x10
        BlueCollision[Direction][0x4A][0x62] = Direction ~ 0x10
        BlueCollision[Direction][0x4A][0x63] = Direction ~ 0x10
        BlueCollision[Direction][0x4B][0x63] = Direction ~ 0x10
        BlueCollision[Direction][0x4C][0x70] = Direction ~ 0x10
        BlueCollision[Direction][0x5A][0x71] = Direction ~ 0x10
        BlueCollision[Direction][0x5A][0x72] = Direction ~ 0x10
        BlueCollision[Direction][0x5A][0x73] = Direction ~ 0x10
        BlueCollision[Direction][0x5B][0x73] = Direction ~ 0x10
        BlueCollision[Direction][0x5C][0x80] = Direction ~ 0x10
        BlueCollision[Direction][0xDA][0x53] = Direction ~ 0x10
        BlueCollision[Direction][0xDB][0x53] = Direction ~ 0x10
        BlueCollision[Direction][0xDC][0x70] = Direction ~ 0x10
        BlueCollision[Direction][0xEA][0x71] = Direction ~ 0x10
        BlueCollision[Direction][0xEA][0x72] = Direction ~ 0x10
        BlueCollision[Direction][0xEA][0x73] = Direction ~ 0x10
    end
    
    -- Down-Right
    for Direction = 0x09, 0x0F do
        BlueCollision[Direction][0xDA][0x99] = Direction ~ 0x10
        BlueCollision[Direction][0xDB][0x99] = Direction ~ 0x10
        BlueCollision[Direction][0xDC][0x7B] = Direction ~ 0x10
        BlueCollision[Direction][0xEA][0x79] = Direction ~ 0x10
        BlueCollision[Direction][0xEA][0x7A] = Direction ~ 0x10
    end
    
    -- Down-Left
    for Direction = 0x11, 0x17 do
        BlueCollision[Direction][0x16][0x99] = Direction ~ 0x10
    end
    
    -- Up-Left
    for Direction = 0x19, 0x1F do
        BlueCollision[Direction][0x16][0x53] = Direction ~ 0x10
        BlueCollision[Direction][0x94][0x80] = Direction ~ 0x10
        BlueCollision[Direction][0x95][0x73] = Direction ~ 0x10
        BlueCollision[Direction][0x96][0x71] = Direction ~ 0x10
        BlueCollision[Direction][0x96][0x72] = Direction ~ 0x10
        BlueCollision[Direction][0x96][0x73] = Direction ~ 0x10
        BlueCollision[Direction][0xA4][0x70] = Direction ~ 0x10
        BlueCollision[Direction][0xA5][0x63] = Direction ~ 0x10
        BlueCollision[Direction][0xA6][0x61] = Direction ~ 0x10
        BlueCollision[Direction][0xA6][0x62] = Direction ~ 0x10
        BlueCollision[Direction][0xA6][0x63] = Direction ~ 0x10
        BlueCollision[Direction][0xB4][0x60] = Direction ~ 0x10
        BlueCollision[Direction][0xB5][0x53] = Direction ~ 0x10
        BlueCollision[Direction][0xB6][0x53] = Direction ~ 0x10
    end
end


-- at the end of the setup, there are 4 possible pixels Link can stand on, so this table holds all possible directions Blue can move in based on its position
local AngleTowardsFinalPosition = {}
do
    -- When moving towards Link, Blue uses the following function to determine its direction.
    -- This is just function objectGetRelativeAngleWithTempVars from the disassembly.
    local DirectionData = {
              0x19, 0x1a, 0x1b, 0x1c, 0x00, 0x00, 0x00,
        0x00, 0x1f, 0x1e, 0x1d, 0x1c, 0x00, 0x00, 0x00,
        0x08, 0x07, 0x06, 0x05, 0x04, 0x00, 0x00, 0x00,
        0x00, 0x01, 0x02, 0x03, 0x04, 0x00, 0x00, 0x00,
        0x18, 0x17, 0x16, 0x15, 0x14, 0x00, 0x00, 0x00,
        0x10, 0x11, 0x12, 0x13, 0x14, 0x00, 0x00, 0x00,
        0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x00, 0x00, 0x00,
        0x10, 0x0f, 0x0e, 0x0d, 0x0c, 0x00, 0x00, 0x00,
    }
    DirectionData[0] = 0x18
    local function AngleTowardsTarget(ObjectX, ObjectY, TargetX, TargetY)
        local H = ObjectY - TargetY
        local E = 0
        
        if H < 0 then
            H = (~H + 1) & 0xFF
            E = 4
        end
        
        local A = ObjectX - TargetX
        if A < 0 then
            A = (~A + 1) & 0xFF
            E = E + 2
        end
        
        if A < H then
            E = E + 1
            A, H = H, A
        end
        
        A = 2 * (A >> 3)
        
        if A < H then
            if 2 * A < H then
                if 3 * A < H then
                    if 4 * A < H then
                        return DirectionData[8 * E + 4]
                    end
                    return DirectionData[8 * E + 3]
                end
                return DirectionData[8 * E + 2]
            end
            return DirectionData[8 * E + 1]
        end
        return DirectionData[8 * E]
    end


    for X = 0x16, 0xEA do
        AngleTowardsFinalPosition[X] = {}
        for Y = 0x53, 0x99 do
            if X < 0x3C
            or (X < 0xDC
            and (X >= 0xB5
            or ((X < 0x4B or X >= 0xA6) and Y >= 0x61)
            or ((X < 0x4C or X >= 0xA5) and Y >= 0x63)
            or ((X < 0x5B or X >= 0x96) and Y >= 0x71)
            or ((X < 0x5C or X >= 0x95) and Y >= 0x73)
            or Y >= 0x81))
            or (X >= 0xDC and Y >= 0x71 and Y < 0x7B)
            or ((X == 0x3C or X == 0xB4) and Y == 0x60)
            or ((X == 0x4C or X == 0xA4 or X == 0xDC) and Y == 0x70)
            or (X == 0xDC and Y == 0x7B)
            or ((X == 0x5C or X == 0x94) and Y == 0x80) then -- Blue in-bounds
                AngleTowardsFinalPosition[X][Y] = {}
                AngleTowardsFinalPosition[X][Y][AngleTowardsTarget(floor(X), floor(Y), 0x90, 0x6E)] = true
                AngleTowardsFinalPosition[X][Y][AngleTowardsTarget(floor(X), floor(Y), 0x90, 0x6F)] = true
                AngleTowardsFinalPosition[X][Y][AngleTowardsTarget(floor(X), floor(Y), 0x91, 0x6E)] = true
                AngleTowardsFinalPosition[X][Y][AngleTowardsTarget(floor(X), floor(Y), 0x91, 0x6F)] = true
            end
        end
    end
end


-- in addition to the final position, this function also returns the amount of frames that green has moved before either hitting a wall or the counter hitting 0
local function MoveGreen (X, Y, Direction, Counter)
    if Direction == 0x00 then
        if X >= 0x5C and X < 0x95 then
            local Distance = max(0, ceil((Y - 0x83.FF) / 0x.8))
            if Counter <= Distance then
                return X, Y - Counter * 0x.8, Counter
            end
            Y = Y - Distance * 0x.8
            if X >= 0x65 and X < 0x8C then
                return X, Y, Distance
            end
            local NewCounter = Counter - Distance
            if X < 0x65 then
                local NewDistance = ceil((X - 0x5B.FF) / 0x.6)
                if NewCounter <= NewDistance then
                    return X - NewCounter * 0x.6, Y, Counter
                end
                NewCounter = min(NewCounter - NewDistance, ceil((Y - 0x73.FF) / 0x.8))
                return X - NewDistance * 0x.6, Y - NewCounter * 0x.8, Distance + NewDistance + NewCounter
            else
                local NewDistance = ceil((0x95 - X) / 0x.6)
                if NewCounter <= NewDistance then
                    return X + NewCounter * 0x.6, Y, Counter
                end
                NewCounter = min(NewCounter - NewDistance, ceil((Y - 0x73.FF) / 0x.8))
                return X + NewDistance * 0x.6, Y - NewCounter * 0x.8, Distance + NewDistance + NewCounter
            end
        elseif X < 0x3C or (X >= 0xB5 and X < 0xDC) then
            Counter = min(Counter, ceil((Y - 0x53.FF) / 0x.8))
            return X, Y - Counter * 0x.8, Counter
        elseif (X >= 0x3C and X < 0x4C) or (X >= 0xA5 and X < 0xB5) then
            local Distance = max(0, ceil((Y - 0x63.FF) / 0x.8))
            if Counter <= Distance then
                return X, Y - Counter * 0x.8, Counter
            end
            Y = Y - Distance * 0x.8
            if X >= 0x45 and X < 0xAC then
                return X, Y, Distance
            end
            local NewCounter = Counter - Distance
            if X < 0x45 then
                local NewDistance = ceil((X - 0x3B.FF) / 0x.6)
                if NewCounter <= NewDistance then
                    return X - NewCounter * 0x.6, Y, Counter
                end
                NewCounter = min(NewCounter - NewDistance, ceil((Y - 0x53.FF) / 0x.8))
                return X - NewDistance * 0x.6, Y - NewCounter * 0x.8, Distance + NewDistance + NewCounter
            else
                local NewDistance = ceil((0xB5 - X) / 0x.6)
                if NewCounter <= NewDistance then
                    return X + NewCounter * 0x.6, Y, Counter
                end
                NewCounter = min(NewCounter - NewDistance, ceil((Y - 0x53.FF) / 0x.8))
                return X + NewDistance * 0x.6, Y - NewCounter * 0x.8, Distance + NewDistance + NewCounter
            end
        else
            local Distance = max(0, ceil((Y - 0x73.FF) / 0x.8))
            if Counter <= Distance then
                return X, Y - Counter * 0x.8, Counter
            end
            Y = Y - Distance * 0x.8
            if (X >= 0x55 and X < 0x9C) or X >= 0xE5 then
                return X, Y, Distance
            end
            local NewCounter = Counter - Distance
            if X < 0x55 then
                local NewDistance = ceil((X - 0x4B.FF) / 0x.6)
                if NewCounter <= NewDistance then
                    return X - NewCounter * 0x.6, Y, Counter
                end
                NewCounter = min(NewCounter - NewDistance, ceil((Y - 0x63.FF) / 0x.8))
                return X - NewDistance * 0x.6, Y - NewCounter * 0x.8, Distance + NewDistance + NewCounter
            elseif X < 0xA5 then
                local NewDistance = ceil((0xA5 - X) / 0x.6)
                if NewCounter <= NewDistance then
                    return X + NewCounter * 0x.6, Y, Counter
                end
                NewCounter = min(NewCounter - NewDistance, ceil((Y - 0x63.FF) / 0x.8))
                return X + NewDistance * 0x.6, Y - NewCounter * 0x.8, Distance + NewDistance + NewCounter
            else
                local NewDistance = ceil((X - 0xDB.FF) / 0x.6)
                if NewCounter <= NewDistance then
                    return X - NewCounter * 0x.6, Y, Counter
                end
                NewCounter = min(NewCounter - NewDistance, ceil((Y - 0x53.FF) / 0x.8))
                return X - NewDistance * 0x.6, Y - NewCounter * 0x.8, Distance + NewDistance + NewCounter
            end
        end
    elseif Direction == 0x08 then
        if Y >= 0x81 then
            Counter = max(0, min(Counter, ceil((0xDA - X) / 0x.8)))
            return X + Counter * 0x.8, Y, Counter
        end
        if X < 0x5C then
            if Y >= 0x71 then
                local Distance = max(0, ceil((0x5A - X) / 0x.8))
                if Counter <= Distance then
                    return X + Counter * 0x.8, Y, Counter
                end
                if Y < 0x7B then
                    return X + Distance * 0x.8, Y, Distance
                end
                local NewCounter = Counter - Distance
                local NewDistance = ceil((0x81 - Y) / 0x.6)
                if NewCounter <= NewDistance then
                    return X + Distance * 0x.8, Y + NewCounter * 0x.6, Counter
                end
                return X + (Counter - NewDistance) * 0x.8, Y + NewDistance * 0x.6, Counter
            elseif Y >= 0x61 then
                local Distance = max(0, ceil((0x4A - X) / 0x.8))
                if Counter <= Distance then
                    return X + Counter * 0x.8, Y, Counter
                end
                X = X + Distance * 0x.8
                if Y < 0x6B then
                    return X, Y, Distance
                end
                local NewCounter = Counter - Distance
                local NewDistance = ceil((0x71 - Y) / 0x.6)
                if NewCounter <= NewDistance then
                    return X, Y + NewCounter * 0x.6, Counter
                end
                NewCounter = min(NewCounter - NewDistance, ceil((0x5A - X) / 0x.8))
                return X + NewCounter * 0x.8, Y + NewDistance * 0x.6, Distance + NewDistance + NewCounter
            else
                local Distance = max(0, ceil((0x3A - X) / 0x.8))
                if Counter <= Distance then
                    return X + Counter * 0x.8, Y, Counter
                end
                X = X + Distance * 0x.8
                if Y < 0x5B then
                    return X, Y, Distance
                end
                local NewCounter = Counter - Distance
                local NewDistance = ceil((0x61 - Y) / 0x.6)
                if NewCounter <= NewDistance then
                    return X, Y + NewCounter * 0x.6, Counter
                end
                NewCounter = min(NewCounter - NewDistance, ceil((0x4A - X) / 0x.8))
                return X + NewCounter * 0x.8, Y + NewDistance * 0x.6, Distance + NewDistance + NewCounter
            end
        else
            if Y >= 0x71 and Y < 0x7B then
                Counter =  min(Counter, ceil((0xEA - X) / 0x.8))
                return X + Counter * 0x.8, Y, Counter
            end
            local Distance = max(0, ceil((0xDA - X) / 0x.8))
            if Counter <= Distance then
                return X + Counter * 0x.8, Y, Counter
            end
            X = X + Distance * 0x.8
            if Y < 0x6B then
                return X, Y, Distance
            end
            local NewCounter = Counter - Distance
            if Y >= 0x7B then
                local NewDistance = ceil((Y - 0x7A.FF) / 0x.6)
                if NewCounter <= NewDistance then
                    return X, Y - NewCounter * 0x.6, Counter
                end
                NewCounter = min(NewCounter - NewDistance, ceil((0xEA - X) / 0x.8))
                return X + NewCounter * 0x.8, Y - NewDistance * 0x.6, Distance + NewDistance + NewCounter
            else
                local NewDistance = ceil((0x71 - Y) / 0x.6)
                if NewCounter <= NewDistance then
                    return X, Y + NewCounter * 0x.6, Counter
                end
                NewCounter = min(NewCounter - NewDistance, ceil((0xEA - X) / 0x.8))
                return X + NewCounter * 0x.8, Y + NewDistance * 0x.6, Distance + NewDistance + NewCounter
            end
        end
    elseif Direction == 0x10 then
        if X < 0xDC then
            Counter = min(Counter, ceil((0x99 - Y) / 0x.8))
            return X, Y + Counter * 0x.8, Counter
        end
        local Distance = max(0, ceil((0x79 - Y) / 0x.8))
        if Counter <= Distance then
            return X, Y + Counter * 0x.8, Counter
        end
        Y = Y + Distance * 0x.8
        if X >= 0xE5 then
            return X, Y, Distance
        end
        local NewCounter = Counter - Distance
        local NewDistance = ceil((X - 0xDB.FF) / 0x.6)
        if NewCounter <= NewDistance then
            return X - NewCounter * 0x.6, Y, Counter
        end
        NewCounter = min(NewCounter - NewDistance, ceil((0x99 - Y) / 0x.8))
        return X - NewDistance * 0x.6, Y + NewCounter * 0x.8, Distance + NewDistance + NewCounter
    else -- Direction == 0x18
        if X < 0x95 or Y >= 0x81 then
            Counter = min(Counter, ceil((X - 0x16.FF) / 0x.8))
            return X - Counter * 0x.8, Y, Counter
        end
        if Y >= 0x71 then
            local Distance = max(0, ceil((X - 0x96.FF) / 0x.8))
            if Counter <= Distance then
                return X - Counter * 0x.8, Y, Counter
            end
            if Y < 0x7B then
                return X - Distance * 0x.8, Y, Distance
            end
            local NewCounter = Counter - Distance
            local NewDistance = ceil((0x81 - Y) / 0x.6)
            if NewCounter <= NewDistance then
                return X - Distance * 0x.8, Y + NewCounter * 0x.6, Counter
            end
            return X - (Counter - NewDistance) * 0x.8, Y + NewDistance * 0x.6, Counter
        elseif Y >= 0x61 then
            local Distance = max(0, ceil((X - 0xA6.FF) / 0x.8))
            if Counter <= Distance then
                return X - Counter * 0x.8, Y, Counter
            end
            X = X - Distance * 0x.8
            if Y < 0x6B then
                return X, Y, Distance
            end
            local NewCounter = Counter - Distance
            local NewDistance = ceil((0x71 - Y) / 0x.6)
            if NewCounter <= NewDistance then
                return X, Y + NewCounter * 0x.6, Counter
            end
            NewCounter = min(NewCounter - NewDistance, ceil((X - 0x96.FF) / 0x.8))
            return X - NewCounter * 0x.8, Y + NewDistance * 0x.6, Distance + NewDistance + NewCounter
        else
            local Distance = max(0, ceil((X - 0xB6.FF) / 0x.8))
            if Counter <= Distance then
                return X - Counter * 0x.8, Y, Counter
            end
            X = X - Distance * 0x.8
            if Y < 0x5B then
                return X, Y, Distance
            end
            local NewCounter = Counter - Distance
            local NewDistance = ceil((0x61 - Y) / 0x.6)
            if NewCounter <= NewDistance then
                return X, Y + NewCounter * 0x.6, Counter
            end
            NewCounter = min(NewCounter - NewDistance, ceil((X - 0xA6.FF) / 0x.8))
            return X - NewCounter * 0x.8, Y + NewDistance * 0x.6, Distance + NewDistance + NewCounter
        end
    end
end

local function MoveBlue (X, Y, Direction, Counter)
    while true do
        local Distance
        if Direction >= 0x01 and Direction <= 0x07 then
            if X < 0x5C then
                if ceil((X - 0x39.FF) / BlueXChange[Direction]) <= ceil((Y - 0x60.FF) / BlueYChange[Direction]) then
                    Distance = max(0, min(Counter, ceil((0x3A - X) / BlueXChange[Direction]), ceil((0x53.FF - Y) / BlueYChange[Direction])))
                elseif ceil((X - 0x3B.FF) / BlueXChange[Direction]) <= ceil((Y - 0x63.FF) / BlueYChange[Direction]) then
                    Distance = max(0, min(Counter, ceil((0x3C - X) / BlueXChange[Direction]), ceil((0x60.FF - Y) / BlueYChange[Direction])))
                elseif ceil((X - 0x49.FF) / BlueXChange[Direction]) <= ceil((Y - 0x70.FF) / BlueYChange[Direction]) then
                    Distance = max(0, min(Counter, ceil((0x4A - X) / BlueXChange[Direction]), ceil((0x63.FF - Y) / BlueYChange[Direction])))
                elseif ceil((X - 0x4B.FF) / BlueXChange[Direction]) <= ceil((Y - 0x73.FF) / BlueYChange[Direction]) then
                    Distance = max(0, min(Counter, ceil((0x4C - X) / BlueXChange[Direction]), ceil((0x70.FF - Y) / BlueYChange[Direction])))
                elseif ceil((X - 0x59.FF) / BlueXChange[Direction]) <= ceil((Y - 0x80.FF) / BlueYChange[Direction]) then
                    Distance = max(0, min(Counter, ceil((0x5A - X) / BlueXChange[Direction]), ceil((0x73.FF - Y) / BlueYChange[Direction])))
                elseif ceil((X - 0x5B.FF) / BlueXChange[Direction]) <= ceil((Y - 0x83.FF) / BlueYChange[Direction]) then
                    Distance = max(0, min(Counter, ceil((0x5C - X) / BlueXChange[Direction]), ceil((0x80.FF - Y) / BlueYChange[Direction])))
                else
                    Distance = max(0, min(Counter, ceil((0x83.FF - Y) / BlueYChange[Direction])))
                end
            else
                if ceil((X - 0x94.FF) / BlueXChange[Direction]) < ceil((Y - 0x84) / BlueYChange[Direction]) and X < 0x95 then
                    Distance = max(0, min(Counter, ceil((0x83.FF - Y) / BlueYChange[Direction])))
                elseif ceil((X - 0xA4.FF) / BlueXChange[Direction]) < ceil((Y - 0x74) / BlueYChange[Direction]) and X < 0xA5 then
                    Distance = max(0, min(Counter, ceil((0x73.FF - Y) / BlueYChange[Direction])))
                elseif ceil((X - 0xB4.FF) / BlueXChange[Direction]) < ceil((Y - 0x64) / BlueYChange[Direction]) and X < 0xB5 then
                    Distance = max(0, min(Counter, ceil((0x63.FF - Y) / BlueYChange[Direction])))
                elseif ceil((X - 0xD9.FF) / BlueXChange[Direction]) <= ceil((Y - 0x70.FF) / BlueYChange[Direction]) then
                    Distance = max(0, min(Counter, ceil((0xDA - X) / BlueXChange[Direction]), ceil((0x53.FF - Y) / BlueYChange[Direction])))
                elseif ceil((X - 0xD9.FF) / BlueXChange[Direction]) > ceil((Y - 0x7B) / BlueYChange[Direction]) and Y >= 0x7B then
                    Distance = max(0, min(Counter, ceil((0xDA - X) / BlueXChange[Direction])))
                elseif ceil((X - 0xDB.FF) / BlueXChange[Direction]) <= ceil((Y - 0x73.FF) / BlueYChange[Direction]) then
                    Distance = max(0, min(Counter, ceil((0xDC - X) / BlueXChange[Direction]), ceil((0x70.FF - Y) / BlueYChange[Direction])))
                else
                    Distance = max(0, min(Counter, ceil((0xEA - X) / BlueXChange[Direction]), ceil((0x73.FF - Y) / BlueYChange[Direction])))
                end
            end
        elseif Direction >= 0x09 and Direction <= 0x0F then
            if X >= 0x5D then
                if ceil((X - 0xD9.FF) / BlueXChange[Direction]) > ceil((Y - 0x70.FF) / BlueYChange[Direction]) and Y < 0x71 then
                    Distance = max(0, min(Counter, ceil((0xDA - X) / BlueXChange[Direction])))
                elseif ceil((X - 0xDB.FF) / BlueXChange[Direction]) > ceil((Y - 0x79) / BlueYChange[Direction]) then
                    Distance = max(0, min(Counter, ceil((0xEA - X) / BlueXChange[Direction]), ceil((0x79 - Y) / BlueYChange[Direction])))
                elseif ceil((X - 0xD9.FF) / BlueXChange[Direction]) > ceil((Y - 0x7B) / BlueYChange[Direction]) then
                    Distance = max(0, min(Counter, ceil((0xDC - X) / BlueXChange[Direction]), ceil((0x7B - Y) / BlueYChange[Direction])))
                else
                    Distance = max(0, min(Counter, ceil((0xDA - X) / BlueXChange[Direction]), ceil((0x99 - Y) / BlueYChange[Direction])))
                end
            else
                if ceil((X - 0x39.FF) / BlueXChange[Direction]) > ceil((Y - 0x60.FF) / BlueYChange[Direction]) and Y < 0x61 then
                    Distance = max(0, min(Counter, ceil((0x3A - X) / BlueXChange[Direction])))
                elseif ceil((X - 0x49.FF) / BlueXChange[Direction]) > ceil((Y - 0x70.FF) / BlueYChange[Direction]) and Y < 0x71 then
                    Distance = max(0, min(Counter, ceil((0x4A - X) / BlueXChange[Direction])))
                elseif ceil((X - 0x59.FF) / BlueXChange[Direction]) > ceil((Y - 0x80.FF) / BlueYChange[Direction]) and Y < 0x81 then
                    Distance = max(0, min(Counter, ceil((0x5A - X) / BlueXChange[Direction])))
                else
                    Distance = max(0, min(Counter, ceil((0x99 - Y) / BlueYChange[Direction])))
                end
            end
        elseif Direction >= 0x11 and Direction <= 0x17 then
            if X >= 0x94 then
                if ceil((0xB6.FF - X) / BlueXChange[Direction]) < ceil((0x61 - Y) / BlueYChange[Direction]) and Y < 0x61 then
                    Distance = max(0, min(Counter, ceil((0xB6.FF - X) / BlueXChange[Direction])))
                elseif ceil((0xA6.FF - X) / BlueXChange[Direction]) < ceil((0x71 - Y) / BlueYChange[Direction]) and Y < 0x71 then
                    Distance = max(0, min(Counter, ceil((0xA6.FF - X) / BlueXChange[Direction])))
                elseif ceil((0x96.FF - X) / BlueXChange[Direction]) < ceil((0x81 - Y) / BlueYChange[Direction]) and Y < 0x81 then
                    Distance = max(0, min(Counter, ceil((0x96.FF - X) / BlueXChange[Direction])))
                elseif ceil((0xDB.FF - X) / BlueXChange[Direction]) > ceil((0x79 - Y) / BlueYChange[Direction]) and X >= 0xDC then
                    Distance = max(0, min(Counter, ceil((0x79 - Y) / BlueYChange[Direction])))
                else
                    Distance = max(0, min(Counter, ceil((0x16.FF - X) / BlueXChange[Direction]), ceil((0x99 - Y) / BlueYChange[Direction])))
                end
            else
                Distance = max(0, min(Counter, ceil((0x16.FF - X) / BlueXChange[Direction]), ceil((0x99 - Y) / BlueYChange[Direction])))
            end
        elseif Direction >= 0x19 and Direction <= 0x1F then
            if X >= 0x95 then
                if ceil((0x94.FF - X) / BlueXChange[Direction]) <= ceil((0x83.FF - Y) / BlueYChange[Direction]) then
                    Distance = max(0, min(Counter, ceil((0x83.FF - Y) / BlueYChange[Direction])))
                elseif ceil((0x96.FF - X) / BlueXChange[Direction]) <= ceil((0x80.FF - Y) / BlueYChange[Direction]) then
                    Distance = max(0, min(Counter, ceil((0x94.FF - X) / BlueXChange[Direction]), ceil((0x80.FF - Y) / BlueYChange[Direction])))
                elseif ceil((0xA4.FF - X) / BlueXChange[Direction]) <= ceil((0x73.FF - Y) / BlueYChange[Direction]) then
                    Distance = max(0, min(Counter, ceil((0x96.FF - X) / BlueXChange[Direction]), ceil((0x73.FF - Y) / BlueYChange[Direction])))
                elseif ceil((0xA6.FF - X) / BlueXChange[Direction]) <= ceil((0x70.FF - Y) / BlueYChange[Direction]) then
                    Distance = max(0, min(Counter, ceil((0xA4.FF - X) / BlueXChange[Direction]), ceil((0x70.FF - Y) / BlueYChange[Direction])))
                elseif ceil((0xDB.FF - X) / BlueXChange[Direction]) > ceil((0x73.FF - Y) / BlueYChange[Direction]) and X >= 0xDC then
                    Distance = max(0, min(Counter, ceil((0x73.FF - Y) / BlueYChange[Direction])))
                elseif ceil((0xB4.FF - X) / BlueXChange[Direction]) <= ceil((0x63.FF - Y) / BlueYChange[Direction]) then
                    Distance = max(0, min(Counter, ceil((0xA6.FF - X) / BlueXChange[Direction]), ceil((0x63.FF - Y) / BlueYChange[Direction])))
                elseif ceil((0xB6.FF - X) / BlueXChange[Direction]) <= ceil((0x60.FF - Y) / BlueYChange[Direction]) then
                    Distance = max(0, min(Counter, ceil((0xB4.FF - X) / BlueXChange[Direction]), ceil((0x60.FF - Y) / BlueYChange[Direction])))
                else
                    Distance = max(0, min(Counter, ceil((0xB6.FF - X) / BlueXChange[Direction]), ceil((0x53.FF - Y) / BlueYChange[Direction])))
                end
            else
                if ceil((0x5B.FF - X) / BlueXChange[Direction]) > ceil((0x83.FF - Y) / BlueYChange[Direction]) and X >= 0x5C then
                    Distance = max(0, min(Counter, ceil((0x83.FF - Y) / BlueYChange[Direction])))
                elseif ceil((0x4B.FF - X) / BlueXChange[Direction]) > ceil((0x73.FF - Y) / BlueYChange[Direction]) and X >= 0x4C then
                    Distance = max(0, min(Counter, ceil((0x73.FF - Y) / BlueYChange[Direction])))
                elseif ceil((0x3B.FF - X) / BlueXChange[Direction]) > ceil((0x63.FF - Y) / BlueYChange[Direction]) and X >= 0x3C then
                    Distance = max(0, min(Counter, ceil((0x63.FF - Y) / BlueYChange[Direction])))
                else
                    Distance = max(0, min(Counter, ceil((0x16.FF - X) / BlueXChange[Direction]), ceil((0x53.FF - Y) / BlueYChange[Direction])))
                end
            end
        elseif Direction == 0x00 then
            if X >= 0x5C and X < 0x95 then
                Distance = max(0, min(Counter, ceil((Y - 0x83.FF) / 0x.8)))
            elseif X < 0x3C or (X >= 0xB5 and X < 0xDC) then
                Distance = min(Counter, ceil((Y - 0x53.FF) / 0x.8))
            elseif (X < 0x4C and X >= 0x3C) or (X >= 0xA5 and X < 0xB5) then
                Distance = max(0, min(Counter, ceil((Y - 0x63.FF) / 0x.8)))
            else
                Distance = max(0, min(Counter, ceil((Y - 0x73.FF) / 0x.8)))
            end
        elseif Direction == 0x08 then
            if X >= 0x5D then
                if Y >= 0x7B or Y < 0x71 then
                    Distance = max(0, min(Counter, ceil((0xDA - X) / 0x.8)))
                else
                    Distance = min(Counter, ceil((0xEA - X) / 0x.8))
                end
            else
                if Y >= 0x81 then
                    Distance = Counter
                elseif Y >= 0x71 then
                    Distance = max(0, min(Counter, ceil((0x5A - X) / 0x.8)))
                elseif Y >= 0x61 then
                    Distance = max(0, min(Counter, ceil((0x4A - X) / 0x.8)))
                else
                    Distance = max(0, min(Counter, ceil((0x3A - X) / 0x.8)))
                end
            end
        elseif Direction == 0x10 then
            if X < 0xDC then
                Distance = min(Counter, ceil((0x99 - Y) / 0x.8))
            else
                Distance = max(0, min(Counter, ceil((0x79 - Y) / 0x.8)))
            end
        else -- Direction == 0x18
            if X < 0x94 then
                Distance = min(Counter, ceil((X - 0x16.FF) / 0x.8))
            else
                if Y >= 0x81 then
                    Distance = Counter
                elseif Y >= 0x71 then
                    Distance = max(0, min(Counter, ceil((X - 0x96.FF) / 0x.8)))
                elseif Y >= 0x61 then
                    Distance = max(0, min(Counter, ceil((X - 0xA6.FF) / 0x.8)))
                else
                    Distance = max(0, min(Counter, ceil((X - 0xB6.FF) / 0x.8)))
                end
            end
        end
        X = X + Distance * BlueXChange[Direction]
        Y = Y + Distance * BlueYChange[Direction]
        if Counter == Distance then return X, Y end
        Direction = BlueCollision[Direction][floor(X)][floor(Y)]
        Counter = Counter - Distance
    end
end



-- The simulation works in 3 stages:
-- First SolveGreen searches for frames where the arrow is in the right spot.
-- If one is found, CreateMovementTables is called. This function retraces the steps that led to this frame while remembering how the Blues change direction.
-- If they move towards Link, only a dummy value is remembered at this point. Then SolveBlue is called.
-- SolveBlue moves one Blue at a time based on the tables created in CreateMovementTables. When the dummy value is encountered, a distinction is made:
-- If Blue's movement can still be manipulated (because this has so far happened less often than MAXMOVESTOWARDSLINK), check all 32 directions.
-- Otherwise Blue just moves towards Link's final position.

local SeedNumber
local InitialGreenX, InitialGreenY, InitialGreenCounter, InitialGreenFrame
local InitialBlue1X, InitialBlue1Y, InitialBlue1Direction, InitialBlue1Counter, InitialBlue1Frame
local InitialBlue2X, InitialBlue2Y, InitialBlue2Direction, InitialBlue2Counter, InitialBlue2Frame
local ArrowFrame                            -- first frame where the arrow is in the right spot
local SlashFrames, SlashNumbers = {}, {}    -- when to slash the sword and how often
local BlueNumber                            -- which Blue are we looking at?
local Frames, Directions, Counters          -- tables that remembers when and how Blue changes direction
local VariableDirections = {}               -- when Blue moves towards Link, remember which direction was chosen

local function SolveBlue(X, Y, Index, NumMoveTowardsLink)
    -- NumMoveTowardsLink: how often Blue has already moved towards Link
    
    for i = Index, #Directions do
        local Direction, Counter = Directions[i], Counters[i]
        if not Direction then -- if moving towards Link
            if NumMoveTowardsLink >= MAXMOVESTOWARDSLINK then -- if Blue has already moved towards Link too many times, assume he stands in the final position
                if X >= 0x95 and X < 0x9D and Y < 0x7B then return end -- this would imply Blue hitting Link, which is considered a failure
                
                --there are 4 pixels Link can stand on so consider them separately
                for Direction in pairs(AngleTowardsFinalPosition[floor(X)][floor(Y)]) do
                    local X, Y = MoveBlue(X, Y, Direction, Counter)
                    VariableDirections[#VariableDirections + 1] = Direction -- remember which direction blue just moved in
                    SolveBlue(X, Y, i + 1, NumMoveTowardsLink) -- create new "savestate"
                    VariableDirections[#VariableDirections] = nil -- this direction has been checked now, so forget it
                end
                return -- all directions have been checked, so this instance of SolveBlue is dead
            else -- if Blue can still move towards Link, consider all possible directions
                for Direction = 0, 0x1F do
                    local X, Y = MoveBlue(X, Y, Direction, Counter)
                    VariableDirections[#VariableDirections + 1] = Direction
                    SolveBlue(X, Y, i + 1, NumMoveTowardsLink + 1) -- increase NumMoveTowardsLink
                    VariableDirections[#VariableDirections] = nil
                end
                return
            end
        end
        X, Y = MoveBlue(X, Y, Direction, Counter) -- Blue doesn't move towards Link so just move normally
    end
    
    -- check final position
    if X >= 0x9C and X < 0xA0 and Y >= 0x77 and Y < 0x7D then -- success
        io.write(format("%5d %4d %d", SeedNumber, ArrowFrame, BlueNumber)) -- write initial seed, final time, and which blue moved
        for i = 1, #SlashFrames do
            io.write(format(" %4d:%d", SlashFrames[i], SlashNumbers[i])) -- write when to slash the sword
        end
        io.write("|")
        for i = 1, #Frames do
            io.write(format(" %4d:%02X", Frames[i], VariableDirections[i])) -- write when Blue moves towards Link and in which direction
        end
        io.write("\n")
    end
end

local function CreateMovementTables()
    
    local Frames1, Frames2, Directions1, Directions2, Counters1, Counters2 = {}, {}, {}, {}, {}, {}
    local Index = 1
    local LastBlue1Frame, LastBlue2Frame

    -- reset the RNG and other values
    local RNi = InitialRNi
    local GreenX, GreenY = InitialGreenX, InitialGreenY
    local Blue1Frame, Blue2Frame, GreenFrame = InitialBlue1Frame, InitialBlue2Frame, InitialGreenFrame

    while true do
        local Frame = min(Blue1Frame, Blue2Frame, GreenFrame)
        
        if Frame > ArrowFrame then -- the frame found by SolveGreen has been reached
            Counters1[#Counters1] = ArrowFrame - LastBlue1Frame -- truncate the last counter so it ends on the critical frame
            Counters2[#Counters2] = ArrowFrame - LastBlue2Frame
            break -- move on to the next step
        end
        
        if SlashFrames[Index] and SlashFrames[Index] == Frame then -- are there sword slashes before the next RNG call?
            RNi = RNi + SlashNumbers[Index]
            Index = Index + 1
        end
        
        if Blue1Frame == Frame then
            RNi = RNi + 2
            local Blue1Direction, Blue1Counter = LAnd0FEquals1[RNi] and HAnd1F[RNi], RNAnd30Plus20[RNi] -- if moving towards Link, just remember a dummy value (false) for now
            if not Blue1Direction then
                Frames1[#Frames1 + 1] = Blue1Frame -- remember all the frames where Blue moves towards Link
            end
            Directions1[#Directions1 + 1], Counters1[#Counters1 + 1] = Blue1Direction, Blue1Counter
            LastBlue1Frame = Blue1Frame
            Blue1Frame = Blue1Frame + Blue1Counter + 1 -- Blue waits for one frame before moving again
        elseif Blue2Frame == Frame then
            RNi = RNi + 2
            local Blue2Direction, Blue2Counter = LAnd0FEquals1[RNi] and HAnd1F[RNi], RNAnd30Plus20[RNi]
            if not Blue2Direction then
                Frames2[#Frames2 + 1] = Blue2Frame
            end
            Directions2[#Directions2 + 1], Counters2[#Counters2 + 1] = Blue2Direction, Blue2Counter
            LastBlue2Frame = Blue2Frame
            Blue2Frame = Blue2Frame + Blue2Counter + 1
        else
            RNi = RNi + 2
            local GreenDirection, GreenCounter = RNAnd18[RNi], RNAnd3FPlus30[RNi]
            GreenX, GreenY, GreenCounter = MoveGreen(GreenX, GreenY, GreenDirection, GreenCounter) -- still need to remember green's position to know when it hits a wall
            GreenFrame = GreenFrame + GreenCounter + 9
        end
    end
    
    BlueNumber = 1
    Frames, Directions, Counters = Frames1, Directions1, Counters1 -- store the tables in a global variable
    SolveBlue(InitialBlue1X, InitialBlue1Y, 1, 0) -- start moving Blue
    BlueNumber = 2
    Frames, Directions, Counters = Frames2, Directions2, Counters2
    SolveBlue(InitialBlue2X, InitialBlue2Y, 1, 0)
end

local function SolveGreen(X, Y, ShotArrow, RNi, Blue1Frame, Blue2Frame, GreenFrame, LastFrame, NumSlashes)
    -- ShotArrow: boolean that determines whether green shot an arrow on the last direction change
    -- Blue1Frame, Blue2Frame, GreenFrame: the next frame where the respective enemy will call the RNG
    -- LastFrame: the last time the RNG was called; used to calculate how many sword slashes are possible
    -- NumSlashes: how many total slashes have already happened
    
    while true do
        local Frame = min(Blue1Frame, Blue2Frame, GreenFrame) -- when will the RNG be called next?
        if NumSlashes < MAXSLASHES then
            SlashFrames[#SlashFrames + 1] = Frame -- remember when the slashes happened
            for Slashes = 1, min((Frame - LastFrame) // FRAMESPERSLASH, MAXSLASHES - NumSlashes) do
                SlashNumbers[#SlashFrames] = Slashes -- remember how many slashes
                SolveGreen(X, Y, ShotArrow, RNi + Slashes, Blue1Frame, Blue2Frame, GreenFrame, Frame, NumSlashes + Slashes) -- create a "savestate" and do the slashes
            end
            SlashFrames[#SlashFrames] = nil -- all possible numbers of slashes have been tested so forget this frame
        end
        LastFrame = Frame
        
        -- figure out which enemy rolls the RNG
        if Blue1Frame == Frame then
            RNi = RNi + 2
            Blue1Frame = Blue1Frame + RNAnd30Plus21[RNi]
        elseif Blue2Frame == Frame then
            RNi = RNi + 2
            Blue2Frame = Blue2Frame + RNAnd30Plus21[RNi]
        else
            RNi = RNi + 2
            ShotArrow = not ShotArrow -- Green shoots an arrow every other time it changes direction
            local Direction, Counter = RNAnd18[RNi], RNAnd3FPlus30[RNi]
            if Direction == 0x00 and ShotArrow and X >= 0x8C and X < 0x8E and floor(Y) & 1 == 1 then -- success
                ArrowFrame = GreenFrame + (Y - 0x83) // 2 -- calculate when the arrow will be at position 0x7B
                CreateMovementTables() -- move on to the next step
            end
            X, Y, Counter = MoveGreen(X, Y, Direction, Counter)
            GreenFrame = GreenFrame + Counter + 9 -- Green waits for 9 frames before moving again
            if GreenFrame > MAXFRAME then return end -- give up at this point
        end
    end
end




local InitialTime = os.clock()

io.output("RawResults.txt")
for RNi = MinRNi, MaxRNi do
    SeedNumber = RNi
    
    -- move all enemies once since their movement can't be affected before they roll the RNG the first time
    InitialGreenX, InitialGreenY, InitialGreenCounter = MoveGreen(0x78.0, 0x88.0, RNAnd18[RNi], RNAnd3FPlus30[RNi])
    InitialGreenFrame = InitialGreenCounter + 9
    local RNi = RNi + 2
    InitialBlue1Direction, InitialBlue1Counter = LAnd0FEquals1[RNi] and HAnd1F[RNi] or 8, RNAnd30Plus20[RNi] -- if moving towards Link, simply move right
    InitialBlue1X, InitialBlue1Y = MoveBlue(0x48.0, 0x78.0, InitialBlue1Direction, InitialBlue1Counter)
    InitialBlue1Frame = InitialBlue1Counter + 2
    RNi = RNi + 2
    InitialBlue2Direction, InitialBlue2Counter = LAnd0FEquals1[RNi] and HAnd1F[RNi] or 8, RNAnd30Plus20[RNi]
    InitialBlue2X, InitialBlue2Y = MoveBlue(0x68.0, 0x88.0, InitialBlue2Direction, InitialBlue2Counter)
    InitialBlue2Frame = InitialBlue2Counter + 2
    InitialRNi = RNi
    
    -- run the simulation
    SolveGreen(InitialGreenX, InitialGreenY, false, RNi, InitialBlue1Frame, InitialBlue2Frame, InitialGreenFrame, 1, 0)
    
    local Time = os.clock() - InitialTime
    print(format("completed seed %d\nelapsed time: %s\nestimated remaining time: %s\n", SeedNumber, DisplayTime(Time), DisplayTime(Time * (MaxRNi - SeedNumber) / (SeedNumber - MinRNi + 1))))
end
io.output():close()