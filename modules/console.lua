--//====================================================
--// Soccer Hub - Module Console
--// Onglet console + boutons debug génériques
--//====================================================

return function(ctx)
    ctx = ctx or {}

    local Tabs = ctx.Tabs or {}
    local Core = ctx.Core
    local Log = ctx.Log or function(text, prefix)
        print(tostring(prefix or "[CONSOLE]") .. " " .. tostring(text))
    end

    local Console = {}

    function Console.Init()
        if not Tabs.Console then
            Log("ConsoleTab introuvable.", "[CONSOLE]")
            return Console
        end

        Tabs.Console:AddButton({
            Title = "Copier console",
            Description = "Copie tous les logs.",
            Icon = "lucide/copy",
            Callback = function()
                if Core and Core.CopyLogs then
                    Core.CopyLogs()
                elseif setclipboard and ctx.logs then
                    setclipboard(table.concat(ctx.logs, "\n"))
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
                if Core and Core.ClearLogs then
                    Core.ClearLogs()
                else
                    Log("ClearLogs indisponible.", "[WARN]")
                end
            end
        })

        Tabs.Console:AddButton({
            Title = "Debug modules",
            Description = "Affiche les modules chargés.",
            Icon = "lucide/search",
            Callback = function()
                Log("===== DEBUG MODULES =====", "[DEBUG]")
                Log("Core = " .. tostring(ctx.Core ~= nil), "[DEBUG]")
                Log("Remotes = " .. tostring(ctx.Remotes ~= nil), "[DEBUG]")
                Log("IndexApi = " .. tostring(ctx.IndexApi ~= nil), "[DEBUG]")
                Log("TournamentApi = " .. tostring(ctx.TournamentApi ~= nil), "[DEBUG]")
                Log("SpinWheelApi = " .. tostring(ctx.SpinWheelApi ~= nil), "[DEBUG]")
                Log("AutoBuyApi = " .. tostring(ctx.AutoBuyApi ~= nil), "[DEBUG]")
                Log("AutoCollectApi = " .. tostring(ctx.AutoCollectApi ~= nil), "[DEBUG]")
                Log("AntiAfkApi = " .. tostring(ctx.AntiAfkApi ~= nil), "[DEBUG]")
                Log("===== FIN DEBUG MODULES =====", "[DEBUG]")
            end
        })

        local paragraph = Tabs.Console:AddParagraph({
            Title = "Console",
            Content = "Aucun log."
        })

        Console.Paragraph = paragraph

        if Core and Core.SetConsoleParagraph then
            Core.SetConsoleParagraph(paragraph)
        end

        return Console
    end

    return Console.Init()
end
