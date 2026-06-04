--// Soccer Hub - Shop Opener Module
--// Ouvre GemShop / Wish / CraftShop via vrais controllers/UIManager quand possible.
--// Ne force pas Visible=true pour ouvrir les shops.

local ShopOpener = {}

ShopOpener.Name = "ShopOpener"
ShopOpener.Version = "1.0.0"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer and LocalPlayer:WaitForChild("PlayerGui")

local Config = {
    ShopIds = {
        GemShop = {
            Display = "Gem Shop",
            UIIds = { "GemShop", "Gem Shop", "gemShop" },
            ControllerNames = { "GemShopController" },
            ControllerPaths = {
                "ReplicatedStorage.Source.Client.UI.GemShop.GemShopController",
            },
            GuiNames = { "GemShop" },
        },

        Wish = {
            Display = "Wish",
            UIIds = { "Gacha", "Wish", "gacha", "wish" },
            ControllerNames = { "GachaController" },
            ControllerPaths = {
                "ReplicatedStorage.Source.Client.UI.Gacha.GachaController",
            },
            GuiNames = { "Gacha", "Wish" },
        },

        CraftShop = {
            Display = "Craft Shop",
            UIIds = { "CraftShop", "Craft Shop", "craftShop" },
            ControllerNames = { "CraftShopController" },
            ControllerPaths = {
                "ReplicatedStorage.Source.Client.UI.CraftShop.CraftShopController",
            },
            GuiNames = { "CraftShop" },
        },
    }
}

local UiManagers = {}
local Controllers = {}
local LastLog = {}

local function addLog(tag, msg)
    local line = "[" .. os.date("%H:%M:%S") .. "] [" .. tostring(tag) .. "] " .. tostring(msg)
    table.insert(LastLog, line)
    while #LastLog > 120 do
        table.remove(LastLog, 1)
    end
    return line
end

function ShopOpener.GetLog()
    return table.concat(LastLog, "\n")
end

local function getPath(obj)
    if typeof(obj) ~= "Instance" then
        return tostring(obj)
    end

    local parts = {}
    local current = obj

    while current do
        table.insert(parts, 1, current.Name)
        current = current.Parent
    end

    return table.concat(parts, ".")
end

local function findModuleByPath(pathString)
    local parts = {}

    for part in string.gmatch(pathString, "[^%.]+") do
        table.insert(parts, part)
    end

    local current = game

    if parts[1] == "game" or parts[1] == "Game" then
        table.remove(parts, 1)
    end

    for i, name in ipairs(parts) do
        if i == 1 then
            local ok, service = pcall(function()
                return game:GetService(name)
            end)

            if ok and service then
                current = service
            else
                current = game:FindFirstChild(name)
            end
        else
            if not current then
                return nil
            end

            current = current:FindFirstChild(name)
        end
    end

    return current
end

local function getLoadedModulesSafe()
    if getloadedmodules then
        local ok, modules = pcall(getloadedmodules)
        if ok and typeof(modules) == "table" then
            return modules
        end
    end

    local modules = {}

    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("ModuleScript") then
            table.insert(modules, obj)
        end
    end

    return modules
end

local function requireModuleSafe(module)
    if typeof(module) ~= "Instance" or not module:IsA("ModuleScript") then
        return nil, "not modulescript"
    end

    local ok, result = pcall(require, module)
    if ok then
        return result, nil
    end

    return nil, tostring(result)
end

local function tryCallFunction(fn, owner, ...)
    if typeof(fn) ~= "function" then
        return false, "not function"
    end

    local args = { ... }

    local ok1, res1 = pcall(function()
        return fn(table.unpack(args))
    end)

    if ok1 then
        return true, res1
    end

    if owner ~= nil then
        local ok2, res2 = pcall(function()
            return fn(owner, table.unpack(args))
        end)

        if ok2 then
            return true, res2
        end

        return false, tostring(res1) .. " | self:" .. tostring(res2)
    end

    return false, tostring(res1)
end

local function looksLikeUiManager(tbl)
    if typeof(tbl) ~= "table" then
        return false
    end

    local hasOpen = typeof(rawget(tbl, "open")) == "function"
    local hasClose = typeof(rawget(tbl, "close")) == "function" or typeof(rawget(tbl, "closeCurrentUI")) == "function"
    local hasRegister = typeof(rawget(tbl, "register")) == "function"
    local hasCurrent = typeof(rawget(tbl, "getCurrentUI")) == "function"
    local hasCloseAll = typeof(rawget(tbl, "closeAll")) == "function"

    return hasOpen and hasClose and (hasRegister or hasCurrent or hasCloseAll)
end

