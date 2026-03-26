-- ════════════════════════════════════════════
--  GameObject.lua
-- ════════════════════════════════════════════
local GameObject = {}

function GameObject:new(id, x, y, w, h, sprite, interactable, onInteract)
    local o = {
        id=id, x=x, y=y, width=w, height=h,
        sprite=sprite, isInteractable=interactable or false,
        onInteract=onInteract or function() end,
        label=id, icon=nil,
        iconColor={1,0.72,0,1},
        collected=false, floatTimer=0,
    }
    setmetatable(o, self); self.__index = self
    return o
end

function GameObject:update(dt)
    self.floatTimer = self.floatTimer + dt
end

function GameObject:isNear(px, py, radius)
    local cx = self.x + self.width/2
    local cy = self.y + self.height/2
    return math.sqrt((px-cx)^2+(py-cy)^2) < (radius or 55)
end

function GameObject:draw(playerX, playerY)
    if self.collected then return end
    local R = require("systems.Renderer")
    local ic = self.iconColor
    local fx = self.x
    local fy = self.y + math.sin(self.floatTimer*1.8)*3
    local near = self:isNear(playerX or 0, playerY or 0, 55)

    if near then
        love.graphics.setColor(ic[1],ic[2],ic[3],0.12)
        love.graphics.circle("fill", fx+self.width/2, fy+self.height/2, math.max(self.width,self.height)*0.75)
    end

    if self.sprite then
        love.graphics.setColor(1,1,1,1)
        local sw,sh = self.sprite:getWidth(), self.sprite:getHeight()
        love.graphics.draw(self.sprite, fx, fy, 0, self.width/sw, self.height/sh)
        love.graphics.setColor(ic[1],ic[2],ic[3],0.2)
        love.graphics.draw(self.sprite, fx, fy, 0, self.width/sw, self.height/sh)
    else
        love.graphics.setColor(ic[1],ic[2],ic[3],0.15)
        love.graphics.rectangle("fill", fx, fy, self.width, self.height)
        love.graphics.setColor(ic[1],ic[2],ic[3],0.6)
        love.graphics.rectangle("line", fx, fy, self.width, self.height)
        if self.icon then
            love.graphics.setFont(R.font_normal)
            love.graphics.setColor(ic[1],ic[2],ic[3],1)
            love.graphics.printf(self.icon, fx, fy+self.height/2-7, self.width, "center")
        end
    end

    if near then
        love.graphics.setColor(ic[1],ic[2],ic[3],0.7)
        love.graphics.setLineWidth(1.5)
        love.graphics.rectangle("line", fx-1, fy-1, self.width+2, self.height+2)
        love.graphics.setLineWidth(1)

        local a = 0.5+0.5*math.abs(math.sin(self.floatTimer*3))
        love.graphics.setColor(1,0.72,0,0.15*a)
        love.graphics.rectangle("fill", fx+self.width/2-14, fy-15, 28, 13)
        love.graphics.setColor(1,0.72,0,0.8*a)
        love.graphics.rectangle("line", fx+self.width/2-14, fy-15, 28, 13)
        love.graphics.setFont(R.font_tiny)
        love.graphics.setColor(1,0.72,0,a)
        love.graphics.printf("[E]", fx+self.width/2-14, fy-13, 28, "center")
    end

    love.graphics.setFont(R.font_tiny)
    love.graphics.setColor(ic[1],ic[2],ic[3], near and 0.9 or 0.4)
    love.graphics.printf(self.label, fx-20, fy+self.height+2, self.width+40, "center")
    love.graphics.setColor(1,1,1,1)
end

return GameObject
