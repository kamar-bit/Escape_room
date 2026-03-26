-- ════════════════════════════════════════════
--  Player.lua
-- ════════════════════════════════════════════
local Player = {}

function Player:new(x, y)
    local p = {
        x=x, y=y, speed=130, width=20, height=28,
        walkTimer=0, walkFrame=0, facing="down", inventory={},
    }
    setmetatable(p, self); self.__index = self
    return p
end

function Player:update(dt, room)
    local R = require("systems.UIManager")
    local dx, dy = 0, 0
    if love.keyboard.isDown("up","z","w")   then dy=-1; self.facing="up"    end
    if love.keyboard.isDown("down","s")     then dy= 1; self.facing="down"  end
    if love.keyboard.isDown("left","q","a") then dx=-1; self.facing="left"  end
    if love.keyboard.isDown("right","d")    then dx= 1; self.facing="right" end
    if dx~=0 and dy~=0 then dx=dx*0.707; dy=dy*0.707 end

    local nx = self.x + dx*self.speed*dt
    local ny = self.y + dy*self.speed*dt
    local WALL = 50
    local HUD_H = R.HUD_H
    local roomW = R.ROOM_W
    local H = love.graphics.getHeight()

    self.x = math.max(WALL, math.min(roomW - self.width - WALL, nx))
    self.y = math.max(HUD_H + WALL, math.min(H - self.height - WALL, ny))

    if dx~=0 or dy~=0 then
        self.walkTimer = self.walkTimer + dt
        if self.walkTimer >= 0.18 then self.walkTimer=0; self.walkFrame=1-self.walkFrame end
    else
        self.walkFrame = 0
    end
end

function Player:getCenterX() return self.x + self.width/2 end
function Player:getCenterY() return self.y + self.height/2 end

function Player:draw()
    local x,y,w,h = self.x, self.y, self.width, self.height
    local legOff = (self.walkFrame==1) and 2 or 0

    love.graphics.setColor(0,0,0,0.3)
    love.graphics.ellipse("fill", x+w/2, y+h+2, w*0.5, 3)

    love.graphics.setColor(0.07,0.22,0.35)
    love.graphics.rectangle("fill", x+2,  y+h-8+legOff, 7, 8)
    love.graphics.rectangle("fill", x+11, y+h-8-legOff, 7, 8)
    love.graphics.setColor(0,0.55,0.8,0.4)
    love.graphics.rectangle("line", x+2,  y+h-8+legOff, 7, 8)
    love.graphics.rectangle("line", x+11, y+h-8-legOff, 7, 8)

    love.graphics.setColor(0.08,0.28,0.45)
    love.graphics.rectangle("fill", x+1, y+10, w-2, h-18)
    love.graphics.setColor(0,0.55,0.8,0.25)
    love.graphics.rectangle("fill", x+3, y+14, w-6, 3)
    love.graphics.setColor(0,0.7,1,0.5)
    love.graphics.rectangle("line", x+1, y+10, w-2, h-18)

    love.graphics.setColor(0.12,0.34,0.52)
    love.graphics.rectangle("fill", x+3, y, w-6, 12, 2, 2)
    love.graphics.setColor(0,0.9,1)
    love.graphics.rectangle("fill", x+5,  y+3, 3, 3)
    love.graphics.rectangle("fill", x+12, y+3, 3, 3)
    love.graphics.setColor(0,0.8,1,0.6)
    love.graphics.rectangle("line", x+3, y, w-6, 12, 2, 2)

    love.graphics.setColor(1,1,1,1)
end

return Player
