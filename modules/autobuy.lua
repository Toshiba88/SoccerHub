--//====================================================
--// Soccer Hub - autobuy.lua
--// Fichier généré par découpage depuis soccer_hub_v33_index_order_fixed.lua
--// Chaque champ contient une partie réelle du script original.
--//====================================================

return {
    logic = [====================[
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

]====================],

    restock = [====================[
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
]====================],

    ui = [====================[
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

]====================],

}
