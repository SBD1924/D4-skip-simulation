local min, max, floor, ceil, abs, huge = math.min, math.max, math.floor, math.ceil, math.abs, math.huge


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


local LinkPossiblePositions = {} -- all the positions Link can stand in
for X = 0x14, 0xEA do
    LinkPossiblePositions[X] = {}
end
for X = 0x14, 0xEA do
    for Y = 0x52, 0x99 do
        if X < 0x40
        or (X < 0xDE
        and (X >= 0xB0
        or ((X < 0x50 or X >= 0xA0) and Y >= 0x5B)
        or ((X < 0x60 or X >= 0x90) and Y >= 0x6B)
        or Y >= 0x7B))
        or (X >= 0xDE and Y >= 0x70 and Y < 0x7B) then
            LinkPossiblePositions[X][Y] = true
        end
    end
end

local BluePossiblePositions = {} -- all the positions Blue can stand in
for X = 0x16, 0xEA do
    BluePossiblePositions[X] = {}
end
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
        or ((X == 0x5C or X == 0x94) and Y == 0x80) then
            BluePossiblePositions[X][Y] = true
        end
    end
end


local ToPosition = {}   -- how long it takes to get to each position from the start of the room
local FromPosition = {} -- how long it takes to get from a position to the final spot
FromPosition[true], FromPosition[false] = {}, {}
FromPosition[true][true], FromPosition[true][false], FromPosition[false][true], FromPosition[false][false] = {}, {}, {}, {}
for X = 0x14, 0xEA do
    ToPosition[X] = {}
    FromPosition[true][true][X], FromPosition[true][false][X], FromPosition[false][true][X], FromPosition[false][false][X] = {}, {}, {}, {}
    for Y = 0x52, 0x99 do
        if LinkPossiblePositions[X][Y] then
            if Y >= 0x7B then
                ToPosition[X][Y] = 0x6D - X + Y
                FromPosition[true][true][X][Y] = abs(X - 0x90) + Y - 0x6E
                FromPosition[true][false][X][Y] = FromPosition[true][true][X][Y] - 1
                FromPosition[false][true][X][Y] = abs(X - 0x91) + Y - 0x6E
                FromPosition[false][false][X][Y] = FromPosition[false][true][X][Y] - 1
            elseif X < 0x90 then
                ToPosition[X][Y] = 0x163 - X - Y
                FromPosition[true][true][X][Y] = 0x118 - X - Y
                FromPosition[true][false][X][Y] = FromPosition[true][true][X][Y] - 1
                FromPosition[false][true][X][Y] = FromPosition[true][true][X][Y] + 1
                FromPosition[false][false][X][Y] = FromPosition[true][true][X][Y]
            else
                ToPosition[X][Y] = abs(X - 0xE7) + max(0, 0x70 - Y)
                FromPosition[true][true][X][Y] = abs(X - 0x90) + abs(Y - 0x6E)
                FromPosition[true][false][X][Y] = abs(X - 0x90) + min(abs(Y - 0x6E), abs(Y - 0x6F))
                FromPosition[false][true][X][Y] = abs(X - 0x91) + abs(Y - 0x6E)
                FromPosition[false][false][X][Y] = abs(X - 0x91) + min(abs(Y - 0x6E), abs(Y - 0x6F))
            end
        end
    end
end


io.output("Auxiliary.txt")
for Direction = 0x00, 0x1F do
    for BlueX = 0x16, 0xEA do
        for BlueY = 0x53, 0x99 do
            if BluePossiblePositions[BlueX][BlueY] then
                local Min  = huge
                local Min1 = huge
                local Min2 = huge
                local Min3 = huge
                local Min4 = huge
                local Area = {}
                for LinkX = 0x14, 0xEA do
                    if (LinkX >= BlueX and Direction <= 0x10) or (BlueX >= LinkX and (Direction >= 0x10 or Direction == 0x00)) then -- if Link is on the wrong side of Blue, it can't possibly walk in the right direction
                        Area[LinkX] = {}
                        for LinkY = 0x52, 0x99 do
                            if LinkPossiblePositions[LinkX][LinkY]
                            and ((LinkY >= BlueY and Direction >= 0x08 and Direction <= 0x18) or (BlueY >= LinkY and (Direction <= 0x08 or Direction >= 0x18)))
                            and AngleTowardsTarget(BlueX, BlueY, LinkX, LinkY) == Direction
                            and (BlueX - LinkX > 0x0D or LinkX - BlueX > 0x0B or BlueY - LinkY > 0x0C or LinkY - BlueY > 0x0B) then -- make sure Link is not so close he is getting hit
                                Min  = min(Min , ToPosition[LinkX][LinkY])
                                Min1 = min(Min1, FromPosition[true][true][LinkX][LinkY])
                                Min2 = min(Min2, FromPosition[true][false][LinkX][LinkY])
                                Min3 = min(Min3, FromPosition[false][true][LinkX][LinkY])
                                Min4 = min(Min4, FromPosition[false][false][LinkX][LinkY])
                                Area[LinkX][LinkY] = true
                            end
                        end
                    end
                end

                io.write(string.format("%02X%02X%02X", Direction, BlueX, BlueY))
                if Min ~= huge then
                    io.write(string.format("%3d%3d%3d%3d%3d:", Min, Min1, Min2, Min3, Min4))
                    
                    -- instead of printing each set of coordinates separately, print them as the coordinates of a rectangle
                    for X = 0x14, 0xEA do
                        for Y = 0x52, 0x99 do
                            if Area[X] and Area[X][Y] then
                                local i = 0
                                while true do
                                    i = i + 1
                                    if (not Area[X + i]) or (not Area[X + i][Y]) then break end
                                end
                                local MaxX = X + i - 1
                                i = 0
                                while true do
                                    i = i + 1
                                    for x = X, MaxX do
                                        if not Area[x][Y + i] then goto continue end
                                    end
                                end
                                ::continue::
                                local MaxY = Y + i - 1
                                
                                io.write(string.format("%02X-%02X,%02X-%02X;", X, MaxX, Y, MaxY))
                                
                                for x = X, MaxX do
                                    for y = Y, MaxY do
                                        Area[x][y] = nil
                                    end
                                end
                            end
                        end
                    end
                end
                io.write("\n")
            end
        end
    end
end
io.output():close()