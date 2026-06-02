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

local function RefreshRemotes()
    Remotes = ReplicatedStorage:FindFirstChild("Remotes")

    if Remotes then
        BuyPackRemote = Remotes:FindFirstChild("BuyPack")
        CollectSlotRemote = Remotes:FindFirstChild("CollectSlot")
        SpinWheelRemote = Remotes:FindFirstChild("SpinWheel")
        SpinWheelDataRemote = Remotes:FindFirstChild("SpinWheelData")
    end
end

local function FireRemote(remote, ...)
    if not remote then
        return false, "Remote introuvable"
    end

    if remote:IsA("RemoteEvent") then
        local ok, err = pcall(function(...)
            remote:FireServer(...)
        end, ...)

        return ok, err
    end

    if remote:IsA("RemoteFunction") then
        local ok, result = pcall(function(...)
            return remote:InvokeServer(...)
        end, ...)

        return ok, result
    end

    return false, "Remote invalide : " .. tostring(remote.ClassName)
end

local function ParseStockText(text)
    text = tostring(text or "")

    local amount = text:match("x(%d+)%s+in%s+stock")

    if amount then
        amount = tonumber(amount) or 0

        return {
            valid = true,
            amount = amount,
            inStock = amount > 0,
            raw = text
        }
    end

    local current, max = text:match("(%d+)%s*/%s*(%d+)")

    if current and max then
        current = tonumber(current) or 0
        max = tonumber(max) or 0

        return {
            valid = true,
            amount = current,
            max = max,
            inStock = current > 0,
            raw = text
        }
    end

    local lower = text:lower()

    if lower:find("sold") or lower:find("out") or lower:find("no stock") then
        return {
            valid = true,
            amount = 0,
            inStock = false,
            raw = text
        }
    end

    return {
        valid = false,
        amount = 0,
        inStock = false,
        raw = text
    }
end

local function CountSelectedPacks()
    local count = 0

    for _, packName in ipairs(PACK_ORDER) do
        if selectedPacks[packName] then
            count += 1
        end
    end

    return count
end

local function CountInStockPacks()
    local count = 0

    for _, packName in ipairs(PACK_ORDER) do
        local data = packData[packName]

        if data and data.inStock then
            count += 1
        end
    end

    return count
end

local function CountSelectedInStockPacks()
    local count = 0

    for _, packName in ipairs(PACK_ORDER) do
        local data = packData[packName]

        if selectedPacks[packName] and data and data.inStock then
            count += 1
        end
    end

    return count
end

local function GetSelectedNamesText()
    local selected = {}

    for _, packName in ipairs(PACK_ORDER) do
        if selectedPacks[packName] then
            table.insert(selected, packName)
        end
    end

    if #selected == 0 then
        return "AUCUN"
    end

    return table.concat(selected, ", ")
end

local function NormalizeSpinDataAfterClaim(data)
    if type(data) ~= "table" then
        return data
    end

    local spins = tonumber(data.spins) or 0
    local recentlyClaimed = (os.clock() - lastClaimedSpinClock) <= 12

    if recentlyClaimed and spins > lastClaimBeforeSpins then
        data.canClaimFree = false

        if not data.timeRemaining or tonumber(data.timeRemaining) == nil or tonumber(data.timeRemaining) <= 0 then
            data.timeRemaining = 1800
        end
    end

    return data
end

local function UpdateHomeAutomationStatus()
    local content = table.concat({
        "",
        StatusDot(autoBuyEnabled) .. "   AUTOBUY",
        "",
        StatusDot(autoCollectEnabled) .. "   AUTOCOLLECT",
        "",
        StatusDot(antiAfkEnabled) .. "   ANTI-AFK",
        "",
        StatusDot(autoClaimSpinEnabled) .. "   SPINWHEEL CLAIM",
        "",
        StatusDot(autoSpinEnabled) .. "   SPINWHEEL SPIN",
        "",
        StatusDot(_G.__SOCCER_HUB_TOURNAMENT_AUTO_JOIN_ENABLED == true) .. "   AUTO JOIN TOURNAMENT"
    }, "\n")

    SetParagraph(HomeAutomationParagraph, "AUTOMATISATIONS", content)
end

local function UpdateSpinWheelStatus()
    local data = NormalizeSpinDataAfterClaim(lastSpinData or {})
    local spins = tonumber(data.spins) or 0
    local canClaim = data.canClaimFree == true
    local timeRemaining = tonumber(data.timeRemaining) or 0
    local nextText = canClaim and "MAINTENANT" or FormatTime(timeRemaining)
    local spinAvailable = spins >= 1

    local content = table.concat({
        "",
        StatusDot(spinAvailable) .. "   SPINS DISPONIBLES : " .. tostring(spins),
        "",
        StatusDot(canClaim) .. "   FREE SPIN",
        "",
        "PROCHAIN CLAIM : " .. tostring(nextText)
    }, "\n")

    SetParagraph(SpinWheelStatusParagraph, "SPINWHEEL", content)
end

local function UpdateStatus()
    UpdateHomeAutomationStatus()
    UpdateSpinWheelStatus()
end

local function GetPackShopMain()
    local packShop = playerGui:FindFirstChild("PackShop")
    local frame = packShop and packShop:FindFirstChild("Frame")
    local main = frame and frame:FindFirstChild("Main")

    return main
end

local function GetPackShopScrollingFrame()
    local main = GetPackShopMain()
    local scrollingFrame = main and main:FindFirstChild("ScrollingFrame")

    return scrollingFrame
end

local function PackExistsInOrder(packName)
    for _, name in ipairs(PACK_ORDER) do
        if name == packName then
            return true
        end
    end

    return false
end

local function AddDetectedPack(packName)
    for _, existing in ipairs(detectedPacks) do
        if existing == packName then
            return
        end
    end

    table.insert(detectedPacks, packName)
end

local function UpdatePackData(packName, packFrame, stockLabel)
    local stockText = tostring(stockLabel.Text)
    local parsed = ParseStockText(stockText)

    packData[packName] = packData[packName] or {}
    packData[packName].frame = packFrame
    packData[packName].stockLabel = stockLabel
    packData[packName].stockText = stockText
    packData[packName].amount = parsed.amount or 0
    packData[packName].inStock = parsed.inStock == true
    packData[packName].stockPath = SafeFullName(stockLabel)
    packData[packName].layoutOrder = packFrame.LayoutOrder or 0

    if selectedPacks[packName] == nil then
        selectedPacks[packName] = false
    end
end

local function SortDetectedByManualOrder()
    local orderIndex = {}

    for i, packName in ipairs(PACK_ORDER) do
        orderIndex[packName] = i
    end

    table.sort(detectedPacks, function(a, b)
        return (orderIndex[a] or 9999) < (orderIndex[b] or 9999)
    end)
end

