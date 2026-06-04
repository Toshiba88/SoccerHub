--// Soccer Hub - main_raw.lua
--// Loader raw GitHub pour la version modulaire.
--// Fix : cache-buster sur chaque module pour éviter l'ancien cache raw GitHub.
--// Restore : pastilles de couleur dans le statut des modules.
--// Add : onglet Shop via module shop_opener.lua.

local BASE = "https://raw.githubusercontent.com/Toshiba88/SoccerHub/main/"
local CACHE_BUSTER = tostring(os.time()) .. "_" .. tostring(math.random(100000, 999999))

local ModuleStatus = {}
local ModuleStatusOrder = {}

local function EscapeLuaString(value)
    value = tostring(value or "")
    value = value:gsub("\\", "\\\\")
    value = value:gsub("\n", "\\n")
    value = value:gsub("\r", "\\r")
    value = value:gsub('"', '\\"')
    return value
end

local function SetModuleStatus(name, ok, detail)
    if ModuleStatus[name] == nil then
        table.insert(ModuleStatusOrder, name)
    end

    ModuleStatus[name] = {
        ok = ok == true,
        detail = tostring(detail or (ok and "OK" or "ERREUR"))
    }
end

local function ValidateModule(moduleTable, expectedFields)
    if type(moduleTable) ~= "table" then
        return false, "retour invalide : " .. typeof(moduleTable)
    end

    for _, fieldName in ipairs(expectedFields or {}) do
        if type(moduleTable[fieldName]) ~= "string" then
            return false, "champ manquant/invalide : " .. tostring(fieldName)
        end
    end

    return true, "OK"
end

local function Get(name, path, expectedFields)
    local src
    local url = BASE .. path .. "?v=" .. CACHE_BUSTER

    local okHttp, httpErr = pcall(function()
        src = game:HttpGet(url)
    end)

    if not okHttp or type(src) ~= "string" or src == "" then
        SetModuleStatus(name, false, "HttpGet fail : " .. tostring(httpErr))
        return {}
    end

    local fn, compileErr = loadstring(src)

    if not fn then
        SetModuleStatus(name, false, "compile fail : " .. tostring(compileErr))
        return {}
    end

    local okRun, result = pcall(fn)

    if not okRun then
        SetModuleStatus(name, false, "run fail : " .. tostring(result))
        return {}
    end

    local okValidate, validateErr = ValidateModule(result, expectedFields)

    if not okValidate then
        SetModuleStatus(name, false, validateErr)
        return result or {}
    end

    SetModuleStatus(name, true, "OK")
    return result
end

local Core = Get("core", "modules/core.lua", {"logic", "startup"})
local Remotes = Get("remotes", "modules/remotes.lua", {"logic"})
local AutoBuy = Get("autobuy", "modules/autobuy.lua", {"logic", "restock", "ui"})
local AutoCollect = Get("autocollect", "modules/autocollect.lua", {"logic", "ui"})
local SpinWheel = Get("spinwheel", "modules/spinwheel.lua", {"logic", "ui"})
local AntiAfk = Get("antiafk", "modules/antiafk.lua", {"logic", "ui"})
local Tournament = Get("tournament", "modules/tournament.lua", {"logic"})
local Index = Get("index", "modules/index.lua", {"logic"})
local UI = Get("ui", "modules/ui.lua", {"logic"})
local Config = Get("config", "modules/config.lua", {"ui"})
local Console = Get("console", "modules/console.lua", {"ui"})
local ShopOpener = Get("shop_opener", "modules/shop_opener.lua", {})

local function Chunk(value)
    if type(value) == "string" then
        return value
    end

    return ""
end

