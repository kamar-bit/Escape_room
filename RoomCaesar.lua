-- ════════════════════════════════════════════
--  RoomCaesar.lua  —  Niveau 1 : Antiquité romaine
-- ════════════════════════════════════════════
local Room       = require("game.Room")
local GameObject = require("game.GameObject")
local Terminal   = require("game.Terminal")
local R          = require("systems.Renderer")

local RoomCaesar = {}
setmetatable(RoomCaesar, {__index = Room})

-- Palette romaine
local STONE      = {0.62, 0.55, 0.42}   -- pierre calcaire
local STONE_DARK = {0.35, 0.30, 0.22}   -- ombre
local STONE_LIGHT= {0.78, 0.72, 0.58}   -- reflet
local MOSAIC_1   = {0.72, 0.55, 0.18}   -- or antique
local MOSAIC_2   = {0.55, 0.18, 0.12}   -- rouge pompéien
local MOSAIC_3   = {0.18, 0.35, 0.55}   -- bleu azur
local WOOD       = {0.40, 0.28, 0.14}
local TORCH_ORG  = {1.00, 0.60, 0.10}
local TORCH_YEL  = {1.00, 0.90, 0.30}
local SHADOW     = {0, 0, 0}

function RoomCaesar:new()
    local r = Room.new(self, "CELLULE I  —  CHIFFRE DE CESAR  —  Ier siecle av. J.-C.", {0.90, 0.72, 0.25})
    r.historicalPeriod = "Antiquite romaine"
    r.torchFlicker = 0
    setmetatable(r, self); self.__index = self
    return r
end

-- ── Helpers de dessin ────────────────────────
local function stone(x,y,w,h)
    love.graphics.setColor(STONE[1],STONE[2],STONE[3],1)
    love.graphics.rectangle("fill",x,y,w,h)
    love.graphics.setColor(STONE_LIGHT[1],STONE_LIGHT[2],STONE_LIGHT[3],0.5)
    love.graphics.line(x,y,x+w,y)
    love.graphics.line(x,y,x,y+h)
    love.graphics.setColor(STONE_DARK[1],STONE_DARK[2],STONE_DARK[3],0.6)
    love.graphics.line(x+w,y,x+w,y+h)
    love.graphics.line(x,y+h,x+w,y+h)
end

local function column(cx, baseY, totalH)
    local shaft_w = 18
    local cx2 = cx - shaft_w/2

    -- Base (stylobate)
    stone(cx2-6, baseY-8, shaft_w+12, 8)
    -- Shaft with entasis
    for row = 0, totalH-16, 2 do
        local taper = math.abs((row/(totalH-16)) - 0.5) * 3
        local sw = shaft_w - taper
        local sx = cx - sw/2
        love.graphics.setColor(STONE[1],STONE[2],STONE[3],1)
        love.graphics.rectangle("fill", sx, baseY - 16 - row - 2, sw, 2)
        -- flûte
        love.graphics.setColor(STONE_DARK[1],STONE_DARK[2],STONE_DARK[3],0.3)
        for fi = 1, 3 do
            love.graphics.line(sx + fi*(sw/4), baseY-16-row-2,
                               sx + fi*(sw/4), baseY-16-row)
        end
    end
    -- Chapiteau dorique
    local capY = baseY - 16 - totalH
    stone(cx2-8, capY,   shaft_w+16, 6)   -- abaque
    stone(cx2-4, capY+6, shaft_w+8,  4)   -- échine
end

local function torch(cx, cy, flicker)
    local f = flicker
    -- support mural
    love.graphics.setColor(STONE_DARK[1],STONE_DARK[2],STONE_DARK[3],1)
    love.graphics.rectangle("fill", cx-3, cy, 6, 14)
    -- bol
    love.graphics.setColor(WOOD[1],WOOD[2],WOOD[3],1)
    love.graphics.rectangle("fill", cx-6, cy-4, 12, 8)
    -- flamme (plusieurs cercles qui bougent)
    local baseAlpha = 0.85 + f*0.15
    love.graphics.setColor(TORCH_ORG[1],TORCH_ORG[2],TORCH_ORG[3], baseAlpha)
    love.graphics.ellipse("fill", cx + f*2,   cy-10+f, 7, 10)
    love.graphics.setColor(TORCH_YEL[1],TORCH_YEL[2],TORCH_YEL[3], baseAlpha)
    love.graphics.ellipse("fill", cx + f*1.5, cy-14+f, 4, 8)
    love.graphics.setColor(1,1,1, 0.6*baseAlpha)
    love.graphics.ellipse("fill", cx,         cy-16,   2, 4)
    -- halo lumineux
    love.graphics.setColor(TORCH_ORG[1],TORCH_ORG[2],TORCH_ORG[3], 0.07+f*0.03)
    love.graphics.circle("fill", cx, cy-8, 30)
