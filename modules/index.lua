--//====================================================
--// Soccer Hub - Module Index
--// Extrait depuis soccer_hub_v33_index_order_fixed.lua
--// Entrée : return function(ctx)
--//====================================================

return function(ctx)
    ctx = ctx or {}

    local ReplicatedStorage = ctx.ReplicatedStorage or game:GetService("ReplicatedStorage")
    local Log = ctx.Log or function(text, prefix)
        print(tostring(prefix or "[INDEX]") .. " " .. tostring(text))
    end
    local SetParagraph = ctx.SetParagraph or function(paragraph, title, content)
        if not paragraph then return end
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
    local AddConnection = ctx.AddConnection or function() end
    local Tabs = ctx.Tabs or {}

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

    local IndexTab = ctx.IndexTab or Tabs.Index
    InitIndexModule(IndexTab)

    return {
        Reload = IndexReloadData,
        Refresh = IndexRefreshRanking,
        GetReport = function()
            return indexLastReport
        end,
        GetCards = function()
            return indexCards
        end,
        GetMutations = function()
            return indexMutations
        end,
        GetTrophies = function()
            return indexTrophies
        end
    }
end
