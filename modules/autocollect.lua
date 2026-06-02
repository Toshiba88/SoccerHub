--//====================================================
--// Soccer Hub - autocollect.lua
--// Fichier généré par découpage depuis soccer_hub_v33_index_order_fixed.lua
--// Chaque champ contient une partie réelle du script original.
--//====================================================

return {
    logic = [====================[
local function TryCollectMoney()
    RefreshRemotes()

    if not CollectSlotRemote then
        Log("CollectSlot introuvable.", "[ERROR]")
        return
    end

    Log("Collect money slots 1 -> " .. tostring(collectMaxSlots), "[COLLECT]")

    for slot = 1, collectMaxSlots do
        if not autoCollectEnabled or not IsCurrentRun() then
            break
        end

        local ok, result = FireRemote(CollectSlotRemote, slot)

        if not ok then
            Log("CollectSlot " .. tostring(slot) .. " erreur : " .. tostring(result), "[COLLECT]")
        end

        task.wait(0.03)
    end
end

local function AutoCollectLoop()
    task.spawn(function()
        while IsCurrentRun() do
            if autoCollectEnabled then
                TryCollectMoney()
            end

            task.wait(math.max(1, collectDelay))
        end
    end)
end

]====================],

    ui = [====================[
local AutoCollectToggle = Tabs.Collect:AddToggle("AutoCollectToggle", {
    Title = "AutoCollect Money",
    Default = false
})

AutoCollectToggle:OnChanged(function()
    autoCollectEnabled = Options.AutoCollectToggle.Value
    Log("AutoCollect = " .. tostring(autoCollectEnabled), "[SYSTEM]")
    UpdateStatus()
end)

Tabs.Collect:AddInput("CollectDelayInput", {
    Title = "Délai ramassage",
    Default = tostring(collectDelay),
    Placeholder = "Ex: 5",
    Numeric = true,
    Finished = false,
    Callback = function(value)
        collectDelay = SafeNumber(value, 5, 1, 300)
        Log("Délai collect = " .. tostring(collectDelay) .. "s", "[SYSTEM]")
        UpdateStatus()
    end
})

Tabs.Collect:AddInput("CollectSlotsInput", {
    Title = "Nombre de slots",
    Default = tostring(collectMaxSlots),
    Placeholder = "Ex: 30",
    Numeric = true,
    Finished = false,
    Callback = function(value)
        collectMaxSlots = SafeNumber(value, 30, 1, 200)
        Log("Slots collect = 1 -> " .. tostring(collectMaxSlots), "[SYSTEM]")
        UpdateStatus()
    end
})
]====================],

}
