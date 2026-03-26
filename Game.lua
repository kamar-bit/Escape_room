-- ════════════════════════════════════════════
--  Game.lua  —  Orchestrateur principal
--  États : "menu" | "playing" | "transition" | "victory"
-- ════════════════════════════════════════════
local R          = require("systems.Renderer")
local UI         = require("systems.UIManager")
local Player     = require("game.Player")
local RoomCaesar   = require("game.RoomCaesar")
local RoomVigenere = require("game.RoomVigenere")
local RoomVernam   = require("game.RoomVernam")

local Game = {}

-- ─── Constructor ──────────────────────────────
function Game:new()
    local g = {
        state            = "menu",   -- menu | playing | transition | victory
        currentRoomIndex = 1,
        player           = Player:new(200, 200),
        rooms            = {},
        roomsSolved      = {caesar=false, vigenere=false, vernam=false},
        roomOrder        = {"caesar","vigenere","vernam"},

        -- Timer
        timerSeconds     = 900,
        timerAccum       = 0,

        -- Transition
        transition = {
            active    = false,
            timer     = 0,
            duration  = 2.2,
            nextIndex = 1,
            title     = "",
            sub       = "",
            barFill   = 0,
        },

        -- Overlay (controls / about)
        overlay = {visible=false, title="", body=""},

        -- Global time for animations
        t = 0,

        -- Elapsed for victory screen
        elapsed = 0,
    }
    setmetatable(g, self)
    self.__index = self
    return g
end

-- ─── Load ─────────────────────────────────────
function Game:load()
    R.loadFonts()
    R.initCRT()

    self.rooms = {
        RoomCaesar:new(),
        RoomVigenere:new(),
        RoomVernam:new(),
    }
    for _, room in ipairs(self.rooms) do
        room:load()
    end

    -- Player start position
    self:resetPlayerPos()
end

function Game:resetPlayerPos()
    local WALL = 48
    self.player.x = 200
    self.player.y = UI.HUD_H + WALL + 60
end

-- ─── Helpers ──────────────────────────────────
function Game:currentRoom()
    return self.rooms[self.currentRoomIndex]
end

function Game:currentRoomName()
    return self.roomOrder[self.currentRoomIndex]
end

function Game:buildGameState()
    -- Build the table UIManager needs for drawing
    local room = self:currentRoom()
    local hints = {}
    -- Collect hints from objects already interacted
    for _, obj in ipairs(room.objects) do
        if obj.hintUnlocked and obj.hint then
            table.insert(hints, obj.hint)
        end
    end
    local hintsCount = #hints

    return {
        currentRoom  = self:currentRoomName(),
        roomsSolved  = self.roomsSolved,
        timerSeconds = self.timerSeconds,
        hintsCount   = hintsCount,
        hints        = hints,
    }
end

-- ─── Update ───────────────────────────────────
function Game:update(dt)
    self.t = self.t + dt

    UI.updateNotifs(dt)

    if self.state == "menu" then
        -- nothing dynamic yet

    elseif self.state == "playing" then
        -- Timer countdown
        self.timerAccum = self.timerAccum + dt
        if self.timerAccum >= 1 then
            self.timerAccum = 0
            self.timerSeconds = math.max(0, self.timerSeconds - 1)
        end

        -- Update current room
        local room = self:currentRoom()
        room:update(dt, self.player)

        -- Only move player when no modal is open
        local anyModal = room.dialog.visible or room.keypad.visible or self.overlay.visible
        if not anyModal then
            self.player:update(dt, room)
        end

        -- Check proximity for [E] hints
        for _, obj in ipairs(room.objects) do
            obj.hintVisible = obj:isNear(self.player:getCenterX(), self.player:getCenterY())
        end

    elseif self.state == "transition" then
        local tr = self.transition
        tr.timer = tr.timer + dt
        tr.barFill = math.min(1, tr.timer / tr.duration)
        if tr.timer >= tr.duration then
            tr.active = false
            self.currentRoomIndex = tr.nextIndex
            self:resetPlayerPos()
            self.state = "playing"
        end

    elseif self.state == "victory" then
        self.elapsed = self.elapsed + dt
    end
end

-- ─── Draw ─────────────────────────────────────
function Game:draw()
    love.graphics.clear(0.02, 0.04, 0.06, 1)

    if self.state == "menu" then
        UI.drawMenu(self.t)

    elseif self.state == "playing" then
        local room = self:currentRoom()
        room:draw(self.player)
        self.player:draw()
        -- HUD
        UI.drawHUD(self:buildGameState(), self.t)
        -- Side panel
        UI.drawSidePanel(self:buildGameState(), room.terminal, self.t)
        -- Dialog
        UI.drawDialog(room.dialog, self.t)
        -- Keypad
        UI.drawKeypad(room.keypad, self.t)
        -- Overlay
        UI.drawOverlay(self.overlay)
        -- Notifications
        UI.drawNotifs()

    elseif self.state == "transition" then
        self:drawTransition()

    elseif self.state == "victory" then
        UI.drawVictory(self.t, math.floor(900 - self.timerSeconds))
    end

    -- CRT effects on top of everything
    R.drawCRT()
