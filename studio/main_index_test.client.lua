--//====================================================
--// Soccer Hub - Test modulaire Index uniquement
--// Usage Studio : LocalScript de test client-side
--//
--// Pré-requis :
--// - Fluent disponible dans _G.Fluent ou shared.Fluent
--// - modules/core.lua, modules/ui_main.lua, modules/index.lua copiés en ModuleScripts
--//   dans le même dossier que ce script, sous un Folder nommé "modules".
--//====================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local modulesFolder = script:WaitForChild("modules")

local Fluent = rawget(_G, "Fluent") or rawget(shared, "Fluent")

if not Fluent then
    warn("[SoccerHub Modular Test] Fluent manquant. Mets Fluent dans _G.Fluent ou shared.Fluent avant de lancer ce test.")
    return
end

local CoreFactory = require(modulesFolder:WaitForChild("core"))
local UIMainFactory = require(modulesFolder:WaitForChild("ui_main"))
local IndexModule = require(modulesFolder:WaitForChild("index"))

local connections = {}
local logs = {}

local ctx = {
    Fluent = Fluent,
    ReplicatedStorage = ReplicatedStorage,
    player = player,
    playerGui = playerGui,
    connections = connections,
    logs = logs,
    SubTitle = "modular test index",
    Theme = "AMOLED"
}

local Core = CoreFactory(ctx)

ctx.Core = Core
ctx.Log = Core.Log
ctx.SetParagraph = Core.SetParagraph
ctx.AddConnection = Core.AddConnection
ctx.SafeFullName = Core.SafeFullName
ctx.SafeNumber = Core.SafeNumber
ctx.StatusDot = Core.StatusDot
ctx.FormatTime = Core.FormatTime

local ui = UIMainFactory(ctx)
ctx.Window = ui.Window
ctx.Tabs = ui.Tabs
ctx.Options = ui.Options

local homeParagraph = ctx.Tabs.Accueil:AddParagraph({
    Title = "TEST MODULAIRE",
    Content = "Index extrait chargé en module séparé.\nLes autres onglets sont présents mais non branchés dans ce test."
})

local consoleParagraph = ctx.Tabs.Console:AddParagraph({
    Title = "Console",
    Content = "Aucun log."
})

Core.SetConsoleParagraph(consoleParagraph)

ctx.Tabs.Console:AddButton({
    Title = "Copier console",
    Description = "Copie tous les logs du test.",
    Callback = function()
        Core.CopyLogs()
    end
})

ctx.Tabs.Console:AddButton({
    Title = "Nettoyer console",
    Description = "Vide la console du test.",
    Callback = function()
        Core.ClearLogs()
    end
})

local indexApi = IndexModule(ctx)
ctx.IndexApi = indexApi

ctx.Window:SelectTab(1)

Core.Log("Soccer Hub modular test lancé.", "[SYSTEM]")
Core.Log("Index chargé depuis modules/index.lua.", "[SYSTEM]")
Core.Log("Cartes chargées = " .. tostring(#indexApi.GetCards()), "[INDEX]")
Core.Log("Mutations chargées = " .. tostring(#indexApi.GetMutations()), "[INDEX]")
Core.Log("Trophées chargés = " .. tostring(#indexApi.GetTrophies()), "[INDEX]")

return ctx
