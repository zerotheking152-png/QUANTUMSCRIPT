local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")


local QuantumUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/QuantumPH2/UI/refs/heads/main/.lua"))()


local QuantumConfig = {
    Version = "1.0.0",
    GameName = "Wizard Alchemy",
    GameUpdate = "Spider Lair UPD",
    Developer = "Muggle Academy",
    Creator = "Quantum Team",

    AutoFarm = {
        Enabled = false,
        TargetType = "Mobs",
        AttackRange = 50,
        LootRange = 30,
        MinHealthPercent = 20,
        AutoHeal = true,
        HealThreshold = 30,
        AutoDash = true,
        UseSkills = true,
        SkillRotation = {1, 2, 3, 4},
        SkillDelay = 0.5,
        LootDelay = 1.0,
    },

    BossFarm = {
        Enabled = false,
        TargetBoss = "Spider Queen",
        AutoDodge = true,
        DodgeDistance = 15,
        ClearAddsFirst = true,
        PhaseDetection = true,
    },

    MaterialFarm = {
        Enabled = false,
        TargetMaterials = {
            "Blueberry", "Seagull Egg", "Withered Mushroom",
            "Goblin Finger", "Golden Tooth", "Dwarf Emblem",
            "Flame Crest", "Goblin Bone", "Copper Earring",
            "Furnace Core", "Lava Behemoth Remains"
        },
        AutoCollect = true,
        CollectRange = 20,
        RouteOptimization = true,
    },

    PotionManager = {
        Enabled = false,
        AutoCraft = true,
        AutoRefine = true,
        MinMagicScore = 50,
        PreferredElements = {"Fire", "Ice", "Earth", "Wind", "Light", "Dark", "Poison"},
        AutoEquipBest = true,
    },

    AntiDetection = {
        Enabled = true,
        RandomDelay = true,
        MinDelay = 0.1,
        MaxDelay = 0.3,
        HumanLikeMovement = true,
        JitterAmount = 0.5,
        AntiAFK = true,
    },

    ESP = {
        Enabled = false,
        ShowMobs = true,
        ShowBoss = true,
        ShowChests = true,
        ShowMaterials = true,
        ShowPlayers = false,
        MaxDistance = 500,
    },

    Movement = {
        Speed = 16,
        JumpPower = 50,
        FlyEnabled = false,
        FlySpeed = 50,
        NoClip = false,
    },

    Stats = {
        MobsKilled = 0,
        BossesKilled = 0,
        MaterialsCollected = 0,
        GoldEarned = 0,
        StartTime = tick(),
        SessionTime = 0,
    }
}


local GameData = {
    Bosses = {
        ["Dwarf King"] = {
            Location = CFrame.new(0, 0, 0),
            HP = 5000,
            Drops = {"Flame Crest", "Copper Earring", "Furnace Core"},
            DropRates = {0.43, 0.43, 0.14},
            Element = "Fire",
            Difficulty = "Sedang",
            World = 1,
        },
        ["Spider Queen"] = {
            Location = CFrame.new(0, 0, 0),
            HP = 8000,
            Drops = {"Spider Venom", "Spider Silk", "Wildbone Staff", "Poison Shard"},
            DropRates = {0.35, 0.35, 0.20, 0.10},
            Element = "Poison",
            Difficulty = "Sulit",
            World = 1,
            HasMaze = true,
            HasAdds = true,
            Phases = 3,
        },
        ["Lava Behemoth"] = {
            Location = CFrame.new(0, 0, 0),
            HP = 15000,
            Drops = {"Lava Behemoth Remains", "Furnace Core", "Magma Shard"},
            DropRates = {0.50, 0.30, 0.20},
            Element = "Fire",
            Difficulty = "Sangat Sulit",
            World = 2,
        },
    },

    Materials = {
        ["Blueberry"] = {MagicScore = 3, Source = "Semak", Locations = {}},
        ["Seagull Egg"] = {MagicScore = 5, Source = "Sarang Burung", Locations = {}},
        ["Withered Mushroom"] = {MagicScore = 4, Source = "Jamur", Locations = {}},
        ["Goblin Finger"] = {MagicScore = 15, Source = "Knife Goblin", DropRate = 0.75},
        ["Golden Tooth"] = {MagicScore = 13, Source = "Pickaxe Dwarf", DropRate = 0.25},
        ["Dwarf Emblem"] = {MagicScore = 12, Source = "Pickaxe Dwarf", DropRate = 0.75},
        ["Flame Crest"] = {MagicScore = 19, Source = "Warhammer Dwarf", DropRate = 0.13},
        ["Goblin Bone"] = {MagicScore = 21, Source = "Archer Goblin", DropRate = 0.38},
        ["Copper Earring"] = {MagicScore = 30, Source = "Mutant Archer", DropRate = 0.43},
        ["Furnace Core"] = {MagicScore = 43, Source = "Mutant/Boss", DropRate = 0.14},
        ["Lava Behemoth Remains"] = {MagicScore = 65, Source = "World 2 Boss", DropRate = 1.0},
    },

    Mobs = {
        "Knife Goblin",
        "Pickaxe Dwarf",
        "Warhammer Dwarf",
        "Archer Goblin",
        "Mutant Archer",
        "Spiderling",
        "Poison Spider",
        "Web Spider",
    },

    Chests = {},

    Races = {
        S_Tier = {"Thestrals"},
        A_Tier = {"Stellar Ambassador", "Fiendish Demon", "Ice Crystal", "Werewolf"},
        B_Tier = {"Fire Spirit", "Water Nymph", "Earth Golem", "Wind Sylph"},
    },
}


