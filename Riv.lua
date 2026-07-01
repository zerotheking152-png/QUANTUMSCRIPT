local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local ESP = {
    Enabled = false,
    ShowName = true,
    ShowHealth = true,
    ShowDistance = true,
    ShowWeapon = true,
    ShowBox = true,
    ShowTracer = false,
    MaxDistance = 2000,
    TeamCheck = true,
    TextSize = 13,
    BoxColor = Color3.fromRGB(255, 60, 60),
    TracerColor = Color3.fromRGB(255, 60, 60),
    TextColor = Color3.fromRGB(255, 255, 255),
    HealthColorLow = Color3.fromRGB(255, 60, 60),
    HealthColorHigh = Color3.fromRGB(60, 255, 100),

    Objects = {},
    Connections = {},
}

local function GetCharacter(player)
    return player.Character
end

local function GetHumanoid(character)
    if not character then return nil end
    return character:FindFirstChildOfClass("Humanoid")
end

local function GetRootPart(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
end

local function GetWeaponName(character)
    if not character then return "None" end
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            return tool.Name
        end
    end
    local player = Players:GetPlayerFromCharacter(character)
    if player and player:FindFirstChild("Backpack") then
        for _, tool in ipairs(player.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                return tool.Name
            end
        end
    end
    return "None"
end

local function WorldToScreen(position)
    local screenPos, onScreen = Camera:WorldToViewportPoint(position)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local function CreateDrawing(type, properties)
    local drawing = Drawing.new(type)
    for prop, value in pairs(properties or {}) do
        drawing[prop] = value
    end
    return drawing
end

local function CreateESPObject(player)
    local obj = {
        Player = player,
        Box = CreateDrawing("Square", {
            Visible = false,
            Thickness = 1.5,
            Filled = false,
            Color = ESP.BoxColor,
            Transparency = 1,
        }),
        BoxFill = CreateDrawing("Square", {
            Visible = false,
            Thickness = 1,
            Filled = true,
            Color = ESP.BoxColor,
            Transparency = 0.15,
        }),
        Name = CreateDrawing("Text", {
            Visible = false,
            Text = player.Name,
            Size = ESP.TextSize,
            Center = true,
            Outline = true,
            OutlineColor = Color3.fromRGB(0, 0, 0),
            Color = ESP.TextColor,
            Font = Drawing.Fonts.Plex,
        }),
        Health = CreateDrawing("Text", {
            Visible = false,
            Text = "100 HP",
            Size = ESP.TextSize - 1,
            Center = true,
            Outline = true,
            OutlineColor = Color3.fromRGB(0, 0, 0),
            Color = ESP.HealthColorHigh,
            Font = Drawing.Fonts.Plex,
        }),
        Distance = CreateDrawing("Text", {
            Visible = false,
            Text = "0m",
            Size = ESP.TextSize - 1,
            Center = true,
            Outline = true,
            OutlineColor = Color3.fromRGB(0, 0, 0),
            Color = ESP.TextColor,
            Font = Drawing.Fonts.Plex,
        }),
        Weapon = CreateDrawing("Text", {
            Visible = false,
            Text = "None",
            Size = ESP.TextSize - 1,
            Center = true,
            Outline = true,
            OutlineColor = Color3.fromRGB(0, 0, 0),
            Color = ESP.TextColor,
            Font = Drawing.Fonts.Plex,
        }),
        Tracer = CreateDrawing("Line", {
            Visible = false,
            Thickness = 1,
            Color = ESP.TracerColor,
            Transparency = 0.7,
        }),
        HealthBar = CreateDrawing("Square", {
            Visible = false,
            Thickness = 1,
            Filled = true,
            Color = ESP.HealthColorHigh,
            Transparency = 1,
        }),
        HealthBarBg = CreateDrawing("Square", {
            Visible = false,
            Thickness = 1,
            Filled = true,
            Color = Color3.fromRGB(30, 30, 30),
            Transparency = 1,
        }),
    }
    ESP.Objects[player] = obj
    return obj
end

local function RemoveESPObject(player)
    local obj = ESP.Objects[player]
    if obj then
        for _, drawing in pairs(obj) do
            if typeof(drawing) == "table" and drawing.Remove then
                drawing:Remove()
            end
        end
        ESP.Objects[player] = nil
    end
end

local function HideAllDrawings(obj)
    for key, drawing in pairs(obj) do
        if key ~= "Player" and typeof(drawing) == "table" and drawing.Visible ~= nil then
            drawing.Visible = false
        end
    end
end

local function UpdateESP()
    if not ESP.Enabled then
        for _, obj in pairs(ESP.Objects) do
            HideAllDrawings(obj)
        end
        return
    end

    for player, obj in pairs(ESP.Objects) do
        if not player or not player.Parent then
            RemoveESPObject(player)
            continue
        end

        if player == LocalPlayer then
            HideAllDrawings(obj)
            continue
        end

        if ESP.TeamCheck and player.Team == LocalPlayer.Team then
            HideAllDrawings(obj)
            continue
        end

        local character = GetCharacter(player)
        local rootPart = GetRootPart(character)
        local humanoid = GetHumanoid(character)

        if not character or not rootPart or not humanoid or humanoid.Health <= 0 then
            HideAllDrawings(obj)
            continue
        end

        local pos, onScreen, depth = WorldToScreen(rootPart.Position)
        local distance = (Camera.CFrame.Position - rootPart.Position).Magnitude

        if not onScreen or distance > ESP.MaxDistance then
            HideAllDrawings(obj)
            continue
        end

        local head = character:FindFirstChild("Head")
        local feet = character:FindFirstChild("HumanoidRootPart") and character.HumanoidRootPart.Position - Vector3.new(0, 3, 0)

        local topPos = head and WorldToScreen(head.Position + Vector3.new(0, 0.5, 0)) or pos
        local bottomPos = feet and WorldToScreen(feet) or pos

        local boxHeight = math.abs(topPos.Y - bottomPos.Y)
        local boxWidth = boxHeight * 0.6

        local boxX = pos.X - boxWidth / 2
        local boxY = topPos.Y

        if ESP.ShowBox then
            obj.Box.Size = Vector2.new(boxWidth, boxHeight)
            obj.Box.Position = Vector2.new(boxX, boxY)
            obj.Box.Color = ESP.BoxColor
            obj.Box.Visible = true

            obj.BoxFill.Size = Vector2.new(boxWidth, boxHeight)
            obj.BoxFill.Position = Vector2.new(boxX, boxY)
            obj.BoxFill.Color = ESP.BoxColor
            obj.BoxFill.Visible = true
        else
            obj.Box.Visible = false
            obj.BoxFill.Visible = false
        end

        if ESP.ShowName then
            obj.Name.Position = Vector2.new(pos.X, boxY - 18)
            obj.Name.Text = player.DisplayName ~= player.Name and player.DisplayName .. " (" .. player.Name .. ")" or player.Name
            obj.Name.Color = ESP.TextColor
            obj.Name.Visible = true
        else
            obj.Name.Visible = false
        end

        if ESP.ShowHealth then
            local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            local healthColor = ESP.HealthColorLow:Lerp(ESP.HealthColorHigh, healthPercent)

            obj.Health.Position = Vector2.new(pos.X, boxY + boxHeight + 4)
            obj.Health.Text = string.format("%.0f / %.0f HP", humanoid.Health, humanoid.MaxHealth)
            obj.Health.Color = healthColor
            obj.Health.Visible = true

            local barWidth = 4
            local barHeight = boxHeight
            local barX = boxX - barWidth - 4
            local barY = boxY
            local healthBarHeight = barHeight * healthPercent
            local barYOffset = barY + (barHeight - healthBarHeight)

            obj.HealthBarBg.Size = Vector2.new(barWidth, barHeight)
            obj.HealthBarBg.Position = Vector2.new(barX, barY)
            obj.HealthBarBg.Visible = true

            obj.HealthBar.Size = Vector2.new(barWidth, healthBarHeight)
            obj.HealthBar.Position = Vector2.new(barX, barYOffset)
            obj.HealthBar.Color = healthColor
            obj.HealthBar.Visible = true
        else
            obj.Health.Visible = false
            obj.HealthBar.Visible = false
            obj.HealthBarBg.Visible = false
        end

        if ESP.ShowDistance then
            obj.Distance.Position = Vector2.new(pos.X, boxY + boxHeight + (ESP.ShowHealth and 16 or 4))
            obj.Distance.Text = string.format("%.0fm", distance)
            obj.Distance.Visible = true
        else
            obj.Distance.Visible = false
        end

        if ESP.ShowWeapon then
            local weaponName = GetWeaponName(character)
            obj.Weapon.Position = Vector2.new(pos.X, boxY + boxHeight + (ESP.ShowHealth and 16 or 4) + (ESP.ShowDistance and 16 or 0))
            obj.Weapon.Text = "[ " .. weaponName .. " ]"
            obj.Weapon.Visible = true
        else
            obj.Weapon.Visible = false
        end

        if ESP.ShowTracer then
            obj.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            obj.Tracer.To = pos
            obj.Tracer.Color = ESP.TracerColor
            obj.Tracer.Visible = true
        else
            obj.Tracer.Visible = false
        end
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESPObject(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        CreateESPObject(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESPObject(player)
end)

table.insert(ESP.Connections, RunService.RenderStepped:Connect(UpdateESP))

local Wallbang = {
    Enabled = false,
    OriginalRaycast = nil,
    IgnoredParts = {},
}

local function SetupWallbang()

    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part:IsDescendantOf(LocalPlayer.Character or Instance.new("Model")) then
            if part.Name:lower():match("wall") or part.Name:lower():match("barrier") or part.Name:lower():match("block") then
                Wallbang.IgnoredParts[part] = true
            end
        end
    end
end

local function ToggleWallbang(enabled)
    if enabled then

        if not Wallbang.OriginalRaycast then
            Wallbang.OriginalRaycast = workspace.Raycast
            workspace.Raycast = function(self, origin, direction, params)
                if Wallbang.Enabled and params then

                    local filter = params.FilterDescendantsInstances or {}
                    for part, _ in pairs(Wallbang.IgnoredParts) do
                        if part and part.Parent then
                            table.insert(filter, part)
                        end
                    end
                    params.FilterDescendantsInstances = filter
                end
                return Wallbang.OriginalRaycast(self, origin, direction, params)
            end
        end
    else

        if Wallbang.OriginalRaycast then
            workspace.Raycast = Wallbang.OriginalRaycast
            Wallbang.OriginalRaycast = nil
        end
    end
end

local Window = WindUI:CreateWindow({
    Title = "Combat Hub",
    Author = "Quantum",
    Icon = "rbxassetid://109818941157555",
    IconThemed = false,
    IconSize = 24,
    Folder = "CombatHub",
    Size = UDim2.new(0, 520, 0, 380),
    MinSize = Vector2.new(480, 300),
    MaxSize = Vector2.new(800, 600),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Resizable = true,
    Acrylic = false,
    Transparent = false,
    ToggleKey = Enum.KeyCode.RightShift,
    OpenButton = {
        Enabled = true,
        Icon = "rbxassetid://109818941157555",
        Position = UDim2.new(0, 20, 0.5, -20),
        Draggable = true,
        OnlyIcon = true,
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 2,
        Color = ColorSequence.new(Color3.fromRGB(100, 255, 140), Color3.fromRGB(60, 180, 220)),
    },
    Topbar = {
        Height = 48,
        ButtonsType = "Default",
    },
    User = {
        Enabled = false,
    },
    HideSearchBar = true,
    ScrollBarEnabled = false,
    SideBarWidth = 170,
    NewElements = false,
    HidePanelBackground = false,
    Background = Color3.fromRGB(15, 15, 20),
})

local ESPTab = Window:Tab({
    Title = "ESP",
    Icon = "eye",
    Desc = "Player visualization",
})

local CombatTab = Window:Tab({
    Title = "Combat",
    Icon = "crosshair",
    Desc = "Combat enhancements",
})

local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings",
    Desc = "Script settings",
})

ESPTab:Toggle({
    Title = "Enable ESP",
    Desc = "Toggle player ESP",
    Icon = "eye",
    Value = false,
    Callback = function(value)
        ESP.Enabled = value
    end,
})

ESPTab:Toggle({
    Title = "Show Box",
    Desc = "Display box around players",
    Icon = "square",
    Value = true,
    Callback = function(value)
        ESP.ShowBox = value
    end,
})

ESPTab:Toggle({
    Title = "Show Name",
    Desc = "Display player names",
    Icon = "user",
    Value = true,
    Callback = function(value)
        ESP.ShowName = value
    end,
})

ESPTab:Toggle({
    Title = "Show Health",
    Desc = "Display health & health bar",
    Icon = "heart",
    Value = true,
    Callback = function(value)
        ESP.ShowHealth = value
    end,
})

ESPTab:Toggle({
    Title = "Show Distance",
    Desc = "Display distance to player",
    Icon = "map-pin",
    Value = true,
    Callback = function(value)
        ESP.ShowDistance = value
    end,
})

ESPTab:Toggle({
    Title = "Show Weapon",
    Desc = "Display equipped weapon",
    Icon = "sword",
    Value = true,
    Callback = function(value)
        ESP.ShowWeapon = value
    end,
})

ESPTab:Toggle({
    Title = "Show Tracer",
    Desc = "Draw line to players",
    Icon = "move",
    Value = false,
    Callback = function(value)
        ESP.ShowTracer = value
    end,
})

ESPTab:Toggle({
    Title = "Team Check",
    Desc = "Ignore teammates",
    Icon = "shield",
    Value = true,
    Callback = function(value)
        ESP.TeamCheck = value
    end,
})

ESPTab:Slider({
    Title = "Max Distance",
    Desc = "Maximum ESP render distance",
    Icon = "maximize",
    Value = {
        Min = 100,
        Max = 5000,
        Default = 2000,
    },
    Callback = function(value)
        ESP.MaxDistance = value
    end,
})

ESPTab:Slider({
    Title = "Text Size",
    Desc = "ESP text size",
    Icon = "type",
    Value = {
        Min = 8,
        Max = 20,
        Default = 13,
    },
    Callback = function(value)
        ESP.TextSize = value
        for _, obj in pairs(ESP.Objects) do
            if obj.Name then obj.Name.Size = value end
            if obj.Health then obj.Health.Size = value - 1 end
            if obj.Distance then obj.Distance.Size = value - 1 end
            if obj.Weapon then obj.Weapon.Size = value - 1 end
        end
    end,
})

CombatTab:Toggle({
    Title = "Wallbang",
    Desc = "Shoot through walls (hooks raycast)",
    Icon = "zap",
    Value = false,
    Callback = function(value)
        Wallbang.Enabled = value
        local success, err = pcall(function()
            ToggleWallbang(value)
        end)
        if not success then
            warn("[Combat Hub] Wallbang error: " .. tostring(err))
        end
    end,
})

CombatTab:Paragraph({
    Title = "Info",
    Desc = "Wallbang hooks workspace.Raycast to ignore wall parts. Effectiveness depends on the game's implementation.",
    Icon = "info",
})

SettingsTab:Dropdown({
    Title = "Theme",
    Desc = "Change UI theme",
    Icon = "palette",
    Values = {"Dark", "Darker", "Light"},
    Value = "Dark",
    Callback = function(value)
        local success, err = pcall(function()
            WindUI:SetTheme(value)
        end)
        if not success then
            warn("[Combat Hub] Failed to set theme: " .. tostring(err))
        end
    end,
})

SettingsTab:Keybind({
    Title = "Toggle UI",
    Desc = "Key to toggle the UI",
    Icon = "command",
    Value = "RightShift",
    CanChange = true,
    Callback = function(key)
        local success, err = pcall(function()
            Window:SetToggleKey(Enum.KeyCode[key])
        end)
        if not success then
            warn("[Combat Hub] Failed to set toggle key: " .. tostring(err))
        end
    end,
})

SettingsTab:Button({
    Title = "Destroy ESP",
    Desc = "Remove all ESP drawings",
    Icon = "trash",
    Callback = function()
        ESP.Enabled = false
        for player, _ in pairs(ESP.Objects) do
            RemoveESPObject(player)
        end

        local success, err = pcall(function()
            WindUI:Notify({
                Title = "ESP Destroyed",
                Content = "All ESP drawings have been removed.",
                Icon = "check",
                Duration = 3,
            })
        end)
        if not success then
            print("[Combat Hub] ESP Destroyed - All ESP drawings have been removed.")
        end
    end,
})

task.delay(1, function()
    local success, err = pcall(function()
        WindUI:Notify({
            Title = "Combat Hub Loaded",
            Content = "ESP + Wallbang ready. Press RightShift to toggle UI.",
            Icon = "check",
            Duration = 5,
        })
    end)
    if not success then
        print("[Combat Hub] Loaded successfully | WindUI v" .. (WindUI.Version or "unknown"))
    end
end)

local function Cleanup()
    ESP.Enabled = false
    for player, _ in pairs(ESP.Objects) do
        RemoveESPObject(player)
    end
    for _, conn in ipairs(ESP.Connections) do
        pcall(function() conn:Disconnect() end)
    end

    if Wallbang.OriginalRaycast then
        workspace.Raycast = Wallbang.OriginalRaycast
        Wallbang.OriginalRaycast = nil
    end
end

game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child.Name == "WindUI" then
        Cleanup()
    end
end)

