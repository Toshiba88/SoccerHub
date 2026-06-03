--//====================================================
--// Soccer Hub - config.lua
--// Fichier généré par découpage depuis soccer_hub_v33_index_order_fixed.lua
--// Fix : création forcée du dossier config avant BuildConfigSection
--//====================================================

return {
    ui = [====================[
local CONFIG_ROOT_FOLDER = "SoccerHub"
local CONFIG_FOLDER = "SoccerHub/SpinASoccerCard"

local function EnsureConfigFolder()
    local ok = true

    if type(isfolder) == "function" and type(makefolder) == "function" then
        local rootExists = false
        pcall(function()
            rootExists = isfolder(CONFIG_ROOT_FOLDER)
        end)

        if not rootExists then
            local makeOk = pcall(function()
                makefolder(CONFIG_ROOT_FOLDER)
            end)
            ok = ok and makeOk
        end

        local folderExists = false
        pcall(function()
            folderExists = isfolder(CONFIG_FOLDER)
        end)

        if not folderExists then
            local makeOk = pcall(function()
                makefolder(CONFIG_FOLDER)
            end)
            ok = ok and makeOk
        end
    else
        ok = false
    end

    return ok
end

local configFolderOk = EnsureConfigFolder()

if type(Log) == "function" then
    Log("Dossier config préparé : " .. tostring(CONFIG_FOLDER) .. " | ok=" .. tostring(configFolderOk), "[CONFIG]")
end

    SaveManager:SetIgnoreIndexes({})
    SaveManager:SetFolder(CONFIG_FOLDER)
    SaveManager:BuildConfigSection(Tabs.Config)

    Tabs.Config:AddButton({
        Title = "Debug dossier config",
        Description = "Copie/liste les fichiers de config visibles par l'executor.",
        Icon = "lucide/folder-search",
        Callback = function()
            local report = {}
            table.insert(report, "====================================================")
            table.insert(report, "SOCCER HUB CONFIG DEBUG")
            table.insert(report, "Folder : " .. tostring(CONFIG_FOLDER))
            table.insert(report, "isfolder = " .. tostring(type(isfolder)))
            table.insert(report, "makefolder = " .. tostring(type(makefolder)))
            table.insert(report, "listfiles = " .. tostring(type(listfiles)))
            table.insert(report, "writefile = " .. tostring(type(writefile)))
            table.insert(report, "readfile = " .. tostring(type(readfile)))
            table.insert(report, "")

            if type(isfolder) == "function" then
                local okRoot, rootResult = pcall(function()
                    return isfolder(CONFIG_ROOT_FOLDER)
                end)
                local okFolder, folderResult = pcall(function()
                    return isfolder(CONFIG_FOLDER)
                end)

                table.insert(report, "Root exists : " .. tostring(okRoot and rootResult))
                table.insert(report, "Folder exists : " .. tostring(okFolder and folderResult))
            end

            if type(listfiles) == "function" then
                local okList, files = pcall(function()
                    return listfiles(CONFIG_FOLDER)
                end)

                table.insert(report, "")
                table.insert(report, "listfiles ok : " .. tostring(okList))

                if okList and type(files) == "table" then
                    table.insert(report, "files count : " .. tostring(#files))
                    for i, filePath in ipairs(files) do
                        table.insert(report, "[" .. tostring(i) .. "] " .. tostring(filePath))
                    end
                else
                    table.insert(report, "listfiles result : " .. tostring(files))
                end
            else
                table.insert(report, "listfiles indisponible")
            end

            table.insert(report, "====================================================")

            local text = table.concat(report, "\n")

            if type(Log) == "function" then
                Log(text, "[CONFIG]")
            else
                print(text)
            end

            if setclipboard then
                setclipboard(text)
            end
        end
    })
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