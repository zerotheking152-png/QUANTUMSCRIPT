local Quantum = loadstring(game:HttpGet("https://raw.githubusercontent.com/QuantumPH2/UI/refs/heads/main/.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")

local Window = Quantum:CreateWindow({
    Name = "Quantum Hub",
    Icon = "atom",
    Version = "1.0.0",
    ToggleKey = Enum.KeyCode.RightShift,
})

local Config = Window.Config

local States = {
    AutoBid = false,
    AutoCollect = false,
    AutoSell = false,
    AutoDrive = false,
    AutoQuest = false,
    AutoFish = false,
    AutoLostItem = false,
    AutoUpgrade = false,
    InstantLoad = false,
    GodMode = false,
    WalkSpeed = 16,
    JumpPower = 50,
    Fly = false,
    NoClip = false,
    ESP = false,
    FullBright = false,
    AntiAfk = true,
    AutoRebirth = false,
    MaxBidAmount = 5000,
    MinItemValue = 100,
    AutoSellThreshold = 80,
    SelectedZone = "Junkyard",
    SelectedVehicle = "Truck",
    TargetRarity = "Common",
}

local Connections = {}
local ESPObjects = {}
local FlyConnection = nil
local NoClipConnection = nil

local function Connect(name, conn)
    if Connections[name] then
        pcall(function() Connections[name]:Disconnect() end)
    end
    Connections[name] = conn
end

local function Disconnect(name)
    if Connections[name] then
        pcall(function() Connections[name]:Disconnect() end)
        Connections[name] = nil
    end
end

local function Notify(title, content, duration)
    Window:Notify({
        Title = title,
        Content = content,
        Duration = duration or 3,
        Icon = "Info",
    })
end

local function GetCharacter()
    Character = LocalPlayer.Character
    if not Character then
        LocalPlayer.CharacterAdded:Wait()
        Character = LocalPlayer.Character
    end
    Humanoid = Character:FindFirstChild("Humanoid")
    HRP = Character:FindFirstChild("HumanoidRootPart")
    return Character, Humanoid, HRP
end

local function GetMoney()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local money = leaderstats:FindFirstChild("Money") or leaderstats:FindFirstChild("Cash")
        if money then
            return money.Value
        end
    end
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if gui then
        for _, screen in pairs(gui:GetDescendants()) do
            if screen:IsA("TextLabel") or screen:IsA("TextButton") then
                local text = screen.Text:gsub("[%$,%,]", "")
                local num = tonumber(text)
                if num and num > 100 then
                    return num
                end
            end
        end
    end
    return 0
end

local function GetNetWorth()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local netWorth = leaderstats:FindFirstChild("NetWorth")
        if netWorth then
            return netWorth.Value
        end
    end
    return 0
end

local function TeleportTo(cframe)
    local char, hum, hrp = GetCharacter()
    if hrp then
        hrp.CFrame = cframe
        return true
    end
    return false
end

local function TweenTo(cframe, speed)
    local char, hum, hrp = GetCharacter()
    if not hrp then return false end
    speed = speed or 100
    local distance = (hrp.Position - cframe.Position).Magnitude
    local tweenTime = distance / speed
    local tween = TweenService:Create(hrp, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {
        CFrame = cframe
    })
    tween:Play()
    tween.Completed:Wait()
    return true
end

local function FindPath(destination)
    local char, hum, hrp = GetCharacter()
    if not hrp then return nil end
    local path = PathfindingService:CreatePath({
        AgentRadius = 3,
        AgentHeight = 6,
        AgentCanJump = true,
        AgentJumpHeight = 8,
        AgentMaxSlope = 45,
    })
    local success, err = pcall(function()
        path:ComputeAsync(hrp.Position, destination)
    end)
    if success and path.Status == Enum.PathStatus.Success then
        return path
    end
    return nil
end

local function FollowPath(path)
    local char, hum, hrp = GetCharacter()
    if not hum or not path then return end
    local waypoints = path:GetWaypoints()
    for _, waypoint in ipairs(waypoints) do
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        hum:MoveTo(waypoint.Position)
        hum.MoveToFinished:Wait()
    end
end

local function GetNearestContainer()
    local char, hum, hrp = GetCharacter()
    if not hrp then return nil end
    local nearest = nil
    local minDist = math.huge
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Part") or obj:IsA("MeshPart") then
            local name = obj.Name:lower()
            if name:find("container") or name:find("storage") or name:find("unit") or name:find("locker") then
                local primary = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
                if primary then
                    local dist = (hrp.Position - primary.Position).Magnitude
                    if dist < minDist and dist < 500 then
                        minDist = dist
                        nearest = obj
                    end
                end
            end
        end
    end
    return nearest
end

local function GetNearestItem()
    local char, hum, hrp = GetCharacter()
    if not hrp then return nil end
    local nearest = nil
    local minDist = math.huge
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
            if obj:FindFirstChild("ClickDetector") or obj:FindFirstChild("ProximityPrompt") then
                local dist = (hrp.Position - obj.Position).Magnitude
                if dist < minDist and dist < 50 then
                    minDist = dist
                    nearest = obj
                end
            end
        end
    end
    return nearest
end

local function GetNearestPrompt()
    local char, hum, hrp = GetCharacter()
    if not hrp then return nil end
    local nearest = nil
    local minDist = math.huge
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local parent = obj.Parent
            if parent and parent:IsA("BasePart") then
                local dist = (hrp.Position - parent.Position).Magnitude
                if dist < minDist and dist < 20 then
                    minDist = dist
                    nearest = obj
                end
            end
        end
    end
    return nearest
end

local function FirePrompt(prompt)
    if prompt and prompt:IsA("ProximityPrompt") then
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration + 0.1)
            prompt:InputHoldEnd()
        end)
    end
