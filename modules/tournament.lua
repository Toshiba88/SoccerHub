--//====================================================
--// Soccer Hub - tournament.lua
--// Fichier généré par découpage depuis soccer_hub_v33_index_order_fixed.lua
--// Chaque champ contient une partie réelle du script original.
--//====================================================

return {
    logic = [====================[
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
]====================],

}