end

-- ─── Transition screen ────────────────────────
function Game:drawTransition()
    local tr = self.transition
    love.graphics.setColor(R.C.bg_deep)
    love.graphics.rectangle("fill",0,0,love.graphics.getWidth(),love.graphics.getHeight())

    R.corners(10,10,love.graphics.getWidth()-20,love.graphics.getHeight()-20, R.C.green, 20)

    -- Title
    love.graphics.setFont(R.font_title)
    local tw = R.font_title:getWidth(tr.title)
    R.glowText(tr.title, (love.graphics.getWidth()-tw)/2,
               love.graphics.getHeight()/2 - 60, R.C.green, R.font_title)

    -- Sub
    love.graphics.setFont(R.font_normal)
    R.setColor(R.C.green_dim)
    love.graphics.printf(tr.sub, 0, love.graphics.getHeight()/2, love.graphics.getWidth(), "center")

    -- Progress bar
    local bw, bh = 300, 4
    local bx = (love.graphics.getWidth()-bw)/2
    local by = love.graphics.getHeight()/2 + 40
    R.panel(bx, by, bw, bh, {0,0,0,0.4}, R.C.border)
    love.graphics.setColor(R.C.green)
    love.graphics.rectangle("fill", bx, by, bw*tr.barFill, bh)
    -- glow
    love.graphics.setColor(R.C.green[1],R.C.green[2],R.C.green[3],0.3)
    love.graphics.rectangle("fill", bx, by-2, bw*tr.barFill, bh+4)
end

-- ─── Input : keys ─────────────────────────────
function Game:keypressed(key)
    if self.state == "menu" then
        if key == "return" or key == "space" then
            self:startGame()
        elseif key == "c" then
            self:showControls()
        elseif key == "a" then
            self:showAbout()
        elseif key == "escape" then
            love.event.quit()
        end
        return
    end

    if self.state == "victory" then
        if key == "escape" or key == "return" then
            self:returnToMenu()
        end
        return
    end

    if self.state == "transition" then return end

    -- ── Playing ──
    local room = self:currentRoom()

    -- Overlay dismiss
    if self.overlay.visible then
        if key == "escape" then self.overlay.visible = false end
        return
    end

    -- Keypad input
    if room.keypad.visible then
        if key == "escape" then
            room.keypad.visible = false
        elseif key == "return" then
            self:keypadValidate()
        elseif key == "backspace" then
            room.keypad.buffer = room.keypad.buffer:sub(1,-2)
        end
        return
    end

    -- Dialog dismiss
    if room.dialog.visible then
        if key == "escape" then
            room.dialog.visible = false
        elseif key == "e" then
            self:collectCurrentObject()
            room.dialog.visible = false
        end
        return
    end

    -- Terminal input
    if key == "return" then
        room.terminal:validateInput()
        -- Check if just solved
        if room.terminal.isSolved and not self.roomsSolved[self:currentRoomName()] then
            self.roomsSolved[self:currentRoomName()] = true
            room.isSolved = true
            UI.notify("Dechiffrement reussi ! Code : " .. room.terminal.doorCode, "green")
            -- Check all solved
            local allDone = true
            for _,v in pairs(self.roomsSolved) do if not v then allDone=false end end
            if allDone then
                love.timer.sleep(0)  -- yield
            end
        end
    elseif key == "backspace" then
        room.terminal:backspace()
    elseif key == "e" then
        self:tryInteract()
    elseif key == "escape" then
        self.overlay.visible = false
    end
end

-- ─── Input : text ─────────────────────────────
function Game:textinput(t)
    if self.state ~= "playing" then return end
    local room = self:currentRoom()

    if room.keypad.visible then
        if t:match("%d") and #room.keypad.buffer < 4 then
            room.keypad.buffer = room.keypad.buffer .. t
        end
        return
    end

    if room.dialog.visible or self.overlay.visible then return end
    room.terminal:addInput(t)
end

-- ─── Interaction ──────────────────────────────
function Game:tryInteract()
    local room = self:currentRoom()
    local px = self.player:getCenterX()
    local py = self.player:getCenterY()

    for _, obj in ipairs(room.objects) do
        if not obj.collected and obj:isNear(px, py, 60) then
            if obj.isTerminal then
                -- Focus terminal, show hint
                UI.notify("Terminal actif — tapez votre reponse", "green")
            else
                -- Show dialog
                room.dialog.visible = true
                room.dialog.title   = obj.dialogTitle or obj.label
                room.dialog.body    = obj.dialogBody  or "(pas de description)"
                room.dialog.objectId = obj.id
                -- Unlock hint
                if obj.hint and not obj.hintUnlocked then
                    obj.hintUnlocked = true
                    UI.notify("Indice debloque !", "amber")
                end
            end
            return
        end
    end

    -- Try door
    local d = room.door
    local dc = {x=d.x+d.w/2, y=d.y+d.h/2}
    if math.sqrt((px-dc.x)^2+(py-dc.y)^2) < 60 then
        self:tryDoor()
    end