end

local function GetVehicle()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("VehicleSeat") or obj:IsA("Seat") then
            if obj:FindFirstChild("Owner") or obj:FindFirstChild("Vehicle") then
                return obj
            end
        end
    end
    return nil
end

local function GetShop()
    for _, obj in pairs(Workspace:GetDescendants()) do
        local name = obj.Name:lower()
        if name:find("shop") or name:find("store") or name:find("sell") then
            if obj:IsA("BasePart") or (obj:IsA("Model") and obj.PrimaryPart) then
                return obj:IsA("Model") and obj.PrimaryPart or obj
            end
        end
    end
    return nil
end

local function GetAuctionZone()
    for _, obj in pairs(Workspace:GetDescendants()) do
        local name = obj.Name:lower()
        if name:find("auction") or name:find("bid") or name:find("yard") then
            if obj:IsA("BasePart") or (obj:IsA("Model") and obj.PrimaryPart) then
                return obj:IsA("Model") and obj.PrimaryPart or obj
            end
        end
    end
    return nil
end

local function GetNPCs()
    local npcs = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("Head") then
            if obj ~= LocalPlayer.Character then
                local head = obj:FindFirstChild("Head")
                if head and head:FindFirstChild("Dialog") or obj:FindFirstChild("Quest") then
                    table.insert(npcs, obj)
                end
            end
        end
    end
    return npcs
end

local function GetFishingSpot()
    for _, obj in pairs(Workspace:GetDescendants()) do
        local name = obj.Name:lower()
        if name:find("fish") or name:find("water") or name:find("pond") or name:find("lake") then
            if obj:IsA("BasePart") then
                return obj
            end
        end
    end
    return nil
end

local function GetLostItems()
    local items = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            local name = obj.Name:lower()
            if name:find("lost") or name:find("collectible") or name:find("hidden") or name:find("treasure") then
                if obj:FindFirstChild("ClickDetector") or obj:FindFirstChild("ProximityPrompt") then
                    table.insert(items, obj)
                end
            end
        end
    end
    return items
end

local function GetUpgrades()
    local upgrades = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        local name = obj.Name:lower()
        if name:find("upgrade") or name:find("buy") or name:find("purchase") then
            if obj:FindFirstChild("ProximityPrompt") or obj:FindFirstChild("ClickDetector") then
                table.insert(upgrades, obj)
            end
        end
    end
    return upgrades
