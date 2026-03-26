-- ════════════════════════════════════════════
--  RoomVernam.lua  —  Niveau 3 : Guerre Froide / Bunker
-- ════════════════════════════════════════════
local Room       = require("game.Room")
local GameObject = require("game.GameObject")
local Terminal   = require("game.Terminal")
local R          = require("systems.Renderer")

local RoomVernam = {}
setmetatable(RoomVernam, {__index = Room})

-- Palette Guerre Froide / bunker soviétique
local CONCRETE   = {0.32, 0.33, 0.30}   -- béton
local CONCRETE_LT= {0.42, 0.43, 0.40}
local CONCRETE_DK= {0.18, 0.19, 0.17}
local METAL      = {0.28, 0.32, 0.30}
local METAL_LT   = {0.48, 0.52, 0.50}
local RED_USSR   = {0.75, 0.10, 0.10}   -- rouge soviétique
local YELLOW_USSR= {0.95, 0.80, 0.10}   -- jaune étoile
local GREEN_ARMY = {0.20, 0.35, 0.18}   -- vert militaire
local AMBER_SCR  = {0.90, 0.65, 0.10}   -- écran ambre
local PIPE_COL   = {0.35, 0.38, 0.32}
local WIRE_COL   = {0.15, 0.55, 0.20}   -- fils électriques verts
local DANGER_YEL = {0.95, 0.80, 0.05}
local RUST       = {0.55, 0.28, 0.08}

function RoomVernam:new()
    local r = Room.new(self, "CELLULE III  —  VERNAM / XOR  —  Guerre Froide 1949", {0.20, 0.80, 0.35})
    r.historicalPeriod = "Guerre Froide — Bunker"
    r.oneTimePadKey = "42"
    r.screenFlicker = 0
    r.warningBlink  = 0
    setmetatable(r, self); self.__index = self
    return r
end

-- ── Helpers ──────────────────────────────────
local function rivet(x, y)
    love.graphics.setColor(METAL_LT[1],METAL_LT[2],METAL_LT[3],1)
    love.graphics.circle("fill", x, y, 3)
    love.graphics.setColor(CONCRETE_DK[1],CONCRETE_DK[2],CONCRETE_DK[3],0.6)
    love.graphics.circle("line", x, y, 3)
    love.graphics.setColor(1,1,1,0.3)
    love.graphics.circle("fill", x-1, y-1, 1)
end

local function metalPanel(x,y,w,h)
    -- Plaque métallique boulonnée
    love.graphics.setColor(METAL[1],METAL[2],METAL[3],1)
    love.graphics.rectangle("fill", x,y,w,h)
    -- soudures
    love.graphics.setColor(METAL_LT[1],METAL_LT[2],METAL_LT[3],0.3)
    love.graphics.line(x,y,x+w,y)
    love.graphics.line(x,y,x,y+h)
    love.graphics.setColor(CONCRETE_DK[1],CONCRETE_DK[2],CONCRETE_DK[3],0.4)
    love.graphics.line(x+w,y,x+w,y+h)
    love.graphics.line(x,y+h,x+w,y+h)
    -- rivets aux coins
    rivet(x+6,y+6); rivet(x+w-6,y+6)
    rivet(x+6,y+h-6); rivet(x+w-6,y+h-6)
end

local function pipe(x1,y1,x2,y2, r, col)
    r = r or 4
    col = col or PIPE_COL
    love.graphics.setColor(col[1],col[2],col[3],1)
    love.graphics.setLineWidth(r*2)
    love.graphics.line(x1,y1,x2,y2)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(METAL_LT[1],METAL_LT[2],METAL_LT[3],0.35)
    love.graphics.setLineWidth(r*2-2)
    love.graphics.line(x1,y1,x2,y2)
    love.graphics.setLineWidth(1)
end

