-- ════════════════════════════════════════════
--  RoomCaesar.lua  —  Niveau 1 : 3 stages
-- ════════════════════════════════════════════
local Room       = require("game.Room")
local GameObject = require("game.GameObject")
local Terminal   = require("game.Terminal")
local R          = require("systems.Renderer")

local RoomCaesar = {}
setmetatable(RoomCaesar, {__index = Room})

-- Palette
local STONE       = {0.62, 0.55, 0.42}
local STONE_DARK  = {0.35, 0.30, 0.22}
local STONE_LIGHT = {0.78, 0.72, 0.58}
local MOSAIC_1    = {0.72, 0.55, 0.18}
local MOSAIC_2    = {0.55, 0.18, 0.12}
local MOSAIC_3    = {0.18, 0.35, 0.55}
local WOOD        = {0.40, 0.28, 0.14}
local TORCH_ORG   = {1.00, 0.60, 0.10}
local TORCH_YEL   = {1.00, 0.90, 0.30}

-- ── Narration text ────────────────────────────
local NARRATION_LINES = {
    "Anno Domini I...",
    "Tu es un cryptographe emprisonne par l'Empire.",
    "La Resistance t'a laisse des indices dans ta cellule.",
    "Chaque fragment cache un nombre.",
    "Additionne-les pour trouver la cle.",
    "Et t'echapper avant l'aube...",
}

-- ── Helpers ──────────────────────────────────
local function stone(x,y,w,h)
    love.graphics.setColor(STONE[1],STONE[2],STONE[3],1)
    love.graphics.rectangle("fill",x,y,w,h)
    love.graphics.setColor(STONE_LIGHT[1],STONE_LIGHT[2],STONE_LIGHT[3],0.5)
    love.graphics.line(x,y,x+w,y); love.graphics.line(x,y,x,y+h)
    love.graphics.setColor(STONE_DARK[1],STONE_DARK[2],STONE_DARK[3],0.6)
    love.graphics.line(x+w,y,x+w,y+h); love.graphics.line(x,y+h,x+w,y+h)
end

local function column(cx, baseY, totalH)
    local shaft_w = 18
    local cx2 = cx - shaft_w/2
    stone(cx2-6, baseY-8, shaft_w+12, 8)
    for row = 0, totalH-16, 2 do
        local taper = math.abs((row/(totalH-16)) - 0.5) * 3
        local sw = shaft_w - taper
        local sx = cx - sw/2
        love.graphics.setColor(STONE[1],STONE[2],STONE[3],1)
        love.graphics.rectangle("fill", sx, baseY-16-row-2, sw, 2)
        love.graphics.setColor(STONE_DARK[1],STONE_DARK[2],STONE_DARK[3],0.3)
        for fi=1,3 do
            love.graphics.line(sx+fi*(sw/4), baseY-16-row-2, sx+fi*(sw/4), baseY-16-row)
        end
    end
    local capY = baseY - 16 - totalH
    stone(cx2-8, capY, shaft_w+16, 6)
    stone(cx2-4, capY+6, shaft_w+8, 4)
end

local function torch(cx, cy, flicker)
    local f = flicker
    love.graphics.setColor(STONE_DARK[1],STONE_DARK[2],STONE_DARK[3],1)
    love.graphics.rectangle("fill", cx-3, cy, 6, 14)
    love.graphics.setColor(WOOD[1],WOOD[2],WOOD[3],1)
    love.graphics.rectangle("fill", cx-6, cy-4, 12, 8)
    local baseAlpha = 0.85 + f*0.15
    love.graphics.setColor(TORCH_ORG[1],TORCH_ORG[2],TORCH_ORG[3], baseAlpha)
    love.graphics.ellipse("fill", cx+f*2,   cy-10+f, 7, 10)
    love.graphics.setColor(TORCH_YEL[1],TORCH_YEL[2],TORCH_YEL[3], baseAlpha)
    love.graphics.ellipse("fill", cx+f*1.5, cy-14+f, 4, 8)
    love.graphics.setColor(1,1,1, 0.6*baseAlpha)
    love.graphics.ellipse("fill", cx, cy-16, 2, 4)
    love.graphics.setColor(TORCH_ORG[1],TORCH_ORG[2],TORCH_ORG[3], 0.07+f*0.03)
    love.graphics.circle("fill", cx, cy-8, 30)
end

local function mosaicTile(x,y,size,c1,c2,c3)
    local cols = {c1,c2,c3}
    local ts = size/4
    for row=0,3 do for col=0,3 do
        local ci = ((row+col)%3)+1
        local cc = cols[ci]
        love.graphics.setColor(cc[1],cc[2],cc[3],0.7)
        love.graphics.rectangle("fill", x+col*ts+0.5, y+row*ts+0.5, ts-1, ts-1)
    end end