function ShopOpener.RefreshRuntimeObjects()
    table.clear(UiManagers)
    table.clear(Controllers)

    if getgc then
        local ok, objects = pcall(getgc, true)
        if ok and typeof(objects) == "table" then
            for i, obj in ipairs(objects) do
                if looksLikeUiManager(obj) then
                    table.insert(UiManagers, {
                        Table = obj,
                        Index = i,
                    })
                end
            end
        end
    end

    local modules = getLoadedModulesSafe()

    for shopKey, data in pairs(Config.ShopIds) do
        Controllers[shopKey] = {}

        for _, pathString in ipairs(data.ControllerPaths) do
            local module = findModuleByPath(pathString)
            if module then
                local result = requireModuleSafe(module)
                if typeof(result) == "table" then
                    table.insert(Controllers[shopKey], {
                        Module = module,
                        Table = result,
                        Source = "require path",
                    })
                end
            end
        end

        for _, module in ipairs(modules) do
            if typeof(module) == "Instance" and module:IsA("ModuleScript") then
                for _, controllerName in ipairs(data.ControllerNames) do
                    if module.Name == controllerName then
                        local result = requireModuleSafe(module)
                        if typeof(result) == "table" then
                            table.insert(Controllers[shopKey], {
                                Module = module,
                                Table = result,
                                Source = "require loadedmodules",
                            })
                        end
                    end
                end
            end
        end
    end

    addLog("REFRESH", "UIManagers=" .. tostring(#UiManagers))
end

local function callUiManagerOpen(uiId)
    local success = false
    local errors = {}

    for _, entry in ipairs(UiManagers) do
        local manager = entry.Table
        local fn = rawget(manager, "open")

        if typeof(fn) == "function" then
            local ok, res = tryCallFunction(fn, manager, uiId)

            if ok then
                success = true
                addLog("OPEN_OK", "UIManager.open(" .. tostring(uiId) .. ") | gc#" .. tostring(entry.Index))
            else
                table.insert(errors, "gc#" .. tostring(entry.Index) .. "=" .. tostring(res))
            end
        end
    end

    if not success and #errors > 0 then
        addLog("OPEN_FAIL", "UIManager.open(" .. tostring(uiId) .. ") errors=" .. table.concat(errors, " || "))
    end

    return success
end

local function callControllerOpen(shopKey)
    local success = false
    local list = Controllers[shopKey] or {}

    for _, entry in ipairs(list) do
        local ctrl = entry.Table
        local module = entry.Module

        for _, name in ipairs({ "open", "Open", "show", "Show" }) do
            local fn = rawget(ctrl, name)

            if typeof(fn) == "function" then
                local ok, res = tryCallFunction(fn, ctrl)

                if ok then
                    success = true
                    addLog("OPEN_OK", "Controller." .. name .. "() | " .. getPath(module))
                else
                    addLog("OPEN_FAIL", "Controller." .. name .. "() | " .. getPath(module) .. " | " .. tostring(res))
                end
            end
        end
    end

    return success
end

local function callUiManagerClose(uiId)
    local success = false

    for _, entry in ipairs(UiManagers) do
        local manager = entry.Table

        for _, name in ipairs({ "close", "closeCurrentUI", "forceClose" }) do
            local fn = rawget(manager, name)

            if typeof(fn) == "function" then
                local ok = false

                if name == "close" or name == "forceClose" then
                    ok = select(1, tryCallFunction(fn, manager, uiId))
                else
                    ok = select(1, tryCallFunction(fn, manager))
                end

                if ok then
                    success = true
                    addLog("CLOSE_OK", "UIManager." .. name .. "(" .. tostring(uiId) .. ")")
                end
            end
        end
    end

    return success
end

local function callControllerClose(shopKey)
    local success = false
    local list = Controllers[shopKey] or {}

    for _, entry in ipairs(list) do
        local ctrl = entry.Table
        local module = entry.Module

        for _, name in ipairs({ "close", "Close", "hide", "Hide" }) do
            local fn = rawget(ctrl, name)

            if typeof(fn) == "function" then
                local ok, res = tryCallFunction(fn, ctrl)

                if ok then
                    success = true
                    addLog("CLOSE_OK", "Controller." .. name .. "() | " .. getPath(module))
                else
                    addLog("CLOSE_FAIL", "Controller." .. name .. "() | " .. getPath(module) .. " | " .. tostring(res))
                end
            end
        end
    end

    return success
end

function ShopOpener.Open(shopKey)
    local data = Config.ShopIds[shopKey]
    if not data then
        addLog("ERROR", "Shop inconnu : " .. tostring(shopKey))
        return false
    end

    ShopOpener.RefreshRuntimeObjects()
    addLog("ACTION", "Ouverture vraie demandée : " .. data.Display)

    local ok = false

    for _, uiId in ipairs(data.UIIds) do
        if callUiManagerOpen(uiId) then
            ok = true
            break
        end
    end

    if not ok then
        ok = callControllerOpen(shopKey)
    end

    if not ok then
        addLog("OPEN_FAIL", data.Display .. " non ouvert via controller/UIManager.")
    end

    return ok
end

function ShopOpener.Close(shopKey)
    local data = Config.ShopIds[shopKey]
    if not data then
        addLog("ERROR", "Shop inconnu : " .. tostring(shopKey))
        return false
    end

    ShopOpener.RefreshRuntimeObjects()
    addLog("ACTION", "Fermeture vraie demandée : " .. data.Display)

    local ok = false

    for _, uiId in ipairs(data.UIIds) do
        if callUiManagerClose(uiId) then
            ok = true
            break
        end
    end

    if not ok then
        ok = callControllerClose(shopKey)
    end

    if not ok then
        addLog("CLOSE_FAIL", data.Display .. " non fermé via controller/UIManager.")
    end

    return ok
end

function ShopOpener.CloseAll()
    ShopOpener.RefreshRuntimeObjects()

    local did = false

    for _, entry in ipairs(UiManagers) do
        local manager = entry.Table
        local fn = rawget(manager, "closeAll")

        if typeof(fn) == "function" then
            local ok = select(1, tryCallFunction(fn, manager))
            if ok then
                did = true
                addLog("CLOSE_ALL", "UIManager.closeAll() OK | gc#" .. tostring(entry.Index))
            end
        end
    end

    for shopKey in pairs(Config.ShopIds) do
        if ShopOpener.Close(shopKey) then
            did = true
        end
    end

    return did
end

function ShopOpener.Mount(Tabs, Fluent)
    if type(Tabs) ~= "table" then
        return false, "Tabs invalide"
    end

    local ShopTab = Tabs.Shop

    if not ShopTab then
        local Window = rawget(Tabs, "__Window") or getgenv().SoccerHubWindow
        if Window and type(Window.AddTab) == "function" then
            ShopTab = Window:AddTab({
                Title = "Shop",
                Icon = "solar/shop-bold"
            })
            Tabs.Shop = ShopTab
        end
    end

    if not ShopTab then
        return false, "Onglet Shop introuvable et Window non exposée"
    end

    ShopTab:AddParagraph({
        Title = "Shop",
        Content = "Ouvre Gem Shop, Wish et Craft Shop via les vrais controllers du jeu. Pas de Visible=true."
    })

    ShopTab:AddButton({
        Title = "Gem Shop",
        Description = "Ouvre le Gem Shop avec ses vraies données.",
        Icon = "lucide/gem",
        Callback = function()
            local ok = ShopOpener.Open("GemShop")
            if Fluent and Fluent.Notify then
                Fluent:Notify({
                    Title = ok and "Gem Shop" or "Gem Shop",
                    Content = ok and "Ouverture demandée." or "Échec ouverture. Regarde la console.",
                    Duration = 4
                })
            end
        end
    })

    ShopTab:AddButton({
        Title = "Wish",
        Description = "Ouvre le menu Wish / Gacha.",
        Icon = "lucide/sparkles",
        Callback = function()
            local ok = ShopOpener.Open("Wish")
            if Fluent and Fluent.Notify then
                Fluent:Notify({
                    Title = "Wish",
                    Content = ok and "Ouverture demandée." or "Échec ouverture. Regarde la console.",
                    Duration = 4
                })
            end
        end
    })

    ShopTab:AddButton({
        Title = "Craft Shop",
        Description = "Ouvre le Craft Shop avec ses vraies données.",
        Icon = "lucide/hammer",
        Callback = function()
            local ok = ShopOpener.Open("CraftShop")
            if Fluent and Fluent.Notify then
                Fluent:Notify({
                    Title = "Craft Shop",
                    Content = ok and "Ouverture demandée." or "Échec ouverture. Regarde la console.",
                    Duration = 4
                })
            end
        end
    })

    ShopTab:AddButton({
        Title = "Fermer tout",
        Description = "Ferme les shops via UIManager/controller.",
        Icon = "lucide/panel-top-close",
        Callback = function()
            local ok = ShopOpener.CloseAll()
            if Fluent and Fluent.Notify then
                Fluent:Notify({
                    Title = "Shop",
                    Content = ok and "Fermeture demandée." or "Fermeture non confirmée.",
                    Duration = 4
                })
            end
        end
    })

    ShopTab:AddButton({
        Title = "Copier debug Shop",
        Description = "Copie les derniers logs du module Shop.",
        Icon = "lucide/copy",
        Callback = function()
            local text = ShopOpener.GetLog()
            local copied = false

            if setclipboard then
                copied = pcall(setclipboard, text)
            end

            if not copied and toclipboard then
                copied = pcall(toclipboard, text)
            end

            if Fluent and Fluent.Notify then
                Fluent:Notify({
                    Title = "Shop Debug",
                    Content = copied and "Debug copié." or "Clipboard indisponible.",
                    Duration = 4
                })
            end
        end
    })

    addLog("MOUNT", "Onglet Shop monté.")
    return true, "OK"
end

return ShopOpener
