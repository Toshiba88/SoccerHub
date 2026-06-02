--//====================================================
--// Soccer Hub - Module Core
--// Fonctions communes extraites de la v33
--//====================================================

return function(ctx)
    ctx = ctx or {}

    local Core = {}

    Core.logs = ctx.logs or {}
    Core.connections = ctx.connections or {}
    Core.maxConsoleLines = ctx.maxConsoleLines or 180
    Core.maxLogStorage = ctx.maxLogStorage or 1200
    Core.runId = ctx.runId or tostring(os.clock()) .. "_" .. tostring(math.random(100000, 999999))

    function Core.IsCurrentRun()
        if ctx.isCurrentRun then
            return ctx.isCurrentRun()
        end

        return true
    end

    function Core.AddConnection(conn)
        if conn then
            table.insert(Core.connections, conn)
        end
    end

    function Core.DisconnectAll()
        for _, conn in ipairs(Core.connections) do
            pcall(function()
                conn:Disconnect()
            end)
        end

        Core.connections = {}
    end

    function Core.SafeFullName(obj)
        local ok, result = pcall(function()
            return obj:GetFullName()
        end)

        if ok then
            return result
        end

        return tostring(obj)
    end

    function Core.SafeNumber(text, defaultValue, minValue, maxValue)
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

    function Core.StatusDot(value)
        return value and "🟢" or "🔴"
    end

    function Core.FormatTime(seconds)
        seconds = tonumber(seconds) or 0

        if seconds <= 0 then
            return "MAINTENANT"
        end

        local minutes = math.floor(seconds / 60)
        local secs = seconds % 60

        return tostring(minutes) .. "M " .. tostring(secs) .. "S"
    end

    function Core.SetParagraph(paragraph, title, content)
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

    function Core.SetConsoleParagraph(paragraph)
        Core.consoleParagraph = paragraph
    end

    function Core.RefreshConsole()
        if not Core.consoleParagraph then
            return
        end

        local startIndex = math.max(1, #Core.logs - Core.maxConsoleLines + 1)
        local visible = {}

        for i = startIndex, #Core.logs do
            table.insert(visible, Core.logs[i])
        end

        if #visible == 0 then
            Core.SetParagraph(Core.consoleParagraph, "Console", "Aucun log.")
        else
            Core.SetParagraph(Core.consoleParagraph, "Console", table.concat(visible, "\n"))
        end
    end

    function Core.Log(text, prefix)
        local cleanPrefix = prefix or "[INFO]"
        local msg = os.date("[%H:%M:%S] ") .. cleanPrefix .. " " .. tostring(text)

        table.insert(Core.logs, msg)

        if #Core.logs > Core.maxLogStorage then
            local removeCount = #Core.logs - Core.maxLogStorage

            for _ = 1, removeCount do
                table.remove(Core.logs, 1)
            end
        end

        print(msg)
        Core.RefreshConsole()
    end

    function Core.Notify(Fluent, title, content, duration)
        pcall(function()
            Fluent:Notify({
                Title = tostring(title),
                Content = tostring(content),
                Duration = duration or 5
            })
        end)
    end

    function Core.CopyLogs()
        if setclipboard then
            setclipboard(table.concat(Core.logs, "\n"))
            Core.Log("Console copiée.", "[SYSTEM]")
            return true
        end

        Core.Log("setclipboard indisponible.", "[WARN]")
        return false
    end

    function Core.ClearLogs()
        Core.logs = {}
        Core.RefreshConsole()
        Core.Log("Console nettoyée.", "[SYSTEM]")
    end

    return Core
end
