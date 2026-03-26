-- ════════════════════════════════════════════
--  UIManager.lua
-- ════════════════════════════════════════════
local R = require("systems.Renderer")
local UIManager = {}

local W = 960
local H = 640
local PANEL_X = 660   -- side panel starts here
local PANEL_W = 300
local HUD_H   = 36
local ROOM_W  = PANEL_X
local ROOM_H  = H - HUD_H

-- ── Notification queue ────────────────────────
UIManager.notifications = {}

function UIManager.notify(msg, ntype, duration)
    table.insert(UIManager.notifications, {
        msg   = msg,
        ntype = ntype or "green",
        timer = duration or 3.0,
        alpha = 1.0
    })
end

function UIManager.updateNotifs(dt)
    for i = #UIManager.notifications, 1, -1 do
        local n = UIManager.notifications[i]
        n.timer = n.timer - dt
        if n.timer < 0.6 then n.alpha = n.timer / 0.6 end
        if n.timer <= 0 then table.remove(UIManager.notifications, i) end
    end
end

function UIManager.drawNotifs()
    local ny = HUD_H + 8
    for _, n in ipairs(UIManager.notifications) do
        local col
        if n.ntype == "green" then col = R.C.green
        elseif n.ntype == "amber" then col = R.C.amber
        else col = R.C.red end
        local tw = 220
        local tx = PANEL_X + (PANEL_W - tw) / 2
        R.panel(tx, ny, tw, 22,
            {col[1],col[2],col[3], 0.12*n.alpha},
            {col[1],col[2],col[3], 0.7*n.alpha})
        love.graphics.setFont(R.font_small)
        love.graphics.setColor(col[1],col[2],col[3], n.alpha)
        love.graphics.printf(n.msg, tx+4, ny+5, tw-8, "center")
        ny = ny + 28
    end
end

-- ═══════════════════════════════════════════
--  TOP HUD
-- ═══════════════════════════════════════════
function UIManager.drawHUD(gameState, t)
    -- Background bar
    R.panel(0, 0, W, HUD_H, R.C.bg_panel, R.C.border)

    -- Logo
    R.glowText("TDC", 8, 9, R.C.green, R.font_normal)

    -- Separator
    R.setColor(R.C.border)
    love.graphics.line(42, 6, 42, HUD_H-6)

    -- Level pips
    local rooms = {"caesar", "vigenere", "vernam"}
    local labels = {"CESAR", "VIGENERE", "VERNAM"}
    local pipColors = {R.C.green, R.C.cyan, R.C.red}
    for i, rname in ipairs(rooms) do
        local px = 52 + (i-1)*72
        local py = 13
        local pw, ph = 60, 10
        local col = pipColors[i]
        local isCurrent = (gameState.currentRoom == rname)
        local isSolved  = gameState.roomsSolved[rname]
        -- pip bg
        if isCurrent then
            R.panel(px,py,pw,ph, {col[1],col[2],col[3],0.25}, col)
        elseif isSolved then
            R.panel(px,py,pw,ph, {col[1],col[2],col[3],0.15}, {col[1],col[2],col[3],0.4})
        else
            R.panel(px,py,pw,ph, {0,0,0,0.3}, R.C.border)
        end
        -- label
        local a = isCurrent and 1 or (isSolved and 0.5 or 0.25)
        love.graphics.setFont(R.font_tiny)
        love.graphics.setColor(col[1],col[2],col[3],a)
        love.graphics.printf(labels[i], px, py+1, pw, "center")
    end

    -- Separator
    R.setColor(R.C.border)
    love.graphics.line(280, 6, 280, HUD_H-6)

    -- Room name
    local roomNames = {caesar="CELLULE I — CESAR", vigenere="CELLULE II — VIGENERE", vernam="CELLULE III — VERNAM"}
    local roomCols  = {caesar=R.C.green, vigenere=R.C.cyan, vernam=R.C.red}
    love.graphics.setFont(R.font_small)
    R.setColor(roomCols[gameState.currentRoom] or R.C.green)
    love.graphics.print(roomNames[gameState.currentRoom] or "", 290, 10)

    -- Timer (right side)
    local timerSecs = gameState.timerSeconds or 900
    local m = math.floor(timerSecs/60)
    local s = timerSecs % 60
    local timerStr = string.format("%02d:%02d", m, s)
    local tcol = (timerSecs < 120) and R.C.red or R.C.amber
    local ta = (timerSecs < 120) and R.blinkAlpha(t, 3) or 1
    love.graphics.setFont(R.font_normal)
    love.graphics.setColor(tcol[1],tcol[2],tcol[3], ta)
    love.graphics.print(timerStr, W - 110, 10)

    -- Hints counter
    love.graphics.setFont(R.font_tiny)
    R.setColor(R.C.green_dim)
    love.graphics.print("INDICES:", W - 180, 6)
    R.setColor(R.C.green)
    love.graphics.print(tostring(gameState.hintsCount or 0).."/3", W - 180, 16)

    -- Solved rooms
    local solved = 0
    for _,v in pairs(gameState.roomsSolved) do if v then solved=solved+1 end end
    love.graphics.setFont(R.font_tiny)
    R.setColor(R.C.green_dim)
    love.graphics.print("SALLES:", W - 220, 6)
    R.setColor(R.C.green)
    love.graphics.print(solved.."/3", W - 220, 16)