local Utility = {}

function Utility:GetRandomDelay()
    if QuantumConfig.AntiDetection.RandomDelay then
        return math.random(QuantumConfig.AntiDetection.MinDelay * 100, QuantumConfig.AntiDetection.MaxDelay * 100) / 100
    end
    return 0.1
end

function Utility:WaitRandom(min, max)
    task.wait(math.random(min * 100, max * 100) / 100)
end

function Utility:GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

function Utility:GetCharacter()
    return Player.Character
end

function Utility:GetHumanoid()
    local char = self:GetCharacter()
    if char then
        return char:FindFirstChild("Humanoid")
    end
    return nil
end

function Utility:GetRootPart()
    local char = self:GetCharacter()
    if char then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

function Utility:GetHealthPercent()
    local humanoid = self:GetHumanoid()
    if humanoid then
        return (humanoid.Health / humanoid.MaxHealth) * 100
    end
    return 100
end

function Utility:IsAlive()
    local humanoid = self:GetHumanoid()
    return humanoid and humanoid.Health > 0
end

function Utility:MoveTo(position, speed)
    local rootPart = self:GetRootPart()
    if not rootPart then return end

    local humanoid = self:GetHumanoid()
    if not humanoid then return end

    if QuantumConfig.AntiDetection.HumanLikeMovement then
        local direction = (position - rootPart.Position).Unit
        local jitter = Vector3.new(
            math.random(-10, 10) / 10 * QuantumConfig.AntiDetection.JitterAmount,
            0,
            math.random(-10, 10) / 10 * QuantumConfig.AntiDetection.JitterAmount
        )
        local targetPos = position + jitter

        humanoid:MoveTo(targetPos)
        humanoid.MoveToFinished:Wait()
    else
        humanoid:MoveTo(position)
        humanoid.MoveToFinished:Wait()
    end
end

function Utility:TeleportTo(position)
    local rootPart = self:GetRootPart()
    if rootPart then
        rootPart.CFrame = CFrame.new(position)
    end
end

function Utility:CastSpell(slot)
    local key = tostring(slot)
    if slot == 1 then key = "One"
    elseif slot == 2 then key = "Two"
    elseif slot == 3 then key = "Three"
    elseif slot == 4 then key = "Four"
    end

    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
end

function Utility:UseDash()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
end

function Utility:UseParry()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
end

function Utility:AutoClick()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

function Utility:Heal()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Five, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Five, false, game)
end

function Utility:FormatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

function Utility:Notify(title, text, duration)
    duration = duration or 3
    pcall(function()
        QuantumUI:Notify({
            Title = title,
            Content = text,
            Duration = duration,
            Icon = "Info"
        })
    end)
end


local ESP = {}
ESP.Drawings = {}

function ESP:CreateDrawing(type, properties)
    local drawing = Drawing.new(type)
    for prop, value in pairs(properties) do
        drawing[prop] = value
    end
    return drawing
end

function ESP:AddESP(object, type, color)
    if not QuantumConfig.ESP.Enabled then return end

    local esp = {}
    esp.Box = self:CreateDrawing("Square", {
        Visible = false,
        Color = color or Color3.fromRGB(255, 255, 255),
        Thickness = 1,
        Filled = false,
        Transparency = 0.7,
    })

    esp.Text = self:CreateDrawing("Text", {
        Visible = false,
        Color = color or Color3.fromRGB(255, 255, 255),
        Size = 14,
        Center = true,
        Outline = true,
        OutlineColor = Color3.fromRGB(0, 0, 0),
    })

    esp.Object = object
    esp.Type = type

    table.insert(self.Drawings, esp)
    return esp
