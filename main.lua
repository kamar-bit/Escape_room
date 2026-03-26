-- ════════════════════════════════════════════
--  THE DECRYPTOR'S CELL — main.lua
-- ════════════════════════════════════════════
local Game = require("game.Game")
game = nil

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    game = Game:new()
    game:load()
end

function love.update(dt)
    game:update(dt)
end

function love.draw()
    game:draw()
end

function love.keypressed(key)
    game:keypressed(key)
end

function love.textinput(t)
    game:textinput(t)
end