local function hazardStripe(x,y,w,h)
    -- Bandes danger jaune/noir
    local stripeW = 12
    love.graphics.setScissor(x,y,w,h)
    for i=0, math.ceil(w/stripeW)+1 do
        if i%2==0 then
            love.graphics.setColor(DANGER_YEL[1],DANGER_YEL[2],DANGER_YEL[3],0.9)
        else
            love.graphics.setColor(0,0,0,0.85)
        end
        love.graphics.polygon("fill",
            x+i*stripeW, y,
            x+(i+1)*stripeW, y,
            x+(i+1)*stripeW-h, y+h,
            x+i*stripeW-h, y+h)
    end
    love.graphics.setScissor()
end

local function crtScreen(x,y,w,h, flicker, text)
    -- Écran CRT ambre style années 50
    love.graphics.setColor(0.05,0.08,0.04,1)
    love.graphics.rectangle("fill", x,y,w,h)
    -- phosphore
    local fa = 0.85 + flicker*0.15
    love.graphics.setColor(AMBER_SCR[1],AMBER_SCR[2],AMBER_SCR[3], fa)
    love.graphics.rectangle("fill", x+2,y+2,w-4,h-4)
    -- scanlines CRT
    love.graphics.setColor(0,0,0,0.25)
    for sl=y+2, y+h-2, 3 do love.graphics.line(x+2,sl,x+w-2,sl) end
    -- texte
    love.graphics.setFont(R.font_tiny)
    love.graphics.setColor(0.10,0.06,0.02, 0.9)
    if text then love.graphics.printf(text, x+4, y+4, w-8, "left") end
    -- reflet d'écran
    love.graphics.setColor(1,1,1,0.06)
    love.graphics.rectangle("fill", x+2,y+2, w-4, h/3)
    -- cadre métal
    metalPanel(x-4,y-4,w+8,h+8)
end

local function warningLight(cx, cy, blink, col)
    col = col or RED_USSR
    local a = 0.5 + blink*0.5
    love.graphics.setColor(col[1],col[2],col[3], a)
    love.graphics.circle("fill", cx, cy, 7)
    love.graphics.setColor(col[1],col[2],col[3], 0.15*a)
    love.graphics.circle("fill", cx, cy, 14)
    love.graphics.setColor(METAL_LT[1],METAL_LT[2],METAL_LT[3],0.8)
    love.graphics.circle("line", cx, cy, 7)
end

