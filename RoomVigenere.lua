-- ════════════════════════════════════════════
--  RoomVigenere.lua  —  Niveau 2 : Renaissance italienne
-- ════════════════════════════════════════════
local Room       = require("game.Room")
local GameObject = require("game.GameObject")
local Terminal   = require("game.Terminal")
local R          = require("systems.Renderer")

local RoomVigenere = {}
setmetatable(RoomVigenere, {__index = Room})

-- Palette Renaissance
local OAK      = {0.32, 0.20, 0.10}   -- chêne sombre
local OAK_LT   = {0.50, 0.34, 0.18}   -- chêne clair
local VELVET   = {0.40, 0.08, 0.12}   -- velours bordeaux
local VELVET_LT= {0.60, 0.14, 0.18}
local GOLD     = {0.85, 0.68, 0.12}   -- or Renaissance
local GOLD_DIM = {0.55, 0.42, 0.06}
local MARBLE   = {0.88, 0.84, 0.76}   -- marbre blanc/gris
local MARBLE_DK= {0.68, 0.62, 0.55}
local PARCH    = {0.92, 0.86, 0.68}   -- parchemin
local CANDLE   = {1.0,  0.82, 0.35}
local STONE2   = {0.55, 0.50, 0.42}
local BLUE_REN = {0.18, 0.32, 0.60}   -- bleu lapis-lazuli

function RoomVigenere:new()
    local r = Room.new(self, "CELLULE II  —  CHIFFRE DE VIGENERE  —  XVIe siecle", {0.30, 0.65, 0.90})
    r.historicalPeriod = "Renaissance italienne"
    r.keyword   = "LEMON"
    r.candleFlicker = 0
    setmetatable(r, self); self.__index = self
    return r
end

-- ── Helpers ──────────────────────────────────
local function woodPanel(x,y,w,h)
    love.graphics.setColor(OAK[1],OAK[2],OAK[3],1)
    love.graphics.rectangle("fill",x,y,w,h)
    -- veinage
    local numGrain = math.floor(w/6)
    for i=0,numGrain do
        local gx = x + i*6 + math.sin(i*1.7)*2
        love.graphics.setColor(OAK_LT[1],OAK_LT[2],OAK_LT[3],0.25)
        love.graphics.line(gx,y, gx+math.sin(i)*3, y+h)
    end
    -- bordure moulurée
    love.graphics.setColor(GOLD[1],GOLD[2],GOLD[3],0.5)
    love.graphics.rectangle("line",x,y,w,h)
    love.graphics.setColor(GOLD[1],GOLD[2],GOLD[3],0.25)
    love.graphics.rectangle("line",x+2,y+2,w-4,h-4)
end

local function bookshelf(x,y,w,h)
    -- étagère en chêne
    woodPanel(x,y,w,h)
    -- planches
    local shelfH = h/3
    for sh=1,2 do
        love.graphics.setColor(OAK_LT[1],OAK_LT[2],OAK_LT[3],0.6)
        love.graphics.rectangle("fill",x,y+sh*shelfH-3,w,6)
        love.graphics.setColor(0,0,0,0.2)
        love.graphics.line(x,y+sh*shelfH, x+w,y+sh*shelfH)
    end
    -- livres colorés
    local bookColors = {
        {0.55,0.10,0.10},{0.10,0.30,0.55},{0.10,0.45,0.20},
        {0.55,0.40,0.08},{0.40,0.10,0.50},{0.12,0.35,0.45},
        {0.60,0.25,0.08},{0.20,0.50,0.35},{0.50,0.10,0.35},
    }
    local bw = 10
    local bx = x+4
    for row=0,1 do
        local by = y + row*shelfH + 6
        local bh = shelfH - 10
        for i,bc in ipairs(bookColors) do
            if bx + bw < x+w-4 then
                love.graphics.setColor(bc[1],bc[2],bc[3],1)
                love.graphics.rectangle("fill",bx,by,bw-1,bh)
                love.graphics.setColor(GOLD[1],GOLD[2],GOLD[3],0.4)
                love.graphics.rectangle("line",bx,by,bw-1,bh)
                -- tranche
                love.graphics.setColor(bc[1]+0.2,bc[2]+0.1,bc[3]+0.1,0.6)
                love.graphics.line(bx,by+2,bx,by+bh-2)
                bx = bx + bw + math.random(0,4)
            end
        end
        bx = x + 4
    end