end

local function mosaicTile(x,y,size, c1,c2,c3)
    -- Motif de mosaïque en damier coloré
    local cols = {c1,c2,c3}
    local ts = size/4
    for row=0,3 do for col=0,3 do
        local ci = ((row+col)%3)+1
        local cc = cols[ci]
        love.graphics.setColor(cc[1],cc[2],cc[3],0.7)
        love.graphics.rectangle("fill", x+col*ts+0.5, y+row*ts+0.5, ts-1, ts-1)
    end end
end

local function arch(cx, topY, w, h, col, fillAlpha)
    -- Arc semi-circulaire
    love.graphics.setColor(col[1],col[2],col[3],fillAlpha or 0.15)
    love.graphics.arc("fill", cx, topY+h/2, w/2, -math.pi, 0)
    love.graphics.rectangle("fill", cx-w/2, topY+h/2, w, h/2)
    love.graphics.setColor(col[1],col[2],col[3],0.6)
    love.graphics.setLineWidth(2)
    love.graphics.arc("line", cx, topY+h/2, w/2, -math.pi, 0)
    love.graphics.line(cx-w/2, topY+h/2, cx-w/2, topY+h)
    love.graphics.line(cx+w/2, topY+h/2, cx+w/2, topY+h)
    love.graphics.setLineWidth(1)
end

-- ── Theme draw ────────────────────────────────
function RoomCaesar:drawTheme(x, y, w, h)
    local WALL = 48
    local ac = self.accentColor

    -- 1. SOL — dallage de marbre avec joints
    love.graphics.setColor(0.60, 0.52, 0.38, 1)
    love.graphics.rectangle("fill", x, y, w, h)
    -- dalles
    local ts = 40
    for row = 0, math.ceil(h/ts) do
        for col = 0, math.ceil(w/ts) do
            local lx = x + col*ts
            local ly = y + row*ts
            love.graphics.setColor(0.64+((row+col)%2)*0.04,
                                   0.56+((row+col)%2)*0.04,
                                   0.40+((row+col)%2)*0.03, 1)
            love.graphics.rectangle("fill", lx+1, ly+1, ts-2, ts-2)
        end
    end
    -- joints en grille
    love.graphics.setColor(0.35,0.28,0.18,0.5)
    for row=0, math.ceil(h/ts) do love.graphics.line(x,y+row*ts, x+w,y+row*ts) end
    for col=0, math.ceil(w/ts) do love.graphics.line(x+col*ts,y, x+col*ts,y+h) end

    -- 2. MUR DU FOND (haut)
    love.graphics.setColor(STONE[1],STONE[2],STONE[3],1)
    love.graphics.rectangle("fill", x, y, w, WALL+20)
    -- assises horizontales
    love.graphics.setColor(STONE_DARK[1],STONE_DARK[2],STONE_DARK[3],0.3)
    for row = 0, 3 do love.graphics.line(x,y+row*16,x+w,y+row*16) end
    -- reflet supérieur
    love.graphics.setColor(STONE_LIGHT[1],STONE_LIGHT[2],STONE_LIGHT[3],0.4)
    love.graphics.line(x,y+1,x+w,y+1)
    -- frise dorée
    love.graphics.setColor(MOSAIC_1[1],MOSAIC_1[2],MOSAIC_1[3],0.55)
    love.graphics.rectangle("fill", x, y+WALL+14, w, 6)
    love.graphics.setColor(1,1,1,0.2)
    love.graphics.line(x,y+WALL+14,x+w,y+WALL+14)

    -- 3. MURS LATÉRAUX
    love.graphics.setColor(STONE[1],STONE[2],STONE[3],1)
    love.graphics.rectangle("fill", x, y+WALL, WALL, h-WALL*2)          -- gauche
    love.graphics.rectangle("fill", x+w-WALL, y+WALL, WALL, h-WALL*2)  -- droite
    -- ombre intérieure
    love.graphics.setColor(0,0,0,0.25)
    love.graphics.rectangle("fill", x+WALL,    y+WALL, 8, h-WALL*2)
    love.graphics.rectangle("fill", x+w-WALL-8,y+WALL, 8, h-WALL*2)

    -- 4. COLONNES DORIQUES — gauche et droite
    local colH = h - WALL*2 - 20
    local colBaseY = y + h - WALL
    column(x + WALL + 2,  colBaseY, colH)
    column(x + WALL + 60, colBaseY, colH)
    column(x + w - WALL - 2,  colBaseY, colH)
    column(x + w - WALL - 60, colBaseY, colH)

    -- 5. MOSAÏQUE au sol (bande décorative centrale)
    local mz_y = y + h - WALL - 20
    for mi = 0, math.floor(w/20)-1 do
        mosaicTile(x + mi*20, mz_y, 20, MOSAIC_1, MOSAIC_2, MOSAIC_3)
    end

    -- 6. TORCHES murales avec flicker
    local f = self.torchFlicker
    torch(x + WALL + 35, y + WALL + 35, f)
    torch(x + w - WALL - 35, y + WALL + 35, -f)

    -- 7. NICHE murale avec buste (décoration)
    local nicheX = x + w/2 - 18
    local nicheY = y + WALL + 22
    -- niche
    love.graphics.setColor(STONE_DARK[1],STONE_DARK[2],STONE_DARK[3],0.5)
    love.graphics.rectangle("fill", nicheX, nicheY, 36, 28)
    love.graphics.setColor(STONE[1],STONE[2],STONE[3],1)
    love.graphics.rectangle("fill", nicheX+2, nicheY+2, 32, 24)
    -- buste simplifié (Caesar bust)
    love.graphics.setColor(0.78,0.72,0.60,1)
    love.graphics.circle("fill", nicheX+18, nicheY+12, 7)   -- tête
    love.graphics.rectangle("fill", nicheX+12, nicheY+18, 12, 8) -- torse
    -- couronne de laurier
    love.graphics.setColor(MOSAIC_1[1],MOSAIC_1[2],MOSAIC_1[3],0.9)
    love.graphics.arc("line", nicheX+18, nicheY+10, 9, -math.pi*0.9, -math.pi*0.1)

    -- 8. INSCRIPTION latine sur le mur
    love.graphics.setFont(R.font_tiny)
    love.graphics.setColor(MOSAIC_1[1],MOSAIC_1[2],MOSAIC_1[3],0.7)
    love.graphics.printf("SPQR  •  AVE CAESAR  •  III - I", x, y+4, w, "center")

    -- 9. Ombre au sol sous murs
    love.graphics.setColor(0,0,0,0.18)
    love.graphics.rectangle("fill", x, y+h-WALL-12, w, 12)