end

-- ═══════════════════════════════════════════
--  SIDE PANEL
-- ═══════════════════════════════════════════
function UIManager.drawSidePanel(gameState, terminal, t)
    local x, y, w = PANEL_X, HUD_H, PANEL_W
    local h = H - HUD_H

    -- Background
    R.panel(x, y, w, h, R.C.bg_panel, R.C.border)

    -- Vertical separator already from panel border
    local cy = y + 4

    -- ── Level badge ──
    local roomNames  = {caesar="NIVEAU 1 — CESAR", vigenere="NIVEAU 2 — VIGENERE", vernam="NIVEAU 3 — VERNAM"}
    local roomCols   = {caesar=R.C.green, vigenere=R.C.cyan, vernam=R.C.red}
    local col = roomCols[gameState.currentRoom] or R.C.green
    R.panel(x+6, cy, w-12, 20, {col[1],col[2],col[3],0.08}, {col[1],col[2],col[3],0.4})
    love.graphics.setColor(col[1],col[2],col[3], R.blinkAlpha(t,1.2))
    love.graphics.circle("fill", x+14, cy+10, 3)
    love.graphics.setFont(R.font_tiny)
    R.setColor(col)
    love.graphics.print(roomNames[gameState.currentRoom] or "", x+22, cy+5)
    cy = cy + 26

    R.separator(x+6, cy, w-12)
    cy = cy + 6

    -- ── Cipher text ──
    love.graphics.setFont(R.font_tiny)
    R.setColor(R.C.amber_dim)
    love.graphics.print("TEXTE INTERCEPTE", x+8, cy)
    cy = cy + 12

    local cipherTexts = {
        caesar   = "XLI GEWEIV QIXLSH\nMW FEWIH SR E WLMJX",
        vigenere = "LXFOPVEFRNHR",
        vernam   = "01001000 01100101\n01101100 01101100\n01101111 (XOR)"
    }
    local ct = cipherTexts[gameState.currentRoom] or ""
    R.panel(x+6, cy, w-12, 44, R.C.bg_term, R.C.border)
    love.graphics.setFont(R.font_tiny)
    R.setColor(R.C.amber)
    love.graphics.printf(ct, x+10, cy+4, w-20, "left")
    cy = cy + 50

    R.separator(x+6, cy, w-12)
    cy = cy + 6

    -- ── Hints ──
    love.graphics.setFont(R.font_tiny)
    R.setColor(R.C.green_dim)
    love.graphics.print("INDICES", x+8, cy)
    cy = cy + 12

    if #gameState.hints == 0 then
        R.panel(x+6, cy, w-12, 18, nil, nil)
        love.graphics.setFont(R.font_tiny)
        R.setColor(R.C.green_dim, 0.5)
        love.graphics.printf("Interagissez avec les objets...", x+8, cy+2, w-16, "left")
        cy = cy + 22
    else
        for _, hint in ipairs(gameState.hints) do
            local hw = w - 12
            R.panel(x+6, cy, hw, 2, nil, {R.C.amber[1],R.C.amber[2],R.C.amber[3],0.2})
            love.graphics.setFont(R.font_tiny)
            love.graphics.setColor(R.C.amber[1],R.C.amber[2],R.C.amber[3], 0.85)
            love.graphics.printf(hint, x+8, cy+3, hw-4, "left")
            -- estimate height
            local _, lines = R.font_tiny:getWrap(hint, hw-4)
            cy = cy + 8 + #lines * 11
            if cy > y + h - 160 then break end
        end
    end

    R.separator(x+6, cy, w-12)
    cy = cy + 6

    -- ── Terminal section ──
    UIManager.drawTerminalPanel(terminal, x, cy, w, y+h - cy - 4, t)
