--//====================================================
--// Soccer Hub - Module Remotes
--// Gestion centralisée des remotes visibles côté client
--//====================================================

return function(ctx)
    ctx = ctx or {}

    local ReplicatedStorage = ctx.ReplicatedStorage or game:GetService("ReplicatedStorage")
    local Log = ctx.Log or function(text, prefix)
        print(tostring(prefix or "[REMOTE]") .. " " .. tostring(text))
    end
    local SafeFullName = ctx.SafeFullName or function(obj)
        local ok, result = pcall(function()
            return obj:GetFullName()
        end)
        return ok and result or tostring(obj)
    end

    local RemotesModule = {}

    RemotesModule.Remotes = nil
    RemotesModule.BuyPack = nil
    RemotesModule.CollectSlot = nil
    RemotesModule.SpinWheel = nil
    RemotesModule.SpinWheelData = nil
    RemotesModule.Tournament = nil
    RemotesModule.TournamentState = nil

    function RemotesModule.Refresh(silent)
        RemotesModule.Remotes = ReplicatedStorage:FindFirstChild("Remotes")

        if not RemotesModule.Remotes then
            RemotesModule.BuyPack = nil
            RemotesModule.CollectSlot = nil
            RemotesModule.SpinWheel = nil
            RemotesModule.SpinWheelData = nil
            RemotesModule.Tournament = nil
            RemotesModule.TournamentState = nil

            if not silent then
                Log("ReplicatedStorage.Remotes introuvable.", "[REMOTE]")
            end

            return false
        end

        RemotesModule.BuyPack = RemotesModule.Remotes:FindFirstChild("BuyPack")
        RemotesModule.CollectSlot = RemotesModule.Remotes:FindFirstChild("CollectSlot")
        RemotesModule.SpinWheel = RemotesModule.Remotes:FindFirstChild("SpinWheel")
        RemotesModule.SpinWheelData = RemotesModule.Remotes:FindFirstChild("SpinWheelData")
        RemotesModule.Tournament = RemotesModule.Remotes:FindFirstChild("Tournament")
        RemotesModule.TournamentState = RemotesModule.Remotes:FindFirstChild("TournamentState")

        if not silent then
            for name, remote in pairs({
                BuyPack = RemotesModule.BuyPack,
                CollectSlot = RemotesModule.CollectSlot,
                SpinWheel = RemotesModule.SpinWheel,
                SpinWheelData = RemotesModule.SpinWheelData,
                Tournament = RemotesModule.Tournament,
                TournamentState = RemotesModule.TournamentState
            }) do
                if remote then
                    Log(name .. " trouvé : " .. SafeFullName(remote) .. " | " .. tostring(remote.ClassName), "[REMOTE]")
                else
                    Log(name .. " introuvable.", "[WARN]")
                end
            end
        end

        return true
    end

    function RemotesModule.Get(name)
        if not RemotesModule.Remotes then
            RemotesModule.Refresh(true)
        end

        if name == "BuyPack" then return RemotesModule.BuyPack end
        if name == "CollectSlot" then return RemotesModule.CollectSlot end
        if name == "SpinWheel" then return RemotesModule.SpinWheel end
        if name == "SpinWheelData" then return RemotesModule.SpinWheelData end
        if name == "Tournament" then return RemotesModule.Tournament end
        if name == "TournamentState" then return RemotesModule.TournamentState end

        return RemotesModule.Remotes and RemotesModule.Remotes:FindFirstChild(tostring(name)) or nil
    end

    function RemotesModule.Call(remote, ...)
        if type(remote) == "string" then
            remote = RemotesModule.Get(remote)
        end

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

    function RemotesModule.ListKnown()
        return {
            BuyPack = RemotesModule.BuyPack,
            CollectSlot = RemotesModule.CollectSlot,
            SpinWheel = RemotesModule.SpinWheel,
            SpinWheelData = RemotesModule.SpinWheelData,
            Tournament = RemotesModule.Tournament,
            TournamentState = RemotesModule.TournamentState
        }
    end

    RemotesModule.Refresh(true)
    return RemotesModule
end