end

local function candle(cx, cy, flicker)
    local f = flicker
    -- chandelier base
    love.graphics.setColor(GOLD[1],GOLD[2],GOLD[3],1)
    love.graphics.rectangle("fill", cx-6, cy+14, 12, 4)   -- pied
    love.graphics.rectangle("fill", cx-3, cy,    6,  14)  -- tige
    love.graphics.setColor(0.95,0.92,0.80,1)
    love.graphics.rectangle("fill", cx-3, cy-16, 6, 16)   -- cire
    -- flamme
    love.graphics.setColor(CANDLE[1],CANDLE[2],CANDLE[3],0.9+f*0.1)
    love.graphics.ellipse("fill", cx+f, cy-20+f*0.5, 4, 7)
    love.graphics.setColor(1,0.95,0.6,0.7)
    love.graphics.ellipse("fill", cx+f*0.5, cy-23, 2, 5)
    -- halo
    love.graphics.setColor(CANDLE[1],CANDLE[2],CANDLE[3],0.06+f*0.02)
    love.graphics.circle("fill", cx, cy-18, 22)
end

local function ornamentedFrame(x,y,w,h, col)
    -- Cadre doré style Renaissance
    love.graphics.setColor(col[1],col[2],col[3],0.8)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", x,y,w,h)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(col[1],col[2],col[3],0.4)
    love.graphics.rectangle("line", x+4,y+4,w-8,h-8)
    -- coins
    local cs = 10
    love.graphics.setColor(col[1],col[2],col[3],0.9)
    for _, cx in ipairs({x,x+w}) do
        for _, cy in ipairs({y,y+h}) do
            love.graphics.circle("fill", cx, cy, 3)
        end
    end
end

