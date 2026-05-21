-- start this script sometime before entering the D4-Skip room
-------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------PARAMETERS-----------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
local TextY      = (client.getwindowsize() - 1) * 0x10 -- Y-position of the first line of code
local LineNumber = 1                                   -- which line in Results.txt to use
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------END OF PARAMETERS-------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------



local TextY2 = TextY + 0x10
local TextY3 = TextY + 0x20

local RED,     BLUE,     GREEN     = 0xC0FF0000, 0xC00000FF, 0xC000FF00
local REDTEXT, BLUETEXT, GREENTEXT = 0xFFFF0000, 0xFF0000FF, 0xFF00FF00


local line
io.input("Results.txt")
for i = 1, LineNumber do
    line = io.read()
end
io.input():close()



local RNG2, RNG1 = tonumber(string.sub(line, 7, 8), 16), tonumber(string.sub(line, 9, 10), 16)
local ArrowFrame = tonumber(string.sub(line, 17, 20)) + 56
local BlueNumberAndPosition = string.sub(line, 22, 28)

local ActiveRoomAddress = 0xCC30
local ClockAddress = 0xC622
local XoffsetAddress, YoffsetAddress = 0xC493, 0xC492
local RNG2Address, RNG1Address = 0xFF95, 0xFF94



local FirstSlashFrames, LastSlashFrames, SlashNumbers = {}, {}, {}
local DirectionFrames, Directions, Areas = {}, {}, {}

for FirstSlashFrame, LastSlashFrame, SlashNumber in string.gmatch(line, "(%d+)-(%d+):(%d)") do
    FirstSlashFrames[#FirstSlashFrames + 1] = tonumber(FirstSlashFrame) + 56
    LastSlashFrames[#FirstSlashFrames] = tonumber(LastSlashFrame) + 56
    SlashNumbers[#FirstSlashFrames] = tonumber(SlashNumber)
end

for DirectionFrame, Direction, Area in string.gmatch(line, "(%d+):([%dA-F][%dA-F]):?(%g*)") do
    DirectionFrames[#DirectionFrames + 1] = tonumber(DirectionFrame) + 56
    Directions[#DirectionFrames] = tonumber(Direction, 16)
    Areas[#DirectionFrames] = {}
    for MinX, MaxX, MinY, MaxY in string.gmatch(Area, "([%dA-F][%dA-F])-([%dA-F][%dA-F]),([%dA-F][%dA-F])-([%dA-F][%dA-F])") do
        Areas[#Areas][#Areas[#Areas] + 1] = {MinX = tonumber(MinX, 16) - 0x50, MaxX = tonumber(MaxX, 16) - 0x50, MinY = tonumber(MinY, 16) - 0x20, MaxY = tonumber(MaxY, 16) - 0x20}
    end
end



--savestate.save("lua")
--savestate.load("lua")
--memory.writebyte(RNG2Address, RNG2)
--memory.writebyte(RNG1Address, RNG1)


local InitialFrame

gui.clearGraphics()
while true do
    gui.text(0, TextY3, BlueNumberAndPosition, nil, "topright")
    
    if InitialFrame then
        local Xoffset, Yoffset = memory.readbyte(XoffsetAddress), memory.readbyte(YoffsetAddress)
        local Frame = memory.read_u32_le(ClockAddress) - InitialFrame
        
        if (not LastSlashFrames[1] or Frame > LastSlashFrames[#LastSlashFrames]) and (not DirectionFrames[1] or Frame > DirectionFrames[#DirectionFrames]) then
            gui.text(0, TextY, ArrowFrame - Frame, nil, "topright")
            if Frame >= ArrowFrame then break end
        else
            for i = 1, #FirstSlashFrames do
                if Frame <= FirstSlashFrames[i] then
                    gui.text(0, TextY, string.format("%d: %d", FirstSlashFrames[i] - Frame, SlashNumbers[i]), BLUETEXT, "topright")
                    break
                elseif Frame <= LastSlashFrames[i] then
                    gui.text(0, TextY, string.format("%d: %d", LastSlashFrames[i] - Frame, SlashNumbers[i]), REDTEXT, "topright")
                    break
                end
            end
            
            if DirectionFrames[1] and Frame == DirectionFrames[#DirectionFrames] then
                gui.clearGraphics()
            else
                for i = 1, #DirectionFrames do
                    if Frame <= DirectionFrames[i] then
                        gui.text(0, TextY2, string.format("%d: %02X", DirectionFrames[i] - Frame, Directions[i]), GREENTEXT, "topright")
                        for j = 1, #Areas[i] do
                            gui.drawBox(Areas[i][j].MinX - Xoffset, Areas[i][j].MinY - Yoffset, Areas[i][j].MaxX - Xoffset, Areas[i][j].MaxY - Yoffset, GREEN, GREEN)
                        end
                        break
                    end
                end
            end
        end
        
    elseif memory.readbyte(ActiveRoomAddress) == 0x8C then
        InitialFrame = memory.read_u32_le(ClockAddress)
        local Xoffset, Yoffset = (memory.readbyte(XoffsetAddress) - 0xA0) & 0xFF, memory.readbyte(YoffsetAddress)
        for i = 1, #Areas do
            for j = 1, #Areas[i] do
                Areas[i][j].MinX = Areas[i][j].MinX + Xoffset
                Areas[i][j].MaxX = Areas[i][j].MaxX + Xoffset
                Areas[i][j].MinY = Areas[i][j].MinY + Yoffset
                Areas[i][j].MaxY = Areas[i][j].MaxY + Yoffset
            end
        end
    end
    
    
    emu.frameadvance()
end