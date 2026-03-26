-- ════════════════════════════════════════════
--  Terminal.lua
-- ════════════════════════════════════════════
local CryptoEngine = require("systems.CryptoEngine")
local Terminal = {}

function Terminal:new(cipherText, algo, correctAnswer, doorCode)
    local t = {
        inputBuffer  = "",
        outputLog    = {},
        cipherText   = cipherText,
        algo         = algo,
        correctAnswer= correctAnswer,
        doorCode     = doorCode,
        isLocked     = false,
        isSolved     = false,
    }
    setmetatable(t, self)
    self.__index = self
    t:log("system", "// THE DECRYPTOR'S CELL v1.0")
    t:log("system", "// Module : " .. algo:upper())
    t:log("hint",   "// Tapez 'aide' pour de l'aide")
    t:log("",       "")
    return t
end

function Terminal:log(kind, text)
    table.insert(self.outputLog, {kind=kind, text=text})
end

function Terminal:addInput(char)
    if self.isSolved then return end
    self.inputBuffer = self.inputBuffer .. char
end

function Terminal:backspace()
    if #self.inputBuffer > 0 then
        self.inputBuffer = self.inputBuffer:sub(1, -2)
    end
end

function Terminal:clear()
    self.inputBuffer = ""
end

function Terminal:validateInput()
    local raw = self.inputBuffer:match("^%s*(.-)%s*$")
    self.inputBuffer = ""
    if raw == "" then return end
    self:log("prompt", "> " .. raw)
    local lower = raw:lower()

    if lower == "aide" or lower == "help" then
        if self.algo == "caesar" then
            self:log("hint", "  Entrez le decalage (ex: 4)")
        elseif self.algo == "vigenere" then
            self:log("hint", "  Entrez le mot-cle (ex: LEMON)")
        else
            self:log("hint", "  xor [nombre] (ex: xor 42)")
        end
        return
    end
    if lower == "clear" or lower == "cls" then
        self.outputLog = {}
        return
    end

    if self.algo == "caesar" then
        local n = tonumber(raw)
        if n == nil then self:log("error","  ERREUR: nombre entier requis") return end
        local result = CryptoEngine.caesarDecrypt(self.cipherText, n)
        self:log("result", "  >> " .. result)
        if n == tonumber(self.correctAnswer) then
            self:log("result", "  [OK] Dechiffrement reussi !")
            self:log("hint",   "  Code porte : " .. self.doorCode)
            self.isSolved = true
        else
            self:log("error",  "  [X]  Decalage incorrect")
        end

    elseif self.algo == "vigenere" then
        local key = raw:match("^[Cc]le%s+(.+)$") or raw:match("^[Kk]ey%s+(.+)$") or raw
        if not key:match("^%a+$") then self:log("error","  ERREUR: lettres uniquement") return end
        local result = CryptoEngine.vigenereDecrypt(self.cipherText, key:upper())
        self:log("result", "  >> " .. result)
        if result:upper() == self.correctAnswer:upper() then
            self:log("result", "  [OK] Dechiffrement reussi !")
            self:log("hint",   "  Code porte : " .. self.doorCode)
            self.isSolved = true
        else
            self:log("error",  "  [X]  Cle incorrecte")
        end

    elseif self.algo == "vernam" then
        local numStr = raw:match("[Xx][Oo][Rr]%s+(%d+)") or raw:match("^(%d+)$")
        if not numStr then self:log("error","  Syntaxe: xor [nombre]") return end
        local keyByte = tonumber(numStr)
        if keyByte == tonumber(self.correctAnswer) then
            self:log("result", "  >> KEY")
            self:log("result", "  [OK] XOR reussi !")
            self:log("hint",   "  Code porte : " .. self.doorCode)
            self.isSolved = true
        else
            self:log("result", "  >> ???")
            self:log("error",  "  [X]  Cle XOR incorrecte")
        end
    end
end

return Terminal