end

function Game:collectCurrentObject()
    local room = self:currentRoom()
    local oid  = room.dialog.objectId
    if not oid then return end
    for _, obj in ipairs(room.objects) do
        if obj.id == oid then
            if not obj.collected then
                obj.collected = true
                UI.notify("Objet collecte : " .. (obj.label or oid), "amber")
            end
            return
        end
    end
end

-- ─── Door logic ───────────────────────────────
function Game:tryDoor()
    local room = self:currentRoom()
    if room.isSolved then
        -- Advance to next room or victory
        local nextIdx = self.currentRoomIndex + 1
        if nextIdx > #self.rooms then
            self:triggerVictory()
        else
            self:triggerTransition(nextIdx)
        end
    else
        -- Open keypad
        room.keypad.visible = true
        room.keypad.buffer  = ""
        room.keypad.wrongFlash = 0
    end
end

function Game:keypadValidate()
    local room = self:currentRoom()
    local code = room.terminal and room.terminal.doorCode or ""
    if room.keypad.buffer == code then
        room.keypad.visible = false
        room.isSolved = true
        self.roomsSolved[self:currentRoomName()] = true
        if room.terminal then room.terminal.isSolved = true end
        UI.notify("Code correct ! Porte ouverte.", "green")
        love.timer.sleep(0)
        local nextIdx = self.currentRoomIndex + 1
        if nextIdx > #self.rooms then
            self:triggerVictory()
        else
            -- Small delay then transition
            self:triggerTransition(nextIdx)
        end
    else
        room.keypad.wrongFlash = 1.0
        UI.notify("Code incorrect !", "red")
        room.keypad.buffer = ""
    end
end

-- ─── Transitions ──────────────────────────────
function Game:triggerTransition(nextIdx)
    local names = {"NIVEAU 1", "NIVEAU 2", "NIVEAU 3"}
    local subs  = {
        "CHIFFRE DE CESAR — ACCES ACCORDE",
        "CHIFFRE DE VIGENERE — ACCES ACCORDE",
        "VERNAM / XOR — ACCES ACCORDE",
    }
    self.transition.active    = true
    self.transition.timer     = 0
    self.transition.barFill   = 0
    self.transition.nextIndex = nextIdx
    self.transition.title     = names[nextIdx] or "NIVEAU SUIVANT"
    self.transition.sub       = subs[nextIdx]  or ""
    self.state = "transition"
end

function Game:triggerVictory()
    self.state   = "victory"
    self.elapsed = 0
end

-- ─── Game start / restart ─────────────────────
function Game:startGame()
    self.state            = "playing"
    self.currentRoomIndex = 1
    self.timerSeconds     = 900
    self.timerAccum       = 0
    self.roomsSolved      = {caesar=false, vigenere=false, vernam=false}
    -- Reload rooms fresh
    self.rooms = {
        RoomCaesar:new(),
        RoomVigenere:new(),
        RoomVernam:new(),
    }
    for _, room in ipairs(self.rooms) do room:load() end
    self:resetPlayerPos()
    UI.notifications = {}
end

function Game:returnToMenu()
    self.state = "menu"
end

-- ─── Controls / About overlays ────────────────
function Game:showControls()
    self.overlay.visible = true
    self.overlay.title   = "CONTROLES"
    self.overlay.body    =
        "DEPLACEMENT\n" ..
        "  Fleches  /  Z Q S D  —  Bouger\n\n" ..
        "INTERACTION\n" ..
        "  [E]  —  Interagir avec un objet\n" ..
        "  [E]  —  Approcher la porte\n\n" ..
        "TERMINAL\n" ..
        "  Tapez directement votre reponse\n" ..
        "  [Entree]  —  Valider\n" ..
        "  [Backspace]  —  Effacer\n" ..
        "  aide  —  Obtenir un indice\n\n" ..
        "NAVIGATION\n" ..
        "  [ESC]  —  Fermer / Menu"
end

function Game:showAbout()
    self.overlay.visible = true
    self.overlay.title   = "A PROPOS"
    self.overlay.body    =
        "THE DECRYPTOR'S CELL\n" ..
        "Serious Game en cybersecurite\n\n" ..
        "Vous etes enferme dans une cellule\n" ..
        "numerique. Dechiffrez 3 niveaux\n" ..
        "de cryptographie pour vous evader.\n\n" ..
        "NIVEAUX :\n" ..
        "  I.   Chiffre de Cesar\n" ..
        "  II.  Chiffre de Vigenere\n" ..
        "  III. Chiffrement Vernam / XOR\n\n" ..
        "Projet IATIC3 — Universite Paris-Saclay\n" ..
        "Encadrant : M. BEN AMOR Soufiane"
end

return Game