end

-- Porte romaine (arc)
function RoomCaesar:drawDoorTheme(d, col, isSolved)
    local stoneC = isSolved and {0.55,0.72,0.45} or STONE

    -- Chambranle en pierre
    stone(d.x-8, d.y, 8, d.h)
    stone(d.x+d.w, d.y, 8, d.h)
    stone(d.x-8, d.y-14, d.w+16, 14)  -- linteau

    -- Arc au-dessus
    love.graphics.setColor(stoneC[1],stoneC[2],stoneC[3],0.9)
    love.graphics.arc("fill", d.x+d.w/2, d.y, d.w/2+8, -math.pi, 0)
    love.graphics.setColor(STONE_DARK[1],STONE_DARK[2],STONE_DARK[3],0.5)
    love.graphics.arc("line", d.x+d.w/2, d.y, d.w/2+8, -math.pi, 0)

    -- Vantail de porte en bois
    love.graphics.setColor(WOOD[1],WOOD[2],WOOD[3], isSolved and 0.5 or 1)
    love.graphics.rectangle("fill", d.x+1, d.y+1, d.w-2, d.h-2)
    -- planches
    love.graphics.setColor(0,0,0,0.2)
    for i=1,4 do love.graphics.line(d.x+1,d.y+i*(d.h/5),d.x+d.w-1,d.y+i*(d.h/5)) end
    -- traverse diagonale
    love.graphics.setColor(STONE_DARK[1],STONE_DARK[2],STONE_DARK[3],0.3)
    love.graphics.line(d.x+2,d.y+2, d.x+d.w-2,d.y+d.h-2)

    -- Heurtoir
    love.graphics.setColor(MOSAIC_1[1],MOSAIC_1[2],MOSAIC_1[3],0.9)
    love.graphics.circle("fill", d.x+d.w/2, d.y+d.h/2, 4)
    love.graphics.setColor(0,0,0,0.3)
    love.graphics.circle("line", d.x+d.w/2, d.y+d.h/2, 4)

    -- Serrure / état
    love.graphics.setFont(R.font_tiny)
    love.graphics.setColor(col[1],col[2],col[3],0.95)
    love.graphics.printf(isSolved and "OPEN" or "LOCK", d.x, d.y+d.h-16, d.w, "center")
    if isSolved and self.terminal then
        love.graphics.setColor(MOSAIC_1[1],MOSAIC_1[2],MOSAIC_1[3],1)
        love.graphics.printf(self.terminal.doorCode, d.x-8, d.y+d.h+2, d.w+16, "center")
    end
