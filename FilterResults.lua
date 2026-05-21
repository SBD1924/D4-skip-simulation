-------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------PARAMETERS-----------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
local MAXFRAME                      = 1200 -- includes setup time (waiting on the title screen or extra screen transitions)
local MAXSLASHES                    =    6 -- max number of sword slashes to change the RNG
local MAXSLASHGROUPS                =    6
local MAXMOVESTOWARDSLINK           =    2 -- max number of times Link stands in a specific spot to change enemy movement
local FRAMESPERSLASHGROUP           =    8 -- frames to perform a group of slashes
local FRAMESPERSLASH                =   16
local ADDITIONALFRAMESONTITLESCREEN =   10 -- includes initial slashes to identify the RNG seed
local FRAMESTOGETINPOSITION         =  120 -- how long it takes to line up in one direction
local FRAMESATTHEEND                =  125 -- when Link holds the bomb
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------END OF PARAMETERS-------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------




local TwoTimesFTGIP = FRAMESTOGETINPOSITION + FRAMESTOGETINPOSITION

local min, max, floor, ceil, huge = math.min, math.max, math.floor, math.ceil, math.huge
local sub, format = string.sub, string.format


local BlueXChange = {0x.18, 0x.30, 0x.47, 0x.5A, 0x.6A, 0x.76, 0x.7D, 0x.80, 0x.7D, 0x.76, 0x.6A, 0x.5A, 0x.47, 0x.30, 0x.18, 0x.00,
-0x.18, -0x.30, -0x.47, -0x.5A, -0x.6A, -0x.76, -0x.7D, -0x.80, -0x.7D, -0x.76, -0x.6A, -0x.5A, -0x.47, -0x.30, -0x.18,}
BlueXChange[0] = 0x.00
local BlueYChange = {-0x.7D, -0x.76, -0x.6A, -0x.5A, -0x.47, -0x.30, -0x.18, 0x.00, 0x.18, 0x.30, 0x.47, 0x.5A, 0x.6A, 0x.76, 0x.7D,
0x.80, 0x.7D, 0x.76, 0x.6A, 0x.5A, 0x.47, 0x.30, 0x.18, 0x.00, -0x.18, -0x.30, -0x.47, -0x.5A, -0x.6A, -0x.76, -0x.7D,}
BlueYChange[0] = -0x.80


local RNAnd18       = {}
local RNAnd3FPlus30 = {}
local HAnd1F        = {}
local RNAnd30Plus20 = {}
local RNAnd30Plus21 = {}
local LAnd0FEquals1 = {}
local RNG           = {} -- actually stores the seed (only used when writing to file)
do
    local RNG2, RNG1 = 0x3A, 0x7B
    for i = 0, 50000 do
        local L = 3 * RNG1
        LAnd0FEquals1[i] = L & 0x0F ~= 1
        RNG2 = (3 * RNG2 + (L >> 8)) & 0xFF
        HAnd1F[i] = RNG2 & 0x1F
        RNG1 = (RNG2 + RNG1) & 0xFF
        RNAnd18[i + 1] = RNG1 & 0x18
        RNAnd3FPlus30[i] = (RNG1 & 0x3F) + 0x2F
        RNAnd30Plus20[i] = (RNG1 & 0x30) + 0x20
        RNAnd30Plus21[i] = RNAnd30Plus20[i] + 1
        RNG[i] = RNG2 * 0x100 + RNG1
    end
end


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
    
    
    -- if not against a wall, don't change direction
    for Direction = 0x00, 0x1F do
        for X = 0x16, 0xEA do
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
                or ((X == 0x5C or X == 0x94) and Y == 0x80) then --Blue in-bounds
                    BlueCollision[Direction][X][Y] = BlueCollision[Direction][X][Y] or Direction
                end
            end
        end
    end
end


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


