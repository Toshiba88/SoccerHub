--//====================================================
--// Soccer Hub - config.lua
--// Version SaveManager Fluent Modded corrigée
--// Debug retiré
--//
--// Important :
--// Ce module continue le if ouvert à la fin de modules/antiafk.lua :
--// if saveOk and SaveManager then
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