end

-- ═══════════════════════════════════════════
--  TERMINAL PANEL (embedded in side panel)
-- ═══════════════════════════════════════════
function UIManager.drawTerminalPanel(terminal, x, y, w, h, t)
    if h < 80 then return end

    love.graphics.setFont(R.font_tiny)
    R.setColor(R.C.green_dim)
    love.graphics.print("TERMINAL DE DECHIFFREMENT", x+8, y)
    y = y + 12

    local th = h - 36  -- output area height
    R.panel(x+6, y, w-12, th, R.C.bg_term, R.C.border)

    -- Output lines (show last N that fit)
    local lineH = 12
    local maxLines = math.floor((th - 6) / lineH)
    love.graphics.setScissor(x+6, y, w-12, th)

    local startIdx = math.max(1, #terminal.outputLog - maxLines + 1)
    for i = startIdx, #terminal.outputLog do
        local entry = terminal.outputLog[i]
        local ey = y + 3 + (i - startIdx) * lineH
        local col
        if entry.kind == "prompt" then col = R.C.green
        elseif entry.kind == "result" then col = R.C.cyan
        elseif entry.kind == "error"  then col = R.C.red
        elseif entry.kind == "hint"   then col = R.C.amber
        else col = {R.C.green[1],R.C.green[2],R.C.green[3],0.45} end
        love.graphics.setColor(col[1],col[2],col[3], col[4] or 1)
        love.graphics.print(entry.text, x+9, ey)
    end
    love.graphics.setScissor()

    -- Input row
    local iy = y + th + 2
    R.panel(x+6, iy, w-12, 22, R.C.bg_term, R.C.border)

    -- Prompt char blink
    local pa = R.blinkAlpha(t, 2)
    love.graphics.setColor(R.C.green[1],R.C.green[2],R.C.green[3], pa)
    love.graphics.print(">", x+9, iy+4)

    -- Input text
    R.setColor(R.C.green)
    local displayInput = terminal.inputBuffer
    -- cursor blink
    if math.floor(t*2) % 2 == 0 then displayInput = displayInput .. "_" end
    love.graphics.print(displayInput, x+18, iy+4)
end

-- ═══════════════════════════════════════════
--  DIALOG / MODAL  (object interaction)
-- ═══════════════════════════════════════════
function UIManager.drawDialog(dialog, t)
    if not dialog or not dialog.visible then return end

    local dw, dh = 340, 200
    local dx = (W - dw) / 2
    local dy = (H - dh) / 2

    -- Dim overlay
    love.graphics.setColor(0,0,0,0.75)
    love.graphics.rectangle("fill", 0,0,W,H)

    -- Box
    R.panel(dx, dy, dw, dh, R.C.bg_panel, R.C.border_hi)
    R.corners(dx, dy, dw, dh, R.C.green, 12)

    -- Header
    R.panel(dx, dy, dw, 28, {R.C.green[1],R.C.green[2],R.C.green[3],0.12}, nil)
    R.separator(dx, dy+28, dw)
    love.graphics.setFont(R.font_small)
    R.setColor(R.C.green)
    love.graphics.printf(dialog.title or "OBJET", dx+8, dy+7, dw-16, "left")

    -- Body text (word-wrapped)
    love.graphics.setFont(R.font_tiny)
    R.setColor(R.C.green_dim, 0.9)
    love.graphics.printf(dialog.body or "", dx+10, dy+36, dw-20, "left")

    -- Buttons
    local btnY = dy + dh - 34
    R.separator(dx, btnY-4, dw)

    -- [E] Collecter  [ESC] Fermer
    R.panel(dx+10, btnY, 100, 22, {R.C.amber[1],R.C.amber[2],R.C.amber[3],0.1}, R.C.amber)
    love.graphics.setFont(R.font_tiny)
    R.setColor(R.C.amber)
    love.graphics.printf("[E] COLLECTER", dx+10, btnY+5, 100, "center")

    R.panel(dx+120, btnY, 100, 22, nil, R.C.border_hi)
    R.setColor(R.C.green_dim)
    love.graphics.printf("[ESC] FERMER", dx+120, btnY+5, 100, "center")
end

-- ═══════════════════════════════════════════
--  KEYPAD MODAL
-- ═══════════════════════════════════════════
function UIManager.drawKeypad(keypad, t)
    if not keypad or not keypad.visible then return end

    local kw, kh = 260, 320
    local kx = (W - kw) / 2
    local ky = (H - kh) / 2

    love.graphics.setColor(0,0,0,0.80)
    love.graphics.rectangle("fill", 0,0,W,H)

    R.panel(kx, ky, kw, kh, R.C.bg_panel, R.C.border_hi)
    R.corners(kx, ky, kw, kh, R.C.red, 12)

    -- Header
    R.panel(kx, ky, kw, 28, {R.C.red[1],R.C.red[2],R.C.red[3],0.1}, nil)
    R.separator(kx, ky+28, kw)
    love.graphics.setFont(R.font_small)
    R.setColor(R.C.red)
    love.graphics.printf("PORTE VERROUILLEE", kx+8, ky+7, kw-16, "center")

    -- Display
    local dispBuf = keypad.buffer:sub(1,4)
    while #dispBuf < 4 do dispBuf = dispBuf .. "_" end
    R.panel(kx+10, ky+36, kw-20, 36, R.C.bg_term, R.C.border)
    love.graphics.setFont(R.font_big)
    R.setColor(R.C.amber)
    love.graphics.printf(dispBuf, kx+10, ky+45, kw-20, "center")

    -- Wrong flash
    if keypad.wrongFlash and keypad.wrongFlash > 0 then
        love.graphics.setColor(1,0.1,0.2, keypad.wrongFlash * 0.4)
        love.graphics.rectangle("fill", kx+10, ky+36, kw-20, 36)
    end

    -- Numeric grid (3 cols)
    local btns = {"1","2","3","4","5","6","7","8","9","<","0","OK"}
    local bw, bh = (kw-28)/3, 36
    for i, lbl in ipairs(btns) do
        local bx = kx+10 + ((i-1)%3) * (bw+4)
        local by = ky+82 + math.floor((i-1)/3) * (bh+4)
        local isOk  = (lbl == "OK")
        local isDel = (lbl == "<")
        local bc = isOk and R.C.green or (isDel and R.C.red or R.C.green_dim)
        R.panel(bx, by, bw, bh,
            {bc[1],bc[2],bc[3], isOk and 0.15 or 0.05},
            {bc[1],bc[2],bc[3], 0.5})
        love.graphics.setFont(R.font_normal)
        R.setColor(bc)
        love.graphics.printf(lbl, bx, by + bh/2 - 7, bw, "center")
    end

    love.graphics.setFont(R.font_tiny)
    R.setColor(R.C.green_dim, 0.6)
    love.graphics.printf("[ESC] Annuler   [Entree] Valider", kx, ky+kh-18, kw, "center")
end

-- ═══════════════════════════════════════════
--  MENU SCREEN
-- ═══════════════════════════════════════════
function UIManager.drawMenu(t)
    local W2 = W/2
    -- Background
    R.setColor(R.C.bg_deep)
    love.graphics.rectangle("fill", 0,0,W,H)
    R.drawGrid(0,0,W,H, 60, R.C.green, 0.04)

    -- Animated corner brackets
    R.corners(10, 10, W-20, H-20, R.C.border, 20)

    -- Subtitle
    love.graphics.setFont(R.font_small)
    R.setColor(R.C.green_dim)
    love.graphics.printf("// SERIOUS GAME  ·  CYBERSECURITE //", 0, H/2 - 110, W, "center")

    -- Title glitch effect
    local titles = {"THE DECRYPTOR'S CELL", "THE D3CRYPTOR'S C3LL", "THE DECRYPTOR'S CELL"}
    local ti = titles[ (math.floor(t*0.3) % 3) + 1 ]
    if math.fmod(t, 7) < 0.08 then ti = "TH3 D3CRYPT0R'S C3LL" end

    love.graphics.setFont(R.font_title)
    -- glow
    love.graphics.setColor(R.C.green[1],R.C.green[2],R.C.green[3], 0.2)
    for dx=-3,3 do for dy=-3,3 do
        love.graphics.printf(ti, dx, H/2 - 68 + dy, W, "center")
    end end
    R.setColor(R.C.green)
    love.graphics.printf(ti, 0, H/2 - 68, W, "center")

    -- Tagline
    love.graphics.setFont(R.font_small)
    R.setColor(R.C.amber_dim)
    love.graphics.printf("— Dechiffrez. Survivez. Evadez-vous. —", 0, H/2 - 18, W, "center")

    -- Buttons
    local btns = {
        {label="[ENTREE]  NOUVELLE PARTIE", col=R.C.green,     y=H/2+20},
        {label="[C]       CONTROLES",       col=R.C.green_dim, y=H/2+52},
        {label="[A]       A PROPOS",         col=R.C.green_dim, y=H/2+80},
    }
    for _, b in ipairs(btns) do
        local bw = 280
        local bx = W2 - bw/2
        R.panel(bx, b.y, bw, 24, {b.col[1],b.col[2],b.col[3],0.08}, {b.col[1],b.col[2],b.col[3],0.4})
        love.graphics.setFont(R.font_small)
        R.setColor(b.col)
        love.graphics.printf(b.label, bx, b.y+5, bw, "center")
    end

    -- Blinking bottom line
    love.graphics.setFont(R.font_tiny)
    love.graphics.setColor(R.C.green[1],R.C.green[2],R.C.green[3], R.blinkAlpha(t, 1.5))
    love.graphics.printf("[ SYSTEME EN LIGNE — BUILD 1.0.0 ]", 0, H-24, W, "center")
end

-- ═══════════════════════════════════════════
--  VICTORY SCREEN
-- ═══════════════════════════════════════════
function UIManager.drawVictory(t, elapsed)
    R.setColor(R.C.bg_deep)
    love.graphics.rectangle("fill",0,0,W,H)

    -- Pulsing glow
    local pulse = 0.5 + 0.5*math.abs(math.sin(t*1.5))
    love.graphics.setColor(R.C.green[1],R.C.green[2],R.C.green[3], 0.06*pulse)
    love.graphics.circle("fill", W/2, H/2, 380)

    R.corners(10,10,W-20,H-20, R.C.green, 20)

    love.graphics.setFont(R.font_huge)
    R.glowText("LIBERTE", 0, H/2-120, R.C.green, R.font_huge)
    -- (centre manually)
    love.graphics.setFont(R.font_huge)
    local tw = R.font_huge:getWidth("LIBERTE")
    R.glowText("LIBERTE", (W-tw)/2, H/2-120, R.C.green, R.font_huge)

    love.graphics.setFont(R.font_small)
    R.setColor(R.C.green_dim)
    love.graphics.printf("// CELLULE DEVERROUILLEE — MISSION ACCOMPLIE //", 0, H/2-30, W, "center")

    love.graphics.setFont(R.font_big)
    R.setColor(R.C.amber)
    love.graphics.printf("CODE FINAL : FREEDOM", 0, H/2+10, W, "center")

    local m = math.floor(elapsed/60)
    local s = elapsed % 60
    love.graphics.setFont(R.font_small)
    R.setColor(R.C.green_dim)
    love.graphics.printf(string.format("Temps total : %02d:%02d", m, s), 0, H/2+50, W, "center")

    love.graphics.setFont(R.font_small)
    R.panel(W/2-90, H/2+90, 180, 26, {R.C.green[1],R.C.green[2],R.C.green[3],0.1}, R.C.green)
    R.setColor(R.C.green)
    love.graphics.printf("[ESC] MENU PRINCIPAL", W/2-90, H/2+96, 180, "center")
end

-- ═══════════════════════════════════════════
--  CONTROLS / ABOUT overlay
-- ═══════════════════════════════════════════
function UIManager.drawOverlay(overlay)
    if not overlay or not overlay.visible then return end

    local ow, oh = 400, 280
    local ox = (W-ow)/2
    local oy = (H-oh)/2

    love.graphics.setColor(0,0,0,0.80)
    love.graphics.rectangle("fill",0,0,W,H)
    R.panel(ox, oy, ow, oh, R.C.bg_panel, R.C.border_hi)
    R.corners(ox,oy,ow,oh, R.C.green, 12)

    R.panel(ox, oy, ow, 28, {R.C.green[1],R.C.green[2],R.C.green[3],0.1}, nil)
    R.separator(ox, oy+28, ow)
    love.graphics.setFont(R.font_normal)
    R.setColor(R.C.green)
    love.graphics.printf(overlay.title, ox, oy+7, ow, "center")

    love.graphics.setFont(R.font_tiny)
    R.setColor(R.C.green_dim, 0.9)
    love.graphics.printf(overlay.body, ox+14, oy+38, ow-28, "left")

    R.separator(ox, oy+oh-28, ow)
    love.graphics.setFont(R.font_tiny)
    R.setColor(R.C.green_dim)
    love.graphics.printf("[ESC]  Fermer", ox, oy+oh-18, ow, "center")
end

-- ── Getters for layout constants ─────────────
UIManager.PANEL_X  = PANEL_X
UIManager.PANEL_W  = PANEL_W
UIManager.HUD_H    = HUD_H
UIManager.ROOM_W   = ROOM_W
UIManager.ROOM_H   = ROOM_H

return UIManager