-- ── Theme draw ────────────────────────────────
function RoomVigenere:drawTheme(rx, ry, rw, rh)
    local WALL = 48

    -- 1. SOL — parquet en chevrons
    local tile = 20
    for row = 0, math.ceil(rh/tile)+1 do
        for col = 0, math.ceil(rw/tile)+1 do
            local lx = rx + col*tile
            local ly = ry + row*tile
            local isAlt = (row+col)%2 == 0
            local br = isAlt and 0.38 or 0.30
            love.graphics.setColor(br*OAK_LT[1], br*2*OAK_LT[2], br*OAK_LT[3], 1)
            -- chevron orienté
            if (col%2)==0 then
                love.graphics.rectangle("fill",lx+1,ly+1,tile-2,tile-2)
            else
                love.graphics.rectangle("fill",lx+1,ly+1,tile-2,tile-2)
                love.graphics.setColor(0,0,0,0.08)
                love.graphics.line(lx+1,ly+1,lx+tile-1,ly+tile-1)
            end
        end
    end
    -- joints parquet
    love.graphics.setColor(0,0,0,0.15)
    for row=0,math.ceil(rh/tile) do love.graphics.line(rx,ry+row*tile,rx+rw,ry+row*tile) end
    for col=0,math.ceil(rw/tile) do love.graphics.line(rx+col*tile,ry,rx+col*tile,ry+rh) end

    -- 2. MUR DU FOND — lambris en chêne
    woodPanel(rx, ry, rw, WALL+30)
    -- moulure supérieure
    love.graphics.setColor(GOLD[1],GOLD[2],GOLD[3],0.55)
    love.graphics.rectangle("fill", rx, ry+WALL+28, rw, 4)
    love.graphics.setColor(1,1,1,0.2)
    love.graphics.line(rx, ry+WALL+28, rx+rw, ry+WALL+28)

    -- 3. MURS LATÉRAUX — pierres avec lambris bas
    love.graphics.setColor(STONE2[1],STONE2[2],STONE2[3],1)
    love.graphics.rectangle("fill", rx, ry+WALL, WALL, rh-WALL*2)
    love.graphics.rectangle("fill", rx+rw-WALL, ry+WALL, WALL, rh-WALL*2)
    -- lambris bas murs latéraux
    woodPanel(rx, ry+rh-WALL-30, WALL, 30)
    woodPanel(rx+rw-WALL, ry+rh-WALL-30, WALL, 30)
    -- ombre intérieure
    love.graphics.setColor(0,0,0,0.2)
    love.graphics.rectangle("fill", rx+WALL,     ry+WALL, 10, rh-WALL*2)
    love.graphics.rectangle("fill", rx+rw-WALL-10, ry+WALL, 10, rh-WALL*2)

    -- 4. BIBLIOTHÈQUE murale (mur droit)
    bookshelf(rx+rw-WALL-2, ry+WALL+35, WALL+2, rh-WALL*2-65)

    -- 5. TAPISSERIE sur mur gauche
    love.graphics.setColor(VELVET[1],VELVET[2],VELVET[3],0.85)
    love.graphics.rectangle("fill", rx+2, ry+WALL+40, WALL-4, rh-WALL*2-80)
    -- motif géométrique tapisserie
    local tw2 = WALL-4
    local th2  = rh-WALL*2-80
    love.graphics.setColor(GOLD[1],GOLD[2],GOLD[3],0.35)
    for ti=0,math.floor(th2/18) do
        love.graphics.rectangle("line", rx+4, ry+WALL+42+ti*18, tw2-4, 16)
    end
    love.graphics.setColor(GOLD[1],GOLD[2],GOLD[3],0.6)
    love.graphics.rectangle("line", rx+2, ry+WALL+40, tw2, th2)

    -- 6. TABLE centrale style Renaissance
    local tblX = rx + rw/2 - 80
    local tblY = ry + rh - WALL - 60
    local tblW, tblH = 160, 45
    -- plateau
    woodPanel(tblX, tblY, tblW, 10)
    love.graphics.setColor(GOLD[1],GOLD[2],GOLD[3],0.4)
    love.graphics.rectangle("line", tblX, tblY, tblW, 10)
    -- pieds tournés
    for _, px in ipairs({tblX+10, tblX+tblW-10}) do
        love.graphics.setColor(OAK[1],OAK[2],OAK[3],1)
        love.graphics.rectangle("fill", px-4, tblY+10, 8, tblH-10)
        love.graphics.setColor(OAK_LT[1],OAK_LT[2],OAK_LT[3],0.5)
        love.graphics.rectangle("fill", px-2, tblY+10, 4, tblH-10)
        -- traverse
        love.graphics.setColor(OAK[1],OAK[2],OAK[3],1)
    end
    love.graphics.rectangle("fill", tblX+10, tblY+tblH-16, tblW-20, 6)

    -- Parchemin sur table
    love.graphics.setColor(PARCH[1],PARCH[2],PARCH[3],0.9)
    love.graphics.rectangle("fill", tblX+25, tblY-18, 60, 24, 2)
    love.graphics.setColor(GOLD_DIM[1],GOLD_DIM[2],GOLD_DIM[3],0.5)
    love.graphics.rectangle("line", tblX+25, tblY-18, 60, 24, 2)
    love.graphics.setFont(R.font_tiny)
    love.graphics.setColor(0.25,0.15,0.05,0.8)
    love.graphics.printf("Tabula", tblX+25, tblY-13, 60, "center")

    -- Chandelier sur table
    local cf = self.candleFlicker
    candle(tblX+130, tblY+2, cf)
    candle(tblX+20,  tblY+2, -cf)

    -- 7. Fenêtre (mur du fond, gauche)
    local winX = rx + 80
    local winY = ry + WALL + 5
    local winW, winH = 44, 36
    love.graphics.setColor(0.55,0.72,0.85,0.4)
    love.graphics.rectangle("fill", winX, winY, winW, winH)
    -- lumière extérieure
    love.graphics.setColor(1,0.95,0.80,0.25)
    love.graphics.rectangle("fill", winX+2, winY+2, winW-4, winH-4)
    -- croisillon
    love.graphics.setColor(OAK[1],OAK[2],OAK[3],1)
    love.graphics.rectangle("fill", winX+winW/2-1, winY, 3, winH)
    love.graphics.rectangle("fill", winX, winY+winH/2-1, winW, 3)
    -- cadre doré
    ornamentedFrame(winX-3, winY-3, winW+6, winH+6, GOLD)

    -- 8. Fenêtre droite
    local win2X = rx + rw - 80 - winW - WALL
    ornamentedFrame(win2X-3, winY-3, winW+6, winH+6, GOLD)
    love.graphics.setColor(0.55,0.72,0.85,0.4)
    love.graphics.rectangle("fill", win2X, winY, winW, winH)
    love.graphics.setColor(1,0.95,0.80,0.2)
    love.graphics.rectangle("fill", win2X+2, winY+2, winW-4, winH-4)
    love.graphics.setColor(OAK[1],OAK[2],OAK[3],1)
    love.graphics.rectangle("fill", win2X+winW/2-1,winY,3,winH)
    love.graphics.rectangle("fill", win2X,winY+winH/2-1,winW,3)

    -- 9. Plafond à caissons
    love.graphics.setColor(OAK[1],OAK[2],OAK[3],0.9)
    love.graphics.rectangle("fill", rx, ry, rw, WALL)
    local cSize = 30
    for ci=0, math.ceil(rw/cSize) do
        love.graphics.setColor(OAK_LT[1],OAK_LT[2],OAK_LT[3],0.3)
        love.graphics.rectangle("line", rx+ci*cSize+2, ry+2, cSize-4, WALL-8)
        love.graphics.setColor(GOLD[1],GOLD[2],GOLD[3],0.15)
        love.graphics.rectangle("fill", rx+ci*cSize+4, ry+4, cSize-8, WALL-12)
    end
    -- corniche
    love.graphics.setColor(GOLD[1],GOLD[2],GOLD[3],0.5)
    love.graphics.rectangle("fill", rx, ry+WALL-4, rw, 4)

    -- 10. Inscription sur le mur
    love.graphics.setFont(R.font_tiny)
    love.graphics.setColor(GOLD[1],GOLD[2],GOLD[3],0.65)
    love.graphics.printf("Blaise de Vigenere  •  Traicte des Chiffres  •  MDLXXXVI", rx, ry+5, rw, "center")