-- ── Theme draw ────────────────────────────────
function RoomVernam:drawTheme(rx, ry, rw, rh)
    local WALL = 48
    local t = love.timer.getTime()

    -- 1. SOL — béton fissuré
    love.graphics.setColor(CONCRETE_DK[1],CONCRETE_DK[2],CONCRETE_DK[3],1)
    love.graphics.rectangle("fill", rx,ry,rw,rh)
    -- dalles béton
    local ds = 50
    for row=0, math.ceil(rh/ds) do
        for col=0, math.ceil(rw/ds) do
            local bv = 0.28 + ((row*7+col*3)%5)*0.02
            love.graphics.setColor(bv,bv+0.01,bv-0.01, 1)
            love.graphics.rectangle("fill", rx+col*ds+1, ry+row*ds+1, ds-2, ds-2)
        end
    end
    -- joints
    love.graphics.setColor(CONCRETE_DK[1]*0.7,CONCRETE_DK[2]*0.7,CONCRETE_DK[3]*0.7,1)
    for row=0,math.ceil(rh/ds) do love.graphics.line(rx,ry+row*ds,rx+rw,ry+row*ds) end
    for col=0,math.ceil(rw/ds) do love.graphics.line(rx+col*ds,ry,rx+col*ds,ry+rh) end
    -- fissures
    love.graphics.setColor(0,0,0,0.3)
    love.graphics.setLineWidth(1)
    love.graphics.line(rx+120,ry+200, rx+145,ry+260, rx+130,ry+310)
    love.graphics.line(rx+380,ry+180, rx+400,ry+240)

    -- 2. PLAFOND — béton avec tuyauterie
    love.graphics.setColor(CONCRETE[1],CONCRETE[2],CONCRETE[3],1)
    love.graphics.rectangle("fill", rx, ry, rw, WALL)
    -- tuyaux au plafond
    pipe(rx,      ry+8,  rx+rw, ry+8,  6, PIPE_COL)
    pipe(rx+80,   ry+8,  rx+80, ry+WALL, 4, PIPE_COL)
    pipe(rx+rw-80,ry+8,  rx+rw-80, ry+WALL, 4, PIPE_COL)
    pipe(rx+200,  ry+22, rx+350, ry+22, 5, {0.55,0.20,0.10})  -- tuyau rouge
    -- câbles électriques
    love.graphics.setColor(WIRE_COL[1],WIRE_COL[2],WIRE_COL[3],0.8)
    love.graphics.setLineWidth(2)
    love.graphics.line(rx+30, ry+36, rx+rw-30, ry+36)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(0.80,0.15,0.10,0.8)
    love.graphics.setLineWidth(2)
    love.graphics.line(rx+30, ry+40, rx+rw-30, ry+40)
    love.graphics.setLineWidth(1)

    -- 3. MURS LATÉRAUX — béton + plaques métal
    love.graphics.setColor(CONCRETE[1],CONCRETE[2],CONCRETE[3],1)
    love.graphics.rectangle("fill", rx, ry+WALL, WALL, rh-WALL*2)
    love.graphics.rectangle("fill", rx+rw-WALL, ry+WALL, WALL, rh-WALL*2)
    metalPanel(rx+2, ry+WALL+20, WALL-4, 60)
    metalPanel(rx+rw-WALL+2, ry+WALL+20, WALL-4, 60)
    -- ombres intérieures
    love.graphics.setColor(0,0,0,0.3)
    love.graphics.rectangle("fill", rx+WALL, ry+WALL, 12, rh-WALL*2)
    love.graphics.rectangle("fill", rx+rw-WALL-12, ry+WALL, 12, rh-WALL*2)

    -- 4. BANDES DE DANGER en bas
    hazardStripe(rx, ry+rh-WALL-10, rw, 10)
    hazardStripe(rx, ry+WALL-10,    rw, 10)

    -- 5. ARMOIRE À FICHIERS (gauche)
    local cabX = rx+WALL+4
    local cabY = ry+WALL+40
    metalPanel(cabX, cabY, 44, 80)
    -- tiroirs
    for ti=0,3 do
        love.graphics.setColor(METAL_LT[1],METAL_LT[2],METAL_LT[3],0.4)
        love.graphics.rectangle("fill", cabX+3, cabY+3+ti*19, 38, 16)
        love.graphics.setColor(METAL_LT[1],METAL_LT[2],METAL_LT[3],0.8)
        love.graphics.rectangle("line", cabX+3, cabY+3+ti*19, 38, 16)
        -- poignée
        love.graphics.setColor(METAL_LT[1],METAL_LT[2],METAL_LT[3],1)
        love.graphics.rectangle("fill", cabX+16, cabY+9+ti*19, 12, 4)
        rivet(cabX+15, cabY+11+ti*19)
        rivet(cabX+29, cabY+11+ti*19)
    end
    -- étiquette CLASSIFIE
    love.graphics.setColor(DANGER_YEL[1],DANGER_YEL[2],DANGER_YEL[3],0.85)
    love.graphics.rectangle("fill", cabX+5, cabY+3, 34, 8)
    love.graphics.setFont(R.font_tiny)
    love.graphics.setColor(0,0,0,1)
    love.graphics.printf("SECRET", cabX+5, cabY+3, 34, "center")

    -- 6. RACK D'ÉQUIPEMENTS (droite)
    local rackX = rx+rw-WALL-50
    local rackY = ry+WALL+30
    metalPanel(rackX, rackY, 50, 100)
    -- unités rack
    for ui=0,4 do
        love.graphics.setColor(CONCRETE_DK[1],CONCRETE_DK[2],CONCRETE_DK[3],1)
        love.graphics.rectangle("fill", rackX+4, rackY+4+ui*19, 42, 16)
        love.graphics.setColor(METAL_LT[1],METAL_LT[2],METAL_LT[3],0.5)
        love.graphics.rectangle("line", rackX+4, rackY+4+ui*19, 42, 16)
        -- leds
        local ledCol = (ui%3==0) and {0.0,0.9,0.2} or ((ui%3==1) and RED_USSR or AMBER_SCR)
        local la = 0.5 + math.abs(math.sin(t*2+ui))*0.5
        love.graphics.setColor(ledCol[1],ledCol[2],ledCol[3],la)
        love.graphics.circle("fill", rackX+10, rackY+12+ui*19, 3)
        love.graphics.circle("fill", rackX+18, rackY+12+ui*19, 3)
    end
    rivet(rackX+4,rackY+4); rivet(rackX+46,rackY+4)
    rivet(rackX+4,rackY+96); rivet(rackX+46,rackY+96)

    -- 7. GRAND ÉCRAN CRT central (mur du fond)
    local scrW, scrH = 140, 60
    local scrX = rx + rw/2 - scrW/2
    local scrY = ry + WALL + 5
    local scrText = "KGBCRYPT v2.1\nONE-TIME PAD ACTIVE\nDATA: 01001000 01100101\nSTATUS: ENCRYPTED"
    crtScreen(scrX, scrY, scrW, scrH, self.screenFlicker, scrText)

    -- 8. TÉLÉPHONE rouge (élément emblématique Guerre Froide)
    local telX = rx + rw/2 + 90
    local telY = ry + rh - WALL - 55
    -- socle
    love.graphics.setColor(0.15,0.15,0.15,1)
    love.graphics.rectangle("fill", telX, telY+30, 44, 8)
    -- corps du téléphone
    love.graphics.setColor(RED_USSR[1],RED_USSR[2],RED_USSR[3],1)
    love.graphics.rectangle("fill", telX+4, telY+8, 36, 22, 3)
    love.graphics.rectangle("fill", telX+2, telY+24, 40, 14, 2)
    -- combiné
    love.graphics.setColor(RED_USSR[1]*0.8,RED_USSR[2]*0.8,RED_USSR[3]*0.8,1)
    love.graphics.rectangle("fill", telX+6, telY, 32, 10, 4)
    -- cadran
    love.graphics.setColor(0.15,0.15,0.15,1)
    love.graphics.circle("fill", telX+22, telY+16, 8)
    love.graphics.setColor(METAL_LT[1],METAL_LT[2],METAL_LT[3],0.5)
    love.graphics.circle("line", telX+22, telY+16, 8)
    -- étiquette
    love.graphics.setFont(R.font_tiny)
    love.graphics.setColor(YELLOW_USSR[1],YELLOW_USSR[2],YELLOW_USSR[3],0.9)
    love.graphics.printf("KREMLIN", telX, telY+26, 44, "center")

    -- 9. LAMPES DE SIGNALISATION
    warningLight(rx+WALL+8, ry+WALL+10, self.warningBlink, RED_USSR)
    warningLight(rx+rw-WALL-8, ry+WALL+10, 1-self.warningBlink, AMBER_SCR)
    warningLight(rx+rw/2, ry+WALL+10, self.warningBlink*0.7, WIRE_COL)

    -- 10. AFFICHE PROPAGANDE (mur gauche)
    love.graphics.setColor(RED_USSR[1],RED_USSR[2],RED_USSR[3],0.9)
    love.graphics.rectangle("fill", rx+4, ry+rh-WALL-80, WALL-8, 60)
    love.graphics.setColor(YELLOW_USSR[1],YELLOW_USSR[2],YELLOW_USSR[3],1)
    -- étoile soviétique simplifiée
    local sx = rx+4+(WALL-8)/2
    local sy = ry+rh-WALL-60
    love.graphics.circle("fill", sx, sy, 8)
    love.graphics.setFont(R.font_tiny)
    love.graphics.setColor(YELLOW_USSR[1],YELLOW_USSR[2],YELLOW_USSR[3],1)
    love.graphics.printf("СССР", rx+4, ry+rh-WALL-30, WALL-8, "center")

    -- 11. TUYAUX additionnels sur les côtés
    pipe(rx+WALL, ry+rh-WALL-30, rx+rw-WALL, ry+rh-WALL-30, 5, PIPE_COL)
    pipe(rx+WALL+20, ry+WALL,    rx+WALL+20, ry+rh-WALL,    4, {0.55,0.20,0.10})

    -- 12. Inscription en cyrillique style (ASCII approx)
    love.graphics.setFont(R.font_tiny)
    love.graphics.setColor(0.20,0.80,0.35,0.3)
    love.graphics.printf("VERNAM • ONE-TIME PAD • NSA/KGB LEVEL ENCRYPTION • 1949", rx, ry+6, rw, "center")
