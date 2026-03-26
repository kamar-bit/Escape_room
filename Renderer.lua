-- ════════════════════════════════════════════
--  Renderer.lua  — palette, fonts, CRT, helpers
--  Compatible LÖVE 11.x / LuaJIT
-- ════════════════════════════════════════════
local Renderer = {}

-- ── Palette ──────────────────────────────────
Renderer.C = {
    bg_deep    = {0.02, 0.04, 0.06, 1},
    bg_cell    = {0.04, 0.08, 0.12, 1},
    bg_panel   = {0.05, 0.12, 0.18, 1},
    bg_term    = {0.02, 0.05, 0.08, 1},
    green      = {0.00, 1.00, 0.53, 1},
    green_dim  = {0.00, 0.67, 0.33, 1},
    green_glow = {0.00, 1.00, 0.53, 0.12},
    amber      = {1.00, 0.72, 0.00, 1},
    amber_dim  = {0.63, 0.46, 0.00, 1},
    red        = {1.00, 0.20, 0.33, 1},
    cyan       = {0.00, 0.83, 1.00, 1},
    cyan_dim   = {0.00, 0.40, 0.50, 1},
    white      = {1.00, 1.00, 1.00, 1},
    border     = {0.00, 1.00, 0.53, 0.25},
    border_hi  = {0.00, 1.00, 0.53, 0.60},
    black      = {0.00, 0.00, 0.00, 1},
}

Renderer.ROOM_COLOR = {
    caesar   = {0.00, 1.00, 0.53, 1},
    vigenere = {0.00, 0.83, 1.00, 1},
    vernam   = {1.00, 0.20, 0.33, 1},
}

-- ── Fonts ─────────────────────────────────────
function Renderer.loadFonts()
    Renderer.font_tiny   = love.graphics.newFont(9)
    Renderer.font_small  = love.graphics.newFont(11)
    Renderer.font_normal = love.graphics.newFont(13)
    Renderer.font_big    = love.graphics.newFont(18)
    Renderer.font_title  = love.graphics.newFont(32)
    Renderer.font_huge   = love.graphics.newFont(52)
    love.graphics.setFont(Renderer.font_normal)
end

-- ── Colour helpers ────────────────────────────
function Renderer.setColor(c, alpha)
    if alpha then
        love.graphics.setColor(c[1], c[2], c[3], alpha)
    else
        love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
    end
end

function Renderer.resetColor()
    love.graphics.setColor(1, 1, 1, 1)
end

-- ── Primitives ────────────────────────────────
function Renderer.rect(mode, x, y, w, h, rx, ry)
    love.graphics.rectangle(mode, x, y, w, h, rx or 0, ry or 0)
end

function Renderer.panel(x, y, w, h, fillColor, borderColor, rx)
    if fillColor then
        Renderer.setColor(fillColor)
        Renderer.rect("fill", x, y, w, h, rx)
    end
    if borderColor then
        Renderer.setColor(borderColor)
        Renderer.rect("line", x, y, w, h, rx)
    end
end

function Renderer.corners(x, y, w, h, color, size)
    size = size or 10
    Renderer.setColor(color or Renderer.C.border_hi)
    love.graphics.line(x,       y,        x+size, y)
    love.graphics.line(x,       y,        x,      y+size)
    love.graphics.line(x+w,     y,        x+w-size, y)
    love.graphics.line(x+w,     y,        x+w,    y+size)
    love.graphics.line(x,       y+h,      x+size, y+h)
    love.graphics.line(x,       y+h,      x,      y+h-size)
    love.graphics.line(x+w,     y+h,      x+w-size, y+h)
    love.graphics.line(x+w,     y+h,      x+w,    y+h-size)
end

-- ── Text helpers ──────────────────────────────
function Renderer.text(str, x, y, color, font)
    love.graphics.setFont(font or Renderer.font_normal)
    Renderer.setColor(color or Renderer.C.green)
    love.graphics.print(str, x, y)
end

function Renderer.glowText(str, x, y, color, font)
    font = font or Renderer.font_normal
    love.graphics.setFont(font)
    love.graphics.setColor(color[1], color[2], color[3], 0.2)
    for dx = -2, 2 do
        for dy = -2, 2 do
            love.graphics.print(str, x+dx, y+dy)
        end
    end
    Renderer.setColor(color)
    love.graphics.print(str, x, y)
end

function Renderer.textCenter(str, y, color, font)
    font = font or Renderer.font_normal
    love.graphics.setFont(font)
    local w = font:getWidth(str)
    local sw = love.graphics.getWidth()
    Renderer.setColor(color or Renderer.C.green)
    love.graphics.print(str, (sw - w) / 2, y)
end

-- ── CRT effects (dessinés chaque frame, sans Canvas ni Mesh) ──
function Renderer.initCRT()
    -- Rien à précalculer — on dessine directement dans drawCRT()
end

function Renderer.drawCRT()
    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()

    -- Scanlines : lignes horizontales semi-transparentes toutes les 3px
    love.graphics.setLineWidth(1)
    love.graphics.setColor(0, 0, 0, 0.08)
    for y = 0, H, 3 do
        love.graphics.line(0, y, W, y)
    end

    -- Vignette : 4 rectangles sombres sur les bords (simple et robuste)
    local vsize = 80
    -- Haut
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", 0, 0, W, vsize)
    -- Bas
    love.graphics.rectangle("fill", 0, H - vsize, W, vsize)
    -- Gauche
    love.graphics.rectangle("fill", 0, 0, vsize, H)
    -- Droite
    love.graphics.rectangle("fill", W - vsize, 0, vsize, H)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

-- ── Grid background ───────────────────────────
function Renderer.drawGrid(x, y, w, h, step, color, alpha)
    step = step or 32
    Renderer.setColor(color or Renderer.C.green, alpha or 0.04)
    love.graphics.setScissor(x, y, w, h)
    love.graphics.setLineWidth(1)
    for gx = x, x + w, step do
        love.graphics.line(gx, y, gx, y + h)
    end
    for gy = y, y + h, step do
        love.graphics.line(x, gy, x + w, gy)
    end
    love.graphics.setScissor()
end

-- ── Blink helper ─────────────────────────────
function Renderer.blinkAlpha(t, speed)
    speed = speed or 2
    return 0.4 + 0.6 * math.abs(math.sin(t * speed))
end

-- ── Separator ────────────────────────────────
function Renderer.separator(x, y, w, color)
    Renderer.setColor(color or Renderer.C.border)
    love.graphics.line(x, y, x + w, y)
end

return Renderer
