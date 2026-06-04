--// Soccer Hub - Shop Opener Module
--// Ouvre GemShop / Wish / CraftShop via vrais controllers/UIManager quand possible.
--// Ne force pas Visible=true pour ouvrir les shops.

local ShopOpener = {}

ShopOpener.Name = "ShopOpener"
ShopOpener.Version = "1.0.1"

local Config = {
    ShopIds = {
        GemShop = {
            Display = "Gem Shop",
            UIIds = { "GemShop", "Gem Shop", "gemShop" },
            ControllerNames = { "GemShopController" },
            ControllerPaths = {
                "ReplicatedStorage.Source.Client.UI.GemShop.GemShopController",
            },
        },

        Wish = {
            Display = "Wish",
            UIIds = { "Gacha", "Wish", "gacha", "wish" },
            ControllerNames = { "GachaController" },
            ControllerPaths = {
                "ReplicatedStorage.Source.Client.UI.Gacha.GachaController",
            },
        },

        CraftShop = {
            Display = "Craft Shop",
            UIIds = { "CraftShop", "Craft Shop", "craftShop" },
            ControllerNames = { "CraftShopController" },
            ControllerPaths = {
                "ReplicatedStorage.Source.Client.UI.CraftShop.CraftShopController",
            },
        },
    }
}

local UiManagers = {}
local Controllers = {}
local LastLog = {}

local function addLog(tag, msg)
    local line = "[" .. os.date("%H:%M:%S") .. "] [" .. tostring(tag) .. "] " .. tostring(msg)
    table.insert(LastLog, line)

    while #LastLog > 80 do
        table.remove(LastLog, 1)
    end

    pcall(function()
        if Log then
            Log(tostring(msg), "[SHOP]")
        end
    end)

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
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

    for _, entry in ipairs(UiManagers) do
        local manager = entry.Table
        local fn = rawget(manager, "open")

        if typeof(fn) == "function" then
            local ok, res = tryCallFunction(fn, manager, uiId)

            if ok then
                success = true
                addLog("OPEN_OK", "UIManager.open(" .. tostring(uiId) .. ")")
            else
                addLog("OPEN_FAIL", "UIManager.open(" .. tostring(uiId) .. ") | " .. tostring(res))
            end
        end
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
                    addLog("OPEN_FAIL", "Controller." .. name .. "() | " .. tostring(res))
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

local function notifySafe(Fluent, title, content)
    pcall(function()
        if Fluent and Fluent.Notify then
            Fluent:Notify({
                Title = title,
                Content = content,
                Duration = 3
            })
        end
    end)
end

local function runOpenDeferred(shopKey, Fluent)
    task.spawn(function()
        task.wait()

        local ok, result = pcall(function()
            return ShopOpener.Open(shopKey)
        end)

        local data = Config.ShopIds[shopKey]
        local title = data and data.Display or tostring(shopKey)

        if ok and result then
            notifySafe(Fluent, title, "Ouverture demandée.")
        else
            notifySafe(Fluent, title, "Échec ouverture. Regarde la console.")
            addLog("ERROR", "Open " .. tostring(shopKey) .. " | " .. tostring(result))
        end
    end)
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

    ShopTab:AddButton({
        Title = "Gem Shop",
        Description = "Ouvre le GemShop.",
        Icon = "lucide/gem",
        Callback = function()
            runOpenDeferred("GemShop", Fluent)
        end
    })

    ShopTab:AddButton({
        Title = "Wish",
        Description = "Ouvre Wish.",
        Icon = "lucide/sparkles",
        Callback = function()
            runOpenDeferred("Wish", Fluent)
        end
    })

    ShopTab:AddButton({
        Title = "Craft Shop",
        Description = "Ouvre le Craft Shop.",
        Icon = "lucide/hammer",
        Callback = function()
            runOpenDeferred("CraftShop", Fluent)
        end
    })

    addLog("MOUNT", "Onglet Shop monté.")
    return true, "OK"
end

return ShopOpener