end

local function GetRemote(name)
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            if obj.Name:lower():find(name:lower()) then
                return obj
            end
        end
    end
    return nil
end

local function GetAllRemotes()
    local remotes = {}
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            table.insert(remotes, obj)
        end
    end
    return remotes
end

local function InvokeRemote(name, ...)
    local remote = GetRemote(name)
    if remote then
        if remote:IsA("RemoteFunction") then
            return pcall(function(...) return remote:InvokeServer(...) end, ...)
        elseif remote:IsA("RemoteEvent") then
            return pcall(function(...) remote:FireServer(...) end, ...)
        end
    end
    return false
end

local function GetGuiButton(text)
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return nil end
    for _, screen in pairs(gui:GetDescendants()) do
        if screen:IsA("TextButton") or screen:IsA("ImageButton") then
            if screen.Text:lower():find(text:lower()) or screen.Name:lower():find(text:lower()) then
                return screen
            end
        end
    end
    return nil
end

local function ClickGuiButton(text)
    local btn = GetGuiButton(text)
    if btn then
        pcall(function()
            if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                btn.MouseButton1Click:Fire()
            end
        end)
        return true
    end
    return false
end

local function GetGuiText(text)
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return nil end
    for _, screen in pairs(gui:GetDescendants()) do
        if screen:IsA("TextLabel") or screen:IsA("TextButton") then
            if screen.Text:lower():find(text:lower()) then
                return screen
            end
        end
    end
    return nil
end

local function CreateESP(obj, color, text)
    if not obj then return end
    if ESPObjects[obj] then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "QuantumESP"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 100, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Adornee = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
    billboard.Parent = obj
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text or obj.Name
    label.TextColor3 = color or Color3.fromRGB(0, 255, 0)
    label.TextSize = 12
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.5
    label.Parent = billboard
    ESPObjects[obj] = billboard
end

local function ClearESP()
    for obj, billboard in pairs(ESPObjects) do
        if billboard and billboard.Parent then
            billboard:Destroy()
        end
    end
    ESPObjects = {}
end

local function UpdateESP()
    ClearESP()
    if not States.ESP then return end
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Part") or obj:IsA("MeshPart") then
            local name = obj.Name:lower()
            if name:find("container") or name:find("storage") then
                CreateESP(obj, Color3.fromRGB(255, 255, 0), "Container")
            elseif name:find("item") or name:find("loot") then
                CreateESP(obj, Color3.fromRGB(0, 255, 0), "Item")
            elseif name:find("npc") or name:find("quest") then
                CreateESP(obj, Color3.fromRGB(0, 150, 255), "NPC")
            elseif name:find("shop") or name:find("sell") then
                CreateESP(obj, Color3.fromRGB(255, 0, 255), "Shop")
            elseif name:find("lost") or name:find("hidden") then
                CreateESP(obj, Color3.fromRGB(255, 100, 0), "Lost Item")
            end
        end
    end
end

local function EnableFly()
    if FlyConnection then return end
    local char, hum, hrp = GetCharacter()
    if not hrp then return end
    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.P = 9e4
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.CFrame = hrp.CFrame
    bodyGyro.Parent = hrp
    local bodyVel = Instance.new("BodyVelocity")
    bodyVel.Velocity = Vector3.new(0, 0, 0)
    bodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVel.Parent = hrp
    FlyConnection = RunService.RenderStepped:Connect(function()
        local cam = Workspace.CurrentCamera
        local moveDir = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDir = moveDir + cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDir = moveDir - cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDir = moveDir - cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDir = moveDir + cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDir = moveDir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDir = moveDir - Vector3.new(0, 1, 0)
        end
        bodyVel.Velocity = moveDir * States.WalkSpeed
        bodyGyro.CFrame = cam.CFrame
    end)
end

local function DisableFly()
    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end
    local char, hum, hrp = GetCharacter()
    if hrp then
        for _, child in pairs(hrp:GetChildren()) do
            if child:IsA("BodyGyro") or child:IsA("BodyVelocity") then
                child:Destroy()
            end
        end
    end
