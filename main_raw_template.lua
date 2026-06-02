--// Soccer Hub - main_raw_template.lua
--// Version modèle si tu veux charger les fichiers depuis un hébergement raw.
--// Remplace BASE par ton URL raw qui contient le dossier modules/.

local BASE = "https://raw.githubusercontent.com/TON_USER/TON_REPO/main/"

local function Get(path)
    local src = game:HttpGet(BASE .. path)
    local fn, err = loadstring(src)
    if not fn then error(err) end
    return fn()
end

local Core = Get("modules/core.lua")
local Remotes = Get("modules/remotes.lua")
local AutoBuy = Get("modules/autobuy.lua")
local AutoCollect = Get("modules/autocollect.lua")
local SpinWheel = Get("modules/spinwheel.lua")
local AntiAfk = Get("modules/antiafk.lua")
local Tournament = Get("modules/tournament.lua")
local Index = Get("modules/index.lua")
local UI = Get("modules/ui.lua")
local Config = Get("modules/config.lua")
local Console = Get("modules/console.lua")

local source = table.concat({
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
}, "\n\n")

local fn, err = loadstring(source)
if not fn then error(err) end
return fn()
