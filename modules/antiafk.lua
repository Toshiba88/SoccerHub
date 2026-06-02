--//====================================================
--// Soccer Hub - antiafk.lua
--// Fichier généré par découpage depuis soccer_hub_v33_index_order_fixed.lua
--// Chaque champ contient une partie réelle du script original.
--//====================================================

return {
    logic = [====================[
local function GetCharacterParts()
    local character = player.Character

    if not character then
        return nil, nil, nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not rootPart then
        return character, nil, nil
    end

    if humanoid.Health <= 0 then
        return character, nil, nil
    end

    return character, humanoid, rootPart
end

local function AntiAfkVirtualUserClick()
    if not antiAfkVirtualUserEnabled then
        return false
    end

    local ok, err = pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)

    if ok then
        lastAntiAfkMethod = "VirtualUser ClickButton2"
        lastAfkStatus = "VIRTUALUSER CLICK ENVOYÉ"
        Log("Anti-AFK méthode : VirtualUser ClickButton2.", "[AFK]")
        return true
    end

    Log("Anti-AFK VirtualUser erreur : " .. tostring(err), "[AFK]")
    return false
end

local function AntiAfkVirtualKey()
    if not antiAfkVirtualKeyEnabled then
        return false
    end

    local ok, err = pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.RightShift, false, game)
        task.wait(0.08)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.RightShift, false, game)
    end)

    if ok then
        lastAntiAfkMethod = "VirtualInput RightShift"
        lastAfkStatus = "VIRTUALINPUT TOUCHE RIGHTSHIFT"
        Log("Anti-AFK méthode : VirtualInput RightShift.", "[AFK]")
        return true
    end

    Log("Anti-AFK VirtualInput key erreur : " .. tostring(err), "[AFK]")
    return false
end

local function AntiAfkVirtualMouse()
    if not antiAfkVirtualMouseEnabled then
        return false
    end

    local ok, err = pcall(function()
        local camera = Workspace.CurrentCamera
        local viewportSize = camera and camera.ViewportSize or Vector2.new(800, 600)
        local x = math.floor(viewportSize.X / 2)
        local y = math.floor(viewportSize.Y / 2)

        VirtualInputManager:SendMouseMoveEvent(x, y, game)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
        task.wait(0.08)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)

    if ok then
        lastAntiAfkMethod = "VirtualInput MouseClick"
        lastAfkStatus = "VIRTUALINPUT CLIC SOURIS"
        Log("Anti-AFK méthode : VirtualInput clic souris.", "[AFK]")
        return true
    end

    Log("Anti-AFK VirtualInput mouse erreur : " .. tostring(err), "[AFK]")
    return false
end

local function AntiAfkRealMove()
    if not antiAfkRealMoveEnabled then
        return false
    end

    local character, humanoid, rootPart = GetCharacterParts()

    if not character or not humanoid or not rootPart then
        lastAfkStatus = "PERSONNAGE NON PRÊT"
        UpdateStatus()
        return false
    end

    if humanoid.Health <= 0 then
        lastAfkStatus = "PERSONNAGE MORT"
        UpdateStatus()
        return false
    end

    if humanoid.Sit then
        pcall(function()
            humanoid.Sit = false
        end)
    end

    local angle = math.random() * math.pi * 2
    local minDistance = math.max(2, math.floor(antiAfkMoveDistance * 0.5))
    local maxDistance = math.max(minDistance, antiAfkMoveDistance)
    local distance = math.random(minDistance, maxDistance)

    local offset = Vector3.new(
        math.cos(angle) * distance,
        0,
        math.sin(angle) * distance
    )

    local targetPosition = rootPart.Position + offset

    local ok, err = pcall(function()
        humanoid:MoveTo(targetPosition)
    end)

    if ok then
        lastAfkMoveClock = os.clock()
        lastAntiAfkMethod = "Humanoid MoveTo"
        lastAfkStatus = "MOUVEMENT ENVOYÉ | DISTANCE " .. tostring(distance)
        Log("Anti-AFK méthode : MoveTo | distance=" .. tostring(distance), "[AFK]")
        return true
    end

    Log("Anti-AFK MoveTo erreur : " .. tostring(err), "[AFK]")
    return false
end

local function RunAntiAfkRotatingMethod()
    if not antiAfkEnabled then
        return false
    end

    local methods = {
        AntiAfkVirtualUserClick,
        AntiAfkVirtualKey,
        AntiAfkVirtualMouse,
        AntiAfkRealMove
    }

    local totalMethods = #methods

    for attempt = 1, totalMethods do
        antiAfkMethodIndex += 1

        if antiAfkMethodIndex > totalMethods then
            antiAfkMethodIndex = 1
        end

        local method = methods[antiAfkMethodIndex]
        local ok = method()

        if ok then
            UpdateStatus()
            return true
        end
    end

    lastAfkStatus = "AUCUNE MÉTHODE ANTI-AFK DISPONIBLE"
    Log("Aucune méthode Anti-AFK n'a fonctionné.", "[AFK]")
    UpdateStatus()

    return false
