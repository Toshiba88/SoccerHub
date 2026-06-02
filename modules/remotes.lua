--//====================================================
--// Soccer Hub - remotes.lua
--// Fichier généré par découpage depuis soccer_hub_v33_index_order_fixed.lua
--// Chaque champ contient une partie réelle du script original.
--//====================================================

return {
    logic = [====================[
local function RefreshRemotes()
    Remotes = ReplicatedStorage:FindFirstChild("Remotes")

    if Remotes then
        BuyPackRemote = Remotes:FindFirstChild("BuyPack")
        CollectSlotRemote = Remotes:FindFirstChild("CollectSlot")
        SpinWheelRemote = Remotes:FindFirstChild("SpinWheel")
        SpinWheelDataRemote = Remotes:FindFirstChild("SpinWheelData")
    end
end

local function FireRemote(remote, ...)
    if not remote then
        return false, "Remote introuvable"
    end

    if remote:IsA("RemoteEvent") then
        local ok, err = pcall(function(...)
            remote:FireServer(...)
        end, ...)

        return ok, err
    end

    if remote:IsA("RemoteFunction") then
        local ok, result = pcall(function(...)
            return remote:InvokeServer(...)
        end, ...)

        return ok, result
    end

    return false, "Remote invalide : " .. tostring(remote.ClassName)
end

]====================],

}