end

function ESP:Update()
    if not QuantumConfig.ESP.Enabled then
        for _, esp in ipairs(self.Drawings) do
            esp.Box.Visible = false
            esp.Text.Visible = false
        end
        return
    end

    local camera = Workspace.CurrentCamera
    local rootPart = Utility:GetRootPart()
    if not rootPart then return end

    for _, esp in ipairs(self.Drawings) do
        if esp.Object and esp.Object.Parent then
            local pos = esp.Object:GetPivot().Position
            local distance = Utility:GetDistance(rootPart.Position, pos)

            if distance <= QuantumConfig.ESP.MaxDistance then
                local screenPos, onScreen = camera:WorldToViewportPoint(pos)

                if onScreen then
                    esp.Box.Visible = true
                    esp.Text.Visible = true
                    esp.Text.Position = Vector2.new(screenPos.X, screenPos.Y - 20)
                    esp.Text.Text = string.format("%s [%.0fm]", esp.Type, distance)
                    esp.Box.Position = Vector2.new(screenPos.X - 25, screenPos.Y - 25)
                    esp.Box.Size = Vector2.new(50, 50)
                else
                    esp.Box.Visible = false
                    esp.Text.Visible = false
                end
            else
                esp.Box.Visible = false
                esp.Text.Visible = false
            end
        else
            esp.Box.Visible = false
            esp.Text.Visible = false
        end
    end
end

function ESP:Clear()
    for _, esp in ipairs(self.Drawings) do
        if esp.Box then esp.Box:Remove() end
        if esp.Text then esp.Text:Remove() end
    end
    self.Drawings = {}
end


local AutoFarm = {}
AutoFarm.Running = false
AutoFarm.CurrentTarget = nil
AutoFarm.Thread = nil

function AutoFarm:FindNearestMob()
    local rootPart = Utility:GetRootPart()
    if not rootPart then return nil end

    local nearestMob = nil
    local nearestDistance = QuantumConfig.AutoFarm.AttackRange

    for _, mob in ipairs(Workspace:GetDescendants()) do
        if mob:IsA("Model") and mob:FindFirstChild("Humanoid") and mob:FindFirstChild("HumanoidRootPart") then
            if mob ~= Character then
                local humanoid = mob.Humanoid
                if humanoid.Health > 0 then
                    local distance = Utility:GetDistance(rootPart.Position, mob.HumanoidRootPart.Position)
                    if distance < nearestDistance then
                        local mobName = mob.Name
                        for _, validMob in ipairs(GameData.Mobs) do
                            if string.find(mobName, validMob) then
                                nearestMob = mob
                                nearestDistance = distance
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    return nearestMob
end

function AutoFarm:FindNearestMaterial()
    local rootPart = Utility:GetRootPart()
    if not rootPart then return nil end

    local nearestMaterial = nil
    local nearestDistance = QuantumConfig.MaterialFarm.CollectRange

    for _, item in ipairs(Workspace:GetDescendants()) do
        if item:IsA("BasePart") or item:IsA("MeshPart") then
            local itemName = item.Name
            for _, materialName in ipairs(QuantumConfig.MaterialFarm.TargetMaterials) do
                if string.find(itemName, materialName) or string.find(itemName, "Drop") or string.find(itemName, "Loot") then
                    local distance = Utility:GetDistance(rootPart.Position, item.Position)
                    if distance < nearestDistance then
                        nearestMaterial = item
                        nearestDistance = distance
                    end
                end
            end
        end
    end

    return nearestMaterial
end

function AutoFarm:FindNearestBoss()
    local rootPart = Utility:GetRootPart()
    if not rootPart then return nil end

    local targetBoss = QuantumConfig.BossFarm.TargetBoss
    local bossData = GameData.Bosses[targetBoss]
    if not bossData then return nil end

    for _, mob in ipairs(Workspace:GetDescendants()) do
        if mob:IsA("Model") and mob:FindFirstChild("Humanoid") then
            if string.find(mob.Name, targetBoss) or string.find(mob.Name, "Boss") then
                if mob.Humanoid.Health > 0 then
                    return mob
                end
            end
        end
    end

    return nil
end