end

local function EnableNoClip()
    if NoClipConnection then return end
    NoClipConnection = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function DisableNoClip()
    if NoClipConnection then
        NoClipConnection:Disconnect()
        NoClipConnection = nil
    end
    local char = LocalPlayer.Character
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

local function EnableFullBright()
    local lighting = game:GetService("Lighting")
    lighting.Brightness = 2
    lighting.ClockTime = 12
    lighting.FogEnd = 100000
    lighting.GlobalShadows = false
    lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
end

local function SetupAntiAfk()
    LocalPlayer.Idled:Connect(function()
        if States.AntiAfk then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
end

local MainTab = Window:CreateTab({
    Name = "Main",
    Icon = "Home",
})

local AutoSection = MainTab:CreateSection({
    Name = "Auto Features",
    Icon = "bot",
    Collapsed = false,
})

AutoSection:CreateToggle({
    Name = "Auto Bid",
    Icon = "coins",
    Desc = "Automatically bid on storage containers",
    Default = false,
    Callback = function(state)
        States.AutoBid = state
        if state then
            Connect("AutoBid", task.spawn(function()
                while States.AutoBid do
                    task.wait(1)
                    local container = GetNearestContainer()
                    if container then
                        local primary = container:IsA("Model") and (container.PrimaryPart or container:FindFirstChildWhichIsA("BasePart")) or container
                        if primary then
                            local dist = (HRP.Position - primary.Position).Magnitude
                            if dist > 10 then
                                TweenTo(primary.CFrame * CFrame.new(0, 0, 5))
                            end
                            local prompt = container:FindFirstChildOfClass("ProximityPrompt", true)
                            if prompt then
                                FirePrompt(prompt)
                            end
                            ClickGuiButton("bid")
                            ClickGuiButton("buy")
                        end
                    end
                end
            end))
        else
            Disconnect("AutoBid")
        end
    end,
})

AutoSection:CreateToggle({
    Name = "Auto Collect",
    Icon = "box",
    Desc = "Automatically collect items from containers",
    Default = false,
    Callback = function(state)
        States.AutoCollect = state
        if state then
            Connect("AutoCollect", task.spawn(function()
                while States.AutoCollect do
                    task.wait(0.3)
                    local item = GetNearestItem()
                    if item then
                        local dist = (HRP.Position - item.Position).Magnitude
                        if dist > 5 then
                            TweenTo(item.CFrame)
              end
                        local prompt = item:FindFirstChildOfClass("ProximityPrompt")
                        if prompt then
                            FirePrompt(prompt)
                        end
                        local clickDetector = item:FindFirstChildOfClass("ClickDetector")
                        if clickDetector then
                            pcall(function()
                                fireclickdetector(clickDetector)
                            end)
                        end
                    end
                end
            end))
        else
            Disconnect("AutoCollect")
        end
    end,
})

AutoSection:CreateToggle({
    Name = "Auto Sell",
    Icon = "shopping-cart",
    Desc = "Automatically sell items at shop",
    Default = false,
    Callback = function(state)
        States.AutoSell = state
        if state then
            Connect("AutoSell", task.spawn(function()
                while States.AutoSell do
                    task.wait(2)
                    local shop = GetShop()
                    if shop then
                        TweenTo(shop.CFrame * CFrame.new(0, 0, 5))
                        task.wait(0.5)
                        ClickGuiButton("sell")
                        ClickGuiButton("sell all")
                        local prompt = shop:FindFirstChildOfClass("ProximityPrompt")
                        if prompt then
                            FirePrompt(prompt)
                        end
                    end
                end
            end))
        else
            Disconnect("AutoSell")
        end
    end,
})

AutoSection:CreateToggle({
    Name = "Auto Drive",
    Icon = "move",
    Desc = "Automatically drive vehicle to destination",
    Default = false,
    Callback = function(state)
        States.AutoDrive = state
        if state then
            Connect("AutoDrive", task.spawn(function()
                while States.AutoDrive do
                    task.wait(2)
                    local vehicle = GetVehicle()
                    if vehicle then
                        local shop = GetShop()
                        if shop then
                            TweenTo(shop.CFrame * CFrame.new(0, 0, 10))
                        end
                    end
                end
            end))
        else
            Disconnect("AutoDrive")
        end
    end,
})

AutoSection:CreateToggle({
    Name = "Auto Quest",
    Icon = "target",
    Desc = "Automatically complete quests from NPCs",
    Default = false,
    Callback = function(state)
        States.AutoQuest = state
        if state then
            Connect("AutoQuest", task.spawn(function()
                while States.AutoQuest do
                    task.wait(3)
                    local npcs = GetNPCs()
                    for _, npc in pairs(npcs) do
                        local head = npc:FindFirstChild("Head")
                        if head then
                            TweenTo(head.CFrame * CFrame.new(0, 0, 3))
                            task.wait(0.5)
                            local prompt = npc:FindFirstChildOfClass("ProximityPrompt", true)
                            if prompt then
                                FirePrompt(prompt)
                            end
                            ClickGuiButton("accept")
                            ClickGuiButton("complete")
                            ClickGuiButton("claim")
                        end
                    end
                end
            end))
        else
            Disconnect("AutoQuest")
        end
    end,
})

AutoSection:CreateToggle({
    Name = "Auto Fish",
    Icon = "fish",
    Desc = "Automatically fish at fishing spots",
    Default = false,
    Callback = function(state)
        States.AutoFish = state
        if state then
            Connect("AutoFish", task.spawn(function()
                while States.AutoFish do
                    task.wait(2)
                    local spot = GetFishingSpot()
                    if spot then
                        TweenTo(spot.CFrame * CFrame.new(0, 0, 5))
                        task.wait(0.5)
                        ClickGuiButton("fish")
                        ClickGuiButton("cast")
                        local prompt = spot:FindFirstChildOfClass("ProximityPrompt")
                        if prompt then
                            FirePrompt(prompt)
                        end
                    end
                end
            end))
        else
            Disconnect("AutoFish")
        end
    end,
})

AutoSection:CreateToggle({
    Name = "Auto Lost Item",
    Icon = "map-pin",
    Desc = "Automatically collect lost/hidden items",
    Default = false,
    Callback = function(state)
        States.AutoLostItem = state
        if state then
            Connect("AutoLostItem", task.spawn(function()
                while States.AutoLostItem do
                    task.wait(1)
                    local items = GetLostItems()
                    for _, item in pairs(items) do
                        TweenTo(item.CFrame)
                        task.wait(0.3)
                        local prompt = item:FindFirstChildOfClass("ProximityPrompt")
                        if prompt then
                            FirePrompt(prompt)
                        end
                        local clickDetector = item:FindFirstChildOfClass("ClickDetector")
                        if clickDetector then
                            pcall(function()
                                fireclickdetector(clickDetector)
                            end)
                        end
                    end
                end
            end))
        else
            Disconnect("AutoLostItem")
        end
    end,
})

AutoSection:CreateToggle({
    Name = "Auto Upgrade",
    Icon = "trending-up",
    Desc = "Automatically buy upgrades when affordable",
    Default = false,
    Callback = function(state)
        States.AutoUpgrade = state
        if state then
            Connect("AutoUpgrade", task.spawn(function()
                while States.AutoUpgrade do
                    task.wait(5)
                    local upgrades = GetUpgrades()
                    for _, upgrade in pairs(upgrades) do
                        local prompt = upgrade:FindFirstChildOfClass("ProximityPrompt")
                        if prompt then
                            local parent = upgrade:IsA("BasePart") and upgrade or upgrade:FindFirstChildWhichIsA("BasePart")
                            if parent then
                                TweenTo(parent.CFrame * CFrame.new(0, 0, 3))
                                task.wait(0.3)
                                FirePrompt(prompt)
                            end
                        end
                    end
                end
            end))
        else
            Disconnect("AutoUpgrade")
        end
    end,
})

AutoSection:CreateToggle({
    Name = "Instant Load",
    Icon = "zap",
    Desc = "Instantly load items into vehicle",
    Default = false,
    Callback = function(state)
        States.InstantLoad = state
        if state then
            Connect("InstantLoad", task.spawn(function()
                while States.InstantLoad do
                    task.wait(0.5)
                    InvokeRemote("Load")
                    InvokeRemote("Store")
                    ClickGuiButton("load")
                    ClickGuiButton("store")
                end
            end))
        else
            Disconnect("InstantLoad")
        end
    end,
})

AutoSection:CreateToggle({
    Name = "Auto Rebirth",
    Icon = "refresh-cw",
    Desc = "Automatically rebirth when possible",
    Default = false,
    Callback = function(state)
        States.AutoRebirth = state
        if state then
            Connect("AutoRebirth", task.spawn(function()
                while States.AutoRebirth do
                    task.wait(10)
                    InvokeRemote("Rebirth")
                    ClickGuiButton("rebirth")
                    ClickGuiButton("prestige")
                end
            end))
        else
            Disconnect("AutoRebirth")
        end
    end,
})

local SettingsSection = MainTab:CreateSection({
    Name = "Settings",
    Icon = "sliders",
    Collapsed = true,
})

SettingsSection:CreateSlider({
    Name = "Max Bid Amount",
    Icon = "coins",
    Min = 100,
    Max = 100000,
    Default = 5000,
    Increment = 100,
    Callback = function(value)
        States.MaxBidAmount = value
    end,
})

SettingsSection:CreateSlider({
    Name = "Min Item Value",
    Icon = "bar-chart-2",
    Min = 10,
    Max = 10000,
    Default = 100,
    Increment = 10,
    Callback = function(value)
        States.MinItemValue = value
    end,
})

SettingsSection:CreateSlider({
    Name = "Auto Sell Threshold",
    Icon = "percent",
    Min = 10,
    Max = 100,
    Default = 80,
    Increment = 5,
    Callback = function(value)
        States.AutoSellThreshold = value
    end,
})

SettingsSection:CreateDropdown({
    Name = "Target Zone",
    Icon = "map-pin",
    Options = {"Junkyard", "Farmyard", "Back Alley", "Shipping Yard", "Mall", "All"},
    Default = "Junkyard",
    Callback = function(value)
        States.SelectedZone = value
    end,
})

SettingsSection:CreateDropdown({
    Name = "Target Rarity",
    Icon = "star",
    Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "All"},
    Default = "Common",
    Callback = function(value)
        States.TargetRarity = value
    end,
})

