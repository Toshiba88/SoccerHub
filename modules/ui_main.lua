--//====================================================
--// Soccer Hub - Module UI Main
--// Création de la fenêtre Fluent + onglets principaux
--//====================================================

return function(ctx)
    ctx = ctx or {}

    local Fluent = ctx.Fluent

    if not Fluent then
        error("ui_main.lua : Fluent manquant dans ctx.Fluent")
    end

    local Window = Fluent:CreateWindow({
        Title = "Soccer Hub | Spin a Soccer Card",
        SubTitle = ctx.SubTitle or "modular v1",
        TabWidth = ctx.TabWidth or 155,
        Size = ctx.Size or UDim2.fromOffset(720, 540),
        Acrylic = false,
        Theme = ctx.Theme or "AMOLED",
        MinimizeKey = ctx.MinimizeKey or Enum.KeyCode.LeftControl,
        Search = true
    })

    local Tabs = {}

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

    return {
        Window = Window,
        Tabs = Tabs,
        Options = Fluent.Options
    }
end