function AutoFarm:AttackTarget(target)
    if not target or not target.Parent then return end

    local targetHumanoid = target:FindFirstChild("Humanoid")
    local targetRoot = target:FindFirstChild("HumanoidRootPart")
    if not targetHumanoid or not targetRoot then return end

    local rootPart = Utility:GetRootPart()
    if not rootPart then return end

    local attackPosition = targetRoot.Position + (targetRoot.Position - rootPart.Position).Unit * 5
    Utility:MoveTo(attackPosition, QuantumConfig.Movement.Speed)

    rootPart.CFrame = CFrame.new(rootPart.Position, targetRoot.Position)

    while targetHumanoid.Health > 0 and AutoFarm.Running do
        if not Utility:IsAlive() then break end

        if QuantumConfig.AutoFarm.AutoHeal and Utility:GetHealthPercent() < QuantumConfig.AutoFarm.HealThreshold then
            Utility:Heal()
            task.wait(0.5)
        end

        if QuantumConfig.AutoFarm.UseSkills then
            for _, slot in ipairs(QuantumConfig.AutoFarm.SkillRotation) do
                Utility:CastSpell(slot)
                task.wait(QuantumConfig.AutoFarm.SkillDelay)
            end
        end

        Utility:AutoClick()
        task.wait(Utility:GetRandomDelay())

        if targetRoot then
            rootPart.CFrame = CFrame.new(rootPart.Position, targetRoot.Position)
        end

        if targetHumanoid.Health <= 0 then
            QuantumConfig.Stats.MobsKilled = QuantumConfig.Stats.MobsKilled + 1
            break
        end
    end
end

function AutoFarm:BossFight(target)
    if not target or not target.Parent then return end

    local targetHumanoid = target:FindFirstChild("Humanoid")
    local targetRoot = target:FindFirstChild("HumanoidRootPart")
    if not targetHumanoid or not targetRoot then return end

    local rootPart = Utility:GetRootPart()
    if not rootPart then return end

    local maxHP = targetHumanoid.MaxHealth
    local currentPhase = 1

    while targetHumanoid.Health > 0 and AutoFarm.Running do
        if not Utility:IsAlive() then break end

        local hpPercent = (targetHumanoid.Health / maxHP) * 100
        if QuantumConfig.BossFarm.PhaseDetection then
            if hpPercent < 33 and currentPhase == 2 then
                currentPhase = 3
                Utility:Notify("Fase Boss", "Fase 3 - DPS Maksimal!", 2)
            elseif hpPercent < 66 and currentPhase == 1 then
                currentPhase = 2
                Utility:Notify("Fase Boss", "Fase 2 - Mode Hindar!", 2)
            end
        end

        if QuantumConfig.BossFarm.AutoDodge then
            local distance = Utility:GetDistance(rootPart.Position, targetRoot.Position)
            if distance < 10 then
                Utility:UseDash()
                task.wait(0.3)
            end
        end

        if QuantumConfig.BossFarm.ClearAddsFirst and string.find(target.Name, "Spider") then
            for _, mob in ipairs(Workspace:GetDescendants()) do
                if mob:IsA("Model") and mob:FindFirstChild("Humanoid") then
                    if string.find(mob.Name, "Spiderling") or string.find(mob.Name, "Poison Spider") then
                        if mob.Humanoid.Health > 0 then
                            self:AttackTarget(mob)
                            break
                        end
                    end
                end
            end
        end

        self:AttackTarget(target)

        task.wait(Utility:GetRandomDelay())
    end

    if targetHumanoid.Health <= 0 then
        QuantumConfig.Stats.BossesKilled = QuantumConfig.Stats.BossesKilled + 1
        Utility:Notify("Boss Dikalahkan", target.Name .. " telah dikalahkan!", 3)
    end
end

function AutoFarm:CollectLoot()
    local rootPart = Utility:GetRootPart()
    if not rootPart then return end

    for _, item in ipairs(Workspace:GetDescendants()) do
        if item:IsA("BasePart") or item:IsA("MeshPart") then
            if string.find(item.Name, "Drop") or string.find(item.Name, "Loot") or
               string.find(item.Name, "Material") or string.find(item.Name, "Gold") then
                local distance = Utility:GetDistance(rootPart.Position, item.Position)
                if distance < QuantumConfig.AutoFarm.LootRange then
                    Utility:MoveTo(item.Position, QuantumConfig.Movement.Speed)
                    task.wait(QuantumConfig.AutoFarm.LootDelay)
                    QuantumConfig.Stats.MaterialsCollected = QuantumConfig.Stats.MaterialsCollected + 1
                end
            end
        end
    end