end

-- Porte Renaissance (double vantail avec moulures)
function RoomVigenere:drawDoorTheme(d, col, isSolved)
    -- Chambranle mouluré
    love.graphics.setColor(OAK[1],OAK[2],OAK[3],1)
    love.graphics.rectangle("fill", d.x-10, d.y-6, d.w+20, d.h+6)
    love.graphics.setColor(GOLD[1],GOLD[2],GOLD[3],0.5)
    love.graphics.rectangle("line", d.x-10, d.y-6, d.w+20, d.h+6)

    -- Double vantail
    local hw = d.w/2 - 1
    for side=0,1 do
        local vx = d.x + side*(hw+2)
        woodPanel(vx, d.y, hw, d.h)
        -- panneau central
        love.graphics.setColor(OAK_LT[1],OAK_LT[2],OAK_LT[3],0.3)
        love.graphics.rectangle("fill", vx+4, d.y+8, hw-8, d.h-16)
        love.graphics.setColor(GOLD[1],GOLD[2],GOLD[3],0.4)
        love.graphics.rectangle("line", vx+4, d.y+8, hw-8, d.h-16)
        -- poignée
        love.graphics.setColor(GOLD[1],GOLD[2],GOLD[3],0.9)
        local kx = side==0 and (vx+hw-5) or (vx+4)
        love.graphics.rectangle("fill", kx-2, d.y+d.h/2-6, 4, 12, 2)
    end

    love.graphics.setFont(R.font_tiny)
    love.graphics.setColor(col[1],col[2],col[3],0.9)
    love.graphics.printf(isSolved and "APERTO" or "CHIUSO", d.x, d.y+d.h-14, d.w, "center")
    if isSolved and self.terminal then
        love.graphics.setColor(GOLD[1],GOLD[2],GOLD[3],1)
        love.graphics.printf(self.terminal.doorCode, d.x-8, d.y+d.h+2, d.w+16, "center")
    end
