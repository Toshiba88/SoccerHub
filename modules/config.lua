--//====================================================
--// Soccer Hub - config.lua
--// Version safe
--// Important : ne pas ajouter de gros bloc local ici.
--// Ce module continue le if ouvert à la fin de modules/antiafk.lua
--//====================================================

return {
    ui = [====================[
    SaveManager:SetIgnoreIndexes({})
    SaveManager:SetFolder("SoccerHub/SpinASoccerCard")
    SaveManager:BuildConfigSection(Tabs.Config)
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