end

function AutoFarm:Start()
    if AutoFarm.Running then return end
    AutoFarm.Running = true

    Utility:Notify("Quantum HUB", "Auto Farm Dimulai!", 3)

    AutoFarm.Thread = task.spawn(function()
        while AutoFarm.Running do
            if not Utility:IsAlive() then
                task.wait(1)
                continue
            end

            local targetType = QuantumConfig.AutoFarm.TargetType

            if targetType == "Mobs" then
                local target = self:FindNearestMob()
                if target then
                    self:AttackTarget(target)
                    self:CollectLoot()
                else
                    task.wait(1)
                end

            elseif targetType == "Boss" then
                if QuantumConfig.BossFarm.Enabled then
                    local target = self:FindNearestBoss()
                    if target then
                        self:BossFight(target)
                        self:CollectLoot()
                    else
                        local bossData = GameData.Bosses[QuantumConfig.BossFarm.TargetBoss]
                        if bossData then
                            Utility:TeleportTo(bossData.Location.Position)
                        end
                        task.wait(2)
                    end
                end

            elseif targetType == "Materials" then
                if QuantumConfig.MaterialFarm.Enabled then
                    local target = self:FindNearestMaterial()
                    if target then
                        Utility:MoveTo(target.Position, QuantumConfig.Movement.Speed)
                        task.wait(0.5)
                        QuantumConfig.Stats.MaterialsCollected = QuantumConfig.Stats.MaterialsCollected + 1
                    else
                        task.wait(1)
                    end
                end

            elseif targetType == "Chests" then
                for _, chestData in ipairs(GameData.Chests) do
                    if AutoFarm.Running then
                        Utility:TeleportTo(chestData.Position)
                        task.wait(1)
                    end
                end
            end

            task.wait(Utility:GetRandomDelay())
        end
    end)
end

function AutoFarm:Stop()
    AutoFarm.Running = false
    if AutoFarm.Thread then
        task.cancel(AutoFarm.Thread)
        AutoFarm.Thread = nil
    end
    Utility:Notify("Quantum HUB", "Auto Farm Dihentikan!", 3)
end


local AntiAFK = {}
AntiAFK.Connection = nil

function AntiAFK:Start()
    if not QuantumConfig.AntiDetection.AntiAFK then return end

    AntiAFK.Connection = UserInputService.WindowFocusReleased:Connect(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
    end)

    task.spawn(function()
        while QuantumConfig.AntiDetection.AntiAFK do
            task.wait(300)
            if Utility:IsAlive() then
                local rootPart = Utility:GetRootPart()
                if rootPart then
                    local randomOffset = Vector3.new(
                        math.random(-5, 5),
                        0,
                        math.random(-5, 5)
                    )
                    Utility:MoveTo(rootPart.Position + randomOffset, QuantumConfig.Movement.Speed)
                end
            end
        end
    end)
end

function AntiAFK:Stop()
    if AntiAFK.Connection then
        AntiAFK.Connection:Disconnect()
        AntiAFK.Connection = nil
    end
end


local Window = QuantumUI:CreateWindow({
    Name = "Quantum HUB",
    Version = QuantumConfig.Version,
    Icon = "atom",
    ToggleKey = Enum.KeyCode.LeftControl
})


local InfoTab = Window:CreateTab({Name = "Info", Icon = "info"})

InfoTab:Section({Name = "Kredit & Perjanjian", Icon = "shield", Collapsed = true})

InfoTab:Paragraph({
    Title = "Quantum HUB v" .. QuantumConfig.Version,
    Content = "Dibuat oleh: " .. QuantumConfig.Creator .. "
" ..
              "Game: " .. QuantumConfig.GameName .. "
" ..
              "Update: " .. QuantumConfig.GameUpdate .. "
" ..
              "Developer: " .. QuantumConfig.Developer
})

InfoTab:Paragraph({
    Title = "LARANGAN",
    Content = "DILARANG MENJUAL SCRIPT INI
" ..
              "DILARANG MENGUBAH KREDIT
" ..
              "DILARANG MENGGUNAKAN UNTUK KEGIATAN ILEGAL
" ..
              "DILARANG MENYEBARKAN TANPA IZIN

" ..
              "Script ini GRATIS untuk penggunaan pribadi.
" ..
              "Jika ada yang menjual, laporkan ke tim kami!"
})