end

local function StartAntiAfk()
    AddConnection(player.Idled:Connect(function()
        if not antiAfkEnabled then
            return
        end

        Log("Event player.Idled détecté, méthode rotative envoyée.", "[AFK]")
        task.spawn(function()
            RunAntiAfkRotatingMethod()
        end)
    end))

    if antiAfkMoveLoopStarted then
        return
    end

    antiAfkMoveLoopStarted = true

    task.spawn(function()
        while IsCurrentRun() do
            if antiAfkEnabled then
                RunAntiAfkRotatingMethod()
            end

            task.wait(math.max(5, antiAfkMoveDelay))
        end
    end)
end

]====================],

    ui = [====================[
local AntiAfkToggle = Tabs.Settings:AddToggle("AntiAfkToggle", {
    Title = "Anti-AFK",
    Default = true
})

AntiAfkToggle:OnChanged(function()
    antiAfkEnabled = Options.AntiAfkToggle.Value
    Log("AntiAFK = " .. tostring(antiAfkEnabled), "[SYSTEM]")
    UpdateStatus()
end)

local AntiAfkMoveToggle = Tabs.Settings:AddToggle("AntiAfkMoveToggle", {
    Title = "Anti-AFK mouvement réel",
    Default = true
})

AntiAfkMoveToggle:OnChanged(function()
    antiAfkRealMoveEnabled = Options.AntiAfkMoveToggle.Value
    Log("Anti-AFK mouvement réel = " .. tostring(antiAfkRealMoveEnabled), "[SYSTEM]")
    UpdateStatus()
end)

local AntiAfkVirtualUserToggle = Tabs.Settings:AddToggle("AntiAfkVirtualUserToggle", {
    Title = "Anti-AFK VirtualUser",
    Default = true
})

AntiAfkVirtualUserToggle:OnChanged(function()
    antiAfkVirtualUserEnabled = Options.AntiAfkVirtualUserToggle.Value
    Log("Anti-AFK VirtualUser = " .. tostring(antiAfkVirtualUserEnabled), "[SYSTEM]")
    UpdateStatus()
end)

local AntiAfkVirtualKeyToggle = Tabs.Settings:AddToggle("AntiAfkVirtualKeyToggle", {
    Title = "Anti-AFK touche virtuelle",
    Default = true
})

AntiAfkVirtualKeyToggle:OnChanged(function()
    antiAfkVirtualKeyEnabled = Options.AntiAfkVirtualKeyToggle.Value
    Log("Anti-AFK touche virtuelle = " .. tostring(antiAfkVirtualKeyEnabled), "[SYSTEM]")
    UpdateStatus()
end)

local AntiAfkVirtualMouseToggle = Tabs.Settings:AddToggle("AntiAfkVirtualMouseToggle", {
    Title = "Anti-AFK clic virtuel",
    Default = true
})

AntiAfkVirtualMouseToggle:OnChanged(function()
    antiAfkVirtualMouseEnabled = Options.AntiAfkVirtualMouseToggle.Value
    Log("Anti-AFK clic virtuel = " .. tostring(antiAfkVirtualMouseEnabled), "[SYSTEM]")
    UpdateStatus()
end)

Tabs.Settings:AddInput("AntiAfkMoveDelayInput", {
    Title = "Délai Anti-AFK",
    Default = tostring(antiAfkMoveDelay),
    Placeholder = "Ex: 45",
    Numeric = true,
    Finished = false,
    Callback = function(value)
        antiAfkMoveDelay = SafeNumber(value, 45, 5, 600)
        Log("Délai Anti-AFK = " .. tostring(antiAfkMoveDelay) .. "s", "[SYSTEM]")
        UpdateStatus()
    end
})

Tabs.Settings:AddInput("AntiAfkMoveDistanceInput", {
    Title = "Distance mouvement Anti-AFK",
    Default = tostring(antiAfkMoveDistance),
    Placeholder = "Ex: 10",
    Numeric = true,
    Finished = false,
    Callback = function(value)
        antiAfkMoveDistance = SafeNumber(value, 10, 2, 100)
        Log("Distance mouvement Anti-AFK = " .. tostring(antiAfkMoveDistance), "[SYSTEM]")
        UpdateStatus()
    end
})

if saveOk and SaveManager then
    SaveManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
]====================],

}