local function ScanExactPacks(silent)
    detectedPacks = {}

    local scrollingFrame = GetPackShopScrollingFrame()

    if not scrollingFrame then
        if not silent then
            Log("PackShop.Frame.Main.ScrollingFrame introuvable. Ouvre le PackShop.", "[ERROR]")
            Notify("Soccer Hub", "Ouvre le PackShop pour que le script puisse lire le stock.", 5)
        end

        UpdateStatus()
        return false
    end

    if not silent then
        Log("Scan exact PackShop...", "[SCAN]")
    end

    for _, packName in ipairs(PACK_ORDER) do
        local packFrame = scrollingFrame:FindFirstChild(packName)

        if packFrame then
            local stockLabel = packFrame:FindFirstChild("Stock")

            if stockLabel and stockLabel:IsA("TextLabel") then
                AddDetectedPack(packName)
                UpdatePackData(packName, packFrame, stockLabel)
            end
        end
    end

    SortDetectedByManualOrder()

    if not silent then
        Log("Packs détectés : " .. tostring(#detectedPacks), "[STATS]")
        Log("Packs en stock : " .. tostring(CountInStockPacks()), "[STATS]")
    end

    UpdateStatus()
    return true
end

local function RefreshSinglePackStock(packName)
    local scrollingFrame = GetPackShopScrollingFrame()

    if not scrollingFrame then
        return false
    end

    local packFrame = scrollingFrame:FindFirstChild(packName)

    if not packFrame then
        return false
    end

    local stockLabel = packFrame:FindFirstChild("Stock")

    if not stockLabel or not stockLabel:IsA("TextLabel") then
        return false
    end

    local oldText = packData[packName] and packData[packName].stockText or nil

    UpdatePackData(packName, packFrame, stockLabel)

    local newText = packData[packName].stockText

    if oldText and oldText ~= newText then
        Log(packName .. " stock : " .. tostring(oldText) .. " -> " .. tostring(newText), "[STOCK]")
    end

    return true
end

local function RefreshAllStocks()
    if #detectedPacks == 0 then
        ScanExactPacks(true)
    end

    for _, packName in ipairs(PACK_ORDER) do
        RefreshSinglePackStock(packName)
    end

    UpdateStatus()
end

local function ClearSelection()
    for _, packName in ipairs(PACK_ORDER) do
        selectedPacks[packName] = false
    end
end

local function HandleDropdownSelection(value)
    ClearSelection()

    if type(value) == "table" then
        for packName, state in pairs(value) do
            if state == true and PackExistsInOrder(packName) then
                selectedPacks[packName] = true
            elseif type(packName) == "number" and PackExistsInOrder(state) then
                selectedPacks[state] = true
            end
        end
    elseif type(value) == "string" then
        if PackExistsInOrder(value) then
            selectedPacks[value] = true
        end
    end

    Log("Sélection mise à jour : " .. tostring(CountSelectedPacks()) .. " pack(s).", "[PACK]")
    UpdateStatus()
end

local function CanBuyPack(packName)
    local data = packData[packName]

    if not selectedPacks[packName] then
        return false, "non sélectionné"
    end

    if not data then
        return false, "stock inconnu"
    end

    if not data.inStock or not data.amount or data.amount <= 0 then
        return false, "stock 0"
    end

    return true, "ok"
end

local function BuyOnce(packName)
    RefreshRemotes()

    local data = packData[packName]

    if not data then
        return false, "data introuvable"
    end

    if not BuyPackRemote then
        return false, "BuyPack introuvable"
    end

    Log("ACHAT : " .. packName .. " | " .. tostring(data.stockText), "[BUY]")

    local ok, result = FireRemote(BuyPackRemote, packName)

    if not ok then
        Log("Erreur BuyPack " .. packName .. " : " .. tostring(result), "[ERROR]")
        return false, "erreur remote"
    end

    Log("BuyPack envoyé : " .. packName .. " | result=" .. tostring(result), "[BUY]")
    return true, "ok"
end

local function DrainPackStock(packName)
    if drainingPack[packName] then
        return
    end

    drainingPack[packName] = true

    task.spawn(function()
        local buys = 0
        local noChangeCount = 0

        Log("Début vidage stock : " .. packName, "[DRAIN]")

        while IsCurrentRun() and autoBuyEnabled and drainStockMode and selectedPacks[packName] do
            RefreshSinglePackStock(packName)

            local data = packData[packName]

            if not data then
                Log("Stop drain " .. packName .. " : data introuvable.", "[DRAIN]")
                break
            end

            if not data.inStock or data.amount <= 0 then
                Log("Stop drain " .. packName .. " : stock vide (" .. tostring(data.stockText) .. ").", "[DRAIN]")
                break
            end

            if buys >= maxBuysPerPackDrain then
                Log("Stop drain " .. packName .. " : limite sécurité atteinte.", "[DRAIN]")
                break
            end

            local beforeText = data.stockText
            local beforeAmount = data.amount

            local allowed, reason = CanBuyPack(packName)

            if not allowed then
                Log("Stop drain " .. packName .. " : " .. tostring(reason), "[DRAIN]")
                break
            end

            local bought = BuyOnce(packName)

            if not bought then
                Log("Stop drain " .. packName .. " : achat impossible.", "[DRAIN]")
                break
            end

            buys += 1

            task.wait(math.max(0.15, drainDelayBetweenBuys))

            RefreshSinglePackStock(packName)

            local afterData = packData[packName]
            local afterText = afterData and afterData.stockText or "?"
            local afterAmount = afterData and afterData.amount or nil

            Log("Drain " .. packName .. " : " .. tostring(beforeText) .. " -> " .. tostring(afterText), "[DRAIN]")

            if afterText == beforeText or afterAmount == beforeAmount then
                noChangeCount += 1
                Log("Stock inchangé après achat pour " .. packName .. " (" .. tostring(noChangeCount) .. "/2)", "[WARN]")

                if noChangeCount >= 2 then
                    Log("Stop drain " .. packName .. " : stock ne change pas, anti-spam.", "[DRAIN]")
                    break
                end
            else
                noChangeCount = 0
            end
        end

        drainingPack[packName] = false
        RefreshAllStocks()

        Log("Fin vidage stock : " .. packName .. " | achats faits=" .. tostring(buys), "[DRAIN]")
    end)
end

local function TryBuyPack(packName)
    RefreshSinglePackStock(packName)

    local allowed, reason = CanBuyPack(packName)

    if not allowed then
        local data = packData[packName]
        Log("Skip " .. packName .. " : " .. tostring(reason) .. " | stock=" .. tostring(data and data.stockText or "?"), "[SKIP]")
        return
    end

    if drainStockMode then
        DrainPackStock(packName)
    else
        BuyOnce(packName)
        task.wait(0.5)
        RefreshSinglePackStock(packName)
    end
end

local function AutoBuyTick()
    RefreshAllStocks()

    for _, packName in ipairs(PACK_ORDER) do
        if not autoBuyEnabled then
            break
        end

        if selectedPacks[packName] then
            TryBuyPack(packName)
            task.wait(0.1)
        end
    end
end

local function AutoBuyLoop()
    task.spawn(function()
        while IsCurrentRun() do
            if autoBuyEnabled then
                AutoBuyTick()
            else
                RefreshAllStocks()
            end

            task.wait(math.max(1, stockScanDelay))
        end
    end)
end

local function TryCollectMoney()
    RefreshRemotes()

    if not CollectSlotRemote then
        Log("CollectSlot introuvable.", "[ERROR]")
        return
    end

    Log("Collect money slots 1 -> " .. tostring(collectMaxSlots), "[COLLECT]")

    for slot = 1, collectMaxSlots do
        if not autoCollectEnabled or not IsCurrentRun() then
            break
        end

        local ok, result = FireRemote(CollectSlotRemote, slot)

        if not ok then
            Log("CollectSlot " .. tostring(slot) .. " erreur : " .. tostring(result), "[COLLECT]")
        end

        task.wait(0.03)
    end
end

local function AutoCollectLoop()
    task.spawn(function()
        while IsCurrentRun() do
            if autoCollectEnabled then
                TryCollectMoney()
            end

            task.wait(math.max(1, collectDelay))
        end
    end)
end

local function ReadSpinWheelData()
    RefreshRemotes()

    if not SpinWheelDataRemote then
        lastSpinStatus = "SPINWHEELDATA INTROUVABLE"
        UpdateStatus()
        return nil
    end

    if not SpinWheelDataRemote:IsA("RemoteFunction") then
        lastSpinStatus = "SPINWHEELDATA INVALIDE : " .. tostring(SpinWheelDataRemote.ClassName)
        UpdateStatus()
        return nil
    end

    local ok, result = pcall(function()
        return SpinWheelDataRemote:InvokeServer()
    end)

    if not ok then
        lastSpinStatus = "ERREUR LECTURE SPINWHEELDATA : " .. tostring(result)
        Log(lastSpinStatus, "[SPIN]")
        UpdateStatus()
        return nil
    end

    if type(result) ~= "table" then
        lastSpinStatus = "SPINWHEELDATA RÉSULTAT INVALIDE"
        lastSpinData = result
        UpdateStatus()
        return nil
    end

    result = NormalizeSpinDataAfterClaim(result)
    lastSpinData = result

    lastSpinStatus = "SPINS=" .. tostring(result.spins)
        .. " | FREE=" .. tostring(result.canClaimFree)
        .. " | PROCHAIN=" .. FormatTime(result.timeRemaining)

    UpdateStatus()
    return result
end

local function DelayedSpinRefreshAfterClaim()
    task.spawn(function()
        for i = 1, 6 do
            if not IsCurrentRun() then
                return
            end

            task.wait(0.75)

            local data = ReadSpinWheelData()

            if type(data) == "table" then
                local spins = tonumber(data.spins) or 0

                if data.canClaimFree == false then
                    Log("Refresh après claim confirmé : free spin désactivé.", "[SPIN]")
                    return
                end

                if spins > lastClaimBeforeSpins then
                    data.canClaimFree = false
                    lastSpinData = data
                    lastSpinStatus = "CLAIM OK | FREE SPIN FORCÉ OFF | SPINS=" .. tostring(spins)
                    UpdateStatus()
                    Log("Refresh après claim : spins augmentés, free spin forcé OFF.", "[SPIN]")
                    return
                end
            end
        end

        ReadSpinWheelData()
    end)
end

local function ClaimFreeSpin()
    RefreshRemotes()

    if not SpinWheelRemote or not SpinWheelRemote:IsA("RemoteEvent") then
        lastSpinStatus = "SPINWHEEL REMOTE INTROUVABLE OU INVALIDE"
        Log(lastSpinStatus, "[SPIN]")
        UpdateStatus()
        return false
    end

    local beforeData = ReadSpinWheelData()
    local beforeSpins = 0

    if type(beforeData) == "table" then
        beforeSpins = tonumber(beforeData.spins) or 0
    end

    local now = os.clock()

    if now - lastSpinClaimClock < spinClaimCooldown then
        lastSpinStatus = "CLAIM IGNORÉ : COOLDOWN ANTI-SPAM"
        UpdateStatus()
        return false
    end

    lastSpinClaimClock = now
    lastClaimedSpinClock = now
    lastClaimBeforeSpins = beforeSpins

    Log("Free spin disponible : SpinWheel:FireServer(\"claim_free\")", "[SPIN]")

    local ok, err = pcall(function()
        SpinWheelRemote:FireServer("claim_free")
    end)

    if not ok then
        lastSpinStatus = "ERREUR CLAIM_FREE : " .. tostring(err)
        Log(lastSpinStatus, "[ERROR]")
        UpdateStatus()
        return false
    end

    task.wait(0.75)

    local afterData = ReadSpinWheelData()

    if type(afterData) == "table" then
        local afterSpins = tonumber(afterData.spins) or 0

        if afterData.canClaimFree == false then
            lastSpinStatus = "FREE SPIN CLAIM AVEC SUCCÈS"
            Log("Free spin claim confirmé | spins=" .. tostring(afterSpins), "[SPIN]")
            UpdateStatus()
            DelayedSpinRefreshAfterClaim()
            return true
        end

        if afterSpins > beforeSpins then
            afterData.canClaimFree = false
            lastSpinData = afterData
            lastSpinStatus = "FREE SPIN CLAIM AVEC SUCCÈS | SPINS=" .. tostring(afterSpins)
            Log("Free spin claim détecté par augmentation des spins : " .. tostring(beforeSpins) .. " -> " .. tostring(afterSpins), "[SPIN]")
            UpdateStatus()
            DelayedSpinRefreshAfterClaim()
            return true
        end
    end

    lastSpinStatus = "CLAIM ENVOYÉ, REFRESH EN COURS"
    Log(lastSpinStatus, "[WARN]")
    UpdateStatus()
    DelayedSpinRefreshAfterClaim()
    return true
end

local function UseOneSpin()
    RefreshRemotes()

    if not SpinWheelRemote or not SpinWheelRemote:IsA("RemoteEvent") then
        lastSpinStatus = "SPINWHEEL REMOTE INTROUVABLE OU INVALIDE"
        Log(lastSpinStatus, "[SPIN]")
        UpdateStatus()
        return false
    end

    local beforeData = ReadSpinWheelData()

    if type(beforeData) ~= "table" then
        return false
    end

    local beforeSpins = tonumber(beforeData.spins) or 0

    if beforeSpins <= 0 then
        lastSpinStatus = "AUTOSPIN IGNORÉ : AUCUN SPIN DISPONIBLE"
        UpdateStatus()
        return false
    end

    local now = os.clock()

    if now - lastSpinUseClock < spinUseCooldown then
        lastSpinStatus = "AUTOSPIN IGNORÉ : COOLDOWN ANTI-SPAM"
        UpdateStatus()
        return false
    end

    lastSpinUseClock = now

    Log("AutoSpin : SpinWheel:FireServer(\"spin\") | spins avant=" .. tostring(beforeSpins), "[SPIN]")

    local ok, err = pcall(function()
        SpinWheelRemote:FireServer("spin")
    end)

    if not ok then
        lastSpinStatus = "ERREUR SPIN : " .. tostring(err)
        Log(lastSpinStatus, "[ERROR]")
        UpdateStatus()
        return false
    end

    task.wait(3)

    local afterData = ReadSpinWheelData()

    if type(afterData) == "table" then
        local afterSpins = tonumber(afterData.spins) or 0

        if afterSpins < beforeSpins then
            lastSpinStatus = "AUTOSPIN LANCÉ AVEC SUCCÈS"
            Log("AutoSpin succès : spins " .. tostring(beforeSpins) .. " -> " .. tostring(afterSpins), "[SPIN]")
            UpdateStatus()
            return true
        end

        lastSpinStatus = "SPIN ENVOYÉ, ÉTAT INCHANGÉ : SPINS=" .. tostring(afterSpins)
        Log(lastSpinStatus, "[WARN]")
        UpdateStatus()
        return true
    end

    return true
end

local function AutoClaimSpinTick()
    local data = ReadSpinWheelData()

    if type(data) ~= "table" then
        return
    end

    if autoClaimSpinEnabled and data.canClaimFree == true then
        local claimed = ClaimFreeSpin()

        if claimed and not autoSpinEnabled then
            DelayedSpinRefreshAfterClaim()
            return
        end

        if claimed and autoSpinEnabled then
            task.wait(math.max(0.5, spinAfterClaimDelay))
            data = ReadSpinWheelData()
        end
    end

    if autoSpinEnabled then
        data = data or ReadSpinWheelData()

        if type(data) == "table" then
            local spins = tonumber(data.spins) or 0

            if spins > 0 then
                UseOneSpin()
            else
                lastSpinStatus = "AUTOSPIN ACTIF : AUCUN SPIN DISPONIBLE"
                UpdateStatus()
            end
        end
    else
        if type(data) == "table" and data.canClaimFree ~= true then
            lastSpinStatus = "PAS DE FREE SPIN | PROCHAIN : " .. FormatTime(data.timeRemaining)
            UpdateStatus()
        end
    end
end

local function AutoClaimSpinLoop()
    task.spawn(function()
        while IsCurrentRun() do
            if autoClaimSpinEnabled or autoSpinEnabled then
                AutoClaimSpinTick()
            else
                ReadSpinWheelData()
            end

            task.wait(math.max(5, spinCheckDelay))
        end
    end)
end

local function GetCharacterParts()
    local character = player.Character

    if not character then
        return nil, nil, nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not rootPart then
        return character, nil, nil
    end

    if humanoid.Health <= 0 then
        return character, nil, nil
    end

    return character, humanoid, rootPart
end

local function AntiAfkVirtualUserClick()
    if not antiAfkVirtualUserEnabled then
        return false
    end

    local ok, err = pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)

    if ok then
        lastAntiAfkMethod = "VirtualUser ClickButton2"
        lastAfkStatus = "VIRTUALUSER CLICK ENVOYÉ"
        Log("Anti-AFK méthode : VirtualUser ClickButton2.", "[AFK]")
        return true
    end

    Log("Anti-AFK VirtualUser erreur : " .. tostring(err), "[AFK]")
    return false
end

local function AntiAfkVirtualKey()
    if not antiAfkVirtualKeyEnabled then
        return false
    end

    local ok, err = pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.RightShift, false, game)
        task.wait(0.08)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.RightShift, false, game)
    end)

    if ok then
        lastAntiAfkMethod = "VirtualInput RightShift"
        lastAfkStatus = "VIRTUALINPUT TOUCHE RIGHTSHIFT"
        Log("Anti-AFK méthode : VirtualInput RightShift.", "[AFK]")
        return true
    end

    Log("Anti-AFK VirtualInput key erreur : " .. tostring(err), "[AFK]")
    return false
end

local function AntiAfkVirtualMouse()
    if not antiAfkVirtualMouseEnabled then
        return false
    end

    local ok, err = pcall(function()
        local camera = Workspace.CurrentCamera
        local viewportSize = camera and camera.ViewportSize or Vector2.new(800, 600)
        local x = math.floor(viewportSize.X / 2)
        local y = math.floor(viewportSize.Y / 2)

        VirtualInputManager:SendMouseMoveEvent(x, y, game)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
        task.wait(0.08)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)

    if ok then
        lastAntiAfkMethod = "VirtualInput MouseClick"
        lastAfkStatus = "VIRTUALINPUT CLIC SOURIS"
        Log("Anti-AFK méthode : VirtualInput clic souris.", "[AFK]")
        return true
    end

    Log("Anti-AFK VirtualInput mouse erreur : " .. tostring(err), "[AFK]")
    return false
end

local function AntiAfkRealMove()
    if not antiAfkRealMoveEnabled then
        return false
    end

    local character, humanoid, rootPart = GetCharacterParts()

    if not character or not humanoid or not rootPart then
        lastAfkStatus = "PERSONNAGE NON PRÊT"
        UpdateStatus()
        return false
    end

    if humanoid.Health <= 0 then
        lastAfkStatus = "PERSONNAGE MORT"
        UpdateStatus()
        return false
    end

    if humanoid.Sit then
        pcall(function()
            humanoid.Sit = false
        end)
    end

    local angle = math.random() * math.pi * 2
    local minDistance = math.max(2, math.floor(antiAfkMoveDistance * 0.5))
    local maxDistance = math.max(minDistance, antiAfkMoveDistance)
    local distance = math.random(minDistance, maxDistance)

    local offset = Vector3.new(
        math.cos(angle) * distance,
        0,
        math.sin(angle) * distance
    )

    local targetPosition = rootPart.Position + offset

    local ok, err = pcall(function()
        humanoid:MoveTo(targetPosition)
    end)

    if ok then
        lastAfkMoveClock = os.clock()
        lastAntiAfkMethod = "Humanoid MoveTo"
        lastAfkStatus = "MOUVEMENT ENVOYÉ | DISTANCE " .. tostring(distance)
        Log("Anti-AFK méthode : MoveTo | distance=" .. tostring(distance), "[AFK]")
        return true
    end

    Log("Anti-AFK MoveTo erreur : " .. tostring(err), "[AFK]")
    return false
end

local function RunAntiAfkRotatingMethod()
    if not antiAfkEnabled then
        return false
    end

    local methods = {
        AntiAfkVirtualUserClick,
        AntiAfkVirtualKey,
        AntiAfkVirtualMouse,
        AntiAfkRealMove
    }

    local totalMethods = #methods

    for attempt = 1, totalMethods do
        antiAfkMethodIndex += 1

        if antiAfkMethodIndex > totalMethods then
            antiAfkMethodIndex = 1
        end

        local method = methods[antiAfkMethodIndex]
        local ok = method()

        if ok then
            UpdateStatus()
            return true
        end
    end

    lastAfkStatus = "AUCUNE MÉTHODE ANTI-AFK DISPONIBLE"
    Log("Aucune méthode Anti-AFK n'a fonctionné.", "[AFK]")
    UpdateStatus()

    return false
end

local function StartAntiAfk()
    AddConnection(player.Idled:Connect(function()
        if not antiAfkEnabled then
            return
        end

        Log("Event player.Idled détecté, méthode rotative envoyée.", "[AFK]")
        task.spawn(function()
            RunAntiAfkRotatingMethod()
        end)
    end))

    if antiAfkMoveLoopStarted then
        return
    end

    antiAfkMoveLoopStarted = true

    task.spawn(function()
        while IsCurrentRun() do
            if antiAfkEnabled then
                RunAntiAfkRotatingMethod()
            end

            task.wait(math.max(5, antiAfkMoveDelay))
        end
    end)
end

local function IsPackRestockText(text)
    text = tostring(text or ""):lower()

    if text:find("trophies have been restocked", 1, true) then
        return false
    end

    if text:find("packs have been restocked", 1, true) then
        return true
    end

    return false
end

local function IsPackRestockObject(obj)
    local full = SafeFullName(obj):lower()
    local name = tostring(obj.Name):lower()

    if full:find("trophies have been restocked", 1, true) or name:find("trophies", 1, true) then
        return false
    end

    if full:find("packshop.frame.main.restockedtext", 1, true) then
        return true
    end

    if full:find("packs have been restocked", 1, true) or name:find("packs have been restocked", 1, true) then
        return true
    end

    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        return IsPackRestockText(obj.Text)
    end

    return false
end

local function MarkPackRestock(source)
    local now = os.clock()

    if now - lastPackRestockClock < restockDebounceSeconds then
        return
    end

    lastPackRestockClock = now
    currentRestockId += 1

    Log("PACK RESTOCK détecté : " .. tostring(source), "[RESTOCK]")
    Log("Restock ID = " .. tostring(currentRestockId), "[RESTOCK]")

    task.defer(function()
        task.wait(0.5)

        if IsCurrentRun() then
            ScanExactPacks(true)
        end
    end)