InfoTab:Section({Name = "Informasi Game", Icon = "globe", Collapsed = true})

InfoTab:Paragraph({
    Title = "Spider Lair Update",
    Content = "Boss Baru: Spider Queen
" ..
              "Elemen Baru: Poison
" ..
              "Area Baru: Sarang Laba-laba dengan Labirin
" ..
              "Item Baru: Wildbone Staff, Senjata Spider
" ..
              "Ramuan Baru: Ramuan Elemen Poison
" ..
              "Kode: 'spider' (5 Race Rerolls), 'poison' (5 Race Rerolls)"
})

InfoTab:Paragraph({
    Title = "Mekanik Game",
    Content = "Brewing Ramuan: Maks 5 bahan, Sistem Magic Score
" ..
              "Kombat: Tongkat + Mantra + Dash(Q) + Parry(F)
" ..
              "Boss: Dwarf King, Spider Queen, Lava Behemoth
" ..
              "Bahan: 11 jenis dengan Magic Score berbeda
" ..
              "Ras: S-Tier (Thestrals 1%) hingga Umum"
})

InfoTab:Section({Name = "Statistik Sesi", Icon = "bar-chart-2", Collapsed = true})

local StatsLabel = InfoTab:Paragraph({
    Title = "Sesi Saat Ini",
    Content = "Musuh Dikalahkan: 0
Boss Dikalahkan: 0
Bahan Dikumpulkan: 0
Waktu Sesi: 00:00:00"
})

task.spawn(function()
    while true do
        task.wait(1)
        QuantumConfig.Stats.SessionTime = tick() - QuantumConfig.Stats.StartTime
        if StatsLabel then
            StatsLabel:SetContent(
                "Musuh Dikalahkan: " .. QuantumConfig.Stats.MobsKilled .. "
" ..
                "Boss Dikalahkan: " .. QuantumConfig.Stats.BossesKilled .. "
" ..
                "Bahan Dikumpulkan: " .. QuantumConfig.Stats.MaterialsCollected .. "
" ..
                "Waktu Sesi: " .. Utility:FormatTime(QuantumConfig.Stats.SessionTime)
            )
        end
    end
end)


local MainTab = Window:CreateTab({Name = "Main", Icon = "sword"})

MainTab:Section({Name = "Pengaturan Auto Farm", Icon = "settings", Collapsed = true})

MainTab:Toggle({
    Name = "Aktifkan Auto Farm",
    Icon = "toggle-right",
    Desc = "Mulai otomatis farming musuh",
    Default = false,
    Callback = function(value)
        QuantumConfig.AutoFarm.Enabled = value
        if value then
            AutoFarm:Start()
        else
            AutoFarm:Stop()
        end
    end
})

MainTab:Dropdown({
    Name = "Target Farm",
    Icon = "target",
    Desc = "Pilih target yang ingin difarm",
    Options = {"Mobs", "Boss", "Materials", "Chests"},
    Default = "Mobs",
    Callback = function(value)
        QuantumConfig.AutoFarm.TargetType = value
    end
})

MainTab:Slider({
    Name = "Jarak Serang",
    Icon = "maximize-2",
    Desc = "Jarak maksimal untuk menyerang target",
    Min = 10,
    Max = 200,
    Default = 50,
    Increment = 1,
    Callback = function(value)
        QuantumConfig.AutoFarm.AttackRange = value
    end
})

MainTab:Slider({
    Name = "Jarak Ambil Drop",
    Icon = "box",
    Desc = "Jarak untuk mengambil drop dari musuh",
    Min = 10,
    Max = 100,
    Default = 30,
    Increment = 1,
    Callback = function(value)
        QuantumConfig.AutoFarm.LootRange = value
    end
})

MainTab:Section({Name = "Pengaturan Kombat", Icon = "zap", Collapsed = true})

MainTab:Toggle({
    Name = "Auto Heal",
    Icon = "heart",
    Desc = "Otomatis menggunakan ramuan HP saat darah rendah",
    Default = true,
    Callback = function(value)
        QuantumConfig.AutoFarm.AutoHeal = value
    end
})

MainTab:Slider({
    Name = "Batas Heal (%)",
    Icon = "activity",
    Desc = "Persentase HP untuk mulai auto heal",
    Min = 10,
    Max = 80,
    Default = 30,
    Increment = 1,
    Callback = function(value)
        QuantumConfig.AutoFarm.HealThreshold = value
    end
})