local function BuildModuleStatusChunk()
    local out = {}

    table.insert(out, "--// MODULE STATUS UI - injecté par main_raw.lua")
    table.insert(out, "local __SoccerHubModuleStatus = {")

    for _, name in ipairs(ModuleStatusOrder) do
        local data = ModuleStatus[name]
        table.insert(out, "    {name=\"" .. EscapeLuaString(name) .. "\", ok=" .. tostring(data.ok == true) .. ", detail=\"" .. EscapeLuaString(data.detail) .. "\"},")
    end

    table.insert(out, "}")
    table.insert(out, [[
local ModuleStatusParagraph

local function BuildModuleStatusContent()
    local lines = {}
    local okCount = 0

    for _, moduleData in ipairs(__SoccerHubModuleStatus) do
        if moduleData.ok then
            okCount += 1
            table.insert(lines, "🟢   " .. tostring(moduleData.name))
        else
            table.insert(lines, "🔴   " .. tostring(moduleData.name) .. " | " .. tostring(moduleData.detail))
        end
    end

    table.insert(lines, 1, "")
    table.insert(lines, 2, "CHARGÉS : " .. tostring(okCount) .. "/" .. tostring(#__SoccerHubModuleStatus))
    table.insert(lines, 3, "")

    return table.concat(lines, "\n")
end

local function UpdateModuleStatusParagraph()
    if ModuleStatusParagraph and SetParagraph then
        SetParagraph(ModuleStatusParagraph, "MODULES", BuildModuleStatusContent())
    end
end

if Tabs and Tabs.Accueil then
    ModuleStatusParagraph = Tabs.Accueil:AddParagraph({
        Title = "MODULES",
        Content = BuildModuleStatusContent()
    })
end

pcall(function()
    local loaded = 0
    for _, moduleData in ipairs(__SoccerHubModuleStatus) do
        if moduleData.ok then
            loaded += 1
        end
    end

    Log("Modules chargés : " .. tostring(loaded) .. "/" .. tostring(#__SoccerHubModuleStatus), "[MODULES]")
end)
]])

    return table.concat(out, "\n")
end

local function BuildShopOpenerChunk()
    local url = BASE .. "modules/shop_opener.lua?v=" .. CACHE_BUSTER

    return [[
--// SHOP OPENER UI - injecté par main_raw.lua
pcall(function()
    if Tabs and Window then
        Tabs.__Window = Window
        getgenv().SoccerHubWindow = Window
        getgenv().SoccerHubTabs = Tabs
        getgenv().SoccerHubFluent = Fluent
    end
end)

task.spawn(function()
    local shopModuleUrl = "]] .. EscapeLuaString(url) .. [["
    local shopSource

    local okHttp, httpErr = pcall(function()
        shopSource = game:HttpGet(shopModuleUrl)
    end)

    if not okHttp or type(shopSource) ~= "string" or shopSource == "" then
        if Log then
            Log("Shop opener HttpGet fail : " .. tostring(httpErr), "[SHOP]")
        end
        return
    end

    local fn, compileErr = loadstring(shopSource)
    if not fn then
        if Log then
            Log("Shop opener compile fail : " .. tostring(compileErr), "[SHOP]")
        end
        return
    end

    local okRun, ShopOpenerModule = pcall(fn)
    if not okRun or type(ShopOpenerModule) ~= "table" then
        if Log then
            Log("Shop opener run fail : " .. tostring(ShopOpenerModule), "[SHOP]")
        end
        return
    end

    if type(ShopOpenerModule.Mount) ~= "function" then
        if Log then
            Log("Shop opener Mount introuvable", "[SHOP]")
        end
        return
    end

    local okMount, mountResult = ShopOpenerModule.Mount(Tabs, Fluent)

    if Log then
        Log("Onglet Shop : " .. tostring(okMount) .. " | " .. tostring(mountResult), "[SHOP]")
    end
end)
]]
end

local source = table.concat({
    Chunk(Core.logic),
    Chunk(Remotes.logic),
    Chunk(AutoBuy.logic),
    Chunk(AutoCollect.logic),
    Chunk(SpinWheel.logic),
    Chunk(AntiAfk.logic),
    Chunk(AutoBuy.restock),
    Chunk(Tournament.logic),
    Chunk(Index.logic),
    Chunk(UI.logic),
    BuildModuleStatusChunk(),
    Chunk(AutoBuy.ui),
    Chunk(AutoCollect.ui),
    Chunk(SpinWheel.ui),
    Chunk(AntiAfk.ui),
    Chunk(Config.ui),
    Chunk(Console.ui),
    BuildShopOpenerChunk(),
    Chunk(Core.startup),
}, "\n\n")

local fn, err = loadstring(source)

if not fn then
    local report = {}

    table.insert(report, "Erreur compilation SoccerHub modulaire : " .. tostring(err))
    table.insert(report, "")
    table.insert(report, "Statut modules :")

    for _, name in ipairs(ModuleStatusOrder) do
        local data = ModuleStatus[name]
        table.insert(report, (data.ok and "OK  " or "FAIL ") .. name .. " | " .. tostring(data.detail))
    end

    error(table.concat(report, "\n"))
end

return fn()