end

-- Draw a roman clock/watch showing roman numeral
local function drawWatch(x, y, numeral, alpha)
    alpha = alpha or 1
    -- Watch body
    love.graphics.setColor(STONE[1],STONE[2],STONE[3],alpha)
    love.graphics.circle("fill", x, y, 18)
    love.graphics.setColor(STONE_DARK[1],STONE_DARK[2],STONE_DARK[3],alpha)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", x, y, 18)
    love.graphics.setLineWidth(1)
    -- Inner face
    love.graphics.setColor(0.85, 0.78, 0.60, alpha)
    love.graphics.circle("fill", x, y, 14)
    -- Roman numeral
    love.graphics.setFont(R.font_tiny)
    love.graphics.setColor(STONE_DARK[1],STONE_DARK[2],STONE_DARK[3],alpha)
    love.graphics.printf(numeral, x-14, y-6, 28, "center")
    -- Clock hands stuck (pointing to numeral position)
    love.graphics.setColor(MOSAIC_2[1],MOSAIC_2[2],MOSAIC_2[3],alpha)
    love.graphics.setLineWidth(2)
    love.graphics.line(x, y, x+2, y-10)  -- hour hand stuck
    love.graphics.line(x, y, x-4, y-8)   -- minute hand stuck
    love.graphics.setLineWidth(1)
end

-- ── Constructor ───────────────────────────────
function RoomCaesar:new()
    local r = Room.new(self, "CELLULE I  —  CHIFFRE DE CESAR", {0.90, 0.72, 0.25})
    r.historicalPeriod = "Antiquite romaine"
    r.torchFlicker     = 0

    -- Stage system
    r.stage            = 1       -- 1, 2, 3, 4(final)
    r.stageObjects     = {}      -- objects per stage

    -- Narration
    r.narration = {
        active    = true,
        lineIndex = 1,
        timer     = 0,
        charIndex = 0,
        displayed = "",
        lineDone  = false,
        allDone   = false,
        waitTime  = 2.2,         -- seconds between lines
    }

    -- Ambient sound (generated via SoundChip or stub)
    r.ambientSound = nil
    r.melodyTimer  = 0
    r.melodyNotes  = {}          -- populated in load()
    r.melodyIndex  = 1
    r.melodySource = nil

    setmetatable(r, self); self.__index = self
    return r
end

-- ── Sound helpers ─────────────────────────────
-- Generate a simple sine-wave tone using SoundData
local function generateTone(freq, duration, volume)
    volume = volume or 0.3
    local sampleRate = 44100
    local samples    = math.floor(sampleRate * duration)
    local sd         = love.sound.newSoundData(samples, sampleRate, 16, 1)
    for i = 0, samples - 1 do
        local t   = i / sampleRate
        -- sine with short fade in/out to avoid clicks
        local env = 1.0
        local fadeLen = math.floor(sampleRate * 0.02)
        if i < fadeLen then env = i / fadeLen
        elseif i > samples - fadeLen then env = (samples - i) / fadeLen end
        local val = math.sin(2 * math.pi * freq * t) * volume * env
        sd:setSample(i, val)
    end
    return love.audio.newSource(sd)
end

