--//====================================================
--// Soccer Hub - main.lua
--// Recompose le script original depuis les modules.
--// Objectif : fichier principal court, aucune fonction supprimée.
--//====================================================

local modules = script:WaitForChild("modules")

local function ReadModule(name)
    local ok, result = pcall(function()
        return require(modules:WaitForChild(name))
    end)

    if not ok then
        error("Erreur require module " .. tostring(name) .. " : " .. tostring(result))
    end

    if type(result) ~= "table" then
        error("Module " .. tostring(name) .. " doit retourner une table de chunks.")
    end

    return result
end

local Core = ReadModule("core")
local Remotes = ReadModule("remotes")
local AutoBuy = ReadModule("autobuy")
local AutoCollect = ReadModule("autocollect")
local SpinWheel = ReadModule("spinwheel")
local AntiAfk = ReadModule("antiafk")
local Tournament = ReadModule("tournament")
local Index = ReadModule("index")
local UI = ReadModule("ui")
local Config = ReadModule("config")
local Console = ReadModule("console")

local chunks = {
    -- Ordre original exact du fichier v33
    Core.logic,
    Remotes.logic,
    AutoBuy.logic,
    AutoCollect.logic,
    SpinWheel.logic,
    AntiAfk.logic,
    AutoBuy.restock,
    Tournament.logic,
    Index.logic,
    UI.logic,
    AutoBuy.ui,
    AutoCollect.ui,
    SpinWheel.ui,
    AntiAfk.ui,
    Config.ui,
    Console.ui,
    Core.startup,
}

local source = table.concat(chunks, "\n\n")

local fn, compileErr = loadstring(source)
if not fn then
    error("Erreur compilation SoccerHub modulaire : " .. tostring(compileErr))
end

return fn()