MainTab:Toggle({
    Name = "Auto Dash (Hindar)",
    Icon = "move",
    Desc = "Otomatis dash untuk menghindar serangan",
    Default = true,
    Callback = function(value)
        QuantumConfig.AutoFarm.AutoDash = value
    end
})

MainTab:Toggle({
    Name = "Auto Cast Mantra",
    Icon = "wand",
    Desc = "Otomatis menggunakan mantra dari hotbar",
    Default = true,
    Callback = function(value)
        QuantumConfig.AutoFarm.UseSkills = value
    end
})

MainTab:Slider({
    Name = "Jeda Cast Mantra (detik)",
    Icon = "clock",
    Desc = "Waktu jeda antar penggunaan mantra",
    Min = 0.1,
    Max = 3.0,
    Default = 0.5,
    Increment = 0.1,
    Callback = function(value)
        QuantumConfig.AutoFarm.SkillDelay = value
    end
})

MainTab:Section({Name = "Pengaturan Boss Farm", Icon = "skull", Collapsed = true})

MainTab:Toggle({
    Name = "Aktifkan Boss Farm",
    Icon = "shield",
    Desc = "Mulai otomatis farming boss",
    Default = false,
    Callback = function(value)
        QuantumConfig.BossFarm.Enabled = value
    end
})

MainTab:Dropdown({
    Name = "Pilih Boss",
    Icon = "target",
    Desc = "Pilih boss yang ingin dilawan",
    Options = {"Spider Queen", "Dwarf King", "Lava Behemoth"},
    Default = "Spider Queen",
    Callback = function(value)
        QuantumConfig.BossFarm.TargetBoss = value
    end
})

MainTab:Toggle({
    Name = "Auto Hindar Serangan Boss",
    Icon = "shield-check",
    Desc = "Otomatis menghindar saat boss menyerang",
    Default = true,
    Callback = function(value)
        QuantumConfig.BossFarm.AutoDodge = value
    end
})

MainTab:Toggle({
    Name = "Bersihkan Spider Adds Dulu",
    Icon = "bug",
    Desc = "Prioritaskan membunuh spider adds sebelum boss",
    Default = true,
    Callback = function(value)
        QuantumConfig.BossFarm.ClearAddsFirst = value
    end
})

MainTab:Section({Name = "Pengaturan Material Farm", Icon = "layers", Collapsed = true})

MainTab:Toggle({
    Name = "Aktifkan Material Farm",
    Icon = "gem",
    Desc = "Otomatis mengumpulkan bahan crafting",
    Default = false,
    Callback = function(value)
        QuantumConfig.MaterialFarm.Enabled = value
    end
})

MainTab:Slider({
    Name = "Jarak Kumpul Bahan",
    Icon = "map-pin",
    Desc = "Jarak untuk mengambil bahan di tanah",
    Min = 5,
    Max = 50,
    Default = 20,
    Increment = 1,
    Callback = function(value)
        QuantumConfig.MaterialFarm.CollectRange = value
    end
})

MainTab:Section({Name = "Anti Deteksi", Icon = "shield", Collapsed = true})

MainTab:Toggle({
    Name = "Aktifkan Anti Deteksi",
    Icon = "shield-check",
    Desc = "Aktifkan sistem anti deteksi otomatis",
    Default = true,
    Callback = function(value)
        QuantumConfig.AntiDetection.Enabled = value
    end
})

MainTab:Toggle({
    Name = "Gerakan Mirip Manusia",
    Icon = "user",
    Desc = "Gerakan karakter terlihat seperti player sungguhan",
    Default = true,
    Callback = function(value)
        QuantumConfig.AntiDetection.HumanLikeMovement = value
    end
})

MainTab:Toggle({
    Name = "Anti Kick AFK",
    Icon = "clock",
    Desc = "Mencegah di kick karena AFK",
    Default = true,
    Callback = function(value)
        QuantumConfig.AntiDetection.AntiAFK = value
        if value then
            AntiAFK:Start()
        else
            AntiAFK:Stop()
        end
    end
})

MainTab:Section({Name = "Pengaturan ESP", Icon = "eye", Collapsed = true})

MainTab:Toggle({
    Name = "Aktifkan ESP",
    Icon = "eye",
    Desc = "Tampilkan informasi musuh di layar",
    Default = false,
    Callback = function(value)
        QuantumConfig.ESP.Enabled = value
        if value then
            task.spawn(function()
                while QuantumConfig.ESP.Enabled do
                    ESP:Update()
                    task.wait(0.1)
                end
                ESP:Clear()
            end)
        end
    end
})

