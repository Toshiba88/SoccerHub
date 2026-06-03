--//====================================================
--// Soccer Hub - config.lua
--// Version custom config manager
--// Important :
--// Ce module continue le if ouvert à la fin de modules/antiafk.lua :
--// if saveOk and SaveManager then
--//====================================================

return {
    ui = [====================[
    SaveManager:SetFolder("SoccerHub/SpinASoccerCard")

    pcall(function()
        SaveManager:BuildFolderTree()
    end)

    SaveManager:SetIgnoreIndexes({
        "SoccerHubConfigName",
        "SoccerHubConfigList"
    })

    _G.__SOCCER_HUB_CONFIG = _G.__SOCCER_HUB_CONFIG or {}
    _G.__SOCCER_HUB_CONFIG.Folder = "SoccerHub/SpinASoccerCard"
    _G.__SOCCER_HUB_CONFIG.SettingsFolder = "SoccerHub/SpinASoccerCard/settings"

    _G.__SOCCER_HUB_CONFIG.GetName = function()
        local value = ""

        pcall(function()
            if Options and Options.SoccerHubConfigName then
                value = Options.SoccerHubConfigName.Value
            end
        end)

        value = tostring(value or "")
        value = value:gsub("^%s+", "")
        value = value:gsub("%s+$", "")

        return value
    end

    _G.__SOCCER_HUB_CONFIG.List = function()
        local out = {}

        pcall(function()
            if type(isfolder) == "function" and type(makefolder) == "function" then
                if not isfolder(_G.__SOCCER_HUB_CONFIG.Folder) then
                    makefolder(_G.__SOCCER_HUB_CONFIG.Folder)
                end

                if not isfolder(_G.__SOCCER_HUB_CONFIG.SettingsFolder) then
                    makefolder(_G.__SOCCER_HUB_CONFIG.SettingsFolder)
                end
            end
        end)

        if type(listfiles) ~= "function" then
            return out
        end

        local ok, files = pcall(function()
            return listfiles(_G.__SOCCER_HUB_CONFIG.SettingsFolder)
        end)

        if not ok or type(files) ~= "table" then
            return out
        end

        for _, filePath in ipairs(files) do
            filePath = tostring(filePath)

            if filePath:sub(-5) == ".json" then
                local name = filePath:match("([^/\\]+)%.json$")

                if name and name ~= "options" and name ~= "autoload" then
                    table.insert(out, name)
                end
            end
        end

        table.sort(out)
        return out
    end

    _G.__SOCCER_HUB_CONFIG.Refresh = function()
        local list = _G.__SOCCER_HUB_CONFIG.List()

        if _G.__SOCCER_HUB_CONFIG.Dropdown then
            pcall(function()
                _G.__SOCCER_HUB_CONFIG.Dropdown:SetValues(list)
            end)

            pcall(function()
                _G.__SOCCER_HUB_CONFIG.Dropdown:SetValue(nil)
            end)
        end

        if type(Log) == "function" then
            Log("Config list refresh : " .. tostring(#list) .. " config(s)", "[CONFIG]")
        end

        return list
    end

    _G.__SOCCER_HUB_CONFIG.Selected = function()
        local value = nil

        pcall(function()
            if Options and Options.SoccerHubConfigList then
                value = Options.SoccerHubConfigList.Value
            end
        end)

        if type(value) == "table" then
            value = value[1]
        end

        return value
    end

    Tabs.Config:AddParagraph({
        Title = "CONFIG",
        Content = "Gestion config custom Soccer Hub.\nSi une config n'apparaît pas, clique Refresh list."
    })

    _G.__SOCCER_HUB_CONFIG.Input = Tabs.Config:AddInput("SoccerHubConfigName", {
        Title = "Config name",
        Default = "",
        Placeholder = "Ex: main",
        Numeric = false,
        Finished = false,
        Callback = function(value)
            if type(Log) == "function" then
                Log("Config name = " .. tostring(value), "[CONFIG]")
            end
        end
    })

    _G.__SOCCER_HUB_CONFIG.Dropdown = Tabs.Config:AddDropdown("SoccerHubConfigList", {
        Title = "Config list",
        Values = _G.__SOCCER_HUB_CONFIG.List(),
        Multi = false,
        AllowNull = true,
        Default = nil
    })

    Tabs.Config:AddButton({
        Title = "Create config",
        Description = "Sauvegarde la config avec le nom écrit.",
        Icon = "lucide/save",
        Callback = function()
            local name = _G.__SOCCER_HUB_CONFIG.GetName()

            if name == "" then
                Fluent:Notify({
                    Title = "Config",
                    Content = "Nom de config vide.",
                    Duration = 4
                })
                return
            end

            local success, err = SaveManager:Save(name)

            if not success then
                Fluent:Notify({
                    Title = "Config",
                    Content = "Erreur sauvegarde : " .. tostring(err),
                    Duration = 6
                })

                if type(Log) == "function" then
                    Log("Erreur SaveManager:Save(" .. tostring(name) .. ") = " .. tostring(err), "[CONFIG]")
                end

                return
            end

            Fluent:Notify({
                Title = "Config",
                Content = "Config créée : " .. tostring(name),
                Duration = 4
            })

            if type(Log) == "function" then
                Log("Config créée : " .. tostring(name), "[CONFIG]")
            end

            task.wait(0.15)
            _G.__SOCCER_HUB_CONFIG.Refresh()
        end
    })

    Tabs.Config:AddButton({
        Title = "Refresh list",
        Description = "Recharge la liste des configs.",
        Icon = "lucide/refresh-cw",
        Callback = function()
            local list = _G.__SOCCER_HUB_CONFIG.Refresh()

            Fluent:Notify({
                Title = "Config",
                Content = tostring(#list) .. " config(s) trouvée(s).",
                Duration = 4
            })
        end
    })

    Tabs.Config:AddButton({
        Title = "Load config",
        Description = "Charge la config sélectionnée.",
        Icon = "lucide/download",
        Callback = function()
            local name = _G.__SOCCER_HUB_CONFIG.Selected()

            if not name or tostring(name) == "" then
                Fluent:Notify({
                    Title = "Config",
                    Content = "Aucune config sélectionnée.",
                    Duration = 4
                })
                return
            end

            local success, err = SaveManager:Load(name)

            if not success then
                Fluent:Notify({
                    Title = "Config",
                    Content = "Erreur chargement : " .. tostring(err),
                    Duration = 6
                })

                if type(Log) == "function" then
                    Log("Erreur Load(" .. tostring(name) .. ") = " .. tostring(err), "[CONFIG]")
                end

                return
            end

            Fluent:Notify({
                Title = "Config",
                Content = "Config chargée : " .. tostring(name),
                Duration = 4
            })

            if type(Log) == "function" then
                Log("Config chargée : " .. tostring(name), "[CONFIG]")
            end
        end
    })

    Tabs.Config:AddButton({
        Title = "Overwrite config",
        Description = "Écrase la config sélectionnée.",
        Icon = "lucide/save-all",
        Callback = function()
            local name = _G.__SOCCER_HUB_CONFIG.Selected()

            if not name or tostring(name) == "" then
                Fluent:Notify({
                    Title = "Config",
                    Content = "Aucune config sélectionnée.",
                    Duration = 4
                })
                return
            end

            local success, err = SaveManager:Save(name)

            if not success then
                Fluent:Notify({
                    Title = "Config",
                    Content = "Erreur overwrite : " .. tostring(err),
                    Duration = 6
                })
                return
            end

            Fluent:Notify({
                Title = "Config",
                Content = "Config écrasée : " .. tostring(name),
                Duration = 4
            })

            if type(Log) == "function" then
                Log("Config écrasée : " .. tostring(name), "[CONFIG]")
            end

            task.wait(0.15)
            _G.__SOCCER_HUB_CONFIG.Refresh()
        end
    })

    Tabs.Config:AddButton({
        Title = "Set as autoload",
        Description = "Charge automatiquement cette config au prochain lancement.",
        Icon = "lucide/power",
        Callback = function()
            local name = _G.__SOCCER_HUB_CONFIG.Selected()

            if not name or tostring(name) == "" then
                Fluent:Notify({
                    Title = "Config",
                    Content = "Aucune config sélectionnée.",
                    Duration = 4
                })
                return
            end

            pcall(function()
                writefile(_G.__SOCCER_HUB_CONFIG.SettingsFolder .. "/autoload.txt", tostring(name))
            end)

            Fluent:Notify({
                Title = "Config",
                Content = "Autoload défini : " .. tostring(name),
                Duration = 4
            })

            if type(Log) == "function" then
                Log("Autoload défini : " .. tostring(name), "[CONFIG]")
            end
        end
    })

    Tabs.Config:AddButton({
        Title = "Debug config folder",
        Description = "Copie le contenu du dossier config.",
        Icon = "lucide/folder-search",
        Callback = function()
            local report = {}

            table.insert(report, "====================================================")
            table.insert(report, "SOCCER HUB CONFIG DEBUG")
            table.insert(report, "Folder = " .. tostring(_G.__SOCCER_HUB_CONFIG.Folder))
            table.insert(report, "Settings = " .. tostring(_G.__SOCCER_HUB_CONFIG.SettingsFolder))
            table.insert(report, "isfolder = " .. tostring(type(isfolder)))
            table.insert(report, "makefolder = " .. tostring(type(makefolder)))
            table.insert(report, "listfiles = " .. tostring(type(listfiles)))
            table.insert(report, "writefile = " .. tostring(type(writefile)))
            table.insert(report, "readfile = " .. tostring(type(readfile)))
            table.insert(report, "")

            pcall(function()
                table.insert(report, "Folder exists = " .. tostring(isfolder(_G.__SOCCER_HUB_CONFIG.Folder)))
                table.insert(report, "Settings exists = " .. tostring(isfolder(_G.__SOCCER_HUB_CONFIG.SettingsFolder)))
            end)

            table.insert(report, "")
            table.insert(report, "Configs parsed:")

            local parsed = _G.__SOCCER_HUB_CONFIG.List()

            for i, name in ipairs(parsed) do
                table.insert(report, "[" .. tostring(i) .. "] " .. tostring(name))
            end

            if type(listfiles) == "function" then
                table.insert(report, "")
                table.insert(report, "Raw listfiles:")

                local ok, files = pcall(function()
                    return listfiles(_G.__SOCCER_HUB_CONFIG.SettingsFolder)
                end)

                table.insert(report, "listfiles ok = " .. tostring(ok))

                if ok and type(files) == "table" then
                    for i, path in ipairs(files) do
                        table.insert(report, "[" .. tostring(i) .. "] " .. tostring(path))
                    end
                else
                    table.insert(report, "files = " .. tostring(files))
                end
            end

            table.insert(report, "====================================================")

            local text = table.concat(report, "\n")

            if setclipboard then
                setclipboard(text)
            end

            if type(Log) == "function" then
                Log(text, "[CONFIG]")
            else
                print(text)
            end

            Fluent:Notify({
                Title = "Config debug",
                Content = "Rapport copié.",
                Duration = 4
            })
        end
    })

    task.delay(0.3, function()
        _G.__SOCCER_HUB_CONFIG.Refresh()
    end)
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

]====================],

}