local PlayerTab = Window:CreateTab({
    Name = "Player",
    Icon = "user",
})

local MovementSection = PlayerTab:CreateSection({
    Name = "Movement",
    Icon = "move",
    Collapsed = false,
})

MovementSection:CreateSlider({
    Name = "Walk Speed",
    Icon = "activity",
    Min = 16,
    Max = 500,
    Default = 16,
    Increment = 1,
    Callback = function(value)
        States.WalkSpeed = value
        local char, hum = GetCharacter()
        if hum then
            hum.WalkSpeed = value
        end
    end,
})

MovementSection:CreateSlider({
    Name = "Jump Power",
    Icon = "arrow-up",
    Min = 50,
    Max = 500,
    Default = 50,
    Increment = 1,
    Callback = function(value)
        States.JumpPower = value
        local char, hum = GetCharacter()
        if hum then
            hum.JumpPower = value
        end
    end,
})

MovementSection:CreateToggle({
    Name = "Fly",
    Icon = "cloud",
    Desc = "Enable flying mode (WASD + Space/Shift)",
    Default = false,
    Callback = function(state)
        States.Fly = state
        if state then
            EnableFly()
        else
            DisableFly()
        end
    end,
})

MovementSection:CreateToggle({
    Name = "No Clip",
    Icon = "unlock",
    Desc = "Walk through walls and objects",
    Default = false,
    Callback = function(state)
        States.NoClip = state
        if state then
            EnableNoClip()
        else
            DisableNoClip()
        end
    end,
})