MainTab:Toggle({
    Name = "Tampilkan Musuh",
    Icon = "target",
    Desc = "Tampilkan ESP untuk musuh biasa",
    Default = true,
    Callback = function(value)
        QuantumConfig.ESP.ShowMobs = value
    end
})

MainTab:Toggle({
    Name = "Tampilkan Boss",
    Icon = "skull",
    Desc = "Tampilkan ESP untuk boss",
    Default = true,
    Callback = function(value)
        QuantumConfig.ESP.ShowBoss = value
    end
})

MainTab:Toggle({
    Name = "Tampilkan Peti",
    Icon = "box",
    Desc = "Tampilkan ESP untuk peti harta",
    Default = true,
    Callback = function(value)
        QuantumConfig.ESP.ShowChests = value
    end
})

MainTab:Section({Name = "Aksi Cepat", Icon = "command", Collapsed = true})

MainTab:Button({
    Name = "Teleport ke Sarang Laba-laba",
    Icon = "map-pin",
    Desc = "Teleport langsung ke lokasi Spider Queen",
    Callback = function()
        local bossData = GameData.Bosses["Spider Queen"]
        if bossData then
            Utility:TeleportTo(bossData.Location.Position)
            Utility:Notify("Teleport", "Teleport ke Sarang Laba-laba!", 2)
        end
    end
})

MainTab:Button({
    Name = "Teleport ke Dwarf King",
    Icon = "map-pin",
    Desc = "Teleport langsung ke lokasi Dwarf King",
    Callback = function()
        local bossData = GameData.Bosses["Dwarf King"]
        if bossData then
            Utility:TeleportTo(bossData.Location.Position)
            Utility:Notify("Teleport", "Teleport ke Dwarf King!", 2)
        end
    end
})

MainTab:Button({
    Name = "Reset Statistik",
    Icon = "refresh-cw",
    Desc = "Reset semua statistik sesi saat ini",
    Callback = function()
        QuantumConfig.Stats.MobsKilled = 0
        QuantumConfig.Stats.BossesKilled = 0
        QuantumConfig.Stats.MaterialsCollected = 0
        QuantumConfig.Stats.StartTime = tick()
        Utility:Notify("Statistik", "Statistik sesi telah direset!", 2)
    end
})


local SettingsTab = Window:CreateTab({Name = "Settings", Icon = "sliders"})

SettingsTab:Section({Name = "Pengaturan Gerakan", Icon = "move", Collapsed = true})

SettingsTab:Slider({
    Name = "Kecepatan Jalan",
    Icon = "zap",
    Desc = "Atur kecepatan berjalan karakter",
    Min = 16,
    Max = 100,
    Default = 16,
    Increment = 1,
    Callback = function(value)
        QuantumConfig.Movement.Speed = value
        local humanoid = Utility:GetHumanoid()
        if humanoid then
            humanoid.WalkSpeed = value
        end
    end
})

SettingsTab:Slider({
    Name = "Kekuatan Lompat",
    Icon = "arrow-up",
    Desc = "Atur tinggi lompatan karakter",
    Min = 50,
    Max = 200,
    Default = 50,
    Increment = 1,
    Callback = function(value)
        QuantumConfig.Movement.JumpPower = value
        local humanoid = Utility:GetHumanoid()
        if humanoid then
            humanoid.JumpPower = value
        end
    end
})

SettingsTab:Toggle({
    Name = "Aktifkan Terbang",
    Icon = "cloud",
    Desc = "Karakter dapat terbang bebas",
    Default = false,
    Callback = function(value)
        QuantumConfig.Movement.FlyEnabled = value
    end
})

SettingsTab:Toggle({
    Name = "Aktifkan NoClip",
    Icon = "layers",
    Desc = "Karakter dapat menembus dinding",
    Default = false,
    Callback = function(value)
        QuantumConfig.Movement.NoClip = value
    end
})


AntiAFK:Start()

Utility:Notify(
    "Quantum HUB Loaded!",
    "v" .. QuantumConfig.Version .. " | Spider Lair UPD
Dibuat oleh " .. QuantumConfig.Creator,
    5
)

print("[Quantum HUB] Berhasil dimuat!")
print("[Quantum HUB] Versi: " .. QuantumConfig.Version)
print("[Quantum HUB] Game: " .. QuantumConfig.GameName)
print("[Quantum HUB] Update: " .. QuantumConfig.GameUpdate)