local ToPosition = {}   -- how long it takes to get into a position where Blue's movement can be manipulated
local FromPosition = {} -- how long it takes to get from a position where Blue's movement was manipulated to the final position
local Area = {}         -- coordinates of a series of rectangles that make up the area Link has to stand in in order to manipulate Blue's movement
FromPosition[true], FromPosition[false] = {}, {} -- different tables for left and right arrow
FromPosition[true][true], FromPosition[true][false], FromPosition[false][true], FromPosition[false][false] = {}, {}, {}, {} -- different tables depending on whether Link can only stand on the upper pixel or both
for Direction = 0x00, 0x1F do
    ToPosition[Direction], FromPosition[true][true][Direction], FromPosition[true][false][Direction], FromPosition[false][true][Direction], FromPosition[false][false][Direction], Area[Direction] = {}, {}, {}, {}, {}, {}
    for X = 0x16, 0xEA do
        ToPosition[Direction][X], FromPosition[true][true][Direction][X], FromPosition[true][false][Direction][X], FromPosition[false][true][Direction][X], FromPosition[false][false][Direction][X], Area[Direction][X] = {}, {}, {}, {}, {}, {}
    end
end

-- fill these tables with the contents of Auxiliary.txt
io.input("Auxiliary.txt")
while true do
    local line = io.read()
    if not line then break end
    local Direction, X, Y = tonumber(sub(line, 1, 2), 16), tonumber(sub(line, 3, 4), 16), tonumber(sub(line, 5, 6), 16)
    if #line == 6 then
        ToPosition[Direction][X][Y], FromPosition[true][true][Direction][X][Y], FromPosition[true][false][Direction][X][Y], FromPosition[false][true][Direction][X][Y], FromPosition[false][false][Direction][X][Y] = huge, huge, huge, huge, huge
    else
        ToPosition[Direction][X][Y] = tonumber(sub(line, 7, 9))
        FromPosition[true][true][Direction][X][Y] = tonumber(sub(line, 10, 12))
        FromPosition[true][false][Direction][X][Y] = tonumber(sub(line, 13, 15))
        FromPosition[false][true][Direction][X][Y] = tonumber(sub(line, 16, 18))
        FromPosition[false][false][Direction][X][Y] = tonumber(sub(line, 19, 21))
        Area[Direction][X][Y] = sub(line, 22, -2)
    end
end
io.input():close()


