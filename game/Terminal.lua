-- ════════════════════════════════════════════
--  Terminal.lua  —  Multi-stage support
-- ════════════════════════════════════════════
local CryptoEngine = require("systems.CryptoEngine")
local Terminal = {}

function Terminal:new(cipherText, algo, correctAnswer, doorCode)
    local t = {
        inputBuffer   = "",
        outputLog     = {},
        cipherText    = cipherText,
        algo          = algo,
        correctAnswer = correctAnswer,
        doorCode      = doorCode,
        isLocked      = false,
        isSolved      = false,

        -- Multi-stage support
        stage         = 0,        -- 0 = not started, 1/2/3 = stages, 4 = solved
        stageAnswers  = {},       -- stores each correct answer per stage
        stageSolved   = {false, false, false},
    }
    setmetatable(t, self)
    self.__index = self
    t:log("system", "// THE DECRYPTOR'S CELL v1.0")
    t:log("system", "// Module : " .. algo:upper())
    t:log("hint",   "// Tapez 'aide' pour de l'aide")
    t:log("",       "")
    return t
end

function Terminal:setStages(answers)
    -- answers = {2, 3, 4} for caesar room
    self.stageAnswers = answers
    self.stage = 1
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

    -- Commands
    if lower == "aide" or lower == "help" then
        if self.stage == 1 then
            self:log("hint", "  Observe ce qui est dans la salle...")
        elseif self.stage == 2 then
            self:log("hint", "  Compte les objets autour de toi.")
        elseif self.stage == 3 then
            self:log("hint", "  Ecoute attentivement la melodie.")
        elseif self.stage == 4 then
            self:log("hint", "  Tu as 3 fragments. Combine-les.")
        else
            self:log("hint", "  Entrez le decalage (ex: 4)")
        end
        return
    end

    if lower == "clear" or lower == "cls" then
        self.outputLog = {}
        return
    end

    -- Multi-stage mode
    if #self.stageAnswers > 0 then
        self:handleStageInput(raw)
        return
    end

    -- Legacy single-answer mode (used by other rooms)
    self:handleLegacyInput(raw)
end

function Terminal:handleStageInput(raw)
    local n = tonumber(raw)

    if self.stage == 1 then
        if n == self.stageAnswers[1] then
            self:log("result", "  [OK] Premier fragment trouve.")
            self:log("hint",   "  La cellule change... reste attentif.")
            self.stageSolved[1] = true
            self.stage = 2
            if self.onStageComplete then self.onStageComplete(1) end
        else
            self:log("error",  "  [X]  Ce n'est pas le bon nombre.")
        end

    elseif self.stage == 2 then
        if n == self.stageAnswers[2] then
            self:log("result", "  [OK] Deuxieme fragment trouve.")
            self:log("hint",   "  Le silence tombe... ecoute.")
            self.stageSolved[2] = true
            self.stage = 3
            if self.onStageComplete then self.onStageComplete(2) end
        else
            self:log("error",  "  [X]  Observe encore la salle.")
        end

    elseif self.stage == 3 then
        if n == self.stageAnswers[3] then
            self:log("result", "  [OK] Troisieme fragment trouve.")
            self:log("hint",   "  Tu as les 3 nombres. Additionne-les.")
            self.stageSolved[3] = true
            self.stage = 4
            if self.onStageComplete then self.onStageComplete(3) end
        else
            self:log("error",  "  [X]  Compte les notes de la melodie.")
        end

    elseif self.stage == 4 then
        if n == tonumber(self.correctAnswer) then
            self:log("result", "  [OK] DECHIFFREMENT COMPLET !")
            self:log("hint",   "  Code porte : " .. self.doorCode)
            self.isSolved = true
            if self.onStageComplete then self.onStageComplete(4) end
        else
            self:log("error",  "  [X]  Additionne les 3 fragments...")
        end
    end
end

function Terminal:handleLegacyInput(raw)
    local lower = raw:lower()
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