end

function RoomVigenere:load()
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

    -- Codex sur l'étagère
    local codex = GameObject:new("book1", W-WALL-62, HUD+WALL+50, 38, 38, nil, true)
    codex.label = "Codex"
    codex.icon  = "C"
    codex.iconColor = {GOLD[1],GOLD[2],GOLD[3],1}
    codex.dialogTitle = "Codex Vigenere — 1586"
    codex.dialogBody  = "\"Traicte des Chiffres\"\npar Blaise de Vigenere\n\nNote au crayon :\n\"La cle est un mot,\nrepete en boucle.\n\nMot-cle de cette salle :\nLEMON\"\n\nEntrez ce mot dans\nle terminal."
    codex.hint = "Cle Vigenere : LEMON"
    table.insert(self.objects, codex)

    -- Cle en or sur la table
    local key = GameObject:new("key1", 95, HUD+WALL+55, 36, 36, nil, true)
    key.label = "Cle en or"
    key.icon  = "K"
    key.iconColor = {GOLD[1],GOLD[2],GOLD[3],1}
    key.dialogTitle = "Cle Renaissance"
    key.dialogBody  = "Une cle en or fin,\ngravee de lettres :\n\nL  E  M  O  N\n\nC'est la cle du\nchiffre de Vigenere.\nEntrez LEMON dans\nle terminal."
    key.hint = "La cle est : LEMON — entrez-la dans le terminal"
    table.insert(self.objects, key)

    -- Parchemin sur table
    local board = GameObject:new("board1", W/2-50, HUD+WALL+55, 38, 38, nil, true)
    board.label = "Parchemin"
    board.icon  = "P"
    board.iconColor = {0.75,0.62,0.25,1}
    board.dialogTitle = "Table de Vigenere"
    board.dialogBody  = "Un tableau 26x26 sur\nparchemin jauni.\n\nPour dechiffrer :\n1. Prenez la lettre du texte\n2. Prenez la lettre de la cle\n3. Trouvez l'intersection\n\nEn clair :\nLXFOPVEFRNHR + LEMON\n= ATTACKATDAWN"
    board.hint = "Methode Vigenere — tapez le mot-cle LEMON"
    table.insert(self.objects, board)

    -- Terminal (style pupitre)
    local term = GameObject:new("terminal", W/2-18, HUD+WALL+190, 36, 44,
        tOk and termImg or nil, true)
    term.label = "Pupitre"
    term.icon  = "T"
    term.iconColor = {0.30, 0.65, 0.90, 1}
    term.isTerminal = true
    table.insert(self.objects, term)

    self.terminal = Terminal:new(
        "LXFOPVEFRNHR",
        "vigenere", "ATTACKATDAWN", "77"
    )
end

function RoomVigenere:update(dt, player)
    self.candleFlicker = math.sin(love.timer.getTime() * 5.1) * 0.35
                       + math.sin(love.timer.getTime() * 11.7) * 0.15
    Room.update(self, dt, player)
end

function RoomVigenere:draw(player)
    Room.draw(self, player)
end

return RoomVigenere