end

-- Porte bunker (lourde porte en acier)
function RoomVernam:drawDoorTheme(d, col, isSolved)
    -- Cadre en acier épais
    love.graphics.setColor(CONCRETE_DK[1],CONCRETE_DK[2],CONCRETE_DK[3],1)
    love.graphics.rectangle("fill", d.x-10, d.y-4, d.w+20, d.h+4)

    -- Corps de la porte
    metalPanel(d.x, d.y, d.w, d.h)

    -- Renforts en croix
    love.graphics.setColor(METAL_LT[1],METAL_LT[2],METAL_LT[3],0.4)
    love.graphics.rectangle("fill", d.x+d.w/2-2, d.y+2, 4, d.h-4)
    love.graphics.rectangle("fill", d.x+2, d.y+d.h/2-2, d.w-4, 4)

    -- Rivets décoratifs
    rivet(d.x+8,  d.y+8);  rivet(d.x+d.w-8, d.y+8)
    rivet(d.x+8,  d.y+d.h-8); rivet(d.x+d.w-8, d.y+d.h-8)

    -- Poignée de bunker
    love.graphics.setColor(METAL_LT[1],METAL_LT[2],METAL_LT[3],1)
    love.graphics.rectangle("fill", d.x+d.w/2-8, d.y+d.h/2-4, 16, 8, 3)
    love.graphics.setColor(CONCRETE_DK[1],CONCRETE_DK[2],CONCRETE_DK[3],0.5)
    love.graphics.rectangle("line", d.x+d.w/2-8, d.y+d.h/2-4, 16, 8, 3)

    -- Voyant lumineux
    local la = isSolved and 1 or (0.4 + self.warningBlink*0.6)
    local lc  = isSolved and {0.0,0.9,0.2,1} or RED_USSR
    love.graphics.setColor(lc[1],lc[2],lc[3],la)
    love.graphics.circle("fill", d.x+d.w-8, d.y+10, 4)

    -- Bande danger en bas de la porte
    hazardStripe(d.x, d.y+d.h-8, d.w, 8)

    love.graphics.setFont(R.font_tiny)
    love.graphics.setColor(col[1],col[2],col[3],0.95)
    love.graphics.printf(isSolved and "OPEN" or "LOCKED", d.x, d.y+4, d.w, "center")
    if isSolved and self.terminal then
        love.graphics.setColor(WIRE_COL[1],WIRE_COL[2]+0.2,WIRE_COL[3],1)
        love.graphics.printf(self.terminal.doorCode, d.x-8, d.y+d.h+2, d.w+16, "center")
    end