local StatsSection = PlayerTab:CreateSection({
    Name = "Player Stats",
    Icon = "bar-chart-2",
    Collapsed = true,
})

local MoneyLabel = StatsSection:CreateLabel({
    Text = "Money: Loading...",
    Icon = "coins",
})

local NetWorthLabel = StatsSection:CreateLabel({
    Text = "Net Worth: Loading...",
    Icon = "trending-up",
})

task.spawn(function()
    while true do
        task.wait(1)
        local money = GetMoney()
        local netWorth = GetNetWorth()
        MoneyLabel:Set("Money: $" .. tostring(money))
        NetWorthLabel:Set("Net Worth: $" .. tostring(netWorth))
    end
end)

local VisualTab = Window:CreateTab({
    Name = "Visual",
    Icon = "eye",
})

local VisualSection = VisualTab:CreateSection({
    Name = "Visual Features",
    Icon = "eye",
    Collapsed = false,
})

VisualSection:CreateToggle({
    Name = "ESP",
    Icon = "target",
    Desc = "Show ESP for containers, items, NPCs, shops",
    Default = false,
    Callback = function(state)
        States.ESP = state
        if state then
            UpdateESP()
            Connect("ESP", Workspace.DescendantAdded:Connect(function()
                task.wait(0.5)
                UpdateESP()
            end))
        else
            Disconnect("ESP")
            ClearESP()
        end
    end,
})

