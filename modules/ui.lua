--//====================================================
--// Soccer Hub - ui.lua
--// Fichier généré par découpage depuis soccer_hub_v33_index_order_fixed.lua
--// Chaque champ contient une partie réelle du script original.
--//====================================================

return {
    logic = [====================[
Window = Fluent:CreateWindow({
    Title = "Soccer Hub | Spin a Soccer Card",
    SubTitle = "v33 Index Order Fixed",
    TabWidth = 155,
    Size = UDim2.fromOffset(720, 540),
    Acrylic = false,
    Theme = "AMOLED",
    MinimizeKey = Enum.KeyCode.LeftControl,
    Search = true
})

Tabs.Accueil = Window:AddTab({
    Title = "Accueil",
    Icon = "solar/home-bold"
})

Tabs.AutoBuy = Window:AddTab({
    Title = "AutoBuy",
    Icon = "lucide/shopping-cart"
})

Tabs.Collect = Window:AddTab({
    Title = "AutoCollect",
    Icon = "lucide/coins"
})

Tabs.SpinWheel = Window:AddTab({
    Title = "SpinWheel",
    Icon = "lucide/rotate-cw"
})

Tabs.Tournament = Window:AddTab({
    Title = "Tournament",
    Icon = "lucide/trophy"
})

Tabs.Shop = Window:AddTab({
    Title = "Shop",
    Icon = "solar/shop-bold"
})

Tabs.Index = Window:AddTab({
    Title = "Index",
    Icon = "lucide/list-ordered"
})

Tabs.Settings = Window:AddTab({
    Title = "Réglages",
    Icon = "lucide/settings"
})

Tabs.Config = Window:AddTab({
    Title = "Sauvegarde",
    Icon = "lucide/save"
})

Tabs.Interface = Window:AddTab({
    Title = "Apparence",
    Icon = "lucide/palette"
})

Tabs.Console = Window:AddTab({
    Title = "Console",
    Icon = "lucide/terminal"
})

Options = Fluent.Options

HomeAutomationParagraph = Tabs.Accueil:AddParagraph({
    Title = "AUTOMATISATIONS",
    Content = "Chargement..."
})

InitTournamentModule(Tabs.Tournament)
InitIndexModule(Tabs.Index)

]====================],

}