end

function RoomCaesar:load()
    local UI = require("systems.UIManager")
    local sOk, shieldImg = pcall(love.graphics.newImage, "assets/maps/object_shield.png")
    local tOk, termImg   = pcall(love.graphics.newImage, "assets/maps/terminal.png")

    local W    = UI.ROOM_W
    local H    = love.graphics.getHeight()
    local HUD  = UI.HUD_H
    local WALL = 48

    self.door.x = W/2 - 26
    self.door.y = H - WALL - 64
    self.door.w = 52
    self.door.h = 64

    -- Bouclier 1
    local s1 = GameObject:new("shield1", 108, HUD+WALL+55, 38, 38,
        sOk and shieldImg or nil, true)
    s1.label = "Bouclier I"
    s1.icon  = "SC"
    s1.iconColor = {MOSAIC_1[1],MOSAIC_1[2],MOSAIC_1[3],1}
    s1.dialogTitle = "Bouclier legionnaire"
    s1.dialogBody  = "Gravure en latin :\n\"LITTERA MIGRAT\"\n(la lettre se deplace)\n\nChaque lettre de l'alphabet\nest decalee d'un certain nombre\nde positions vers la droite."
    s1.hint = "Indice : chaque lettre est decalee dans l'alphabet"
    table.insert(self.objects, s1)

    -- Bouclier 2
    local s2 = GameObject:new("shield2", 230, HUD+WALL+45, 38, 38,
        sOk and shieldImg or nil, true)
    s2.label = "Bouclier II"
    s2.icon  = "SC"
    s2.iconColor = {MOSAIC_1[1],MOSAIC_1[2],MOSAIC_1[3],1}
    s2.dialogTitle = "Bouclier du centurion"
    s2.dialogBody  = "Inscription gravee :\n\"Caesar solebat III\nSed hic numerus alius est...\"\n\n(Cesar utilisait 3\nmais ce nombre est different)\n\nLe vrai decalage est grave\npres de la porte."
    s2.hint = "Le decalage n'est pas 3. Regardez pres de la porte !"
    table.insert(self.objects, s2)

    -- Parchemin sur colonne
    local scroll = GameObject:new("scroll1", W-172, HUD+WALL+55, 36, 36, nil, true)
    scroll.label = "Parchemin"
    scroll.icon  = "P"
    scroll.iconColor = {MOSAIC_3[1],MOSAIC_3[2],MOSAIC_3[3]+0.2,1}
    scroll.dialogTitle = "Parchemin imperial"
    scroll.dialogBody  = "Un rouleau de papyrus :\n\n\"QUATTUOR — le nombre\ndes legions de Cesar\nen Gaule.\n\nROT-4 : decale chaque\nlettre de 4 positions.\nEssayez 4 dans le terminal.\""
    scroll.hint = "La cle de dechiffrement CESAR = 4"
    table.insert(self.objects, scroll)

    -- Terminal (style tablette de cire romaine)
    local term = GameObject:new("terminal", W/2-18, HUD+WALL+185, 36, 44,
        tOk and termImg or nil, true)
    term.label = "Tabula"
    term.icon  = "T"
    term.iconColor = {0.0, 0.85, 0.45, 1}
    term.isTerminal = true
    table.insert(self.objects, term)

    self.terminal = Terminal:new(
        "XLI GEWEIV QIXLSH MW FEWIH SR E WLMJX",
        "caesar", "4", "IV"
    )
end

function RoomCaesar:update(dt, player)
    -- Flicker de torche
    self.torchFlicker = math.sin(love.timer.getTime() * 7.3) * 0.4
                      + math.sin(love.timer.getTime() * 13.1) * 0.2
    Room.update(self, dt, player)
end

function RoomCaesar:draw(player)
    Room.draw(self, player)
end

return RoomCaesar
