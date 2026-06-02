--//====================================================
--// Soccer Hub - core.lua
--// Fichier généré par découpage depuis soccer_hub_v33_index_order_fixed.lua
--// Chaque champ contient une partie réelle du script original.
--//====================================================

return {
    logic = [====================[
--//====================================================
--// SOCCER HUB | SPIN A SOCCER CARD v24 INDEX CALCULATOR
--// Fluent Modded Full Native
--// Anti-AFK multi-méthodes rotatif
--// Saut Anti-AFK supprimé
--// Fix AutoClaim Free Spin sans AutoSpin
--// Packs fusionnés avec AutoBuy
--// InterfaceManager séparé dans Interface
--// Aucun custom UI
--// Aucun Group.Frame
--// Aucun Instance.new
--//====================================================

if _G.__SOCCER_HUB_DESTROY then
    pcall(function()
        _G.__SOCCER_HUB_DESTROY()
    end)
end

_G.__SOCCER_HUB_RUN_ID = tostring(os.clock()) .. "_" .. tostring(math.random(100000, 999999))
local RUN_ID = _G.__SOCCER_HUB_RUN_ID
_G.__SOCCER_HUB_TOURNAMENT_AUTO_JOIN_ENABLED = false

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Fluent
local SaveManager
local InterfaceManager

local function SafeHttpGet(url)
    local body
    local ok, err = pcall(function()
        body = game:HttpGet(url)
    end)

    if (not ok or type(body) ~= "string" or body == "") then
        local ok2, err2 = pcall(function()
            body = game:HttpGet(url, true)
        end)

        if not ok2 then
            return nil, tostring(err2 or err or "HttpGet failed")
        end
    end

    if type(body) ~= "string" or body == "" then
        return nil, "HttpGet a retourné nil/vide pour : " .. tostring(url)
    end

    return body, nil
end

local function LoadRemoteScript(url)
    local source, getErr = SafeHttpGet(url)

    if type(source) ~= "string" or source == "" then
        return false, getErr or "source nil/vide"
    end

    local fn, compileErr = loadstring(source)

    if not fn then
        return false, "loadstring compile error : " .. tostring(compileErr)
    end

    local ok, result = pcall(fn)

    if not ok then
        return false, result
    end

    return true, result
end

local fluentOk, fluentResult = LoadRemoteScript(
    "https://github.com/StyearX/Fluent-Modded/releases/download/Fluent/FluentPro"
)

if fluentOk then
    Fluent = fluentResult
end

if not fluentOk or not Fluent then
    warn("[Soccer Hub] Fluent Modded n'a pas chargé : " .. tostring(fluentResult))
    return
end

local saveOk, saveResult = LoadRemoteScript(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"
)

if saveOk then
    SaveManager = saveResult
end

local saveErr = saveOk and nil or saveResult

local interfaceOk, interfaceResult = LoadRemoteScript(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"
)

if interfaceOk then
    InterfaceManager = interfaceResult
end

local interfaceErr = interfaceOk and nil or interfaceResult

local PACK_ORDER = {
    "Bronze",
    "Silver",
    "Gold",
    "Platinum",
    "Diamond",
    "Toxic",
    "Shadow",
    "Infernal",
    "Corrupted",
    "Cosmic",
    "Eclipse",
    "Hades",
    "Heaven",
    "Chaos",
    "Ordain",
    "Alpha",
    "Omega",
    "Genesis",
    "Abyssal",
    "Enigma",
    "Oracle",
    "Wither",
    "Bloom",
    "Dawn",
    "Dusk",
    "Conquest",
    "Fallen",
    "Ruin",
    "Valor"
}

local MAX_CONSOLE_LINES = 180
local MAX_LOG_STORAGE = 1200

local maxBuysPerPackDrain = 9999
local restockDebounceSeconds = 3

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local BuyPackRemote
local CollectSlotRemote
local SpinWheelRemote
local SpinWheelDataRemote

local autoBuyEnabled = false
local autoCollectEnabled = false
local drainStockMode = true

local autoClaimSpinEnabled = false
local autoSpinEnabled = false

local antiAfkEnabled = true
local antiAfkRealMoveEnabled = true
local antiAfkVirtualUserEnabled = true
local antiAfkVirtualKeyEnabled = true
local antiAfkVirtualMouseEnabled = true
local antiAfkMoveDelay = 45
local antiAfkMoveDistance = 10
local antiAfkMoveLoopStarted = false
local antiAfkMethodIndex = 0
local lastAfkStatus = "NON VÉRIFIÉ"
local lastAfkMoveClock = 0
local lastAntiAfkMethod = "AUCUNE"

local spinCheckDelay = 30
local spinAfterClaimDelay = 1.5
local spinClaimCooldown = 5
local spinUseCooldown = 5

local lastSpinClaimClock = 0
local lastSpinUseClock = 0
local lastSpinData = nil
local lastSpinStatus = "NON VÉRIFIÉ"
local lastClaimedSpinClock = 0
local lastClaimBeforeSpins = 0

local stockScanDelay = 2
local drainDelayBetweenBuys = 0.35

local collectDelay = 5
local collectMaxSlots = 30

local currentRestockId = 0
local lastPackRestockClock = 0

local detectedPacks = {}
local selectedPacks = {}
local packData = {}
local drainingPack = {}

local logs = {}
local connections = {}
local restockedTextBound = false

local lastActionText = "AUCUNE ACTION POUR LE MOMENT."
local lastActionType = "INFO"

local Options
local Window
local Tabs = {}

local HomeAutomationParagraph
local SpinWheelStatusParagraph
local ConsoleParagraph
local PackDropdown

local function IsCurrentRun()
    return _G.__SOCCER_HUB_RUN_ID == RUN_ID
end

local function AddConnection(conn)
    if conn then
        table.insert(connections, conn)
    end
end

_G.__SOCCER_HUB_DESTROY = function()
    if _G.__SOCCER_HUB_RUN_ID == RUN_ID then
        _G.__SOCCER_HUB_RUN_ID = "STOPPED_" .. tostring(os.clock())
        _G.__SOCCER_HUB_TOURNAMENT_AUTO_JOIN_ENABLED = false
    end

    for _, conn in ipairs(connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end

    connections = {}

    if Window then
        pcall(function()
            Window:Destroy()
        end)
    end
end

local function SafeFullName(obj)
    local ok, result = pcall(function()
        return obj:GetFullName()
    end)

    if ok then
        return result
    end

    return tostring(obj)
end

local function SafeNumber(text, defaultValue, minValue, maxValue)
    local n = tonumber(text)

    if not n then
        return defaultValue
    end

    if minValue and n < minValue then
        n = minValue
    end

    if maxValue and n > maxValue then
        n = maxValue
    end

    return n
end

local function StatusDot(value)
    return value and "🟢" or "🔴"
end

local function FormatTime(seconds)
    seconds = tonumber(seconds) or 0

    if seconds <= 0 then
        return "MAINTENANT"
    end

    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60

    return tostring(minutes) .. "M " .. tostring(secs) .. "S"
end

local function SetParagraph(paragraph, title, content)
    if not paragraph then
        return
    end

    pcall(function()
        paragraph:Set({
            Title = tostring(title),
            Content = tostring(content)
        })
    end)

    pcall(function()
        paragraph:SetTitle(tostring(title))
    end)

    pcall(function()
        paragraph:SetDesc(tostring(content))
    end)
end

local function SetLastAction(text, actionType)
    lastActionText = tostring(text or "AUCUNE ACTION.")
    lastActionType = tostring(actionType or "INFO")
end

local function RefreshConsole()
    if not ConsoleParagraph then
        return
    end

    local startIndex = math.max(1, #logs - MAX_CONSOLE_LINES + 1)
    local visible = {}

    for i = startIndex, #logs do
        table.insert(visible, logs[i])
    end

    if #visible == 0 then
        SetParagraph(ConsoleParagraph, "Console", "Aucun log.")
    else
        SetParagraph(ConsoleParagraph, "Console", table.concat(visible, "\n"))
    end
end

local function Log(text, prefix)
    local cleanPrefix = prefix or "[INFO]"
    local msg = os.date("[%H:%M:%S] ") .. cleanPrefix .. " " .. tostring(text)

    table.insert(logs, msg)

    if #logs > MAX_LOG_STORAGE then
        local removeCount = #logs - MAX_LOG_STORAGE

        for _ = 1, removeCount do
            table.remove(logs, 1)
        end
    end

    if cleanPrefix ~= "[SKIP]" then
        SetLastAction(text, cleanPrefix)
    end

    print(msg)
    RefreshConsole()
end

local function Notify(title, content, duration)
    pcall(function()
        Fluent:Notify({
            Title = tostring(title),
            Content = tostring(content),
            Duration = duration or 5
        })
    end)
end

]====================],

    startup = [====================[
Window:SelectTab(1)

RefreshRemotes()
StartRestockWatcher()
StartAntiAfk()
AutoBuyLoop()
AutoCollectLoop()
AutoClaimSpinLoop()

Notify("Soccer Hub", "v23 Fluent Modded chargé.", 5)

Log("Soccer Hub | Spin a Soccer Card v23 chargé.", "[SYSTEM]")
Log("Anti-AFK multi-méthodes activé.", "[SYSTEM]")
Log("Méthodes : VirtualUser, VirtualInput Key, VirtualInput Mouse, MoveTo.", "[SYSTEM]")
Log("Rotation anti-AFK toutes les " .. tostring(antiAfkMoveDelay) .. "s.", "[SYSTEM]")
Log("Méthode saut supprimée.", "[SYSTEM]")
Log("Fix : AutoClaim Free Spin fonctionne sans AutoSpin.", "[SYSTEM]")
Log("Base : v3.9 adaptée Fluent Modded.", "[SYSTEM]")
Log("Mode UI : full natif Fluent Modded.", "[SYSTEM]")
Log("Aucun custom UI.", "[SAFE]")
Log("Aucun Group.Frame.", "[SAFE]")
Log("Aucun Instance.new.", "[SAFE]")
Log("Thème Fluent Modded : AMOLED.", "[THEME]")
Log("Fluent Modded version : " .. tostring(Fluent.Version), "[SYSTEM]")
Log("AutoClaim : SpinWheel:FireServer(\"claim_free\")", "[SYSTEM]")
Log("AutoSpin : SpinWheel:FireServer(\"spin\")", "[SYSTEM]")
Log("Stock > 0 obligatoire.", "[SYSTEM]")
Log("Stock exact : PackShop.Frame.Main.ScrollingFrame.<Pack>.Stock.Text", "[SYSTEM]")
Log("Tournament intégré corrigé : equip_best + join + money check + shop close après tokens.", "[SYSTEM]")

if BuyPackRemote then
    Log("BuyPack trouvé.", "[REMOTE]")
else
    Log("BuyPack introuvable.", "[WARN]")
end

if CollectSlotRemote then
    Log("CollectSlot trouvé.", "[REMOTE]")
else
    Log("CollectSlot introuvable.", "[WARN]")
end

if SpinWheelRemote then
    Log("SpinWheel trouvé.", "[REMOTE]")
else
    Log("SpinWheel introuvable.", "[WARN]")
end

if SpinWheelDataRemote then
    Log("SpinWheelData trouvé.", "[REMOTE]")
else
    Log("SpinWheelData introuvable.", "[WARN]")
end

task.defer(function()
    task.wait(1)

    if not IsCurrentRun() then
        return
    end

    ScanExactPacks(true)
    ReadSpinWheelData()
    UpdateStatus()

    if saveOk and SaveManager then
        local okLoad, errLoad = pcall(function()
            SaveManager:LoadAutoloadConfig()
        end)

        if okLoad then
            Log("Config autoload chargée si disponible.", "[CONFIG]")
        else
            Log("Erreur autoload config : " .. tostring(errLoad), "[WARN]")
        end
    end
end)
]====================],

}
