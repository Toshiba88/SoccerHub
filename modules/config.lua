--//====================================================
--// Soccer Hub - config.lua
--// Version SaveManager Fluent Modded corrigée
--//
--// Important :
--// Ce module continue le if ouvert à la fin de modules/antiafk.lua :
--// if saveOk and SaveManager then
--//
--// Correction :
--// - utilise SaveManager:RefreshConfigList()
--// - garde une vraie référence directe au dropdown
--// - évite de dépendre uniquement de SaveManager.Options.SaveManager_ConfigList
--// - évite les gros blocs local au top-level pour ne pas refaire "Out of local registers"
--//====================================================

return {
    ui = [====================[
    SaveManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({
        "SaveManager_NewName",
        "SaveManager_ConfigList",
        "SaveManager_ConfigName"
    })

    SaveManager:SetFolder("SoccerHub/SpinASoccerCard")

    _G.__SOCCER_HUB_CONFIG_SECTION = Tabs.Config:AddSection("Configuration")

    _G.__SOCCER_HUB_CONFIG_SECTION:AddInput("SaveManager_NewName", {
        Title = "Config name",
        Placeholder = "Ex: main"
    })

    _G.__SOCCER_HUB_CONFIG_DROPDOWN = _G.__SOCCER_HUB_CONFIG_SECTION:AddDropdown("SaveManager_ConfigList", {
        Title = "Config list",
        Values = SaveManager:RefreshConfigList(),
        Multi = false,
        AllowNull = true,
        Default = nil
    })

    _G.__SOCCER_HUB_CONFIG_SECTION:AddButton({
        Title = "Create config",
        Description = "Créer une nouvelle config avec le nom écrit.",
        Callback = function()
            local name = ""

            pcall(function()
                if SaveManager.Options and SaveManager.Options.SaveManager_NewName then
                    name = SaveManager.Options.SaveManager_NewName.Value
                elseif Options and Options.SaveManager_NewName then
                    name = Options.SaveManager_NewName.Value
                end
            end)

            name = tostring(name or "")
            name = name:gsub("^%s+", "")
            name = name:gsub("%s+$", "")

            if name:gsub(" ", "") == "" then
                Fluent:Notify({
                    Title = "Config",
                    Content = "Nom de config vide.",
                    Duration = 5
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
                Duration = 5
            })

            if type(Log) == "function" then
                Log("Config créée : " .. tostring(name), "[CONFIG]")
            end

            task.wait(0.15)

            pcall(function()
                _G.__SOCCER_HUB_CONFIG_DROPDOWN:SetValues(SaveManager:RefreshConfigList())
                _G.__SOCCER_HUB_CONFIG_DROPDOWN:SetValue(name)
            end)
        end
    })

    _G.__SOCCER_HUB_CONFIG_SECTION:AddButton({
        Title = "Refresh list",
        Description = "Recharge la liste des configs.",
        Callback = function()
            pcall(function()
                _G.__SOCCER_HUB_CONFIG_DROPDOWN:SetValues(SaveManager:RefreshConfigList())
                _G.__SOCCER_HUB_CONFIG_DROPDOWN:SetValue(nil)
            end)

            if type(Log) == "function" then
                local list = SaveManager:RefreshConfigList()
                Log("Refresh config list : " .. tostring(#list) .. " config(s)", "[CONFIG]")
            end
        end
    })

    _G.__SOCCER_HUB_CONFIG_SECTION:AddButton({
        Title = "Load config",
        Description = "Charge la config sélectionnée.",
        Callback = function()
            local name = nil

            pcall(function()
                name = _G.__SOCCER_HUB_CONFIG_DROPDOWN.Value
            end)

            if not name or tostring(name) == "" then
                Fluent:Notify({
                    Title = "Config",
                    Content = "Aucune config sélectionnée.",
                    Duration = 5
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
                    Log("Erreur SaveManager:Load(" .. tostring(name) .. ") = " .. tostring(err), "[CONFIG]")
                end

                return
            end

            Fluent:Notify({
                Title = "Config",
                Content = "Config chargée : " .. tostring(name),
                Duration = 5
            })

            if type(Log) == "function" then
                Log("Config chargée : " .. tostring(name), "[CONFIG]")
            end
        end
    })

    _G.__SOCCER_HUB_CONFIG_SECTION:AddButton({
        Title = "Overwrite config",
        Description = "Écrase la config sélectionnée.",
        Callback = function()
            local name = nil

            pcall(function()
                name = _G.__SOCCER_HUB_CONFIG_DROPDOWN.Value
            end)

            if not name or tostring(name) == "" then
                Fluent:Notify({
                    Title = "Config",
                    Content = "Aucune config sélectionnée.",
                    Duration = 5
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
                Duration = 5
            })

            if type(Log) == "function" then
                Log("Config écrasée : " .. tostring(name), "[CONFIG]")
            end

            task.wait(0.15)

            pcall(function()
                _G.__SOCCER_HUB_CONFIG_DROPDOWN:SetValues(SaveManager:RefreshConfigList())
                _G.__SOCCER_HUB_CONFIG_DROPDOWN:SetValue(name)
            end)
        end
    })

    _G.__SOCCER_HUB_CONFIG_SECTION:AddButton({
        Title = "Set as autoload",
        Description = "Charge automatiquement la config sélectionnée au prochain lancement.",
        Callback = function()
            local name = nil

            pcall(function()
                name = _G.__SOCCER_HUB_CONFIG_DROPDOWN.Value
            end)

            if not name or tostring(name) == "" then
                Fluent:Notify({
                    Title = "Config",
                    Content = "Aucune config sélectionnée.",
                    Duration = 5
                })
                return
            end

            pcall(function()
                writefile(SaveManager.Folder .. "/settings/autoload.txt", tostring(name))
            end)

            Fluent:Notify({
                Title = "Config",
                Content = "Autoload défini : " .. tostring(name),
                Duration = 5
            })

            if type(Log) == "function" then
                Log("Autoload défini : " .. tostring(name), "[CONFIG]")
            end
        end
    })

    _G.__SOCCER_HUB_CONFIG_SECTION:AddButton({
        Title = "Debug config folder",
        Description = "Copie le rapport du dossier config.",
        Callback = function()
            local report = {}

            table.insert(report, "====================================================")
            table.insert(report, "SOCCER HUB CONFIG DEBUG")
            table.insert(report, "Folder = " .. tostring(SaveManager.Folder))
            table.insert(report, "Settings = " .. tostring(SaveManager.Folder .. "/settings"))
            table.insert(report, "isfolder = " .. tostring(type(isfolder)))
            table.insert(report, "makefolder = " .. tostring(type(makefolder)))
            table.insert(report, "listfiles = " .. tostring(type(listfiles)))
            table.insert(report, "writefile = " .. tostring(type(writefile)))
            table.insert(report, "readfile = " .. tostring(type(readfile)))
            table.insert(report, "")

            pcall(function()
                table.insert(report, "Folder exists = " .. tostring(isfolder(SaveManager.Folder)))
                table.insert(report, "Settings exists = " .. tostring(isfolder(SaveManager.Folder .. "/settings")))
            end)

            table.insert(report, "")
            table.insert(report, "SaveManager:RefreshConfigList():")

            local okRefresh, configList = pcall(function()
                return SaveManager:RefreshConfigList()
            end)

            table.insert(report, "refresh ok = " .. tostring(okRefresh))

            if okRefresh and type(configList) == "table" then
                table.insert(report, "config count = " .. tostring(#configList))

                for i, name in ipairs(configList) do
                    table.insert(report, "[" .. tostring(i) .. "] " .. tostring(name))
                end
            else
                table.insert(report, "refresh result = " .. tostring(configList))
            end

            table.insert(report, "")
            table.insert(report, "Raw listfiles:")

            if type(listfiles) == "function" then
                local okList, files = pcall(function()
                    return listfiles(SaveManager.Folder .. "/settings")
                end)

                table.insert(report, "listfiles ok = " .. tostring(okList))

                if okList and type(files) == "table" then
                    table.insert(report, "files count = " .. tostring(#files))

                    for i, filePath in ipairs(files) do
                        table.insert(report, "[" .. tostring(i) .. "] " .. tostring(filePath))
                    end
                else
                    table.insert(report, "files = " .. tostring(files))
                end
            else
                table.insert(report, "listfiles indisponible")
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
                Duration = 5
            })
        end
    })

    task.delay(0.3, function()
        pcall(function()
            _G.__SOCCER_HUB_CONFIG_DROPDOWN:SetValues(SaveManager:RefreshConfigList())
        end)
    end)

    task.delay(0.8, function()
        pcall(function()
            SaveManager:LoadAutoloadConfig()
        end)
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
