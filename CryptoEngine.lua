-- ════════════════════════════════════════════
--  CryptoEngine.lua  (Static utility class)
--  Compatible LuaJIT / LÖVE (pas de ~ bitwise)
-- ════════════════════════════════════════════
local CryptoEngine = {}

-- ── César ─────────────────────────────────────
function CryptoEngine.caesarDecrypt(text, shift)
    shift = shift % 26
    local result = ""
    for i = 1, #text do
        local c = text:sub(i,i)
        if c:match("%u") then
            local v = (c:byte() - 65 - shift + 260) % 26
            result = result .. string.char(v + 65)
        elseif c:match("%l") then
            local v = (c:byte() - 97 - shift + 260) % 26
            result = result .. string.char(v + 97)
        else
            result = result .. c
        end
    end
    return result
end

function CryptoEngine.caesarEncrypt(text, shift)
    return CryptoEngine.caesarDecrypt(text, 26 - (shift % 26))
end

-- ── Vigenère ──────────────────────────────────
function CryptoEngine.vigenereDecrypt(text, key)
    key = key:upper()
    local result = ""
    local ki = 1
    for i = 1, #text do
        local c = text:sub(i,i):upper()
        if c:match("%u") then
            local k = key:sub(((ki-1) % #key)+1, ((ki-1) % #key)+1):byte() - 65
            local v = (c:byte() - 65 - k + 26) % 26
            result = result .. string.char(v + 65)
            ki = ki + 1
        else
            result = result .. text:sub(i,i)
        end
    end
    return result
end

function CryptoEngine.vigenereEncrypt(text, key)
    key = key:upper()
    local result = ""
    local ki = 1
    for i = 1, #text do
        local c = text:sub(i,i):upper()
        if c:match("%u") then
            local k = key:sub(((ki-1) % #key)+1, ((ki-1) % #key)+1):byte() - 65
            local v = (c:byte() - 65 + k) % 26
            result = result .. string.char(v + 65)
            ki = ki + 1
        else
            result = result .. text:sub(i,i)
        end
    end
    return result
end

-- ── Vernam / XOR ──────────────────────────────
-- LuaJIT n'a pas l'opérateur ~ de Lua 5.3
-- On utilise bit.bxor() fourni par LÖVE / LuaJIT
function CryptoEngine.vernamXORnum(text, keyByte)
    local result = ""
    keyByte = math.floor(keyByte)
    for i = 1, #text do
        local b = text:sub(i,i):byte()
        result = result .. string.char(bit.bxor(b, keyByte))
    end
    return result
end

return CryptoEngine