-- ── Load ─────────────────────────────────────
function RoomCaesar:load()
    local UI  = require("systems.UIManager")
    local W   = UI.ROOM_W
    local H   = love.graphics.getHeight()
    local HUD = UI.HUD_H
    local WALL= 48

    self.door.x = W/2 - 26
    self.door.y = H - WALL - 64
    self.door.w = 52
    self.door.h = 64

    -- ── Terminal (always present) ──────────────
    local tOk, termImg = pcall(love.graphics.newImage, "assets/maps/terminal.png")
    local term = GameObject:new("terminal", W/2-18, HUD+WALL+185, 36, 44,
        tOk and termImg or nil, true)
    term.label      = "Tabula"
    term.icon       = "T"
    term.iconColor  = {0.0, 0.85, 0.45, 1}
    term.isTerminal = true
    table.insert(self.objects, term)

    self.terminal = Terminal:new(
        "XLI GEWEIV QIXLSH MW FEWIH SR E WLMJX",
        "caesar", "9", "IX"
    )
    self.terminal:setStages({2, 3, 4})

    -- Callback: when a stage is completed, update room
    self.terminal.onStageComplete = function(stageNum)
        self:onStageComplete(stageNum)
    end

    -- ── Stage 1 objects: one watch showing II ─
    self.stageObjects[1] = {}
    local watch1 = GameObject:new("watch1", W/2 - 80, HUD+WALL+60, 36, 36, nil, true)
    watch1.label       = "Horloge"
    watch1.icon        = "II"
    watch1.iconColor   = {MOSAIC_1[1],MOSAIC_1[2],MOSAIC_1[3],1}
    watch1.dialogTitle = "Horloge brisee"
    watch1.dialogBody  = "Une vieille horloge romaine.\nSes aiguilles sont figees.\n\n\"HORA II\"\n\nLe temps s'est arrete ici."
    watch1.hint        = "L'horloge indique II"
    watch1.isWatch     = true
    watch1.numeral     = "II"
    table.insert(self.stageObjects[1], watch1)

    -- ── Stage 2 objects: everything x3 ────────
    self.stageObjects[2] = {}
    local sOk, shieldImg = pcall(love.graphics.newImage, "assets/maps/object_shield.png")
    local positions = {
        {W/2 - 160, HUD+WALL+55},
        {W/2 - 60,  HUD+WALL+55},
        {W/2 + 40,  HUD+WALL+55},
    }
    for i = 1, 3 do
        local s = GameObject:new("shield"..i, positions[i][1], positions[i][2], 36, 36,
            sOk and shieldImg or nil, true)
        s.label       = "Bouclier "..i
        s.icon        = "SC"
        s.iconColor   = {MOSAIC_1[1],MOSAIC_1[2],MOSAIC_1[3],1}
        s.dialogTitle = "Bouclier legionnaire"
        s.dialogBody  = "Trois boucliers.\nTrois torches.\nTrois colonnes.\n\nTout se repete..."
        s.hint        = "Tout est en trois ici..."
        table.insert(self.stageObjects[2], s)
    end
    -- 3 watch copies
    local wPos = {
        {W/2 - 140, HUD+WALL+110},
        {W/2,       HUD+WALL+110},
        {W/2 + 120, HUD+WALL+110},
    }
    for i = 1, 3 do
        local w = GameObject:new("watch2_"..i, wPos[i][1], wPos[i][2], 36, 36, nil, false)
        w.isWatch  = true
        w.numeral  = "II"
        w.noInteract = true
        table.insert(self.stageObjects[2], w)
    end

    -- ── Stage 3 objects: none (just music) ────
    self.stageObjects[3] = {}

    -- ── Generate melody notes (Do Re Mi Fa) ───
    -- C4=261.63, D4=293.66, E4=329.63, F4=349.23
    local noteFreqs = {261.63, 293.66, 329.63, 349.23}
    for _, freq in ipairs(noteFreqs) do
        local src = generateTone(freq, 0.55, 0.28)
        src:setLooping(false)
        table.insert(self.melodyNotes, src)
    end

    -- ── Ambient background sound (low drone) ──
    local ok, ambSrc = pcall(generateTone, 110, 3.0, 0.08)
    if ok then
        ambSrc:setLooping(true)
        self.ambientSound = ambSrc
        ambSrc:play()
    end

    -- Load stage 1 objects into room
    self:loadStageObjects(1)
end

function RoomCaesar:loadStageObjects(stageNum)
    -- Remove old stage objects (keep terminal)
    local newObjects = {}
    for _, obj in ipairs(self.objects) do
        if obj.id == "terminal" then
            table.insert(newObjects, obj)
        end
    end
    self.objects = newObjects

    -- Add new stage objects
    if self.stageObjects[stageNum] then
        for _, obj in ipairs(self.stageObjects[stageNum]) do
            table.insert(self.objects, obj)
        end
    end
end

function RoomCaesar:onStageComplete(stageNum)
    self.stage = stageNum + 1
    if stageNum < 4 then
        self:loadStageObjects(stageNum + 1)
    end
    -- Stage 3: start melody loop
    if stageNum == 2 then
        self.melodyTimer = 0
        self.melodyIndex = 1
        self.playingMelody = true
    end
    -- Stage 4: door opens (handled by terminal.isSolved)
end

