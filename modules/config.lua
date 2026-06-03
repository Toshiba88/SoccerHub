--//====================================================
--// Soccer Hub - config.lua
--// Fichier généré par découpage depuis soccer_hub_v33_index_order_fixed.lua
--// Revert safe : évite l'erreur Out of local registers
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