end

function RoomVernam:load()
    local UI = require("systems.UIManager")
    local tOk, termImg = pcall(love.graphics.newImage, "assets/maps/terminal.png")
    local W    = UI.ROOM_W
    local H    = love.graphics.getHeight()
    local HUD  = UI.HUD_H
    local WALL = 48

    self.door.x = W/2 - 26
    self.door.y = H - WALL - 64
    self.door.w = 52
    self.door.h = 64

    -- Disquette / bande magnétique
    local chip = GameObject:new("chip1", 90, HUD+WALL+160, 36, 36, nil, true)
    chip.label = "Bande OTP"
    chip.icon  = "B"
    chip.iconColor = {AMBER_SCR[1],AMBER_SCR[2],AMBER_SCR[3],1}
    chip.dialogTitle = "Bande magnetique — CONFIDENTIEL"
    chip.dialogBody  = "Etiquette rouge :\n\"ONE-TIME PAD\nCLE XOR = 42\n\nOPERATION : VERNAM\"\n\nDans le terminal,\ntapez : xor 42"
    chip.hint = "Cle XOR = 42 — tapez 'xor 42' dans le terminal"
    table.insert(self.objects, chip)

    -- Manuel de cryptographie NSA
    local circuit = GameObject:new("circuit1", W-WALL-56, HUD+WALL+155, 36, 36, nil, true)
    circuit.label = "Manuel NSA"
    circuit.icon  = "M"
    circuit.iconColor = {GREEN_ARMY[1]+0.1,GREEN_ARMY[2]+0.2,GREEN_ARMY[3]+0.1,1}
    circuit.dialogTitle = "Manuel NSA — CONFIDENTIEL"
    circuit.dialogBody  = "\"Chiffre de Vernam (1917)\nGilbert Vernam & AT&T\n\nPrincipe XOR :\nA XOR B = C\nC XOR B = A\n\nLa cle est un nombre.\nXOR est reversible.\n\nSi A=72 ('H') et cle=42 :\n72 XOR 42 = 98 = 'b'\n98 XOR 42 = 72 = 'H'\""
    circuit.hint = "XOR est reversible : dechiffrer = rechiffrer avec la meme cle"
    table.insert(self.objects, circuit)

    -- Téléscripteur (objet central)
    local manual = GameObject:new("manual1", W/2+30, HUD+WALL+165, 36, 36, nil, true)
    manual.label = "Telecopieur"
    manual.icon  = "T"
    manual.iconColor = {AMBER_SCR[1],AMBER_SCR[2],AMBER_SCR[3],1}
    manual.dialogTitle = "Message chiffre intercepte"
    manual.dialogBody  = "Transmission XOR recue :\n\n01001000 01100101\n01101100 01101100\n01101111\n\n= 'H','e','l','l','o'\nXOR avec cle=42\n\nResultat : tapez\nxor 42 dans le terminal"
    manual.hint = "Le texte XOR decode avec la cle 42 donne le mot-cle final"
    table.insert(self.objects, manual)

    -- Terminal (vrai ordinateur style années 70)
    local term = GameObject:new("terminal", W/2-18, HUD+WALL+190, 36, 44,
        tOk and termImg or nil, true)
    term.label = "Ordinateur"
    term.icon  = "C"
    term.iconColor = {0.20, 0.80, 0.35, 1}
    term.isTerminal = true
    table.insert(self.objects, term)

    self.terminal = Terminal:new(
        "01001000 01100101 01101100 01101100 01101111",
        "vernam", "42", "999"
    )
end

function RoomVernam:update(dt, player)
    local t = love.timer.getTime()
    self.screenFlicker = math.sin(t * 17.3) * 0.08 + math.sin(t * 5.1) * 0.04
    self.warningBlink  = math.abs(math.sin(t * 1.8))
    Room.update(self, dt, player)
end

function RoomVernam:draw(player)
    Room.draw(self, player)
end

return RoomVernam