VisualSection:CreateToggle({
    Name = "Full Bright",
    Icon = "sun",
    Desc = "Remove darkness and fog",
    Default = false,
    Callback = function(state)
        if state then
            EnableFullBright()
        end
    end,
})

VisualSection:CreateToggle({
    Name = "God Mode",
    Icon = "shield",
    Desc = "Prevent taking damage",
    Default = false,
    Callback = function(state)
        States.GodMode = state
        if state then
            Connect("GodMode", LocalPlayer.CharacterAdded:Connect(function(char)
                task.wait(0.5)
                local hum = char:WaitForChild("Humanoid")
                hum.Health = hum.MaxHealth
                hum:GetPropertyChangedSignal("Health"):Connect(function()
                    if States.GodMode then
                        hum.Health = hum.MaxHealth
                    end
                end)
            end))
            local char, hum = GetCharacter()
            if hum then
                hum.Health = hum.MaxHealth
                hum:GetPropertyChangedSignal("Health"):Connect(function()
                    if States.GodMode then
                        hum.Health = hum.MaxHealth
                    end
                end)
            end
        else
            Disconnect("GodMode")
        end
    end,
})

local TeleportTab = Window:CreateTab({
    Name = "Teleport",
    Icon = "map-pin",
})

local TPSection = TeleportTab:CreateSection({
    Name = "Teleport Locations",
    Icon = "compass",
    Collapsed = false,
})

TPSection:CreateButton({
    Name = "TP to Shop",
    Icon = "shopping-cart",
    Callback = function()
        local shop = GetShop()
        if shop then
            TeleportTo(shop.CFrame * CFrame.new(0, 5, 0))
            Notify("Teleport", "Teleported to Shop", 2)
        else
            Notify("Teleport", "Shop not found", 2)
        end
    end,
})

TPSection:CreateButton({
    Name = "TP to Auction",
    Icon = "gavel",
    Callback = function()
        local auction = GetAuctionZone()
        if auction then
            TeleportTo(auction.CFrame * CFrame.new(0, 5, 0))
            Notify("Teleport", "Teleported to Auction", 2)
        else
            Notify("Teleport", "Auction not found", 2)
        end
    end,
})

TPSection:CreateButton({
    Name = "TP to Spawn",
    Icon = "home",
    Callback = function()
        local spawnLocation = Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChild("Spawn")
        if spawnLocation then
            TeleportTo(spawnLocation.CFrame * CFrame.new(0, 5, 0))
            Notify("Teleport", "Teleported to Spawn", 2)
        else
            Notify("Teleport", "Spawn not found", 2)
        end
    end,
})

