--//====================================================
--// Soccer Hub - console.lua
--// Fichier généré par découpage depuis soccer_hub_v33_index_order_fixed.lua
--// Chaque champ contient une partie réelle du script original.
--//====================================================

return {
    ui = [====================[
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

]====================],

}
