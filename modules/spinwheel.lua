--//====================================================
--// Soccer Hub - spinwheel.lua
--// Fichier généré par découpage depuis soccer_hub_v33_index_order_fixed.lua
--// Chaque champ contient une partie réelle du script original.
--//====================================================

return {
    logic = [====================[
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

]====================],

    ui = [====================[
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
]====================],

}