TPSection:CreateButton({
    Name = "TP to Vehicle",
    Icon = "truck",
    Callback = function()
        local vehicle = GetVehicle()
        if vehicle then
            local part = vehicle:IsA("BasePart") and vehicle or vehicle:FindFirstChildWhichIsA("BasePart")
            if part then
                TeleportTo(part.CFrame * CFrame.new(0, 5, 0))
                Notify("Teleport", "Teleported to Vehicle", 2)
            end
        else
            Notify("Teleport", "Vehicle not found", 2)
        end
    end,
})

TPSection:CreateButton({
    Name = "TP to Fishing Spot",
    Icon = "fish",
    Callback = function()
        local spot = GetFishingSpot()
        if spot then
            TeleportTo(spot.CFrame * CFrame.new(0, 5, 0))
            Notify("Teleport", "Teleported to Fishing Spot", 2)
        else
            Notify("Teleport", "Fishing spot not found", 2)
        end
    end,
})

TPSection:CreateInput({
    Name = "TP to Player",
    Icon = "user",
    Placeholder = "Player Name",
    Callback = function(text)
        for _, player in pairs(Players:GetPlayers()) do
            if player.Name:lower():find(text:lower()) or player.DisplayName:lower():find(text:lower()) then
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    TeleportTo(char.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0))
                    Notify("Teleport", "Teleported to " .. player.Name, 2)
                    return
                end
            end
        end
        Notify("Teleport", "Player not found", 2)
    end,
})

local MiscTab = Window:CreateTab({
    Name = "Misc",
    Icon = "settings",
})

local MiscSection = MiscTab:CreateSection({
    Name = "Miscellaneous",
    Icon = "wrench",
    Collapsed = false,
})

MiscSection:CreateToggle({
    Name = "Anti AFK",
    Icon = "clock",
    Desc = "Prevent getting kicked for being AFK",
    Default = true,
    Callback = function(state)
        States.AntiAfk = state
    end,
})

MiscSection:CreateButton({
    Name = "Rejoin Server",
    Icon = "refresh-cw",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

MiscSection:CreateButton({
    Name = "Server Hop",
    Icon = "globe",
    Callback = function()
        local HttpService = game:GetService("HttpService")
        local TeleportService = game:GetService("TeleportService")
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        end)
        if success and result and result.data then
            for _, server in pairs(result.data) do
                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                    return
                end
            end
        end
        Notify("Server Hop", "No available servers found", 3)
    end,
})

MiscSection:CreateButton({
    Name = "Reset Character",
    Icon = "rotate-ccw",
    Callback = function()
        local char, hum = GetCharacter()
        if hum then
            hum.Health = 0
        end
    end,
})

MiscSection:CreateButton({
    Name = "Clear All Items",
    Icon = "trash",
    Callback = function()
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, item in pairs(backpack:GetChildren()) do
                item:Destroy()
            end
        end
        Notify("Clear", "All items cleared", 2)
    end,
})

local ThemeSection = MiscTab:CreateSection({
    Name = "Theme",
    Icon = "palette",
    Collapsed = true,
})

ThemeSection:CreateDropdown({
    Name = "UI Theme",
    Icon = "palette",
    Options = {"QuantumDark", "Dark", "Light", "Ocean", "Midnight", "Forest"},
    Default = "QuantumDark",
    Callback = function(value)
        Window:SetTheme(value)
    end,
})

SetupAntiAfk()

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HRP = char:WaitForChild("HumanoidRootPart")
    if States.WalkSpeed ~= 16 then
        Humanoid.WalkSpeed = States.WalkSpeed
    end
    if States.JumpPower ~= 50 then
        Humanoid.JumpPower = States.JumpPower
    end
    if States.GodMode then
        Humanoid.Health = Humanoid.MaxHealth
        Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if States.GodMode then
                Humanoid.Health = Humanoid.MaxHealth
            end
        end)
    end
end)

Notify("Quantum Hub", "Storage Hunters: Open World v1.0.0 Loaded!", 5)