-- these functions calculate how long the setup will take based on the respawn point and the desired seed
local function InsideD4(RNi)
    local Ticks = RNi - 819 - ADDITIONALFRAMESONTITLESCREEN
    return Ticks < 0 and huge or (Ticks // 516) * 102 + (Ticks % 516) -- two screen transitions take 102 frames and advance the RNG 516 times
end

local function InsideD5(RNi)
    local Ticks = RNi - 1846 - ADDITIONALFRAMESONTITLESCREEN
    if Ticks < 0 then return InsideD4(RNi) + 306 end -- if RNi is too small, it can only be reached by hard resetting in D4; the extra hard reset takes 306 frames
    local Frames = (Ticks // 516) * 102
    Ticks = Ticks % 516
    return Frames + (Ticks >= 256 and (Ticks - 256) + 130 or Ticks)
end

local function OutsideD5(RNi)
    local Ticks = RNi - 1590 - ADDITIONALFRAMESONTITLESCREEN
    if Ticks < 0 then return InsideD4(RNi) end
    local Frames = (Ticks // 516) * 102
    Ticks = Ticks % 516
    return Frames + (Ticks >= 256 and (Ticks - 256) + 130 or Ticks)
end

local SetupTime = InsideD5 -- choose respawn point


-- The raw results are run through several filters. A result will be discarded if one of the following is true:
-- - The attempt takes too long
-- - Too many slashes are needed
-- - Too many slash groups are needed
-- - The frame window for a group of slashes is too tight
-- - The last slash happens too late to be able to pull out the bomb in time
-- - The Blue we are boosting off of hits Link shortly before getting in position. Whether the other enemies hit him is not checked because that is pretty unlikely.
-- - Blue is in the wrong spot. This happens if Link is on the right pixel and Blue is at its leftmost position (hitting Link) or if Link is on the left pixel and Blue is at its rightmost position (out of reach).
-- - Blue moved out of position one frame later, so the second frame for the shield boost wouldn't work
-- - Blue needs to move towards Link too many times
-- - There's not enough time to get into a position that makes Blue move in a certain direction
-- - There's not enough time to get from such a position to the final spot
-- (Whether there is enough time to get from one such position to another is not checked because it would be a lot to calculate)
-- - There isn't enough time between slashes to line up Link's position


--local LineNumber = 0
local Results = {} -- attempts that survive all the filters go here

io.input("RawResults.txt")
while true do
    local line = io.read()
    if not line then break end
    --LineNumber = LineNumber + 1
    
    local SeedNumber = tonumber(sub(line, 1, 5))
    local ArrowFrame = tonumber(sub(line, 7, 10))

    if ArrowFrame + SetupTime(SeedNumber) > MAXFRAME then goto continue end -- attempt takes too long

    local FinalFrame = ArrowFrame - FRAMESATTHEEND -- the bomb has to be pulled by this frame, so everything needs to be set up already
    local FrameWhenInPosition = FinalFrame - TwoTimesFTGIP -- use this to calculate if Link can get into position in time
    local BlueNumber = tonumber(sub(line, 12, 12))
    local SlashFrames, SlashNumbers = {}, {}
    local DirectionFrames, VariableDirections = {}, {}
    do
        local Index = 13
        local sum = 0
        while true do
            if sub(line, Index, Index) == "|" then break end
            SlashFrames[#SlashFrames + 1] = tonumber(sub(line, Index + 1, Index + 4))
            SlashNumbers[#SlashFrames] = tonumber(sub(line, Index + 6, Index + 6))
            sum = sum + SlashNumbers[#SlashNumbers]

            if sum > MAXSLASHES then goto continue end -- too many slashes

            Index = Index + 7
        end
        
        if #SlashFrames > MAXSLASHGROUPS then goto continue end
        
        for i = Index + 2, #line, 8 do
            DirectionFrames[#DirectionFrames + 1] = tonumber(sub(line, i, i + 3))
            VariableDirections[#DirectionFrames] = tonumber(sub(line, i + 5, i + 6), 16)
        end
    end
    
    local Xs, Ys = {}, {}               -- where Blue is when moving towards Link
    local Directions, Counters = {}, {} -- directions and counters for the last part, which is analysed frame by frame
    local LastFrames = {}               -- the first possible frames for sword slashes
    local X, Y                          -- Blue's position as soon as moving frame by frame starts
    local DoesNotMove                   -- if Blue chooses a new direction on the exact frame it gets in position, it won't move on the frame after
    local CounterTillFrameWhenInPosition         -- how long before moving frame by frame
    local BlueFinished, GreenFinished   -- Green can reach the position it fires the arrow at slightly before or after the critical frame, depending on its Y-position. Need to remember if this position was already stored.
    local ArrowIsLeft                   -- whether the Arrow's X-position is 0x87 or 0x88
    
    -- if both Blues call the RNG on the same frame, the order depends on which is which, so both need to be looked at separately
    if BlueNumber == 1 then
        local RNi = SeedNumber
        local GreenX, GreenY, GreenCounter = MoveGreen(0x78.0, 0x88.0, RNAnd18[RNi], RNAnd3FPlus30[RNi])
        local GreenFrame = GreenCounter + 9
        RNi = RNi + 2
        local Blue1Direction, Blue1Counter = LAnd0FEquals1[RNi] and HAnd1F[RNi] or 8, RNAnd30Plus20[RNi]
        local Blue1X, Blue1Y = MoveBlue(0x48.0, 0x78.0, Blue1Direction, Blue1Counter)
        local Blue1Frame = Blue1Counter + 2
        RNi = RNi + 2
        local Blue2Frame = RNAnd30Plus20[RNi] + 2
        
        local LastFrame = 1
        local SlashIndex = 1
        local DirectionIndex = 0
        
        while true do
            local Frame = min(Blue1Frame, Blue2Frame, GreenFrame)
            
            if SlashFrames[SlashIndex] and SlashFrames[SlashIndex] == Frame then

                if Frame - LastFrame < FRAMESPERSLASHGROUP + SlashNumbers[SlashIndex] * FRAMESPERSLASH and LastFrame > 1 then goto continue end -- not enough time to perform the slashes (ignore this check at the very start since slashes are easier to time there)

                RNi = RNi + SlashNumbers[SlashIndex]
                SlashIndex = SlashIndex + 1
                LastFrames[#LastFrames + 1] = LastFrame -- LastFrames stores the first frame the sword can be slashed and SlashFrames stores the last
            end
            
            if Blue1Frame == Frame then
                RNi = RNi + 2
                local Blue1Counter, Blue1Direction = RNAnd30Plus20[RNi]
                if not BlueFinished then -- if Blue is already done, only update the frame
                    if LAnd0FEquals1[RNi] then
                        Blue1Direction = HAnd1F[RNi]
                    else
                        DirectionIndex = DirectionIndex + 1
                        Blue1Direction = VariableDirections[DirectionIndex]
                        Xs[#Xs + 1], Ys[#Ys + 1] = floor(Blue1X), floor(Blue1Y) -- remember Blue's position for later
                    end
                    if Blue1Frame + Blue1Counter >= ArrowFrame then -- if we have reached the critical frame
                        if Blue1Frame + Blue1Counter == ArrowFrame then DoesNotMove = true end -- equality means Blue will call the RNG on the next frame
                        Directions[#Directions + 1] = Blue1Direction
                        Counters[#Directions] = ArrowFrame - Blue1Frame -- truncate counter to end on ArrowFrame
                        if GreenFinished then break else BlueFinished = true end
                    end
                    if DirectionIndex > MAXMOVESTOWARDSLINK or Blue1Frame + Blue1Counter >= FrameWhenInPosition then -- at this point assume Link stands in the final position and make sure Blue does not hit him
                        X, Y = X or Blue1X, Y or Blue1Y -- remember this position if not already done
                        CounterTillFrameWhenInPosition = CounterTillFrameWhenInPosition or (DirectionIndex > MAXMOVESTOWARDSLINK and 0 or FrameWhenInPosition - Blue1Frame) -- If this was triggered by Blue moving towards Link, don't wait here. Otherwise wait until FrameWhenInPosition is reached.
                        Directions[#Directions + 1] = Blue1Direction
                        Counters[#Directions] = Blue1Counter
                    end
                    Blue1X, Blue1Y = MoveBlue(Blue1X, Blue1Y, Blue1Direction, Blue1Counter)
                end
                Blue1Frame = Blue1Frame + Blue1Counter + 1
            elseif Blue2Frame == Frame then
                RNi = RNi + 2
                Blue2Frame = Blue2Frame + RNAnd30Plus21[RNi]
            else
                RNi = RNi + 2
                local GreenDirection, GreenCounter = RNAnd18[RNi], RNAnd3FPlus30[RNi]
                if GreenFrame + 11 >= ArrowFrame and not GreenFinished then -- it takes at most 11 frames for the arrow to get in position
                    ArrowIsLeft = GreenX < 0x8D
                    if BlueFinished then break else GreenFinished = true end
                end
                GreenX, GreenY, GreenCounter = MoveGreen(GreenX, GreenY, GreenDirection, GreenCounter)
                GreenFrame = GreenFrame + GreenCounter + 9
            end
            LastFrame = Frame
        end
    else -- BlueNumber == 2
        local RNi = SeedNumber
        local GreenX, GreenY, GreenCounter = MoveGreen(0x78.0, 0x88.0, RNAnd18[RNi], RNAnd3FPlus30[RNi])
        local GreenFrame = GreenCounter + 9
        RNi = RNi + 2
        local Blue1Frame = RNAnd30Plus20[RNi] + 2
        RNi = RNi + 2
        local Blue2Direction, Blue2Counter = LAnd0FEquals1[RNi] and HAnd1F[RNi] or 8, RNAnd30Plus20[RNi]
        local Blue2X, Blue2Y = MoveBlue(0x68.0, 0x88.0, Blue2Direction, Blue2Counter)
        local Blue2Frame = Blue2Counter + 2
        
        local LastFrame = 1
        local SlashIndex = 1
        local DirectionIndex = 0
        
        while true do
            local Frame = min(Blue1Frame, Blue2Frame, GreenFrame)
            
            if SlashFrames[SlashIndex] and SlashFrames[SlashIndex] == Frame then

                if Frame - LastFrame < FRAMESPERSLASHGROUP + SlashNumbers[SlashIndex] * FRAMESPERSLASH and LastFrame > 1 then goto continue end

                RNi = RNi + SlashNumbers[SlashIndex]
                SlashIndex = SlashIndex + 1
                LastFrames[#LastFrames + 1] = LastFrame
            end
            
            if Blue1Frame == Frame then
                RNi = RNi + 2
                Blue1Frame = Blue1Frame + RNAnd30Plus21[RNi]
            elseif Blue2Frame == Frame then
                RNi = RNi + 2
                local Blue2Counter, Blue2Direction = RNAnd30Plus20[RNi]
                if not BlueFinished then
                    if LAnd0FEquals1[RNi] then
                        Blue2Direction = HAnd1F[RNi]
                    else
                        DirectionIndex = DirectionIndex + 1
                        Blue2Direction = VariableDirections[DirectionIndex]
                        Xs[#Xs + 1], Ys[#Ys + 1] = floor(Blue2X), floor(Blue2Y)
                    end
                    if Blue2Frame + Blue2Counter >= ArrowFrame then
                        if Blue2Frame + Blue2Counter == ArrowFrame then DoesNotMove = true end
                        Directions[#Directions + 1] = Blue2Direction
                        Counters[#Directions] = ArrowFrame - Blue2Frame
                        if GreenFinished then break else BlueFinished = true end
                    end
                    if DirectionIndex > MAXMOVESTOWARDSLINK or Blue2Frame + Blue2Counter >= FrameWhenInPosition then
                        X, Y = X or Blue2X, Y or Blue2Y
                        CounterTillFrameWhenInPosition = CounterTillFrameWhenInPosition or (DirectionIndex > MAXMOVESTOWARDSLINK and 0 or FrameWhenInPosition - Blue2Frame)
                        Directions[#Directions + 1] = Blue2Direction
                        Counters[#Directions] = Blue2Counter
                    end
                    Blue2X, Blue2Y = MoveBlue(Blue2X, Blue2Y, Blue2Direction, Blue2Counter)
                end
                Blue2Frame = Blue2Frame + Blue2Counter + 1
            else
                RNi = RNi + 2
                local GreenDirection, GreenCounter = RNAnd18[RNi], RNAnd3FPlus30[RNi]
                GreenX, GreenY, GreenCounter = MoveGreen(GreenX, GreenY, GreenDirection, GreenCounter)
                GreenFrame = GreenFrame + GreenCounter + 9
                if GreenFrame + 11 >= ArrowFrame and not GreenFinished then
                    ArrowIsLeft = GreenX < 0x8D
                    if BlueFinished then break else GreenFinished = true end
                end
            end
            LastFrame = Frame
        end
    end

    if #LastFrames > 0 and LastFrames[#LastFrames] + 17 > FinalFrame then goto continue end -- last slash happens too late
    if not LastFrames[#SlashFrames] then goto continue end -- if SlashFrames has more entries than LastFrames, that also means the last slash happened too late (after Blue's last direction change)
    

    -- at this point start moving frame by frame to check if Link gets hit at any point
    local OnlyUpper = false -- if Link can only stand on the upper pixel because he will otherwise get hit
    local Direction = Directions[1]

    -- first simply move until FrameWhenInPosition is reached
    for j = 1, CounterTillFrameWhenInPosition do
        Direction = BlueCollision[Direction][floor(X)][floor(Y)]
        X, Y = X + BlueXChange[Direction], Y + BlueYChange[Direction]
    end
    
    if ArrowIsLeft then
        for j = CounterTillFrameWhenInPosition + 1, Counters[1] do
            Direction = BlueCollision[Direction][floor(X)][floor(Y)]
            X, Y = X + BlueXChange[Direction], Y + BlueYChange[Direction]
            if X < 0x9D and Y < 0x7C and X >= 0x95 then
                if Y < 0x7B then goto continue end -- Link is hit
                OnlyUpper = true -- we can still dodge Blue by standing on the upper pixel
            end
        end
        for i = 2, #Directions do
            Direction = Directions[i]
            for j = 1, Counters[i] do
                Direction = BlueCollision[Direction][floor(X)][floor(Y)]
                X, Y = X + BlueXChange[Direction], Y + BlueYChange[Direction]
                if X < 0x9D and Y < 0x7C and X >= 0x95 then
                    if Y < 0x7B then goto continue end
                    OnlyUpper = true
                end
            end
        end

        if X >= 0x9F then goto continue end -- the rightmost position doesn't work if the arrow is on the left

        if not DoesNotMove then
            X, Y = X + BlueXChange[Direction], Y + BlueYChange[Direction]
            if X < 0x9C or X >= 0x9F or Y < 0x77 or Y >= 0x7D then goto continue end -- Blue has moved out of position, so the second frame would not work
        end
    else -- arrow is right
        for j = CounterTillFrameWhenInPosition + 1, Counters[1] do
            Direction = BlueCollision[Direction][floor(X)][floor(Y)]
            X, Y = X + BlueXChange[Direction], Y + BlueYChange[Direction]
            if X < 0x9E and Y < 0x7C and X >= 0x95 then
                if Y < 0x7B then goto continue end
                OnlyUpper = true
            end
        end
        for i = 2, #Directions do
            Direction = Directions[i]
            for j = 1, Counters[i] do
                Direction = BlueCollision[Direction][floor(X)][floor(Y)]
                X, Y = X + BlueXChange[Direction], Y + BlueYChange[Direction]
                if X < 0x9E and Y < 0x7C and X >= 0x95 then
                    if Y < 0x7B then goto continue end
                    OnlyUpper = true
                end
            end
        end

        if X < 0x9D then goto continue end -- the leftmost position doesn't work if the arrow is on the right

        if not DoesNotMove then
            X, Y = X + BlueXChange[Direction], Y + BlueYChange[Direction]
            if X < 0x9D or X >= 0xA0 or Y < 0x77 or Y >= 0x7D then goto continue end
        end
    end
    

    
    if DirectionFrames[1] and ToPosition[VariableDirections[1]][Xs[1]][Ys[1]] > DirectionFrames[1] then goto continue end
    local FirstFrame = 0 -- the first frame where Link can be in the final spot
    for i = 1, #DirectionFrames do
        local Frame, X, Y, Direction = DirectionFrames[i], Xs[i], Ys[i], VariableDirections[i]
        if FromPosition[ArrowIsLeft][OnlyUpper][Direction][X][Y] ~= 0 then
            if Frame + FromPosition[ArrowIsLeft][OnlyUpper][Direction][X][Y] > FinalFrame then goto continue end -- getting from the position to the final spot takes too long
            if i > MAXMOVESTOWARDSLINK then goto continue end

            FirstFrame = Frame + FromPosition[ArrowIsLeft][OnlyUpper][Direction][X][Y]
        end
    end
    
    local Index -- index of the first slash that happens after Link could already be in position
    for i = 1, #SlashFrames do
        if SlashFrames[i] > FirstFrame then
            Index = i
            break
        end
    end
    if Index then
        local GetInPosition = 0 -- how often there was time to line up Link's position
        if SlashFrames[Index] - FirstFrame >= FRAMESTOGETINPOSITION then
            GetInPosition = 1
            if SlashFrames[Index] - FirstFrame >= TwoTimesFTGIP then GetInPosition = 2 end
        end
        for i = Index + 1, #SlashFrames do
            if SlashFrames[i] - SlashFrames[i - 1] >= FRAMESTOGETINPOSITION then
                GetInPosition = GetInPosition + 1
                if SlashFrames[i] - SlashFrames[i - 1] >= TwoTimesFTGIP then GetInPosition = 2 end
            end
        end
        if FinalFrame - SlashFrames[#SlashFrames] >= FRAMESTOGETINPOSITION then
            GetInPosition = GetInPosition + 1
            if FinalFrame - SlashFrames[#SlashFrames] >= TwoTimesFTGIP then
                GetInPosition = 2
            end
        end

        if GetInPosition < 2 then goto continue end -- not enough time to line up position

    elseif FinalFrame - FirstFrame < TwoTimesFTGIP then goto continue -- not enough time to line up position
    end
    

    local TotalTime = ArrowFrame + SetupTime(SeedNumber)
    if TotalTime > MAXFRAME then goto continue end -- attempt takes too long



    -- attempts that survive until here are considered a success

    -- Comment out the next section if you don't want to change how the line is represented. This means that the resulting file can be used again to run through this script.
    ---[=[
    local line = format("%5d %04X %4d %4d %d %s,%s", SeedNumber - 261, RNG[SeedNumber - 261], TotalTime, ArrowFrame, BlueNumber, ArrowIsLeft and "90" or "91", OnlyUpper and "6E" or "6F") -- subtract 261 to get the RNG before entering the room
    local SlashIndex, DirectionIndex = 1, 1
    while true do
        -- put slashes and direction changes in chronological order
        local SlashFrame, DirectionFrame = SlashFrames[SlashIndex], DirectionFrames[DirectionIndex]
        if not SlashFrame then
            if not DirectionFrame then break end
            line = line .. format(" %d:%02X", DirectionFrame, VariableDirections[DirectionIndex])
            line = line .. Area[VariableDirections[DirectionIndex]][Xs[DirectionIndex]][Ys[DirectionIndex]]
            DirectionIndex = DirectionIndex + 1
        elseif not DirectionFrame or SlashFrame <= DirectionFrame then
            line = line .. format(" %d-%d:%d", LastFrames[SlashIndex], SlashFrame, SlashNumbers[SlashIndex])
            SlashIndex = SlashIndex + 1
        else
            line = line .. format(" %d:%02X", DirectionFrame, VariableDirections[DirectionIndex])
            line = line .. Area[VariableDirections[DirectionIndex]][Xs[DirectionIndex]][Ys[DirectionIndex]]
            DirectionIndex = DirectionIndex + 1
        end
    end
    --]=]
    Results[#Results + 1] = {TotalTime, SeedNumber, line}    
    
::continue:: -- attempts that don't survive land here
end
io.input():close()


io.output("Results.txt")
-- sort results based on overall time including setup
table.sort(Results, function (a, b) return a[1] < b[1] or a[1] == b[1] and a[2] < b[2] end)
for i = 1, #Results do
    io.write(Results[i][3], "\n")
end
io.output():close()

-- What the numbers in this file mean (in order):
-- - The index of the RNG seed just before entering the room
-- - The seed itself (in little endian)
-- - The total time including setup
-- - Only the time spent in the room, without setup (starting from the first frame you have control)
-- - Which Blue are we looking at? (in the order they are loaded in memory; 1 is the one that starts off-screen)
-- - Where Link has to stand at the end. (If the Y-position reads 6F, 6E will also work)
-- - After that are the actions you have to perform while in the room, separated by spaces:
--   - If the group start with a range, that is the frame window to perform a certain amount of slashes. The number after the colon tells you how many times to slash in that window.
--   - If the group starts with a single number, that means you have to stand in a certain area at this frame. The area is then given as a series of rectangle coordinates, the single rectangles separated by semicola.