end

local function BindRestockedTextWatcher()
    if restockedTextBound then
        return
    end

    local main = GetPackShopMain()
    local restockedText = main and main:FindFirstChild("RestockedText")

    if not restockedText or not (restockedText:IsA("TextLabel") or restockedText:IsA("TextButton") or restockedText:IsA("TextBox")) then
        return
    end

    restockedTextBound = true

    AddConnection(restockedText:GetPropertyChangedSignal("Text"):Connect(function()
        if IsPackRestockText(restockedText.Text) then
            MarkPackRestock(SafeFullName(restockedText) .. " TextChanged")
        end
    end))

    Log("Watcher RestockedText attaché.", "[RESTOCK]")
end

local function StartRestockWatcher()
    AddConnection(playerGui.DescendantAdded:Connect(function(obj)
        pcall(function()
            if IsPackRestockObject(obj) then
                MarkPackRestock(SafeFullName(obj))
            end

            if obj.Name == "RestockedText" then
                task.defer(BindRestockedTextWatcher)
            end
        end)
    end))

    task.spawn(function()
        while IsCurrentRun() do
            BindRestockedTextWatcher()
            task.wait(5)
        end
    end)
end


--//====================================================
--// TOURNAMENT MODULE - intégré depuis le test v2.2
--// Isolé pour éviter Out of local registers
--//====================================================
local function InitTournamentModule(TournamentTab)
    if not TournamentTab then
        Log("Tournament : onglet introuvable.", "[TOURNAMENT]")
        return
    end

    local Lighting = game:GetService("Lighting")
    local autoTournamentEnabled = false
    local autoCloseShopEnabled = true
    local moneyCheckEnabled = true
    local loopStarted = false
    local shopLoopStarted = false

    local scanDelayFar = 10
    local scanDelayNear = 0.5
    local nearWindowSeconds = 90
    local delayAfterBestTeam = 2.0
    local delayAfterJoinFireBeforeState = 0.75
    local delayBetweenJoinAttempts = 2.0
    local preBestTeamSecondsBeforeWindow = 20
    local minSecondsBeforeClose = 5

    local testedThisWindow = false
    local joinedThisWindow = false
    local bestTeamDoneThisWindow = false
    local preBestTeamDoneThisWindow = false
    local tournamentAttemptRunning = false
    local joinedConfirmedClock = 0
    local fallbackShopCloseDelayAfterJoin = 75
    local shopCloseAllowedUntil = 0
    local shopCloseWindowAfterGain = 180
    local lastShopCloseAttemptClock = 0
    local lastCountdownBucket = nil
    local lastTournamentState = nil
    local lastTournamentWindowText = "INCONNU"
    local lastTournamentActionText = "AUCUNE ACTION"

    local TournamentRemote = nil
    local TournamentStateRemote = nil
    local BEST_TEAM_ACTION = "equip_best"
    local JOIN_ACTION = "join"

    local minMoneyAmount = 1
    local minMoneySuffix = "Qa"
    local minMoneyValue = 1e15
    local currentMoneyValue = nil
    local currentMoneyText = "NON LU"
    local lastMoneyCheckStatus = "NON CHECK"
    local lastKnownTokenAmount = nil
    local lastTokenGainAmount = nil
    local currentTournamentTokenText = "NON LU"
    local currentTournamentTokenPath = ""
    local lastShopCloseStatus = "AUCUNE"

    local StatusParagraph = nil

    local MoneySuffixMultipliers = {
        [""] = 1,
        ["K"] = 1e3,
        ["M"] = 1e6,
        ["B"] = 1e9,
        ["T"] = 1e12,
        ["Qa"] = 1e15,
        ["Qi"] = 1e18,
        ["Sx"] = 1e21,
        ["Sp"] = 1e24,
        ["Oc"] = 1e27,
        ["No"] = 1e30,
        ["Dc"] = 1e33
    }

    local MoneySuffixOrder = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"}
    local MoneySuffixDetectOrder = {"qa", "qi", "sx", "sp", "oc", "no", "dc", "k", "m", "b", "t"}

    local function NormalizeMoneySuffix(suffix)
        suffix = tostring(suffix or ""):lower()

        if suffix == "" then
            return ""
        elseif suffix == "k" then
            return "K"
        elseif suffix == "m" then
            return "M"
        elseif suffix == "b" then
            return "B"
        elseif suffix == "t" then
            return "T"
        elseif suffix == "qa" then
            return "Qa"
        elseif suffix == "qi" then
            return "Qi"
        elseif suffix == "sx" then
            return "Sx"
        elseif suffix == "sp" then
            return "Sp"
        elseif suffix == "oc" then
            return "Oc"
        elseif suffix == "no" then
            return "No"
        elseif suffix == "dc" then
            return "Dc"
        end

        return nil
    end

    local function RecalculateMinMoneyValue()
        local multiplier = MoneySuffixMultipliers[minMoneySuffix] or 1
        minMoneyValue = (tonumber(minMoneyAmount) or 0) * multiplier
    end

    local function NormalizeMoneyText(text)
        text = tostring(text or "")
        text = text:gsub("<.->", "")
        text = text:gsub(",", "")
        text = text:gsub("%s+", "")
        text = text:gsub("%$", "")
        text = text:gsub("€", "")
        return text
    end

    local function ParseCompactMoney(text)
        local clean = NormalizeMoneyText(text)
        local numberPart, alphaTail = clean:match("([%d%.]+)(%a*)")

        if not numberPart then
            return nil, "no_number"
        end

        local n = tonumber(numberPart)

        if not n then
            return nil, "bad_number"
        end

        alphaTail = tostring(alphaTail or ""):lower()
        local detectedSuffix = ""

        for _, suffix in ipairs(MoneySuffixDetectOrder) do
            if alphaTail:sub(1, #suffix) == suffix then
                detectedSuffix = suffix
                break
            end
        end

        local normalizedSuffix = NormalizeMoneySuffix(detectedSuffix)

        if not normalizedSuffix then
            return nil, "unknown_suffix:" .. tostring(detectedSuffix)
        end

        local multiplier = MoneySuffixMultipliers[normalizedSuffix]

        if not multiplier then
            return nil, "missing_multiplier:" .. tostring(normalizedSuffix)
        end

        return n * multiplier, normalizedSuffix
    end

    local function FormatMoneyValue(value)
        value = tonumber(value)

        if not value then
            return "nil"
        end

        local bestSuffix = ""
        local bestMultiplier = 1

        for _, suffix in ipairs(MoneySuffixOrder) do
            local multiplier = MoneySuffixMultipliers[suffix]

            if multiplier and value >= multiplier then
                bestSuffix = suffix
                bestMultiplier = multiplier
            end
        end

        local shortValue = value / bestMultiplier

        if bestSuffix == "" then
            return tostring(math.floor(shortValue))
        end

        return string.format("%.2f%s", shortValue, bestSuffix)
    end

    local function FormatSeconds(seconds)
        seconds = tonumber(seconds) or 0

        if seconds < 0 then
            seconds = 0
        end

        local minutes = math.floor(seconds / 60)
        local secs = math.floor(seconds % 60)

        return string.format("%02d:%02d", minutes, secs)
    end

    local function GetText(obj)
        if not obj then
            return ""
        end

        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            return tostring(obj.Text or "")
        end

        return ""
    end

    local function ParseNumberFromText(text)
        local clean = tostring(text or "")
        clean = clean:gsub(",", "")
        clean = clean:gsub("%s+", "")
        clean = clean:gsub("[^%d%.]", "")
        return tonumber(clean)
    end

    local function GetCurrentMoney()
        local hud = playerGui:FindFirstChild("HUD")
        local currency = hud and hud:FindFirstChild("Currency")
        local cashLabel = currency and currency:FindFirstChild("Cash")

        if not cashLabel then
            currentMoneyValue = nil
            currentMoneyText = "Cash label introuvable"
            return nil, "Cash label introuvable : PlayerGui.HUD.Currency.Cash"
        end

        local text = tostring(cashLabel.Text or "")
        local value, suffixOrErr = ParseCompactMoney(text)

        if not value then
            currentMoneyValue = nil
            currentMoneyText = text
            return nil, "Impossible de parser Cash : " .. tostring(text) .. " | " .. tostring(suffixOrErr)
        end

        currentMoneyValue = value
        currentMoneyText = text
        return value, text
    end

    local function HasEnoughMoneyForTournament()
        if not moneyCheckEnabled then
            lastMoneyCheckStatus = "Check argent désactivé"
            return true, lastMoneyCheckStatus
        end

        RecalculateMinMoneyValue()

        local moneyValue, moneyTextOrErr = GetCurrentMoney()

        if not moneyValue then
            lastMoneyCheckStatus = tostring(moneyTextOrErr)
            return false, lastMoneyCheckStatus
        end

        if moneyValue < minMoneyValue then
            lastMoneyCheckStatus = "Argent insuffisant : "
                .. tostring(moneyTextOrErr)
                .. " < "
                .. tostring(minMoneyAmount)
                .. tostring(minMoneySuffix)
                .. " | "
                .. FormatMoneyValue(moneyValue)
                .. " < "
                .. FormatMoneyValue(minMoneyValue)

            return false, lastMoneyCheckStatus
        end

        lastMoneyCheckStatus = "Argent OK : "
            .. tostring(moneyTextOrErr)
            .. " >= "
            .. tostring(minMoneyAmount)
            .. tostring(minMoneySuffix)
            .. " | "
            .. FormatMoneyValue(moneyValue)
            .. " >= "
            .. FormatMoneyValue(minMoneyValue)

        return true, lastMoneyCheckStatus
    end

    local function TournamentRefreshRemotes(silent)
        local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes")

        if not remoteFolder then
            TournamentRemote = nil
            TournamentStateRemote = nil

            if not silent then
                Log("Tournament : ReplicatedStorage.Remotes introuvable.", "[TOURNAMENT]")
            end

            return false
        end

        TournamentRemote = remoteFolder:FindFirstChild("Tournament")
        TournamentStateRemote = remoteFolder:FindFirstChild("TournamentState")

        if not silent then
            if TournamentRemote then
                Log("Tournament trouvé : " .. SafeFullName(TournamentRemote) .. " | " .. TournamentRemote.ClassName, "[TOURNAMENT]")
            else
                Log("Tournament introuvable.", "[TOURNAMENT]")
            end

            if TournamentStateRemote then
                Log("TournamentState trouvé : " .. SafeFullName(TournamentStateRemote) .. " | " .. TournamentStateRemote.ClassName, "[TOURNAMENT]")
            else
                Log("TournamentState introuvable.", "[TOURNAMENT]")
            end
        end

        return TournamentRemote ~= nil and TournamentStateRemote ~= nil
    end

    local function ReadTournamentState(silent)
        TournamentRefreshRemotes(true)

        if not TournamentStateRemote or not TournamentStateRemote:IsA("RemoteFunction") then
            if not silent then
                Log("TournamentState introuvable ou invalide.", "[TOURNAMENT]")
            end

            return nil
        end

        local ok, result = pcall(function()
            return TournamentStateRemote:InvokeServer()
        end)

        if not ok then
            if not silent then
                Log("Erreur TournamentState : " .. tostring(result), "[TOURNAMENT]")
            end

            return nil
        end

        lastTournamentState = result
        return result
    end

    local function IsExplicitJoinPhase(phase)
        phase = tostring(phase)
        return phase == "join_window"
            or phase == "joinWindow"
            or phase == "queue_open"
            or phase == "open"
    end

    local function GetTimingInfo(state)
        if type(state) ~= "table" then
            return {
                valid = false,
                secondsLeft = -1,
                cycleSeconds = -1,
                joinWindowSeconds = -1,
                threshold = -1,
                secondsUntilWindow = -1,
                secondsUntilClose = -1,
                inWindow = false
            }
        end

        local secondsLeft = tonumber(state.secondsLeft)
        local cycleSeconds = tonumber(state.cycleSeconds)
        local joinWindowSeconds = tonumber(state.joinWindowSeconds)
        local phase = tostring(state.phase)

        if not secondsLeft or not cycleSeconds or not joinWindowSeconds then
            return {
                valid = false,
                secondsLeft = secondsLeft or -1,
                cycleSeconds = cycleSeconds or -1,
                joinWindowSeconds = joinWindowSeconds or -1,
                threshold = -1,
                secondsUntilWindow = -1,
                secondsUntilClose = -1,
                inWindow = false
            }
        end

        local threshold = cycleSeconds - joinWindowSeconds
        local inWindow = secondsLeft >= threshold or IsExplicitJoinPhase(phase)
        local secondsUntilWindow
        local secondsUntilClose

        if inWindow then
            secondsUntilWindow = 0

            if secondsLeft >= threshold then
                secondsUntilClose = secondsLeft - threshold
            else
                secondsUntilClose = secondsLeft
            end
        else
            secondsUntilWindow = secondsLeft
            secondsUntilClose = -1
        end

        return {
            valid = true,
            secondsLeft = secondsLeft,
            cycleSeconds = cycleSeconds,
            joinWindowSeconds = joinWindowSeconds,
            threshold = threshold,
            secondsUntilWindow = secondsUntilWindow,
            secondsUntilClose = secondsUntilClose,
            inWindow = inWindow
        }
    end

    local function TournamentUpdateStatus()
        local info = GetTimingInfo(lastTournamentState)

        if info.valid then
            if info.inWindow then
                lastTournamentWindowText = "OUVERTE | fermeture dans " .. FormatSeconds(info.secondsUntilClose)
            else
                lastTournamentWindowText = "dans " .. FormatSeconds(info.secondsUntilWindow)
            end
        else
            lastTournamentWindowText = "INCONNU"
        end

        SetParagraph(StatusParagraph, "TOURNAMENT", table.concat({
            "",
            StatusDot(autoTournamentEnabled) .. "   AUTO JOIN",
            "",
            StatusDot(moneyCheckEnabled) .. "   CHECK ARGENT MINIMUM",
            "",
            StatusDot(autoCloseShopEnabled) .. "   AUTO CLOSE SHOP APRÈS TOKENS",
            "",
            "OUVERTURE TOURNOIS : " .. tostring(lastTournamentWindowText),
            "",
            "TOKEN TOURNAMENT : " .. tostring(currentTournamentTokenText)
        }, "\n"))
    end

    local function FireTournamentAction(actionName)
        TournamentRefreshRemotes(true)

        if not TournamentRemote then
            lastTournamentActionText = "Tournament remote introuvable"
            Log(lastTournamentActionText, "[ERROR]")
            TournamentUpdateStatus()
            return false
        end

        if not TournamentRemote:IsA("RemoteEvent") then
            lastTournamentActionText = "Tournament remote invalide : " .. tostring(TournamentRemote.ClassName)
            Log(lastTournamentActionText, "[ERROR]")
            TournamentUpdateStatus()
            return false
        end

        Log("Tournament:FireServer(" .. tostring(actionName) .. ")", "[FIRE]")

        local ok, err = pcall(function()
            TournamentRemote:FireServer(actionName)
        end)

        if not ok then
            lastTournamentActionText = "Erreur FireServer " .. tostring(actionName) .. " : " .. tostring(err)
            Log(lastTournamentActionText, "[ERROR]")
            TournamentUpdateStatus()
            return false
        end

        lastTournamentActionText = "Fire envoyé : " .. tostring(actionName)
        Log(lastTournamentActionText, "[FIRE]")
        TournamentUpdateStatus()
        return true
    end

    local function IsJoinWindowOpenByState(state)
        if type(state) ~= "table" then
            return false, "state invalide"
        end

        if state.ok ~= true then
            return false, "state.ok false"
        end

        if state.queued == true then
            return false, "déjà queued"
        end

        local info = GetTimingInfo(state)

        if not info.valid then
            return false, "timing invalide"
        end

        if not info.inWindow then
            return false, "fenêtre fermée | prochaine dans " .. FormatSeconds(info.secondsUntilWindow)
        end

        if info.secondsUntilClose < minSecondsBeforeClose then
            return false, "trop proche fermeture | fermeture dans " .. FormatSeconds(info.secondsUntilClose)
        end

        return true, "fenêtre ouverte | phase=" .. tostring(state.phase) .. " | fermeture dans " .. FormatSeconds(info.secondsUntilClose)
    end

    local function DisableBlurEffects(root)
        if not root then
            return
        end

        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("BlurEffect") then
                pcall(function()
                    obj.Enabled = false
                    obj.Size = 0
                end)
            end

            if obj:IsA("DepthOfFieldEffect") then
                pcall(function()
                    obj.Enabled = false
                    obj.FarIntensity = 0
                    obj.NearIntensity = 0
                    obj.InFocusRadius = 100000
                end)
            end
        end
    end

    local function FixBlur()
        DisableBlurEffects(Lighting)
        DisableBlurEffects(Workspace)

        if Workspace.CurrentCamera then
            DisableBlurEffects(Workspace.CurrentCamera)

            pcall(function()
                Workspace.CurrentCamera.FieldOfView = 70
            end)
        end
    end

    local function IsGuiVisibleInHierarchy(obj)
        if not obj then
            return false
        end

        local current = obj

        while current and current ~= playerGui do
            if current:IsA("ScreenGui") and current.Enabled == false then
                return false
            end

            if current:IsA("GuiObject") and current.Visible == false then
                return false
            end

            current = current.Parent
        end

        return true
    end

    local function IsLikelyTournamentShop(obj)
        if not obj then
            return false
        end

        local nameLower = tostring(obj.Name):lower()
        local fullLower = SafeFullName(obj):lower()

        if fullLower:find("tournamentserver", 1, true) and fullLower:find("shop", 1, true) then
            return true
        end

        if fullLower:find("tournament", 1, true) and nameLower == "shop" then
            return true
        end

        if fullLower:find("tournament", 1, true)
            and (nameLower:find("shop", 1, true) or nameLower:find("reward", 1, true) or nameLower:find("result", 1, true)) then
            return true
        end

        return false
    end

    local function GetTournamentShopCandidates()
        local candidates = {}
        local seen = {}

        local function add(obj)
            if obj and not seen[obj] then
                seen[obj] = true
                table.insert(candidates, obj)
            end
        end

        local tournamentServer = playerGui:FindFirstChild("TournamentServer")
        local directShop = tournamentServer and tournamentServer:FindFirstChild("Shop")
        add(directShop)

        if tournamentServer then
            for _, obj in ipairs(tournamentServer:GetDescendants()) do
                if IsLikelyTournamentShop(obj) then
                    add(obj)
                end
            end
        end

        for _, obj in ipairs(playerGui:GetDescendants()) do
            if IsLikelyTournamentShop(obj) then
                add(obj)
            end
        end

        return candidates
    end

    local function GetTournamentServerShop()
        local candidates = GetTournamentShopCandidates()

        for _, obj in ipairs(candidates) do
            if obj and IsGuiVisibleInHierarchy(obj) then
                return obj
            end
        end

        return candidates[1]
    end

    local function GetTournamentShopVisibleCandidate()
        local candidates = GetTournamentShopCandidates()

        for _, obj in ipairs(candidates) do
            if obj and IsGuiVisibleInHierarchy(obj) then
                return obj
            end
        end

        return nil
    end

    local function IsCloseButtonCandidate(obj)
        if not obj or not obj:IsA("GuiButton") then
            return false
        end

        local nameLower = tostring(obj.Name):lower()
        local fullLower = SafeFullName(obj):lower()
        local textLower = ""

        if obj:IsA("TextButton") then
            textLower = tostring(obj.Text or ""):lower()
        end

        if nameLower == "close" or nameLower == "x" or nameLower == "exit" then
            return true
        end

        if nameLower:find("close", 1, true) or nameLower:find("exit", 1, true) then
            return true
        end

        if fullLower:find("closeframe", 1, true) or fullLower:find("close", 1, true) then
            return true
        end

        if textLower == "x" or textLower == "×" or textLower:find("close", 1, true) then
            return true
        end

        return false
    end

    local function GetTournamentServerShopCloseButton()
        local shop = GetTournamentShopVisibleCandidate() or GetTournamentServerShop()

        if not shop then
            return nil
        end

        -- Chemin historique confirmé par le test.
        local frame = shop:FindFirstChild("Frame")
        local main = frame and frame:FindFirstChild("Main")
        local closeFrame = main and main:FindFirstChild("CloseFrame")
        local exact = closeFrame and closeFrame:FindFirstChild("Close")

        if exact and exact:IsA("GuiButton") then
            return exact
        end

        for _, obj in ipairs(shop:GetDescendants()) do
            if IsCloseButtonCandidate(obj) then
                return obj
            end
        end

        return nil
    end

    local function GetTournamentShopCloseButtons()
        local buttons = {}
        local seen = {}

        local function add(button)
            if button and button:IsA("GuiButton") and not seen[button] then
                seen[button] = true
                table.insert(buttons, button)
            end
        end

        local candidates = GetTournamentShopCandidates()

        for _, shop in ipairs(candidates) do
            if shop then
                local frame = shop:FindFirstChild("Frame")
                local main = frame and frame:FindFirstChild("Main")
                local closeFrame = main and main:FindFirstChild("CloseFrame")
                add(closeFrame and closeFrame:FindFirstChild("Close"))

                for _, obj in ipairs(shop:GetDescendants()) do
                    if IsCloseButtonCandidate(obj) then
                        add(obj)
                    end
                end
            end
        end

        -- Dernier filet : certains jeux mettent le bouton close en dehors du frame Shop,
        -- mais toujours sous TournamentServer.
        local tournamentServer = playerGui:FindFirstChild("TournamentServer")

        if tournamentServer then
            for _, obj in ipairs(tournamentServer:GetDescendants()) do
                if IsCloseButtonCandidate(obj) then
                    add(obj)
                end
            end
        end

        return buttons
    end

    local function IsTournamentShopVisible()
        return GetTournamentShopVisibleCandidate() ~= nil
    end

    local function ClickGuiButtonExact(button)
        if not button then
            return false, "button nil"
        end

        local clicked = false

        pcall(function()
            firesignal(button.MouseButton1Click)
            clicked = true
        end)

        pcall(function()
            firesignal(button.Activated)
            clicked = true
        end)

        pcall(function()
            firesignal(button.MouseButton1Down)
            task.wait(0.05)
            firesignal(button.MouseButton1Up)
            clicked = true
        end)

        local okVirtual, errVirtual = pcall(function()
            if not button:IsA("GuiObject") then
                return
            end

            local pos = button.AbsolutePosition
            local size = button.AbsoluteSize
            local x = math.floor(pos.X + (size.X / 2))
            local y = math.floor(pos.Y + (size.Y / 2))

            VirtualInputManager:SendMouseMoveEvent(x, y, game)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
            task.wait(0.08)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
            clicked = true
        end)

        if clicked then
            if okVirtual then
                return true, "firesignal+VirtualInputManager"
            end

            return true, "firesignal"
        end

        return false, tostring(errVirtual)
    end

    local function LogTournamentShopDebug(reason)
        local candidates = GetTournamentShopCandidates()
        Log("Shop debug " .. tostring(reason) .. " | candidats=" .. tostring(#candidates), "[SHOP]")

        for i, obj in ipairs(candidates) do
            if i > 6 then
                break
            end

            local extra = ""

            if obj:IsA("ScreenGui") then
                extra = " | Enabled=" .. tostring(obj.Enabled)
            elseif obj:IsA("GuiObject") then
                extra = " | Visible=" .. tostring(obj.Visible) .. " | HierarchyVisible=" .. tostring(IsGuiVisibleInHierarchy(obj))
            end

            Log("Shop candidat #" .. tostring(i) .. " : " .. SafeFullName(obj) .. extra, "[SHOP]")
        end

        local buttons = GetTournamentShopCloseButtons()
        Log("Shop close buttons trouvés=" .. tostring(#buttons), "[SHOP]")

        for i, button in ipairs(buttons) do
            if i > 6 then
                break
            end

            Log("Close candidat #" .. tostring(i) .. " : " .. SafeFullName(button), "[SHOP]")
        end
    end

    local function SetPlayerScreenGuiEnabled(guiName, enabled)
        local guiObj = playerGui:FindFirstChild(guiName)

        if guiObj and guiObj:IsA("ScreenGui") then
            local oldValue = guiObj.Enabled
            local ok, err = pcall(function()
                guiObj.Enabled = enabled
            end)

            if ok then
                Log("ScreenGui " .. tostring(guiName) .. ".Enabled " .. tostring(oldValue) .. " -> " .. tostring(enabled), "[SHOP]")
                return true
            end

            Log("Erreur ScreenGui " .. tostring(guiName) .. ".Enabled=" .. tostring(enabled) .. " : " .. tostring(err), "[SHOP]")
            return false
        end

        Log("ScreenGui " .. tostring(guiName) .. " introuvable ou invalide", "[SHOP]")
        return false
    end

    local function RestoreTournamentHudAfterShopClose()
        -- Changements exacts capturés quand tu fermes le shop manuellement :
        -- HUD false -> true
        -- TopbarCentered false -> true
        -- TopbarCenteredClipped false -> true
        -- TopbarStandard false -> true
        -- TopbarStandardClipped false -> true
        -- IMPORTANT : on ne touche PAS aux enfants GuiObject.Visible.
        SetPlayerScreenGuiEnabled("HUD", true)
        SetPlayerScreenGuiEnabled("TopbarCentered", true)
        SetPlayerScreenGuiEnabled("TopbarCenteredClipped", true)
        SetPlayerScreenGuiEnabled("TopbarStandard", true)
        SetPlayerScreenGuiEnabled("TopbarStandardClipped", true)
    end

    local function CloseTournamentShopClean(reason)
        local tournamentServer = playerGui:FindFirstChild("TournamentServer")

        -- Méthode propre validée par le détecteur PlayerGui :
        -- le jeu ferme le shop en désactivant TournamentServer puis en réactivant
        -- uniquement HUD + les 4 Topbar*. On reproduit ces 6 changements exacts,
        -- sans clic, sans Shop.Visible=false et sans forcer les descendants visibles.
        if tournamentServer and tournamentServer:IsA("ScreenGui") then
            Log("Fermeture shop propre sans clic | raison=" .. tostring(reason), "[SHOP]")

            local okClose = SetPlayerScreenGuiEnabled("TournamentServer", false)
            task.wait(0.05)
            RestoreTournamentHudAfterShopClose()
            task.wait(0.05)
            FixBlur()

            if not okClose then
                lastShopCloseStatus = "Erreur fermeture TournamentServer.Enabled=false"
                Log(lastShopCloseStatus, "[SHOP]")
                LogTournamentShopDebug("fermeture propre erreur")
                TournamentUpdateStatus()
                return false
            end

            local stillVisible = IsTournamentShopVisible()

            if not stillVisible then
                lastShopCloseStatus = "Shop fermé + HUD/Topbar restaurés | raison=" .. tostring(reason)
                Log(lastShopCloseStatus, "[SHOP]")
                TournamentUpdateStatus()
                return true
            end

            -- Si notre détection large croit encore voir un shop, on log seulement.
            -- On ne fait PAS de fallback brutal sur Shop.Visible ni sur les enfants HUD.
            lastShopCloseStatus = "Fermeture envoyée + HUD/Topbar restaurés, mais shop encore détecté visible | raison=" .. tostring(reason)
            Log(lastShopCloseStatus, "[SHOP]")
            LogTournamentShopDebug("fermeture propre envoyée mais visible")
            TournamentUpdateStatus()
            return false
        end

        lastShopCloseStatus = "TournamentServer introuvable ou pas ScreenGui"
        Log(lastShopCloseStatus .. " | raison=" .. tostring(reason), "[SHOP]")
        LogTournamentShopDebug("TournamentServer invalide")
        TournamentUpdateStatus()
        return false
    end

    local function ReadTokenObject(obj)
        if not obj then
            return nil, ""
        end

        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            local text = GetText(obj)
            local n = ParseNumberFromText(text)

            if n then
                return n, text
            end
        end

        return nil, ""
    end

    local function GetTournamentTokenAmountFromGui()
        -- Chemin historique du test : compteur principal Tournament.
        local tournamentGui = playerGui:FindFirstChild("Tournament")
        local frame = tournamentGui and tournamentGui:FindFirstChild("Frame")
        local main = frame and frame:FindFirstChild("Main")
        local tokenAmount = main and main:FindFirstChild("TokenAmount")

        local n, text = ReadTokenObject(tokenAmount)

        if n then
            return n, text, SafeFullName(tokenAmount)
        end

        -- Chemin confirmé par le scan quand le shop est ouvert : "You have 240 Tokens".
        local tournamentServer = playerGui:FindFirstChild("TournamentServer")
        local shop = tournamentServer and tournamentServer:FindFirstChild("Shop")
        local shopFrame = shop and shop:FindFirstChild("Frame")
        local shopMain = shopFrame and shopFrame:FindFirstChild("Main")
        local tournamentCurrency = shopMain and shopMain:FindFirstChild("TournamentCurrency")

        n, text = ReadTokenObject(tournamentCurrency)

        if n then
            return n, text, SafeFullName(tournamentCurrency)
        end

        -- Fallback limité aux GUIs Tournament/TournamentServer uniquement.
        -- On évite les TradeTokenAmount ailleurs dans l'interface.
        local roots = {}

        if tournamentGui then
            table.insert(roots, tournamentGui)
        end

        if tournamentServer then
            table.insert(roots, tournamentServer)
        end

        for _, root in ipairs(roots) do
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                    local nameLower = tostring(obj.Name):lower()
                    local fullLower = SafeFullName(obj):lower()

                    if nameLower == "tokenamount"
                        or nameLower == "tournamentcurrency"
                        or fullLower:find("tournamentcurrency", 1, true)
                        or fullLower:find("tokenamount", 1, true)
                    then
                        local amount, raw = ReadTokenObject(obj)

                        if amount then
                            return amount, raw, SafeFullName(obj)
                        end
                    end
                end
            end
        end

        return nil, "", ""
    end

    local function CheckTokenGain()
        local amount, raw, path = GetTournamentTokenAmountFromGui()

        if not amount then
            currentTournamentTokenText = "NON LU"
            currentTournamentTokenPath = ""
            TournamentUpdateStatus()
            return false
        end

        currentTournamentTokenText = tostring(amount)
        currentTournamentTokenPath = tostring(path or "")

        if lastKnownTokenAmount == nil then
            lastKnownTokenAmount = amount
            Log("Tournament tokens baseline : " .. tostring(amount) .. " | raw=" .. tostring(raw) .. " | path=" .. tostring(path), "[TOKEN]")
            TournamentUpdateStatus()
            return false
        end

        if amount > lastKnownTokenAmount then
            lastTokenGainAmount = amount - lastKnownTokenAmount
            Log("Gain tokens détecté : +" .. tostring(lastTokenGainAmount) .. " | " .. tostring(lastKnownTokenAmount) .. " -> " .. tostring(amount) .. " | raw=" .. tostring(raw) .. " | path=" .. tostring(path), "[TOKEN]")
            lastKnownTokenAmount = amount
            TournamentUpdateStatus()
            return true
        end

        lastKnownTokenAmount = amount
        TournamentUpdateStatus()
        return false
    end

    local function ShouldFallbackCloseShop()
        if not joinedThisWindow then
            return false
        end

        if joinedConfirmedClock <= 0 then
            return false
        end

        if os.clock() - joinedConfirmedClock < fallbackShopCloseDelayAfterJoin then
            return false
        end

        local state = ReadTournamentState(true)
        local info = GetTimingInfo(state)

        -- Sécurité : ne jamais fermer juste pendant la fenêtre de join.
        if info.valid and info.inWindow then
            return false
        end

        return IsTournamentShopVisible()
    end

    local function CheckAndCloseTournamentShop()
        if not autoCloseShopEnabled then
            return false
        end

        local gained = CheckTokenGain()

        if gained then
            shopCloseAllowedUntil = os.clock() + shopCloseWindowAfterGain
            Log("Gain tokens détecté : fermeture shop autorisée pendant " .. tostring(shopCloseWindowAfterGain) .. "s.", "[SHOP]")
        end

        -- Important : ton dernier log montre que le gain token est bien détecté,
        -- mais l'ancienne condition IsTournamentShopVisible() empêchait la fermeture.
        -- Donc pendant la fenêtre après gain, on tente la fermeture du ScreenGui
        -- TournamentServer directement, sans attendre que le shop soit détecté visible.
        if shopCloseAllowedUntil > 0 and os.clock() <= shopCloseAllowedUntil then
            if os.clock() - lastShopCloseAttemptClock >= 0.75 then
                lastShopCloseAttemptClock = os.clock()

                local closed = CloseTournamentShopClean("gain tokens détecté / fermeture forcée")

                if closed then
                    shopCloseAllowedUntil = 0
                end

                return closed
            end
        elseif shopCloseAllowedUntil > 0 and os.clock() > shopCloseAllowedUntil then
            shopCloseAllowedUntil = 0
            Log("Fenêtre fermeture shop après gain expirée.", "[SHOP]")
        end

        if ShouldFallbackCloseShop() then
            return CloseTournamentShopClean("TournamentShop visible après tournoi")
        end

        return false
    end

    local function ResetFlagsIfNewCycle(state)
        if type(state) ~= "table" then
            return
        end

        local info = GetTimingInfo(state)

        if not info.valid then
            return
        end

        if not info.inWindow then
            if (testedThisWindow or joinedThisWindow) and info.secondsUntilWindow > 30 then
                Log("Tournament reset flags hors fenêtre.", "[TOURNAMENT]")
                testedThisWindow = false
                joinedThisWindow = false
                bestTeamDoneThisWindow = false
                preBestTeamDoneThisWindow = false
                tournamentAttemptRunning = false
                joinedConfirmedClock = 0
            end
        end
    end

    local function MaybeLogCountdown(state)
        if type(state) ~= "table" then
            return
        end

        local info = GetTimingInfo(state)

        if not info.valid then
            return
        end

        local bucket

        if info.inWindow then
            bucket = "OPEN-" .. tostring(math.floor(info.secondsUntilClose / 5) * 5)
        elseif info.secondsUntilWindow <= 30 then
            bucket = "T-" .. tostring(math.floor(info.secondsUntilWindow / 5) * 5)
        elseif info.secondsUntilWindow <= nearWindowSeconds then
            bucket = "T-" .. tostring(math.floor(info.secondsUntilWindow / 15) * 15)
        else
            bucket = "T-" .. tostring(math.floor(info.secondsUntilWindow / 60) * 60)
        end

        if bucket ~= lastCountdownBucket then
            lastCountdownBucket = bucket

            if info.inWindow then
                Log("Tournament fenêtre OUVERTE | fermeture dans " .. FormatSeconds(info.secondsUntilClose), "[TOURNAMENT]")
            else
                Log("Prochaine fenêtre Tournament dans " .. FormatSeconds(info.secondsUntilWindow), "[TOURNAMENT]")
            end
        end
    end

    local function GetNextDelay(state)
        local info = GetTimingInfo(state)

        if not info.valid then
            return scanDelayFar
        end

        if info.inWindow then
            return scanDelayNear
        end

        if info.secondsUntilWindow <= nearWindowSeconds then
            return scanDelayNear
        end

        return scanDelayFar
    end

    local function DoBestTeam()
        -- Version test v2.2 : best_team est envoyé une seule fois dans la fenêtre,
        -- juste avant les tentatives de join.
        if bestTeamDoneThisWindow then
            Log("Best Team ignoré : déjà fait cette fenêtre.", "[BEST]")
            return true
        end

        Log("Best Team : Tournament:FireServer(\"" .. tostring(BEST_TEAM_ACTION) .. "\")", "[BEST]")

        local ok = FireTournamentAction(BEST_TEAM_ACTION)

        if ok then
            bestTeamDoneThisWindow = true
            task.wait(delayAfterBestTeam)
        end

        return ok
    end

    local function DoJoin()
        local state = ReadTournamentState(true)
        local open, reason = IsJoinWindowOpenByState(state)

        Log("Check Join = " .. tostring(open) .. " | " .. tostring(reason), "[JOIN]")

        if not open then
            lastTournamentActionText = "Join bloqué : " .. tostring(reason)
            TournamentUpdateStatus()
            return false
        end

        local moneyOk, moneyReason = HasEnoughMoneyForTournament()
        Log("Check argent avant join = " .. tostring(moneyOk) .. " | " .. tostring(moneyReason), "[MONEY]")

        if not moneyOk then
            lastTournamentActionText = "Join bloqué : " .. tostring(moneyReason)
            TournamentUpdateStatus()
            return false
        end

        Log("Join : Tournament:FireServer(\"" .. tostring(JOIN_ACTION) .. "\")", "[JOIN]")

        local sent = FireTournamentAction(JOIN_ACTION)

        if not sent then
            return false
        end

        task.wait(delayAfterJoinFireBeforeState)

        local afterState = ReadTournamentState(true)

        if type(afterState) == "table" and afterState.queued == true then
            joinedThisWindow = true
            testedThisWindow = true
            joinedConfirmedClock = os.clock()
            lastTournamentActionText = "Join confirmé : queued=true"
            Log("JOIN CONFIRMÉ : queued=true", "[JOIN]")
            Notify("Tournament", "Join confirmé : queued=true", 8)
            TournamentUpdateStatus()
            return true
        end

        Log("Join envoyé mais queued non confirmé.", "[WARN]")
        TournamentUpdateStatus()
        return false
    end

    local function RunTournamentNow()
        if tournamentAttemptRunning then
            Log("Tournament : tentative déjà en cours, skip double lancement.", "[TOURNAMENT]")
            return false
        end

        tournamentAttemptRunning = true
        local okFinal = false
        local joinAttemptCount = 0

        while IsCurrentRun() and autoTournamentEnabled do
            GetCurrentMoney()

            local state = ReadTournamentState(true)
            ResetFlagsIfNewCycle(state)

            if type(state) == "table" and state.queued == true then
                joinedThisWindow = true
                testedThisWindow = true
                if joinedConfirmedClock <= 0 then
                    joinedConfirmedClock = os.clock()
                end
                lastTournamentActionText = "Déjà queued=true"
                Log("Tournament déjà queued=true, stop boucle.", "[TOURNAMENT]")
                okFinal = true
                break
            end

            local open, reason = IsJoinWindowOpenByState(state)
            Log("Check fenêtre tournament = " .. tostring(open) .. " | " .. tostring(reason), "[TOURNAMENT]")

            if not open then
                lastTournamentActionText = "Tournament bloqué : " .. tostring(reason)
                TournamentUpdateStatus()
                break
            end

            local moneyOk, moneyReason = HasEnoughMoneyForTournament()
            Log("Check argent = " .. tostring(moneyOk) .. " | " .. tostring(moneyReason), "[MONEY]")

            if not moneyOk then
                lastTournamentActionText = "Tournament bloqué : " .. tostring(moneyReason)
                TournamentUpdateStatus()
                break
            end

            if joinAttemptCount == 0 then
                Log("====================================================", "[TOURNAMENT]")
                Log("DÉBUT TOURNAMENT AUTO - REMOTE VERSION TEST", "[TOURNAMENT]")
                Log("Best Team = " .. tostring(BEST_TEAM_ACTION), "[TOURNAMENT]")
                Log("Join = " .. tostring(JOIN_ACTION), "[TOURNAMENT]")
                Log("Fenêtre = " .. tostring(reason), "[TOURNAMENT]")
                Log("Argent = " .. tostring(moneyReason), "[TOURNAMENT]")
                Log("====================================================", "[TOURNAMENT]")

                local bestOk = DoBestTeam()

                if not bestOk then
                    lastTournamentActionText = "Tournament bloqué : Best Team non envoyé"
                    TournamentUpdateStatus()
                    break
                end
            else
                Log("Retry join sans renvoyer best_team, version test.", "[TOURNAMENT]")
            end

            joinAttemptCount += 1
            Log("Tentative join tournament #" .. tostring(joinAttemptCount), "[TOURNAMENT]")

            local success = DoJoin()

            if success then
                Log("TOURNAMENT : join terminé avec succès.", "[TOURNAMENT]")
                okFinal = true
                break
            end

            Log("Tournament non queued : retry join dans " .. tostring(delayBetweenJoinAttempts) .. "s si fenêtre encore ouverte.", "[TOURNAMENT]")
            task.wait(delayBetweenJoinAttempts)
        end

        tournamentAttemptRunning = false

        if not okFinal then
            Log("Tournament : boucle terminée sans confirmation queued=true.", "[TOURNAMENT]")
        end

        TournamentUpdateStatus()
        return okFinal
    end

    local function AutoTournamentTick()
        GetCurrentMoney()
        local state = ReadTournamentState(true)
        ResetFlagsIfNewCycle(state)
        MaybeLogCountdown(state)
        CheckAndCloseTournamentShop()

        local open = false
        open = IsJoinWindowOpenByState(state)

        if open and not testedThisWindow and not tournamentAttemptRunning then
            Log("Fenêtre Tournament ouverte détectée : lancement auto.", "[TOURNAMENT]")
            RunTournamentNow()
        end

        TournamentUpdateStatus()
        return GetNextDelay(state)
    end

    local function StartTournamentLoop()
        if loopStarted then
            return
        end

        loopStarted = true

        task.spawn(function()
            while IsCurrentRun() do
                local nextDelay = scanDelayFar

                if autoTournamentEnabled then
                    nextDelay = AutoTournamentTick()
                else
                    GetCurrentMoney()
                    CheckAndCloseTournamentShop()
                    TournamentUpdateStatus()
                end

                task.wait(math.max(0.5, nextDelay))
            end
        end)
    end

    local function StartTournamentShopLoop()
        if shopLoopStarted then
            return
        end

        shopLoopStarted = true

        task.spawn(function()
            while IsCurrentRun() do
                CheckAndCloseTournamentShop()
                task.wait(0.5)
            end
        end)
    end

    StatusParagraph = TournamentTab:AddParagraph({
        Title = "ÉTAT",
        Content = "Chargement..."
    })

    local AutoTournamentToggle = TournamentTab:AddToggle("TournamentAutoJoinToggle", {
        Title = "Auto join",
        Default = false
    })

    AutoTournamentToggle:OnChanged(function()
        autoTournamentEnabled = Options.TournamentAutoJoinToggle.Value
        _G.__SOCCER_HUB_TOURNAMENT_AUTO_JOIN_ENABLED = autoTournamentEnabled
        Log("Tournament Auto join = " .. tostring(autoTournamentEnabled), "[SYSTEM]")

        if autoTournamentEnabled then
            StartTournamentLoop()
            task.spawn(function()
                AutoTournamentTick()
            end)
        end

        TournamentUpdateStatus()
        UpdateStatus()
    end)

    TournamentTab:AddInput("TournamentScanFarInput", {
        Title = "Délai scan loin fenêtre",
        Default = tostring(scanDelayFar),
        Placeholder = "Ex: 10",
        Numeric = false,
        Finished = false,
        Callback = function(value)
            scanDelayFar = SafeNumber(value, 10, 3, 60)
            Log("Tournament scan loin = " .. tostring(scanDelayFar) .. "s", "[SYSTEM]")
            TournamentUpdateStatus()
        end
    })

    TournamentTab:AddInput("TournamentScanNearInput", {
        Title = "Délai scan proche fenêtre",
        Default = tostring(scanDelayNear),
        Placeholder = "Ex: 0.5",
        Numeric = false,
        Finished = false,
        Callback = function(value)
            local normalizedValue = tostring(value or ""):gsub(",", ".")
            scanDelayNear = SafeNumber(normalizedValue, 0.5, 0.25, 5)
            Log("Tournament scan proche = " .. tostring(scanDelayNear) .. "s", "[SYSTEM]")
            TournamentUpdateStatus()
        end
    })

    -- Espace retiré : les catégories commencent plus haut.

    local MoneyCheckToggle = TournamentTab:AddToggle("TournamentMoneyCheckToggle", {
        Title = "Bloquer si argent minimum non atteint",
        Default = true
    })

    MoneyCheckToggle:OnChanged(function()
        moneyCheckEnabled = Options.TournamentMoneyCheckToggle.Value
        Log("Tournament MoneyCheck = " .. tostring(moneyCheckEnabled), "[MONEY]")
        TournamentUpdateStatus()
    end)

    TournamentTab:AddInput("TournamentMinMoneyAmountInput", {
        Title = "Montant minimum argent",
        Default = tostring(minMoneyAmount),
        Placeholder = "Ex: 1 / 2.5 / 2,5",
        Numeric = false,
        Finished = false,
        Callback = function(value)
            local normalizedValue = tostring(value or ""):gsub(",", ".")
            local n = tonumber(normalizedValue)

            if not n then
                n = 1
            end

            if n < 0 then
                n = 0
            end

            minMoneyAmount = n
            RecalculateMinMoneyValue()
            Log("Tournament minimum argent = " .. tostring(minMoneyAmount) .. tostring(minMoneySuffix), "[MONEY]")
            TournamentUpdateStatus()
        end
    })

    TournamentTab:AddDropdown("TournamentMoneySuffixDropdown", {
        Title = "Unité minimum argent",
        Values = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"},
        Multi = false,
        Default = "Qa",
        Callback = function(value)
            minMoneySuffix = tostring(value or "Qa")

            if not MoneySuffixMultipliers[minMoneySuffix] then
                minMoneySuffix = "Qa"
            end

            RecalculateMinMoneyValue()
            Log("Tournament unité minimum = " .. tostring(minMoneySuffix), "[MONEY]")
            TournamentUpdateStatus()
        end
    })

    -- Espace retiré : les catégories commencent plus haut.

    local AutoCloseShopToggle = TournamentTab:AddToggle("TournamentAutoCloseShopToggle", {
        Title = "Fermer TournamentShop après gain tokens",
        Default = true
    })

    AutoCloseShopToggle:OnChanged(function()
        autoCloseShopEnabled = Options.TournamentAutoCloseShopToggle.Value
        Log("Tournament AutoCloseShop = " .. tostring(autoCloseShopEnabled), "[SHOP]")

        if autoCloseShopEnabled then
            StartTournamentShopLoop()
        end

        TournamentUpdateStatus()
    end)

    RecalculateMinMoneyValue()
    TournamentRefreshRemotes(false)
    ReadTournamentState(false)
    GetCurrentMoney()

    do
        local tokenAmount, tokenRaw, tokenPath = GetTournamentTokenAmountFromGui()

        if tokenAmount then
            lastKnownTokenAmount = tokenAmount
            currentTournamentTokenText = tostring(tokenAmount)
            currentTournamentTokenPath = tostring(tokenPath or "")
            Log("Tournament tokens initiaux : " .. tostring(tokenAmount) .. " | raw=" .. tostring(tokenRaw) .. " | path=" .. tostring(tokenPath), "[TOKEN]")
        else
            currentTournamentTokenText = "NON LU"
            currentTournamentTokenPath = ""
        end
    end

    StartTournamentLoop()
    StartTournamentShopLoop()
    TournamentUpdateStatus()
    Log("Tournament intégré : equip_best + join, shop close seulement après gain tokens.", "[SYSTEM]")
end



--//====================================================
--// INDEX GLOBAL - CARTES / MUTATIONS / TROPHÉES
--// Classement dynamique sans remote, sans modification du jeu
--//====================================================

local IndexRankingParagraph
local IndexRankingGroup
local IndexRankingScroll
local IndexRankingContent
local IndexRankingLayout
local indexCards = {}
local indexMutations = {}
local indexTrophies = {}
local indexMutationMap = {}
local indexTrophyChoiceMap = {}
local indexSelectedMutationNames = {}
local indexSelectedTrophyChoices = {}
local indexSelectedRarityFilter = "Toutes"
local indexLastReport = ""
local indexBestFixedIncome = 0
local indexBestFixedCardName = "?"

local INDEX_RARITY_ORDER = {
    ["Bronze"] = 1,
    ["Silver"] = 2,
    ["Gold"] = 3,
    ["Legendary"] = 4,
    ["Mythic"] = 5,
    ["Divine"] = 6,
    ["Primordial"] = 7,
    ["Gilded Zenith"] = 8,
    ["Crimson Zenith"] = 9,
    ["Azure Zenith"] = 10,
    ["Oblivion"] = 11,
    ["Astral"] = 12,
    ["Supernova"] = 13,
    ["Sovereign"] = 14,
    ["Eternity"] = 15,
    ["The Monarch"] = 16,
    ["Vandal"] = 17,
    ["Tyrant"] = 18,
    ["Verdant"] = 19,
    ["Silvane"] = 20,
    ["Lunar"] = 21,
    ["Solar"] = 22,
    ["Nether"] = 23,
    ["Aether"] = 24,
    ["Player of the Month"] = 25,
    ["Exclusive"] = 26,
    ["Secret Exclusive"] = 27,
    ["OWNER"] = 98,
    ["so cool"] = 99,
    ["Unknown"] = 999
}

local function IndexFormatNumber(value)
    value = tonumber(value)

    if not value then
        return "?"
    end

    local suffixes = {
        {"Dc", 1e33},
        {"No", 1e30},
        {"Oc", 1e27},
        {"Sp", 1e24},
        {"Sx", 1e21},
        {"Qi", 1e18},
        {"Qa", 1e15},
        {"T", 1e12},
        {"B", 1e9},
        {"M", 1e6},
        {"K", 1e3}
    }

    for _, data in ipairs(suffixes) do
        local suffix = data[1]
        local mult = data[2]

        if value >= mult then
            return string.format("%.2f%s", value / mult, suffix)
        end
    end

    if value % 1 == 0 then
        return tostring(math.floor(value))
    end

    return tostring(math.floor(value * 100) / 100)
end

local function IndexFormatPercentFromMultiplier(multiplier)
    multiplier = tonumber(multiplier) or 1
    local total = math.floor(multiplier * 1000) / 10
    local bonus = math.floor((multiplier - 1) * 1000) / 10

    if bonus == 0 then
        return tostring(total) .. "%"
    end

    return tostring(total) .. "% (+" .. tostring(bonus) .. "%)"
end

local function IndexFormatScaling(multiplier)
    multiplier = tonumber(multiplier) or 0
    return tostring(math.floor(multiplier * 1000) / 10) .. "%"
end

local function IndexClipText(text, maxLen)
    text = tostring(text or "")
    maxLen = tonumber(maxLen) or 20

    if #text <= maxLen then
        return text
    end

    if maxLen <= 1 then
        return text:sub(1, maxLen)
    end

    return text:sub(1, maxLen - 1) .. "…"
end

local function IndexNormalizeMultiSelection(value)
    local selected = {}

    if type(value) ~= "table" then
        if value ~= nil and tostring(value) ~= "" then
            table.insert(selected, tostring(value))
        end

        return selected
    end

    local hasBooleanMap = false

    for k, v in pairs(value) do
        if type(k) == "string" and type(v) == "boolean" then
            hasBooleanMap = true
            break
        end
    end

    if hasBooleanMap then
        for k, v in pairs(value) do
            if v == true then
                table.insert(selected, tostring(k))
            end
        end
    else
        for _, v in pairs(value) do
            if v ~= nil and tostring(v) ~= "" then
                table.insert(selected, tostring(v))
            end
        end
    end

    table.sort(selected)
    return selected
end

local function IndexGetConfigs()
    local source = ReplicatedStorage:FindFirstChild("Source")
    local shared = source and source:FindFirstChild("Shared")
    return shared and shared:FindFirstChild("Configs")
end

local function IndexRequireConfig(configName)
    local configs = IndexGetConfigs()
    local module = configs and configs:FindFirstChild(configName)

    if not module or not module:IsA("ModuleScript") then
        return nil, tostring(configName) .. " introuvable"
    end

    local ok, result = pcall(function()
        return require(module)
    end)

    if not ok or type(result) ~= "table" then
        return nil, tostring(configName) .. " require fail : " .. tostring(result)
    end

    return result, "OK"
end

local function IndexLoadCards()
    indexCards = {}
    indexBestFixedIncome = 0
    indexBestFixedCardName = "?"

    local cardConfig, err = IndexRequireConfig("CardConfig")

    if type(cardConfig) ~= "table" then
        Log("Index CardConfig erreur : " .. tostring(err), "[INDEX]")
        return false
    end

    local cardsTable = cardConfig.Cards or cardConfig.cards or cardConfig

    if type(cardsTable) ~= "table" then
        Log("Index Cards introuvable dans CardConfig.", "[INDEX]")
        return false
    end

    for key, data in pairs(cardsTable) do
        if type(data) == "table" then
            local incomeRate = tonumber(data.IncomeRate) or 0
            local isScaling = data.IsPercentageScaling == true
            local scalingPercentage = tonumber(data.ScalingPercentage) or 0
            local name = tostring(data.DisplayName or data.Name or key)
            local rarity = tostring(data.Rarity or "Unknown")

            local card = {
                key = tostring(key),
                name = name,
                rarity = rarity,
                incomeRate = incomeRate,
                isScaling = isScaling,
                scalingPercentage = scalingPercentage,
                powerText = tostring(data.PowerText or ""),
                hidden = data.Hide == true,
                unstealable = data.Unstealable == true,
                untradeable = data.Untradeable == true,
                immuneToRebirth = data.ImmuneToRebirth == true,
                trackGlobalCount = data.TrackGlobalCount == true
            }

            table.insert(indexCards, card)

            if not isScaling and incomeRate > indexBestFixedIncome then
                indexBestFixedIncome = incomeRate
                indexBestFixedCardName = name
            end
        end
    end

    Log("Index cartes chargées : " .. tostring(#indexCards) .. " | référence scaling=" .. tostring(indexBestFixedCardName) .. " " .. IndexFormatNumber(indexBestFixedIncome) .. "/s", "[INDEX]")
    return true
end

local function IndexLoadMutations()
    indexMutations = {}
    indexMutationMap = {}

    local mutationConfig, err = IndexRequireConfig("MutationConfig")

    if type(mutationConfig) ~= "table" then
        Log("Index MutationConfig erreur : " .. tostring(err), "[INDEX]")
        return false
    end

    local definitions = mutationConfig.Definitions or mutationConfig.Mutations or mutationConfig.mutations or mutationConfig

    for key, data in pairs(definitions) do
        if type(data) == "table" then
            local multiplier = tonumber(data.Multiplier) or tonumber(data.IncomeMultiplier) or 1
            local displayName = tostring(data.DisplayName or data.Name or key)
            local label = displayName .. " | " .. IndexFormatPercentFromMultiplier(multiplier)

            local mutation = {
                key = tostring(key),
                name = displayName,
                label = label,
                multiplier = multiplier,
                chance = data.BoostedChancePerSec or data.Chance or data.IndexChance,
                description = tostring(data.IndexDescription or data.Description or "")
            }

            table.insert(indexMutations, mutation)
            indexMutationMap[label] = mutation
        end
    end

    table.sort(indexMutations, function(a, b)
        if a.multiplier ~= b.multiplier then
            return a.multiplier > b.multiplier
        end

        return a.name < b.name
    end)

    Log("Index mutations chargées : " .. tostring(#indexMutations), "[INDEX]")
    return true
end

local function IndexLoadTrophies()
    indexTrophies = {}
    indexTrophyChoiceMap = {}

    local trophyConfig, err = IndexRequireConfig("TrophyConfig")

    if type(trophyConfig) ~= "table" then
        Log("Index TrophyConfig erreur : " .. tostring(err), "[INDEX]")
        return false
    end

    local trophiesTable = trophyConfig.Trophies or trophyConfig.Definitions or trophyConfig.trophies or trophyConfig

    for trophyKey, data in pairs(trophiesTable) do
        if type(data) == "table" then
            local trophyName = tostring(data.DisplayName or data.Name or trophyKey)
            local rarity = tostring(data.Rarity or "Unknown")
            local stars = data.Stars or {}

            for star = 1, 3 do
                local starData = stars[star]

                if type(starData) == "table" then
                    local moneyMultiplier = tonumber(starData.moneyMultiplier) or 1
                    local gemPerSec = tonumber(starData.gemPerSec) or 0
                    local gemCap = tonumber(starData.gemCap) or 0
                    local starText = string.rep("⭐", star)
                    local label = trophyName .. " " .. starText .. " | " .. IndexFormatPercentFromMultiplier(moneyMultiplier)

                    local trophy = {
                        key = tostring(trophyKey),
                        name = trophyName,
                        label = label,
                        rarity = rarity,
                        star = star,
                        moneyMultiplier = moneyMultiplier,
                        gemPerSec = gemPerSec,
                        gemCap = gemCap,
                        stockChance = tonumber(data.StockChance) or 0
                    }

                    table.insert(indexTrophies, trophy)
                    indexTrophyChoiceMap[label] = trophy
                end
            end
        end
    end

    table.sort(indexTrophies, function(a, b)
        if a.moneyMultiplier ~= b.moneyMultiplier then
            return a.moneyMultiplier > b.moneyMultiplier
        end

        if a.star ~= b.star then
            return a.star > b.star
        end

        return a.name < b.name
    end)

    Log("Index trophées/étoiles chargés : " .. tostring(#indexTrophies), "[INDEX]")
    return true
end

local function IndexGetSelectedMutationMultiplier()
    local multiplier = 1
    local names = {}

    for _, label in ipairs(indexSelectedMutationNames) do
        local mutation = indexMutationMap[label]

        if mutation then
            multiplier = multiplier * mutation.multiplier
            table.insert(names, mutation.name .. " x" .. tostring(mutation.multiplier))
        end
    end

    if #names == 0 then
        return 1, "Aucune mutation"
    end

    return multiplier, table.concat(names, " + ")
end

local function IndexGetSelectedTrophyMultiplier()
    local byTrophy = {}

    for _, label in ipairs(indexSelectedTrophyChoices) do
        local trophy = indexTrophyChoiceMap[label]

        if trophy then
            local current = byTrophy[trophy.key]

            -- Sécurité : si plusieurs étoiles du même trophée sont cochées,
            -- on garde uniquement l'étoile la plus haute pour éviter un double calcul.
            if not current or trophy.star > current.star then
                byTrophy[trophy.key] = trophy
            end
        end
    end

    local multiplier = 1
    local gemPerSec = 0
    local gemCapText = {}
    local names = {}

    for _, trophy in pairs(byTrophy) do
        multiplier = multiplier * trophy.moneyMultiplier
        gemPerSec = gemPerSec + trophy.gemPerSec
        table.insert(names, trophy.name .. " " .. string.rep("⭐", trophy.star) .. " x" .. tostring(trophy.moneyMultiplier))

        if trophy.gemPerSec > 0 then
            table.insert(gemCapText, trophy.name .. " cap " .. tostring(trophy.gemCap))
        end
    end

    table.sort(names)
    table.sort(gemCapText)

    if #names == 0 then
        return 1, 0, "Aucun trophée", ""
    end

    return multiplier, gemPerSec, table.concat(names, " + "), table.concat(gemCapText, " | ")
end

local function IndexGetBaseCardValue(card)
    if card.isScaling then
        return indexBestFixedIncome * card.scalingPercentage
    end

    return card.incomeRate
end

local function IndexPassFilter(card)
    local selectedRarity = tostring(indexSelectedRarityFilter or "Toutes")

    if selectedRarity == "" or selectedRarity == "Toutes" then
        return true
    end

    return tostring(card.rarity) == selectedRarity
end
local function IndexBuildRankingRows()
    local mutationMultiplier = IndexGetSelectedMutationMultiplier()
    local trophyMultiplier = IndexGetSelectedTrophyMultiplier()
    local totalMultiplier = mutationMultiplier * trophyMultiplier
    local useFinal = math.abs(totalMultiplier - 1) > 0.000001

    local exclusiveRows = {}
    local fixedRows = {}

    for _, card in ipairs(indexCards) do
        if IndexPassFilter(card) then
            local baseValue = IndexGetBaseCardValue(card)
            local finalValue = baseValue * totalMultiplier
            local row = {
                card = card,
                baseValue = baseValue,
                finalValue = finalValue
            }

            if card.isScaling then
                table.insert(exclusiveRows, row)
            else
                table.insert(fixedRows, row)
            end
        end
    end

    local function SortRows(rows)
        table.sort(rows, function(a, b)
            if a.finalValue ~= b.finalValue then
                return a.finalValue > b.finalValue
            end

            local ar = INDEX_RARITY_ORDER[a.card.rarity] or 999
            local br = INDEX_RARITY_ORDER[b.card.rarity] or 999

            if ar ~= br then
                return ar > br
            end

            return a.card.name < b.card.name
        end)
    end

    table.sort(exclusiveRows, function(a, b)
        if a.card.scalingPercentage ~= b.card.scalingPercentage then
            return a.card.scalingPercentage > b.card.scalingPercentage
        end

        return a.card.name < b.card.name
    end)

    SortRows(fixedRows)

    local compactInfo = {}

    if mutationMultiplier ~= 1 then
        table.insert(compactInfo, "Mutation " .. IndexFormatPercentFromMultiplier(mutationMultiplier))
    end

    if trophyMultiplier ~= 1 then
        table.insert(compactInfo, "Trophée " .. IndexFormatPercentFromMultiplier(trophyMultiplier))
    end

    if indexSelectedRarityFilter ~= "" and indexSelectedRarityFilter ~= "Toutes" then
        table.insert(compactInfo, "Rareté " .. tostring(indexSelectedRarityFilter))
    end

    return exclusiveRows, fixedRows, useFinal, compactInfo
end

local function IndexBuildRankingReport()
    local exclusiveRows, fixedRows, useFinal, compactInfo = IndexBuildRankingRows()
    local out = {}

    if #compactInfo > 0 then
        table.insert(out, table.concat(compactInfo, " | "))
        table.insert(out, "")
    end

    if #exclusiveRows > 0 then
        table.insert(out, "EXCLUSIVE")
        for _, row in ipairs(exclusiveRows) do
            table.insert(out, "• " .. tostring(row.card.name) .. " — " .. tostring(row.card.rarity) .. " — " .. IndexFormatScaling(row.card.scalingPercentage))
        end
        table.insert(out, "")
    end

    table.insert(out, "CARTES")
    for _, row in ipairs(fixedRows) do
        local shownValue = useFinal and row.finalValue or row.baseValue
        table.insert(out, "• " .. tostring(row.card.name) .. " — " .. tostring(row.card.rarity) .. " — " .. IndexFormatNumber(shownValue) .. "/s")
    end

    if #exclusiveRows == 0 and #fixedRows == 0 then
        table.insert(out, "Aucune carte pour cette rareté.")
    end

    indexLastReport = table.concat(out, "\n")
    return indexLastReport
end

local function IndexClearRankingContent()
    if not IndexRankingContent then
        return
    end

    for _, child in ipairs(IndexRankingContent:GetChildren()) do
        if child ~= IndexRankingLayout then
            pcall(function()
                child:Destroy()
            end)
        end
    end
end

local function IndexMakeLabel(parent, text, width, font, textColor, align)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Size = UDim2.new(0, width, 1, 0)
    label.Font = font or Enum.Font.Gotham
    label.Text = tostring(text or "")
    label.TextColor3 = textColor or Color3.fromRGB(245, 245, 245)
    label.TextSize = 12
    label.TextXAlignment = align or Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextWrapped = false
    label.ClipsDescendants = true
    label.Parent = parent
    return label
end

local function IndexMakeRow(height, backgroundTransparency)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, height or 22)
    row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    row.BackgroundTransparency = backgroundTransparency or 1
    row.BorderSizePixel = 0
    row.Parent = IndexRankingContent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 5)
    rowCorner.Parent = row

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Parent = row

    return row
end

local function IndexAddSection(title)
    local row = IndexMakeRow(24, 1)
    local label = IndexMakeLabel(row, tostring(title), 520, Enum.Font.GothamBold, Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Left)
    label.TextSize = 13
end

local function IndexAddInfo(text)
    local row = IndexMakeRow(22, 0.92)
    IndexMakeLabel(row, tostring(text), 520, Enum.Font.GothamSemibold, Color3.fromRGB(200, 220, 255), Enum.TextXAlignment.Left)
end

local function IndexAddHeader(col1, col2, col3, valueWidth)
    local row = IndexMakeRow(20, 0.95)
    IndexMakeLabel(row, col1, 190, Enum.Font.GothamBold, Color3.fromRGB(230, 238, 255), Enum.TextXAlignment.Left)
    IndexMakeLabel(row, col2, 155, Enum.Font.GothamBold, Color3.fromRGB(230, 238, 255), Enum.TextXAlignment.Left)
    IndexMakeLabel(row, col3, valueWidth or 95, Enum.Font.GothamBold, Color3.fromRGB(230, 238, 255), Enum.TextXAlignment.Right)
end

local function IndexAddRankingRow(name, rarity, value, alternate)
    local row = IndexMakeRow(21, alternate and 0.94 or 1)
    IndexMakeLabel(row, IndexClipText(name, 26), 190, Enum.Font.GothamSemibold, Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Left)
    IndexMakeLabel(row, IndexClipText(rarity, 22), 155, Enum.Font.Gotham, Color3.fromRGB(210, 220, 235), Enum.TextXAlignment.Left)
    IndexMakeLabel(row, value, 95, Enum.Font.GothamBold, Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Right)
end

local function IndexRenderRankingGui()
    if not IndexRankingContent then
        return false
    end

    IndexClearRankingContent()

    local exclusiveRows, fixedRows, useFinal, compactInfo = IndexBuildRankingRows()

    if #compactInfo > 0 then
        IndexAddInfo(table.concat(compactInfo, "   •   "))
    end

    if #exclusiveRows > 0 then
        IndexAddSection("EXCLUSIVE")
        IndexAddHeader("Nom", "Rareté", "%", 95)

        for i, row in ipairs(exclusiveRows) do
            IndexAddRankingRow(row.card.name, row.card.rarity, IndexFormatScaling(row.card.scalingPercentage), i % 2 == 0)
        end
    end

    if #fixedRows > 0 then
        if #exclusiveRows > 0 then
            local spacer = IndexMakeRow(8, 1)
            spacer.Visible = true
        end

        IndexAddSection("CARTES")
        IndexAddHeader("Nom", "Rareté", "Valeur", 95)

        for i, row in ipairs(fixedRows) do
            local shownValue = useFinal and row.finalValue or row.baseValue
            IndexAddRankingRow(row.card.name, row.card.rarity, IndexFormatNumber(shownValue) .. "/s", i % 2 == 0)
        end
    end

    if #exclusiveRows == 0 and #fixedRows == 0 then
        IndexAddInfo("Aucune carte pour cette rareté.")
    end

    indexLastReport = IndexBuildRankingReport()
    return true
end

local function IndexRefreshRanking()
    local report = IndexBuildRankingReport()

    if IndexRenderRankingGui() then
        if IndexRankingParagraph then
            SetParagraph(IndexRankingParagraph, "CLASSEMENT", "")
        end
    else
        SetParagraph(IndexRankingParagraph, "CLASSEMENT", report)
    end
end
local function IndexReloadData()
    IndexLoadCards()
    IndexLoadMutations()
    IndexLoadTrophies()
    IndexRefreshRanking()
end

local function InitIndexModule(IndexTab)
    if not IndexTab then
        return
    end

    IndexLoadCards()
    IndexLoadMutations()
    IndexLoadTrophies()

    local mutationValues = {}

    for _, mutation in ipairs(indexMutations) do
        table.insert(mutationValues, mutation.label)
    end

    local trophyValues = {}

    for _, trophy in ipairs(indexTrophies) do
        table.insert(trophyValues, trophy.label)
    end

    local rarityMap = {
        ["Toutes"] = true
    }

    for _, card in ipairs(indexCards) do
        rarityMap[tostring(card.rarity or "Unknown")] = true
    end

    local rarityValues = {}

    for rarity in pairs(rarityMap) do
        table.insert(rarityValues, rarity)
    end

    table.sort(rarityValues, function(a, b)
        if a == "Toutes" then
            return true
        end

        if b == "Toutes" then
            return false
        end

        local ao = INDEX_RARITY_ORDER[a] or 999
        local bo = INDEX_RARITY_ORDER[b] or 999

        if ao ~= bo then
            return ao < bo
        end

        return tostring(a) < tostring(b)
    end)

    IndexTab:AddDropdown("IndexMutationMultiDropdown", {
        Title = "Mutation(s)",
        Description = "Choix multiple.",
        Values = mutationValues,
        Multi = true,
        Default = {}
    }):OnChanged(function(value)
        indexSelectedMutationNames = IndexNormalizeMultiSelection(value)
        IndexRefreshRanking()
    end)

    IndexTab:AddDropdown("IndexTrophyMultiDropdown", {
        Title = "Trophées",
        Description = "Choix multiple. La plus haute étoile sélectionnée par trophée est utilisée.",
        Values = trophyValues,
        Multi = true,
        Default = {}
    }):OnChanged(function(value)
        indexSelectedTrophyChoices = IndexNormalizeMultiSelection(value)
        IndexRefreshRanking()
    end)

    IndexTab:AddDropdown("IndexRarityFilterDropdown", {
        Title = "Rareté",
        Description = "Filtre le classement.",
        Values = rarityValues,
        Multi = false,
        Default = "Toutes"
    }):OnChanged(function(value)
        indexSelectedRarityFilter = tostring(value or "Toutes")
        IndexRefreshRanking()
    end)

    -- Espace retiré : classement rapproché des menus.

    local groupOk, groupResult = pcall(function()
        return IndexTab:AddGroup({
            Title = "CLASSEMENT"
        })
    end)

    if groupOk and type(groupResult) == "table" and groupResult.Frame then
        IndexRankingGroup = groupResult
        local frame = groupResult.Frame

        pcall(function()
            frame.Size = UDim2.new(1, 0, 0, 360)
            frame.AutomaticSize = Enum.AutomaticSize.None
            frame.BackgroundTransparency = 1
            frame.LayoutOrder = 100000
        end)

        task.defer(function()
            pcall(function()
                frame.LayoutOrder = 100000
            end)
        end)

        IndexRankingScroll = Instance.new("ScrollingFrame")
        IndexRankingScroll.Name = "IndexRankingScroll"
        IndexRankingScroll.Size = UDim2.new(1, -6, 0, 350)
        IndexRankingScroll.Position = UDim2.fromOffset(3, 4)
        IndexRankingScroll.BackgroundColor3 = Color3.fromRGB(8, 13, 24)
        IndexRankingScroll.BackgroundTransparency = 0.35
        IndexRankingScroll.BorderSizePixel = 0
        IndexRankingScroll.ScrollBarThickness = 5
        IndexRankingScroll.CanvasSize = UDim2.fromOffset(0, 0)
        IndexRankingScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        IndexRankingScroll.Parent = frame

        local scrollCorner = Instance.new("UICorner")
        scrollCorner.CornerRadius = UDim.new(0, 8)
        scrollCorner.Parent = IndexRankingScroll

        IndexRankingContent = Instance.new("Frame")
        IndexRankingContent.Name = "IndexRankingContent"
        IndexRankingContent.Size = UDim2.new(1, -10, 0, 0)
        IndexRankingContent.Position = UDim2.fromOffset(6, 6)
        IndexRankingContent.BackgroundTransparency = 1
        IndexRankingContent.AutomaticSize = Enum.AutomaticSize.Y
        IndexRankingContent.Parent = IndexRankingScroll

        IndexRankingLayout = Instance.new("UIListLayout")
        IndexRankingLayout.FillDirection = Enum.FillDirection.Vertical
        IndexRankingLayout.SortOrder = Enum.SortOrder.LayoutOrder
        IndexRankingLayout.Padding = UDim.new(0, 2)
        IndexRankingLayout.Parent = IndexRankingContent

        AddConnection(IndexRankingLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            IndexRankingScroll.CanvasSize = UDim2.fromOffset(0, IndexRankingLayout.AbsoluteContentSize.Y + 18)
        end))
    else
        IndexRankingParagraph = IndexTab:AddParagraph({
            Title = "CLASSEMENT",
            Content = "Chargement..."
        })
    end

    IndexRefreshRanking()
    Log("Index intégré : tableau custom forcé sous Mutation/Trophées/Rareté.", "[INDEX]")
end
Window = Fluent:CreateWindow({
    Title = "Soccer Hub | Spin a Soccer Card",
    SubTitle = "v33 Index Order Fixed",
    TabWidth = 155,
    Size = UDim2.fromOffset(720, 540),
    Acrylic = false,
    Theme = "AMOLED",
    MinimizeKey = Enum.KeyCode.LeftControl,
    Search = true
})

Tabs.Accueil = Window:AddTab({
    Title = "Accueil",
    Icon = "solar/home-bold"
})

Tabs.AutoBuy = Window:AddTab({
    Title = "AutoBuy",
    Icon = "lucide/shopping-cart"
})

Tabs.Collect = Window:AddTab({
    Title = "AutoCollect",
    Icon = "lucide/coins"
})

Tabs.SpinWheel = Window:AddTab({
    Title = "SpinWheel",
    Icon = "lucide/rotate-cw"
})

Tabs.Tournament = Window:AddTab({
    Title = "Tournament",
    Icon = "lucide/trophy"
})

Tabs.Index = Window:AddTab({
    Title = "Index",
    Icon = "lucide/list-ordered"
})

Tabs.Settings = Window:AddTab({
    Title = "Réglages",
    Icon = "lucide/settings"
})

Tabs.Config = Window:AddTab({
    Title = "Sauvegarde",
    Icon = "lucide/save"
})

Tabs.Interface = Window:AddTab({
    Title = "Apparence",
    Icon = "lucide/palette"
})

Tabs.Console = Window:AddTab({
    Title = "Console",
    Icon = "lucide/terminal"
})

Options = Fluent.Options

HomeAutomationParagraph = Tabs.Accueil:AddParagraph({
    Title = "AUTOMATISATIONS",
    Content = "Chargement..."
})

InitTournamentModule(Tabs.Tournament)
InitIndexModule(Tabs.Index)

PackDropdown = Tabs.AutoBuy:AddDropdown("PackMultiDropdown", {
    Title = "Packs à acheter",
    Description = "Choisis les packs à vider.",
    Values = PACK_ORDER,
    Multi = true,
    Default = {}
})

PackDropdown:OnChanged(function(value)
    HandleDropdownSelection(value)
end)

-- Espace retiré : les catégories commencent plus haut.

local AutoBuyToggle = Tabs.AutoBuy:AddToggle("AutoBuyToggle", {
    Title = "AutoBuy",
    Default = false
})

AutoBuyToggle:OnChanged(function()
    autoBuyEnabled = Options.AutoBuyToggle.Value
    Log("AutoBuy = " .. tostring(autoBuyEnabled), "[SYSTEM]")
    UpdateStatus()
end)

local DrainToggle = Tabs.AutoBuy:AddToggle("DrainStockToggle", {
    Title = "Vider le stock",
    Default = true
})

DrainToggle:OnChanged(function()
    drainStockMode = Options.DrainStockToggle.Value
    Log("DrainStockMode = " .. tostring(drainStockMode), "[SYSTEM]")
    UpdateStatus()
end)

Tabs.AutoBuy:AddInput("StockScanDelayInput", {
    Title = "Délai Scan Stock",
    Default = tostring(stockScanDelay),
    Placeholder = "Ex: 2",
    Numeric = true,
    Finished = false,
    Callback = function(value)
        stockScanDelay = SafeNumber(value, 2, 1, 300)
        Log("Délai Scan Stock = " .. tostring(stockScanDelay) .. "s", "[SYSTEM]")
        UpdateStatus()
    end
})

Tabs.AutoBuy:AddInput("DrainDelayInput", {
    Title = "Délai entre achats",
    Default = tostring(drainDelayBetweenBuys),
    Placeholder = "Ex: 0.35",
    Numeric = false,
    Finished = false,
    Callback = function(value)
        drainDelayBetweenBuys = SafeNumber(value, 0.35, 0.15, 10)
        Log("Délai entre achats = " .. tostring(drainDelayBetweenBuys) .. "s", "[SYSTEM]")
        UpdateStatus()
    end
})

local AutoCollectToggle = Tabs.Collect:AddToggle("AutoCollectToggle", {
    Title = "AutoCollect Money",
    Default = false
})

AutoCollectToggle:OnChanged(function()
    autoCollectEnabled = Options.AutoCollectToggle.Value
    Log("AutoCollect = " .. tostring(autoCollectEnabled), "[SYSTEM]")
    UpdateStatus()
end)

Tabs.Collect:AddInput("CollectDelayInput", {
    Title = "Délai ramassage",
    Default = tostring(collectDelay),
    Placeholder = "Ex: 5",
    Numeric = true,
    Finished = false,
    Callback = function(value)
        collectDelay = SafeNumber(value, 5, 1, 300)
        Log("Délai collect = " .. tostring(collectDelay) .. "s", "[SYSTEM]")
        UpdateStatus()
    end
})

Tabs.Collect:AddInput("CollectSlotsInput", {
    Title = "Nombre de slots",
    Default = tostring(collectMaxSlots),
    Placeholder = "Ex: 30",
    Numeric = true,
    Finished = false,
    Callback = function(value)
        collectMaxSlots = SafeNumber(value, 30, 1, 200)
        Log("Slots collect = 1 -> " .. tostring(collectMaxSlots), "[SYSTEM]")
        UpdateStatus()
    end
})

SpinWheelStatusParagraph = Tabs.SpinWheel:AddParagraph({
    Title = "SPINWHEEL",
    Content = "Chargement..."
})

-- Espace retiré : les catégories commencent plus haut.

local AutoClaimSpinToggle = Tabs.SpinWheel:AddToggle("AutoClaimSpinToggle", {
    Title = "AutoClaim Free Spin",
    Default = false
})

AutoClaimSpinToggle:OnChanged(function()
    autoClaimSpinEnabled = Options.AutoClaimSpinToggle.Value
    Log("AutoClaim Free Spin = " .. tostring(autoClaimSpinEnabled), "[SYSTEM]")
    UpdateStatus()

    if autoClaimSpinEnabled then
        task.spawn(function()
            AutoClaimSpinTick()
        end)
    end
end)

local AutoSpinToggle = Tabs.SpinWheel:AddToggle("AutoSpinToggle", {
    Title = "AutoSpin",
    Default = false
})

AutoSpinToggle:OnChanged(function()
    autoSpinEnabled = Options.AutoSpinToggle.Value
    Log("AutoSpin = " .. tostring(autoSpinEnabled), "[SYSTEM]")
    UpdateStatus()

    if autoSpinEnabled then
        task.spawn(function()
            AutoClaimSpinTick()
        end)
    end
end)

Tabs.SpinWheel:AddInput("SpinCheckDelayInput", {
    Title = "Délai scan SpinWheel",
    Default = tostring(spinCheckDelay),
    Placeholder = "Ex: 30",
    Numeric = true,
    Finished = false,
    Callback = function(value)
        spinCheckDelay = SafeNumber(value, 30, 5, 1800)
        Log("Délai scan SpinWheel = " .. tostring(spinCheckDelay) .. "s", "[SYSTEM]")
        UpdateStatus()
    end
})

Tabs.SpinWheel:AddInput("SpinAfterClaimDelayInput", {
    Title = "Délai spin après claim gratuit",
    Default = tostring(spinAfterClaimDelay),
    Placeholder = "Ex: 1.5",
    Numeric = false,
    Finished = false,
    Callback = function(value)
        spinAfterClaimDelay = SafeNumber(value, 1.5, 0.5, 30)
        Log("Délai spin après claim gratuit = " .. tostring(spinAfterClaimDelay) .. "s", "[SYSTEM]")
        UpdateStatus()
    end
})

local AntiAfkToggle = Tabs.Settings:AddToggle("AntiAfkToggle", {
    Title = "Anti-AFK",
    Default = true
})

AntiAfkToggle:OnChanged(function()
    antiAfkEnabled = Options.AntiAfkToggle.Value
    Log("AntiAFK = " .. tostring(antiAfkEnabled), "[SYSTEM]")
    UpdateStatus()
end)

local AntiAfkMoveToggle = Tabs.Settings:AddToggle("AntiAfkMoveToggle", {
    Title = "Anti-AFK mouvement réel",
    Default = true
})

AntiAfkMoveToggle:OnChanged(function()
    antiAfkRealMoveEnabled = Options.AntiAfkMoveToggle.Value
    Log("Anti-AFK mouvement réel = " .. tostring(antiAfkRealMoveEnabled), "[SYSTEM]")
    UpdateStatus()
end)

local AntiAfkVirtualUserToggle = Tabs.Settings:AddToggle("AntiAfkVirtualUserToggle", {
    Title = "Anti-AFK VirtualUser",
    Default = true
})

AntiAfkVirtualUserToggle:OnChanged(function()
    antiAfkVirtualUserEnabled = Options.AntiAfkVirtualUserToggle.Value
    Log("Anti-AFK VirtualUser = " .. tostring(antiAfkVirtualUserEnabled), "[SYSTEM]")
    UpdateStatus()
end)

local AntiAfkVirtualKeyToggle = Tabs.Settings:AddToggle("AntiAfkVirtualKeyToggle", {
    Title = "Anti-AFK touche virtuelle",
    Default = true
})

AntiAfkVirtualKeyToggle:OnChanged(function()
    antiAfkVirtualKeyEnabled = Options.AntiAfkVirtualKeyToggle.Value
    Log("Anti-AFK touche virtuelle = " .. tostring(antiAfkVirtualKeyEnabled), "[SYSTEM]")
    UpdateStatus()
end)

local AntiAfkVirtualMouseToggle = Tabs.Settings:AddToggle("AntiAfkVirtualMouseToggle", {
    Title = "Anti-AFK clic virtuel",
    Default = true
})

AntiAfkVirtualMouseToggle:OnChanged(function()
    antiAfkVirtualMouseEnabled = Options.AntiAfkVirtualMouseToggle.Value
    Log("Anti-AFK clic virtuel = " .. tostring(antiAfkVirtualMouseEnabled), "[SYSTEM]")
    UpdateStatus()
end)

Tabs.Settings:AddInput("AntiAfkMoveDelayInput", {
    Title = "Délai Anti-AFK",
    Default = tostring(antiAfkMoveDelay),
    Placeholder = "Ex: 45",
    Numeric = true,
    Finished = false,
    Callback = function(value)
        antiAfkMoveDelay = SafeNumber(value, 45, 5, 600)
        Log("Délai Anti-AFK = " .. tostring(antiAfkMoveDelay) .. "s", "[SYSTEM]")
        UpdateStatus()
    end
})

Tabs.Settings:AddInput("AntiAfkMoveDistanceInput", {
    Title = "Distance mouvement Anti-AFK",
    Default = tostring(antiAfkMoveDistance),
    Placeholder = "Ex: 10",
    Numeric = true,
    Finished = false,
    Callback = function(value)
        antiAfkMoveDistance = SafeNumber(value, 10, 2, 100)
        Log("Distance mouvement Anti-AFK = " .. tostring(antiAfkMoveDistance), "[SYSTEM]")
        UpdateStatus()
    end
})

if saveOk and SaveManager then
    SaveManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({})
    SaveManager:SetFolder("SoccerHub/SpinASoccerCard")
    SaveManager:BuildConfigSection(Tabs.Config)
else
    Tabs.Config:AddParagraph({
        Title = "CONFIG INDISPONIBLE",
        Content = "SaveManager n'a pas chargé.\nErreur SaveManager : " .. tostring(saveErr)
    })
end

if interfaceOk and InterfaceManager then
    InterfaceManager:SetLibrary(Fluent)
    InterfaceManager:SetFolder("SoccerHub")
    InterfaceManager:BuildInterfaceSection(Tabs.Interface)
else
    Tabs.Interface:AddParagraph({
        Title = "INTERFACE INDISPONIBLE",
        Content = "InterfaceManager n'a pas chargé.\nErreur InterfaceManager : " .. tostring(interfaceErr)
    })
end

Tabs.Console:AddButton({
    Title = "Copier console",
    Description = "Copie tous les logs.",
    Icon = "lucide/copy",
    Callback = function()
        if setclipboard then
            setclipboard(table.concat(logs, "\n"))
            Log("Console copiée.", "[SYSTEM]")
        else
            Log("setclipboard indisponible.", "[WARN]")
        end
    end
})

Tabs.Console:AddButton({
    Title = "Nettoyer console",
    Description = "Vide la console visible.",
    Icon = "lucide/trash",
    Callback = function()
        logs = {}
        RefreshConsole()
        Log("Console nettoyée.", "[SYSTEM]")
    end
})

Tabs.Console:AddButton({
    Title = "Debug Anti-AFK",
    Description = "Affiche la dernière méthode Anti-AFK utilisée.",
    Icon = "lucide/search",
    Callback = function()
        Log("===== DEBUG ANTI-AFK =====", "[DEBUG]")
        Log("AntiAFK = " .. tostring(antiAfkEnabled), "[DEBUG]")
        Log("Délai Anti-AFK = " .. tostring(antiAfkMoveDelay), "[DEBUG]")
        Log("VirtualUser = " .. tostring(antiAfkVirtualUserEnabled), "[DEBUG]")
        Log("VirtualKey = " .. tostring(antiAfkVirtualKeyEnabled), "[DEBUG]")
        Log("VirtualMouse = " .. tostring(antiAfkVirtualMouseEnabled), "[DEBUG]")
        Log("RealMove = " .. tostring(antiAfkRealMoveEnabled), "[DEBUG]")
        Log("Dernière méthode = " .. tostring(lastAntiAfkMethod), "[DEBUG]")
        Log("Dernier état = " .. tostring(lastAfkStatus), "[DEBUG]")
        Log("Index méthode = " .. tostring(antiAfkMethodIndex), "[DEBUG]")
        Log("===== FIN DEBUG ANTI-AFK =====", "[DEBUG]")
    end
})

Tabs.Console:AddButton({
    Title = "Test Anti-AFK maintenant",
    Description = "Lance une méthode Anti-AFK immédiatement.",
    Icon = "lucide/play",
    Callback = function()
        RunAntiAfkRotatingMethod()
    end
})

Tabs.Console:AddButton({
    Title = "Debug SpinWheel",
    Description = "Affiche les dernières données SpinWheel.",
    Icon = "lucide/search",
    Callback = function()
        Log("===== DEBUG SPINWHEEL =====", "[DEBUG]")
        Log("AutoClaim = " .. tostring(autoClaimSpinEnabled), "[DEBUG]")
        Log("AutoSpin = " .. tostring(autoSpinEnabled), "[DEBUG]")
        Log("lastClaimBeforeSpins = " .. tostring(lastClaimBeforeSpins), "[DEBUG]")
        Log("lastClaimedSpinClock delta = " .. tostring(os.clock() - lastClaimedSpinClock), "[DEBUG]")

        if type(lastSpinData) == "table" then
            Log("spins = " .. tostring(lastSpinData.spins), "[DEBUG]")
            Log("canClaimFree = " .. tostring(lastSpinData.canClaimFree), "[DEBUG]")
            Log("timeRemaining = " .. tostring(lastSpinData.timeRemaining), "[DEBUG]")
        else
            Log("lastSpinData invalide = " .. tostring(lastSpinData), "[DEBUG]")
        end

        Log("lastSpinStatus = " .. tostring(lastSpinStatus), "[DEBUG]")
        Log("===== FIN DEBUG SPINWHEEL =====", "[DEBUG]")
    end
})

ConsoleParagraph = Tabs.Console:AddParagraph({
    Title = "Console",
    Content = "Aucun log."
})

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
