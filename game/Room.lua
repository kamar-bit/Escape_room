-- ════════════════════════════════════════════
--  Room.lua  (base class)
-- ════════════════════════════════════════════
local R = require("systems.Renderer")
local Room = {}

function Room:new(name, accentColor)
    local r = {
        name        = name,
        background  = nil,
        objects     = {},
        terminal    = nil,
        isSolved    = false,
        door        = {x=0, y=0, w=52, h=64, locked=true},
        accentColor = accentColor or R.C.green,
        dialog      = {visible=false, title="", body="", objectId=nil},
        keypad      = {visible=false, buffer="", wrongFlash=0},
        hints       = {},
    }
    setmetatable(r, self)
    self.__index = self
    return r
end

function Room:load() end

function Room:update(dt, player)
    for _, obj in ipairs(self.objects) do obj:update(dt) end
    if self.keypad.wrongFlash and self.keypad.wrongFlash > 0 then
        self.keypad.wrongFlash = self.keypad.wrongFlash - dt * 3
    end
end

-- Subclasses override drawTheme() to paint their world
function Room:drawTheme(x, y, w, h) end

function Room:drawBackground()
    local UI = require("systems.UIManager")
    local x, y = 0, UI.HUD_H
    local w, h  = UI.ROOM_W, UI.ROOM_H
    -- Delegate to themed draw
    self:drawTheme(x, y, w, h)
    -- Nameplate
    love.graphics.setFont(R.font_tiny)
    love.graphics.setColor(self.accentColor[1], self.accentColor[2], self.accentColor[3], 0.35)
    love.graphics.printf(self.name, x, y + 10, w, "center")
end

function Room:drawDoor()
    local d  = self.door
    local ac = self.accentColor
    local isSolved = self.isSolved or (self.terminal and self.terminal.isSolved)
    local col = isSolved and ac or R.C.red

    -- Draw is delegated per room — base version: simple arch door
    self:drawDoorTheme(d, col, isSolved)
end

-- Default door (overridden per room)
function Room:drawDoorTheme(d, col, isSolved)
    love.graphics.setColor(col[1], col[2], col[3], isSolved and 0.18 or 0.08)
    love.graphics.rectangle("fill", d.x, d.y, d.w, d.h)
    love.graphics.setColor(col[1], col[2], col[3], 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", d.x, d.y, d.w, d.h)
    love.graphics.setLineWidth(1)
    love.graphics.setFont(R.font_tiny)
    love.graphics.setColor(col[1], col[2], col[3], 0.9)
    love.graphics.printf(isSolved and ">>>" or "---", d.x, d.y + 4, d.w, "center")
    if isSolved and self.terminal then
        love.graphics.setColor(col[1], col[2], col[3], 0.95)
        love.graphics.printf(self.terminal.doorCode, d.x - 4, d.y + d.h - 14, d.w + 8, "center")
    end
end

function Room:draw(player)
    self:drawBackground()
    for _, obj in ipairs(self.objects) do
        obj:draw(player and player:getCenterX() or 0,
                 player and player:getCenterY() or 0)
    end
    self:drawDoor()
end

return Room