-- ── Update ────────────────────────────────────
function RoomCaesar:update(dt, player)
    self.torchFlicker = math.sin(love.timer.getTime() * 7.3) * 0.4
                      + math.sin(love.timer.getTime() * 13.1) * 0.2

    -- Typewriter narration
    local nav = self.narration
    if nav.active and not nav.allDone then
        if not nav.lineDone then
            nav.timer = nav.timer + dt
            local charsPerSec = 28
            local targetChar  = math.floor(nav.timer * charsPerSec)
            local line        = NARRATION_LINES[nav.lineIndex]
            if targetChar >= #line then
                nav.displayed = line
                nav.lineDone  = true
                nav.timer     = 0
            else
                nav.displayed = line:sub(1, targetChar)
            end
        else
            nav.timer = nav.timer + dt
            if nav.timer >= nav.waitTime then
                nav.timer    = 0
                nav.lineDone = false
                nav.charIndex= 0
                nav.lineIndex= nav.lineIndex + 1
                nav.displayed= ""
                if nav.lineIndex > #NARRATION_LINES then
                    nav.allDone = true
                    nav.active  = false
                end
            end
        end
    end

    -- Melody (stage 3)
    if self.playingMelody and #self.melodyNotes > 0 then
        self.melodyTimer = self.melodyTimer + dt
        local noteLen = 0.7   -- seconds per note
        if self.melodyTimer >= noteLen then
            self.melodyTimer = 0
            -- Stop previous
            for _, src in ipairs(self.melodyNotes) do src:stop() end
            -- Play current note
            self.melodyNotes[self.melodyIndex]:play()
            self.melodyIndex = (self.melodyIndex % #self.melodyNotes) + 1
        end
    end

    Room.update(self, dt, player)
end

-- ── Draw ──────────────────────────────────────
function RoomCaesar:drawTheme(x, y, w, h)
    local WALL = 48

    -- Floor
    love.graphics.setColor(0.60, 0.52, 0.38, 1)
    love.graphics.rectangle("fill", x, y, w, h)
    local ts = 40
    for row=0, math.ceil(h/ts) do
        for col=0, math.ceil(w/ts) do
            local lx, ly = x+col*ts, y+row*ts
            love.graphics.setColor(0.64+((row+col)%2)*0.04, 0.56+((row+col)%2)*0.04,
                                   0.40+((row+col)%2)*0.03, 1)
            love.graphics.rectangle("fill", lx+1, ly+1, ts-2, ts-2)
        end
    end
    love.graphics.setColor(0.35,0.28,0.18,0.5)
    for row=0,math.ceil(h/ts) do love.graphics.line(x,y+row*ts,x+w,y+row*ts) end
    for col=0,math.ceil(w/ts) do love.graphics.line(x+col*ts,y,x+col*ts,y+h) end

    -- Back wall
    love.graphics.setColor(STONE[1],STONE[2],STONE[3],1)
    love.graphics.rectangle("fill", x, y, w, WALL+20)
    love.graphics.setColor(STONE_DARK[1],STONE_DARK[2],STONE_DARK[3],0.3)
    for row=0,3 do love.graphics.line(x,y+row*16,x+w,y+row*16) end
    love.graphics.setColor(MOSAIC_1[1],MOSAIC_1[2],MOSAIC_1[3],0.55)
    love.graphics.rectangle("fill", x, y+WALL+14, w, 6)

    -- Side walls
    love.graphics.setColor(STONE[1],STONE[2],STONE[3],1)
    love.graphics.rectangle("fill", x, y+WALL, WALL, h-WALL*2)
    love.graphics.rectangle("fill", x+w-WALL, y+WALL, WALL, h-WALL*2)
    love.graphics.setColor(0,0,0,0.25)
    love.graphics.rectangle("fill", x+WALL, y+WALL, 8, h-WALL*2)
    love.graphics.rectangle("fill", x+w-WALL-8, y+WALL, 8, h-WALL*2)

    -- Columns
    local colH    = h - WALL*2 - 20
    local colBaseY= y + h - WALL
    column(x+WALL+2,  colBaseY, colH)
    column(x+WALL+60, colBaseY, colH)
    column(x+w-WALL-2,  colBaseY, colH)
    column(x+w-WALL-60, colBaseY, colH)

    -- Mosaic band
    local mz_y = y + h - WALL - 20
    for mi=0, math.floor(w/20)-1 do
        mosaicTile(x+mi*20, mz_y, 20, MOSAIC_1, MOSAIC_2, MOSAIC_3)
    end

    -- Torches (x3 in stage 2, x1 otherwise)
    local f = self.torchFlicker
    if self.stage == 2 then
        torch(x+WALL+35,     y+WALL+35,  f)
        torch(x+w/2,         y+WALL+35,  f*0.8)
        torch(x+w-WALL-35,   y+WALL+35, -f)
    else
        torch(x+WALL+35,     y+WALL+35,  f)
        torch(x+w-WALL-35,   y+WALL+35, -f)
    end

    -- Draw watches (for stage 1 and 2)
    if self.stage == 1 then
        drawWatch(x+w/2-80 + 18, y+UI_HUD_offset()+60+18, "II", 1)
    elseif self.stage == 2 then
        local UI = require("systems.UIManager")
        local HUD = UI.HUD_H
        drawWatch(x+w/2-140+18, y+(HUD-y)+110+18, "II", 1)
        drawWatch(x+w/2+18,     y+(HUD-y)+110+18, "II", 1)
        drawWatch(x+w/2+120+18, y+(HUD-y)+110+18, "II", 1)
    end

    -- Stage label
    love.graphics.setFont(R.font_tiny)
    love.graphics.setColor(MOSAIC_1[1],MOSAIC_1[2],MOSAIC_1[3],0.7)
    love.graphics.printf("SPQR  •  AVE CAESAR  •  STAGE "..self.stage, x, y+4, w, "center")

    -- Stage 3 overlay: dim room
    if self.stage == 3 then
        love.graphics.setColor(0, 0, 0, 0.45)
        love.graphics.rectangle("fill", x, y, w, h)
        love.graphics.setFont(R.font_tiny)
        love.graphics.setColor(MOSAIC_1[1],MOSAIC_1[2],MOSAIC_1[3],0.85)
        love.graphics.printf("~ Do  Re  Mi  Fa ~", x, y+h/2-10, w, "center")
    end

    -- Narration overlay
    if not self.narration.allDone then
        love.graphics.setColor(0, 0, 0, 0.72)
        love.graphics.rectangle("fill", x+20, y+h-90, w-40, 70)
        love.graphics.setColor(MOSAIC_1[1],MOSAIC_1[2],MOSAIC_1[3],0.9)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", x+20, y+h-90, w-40, 70)
        love.graphics.setFont(R.font_tiny)
        love.graphics.setColor(1, 1, 1, 0.95)
        love.graphics.printf(self.narration.displayed .. "_",
            x+30, y+h-75, w-60, "left")
        -- Skip hint
        love.graphics.setColor(0.6,0.6,0.6,0.7)
        love.graphics.printf("[E] pour passer", x, y+h-18, w, "center")
    end
end

-- Small helper to avoid referencing UI inside drawTheme without require
function UI_HUD_offset()
    local ok, UI = pcall(require, "systems.UIManager")
    return ok and UI.HUD_H or 40
end

function RoomCaesar:drawDoorTheme(d, col, isSolved)
    local stoneC = isSolved and {0.55,0.72,0.45} or STONE
    stone(d.x-8, d.y, 8, d.h)
    stone(d.x+d.w, d.y, 8, d.h)
    stone(d.x-8, d.y-14, d.w+16, 14)
    love.graphics.setColor(stoneC[1],stoneC[2],stoneC[3],0.9)
    love.graphics.arc("fill", d.x+d.w/2, d.y, d.w/2+8, -math.pi, 0)
    love.graphics.setColor(STONE_DARK[1],STONE_DARK[2],STONE_DARK[3],0.5)
    love.graphics.arc("line", d.x+d.w/2, d.y, d.w/2+8, -math.pi, 0)
    love.graphics.setColor(WOOD[1],WOOD[2],WOOD[3], isSolved and 0.5 or 1)
    love.graphics.rectangle("fill", d.x+1, d.y+1, d.w-2, d.h-2)
    love.graphics.setColor(0,0,0,0.2)
    for i=1,4 do love.graphics.line(d.x+1,d.y+i*(d.h/5),d.x+d.w-1,d.y+i*(d.h/5)) end
    love.graphics.setColor(STONE_DARK[1],STONE_DARK[2],STONE_DARK[3],0.3)
    love.graphics.line(d.x+2,d.y+2, d.x+d.w-2,d.y+d.h-2)
    love.graphics.setColor(MOSAIC_1[1],MOSAIC_1[2],MOSAIC_1[3],0.9)
    love.graphics.circle("fill", d.x+d.w/2, d.y+d.h/2, 4)
    love.graphics.setFont(R.font_tiny)
    love.graphics.setColor(col[1],col[2],col[3],0.95)
    love.graphics.printf(isSolved and "OPEN" or "LOCK", d.x, d.y+d.h-16, d.w, "center")
    if isSolved and self.terminal then
        love.graphics.setColor(MOSAIC_1[1],MOSAIC_1[2],MOSAIC_1[3],1)
        love.graphics.printf(self.terminal.doorCode, d.x-8, d.y+d.h+2, d.w+16, "center")
    end
end

function RoomCaesar:draw(player)
    Room.draw(self, player)
end

return RoomCaesar