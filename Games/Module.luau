local Packages = ...

local _ENV = (getgenv or getrenv or getfenv)()

local Utils, Settings = Packages.Utils, Packages.Settings
local Module, Cached = Packages.Module, Packages.Cached

local HIDDEN_SETTINGS = Packages.HIDDEN_SETTINGS

local VirtualInputManager = game:GetService('VirtualInputManager')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local CollectionService = game:GetService('CollectionService')
local UserInputService = game:GetService('UserInputService')
local TeleportService = game:GetService('TeleportService')
local TweenService = game:GetService('TweenService')
local HttpService = game:GetService('HttpService')
local RunService = game:GetService('RunService')
local StarterGui = game:GetService('StarterGui')
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService('Lighting')
local Players = game:GetService('Players')

local WorldOrigin = workspace:WaitForChild("_WorldOrigin")
local ChestModels = workspace:WaitForChild("ChestModels")
local Characters = workspace:WaitForChild("Characters")
local SeaBeasts = workspace:WaitForChild("SeaBeasts")
local Enemies = workspace:WaitForChild("Enemies")
local Boats = workspace:WaitForChild("Boats")
local NPCs = workspace:WaitForChild("NPCs")
local Map = workspace:WaitForChild("Map")

local EnemySpawns = WorldOrigin:WaitForChild("EnemySpawns")
local Locations = WorldOrigin:WaitForChild("Locations")

local WaterBasePlane = Map:WaitForChild("WaterBase-Plane", math.huge)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Effect = ReplicatedStorage:WaitForChild('Effect')

local GunValidator = Remotes:WaitForChild("Validator2")
local CommF = Remotes:WaitForChild("CommF_")
local CommE = Remotes:WaitForChild('CommE')

local Net = Modules:WaitForChild("Net")

local Camera = workspace.CurrentCamera

local Connections = Utils.Connections
local EachOthers = Utils.EachOthers
local GoodQueue = Utils.GoodQueue
local Plugins = Utils.Plugins

local Render = RunService.RenderStepped
local Heartbeat = RunService.Heartbeat
local Connect = Connections.Connect
local Stepped = RunService.Stepped

local Player = Players.LocalPlayer

local PlayerGui = Player.PlayerGui
local Backpack = Player.Backpack

local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character and Character:WaitForChild('Humanoid', math.huge)
local PrimaryPart = Character and Character:WaitForChild('HumanoidRootPart', math.huge)

local setupvalue = setupvalue or (debug and debug.setupvalue)
local getupvalue = getupvalue or (debug and debug.getupvalue)

local KILLAURA_TAG = _ENV.TAGS_KILLABLE or "NVL_KILL_AURA"
local BRING_TAG = _ENV.TAGS_BRINGABLE or "NVL_PULLS_ENEMIES"

Module.NotifyManager = (function()
    local NotifyManager = {} do
        NotifyManager.__Collections = {}
        NotifyManager.__Notification = require(ReplicatedStorage.Notification)
        NotifyManager.__Original = NotifyManager.__Notification.new
    end

    function NotifyManager:NewTrack(Word, Action)
        table.insert(self.__Collections, {
            Word = Word,
            Action = Action
        })
    end

    function NotifyManager:__check(Text)
        for _, Track in self.__Collections do
            if Text:find(Track.Word, 1, true) then
                task.delay(1.5, Track.Action, Text)
            end
        end
    end

    pcall(restorefunction, NotifyManager.__Notification.new)
    NotifyManager.__Notification.new = function(Text, Duration, Prioritized)
        NotifyManager:__check(Text)
        return NotifyManager.__Original(Text, Duration, Prioritized)
    end

    return NotifyManager
end)()

Module.GameInfo = (function()
    local NotifyManager = Module.NotifyManager

    local GameInfo = {}

    function GameInfo:GetRemainTime(NextTick, IsActive)
        if IsActive then
            return Utils:Color("Active", Color3.fromRGB(0, 255, 127))
        end

        if NextTick == 0 then
            return Utils:Color("N/A", Color3.fromRGB(150, 150, 150))
        end

        local Remaining = NextTick - tick()

        if Remaining <= 0 then
            return Utils:Color("Soon", Color3.fromRGB(255, 170, 0))
        end

        return Utils:Color(string.format("%02d:%02d:%02d", math.floor(Remaining / 3600), math.floor(Remaining % 3600 / 60), Remaining % 60), Color3.fromRGB(255, 170, 0))
    end

    function GameInfo:IsRaidCanKillAura(RaidTimer)
        local Minutes, Seconds = RaidTimer.Text:match("Time Left: (%d+):(%d+)")

        if not Minutes or not Seconds then
            return false
        end

        return tonumber(Minutes) * 60 + tonumber(Seconds) < 600
    end

    function GameInfo:GetUptime()
        local Part = Locations:FindFirstChildOfClass("Part")
        if not Part then return "00:00:00" end

        local TimeIn = Part:GetAttribute("TimeIn")
        if type(TimeIn) ~= "number" then return "00:00:00" end

        local ServerUptime = math.max(0,
            DateTime.now().UnixTimestampMillis / 1000 - TimeIn
        )

        local Hours = math.floor(ServerUptime / 3600)
        local Minutes = math.floor(ServerUptime % 3600 / 60)
        local Seconds = math.floor(ServerUptime % 60)

        return string.format("%02d:%02d:%02d", Hours, Minutes, Seconds)
    end

    GameInfo.Positions = {
        SubmergTarveler = Vector3.new(11427, -2155, 9728),
        SubmarineWorker = Vector3.new(-16266, 25, 1372),
        SubmergIsland = Vector3.new(11534, -2155, 9830),
        EliteQuest = Vector3.new(-5418, 313, -2826),
        ShipSeller3 = CFrame.new(-16928, 9, 437),
        ShipSeller2 = CFrame.new(-111, 10, 2954)
    }

    GameInfo.Sea = tonumber(workspace:GetAttribute("MAP"):match("^Sea(%d+)$") ) or 1
    GameInfo.SeaNames = { "Main", "Dressrosa", "Zou" }

    GameInfo.RaidList = (function()
        local RaidList = {}
        local Raids = require(ReplicatedStorage.Raids)

        local AdvancedRaids = Raids.advancedRaids or {}
        local NormalRaids = Raids.raids or {}

        for i = 1, #AdvancedRaids do
            table.insert(RaidList, AdvancedRaids[i])
        end

        for i = 1, #NormalRaids do
            table.insert(RaidList, NormalRaids[i])
        end

        return RaidList
    end)()

    GameInfo.NextElite = 0

    GameInfo.NextPirateRaid = 0
    GameInfo.IsPirateRaid = false do
        NotifyManager:NewTrack("Pirates have been spotted approaching", function()
            GameInfo.IsPirateRaid = true
        end)

        NotifyManager:NewTrack("The pirates are raiding Castle", function()
            GameInfo.IsPirateRaid = true
        end)

        NotifyManager:NewTrack("Good job!", function()
            GameInfo.IsPirateRaid = false
            GameInfo.NextPirateRaid = tick() + (75 * 60)
        end)

        NotifyManager:NewTrack("The pirates have stopped raiding.", function()
            GameInfo.IsPirateRaid = false
            GameInfo.NextPirateRaid = tick() + (75 * 60)
        end) 
    end

    GameInfo.NextFactory = 0
    GameInfo.IsFactory = false do
        NotifyManager:NewTrack("We are breaching the factory", function()
            GameInfo.IsFactory = true
        end)

        NotifyManager:NewTrack("THE FACTORY HAS BEEN BREACHED", function()
            GameInfo.IsFactory = true
        end)

        NotifyManager:NewTrack("101 FACTorY MALffffUNCtion", function()
            GameInfo.IsFactory = false
            GameInfo.NextFactory = tick() + (90 * 60)
        end)

        NotifyManager:NewTrack("FACTORY POISON CONTROL ACTIVATED", function()
            GameInfo.IsFactory = false
            GameInfo.NextFactory = tick() + (90 * 60)
        end) 
    end

    GameInfo.NeedCoreBrain = false do
        NotifyManager:NewTrack("supply a", function()
            GameInfo.NeedCoreBrain = true
        end) 
    end

    return GameInfo
end)()

Module.HookManager = (function()
    local Mouse = require(ReplicatedStorage.Mouse)

    local HookManager = {} do
        HookManager.__Flags = {}
    end

    function HookManager:Validate()
        for _, Flag in self.__Flags do
            if Settings[Flag] == true then
                return true
            end
        end

        return false
    end

    function HookManager:Import(Flag)
        table.insert(self.__Flags, Flag)
    end

    function HookManager:ValidUpvalues(Function)
        if type(Function) == 'function' and not iscclosure(Function) then
            local IsMouse, IsCamera, IsAngles
            local Upvalues = getupvalues(Function)

            for _, Value in Upvalues do
                if Value == Mouse then
                    IsMouse= true
                end

                if Value == Camera then
                    IsCamera = true
                end

                if typeof(Value) == "CFrame" and Value == CFrame.Angles(0, math.pi, 0) then
                    IsAngles = true
                end
            end

            return IsMouse and IsCamera and IsAngles 
        end
    end

    Module.RemoveEffect = setmetatable({}, {
        __call = function(self, Value)
            local OnSpawn = self.Cached or filtergc("function", {
                Name = "onEffectSpawn"
            }, true)

            self.Cached = OnSpawn

            if Value then
                pcall(hookfunction, OnSpawn, function()
                    return
                end)
            else
                pcall(restorefunction, OnSpawn)
            end
        end,
    })

    Module.OpenStock = setmetatable({}, {
        __call = function(self, IsAdvanced)
            if not self.Cached then
                self.Cached = require(ReplicatedStorage.Controllers.UI.FruitShop)
            end

            return self.Cached.Open(self.Cached, IsAdvanced and "AdvancedFruitDealer")
        end
    })

    if not _ENV.NVL_ORIGINAL then
        _ENV.TARGET_POSITION = Vector3.new(0, 100, 0)

        for _, Function in getgc(true) do
            if HookManager:ValidUpvalues(Function) then
                _ENV.NVL_ORIGINAL = hookfunction(Function, newcclosure(function()
                    if _ENV.NVL_GET_CLOSEST then
                        local Closest = _ENV.NVL_GET_CLOSEST()
                        if Closest then return rawset(Mouse, "Hit", Closest:GetPivot()) end 
                    end

                    if _ENV.NVL_VALIDATE_HOOK then
                        return rawset(Mouse, "Hit", CFrame.new(_ENV.TARGET_POSITION))
                    end

                    return _ENV.NVL_ORIGINAL()
                end)) 
            end
        end
    end

    _ENV.NVL_CUSTOM_REJOIN = _ENV.NVL_CUSTOM_REJOIN or function()
        task.spawn(Remotes.DoRejoin.FireServer, Remotes.DoRejoin)
    end

    return HookManager
end)()

Module.AliveManager = (function()
    local AliveManager = {} do
        AliveManager.__Counting = 0
    end

    AliveManager.HumanoidsCache = setmetatable({}, {
        __index = function(self, Character)
            local Type = Character.Parent == SeaBeasts and "Health" or "Humanoid"
            local Humanoid = Character:FindFirstChild(Type)

            if Humanoid then
                self[Character] = Humanoid
            end

            return Humanoid
        end,
        __newindex = function(self, Index, Value)
            if AliveManager.__Counting >= 50 then
                for Key, Cache in self do
                    if typeof(Cache) == "Instance" and not Cache:IsDescendantOf(game) then
                        rawset(self, Key, nil)
                    end
                end

                AliveManager.__Counting = 0
            end

            AliveManager.__Counting += 1
            return rawset(self, Index, Value)
        end
    })

    function AliveManager:GetHumanoidHealth(Humanoid)
        return Humanoid[ Humanoid.ClassName == "Humanoid" and "Health" or "Value" ]
    end

    function AliveManager:IsSeaBeastAlive(Model)
        return Model and Model:FindFirstChild('Health') and Model.Health.Value > 0
    end

    function AliveManager:IsShipSunk(Enemy)
        return Enemy:GetAttribute("Dead") ~= true and Enemy:GetAttribute("Sunk") ~= true and self:IsSeaBeastAlive(Enemy)
    end

    function AliveManager:IsShipAlive(Model)
        return Model and Model:FindFirstChild('Humanoid') and Model.Humanoid.Value > 0
    end

    function Module:IsAlive(Model)
        if Model.Parent == Boats then
            return AliveManager:IsShipAlive(Model)
        end

        if Model.Parent == Enemies and Model:GetAttribute("IsBoat") then
            return AliveManager:IsShipSunk(Model)
        end

        if Model.Parent == SeaBeasts then
            return AliveManager:IsShipSunk(Model)
        end

        local Humanoid = AliveManager.HumanoidsCache[Model]

        if Humanoid then
            return AliveManager:GetHumanoidHealth(Humanoid) > 0
        else
            return Model.Parent == Boats
        end
    end

    return AliveManager
end)()

Module.BladeHits = (function()
    local HookManager = Module.HookManager
    local GameInfo = Module.GameInfo

    local BladeHits = {} do
        BladeHits.__BladeHits = {}
        BladeHits.__Net = require(Net)
        BladeHits.__LocalPosition = nil
        BladeHits.__Debounce = 0
        BladeHits.__ShootDebounce = 0
        BladeHits.__HitFunction = nil

        BladeHits.__CoroutineId = (function()
            local UserId = tostring(Player.UserId)
            local Coroutine = tostring(coroutine.running())
            return `{UserId:sub(2, 4)}{Coroutine:sub(11, 15)}`
        end)()

        BladeHits.__ShootsPerTarget = {
            ["Dual Flintlock"] = 2
        }

        BladeHits.__ShootsFunctions = {
            ["Skull Guitar"] = function(self, Equipped, Position)
                if not Humanoid then return end

                for _, Remote in Humanoid:GetChildren() do
                    if Remote:IsA('RemoteFunction') then
                        task.spawn(Remote.InvokeServer, Remote, 'TAP', Position)
                    end
                end
            end
        }

        BladeHits.__SpecialShoots = {
            ["Skull Guitar"] = "TAP",
            ["Bazooka"] = "Position",
            ["Cannon"] = "Position",
            ["Dragonstorm"] = "Overheat"
        }

        BladeHits.__Overheat = {
            ["Dragonstorm"] = {
                MaxOverheat = 3,
                Cooldown = 0,
                TotalOverheat = 0,
                Distance = 400,
                Shooting = false
            }
        }
    end

    local RegisterAttack = BladeHits.__Net:RemoteEvent('RegisterAttack')
    local ShootGunEvent = BladeHits.__Net:RemoteEvent('ShootGunEvent')
    local RegisterHit = BladeHits.__Net:RemoteEvent('RegisterHit')

    local BonusMomentsRemoteFunction = Remotes:WaitForChild('BonusMomentsRemoteFunction')

    local SUCCESS_SHOOT, SHOOT_FUNCTION = pcall(function()
        return getupvalue(require(ReplicatedStorage.Controllers.CombatController).Attack, 9)
    end)

    local HitboxLimbs = {
        "RightLowerArm", "RightUpperArm", "LeftLowerArm",
        "LeftUpperArm", "RightHand", "LeftHand"
    }

    function BladeHits:GetRandomHitboxLimb(Model)
        return Model:FindFirstChild(HitboxLimbs[math.random(#HitboxLimbs)])
    end

    function BladeHits:CheckPlayerAlly(Target)
        if Target.Parent == Characters then
            Target = Players:GetPlayerFromCharacter(Target)
        end

        if not Target then return false end

        if tostring(Target.Team) == "Marines" and Target.Team == Player.Team then
            return false
        elseif Target:HasTag(`Ally{Player.Name}`) or Player:HasTag(`Ally{Target.Name}`) then
            return false
        end

        return true
    end

    function BladeHits:CanChangeGunTarget(Target, Enemy)
        if Enemy.Parent == SeaBeasts then
            return true
        elseif Target.Parent ~= SeaBeasts and Enemy:GetAttribute("IsBoat") then
            return true
        end

        return false
    end

    function BladeHits:ProcessHits(List, Distance)
        local MyCharacter = Player.Character
        local Targets = List:GetChildren()

        for i = 1, #Targets do
            local Character = Targets[i]
            if Character == MyCharacter or Character:GetAttribute("IsBoat") or not Module:IsAlive(Character) then continue end
            local RootPart = Character.PrimaryPart
            if RootPart and (Character.Parent ~= Characters or self:CheckPlayerAlly(Character)) then
                local Hitbox = self:GetRandomHitboxLimb(Character) or RootPart
                if Hitbox and (self.__LocalPosition - RootPart.Position).Magnitude <= Distance then
                    table.insert(self.__BladeHits, { Character, Hitbox })
                end
            end
        end
    end

    function BladeHits:ProcessSeaEventsHits(Distance)
        for _, SeaBeast in SeaBeasts:GetChildren() do
            local BasePart = SeaBeast:FindFirstChildOfClass("MeshPart")
            if Module:IsAlive(SeaBeast) and BasePart and (self.__LocalPosition - BasePart.Position).Magnitude < Distance then
                table.insert(self.__BladeHits, { SeaBeast, BasePart })
            end
        end

        for _, Boat in Enemies:GetChildren() do
            if not Boat:GetAttribute("IsBoat") then continue end
            local BasePart = Boat:FindFirstChildOfClass("MeshPart")
            if Module:IsAlive(Boat) and BasePart and (self.__LocalPosition - BasePart.Position).Magnitude < Distance then
                table.insert(self.__BladeHits, { Boat, BasePart })
            end
        end
    end

    function BladeHits:UpdateBladeHits(Distance, SeaEvents)
        Distance = Distance or HIDDEN_SETTINGS.FAST_ATTACK_DISTANCE
        self.__BladeHits = {}

        if not Settings['Players Filter'] then
            self:ProcessHits(Characters, Distance)
        end

        self:ProcessHits(Enemies, Distance)

        if SeaEvents then
            self:ProcessSeaEventsHits(Distance)
        end
    end

    function BladeHits:ConvertToGunHits()
        local Target, Hitbox
        local MinDist = math.huge

        for Index = 1, #self.__BladeHits do
            local Hit = self.__BladeHits[Index]
            local Dist = (self.__LocalPosition - Hit[2].Position).Magnitude

            if Dist < MinDist then
                MinDist = Dist
                Hitbox, Target = Hit[2], Hit[1]
            end
        end

        self.__BladeHits = { Hitbox, math.random() }
        return Hitbox.Position, Hitbox
    end

    function BladeHits:GetClosestEnemy(Distance)
        self:UpdateBladeHits(Distance, true)
        local MinDist, Closest = math.huge, nil

        for i = 1, #self.__BladeHits do
            local Magnitude = (self.__LocalPosition - self.__BladeHits[i][2].Position).Magnitude
            if Magnitude <= MinDist then
                MinDist, Closest = Magnitude, self.__BladeHits[i][2]
            end
        end

        return Closest
    end

    function BladeHits:GetValidator2()
        local V1 = getupvalue(SHOOT_FUNCTION, 16)
        local V2 = getupvalue(SHOOT_FUNCTION, 14)
        local V3 = getupvalue(SHOOT_FUNCTION, 17)
        local V4 = getupvalue(SHOOT_FUNCTION, 18)
        local V5 = getupvalue(SHOOT_FUNCTION, 15)
        local V6 = getupvalue(SHOOT_FUNCTION, 13)
        local V7 = getupvalue(SHOOT_FUNCTION, 19)

        local V8 = V6 * V2
        local V9 = (V5 * V2 + V6 * V1) % V3

        V9 = (V9 * V3 + V8) % V4
        V5 = math.floor(V9 / V3)
        V6 = V9 - V5 * V3
        V7 = V7 + 1

        setupvalue(SHOOT_FUNCTION, 16, V1)
        setupvalue(SHOOT_FUNCTION, 14, V2)
        setupvalue(SHOOT_FUNCTION, 17, V3)
        setupvalue(SHOOT_FUNCTION, 18, V4)
        setupvalue(SHOOT_FUNCTION, 15, V5)
        setupvalue(SHOOT_FUNCTION, 13, V6)
        setupvalue(SHOOT_FUNCTION, 19, V7)

        return math.floor(V9 / V4 * 16777215), V7
    end

    function BladeHits:FireGun(Equipped)
        local ShootType = self.__SpecialShoots[Equipped.Name] or "Normal"

        if ShootType == "Normal" or ShootType == "Overheat" and Equipped.Enabled then
            local Distance = ShootType == "Overheat" and self.__Overheat[Equipped.Name].Distance or 200
            self:UpdateBladeHits(Distance, true)

            if #self.__BladeHits == 0 then return end

            local Position, PrimaryPart = self:ConvertToGunHits()
            local PrimaryTarget = PrimaryPart.Parent

            if ShootType == "Overheat" then
                self.__Debounce = tick() + 9e9

                while PrimaryTarget.Parent and Module:IsAlive(PrimaryTarget) and Equipped and Equipped.Parent == Player.Character do
                    if PrimaryPart.Parent ~= PrimaryTarget or Player:DistanceFromCharacter(PrimaryPart.Position) > Distance then break end
                    Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)

                    GunValidator:FireServer(self:GetValidator2())
                    ShootGunEvent:FireServer(Position, self.__BladeHits)

                    task.wait()
                end

                self.__Debounce = 0
            elseif PrimaryTarget then
                local Shoots = self.__ShootsPerTarget[Equipped.Name] or 1

                Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)
                GunValidator:FireServer(self:GetValidator2())

                for i = 1, Shoots do
                    ShootGunEvent:FireServer(Position, self.__BladeHits)
                end
            end
        elseif ShootType == "Position" or (ShootType == "TAP" and Equipped:FindFirstChild("RemoteEvent")) then
            local Target = self:GetClosestEnemy(200)
            if not Target then return end

            GunValidator:FireServer(self:GetValidator2())

            if self.__ShootsFunctions[Equipped.Name] then
                return self.__ShootsFunctions[Equipped.Name](self, Equipped, Target.Position)
            end

            Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)

            if ShootType == "TAP" then
                Equipped.RemoteEvent:FireServer("TAP", Target.Position)
            else
                ShootGunEvent:FireServer(Target.Position)
            end
        end
    end

    function BladeHits:Provoke(Target)
        if not Target then return end

        local EscapeKey = Target:GetAttribute("EscapeKey")
        if not EscapeKey then return end

        BonusMomentsRemoteFunction:InvokeServer(
            "Escape from Alcatraz",
            "Provoke",
            EscapeKey
        )
    end

    function BladeHits:Hit( ... )
        if self.__HitFunction then
            self.__HitFunction( ... )
        else
            RegisterHit:FireServer( ... )
        end
    end

    function BladeHits:SendHits(Closest, Targets)
        RegisterAttack:FireServer(0.5)

        if Targets == 'Cloud' then
            self:Provoke(Closest)
            return self:Hit(Closest)
        end

        self:Hit(Closest, Targets, nil, self.__CoroutineId)
    end

    function BladeHits:SendSlash(Equipped, Closest)
        local LeftClick = Equipped:FindFirstChild("LeftClickRemote")
        if not LeftClick then return end

        local Direction = (self.__LocalPosition - Closest:GetPivot().Position).Unit
        for i = 1, 4 do LeftClick:FireServer(Direction, i) end
    end

    function BladeHits:GetClosestCloud()
        if GameInfo.Sea ~= 1 then return end

        local Sky = Map:FindFirstChild('Sky')
        if not Sky then return end

        local Nearest, Distance = nil, 50

        for _, Cloud in Sky:GetChildren() do
            if Cloud.Name == 'cloud' and Cloud.Transparency == 0 then
                local Magnitude = Player:DistanceFromCharacter(Cloud.Position)
                if Magnitude < Distance then
                    Nearest, Distance = Cloud, Magnitude
                end
            end
        end

        return Nearest, Distance
    end

    function BladeHits:FireTarget(Equipped, Character)
        if not Character then return end

        self.__LocalPosition = Character:GetPivot().Position

        local ToolTip = Equipped.ToolTip
        local Name = Equipped.Name

        if ToolTip == "Gun" then
            local Cooldown = Equipped:FindFirstChild("Cooldown")
            local Current = Cooldown and Cooldown.Value or 0.3

            if (tick() - self.__Debounce) < Current then return end
            self.__Debounce = tick()

            return self:FireGun(Equipped)
        end

        self:UpdateBladeHits()

        local Closest = self:GetClosestEnemy()
        if not Closest then return end

        if Name == "Ice-Ice" or Name == "Light-Light" then
            self:SendHits(Closest, self.__BladeHits)
        elseif ToolTip == "Blox Fruit" then
            self:SendSlash(Equipped, Closest)
        else
            self:SendHits(Closest, self.__BladeHits)
        end
    end

    Connect(Stepped, function()
        _ENV.NVL_VALIDATE_HOOK = HookManager:Validate()

        if not Settings['Fast Attack'] then return end

        local Character = Player.Character
        if not Character then return end

        local Equipped = Character:FindFirstChildOfClass("Tool")
        if not Equipped then return end

        Cached.Equipped = Equipped
        BladeHits:FireTarget(Equipped, Character)

        local Cloud = BladeHits:GetClosestCloud()
        if not Cloud then return end

        BladeHits:SendHits(Cloud, 'Cloud')
    end)

    task.defer(pcall, function()
        local Success, Global = pcall(require, ReplicatedStorage.Global)

        if Success and Global then
            Cached.Global = Global

            if Global.SendHitsToServer then
                BladeHits.__HitFunction = Global.SendHitsToServer
            end
        end
    end)

    return BladeHits
end)()

Module.GateModule = (function()
    local GameInfo = Module.GameInfo

    local BoatCastleTeleporters = Net:WaitForChild('RF/BoatCastleTeleporters')
    local SubmarineWorkerSpeak = Net:WaitForChild('RF/SubmarineWorkerSpeak')

    local SubmergBoundingBox = _ENV.NVL_SMBB or Instance.new('Part') do
        SubmergBoundingBox.CFrame = CFrame.new(10550, -1733, 9940)
        SubmergBoundingBox.Size = Vector3.new(2787, 1283, 2892)
        SubmergBoundingBox.CanCollide = false
        SubmergBoundingBox.Anchored = true
        SubmergBoundingBox.Parent = workspace
        SubmergBoundingBox.Transparency = 1

        _ENV.NVL_SMBB = SubmergBoundingBox
    end

    local MirrorBoundingBox = _ENV.NVL_MBB or Instance.new('Part') do
        MirrorBoundingBox.CFrame = CFrame.new(-2045, 4911, -14800)
        MirrorBoundingBox.Size = Vector3.new(1425, 895, 1415)
        MirrorBoundingBox.CanCollide = false
        MirrorBoundingBox.Anchored = true
        MirrorBoundingBox.Parent = workspace
        MirrorBoundingBox.Transparency = 1

        _ENV.NVL_MBB = MirrorBoundingBox
    end

    local GateModule = {} do
        GateModule.__Gates = { {}, {}, {} }
    end

    function GateModule:NewGates(Index, Data)
        self.__Gates[ Index ] = Data
    end

    function GateModule:IsCloudInGate(GateModel)
        local Sky = Map:FindFirstChild("Sky")
        if not Sky then return end

        local SkyTeleporter = Sky:FindFirstChild("SkyTeleporter")
        if not SkyTeleporter then return end

        local CFrame, Size = SkyTeleporter:GetBoundingBox()

        for _, Cloud in Sky:GetChildren() do
            if Cloud.Name == "cloud" and Cloud.Transparency == 0 then
                local Position = CFrame:PointToObjectSpace(Cloud.Position)

                if math.abs(Position.X) <= Size.X / 2 and math.abs(Position.Y) <= Size.Y / 2 and math.abs(Position.Z) <= Size.Z / 2 then
                    return Cloud
                end
            end
        end
    end

    function GateModule:InitiateTeleport(Name)
        local Island = Map:FindFirstChild(Name)
        if not Island then return end

        local MapTeleportC = Island:FindFirstChild('MapTeleportC')
        if not MapTeleportC then return end

        BoatCastleTeleporters:InvokeServer("InitiateTeleport", MapTeleportC)
    end

    function GateModule:IsAtSubmergIsland(Position)
        local SubmergIsland = SubmergBoundingBox
        local RelativePosition = SubmergIsland.CFrame:PointToObjectSpace(Position)
        return math.abs(RelativePosition.X) <= SubmergIsland.Size.X / 2 and math.abs(RelativePosition.Y) <= SubmergIsland.Size.Y / 2 and math.abs(RelativePosition.Z) <= SubmergIsland.Size.Z / 2
    end

    function GateModule:IsAtMirrorDimension(Position)
        local MirrorDimension = MirrorBoundingBox
        local RelativePosition = MirrorDimension.CFrame:PointToObjectSpace(Position)
        return math.abs(RelativePosition.X) <= MirrorDimension.Size.X / 2 and math.abs(RelativePosition.Y) <= MirrorDimension.Size.Y / 2 and math.abs(RelativePosition.Z) <= MirrorDimension.Size.Z / 2
    end

    function GateModule:CanUseGate()
        if GameInfo.Sea ~= 3 then return true end
        if Cached.IsDefeated == true then return true end

        local Unlockables = Module:ComF("GetUnlockables")

        if Unlockables and Unlockables.DefeatedIndraTrueForm == true then
            Cached.IsDefeated = true
            return true
        end

        return false
    end

    function GateModule:CanInitiateTeleport()
        if GameInfo.Sea ~= 3 then return true end
        if Cached.CanInitiateTeleport == true then return true end

        local IsKilled = SubmarineWorkerSpeak:InvokeServer("AskKilledTikiBoss")
        if IsKilled == true then
            Cached.CanInitiateTeleport = true
            return true
        end

        return false
    end
    function GateModule:FlamingoAccess()
        if GameInfo.Sea ~= 2 then return true end
        if Cached.FlamingoAccess == true then return true end

        local Unlockables = Module:ComF("GetUnlockables")
        if Unlockables and Unlockables.FlamingoAccess == true then
            Cached.FlamingoAccess = true
            return true
        end

        return false
    end

    GateModule:NewGates(1, {
        {
            Gates = {
                ['Gate Water'] = Vector3.new(3864, 15, -1926),
                ["Under Water"] = Vector3.new(61166, 10, 1953),
            }
        },
        {
            Gates = {
                ['Lower Sky'] = Vector3.new(-4173, 1096, -346),
                ["Upper Sky"] = Vector3.new(-6020, 5469, 2211),
            },
        }
    })

    GateModule:NewGates(2, {
        {
            Gates = {
                ['In Ghost Ship'] = Vector3.new(923, 126, 32852),
                ['Out Ghost Ship'] = Vector3.new(-6508, 89, -132)
            },
        },
        {
            Gates = {
                ['Swan Mansion'] = Vector3.new(-286, 306, 597),
                ['Don Swan Room'] = Vector3.new(2284, 15, 905)
            },
            Condition = function()
                return GateModule:FlamingoAccess()
            end,
        },
    })

    GateModule:NewGates(3, {
        {
            Gates = {
                ['WaterfallBossHitbox'] = Vector3.new(-11993, 332, -8841),
                ["TurtleEntranceBoss"] = Vector3.new(5369, 25, -497)
            },
            Condition = function()
                return Module.DataModule.__currently('__Level') >= 1950
            end,
        },
        {
            Gates = {
                ['Castle on the Sea'] = Vector3.new(-5091, 315, -3169),
                ['Tiki outpos'] = Vector3.new(-16813, 58, 305)
            },
            Condition = function()
                return GateModule:CanInitiateTeleport()
            end,
        },
        {
            Gates = {
                ['Castle on the Sea'] = Vector3.new(-5060, 317, -3193),
                ['Turtle Mansion'] = Vector3.new(-12478, 375, -7562)
            },
            Condition = function()
                return GateModule:CanUseGate()
            end
        },
        {
            Gates = {
                ['Castle on the Sea'] = Vector3.new(-5019, 315, -3188),
                ['Hydra Island'] = Vector3.new(5659, 1013, -334)
            },
            Condition = function()
                return GateModule:CanUseGate()
            end
        },
        {
            Gates = {
                ['Temple of Time'] = Vector3.new(28286, 14897, 103),
                ['Great Tree'] = Vector3.new(3029, 2281, -7325)
            }
        },
        {
            Gates = {
                ['Submerg Island'] = Vector3.new(11427, -2155, 9728),
                ['Tiki outpos [ Submerg ]'] = Vector3.new(-16266, 25, 1372)
            },
            Condition = function()
                return GateModule:CanInitiateTeleport()
            end,
        },
        {
            Gates = {
                ['Dimension'] = Vector3.new(-2137, 70, -12388),
            },
            Condition = function() return false end,
        }
    })

    function GateModule:IsPositionOnGate(Target)
        local Current = self.__Gates[ GameInfo.Sea ]
        if not Current then return end

        for _, Data in Current do
            for _, Position in Data.Gates do
                if (Position - Target).Magnitude <= 100 then
                    return true
                end
            end
        end
    end

    function GateModule:IsPlayerNearGate()
        local Current = self.__Gates[GameInfo.Sea]
        if not Current then return end

        for _, Data in Current do
            for Name, Position in Data.Gates do
                if Name ~= "Dimension" and Player:DistanceFromCharacter(Position) <= 100 then
                    return true
                end
            end
        end
    end

    function GateModule:GetGate(TargetPosition, BlockingGateName, OnlyBlocking)
        local Gates = self.__Gates[ GameInfo.Sea ]
        if not Gates then return end

        local Character = Player.Character
        if not Character then return end

        local RootPart = Character:FindFirstChild("HumanoidRootPart")
        if not RootPart then return end

        local PlayerPosition = RootPart.Position
        local DirectDistance = (PlayerPosition - TargetPosition).Magnitude

        local BestRoute = {
            Type = "Direct",
            Distance = DirectDistance,
        }

        for _, GateData in Gates do
            if GateData.Condition and not GateData.Condition() then
                continue
            end

            local GateNames = {}
            local GateList = GateData.Gates
            local GateQuest = GateData.Quest

            for GateName in GateList do
                if OnlyBlocking then
                    if BlockingGateName and BlockingGateName[ GateName ] then
                        table.insert(GateNames, GateName)
                    end
                else
                    if not BlockingGateName or not BlockingGateName[ GateName ] then
                        table.insert(GateNames, GateName)
                    end
                end
            end

            for IndexA = 1, #GateNames do
                for IndexB = 1, #GateNames do
                    if IndexA == IndexB then
                        continue
                    end

                    local GateInName = GateNames[ IndexA ]
                    local GateOutName = GateNames[ IndexB ]

                    local GateIn = GateList[ GateInName ]
                    local GateOut = GateList[ GateOutName ]

                    local GateInDistance = (PlayerPosition - GateIn).Magnitude
                    local GateOutDistance = (GateOut - TargetPosition).Magnitude
                    local Distance = GateInDistance + GateOutDistance

                    if Distance < BestRoute.Distance then
                        BestRoute = {
                            Type = "Gate",

                            GateIn = GateIn,
                            GateOut = GateOut,

                            GateInName = GateInName,
                            GateOutName = GateOutName,

                            Quest = GateQuest,
                            Distance = Distance,

                            RemoteType = GateData.RemoteType,
                        }
                    end
                end
            end
        end

        return BestRoute
    end

    return GateModule
end)()

Module.EnemiesModule = (function()
    local GameInfo = Module.GameInfo
    local EnemyLocations, SpawnLocations = {}, {}

    local BringBlacklist = {
        ["Tyrant of the skies"] = true
    }

    local EliteTags = {
        ["Tyrant of the skies"] = true,
        ["Deandre"] = true,
        ["Diablo"] = true,
        ["Urban"] = true,
    }

    local EnemiesModule = Module:Dictionary({
        "__CakePrince", "__PirateRaid", "__RaidBoss",
        "__TyrantSkies", "__Bones", "__Elite", "__Others", 
    }, {})

    local SeaCastle = CFrame.new(-5556, 314, -2988) do
        Cached.Enemies = {}
        Cached.Bring =  {}

        _ENV.TAGS_KILLABLE = KILLAURA_TAG
        _ENV.TAGS_BRINGABLE = BRING_TAG
    end

    local TagsMobs = {
        __Bones = Module:Dictionary({ "Reborn Skeleton", "Living Zombie", "Demonic Soul", "Posessed Mummy" }, true),
        __CakePrince = Module:Dictionary({ "Head Baker", "Baking Staff", "Cake Guard", "Cookie Crafter" }, true),
        __TyrantSkies = Module:Dictionary({ "Sun-kissed Warrior", "Skull Slayer", "Isle Champion", "Serpent Hunter" }, true)
    }

    local Attachment = Instance.new("Attachment") do
        Attachment.Position = Vector3.zero

        local AlignPosition = Instance.new("AlignPosition")
        AlignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
        AlignPosition.Position = Vector3.new(0, 20, 0)
        AlignPosition.Responsiveness = 200
        AlignPosition.MaxForce = math.huge
        AlignPosition.Attachment0 = Attachment
        AlignPosition.Parent = Attachment
    end

    local function GetEnemyName(strings)
        return (strings:find("Lv. ") and strings:gsub(" %pLv. %d+%p", "") or strings):gsub(" %pBoss%p", "")
    end

    local function GetParts(Enemy)
        local Humanoid = Enemy:FindFirstChildOfClass("Humanoid") or Enemy:WaitForChild("Humanoid", 10)
        local Root = Enemy:FindFirstChild("HumanoidRootPart") or Enemy:WaitForChild("HumanoidRootPart", 10)

        if not (Humanoid and Root and Enemy.Parent) then return end
        if Humanoid.Health <= 0 then return end

        return Humanoid, Root
    end

    local function NewSpawn(Part)
        local EnemyName = GetEnemyName(Part.Name)
        EnemyLocations[EnemyName] = EnemyLocations[EnemyName] or {}

        local EnemySpawn = Part.CFrame + Vector3.new(0, 25, 0)
        SpawnLocations[EnemyName] = Part

        if not table.find(EnemyLocations[EnemyName], EnemySpawn) then
            table.insert(EnemyLocations[EnemyName], EnemySpawn)
        end
    end

    local function New(list, NewEnemy)
        if table.find(list, NewEnemy) then return end

        local Humanoid = NewEnemy:WaitForChild("Humanoid")
        local Name = NewEnemy.Name

        if Humanoid and Humanoid.Health > 0 then
            table.insert(list, NewEnemy)
            Humanoid.Died:Wait()

            local index = table.find(list, NewEnemy)
            if index then table.remove(list, index) end

            if EliteTags[ Name ] then
                GameInfo.NextElite = tick() + 525
            end
        end
    end

    local function IsFromPiratesSea(Enemy)
        local Humanoid, Root = GetParts(Enemy)
        if not Root then return end

        if Enemy.Name == "rip_indra True Form" or Enemy.Name == "Blank Buddy" then return end
        if (Root.Position - SeaCastle.Position).Magnitude <= 750 then
            GameInfo.IsPirateRaid = true
            task.spawn(New, EnemiesModule.__PirateRaid, Enemy)
        end
    end

    local function IsFromEliteQuest(Enemy)
        local Humanoid, Root = GetParts(Enemy)
        if not Root then return end

        if not EliteTags[Enemy.Name] then return end
        if Enemy:GetAttribute("RaidBoss") then return end

        task.spawn(New, EnemiesModule.__Elite, Enemy)
    end

    local function NewEnemyAdded(Enemy)
        local EnemyName = Enemy.Name
        local Others = EnemiesModule.__Others

        Others[EnemyName] = Others[EnemyName] or {}
        task.spawn(New, Others[EnemyName], Enemy)

        if GameInfo.Sea == 3 then
            task.spawn(IsFromPiratesSea, Enemy)
            task.spawn(IsFromEliteQuest, Enemy)
        end

        if Enemy:GetAttribute("RaidBoss") then
            task.spawn(New, EnemiesModule.__RaidBoss, Enemy)
        elseif EnemiesModule["__" .. EnemyName] then
            task.spawn(New, EnemiesModule["__" .. EnemyName], Enemy)
        else
            for Tag, Mobs in pairs(TagsMobs) do
                if Mobs[EnemyName] then
                    task.spawn(New, EnemiesModule[Tag], Enemy)
                    break
                end
            end
        end
    end

    function EnemiesModule:Validate(Filter, Enemy)
        if Filter == nil then return true end

        if type(Filter) == "table" then
            return table.find(Filter, Enemy.Name) ~= nil
        end

        if type(Filter) == "string" then
            return Enemy.Name == Filter
        end

        return false
    end

    function EnemiesModule:IsSpawned(EnemyName)
        local Cached = SpawnLocations[EnemyName]

        if Cached and Cached.Parent then
            return (Cached:GetAttribute("Active") or EnemiesModule:GetEnemyByTag(EnemyName)) and true or false
        end

        return EnemiesModule:GetEnemyByTag(EnemyName) and true or false
    end

    function EnemiesModule:GetTagged(TagName)
        return self["__" .. TagName] or self.__Others[TagName]
    end

    function EnemiesModule:GetEnemyByTag(TagName)
        local CachedEnemy = Cached.Enemies[TagName]

        if CachedEnemy and Module:IsAlive(CachedEnemy) then
            return CachedEnemy
        end

        local Enemies = self:GetTagged(TagName)

        if Enemies and #Enemies > 0 then
            for i = 1, #Enemies do
                local Enemy = Enemies[i]

                if Module:IsAlive(Enemy) then
                    Cached.Enemies[TagName] = Enemy
                    return Enemy
                end
            end
        end
    end

    function EnemiesModule:GetClosest(Enemies)
        local SpecialTag = table.concat(Enemies, ".")
        local CachedEnemy = Cached.Enemies[SpecialTag]

        if CachedEnemy and Module:IsAlive(CachedEnemy) then
            return CachedEnemy
        end

        local Distance, Nearest = math.huge, nil

        for i = 1, #Enemies do
            local Enemy = self:GetClosestByTag(Enemies[i])
            local Magnitude = Enemy and Player:DistanceFromCharacter(Enemy:GetPivot().Position)

            if Enemy and Magnitude <= Distance then
                Distance, Nearest = Magnitude, Enemy
            end
        end

        if Nearest then
            Cached.Enemies[SpecialTag] = Nearest
            return Nearest
        end
    end

    function EnemiesModule:GetClosestByTag(TagName)
        local CachedEnemy = Cached.Enemies[TagName]

        if CachedEnemy and Module:IsAlive(CachedEnemy) then
            return CachedEnemy
        end

        local Enemies = self:GetTagged(TagName)

        if Enemies and #Enemies > 0 then
            local Distance, Nearest = math.huge, nil

            for i = 1, #Enemies do
                local Enemy = Enemies[i]
                local PrimaryPart = Enemy.PrimaryPart

                if PrimaryPart and Module:IsAlive(Enemy) then
                    local Magnitude = Player:DistanceFromCharacter(PrimaryPart.Position)

                    if Magnitude <= 15 then
                        Cached.Enemies[TagName] = Enemy
                        return Enemy
                    elseif Magnitude <= Distance then
                        Distance, Nearest = Magnitude, Enemy
                    end
                end
            end

            if Nearest then
                Cached.Enemies[TagName] = Nearest
                return Nearest
            end
        end
    end

    function EnemiesModule:GetEnemies(Range, Names)
        local Distance, Nearest = Range or math.huge, nil
        local EnemiesList = Enemies:GetChildren()

        for i = 1, #EnemiesList do
            local Enemy = EnemiesList[i]

            if not Enemy.PrimaryPart then continue end
            if not self:Validate(Names, Enemy) then continue end
            if not Module:IsAlive(Enemy) then continue end

            local Magnitude = Player:DistanceFromCharacter(Enemy:GetPivot().Position)

            if Magnitude < Distance then
                Distance = Magnitude
                Nearest = Enemy
            end
        end

        return Nearest
    end

    function EnemiesModule:GetSpawnPoints(Names)
        local IsString = type(Names) == "string"
        Names = IsString and { Names } or Names

        local SpawnPoints = {
            Names = Names,
            IsLoop = IsString,
            NameIndex = 1,
            PositionIndex = 1
        }

        while SpawnPoints.NameIndex <= #Names do
            local EnemyName = Names[SpawnPoints.NameIndex]
            local EnemySpawner = EnemyLocations[EnemyName]

            if EnemySpawner then
                SpawnPoints.EnemyName = EnemyName
                SpawnPoints.EnemySpawner = EnemySpawner
                return SpawnPoints
            end

            SpawnPoints.NameIndex += 1
        end

        return nil
    end

    function EnemiesModule:NextSpawnAxis(SpawnPoints)
        if not SpawnPoints or not SpawnPoints.EnemySpawner then
            return nil
        end

        if SpawnPoints.Cooldown and tick() < SpawnPoints.Cooldown then
            return SpawnPoints.LastTarget
        end

        for I = SpawnPoints.PositionIndex, #SpawnPoints.EnemySpawner do
            local Position = SpawnPoints.EnemySpawner[I]

            if (PrimaryPart.Position - Position.Position).Magnitude >= 3 then
                if SpawnPoints.PositionIndex ~= I then
                    SpawnPoints.Cooldown = tick() + 1
                end

                SpawnPoints.PositionIndex = I
                SpawnPoints.LastTarget = Position
                return Position
            end
        end

        if SpawnPoints.IsLoop then
            SpawnPoints.PositionIndex = 1
            return nil
        end

        for I = SpawnPoints.NameIndex + 1, #SpawnPoints.Names do
            local NextName = SpawnPoints.Names[I]
            local NextSpawner = EnemyLocations[NextName]

            if NextSpawner then
                SpawnPoints.NameIndex = I
                SpawnPoints.EnemyName = NextName
                SpawnPoints.EnemySpawner = NextSpawner
                SpawnPoints.PositionIndex = 1
                SpawnPoints.Cooldown = nil
                return self:NextSpawnAxis(SpawnPoints)
            end
        end

        return nil
    end

    function EnemiesModule:IsOnRange(Index)
        local Counting = 0

        for _, Enemy in Enemies:GetChildren() do
            if Module:IsAlive(Enemy) and Player:DistanceFromCharacter(Enemy:GetPivot().Position) <= 50 then
                Counting += 1

                if Counting >= Index then
                    return false
                end
            end
        end

        return true
    end

    local function Bring(Enemy:Model)
        local RootPart = Enemy:WaitForChild("HumanoidRootPart")
        local Humanoid = Enemy:WaitForChild("Humanoid")

        local EnemyName = Enemy.Name
        if BringBlacklist[EnemyName] then return end

        local CloneAttachment = Attachment:Clone()
        local AlignPosition = CloneAttachment.AlignPosition
        CloneAttachment.Parent = RootPart

        while Enemy and Enemy.Parent == Enemies and Enemy:HasTag(BRING_TAG) do
            if not _ENV.OnFarm then break end
            if not Humanoid or Humanoid.Health <= 0 then break end
            if not RootPart or RootPart.Parent ~= Enemy then break end

            local Target = Cached.Bring[EnemyName]

            if Target and (Target.Position - RootPart.Position).Magnitude <= Settings["Bring Distance"] then
                if AlignPosition.Position ~= Target.Position then
                    AlignPosition.Position = Target.Position
                end
            else
                break
            end task.wait()
        end

        if Enemy and Enemy:HasTag(BRING_TAG) then Enemy:RemoveTag(BRING_TAG) end
        if CloneAttachment then CloneAttachment:Destroy() end
    end

    local function KillAura(Enemy)
        local Humanoid = Enemy:FindFirstChild("Humanoid")
        local RootPart = Enemy:FindFirstChild("HumanoidRootPart")

        pcall(sethiddenproperty, Player, "SimulationRadius", math.huge)

        if Humanoid and RootPart then
            RootPart.CanCollide = false
            RootPart.Size = Vector3.new(60, 60, 60)
            Humanoid:ChangeState(15)
            Humanoid.Health = 0
            task.wait()
            Enemy:RemoveTag(KILLAURA_TAG)
        end
    end

    for _, Enemy in CollectionService:GetTagged("BasicMob") do task.spawn(NewEnemyAdded, Enemy) end
    for _, Spawn in EnemySpawns:GetChildren() do NewSpawn(Spawn) end

    Connect(CollectionService:GetInstanceAddedSignal("BasicMob"), NewEnemyAdded)
    Connect(CollectionService:GetInstanceAddedSignal(KILLAURA_TAG), KillAura)
    Connect(CollectionService:GetInstanceAddedSignal(BRING_TAG), Bring)
    Connect(EnemySpawns.ChildAdded, NewSpawn)

    return EnemiesModule
end)()

Module.DataModule = (function()
    local GameInfo = Module.GameInfo
    local Data = Player:WaitForChild('Data', math.huge)

    local DataModule = {} do
        DataModule.__Data = Module:Import('Games/DateModule')(GameInfo.Sea)
        DataModule.__Currently = DataModule.__Data.Currently
    end

    function DataModule.__get(Index)
        return DataModule.__Data[ Index ]
    end

    function DataModule.__currently(Index)
        return DataModule.__Currently[ Index ]
    end

    function DataModule.__new(Instancer)
        local Name = Instancer.Name
        local Currently = DataModule.__Currently

        if not Instancer.ClassName:find('Value') then
            return false
        end

        if not Currently[`__{Name}`] then
            Currently[`__{Name}`] = Instancer.Value
            Connect(Instancer:GetPropertyChangedSignal('Value'), function()
                Currently[`__{Name}`] = Instancer.Value
            end)
        end
    end

    function DataModule:GetClosestByMaterial(Name)
        return self.__Currently.Materials[Name]
    end

    for _, Instance in Data:GetChildren() do DataModule.__new(Instance) end
    Connect(Data.ChildAdded, DataModule.__new)

    return DataModule
end)()

Module.TweenManager = loadstring([[
    local TweenService = ...

local TweenManager = {}
TweenManager.__index = TweenManager

local Tweens = {}
local EasingStyle = Enum.EasingStyle.Linear

function TweenManager.new(Object, Time, Property, Value)
    local self = setmetatable({}, TweenManager)

    self.Value = Value
    self.Object = Object

    self.Info = TweenInfo.new(Time, EasingStyle)
    self.Tween = TweenService:Create(Object, self.Info, {
        [ Property ] = Value
    })

    self.Tween:Play()

    if Tweens[ Object ] then
        Tweens[ Object ]:Destroy()
    end

    Tweens[ Object ] = self

    return self
end

function TweenManager:Destroy()
    self.Tween:Pause()
    self.Tween:Destroy()

    Tweens[ self.Object ] = nil
    setmetatable(self, nil)
end

function TweenManager:StopTween(Object)
    if Object and Tweens[ Object ] then
        Tweens[ Object ]:Destroy()
    end
end

return TweenManager
]])(TweenService)

Module.BodyVelocity = function(PlayerManager)
    local DisabledParts = {}
    local WasNoclip = false

    local BodyVelocity = Instance.new("BodyVelocity") do
        BodyVelocity.Velocity = Vector3.zero
        BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        BodyVelocity.P = 1000
    end

    local Highlight = Instance.new("Highlight") do
        Highlight.FillColor = Color3.fromRGB(255, 255, 255)
        Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        Highlight.FillTransparency = 0.3
    end

    if _ENV.tween_bodyvelocity then
        _ENV.tween_bodyvelocity:Destroy()
    end

    if _ENV.highlight then
        _ENV.highlight:Destroy()
    end

    _ENV.highlight = Highlight
    _ENV.tween_bodyvelocity = BodyVelocity

    local CanTouchObjects = {} do
        local function AddObjectToBaseParts(Object)
            if Object:IsA("BasePart") and Object.CanTouch then
                table.insert(CanTouchObjects, Object)
            end
        end

        local function RemoveObjectsFromBaseParts(BasePart)
            local index = table.find(CanTouchObjects, BasePart)

            if index then
                table.remove(CanTouchObjects, index)
            end
        end

        local function NewCharacter(Character)
            table.clear(CanTouchObjects)
            table.clear(DisabledParts)
            WasNoclip = false

            for _, Object in Character:GetDescendants() do AddObjectToBaseParts(Object) end
            Character.DescendantAdded:Connect(AddObjectToBaseParts)
            Character.DescendantRemoving:Connect(RemoveObjectsFromBaseParts)
        end

        Connect(Player.CharacterAdded, NewCharacter)
        task.spawn(NewCharacter, Player.Character)
    end

    local function NoClipOnStepped(Character)
        if _ENV.OnFarm then
            WasNoclip = true

            for _, BasePart in Character:GetDescendants() do
                if BasePart:IsA("BasePart") and BasePart.CanCollide then
                    DisabledParts[BasePart] = true
                    BasePart.CanCollide = false
                end
            end

            _ENV.NVL_BODY_TOUCH = Module.GateModule:IsPlayerNearGate()

            for i = 1, #CanTouchObjects do
                if CanTouchObjects[i].Parent then
                    CanTouchObjects[i].CanTouch = not _ENV.NVL_BODY_TOUCH
                end
            end
        elseif WasNoclip then
            WasNoclip = false

            for BasePart in DisabledParts do
                if BasePart.Parent then
                    BasePart.CanCollide = true
                end
            end

            table.clear(DisabledParts)

            for i = 1, #CanTouchObjects do
                if CanTouchObjects[i].Parent then
                    CanTouchObjects[i].CanTouch = true
                end
            end
        end
    end

    local function UpdateVelocityOnStepped(Character)
        local BasePart = Character:FindFirstChild("Head")
        local Humanoid = Character:FindFirstChild("Humanoid")

        local BodyVelocity = _ENV.tween_bodyvelocity
        local Highlight = _ENV.highlight

        if _ENV.OnFarm and BasePart and Humanoid and Humanoid.Health > 0 then
            if BodyVelocity.Parent ~= BasePart then
                BodyVelocity.Parent = BasePart
            end

            if Highlight.Parent ~= Character then
                Highlight.Parent = Character
            end
        elseif BodyVelocity.Parent then
            BodyVelocity.Parent = nil
            Highlight.Parent = nil
        end

        if BodyVelocity.Velocity ~= Vector3.zero and (not Humanoid or not Humanoid.SeatPart or not _ENV.OnFarm) then
            BodyVelocity.Velocity = Vector3.zero
            Highlight.Parent = nil
        end
    end

    Connect(Render, function()
        if PlayerManager and PlayerManager:IsAlive() and Player.Character then
            UpdateVelocityOnStepped(Player.Character)
            NoClipOnStepped(Player.Character)
        end
    end)

    return BodyVelocity
end

Module.ItemsService = (function()
    local TextLabels = Cached.TextLabels

    local ItemReplication = require(ReplicatedStorage.ItemReplicationService)
    local ItemConfig = require(ReplicatedStorage.ItemConfig)
    local ItemId = require(ReplicatedStorage.Economy.ItemId)

    local ItemsService = {} do
        ItemsService.__Requirements = {}
        ItemsService.__Unlocked = {}
        ItemsService.__Mastery = {}
        ItemsService.__Fruits = {}
        ItemsService.__Items = {}
        ItemsService.__Count = {}
    end

    local function Resolve(ItemId)
        local Conf = ItemConfig.match(ItemId):asNullable()

        if type(Conf) ~= "table" or type(Conf.Index) ~= "table" then
            return nil, nil
        end

        return Conf.Index.StorageKey, Conf.Index.IdType
    end

    local function IsBaseFruit(Key)
        local Length = #Key

        if Length % 2 == 0 then
            return false
        end

        local Middle = (Length + 1) / 2
        return Key:sub(Middle, Middle) == "-" and Key:sub(1, Middle - 1) == Key:sub(Middle + 1)
    end

    local function Update(Item)
        if type(Item) ~= "table" then return end
        local Details = Item.details or Item

        if Details.Type == "Wear" then
            Details.Type = "Accessory"
        end

        local Name = Details.Name
        if not Name then return end

        ItemsService.__Items[Name] = Item

        if not ItemsService.__Unlocked[Name] then
            ItemsService.__Unlocked[Name] = true
        end

        if Details.Count ~= nil then
            ItemsService.__Count[Name] = Details.Count
        end

        if Details.Mastery ~= nil then
            ItemsService.__Mastery[Name] = Details.Mastery
        end

        if Details.MasteryRequirements ~= nil then
            ItemsService.__Requirements[Name] = Details.MasteryRequirements
        end

        if Details.Count ~= nil and Details.ItemId and IsBaseFruit(Name) then
            local Conf = ItemConfig.match(Details.ItemId):asNullable()
            local Groups = Conf and Conf.Inventory and Conf.Inventory.Groups

            if Groups and table.find(Groups, "Treasure") then
                ItemsService.__Fruits[Name] = ItemsService.__Count[Name]
            end
        end
    end

    local function Remove(Name)
        if type(Name) == "table" then
            local Details = Name.details or Name
            Name = Details.Name
        end

        if type(Name) == "string" then
            ItemsService.__Unlocked[Name] = nil
            ItemsService.__Mastery[Name] = nil
            ItemsService.__Count[Name] = nil
            ItemsService.__Items[Name] = nil
            ItemsService.__Fruits[Name] = nil
        end
    end

    local function NewCatagory(Set)
        local Items = ItemReplication:GetItems(Set.Key)
        if type(Items) ~= "table" then return end

        for _, Entry in Items do
            local Name, ItemType = Resolve(Entry.ItemId)
            if not Name then continue end

            Update({ details = {
                Name = Name,
                Type = ItemType,
                ItemId = Entry.ItemId,
                UID  = Entry.NetworkedUID,
                [ Set.Field ] = Entry.Value,
            }})
        end
    end

    local function ItemChanged(Key, ItemId, Uid, Value, OldValue, SkipFlag)
        if SkipFlag then return end

        local Name, ItemType = Resolve(ItemId)
        if not Name then return end

        if Key == "IsOwned" then
            if Value == nil then
                Remove(Name)
            else
                Update({ details = { Name = Name, Type = ItemType, ItemId = ItemId, UID = Uid } })
            end
        elseif Key == "Quantity" then
            if Value == nil then
                ItemsService.__Fruits[Name] = nil
            else
                Update({ details = { Name = Name, Type = ItemType, ItemId = ItemId, UID = Uid, Count = Value } })
            end
        elseif Key == "Mastery" then
            Update({ details = { Name = Name, Type = ItemType, ItemId = ItemId, UID = Uid, Mastery = Value } })
        end
    end

    function ItemsService:InCharacter(Name)
        return (Character and Character:FindFirstChild(Name)) or (Backpack and Backpack:FindFirstChild(Name))
    end

    function ItemsService:HaveItem(Name)
        return self.__Unlocked[Name] == true
    end

    function ItemsService:GetCount(Name)
        return self.__Count[Name] or 0
    end

    function ItemsService:GetItemId(Name)
        return ItemId.getId(Name, "Skin"):asNullable()
    end

    function ItemsService:GetMastery(Name)
        return self.__Mastery[Name] or 0
    end

    function ItemsService:GetItem(Name)
        return self.__Items[Name]
    end

    function ItemsService.__InitClient()
        local Keys = require(ReplicatedStorage.ItemReplicationService.KEYS)
        local Quantity = {
            { Key = Keys.QUANTITY, Field = "Count"   },
            { Key = Keys.MASTERY,  Field = "Mastery" }
        }

        for _, Set in Quantity do NewCatagory(Set) end
        ItemReplication:ConnectOnChanged(ItemChanged)
    end

    return ItemsService
end)()

Module.PlayerManager = (function()
    local PlayerManager = {} do
        PlayerManager.__IsBringed = false
    end

    local EnemiesModule = Module.EnemiesModule
    local GateModule = Module.GateModule
    local GameInfo = Module.GameInfo

    local Positions = GameInfo.Positions

    local BodyVelocity = Module.BodyVelocity(PlayerManager)
    local TweenManager = Module.TweenManager

    function PlayerManager:IsAlive()
        if not Character then return end
        if not Humanoid then return end
        if not PrimaryPart then return end
        if not Backpack then return end

        return (Humanoid and Humanoid.Health > 0) or PrimaryPart ~= nil
    end

    function PlayerManager:GetHealth()
        return Humanoid and Humanoid.Health / Humanoid.MaxHealth * 100 or 0
    end

    function PlayerManager.__to(Target, Sit)
        if not PlayerManager:IsAlive() then return end

        if typeof(Target) == "Vector3" then
            Target = CFrame.new(Target)
        end

        if not Sit and Humanoid.Sit then
            Humanoid.Sit = false
        end

        local Velocity = Settings["Travel Velocity"] or HIDDEN_SETTINGS.TWEEN_SPEED
        local Distance = Player:DistanceFromCharacter(Target.Position)

        if Distance <= 100 then
            return TweenManager.new(PrimaryPart, 0.125, "CFrame", Target)
        end

        return TweenManager.new(PrimaryPart, Distance / Velocity, "CFrame", Target)
    end

    function PlayerManager.__stopship()
        local LastShip = Cached.LastShip

        if LastShip and LastShip.Parent then
            local VehicleSeat = LastShip:FindFirstChild("VehicleSeat")
            if VehicleSeat then TweenManager:StopTween(VehicleSeat) end
            Cached.LastShip = nil
        end
    end

    function PlayerManager.__stop()
        if not BodyVelocity.Parent and Player.Character then
            TweenManager:StopTween(PrimaryPart)
            PlayerManager.__stopship()
        end
    end

    function PlayerManager:EnabledBuso()
        if Character and not Character:FindFirstChild('HasBuso') then
            Module:ComF('Buso')
        end
    end

    function PlayerManager:EquipTool(ToolName, IsToolTip)
        if not self:IsAlive() then return end

        local LastEquip = Cached.LastEquip

        if LastEquip and (IsToolTip and LastEquip.ToolTip or LastEquip.Name) == ToolName and LastEquip.Parent == Character then
            if LastEquip:GetAttribute('Locks') then
                LastEquip:SetAttribute('Locks', nil)
            end

            return LastEquip
        end

        for _, Tool in Backpack:GetChildren() do
            if not Tool:IsA("Tool") then continue end
            if (IsToolTip and Tool.ToolTip or Tool.Name) ~= ToolName then continue end
            if Tool:GetAttribute('Locks') then
                Tool:SetAttribute('Locks', nil)
            end

            Humanoid:EquipTool(Tool)
            Cached.LastEquip = Tool

            return Tool
        end
    end

    function PlayerManager:Travel(Target, HaveSit, BlockingGate, Exclude)
        if not PlayerManager:IsAlive() then return end

        _ENV.OnFarm = true

        if typeof(Target) == "Vector3" then
            Target = CFrame.new(Target)
        end

        if Player:DistanceFromCharacter(Target.Position) <= 750 then
            return self.__to(Target, HaveSit)
        end

        local Route = GateModule:GetGate(Target.Position, BlockingGate, Exclude)
        if not Route then return self.__to(Target, HaveSit) end

        local GateOut = Route.GateOut
        local GateIn = Route.GateIn

        local GateOutName = Route.GateOutName
        local GateInName = Route.GateInName

        local IsTargetAtSubmerg = GateModule:IsAtSubmergIsland(Target.Position)
        local IsPlayerAtSubmerg = GateModule:IsAtSubmergIsland(PrimaryPart.Position)

        if IsTargetAtSubmerg and not IsPlayerAtSubmerg then
            if Player:DistanceFromCharacter(Positions.SubmarineWorker) > 5 then
                return self:Travel(Positions.SubmarineWorker, HaveSit, {
                    ['Tiki outpos [ Submerg ]'] = true,
                    ['Submerg Island'] = true
                })
            end

            Net["RF/SubmarineWorkerSpeak"]:InvokeServer("TravelToSubmergedIsland")
            return task.wait(1.5)
        end

        if IsPlayerAtSubmerg and not IsTargetAtSubmerg then
            if Player:DistanceFromCharacter(Positions.SubmergTarveler) > 5 then
                return self.__to(CFrame.new(Positions.SubmergTarveler), HaveSit)
            end

            Net["RF/SubmarineTransportation"]:InvokeServer("InitiateTeleport", "Tiki Outpost")
            task.wait(1.5)

            return self:Travel(Target, HaveSit, BlockingGate, Exclude)
        end

        local IsTargetAtDimension = GateModule:IsAtMirrorDimension(Target.Position)
        local IsPlayerAtDimension = GateModule:IsAtMirrorDimension(PrimaryPart.Position)

        if IsTargetAtDimension and not IsPlayerAtDimension then
            if Player:DistanceFromCharacter(Vector3.new(-2137, 70, -12388)) >= 5 then
                return self:Travel(CFrame.new(-2137, 70, -12388), HaveSit, BlockingGate, Exclude)
            end

            local CakeLoaf = Map:FindFirstChild('CakeLoaf')            
            if not CakeLoaf then return end

            local BigMirror = CakeLoaf:FindFirstChild('BigMirror')
            if not BigMirror then return end

            local Main = BigMirror:FindFirstChild('Main')
            if not Main then return end

            task.wait(0.5)

            for i = 0, 1 do
                pcall(firetouchinterest, PrimaryPart, Main, i)
            end

            return task.wait(0.5) 
        end

        if Route.Type == "Direct" then
            return self.__to(Target, HaveSit)
        end

        if GateInName == 'Lower Sky' and GateModule:IsCloudInGate() then
            self:EquipTool("Melee", true)
            return self.__to(CFrame.new(-4205, 1100, -369), HaveSit)
        end

        if GateOutName == 'Under Water' then
            if Player:DistanceFromCharacter(Vector3.new(4048, 18, -1812)) > 5 then
                return self.__to(CFrame.new(4048, 18, -1812), HaveSit)
            end
        elseif GateOutName == 'Great Tree' then
            if Player:DistanceFromCharacter(Vector3.new(28607, 14897, 106)) > 5 then
                return self.__to(CFrame.new(28607, 14897, 106), HaveSit)
            end
        elseif Player:DistanceFromCharacter(GateIn) > 5 then
            return self.__to(GateIn, HaveSit)
        end

        TweenManager:StopTween(PrimaryPart)
        task.wait(0.5)

        if GateOutName == 'Under Water' then
            Module:ComF("requestEntrance", Vector3.new(61163, 11, 1819))
        elseif GateInName == 'Tiki outpos' then
            GateModule:InitiateTeleport('TikiOutpost')
        elseif GateOutName == 'Tiki outpos' then
            GateModule:InitiateTeleport('Boat Castle')
        elseif GateOutName == 'Great Tree' then
            Module:ComF("RaceV4Progress", "TeleportBack")
        elseif GateOutName == 'Temple of Time' then
            Module:ComF("RaceV4Progress", "Check")
            Module:ComF("RaceV4Progress", "Teleport")
        elseif GateOutName == 'Submerg Island' then
            Net["RF/SubmarineWorkerSpeak"]:InvokeServer("TravelToSubmergedIsland")
        elseif GateInName == 'Submerg Island' then
            Net["RF/SubmarineTransportation"]:InvokeServer("InitiateTeleport", "Tiki Outpost")
        else
            Module:ComF("requestEntrance", GateOut)
        end

        task.wait(0.5)
    end

    function PlayerManager:BringEnemies(ToEnemy, CustomCFrame, Distance)
        if not Module:IsAlive(ToEnemy) or not ToEnemy.PrimaryPart then
            return nil
        end

        pcall(sethiddenproperty, Player, "SimulationRadius", math.huge)

        if Distance or Settings['Enabled Bring'] then
            local Name = ToEnemy.Name
            local Target = CustomCFrame or ToEnemy.PrimaryPart.CFrame
            local MaxDistance = Distance or Settings['Bring Distance']

            if not Cached.Bring[Name] or (Target.Position - Cached.Bring[Name].Position).Magnitude > 25 then
                Cached.Bring[Name] = Target
            end

            local EnemyList = EnemiesModule:GetTagged(Name) or Enemies:GetChildren()

            for i = 1, #EnemyList do
                local Enemy = EnemyList[i]

                if Enemy.Name == Name and Enemy.Parent == Enemies and not Enemy:HasTag(BRING_TAG) and Enemy:FindFirstChild("CharacterReady") then
                    local PrimaryPart = Enemy.PrimaryPart

                    if Module:IsAlive(Enemy) and PrimaryPart then
                        if Player:DistanceFromCharacter(PrimaryPart.Position) < MaxDistance then
                            Enemy.Humanoid.WalkSpeed = 0
                            Enemy.Humanoid.JumpPower = 0
                            Enemy:AddTag(BRING_TAG)
                        end
                    end
                end
            end
        else
            if not Cached.Bring[ToEnemy] then
                Cached.Bring[ToEnemy] = ToEnemy.PrimaryPart.CFrame
            end

            ToEnemy.PrimaryPart.CFrame = Cached.Bring[ToEnemy]
        end
    end

    function PlayerManager:WaitEnemies(Names)
        Names = type(Names) == 'string' and { Names } or Names

        local Enemy = EnemiesModule:GetClosest(Names)

        if Enemy then
            self._SpawnPoints = nil
            self._SpawnKey = nil
            return
        end

        local Copy = table.clone(Names);table.sort(Copy)
        local Key = table.concat(Copy, "|")

        if self._SpawnKey ~= Key then
            self._SpawnPoints = nil
            self._SpawnKey = Key
        end

        if not self._SpawnPoints then
            self._SpawnPoints = EnemiesModule:GetSpawnPoints(Names)
        end

        local SpawnPoints = self._SpawnPoints
        if not SpawnPoints then return end

        local Target = EnemiesModule:NextSpawnAxis(SpawnPoints)
        if not Target then
            self._SpawnPoints = nil
            self._SpawnKey = nil
            return
        end

        PlayerManager:Travel(Target)

        return true
    end

    function PlayerManager:GetYAxis(ToolTip)
        if ToolTip == 'Blox Fruit' then
            return Settings["Fruit Axis Distance"] or 15
        end

        if ToolTip == 'Gun' then
            return Settings['Gun Axis Distance'] or 35
        end

        return Settings['Melee Axis Distance'] or 25
    end

    PlayerManager.SpacialKills = {
        ['Cake Prince'] = "Below",
        ['Dough King'] = "Below",
    }

    function PlayerManager:Kills(Enemy, Break)
        if not self:IsAlive() or not Module:IsAlive(Enemy) then
            return false
        end

        local SpacialKill = self.SpacialKills[ Enemy.Name ]

        repeat Heartbeat:Wait()
            local Weapon = Settings["Select Weapon"] or "Melee"

            local HumanoidRootPart = Enemy:FindFirstChild("HumanoidRootPart")
            if not HumanoidRootPart then break end

            self:EnabledBuso()
            self:EquipTool(Weapon, true)

            local Height = self:GetYAxis(Weapon)

            if SpacialKill == "Below" then
                Height = -math.abs(Height)
            end

            local YAxis = Vector3.new(0, Height, 0)
            local Target = CFrame.new(HumanoidRootPart.Position + YAxis)
            local Distance = Player:DistanceFromCharacter(Target.Position)

            if Distance <= 20 and not self.__IsBringed then
                self:BringEnemies(Enemy)
                self.__IsBringed = EnemiesModule:IsOnRange(2)
            end

            if Distance > 5 then self:Travel(Target) end
        until not _ENV.OnFarm or (Break and Break()) or not Module:IsAlive(Enemy) or not self:IsAlive()

        self.__IsBringed = false
    end

    function PlayerManager:KillPlayer(Enemy, Break)
        if not self:IsAlive() or not Module:IsAlive(Enemy) then
            return false
        end

        repeat Heartbeat:Wait()
            local Weapon = Settings["Select Weapon"] or "Melee"

            local HumanoidRootPart = Enemy:FindFirstChild("HumanoidRootPart")
            if not HumanoidRootPart then break end

            self:EnabledBuso()
            self:EquipTool(Weapon, true)

            local Height = self:GetYAxis(Weapon)
            local Behind = -HumanoidRootPart.CFrame.LookVector * 5

            local Position = HumanoidRootPart.Position + Behind + Vector3.new(0, Height, 0)
            local Target = CFrame.lookAt(Position, HumanoidRootPart.Position)
            local Distance = Player:DistanceFromCharacter(Target.Position)

            self:Travel(Target)

            if Distance < 5 then
                Module.SkillManager:FireSkill(HumanoidRootPart.Position, {
                    "X", "Z", "C"
                })
            end
        until not _ENV.OnFarm or (Break and Break()) or not Module:IsAlive(Enemy) or not self:IsAlive()
    end

    Connect(Player.CharacterAdded, function(v)
        Character = v
        Humanoid = v:WaitForChild("Humanoid", math.huge)
        Backpack = Player:FindFirstChildOfClass('Backpack')
        PrimaryPart = v:WaitForChild("HumanoidRootPart", math.huge)
    end)

    Connect(BodyVelocity:GetPropertyChangedSignal("Parent"), PlayerManager.__stop)

    return PlayerManager
end)()

Module.CooldownService = (function()
    local PlayerManager = Module.PlayerManager

    local CooldownService = {} do
        CooldownService.__ToolNames = {}
        CooldownService.__ToolTips = {}
        CooldownService.__Backlist = {
            ['Portal'] = { "C", "V" },
            ['Buddha'] = { "Z" }
        }
    end

    local Main = PlayerGui:WaitForChild('Main', math.huge)
    local Skill = Main:WaitForChild('Skills', math.huge)

    function CooldownService.__selects()
        return {
            ['Melee'] = Settings['Melee'] or { "Z", "X", "C" },
            ['Sword'] = Settings['Sword'] or { "Z", "X" },
            ['Gun'] = Settings['Gun'] or { "Z", "X" },
            ['Blox Fruit'] = Settings['Blox Fruit'] or { "Z", "X", "C" }
        }
    end

    function CooldownService.__update()
        CooldownService.__ToolNames = {}
        CooldownService.__ToolTips = {}

        for _, Tool in Backpack:GetChildren() do
            if Tool:IsA('Tool') and table.find(HIDDEN_SETTINGS.TOOLS, Tool.ToolTip) then
                CooldownService.__ToolNames[ Tool.Name ] = true
                CooldownService.__ToolTips[ Tool.Name ] = Tool.ToolTip
            end
        end

        for _, Tool in Character:GetChildren() do
            if Tool:IsA('Tool') and table.find(HIDDEN_SETTINGS.TOOLS, Tool.ToolTip) then
                CooldownService.__ToolNames[ Tool.Name ] = true
                CooldownService.__ToolTips[ Tool.Name ] = Tool.ToolTip
            end
        end
    end

    function CooldownService.__validtool()
        local ContainerIndex = 0

        for _, Container in Skill:GetChildren() do
            if CooldownService.__ToolNames[ Container.Name ] then
                ContainerIndex += 1
            end
        end

        return ContainerIndex == 4
    end

    function CooldownService.__switch()
        CooldownService.__update()

        if not CooldownService.__validtool()  then
            for ToolName in CooldownService.__ToolNames do
                PlayerManager:EquipTool(ToolName)
                task.wait(0.25)
            end 
        end
    end

    function CooldownService.__isblacklist(Container, Frame)
        for ToolName, Skills in CooldownService.__Backlist do
            if Container.Name:find(ToolName) then
                for _, Input in Skills do
                    if Input == Frame.Name then
                        return true
                    end
                end
            end
        end

        return false
    end

    function CooldownService.__isselected(Selects, Frame)
        for _, Input in Selects do
            if Input == Frame.Name then
                return true
            end
        end

        return false
    end

    function CooldownService.__validate(Frame, Selected)
        if not Frame:IsA('Frame') or Frame.Name == 'Template' then
            return false
        end

        local Cooldown = Frame:FindFirstChild('Cooldown')
        local Title = Frame:FindFirstChild('Title')
        local Container = Frame.Parent

        local SelectSkill = Selected or CooldownService.__selects()
        local ToolTip = CooldownService.__ToolTips[ Container.Name ]
        local IndexSelect = SelectSkill[ ToolTip ]

        if not CooldownService.__isselected(IndexSelect, Frame) then
            return false
        end 

        if not Title or not Cooldown then
            return false
        end

        if Title.Text:lower():find('transform') then
            return false
        end

        if CooldownService.__isblacklist(Container, Frame) then
            return false
        end

        return Cooldown.Size.X.Scale == 0 and Title.TextColor3 == Color3.fromRGB(255, 255, 255)
    end

    function CooldownService.__getskill(Selected)
        CooldownService.__update()

        for _, Container in Skill:GetChildren() do
            if not CooldownService.__ToolNames[ Container.Name ] then
                continue
            end

            for _, Frame in Container:GetChildren() do
                if not CooldownService.__validate(Frame, Selected) then
                    continue
                end

                return Frame.Name, Container.Name
            end
        end
    end

    function CooldownService.__equiper(Selected)
        CooldownService.__update()

        local Equipped = Character:FindFirstChildOfClass("Tool")
        if not Equipped then return end

        local Container = Skill:FindFirstChild(Equipped.Name)
        if not Container then return end

        for _, Frame in Container:GetChildren() do
            if not CooldownService.__validate(Frame, { [
                CooldownService.__ToolTips[Container.Name] ] = Selected}) then
                continue
            end

            return Frame.Name
        end
    end

    return CooldownService
end)()

Module.SkillManager = (function()
    local SkillManager = {} do
        SkillManager.__LastSkillUse = 0
    end

    local CooldownService = Module.CooldownService
    local PlayerManager = Module.PlayerManager

    function SkillManager.__aimat(Vector)
        _ENV.TARGET_POSITION = (typeof(Vector) == 'CFrame' and Vector.Position) or Vector
    end

    function SkillManager:FireAllSkill(Target, Selected)
        if not PlayerManager:IsAlive() then return end

        if tick() - SkillManager.__LastSkillUse < 0.2 then return end

        local Skill, Tool = CooldownService.__getskill(Selected)

        if not Skill then
            return CooldownService.__switch()
        end

        if not Character:FindFirstChild(Tool) then
            return PlayerManager:EquipTool(Tool)
        end

        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[Skill], false, game)
        task.wait(0.05); self.__aimat(Target)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[Skill], false, game)

        SkillManager.__LastSkillUse = tick()
    end

    function SkillManager:FireSkill(Target, Selected)
        if not PlayerManager:IsAlive() then return end

        if tick() - SkillManager.__LastSkillUse < 0.2 then return end

        local Skill = CooldownService.__equiper(Selected or { "Z", "X", "C", "V" })
        if not Skill then return end

        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[Skill], false, game)
        task.wait(0.05); self.__aimat(Target)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[Skill], false, game)

        SkillManager.__LastSkillUse = tick()
    end

    return SkillManager
end)()

Module.QuestModule = (function()
    local EnemiesModule = Module.EnemiesModule
    local DataModule = Module.DataModule
    local GameInfo = Module.GameInfo

    local QuestManager = {} do
        QuestManager.Blacklist = { "BartiloQuest", "MarineQuest", "CitizenQuest" }
        QuestManager.SeaRanges = { {0, 700}, {700, 1500}, {1500, math.huge} }
        QuestManager.GuideModule = require(ReplicatedStorage:WaitForChild('GuideModule'))
        QuestManager.Quests = require(ReplicatedStorage:WaitForChild('Quests'))

        QuestManager.StarterQuests = {
            Bandit = {
                Name = "Bandits",
                Monster = "Bandit",
                Level = 1,
                Quest = "BanditQuest1",
                Position = CFrame.new(1059, 15, 1550),
            },
            Trainee = {
                Name = "Trainees",
                Monster = "Trainee",
                Level = 1,
                Quest = "MarineQuest",
                Position = CFrame.new(-2711, 24, 2104),
            },
        }
    end

    function QuestManager:GetAllBossNames()
        local Range = self.SeaRanges[ GameInfo.Sea ]
        if not Range then return {} end

        local Names, Seen = {}, {}

        for QuestName, Missions in self.Quests do
            if table.find(self.Blacklist, QuestName) then continue end

            for _, Mission in Missions do
                if Mission.MeetsRequirements then continue end

                local Required = Mission.LevelReq
                if Required < Range[1] or Required >= Range[2] then continue end

                local Monster, Value = next(Mission.Task)

                if Monster and Value <= 1 and not Seen[ Monster ] then
                    Seen[ Monster ] = true
                    table.insert(Names, Monster)
                end
            end
        end

        return Names
    end

    function QuestManager:GetMonsterQuestByName(Name)
        if typeof(Name) ~= "string" then return end

        local Starter = self.StarterQuests[ Name ]
        if Starter then return Starter end

        local Character = Player.Character
        local Origin = Character and Character:GetPivot().Position or Vector3.zero

        local Best, BestDistance

        for QuestName, Missions in self.Quests do
            for Number, Mission in Missions do
                if Mission.MeetsRequirements then continue end
                if not Mission.Task[ Name ] then continue end

                for _, Npc in self.GuideModule.Data.NPCList do
                    if Npc.InternalQuestName ~= QuestName then continue end

                    local Distance = (Npc.Position - Origin).Magnitude

                    if not Best or Distance < BestDistance then
                        BestDistance = Distance

                        Best = {
                            Name = Mission.Name,
                            Monster = Name,
                            Level = Number,
                            Quest = QuestName,
                            Position = CFrame.new(Npc.Position),
                        }
                    end
                end
            end
        end

        return Best
    end

    function QuestManager:GetBossQuestByName(BossName)
        if typeof(BossName) ~= "string" then return end

        local Character = Player.Character
        local Origin = Character and Character:GetPivot().Position or Vector3.zero

        local Best, BestDistance

        for QuestName, Missions in self.Quests do
            for Number, Mission in Missions do
                if Mission.MeetsRequirements then continue end

                local Monster, Value = next(Mission.Task)
                if Monster ~= BossName or Value > 1 then continue end

                for _, Npc in self.GuideModule.Data.NPCList do
                    if Npc.InternalQuestName ~= QuestName then continue end

                    local Distance = (Npc.Position - Origin).Magnitude

                    if not Best or Distance < BestDistance then
                        BestDistance = Distance

                        Best = {
                            Name = Mission.Name,
                            Monster = BossName,
                            Level = Number,
                            Quest = QuestName,
                            Position = CFrame.new(Npc.Position),
                        }
                    end
                end
            end
        end

        return Best
    end

    function QuestManager:GetQuest()
        local Level = DataModule.__currently('__Level')

        if Level <= 9 then
            local Team = tostring(Player.Team)

            if Team == "Marines" then
                return self.StarterQuests.Trainee
            elseif Team == "Pirates" then
                return self.StarterQuests.Bandit
            end

            return
        end

        local Character = Player.Character
        local Origin = Character and Character:GetPivot().Position or Vector3.zero

        local Best, BestLevel, BestDistance

        for _, Npc in self.GuideModule.Data.NPCList do
            local QuestName = Npc.InternalQuestName
            if not QuestName or table.find(self.Blacklist, QuestName) then continue end

            local Missions = self.Quests[ QuestName ]
            if not Missions then continue end

            local Distance = (Npc.Position - Origin).Magnitude

            for Number, Mission in Missions do
                local Required = Mission.LevelReq
                local Monster, Value = next(Mission.Task)

                if not Monster or Value <= 1 then continue end
                if Mission.MeetsRequirements or Required > Level then continue end

                if not Best or Required > BestLevel or (Required == BestLevel and Distance < BestDistance) then
                    BestLevel = Required
                    BestDistance = Distance

                    Best = {
                        Name = Mission.Name,
                        Monster = Monster,
                        Level = Number,
                        Quest = QuestName,
                        Position = CFrame.new(Npc.Position),
                        Distance = Distance,
                    }
                end
            end
        end

        if not Best then return end

        local Missions = self.Quests[ Best.Quest ]
        local Boss, BossLevel

        for Number, Mission in Missions do
            local Required = Mission.LevelReq
            local Monster, Value = next(Mission.Task)

            if not Monster or Value > 1 then continue end
            if Mission.MeetsRequirements or Required > Level then continue end
            if BossLevel and Required <= BossLevel then continue end

            if EnemiesModule:GetClosest({ Monster }) then
                BossLevel = Required

                Boss = {
                    Name = Mission.Name,
                    Monster = Monster,
                    Level = Number,
                    Quest = Best.Quest,
                    Position = Best.Position,
                }
            end
        end

        if Boss then return Boss end
        Best.Distance = nil

        return Best
    end

    function QuestManager:GetQuestName()
        local Frame = PlayerGui:FindFirstChild("TrackedQuestFrame")
        if not Frame then return end

        local Container = Frame:FindFirstChild("Frame")
        if not Container then return end

        local Header = Container:FindFirstChild("header")
        if not Header then return end

        local Label = Header:FindFirstChild("textLabel")
        if not Label then return end

        return Label.Text
    end

    function QuestManager:IsOnQuest()
        return self:GetQuestName() ~= nil
    end

    function QuestManager:MatchQuest(Monsters)
        local QuestName = self:GetQuestName()
        if not QuestName then return false end

        return Module:MatchString(QuestName, Monsters)
    end

    return QuestManager
end)()

Module.DevilFruitModule = (function()
    local ItemsService = Module.ItemsService
    local DataModule = Module.DataModule

    local GachaNetworkRF = Net:WaitForChild("RF/GachaNetworkRF")

    local DevilFruitModule = {} do
        DevilFruitModule.__LastCheck = 0
        DevilFruitModule.__CachedTimeEnds = 0
    end

    function DevilFruitModule.__gettime()
        local CurrentTime = os.clock()

        if CurrentTime - DevilFruitModule.__LastCheck < 1 then
            return DevilFruitModule.__CachedTimeEnds
        end

        local Success, Result = pcall(function()
            return GachaNetworkRF:InvokeServer({
                Context = "Check",
                BoxName = "ZiolesGacha"
            })
        end)

        if Success and Result and Result.Cooldown then
            DevilFruitModule.__LastCheck = CurrentTime
            DevilFruitModule.__CachedTimeEnds = Result.Cooldown.TimeEnds
        end

        return DevilFruitModule.__CachedTimeEnds
    end

    function DevilFruitModule.__cangacha()
        local TimeEnds = DevilFruitModule.__gettime()
        local Remaining = TimeEnds - os.time()

        if Remaining > 0 then
            return false, Remaining
        end

        return true, 0
    end

    function DevilFruitModule:GetRemainTime()
        local CanGacha, Remaining = self.__cangacha()

        if CanGacha then
            return Utils:Color("Available", Color3.fromRGB(0, 255, 127))
        end

        return Utils:Color(string.format("%02d:%02d:%02d",
            math.floor(Remaining / 3600),
            math.floor(Remaining % 3600 / 60),
            Remaining % 60
            ), Color3.fromRGB(255, 170, 0))
    end

    function DevilFruitModule:RandomFruit()
        local CanGacha = self.__cangacha()
        if not CanGacha then return end

        local Check = GachaNetworkRF:InvokeServer({
            Context = "Check",
            BoxName = "ZiolesGacha"
        })

        local Price = Check and Check.Price
        if not Price or Price.Current < Price.Value then return end

        return GachaNetworkRF:InvokeServer({
            Context = "Purchase",
            BoxName = "ZiolesGacha"
        })
    end

    function DevilFruitModule:StoreFruit(Fruit)
        if not Fruit.Name:find("Fruit") then return end

        local FruitCap = DataModule.__currently('__FruitCap')
        local Name = Fruit:GetAttribute("OriginalName")

        if ItemsService:GetCount(Name) ~= FruitCap then
            return Module:ComF("StoreFruit", Name, Fruit)
        end
    end

    function DevilFruitModule.__isfruit(Container)
        if not Container then return false end

        for _, Object in Container:GetChildren() do
            if Object.Name:find("Fruit") then
                return true
            end
        end

        return false
    end

    function DevilFruitModule:HaveFruit()
        return (Character and self.__isfruit(Character)) or (Backpack and self.__isfruit(Backpack))
    end

    function DevilFruitModule.__getfruits(IsHigh)
        local Collects, Threshold = {}, 999999
        local Fruits = Module:ComF("GetFruits")

        for _, Fruit in pairs(Fruits) do
            local Price = Fruit.Price or 0
            local Name = Fruit.Name or "Unknown"

            if (Price >= Threshold) == IsHigh then
                Collects[Name] = Price
            end
        end

        return Collects
    end

    function DevilFruitModule.__getfruit(IsHigh)
        local Target, Lowest = nil, math.huge
        local Fruits = DevilFruitModule.__getfruits(IsHigh)

        for Name, Count in ItemsService.__Fruits do
            local Value = Fruits[Name]
            if Value and type(Value) == "number" and Value < Lowest then
                Lowest, Target = Value, Name
            end 
        end

        return Target
    end

    function DevilFruitModule:LoadFruit(IsHigh)
        if self:HaveFruit() then return end

        local Fruit = self.__getfruit(IsHigh)
        if not Fruit then return end

        return Module:ComF("LoadFruit", Fruit)
    end

    return DevilFruitModule
end)()

Module.StaticsModule = (function()
    local StaticsModule = {}

    local PlayerManager = Module.PlayerManager
    local EnemiesModule = Module.EnemiesModule
    local TweenManager = Module.TweenManager
    local GateModule = Module.GateModule

    local DangerDistance = require(ReplicatedStorage.DangerDistance)

    local HalfSize = _ENV.NVL_HALF_SIZE or WaterBasePlane.Size * 0.5 do
        _ENV.NVL_HALF_SIZE = HalfSize
    end

    local ColorMap = {
        ["Really red"] = "Pure Red",
        ["Hot pink"] = "Winter Sky",
        ["Oyster"] = "Snow White",
    }

    local ZoneCoordinates = {
        ['Infinite - ∞'] = { -9999999, 9999999 },
        ['Low - 1'] = { -21227, 4047 },
        ['Meduim - 2'] = { -24237, 6381 },
        ['High - 3'] = { -27105, 8959 },
        ['Extreme - 4'] = { -29350, 11744 },
        ['Crazy - 5'] = { -32404, 16208 },
        ['??? - 6'] = { -35611, 20548 },
    }

    function StaticsModule:GetZone(Selected)
        local Coords = ZoneCoordinates[ Selected ]
        if Coords then return CFrame.new(Coords[1], 100, Coords[2]) end

        return CFrame.new(-9999999, 100, 9999999)
    end

    function StaticsModule:RemoveBoatCollision(Boat)
        local Objects = Boat:GetDescendants()

        for i = 1, #Objects do
            local BasePart = Objects[i]

            if BasePart:IsA("BasePart") and BasePart.CanCollide then
                BasePart.CanCollide = false
            end
        end
    end

    function StaticsModule:IsOnWater(Position)
        local Offset = Position - WaterBasePlane.Position
        return math.abs(Offset.X) <= HalfSize.X and math.abs(Offset.Z) <= HalfSize.Z and Offset.Y <= 2
    end

    function StaticsModule:ValidPartColors(Part)
        local Inside = Part:FindFirstChild('Part')
        if not Inside then return end

        if Inside and Inside.BrickColor then
            return tostring(Inside.BrickColor) == "Lime green"
        end

        return false
    end

    function StaticsModule:CalculateColors(Part)
        if Part and Part.BrickColor then
            return ColorMap[ tostring(Part.BrickColor) ]
        end
    end

    function StaticsModule:IsOwnerShip(Model)
        local Owner = Model:FindFirstChild("Owner")

        if not Owner or not Owner:IsA("ObjectValue") then
            return false
        end

        if tostring(Owner.Value) ~= Player.Name then
            return false
        end

        return true
    end

    function StaticsModule:ShipTravel(PlayerShip, Target, YAxis, Velocity)
        Cached.LastShip = PlayerShip

        local VehicleSeat = PlayerShip:FindFirstChild("VehicleSeat")
        if not VehicleSeat then return end

        local BodyPosition = VehicleSeat:FindFirstChild("BodyPosition")
        local BodyVelocity = VehicleSeat:FindFirstChild("BodyVelocity")
        if not BodyPosition or not BodyVelocity then return end

        local Origin = VehicleSeat.Position
        local TargetPosition = Vector3.new(Target.Position.X, YAxis, Target.Position.Z)
        local Distance = (TargetPosition - PlayerShip:GetPivot().Position).Magnitude

        BodyVelocity.P = 0
        BodyPosition.MaxForce = Vector3.zero
        BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)

        local StartPosition = Vector3.new(Origin.X, YAxis, Origin.Z)
        local Direction = (TargetPosition - StartPosition).Unit
        local TargetCFrame = CFrame.lookAt(TargetPosition, TargetPosition + Direction)

        VehicleSeat.CFrame = CFrame.lookAt(StartPosition, StartPosition + Direction)
        if Distance > 10 then TweenManager.new(VehicleSeat, Distance / Velocity, "CFrame", TargetCFrame) end
    end

    function StaticsModule:CheckShipHealth(Ship, Threshold)
        if not Threshold then return false end

        local MaxHealth = Ship:GetAttribute("MaxHealth") or 0
        local Humanoid = Ship:FindFirstChild("Humanoid")

        return Humanoid and MaxHealth > 0 and (Humanoid.Value / MaxHealth) * 100 <= Threshold
    end

    function StaticsModule:GetDangerDistance(Target)
        if typeof(Target) == "Instance" then
            Target = Target:GetPivot().Position
        end

        return DangerDistance(Target)
    end

    StaticsModule.PlatesBartilo = function()
        local Dressrosa = Map:FindFirstChild('Dressrosa')
        if not Dressrosa then return end

        local BartiloPlates = Dressrosa:FindFirstChild("BartiloPlates")
        if not BartiloPlates then return end

        for i = 1, 8 do
            if BartiloPlates["Plate" .. i].BrickColor == BrickColor.new("Sand yellow") then
                return BartiloPlates["Plate" .. i]
            end
        end
    end

    StaticsModule.TreeEagles = setmetatable({
        __history = {},
        __cooldown = 5,
        __old = nil,
        __tick = 0,
    }, {
        __call = function(self, EagleBossArena)
            local Objects = EagleBossArena:GetChildren()
            local Trees = {}

            for i = 1, #Objects do
                local Object: Model = Objects[i]

                if Object.Name ~= "Tree" then continue end
                if not Object:IsA("Model") then continue end

                local PrimaryPart = Object.PrimaryPart
                if not PrimaryPart then continue end

                table.insert(Trees, Object)
            end

            if #Trees == 0 then
                self.__old = nil
                return nil
            end

            local HistoryCount = 0

            for _ in self.__history do
                HistoryCount += 1
            end

            if HistoryCount >= #Trees then
                self.__history = {}
                self.__old = nil
                self.__tick = 0
            end

            if self.__old then
                if os.clock() - self.__tick < self.__cooldown then
                    if self.__old.Parent then
                        return self.__old
                    end

                    self.__old = nil
                end
            end

            local Nearest, Distance = nil, math.huge

            for i = 1, #Trees do
                local Object = Trees[i]

                if self.__history[Object] then continue end

                local PrimaryPart = Object.PrimaryPart
                local Magnitude = Player:DistanceFromCharacter(PrimaryPart.Position)

                if Magnitude < Distance then
                    Nearest, Distance = Object, Magnitude
                end
            end

            if not Nearest then
                self.__history = {}
                self.__old = nil
                self.__tick = 0

                return self(EagleBossArena)
            end

            self.__history[ Nearest ] = true
            self.__old = Nearest
            self.__tick = os.clock()

            return Nearest
        end,
    })

    StaticsModule.Chest = function()
        local Chests = CollectionService:GetTagged("_ChestTagged")
        local Distance, Nearest = math.huge, nil

        for i = 1, #Chests do
            local Chest = Chests[i]
            local Magnitude = Player:DistanceFromCharacter(Chest:GetPivot().Position)
            if GateModule:IsPositionOnGate(Chest:GetPivot().Position) then continue end
            if not Chest:GetAttribute("IsDisabled") and Magnitude < Distance then
                Distance, Nearest = Magnitude, Chest
            end
        end

        return Nearest
    end

    StaticsModule.GetChestByIsland = function(Island)
        local Chests = CollectionService:GetTagged("_ChestTagged")
        local Distance, Nearest = math.huge, nil

        for i = 1, #Chests do
            local Chest = Chests[i]
            local Magnitude = Player:DistanceFromCharacter(Chest:GetPivot().Position)

            if not Chest:IsDescendantOf(Island) then continue end
            if not Chest:GetAttribute("IsDisabled") and Magnitude < Distance then
                Distance, Nearest = Magnitude, Chest
            end
        end

        return Nearest
    end

    StaticsModule.Berry = setmetatable({}, {
        __call = function(self, BerryArray)
            local CachedBush = self.Cached

            if CachedBush and CachedBush:IsDescendantOf(Map) then
                for _, BerryName in pairs(CachedBush:GetAttributes()) do
                    if not BerryArray or table.find(BerryArray, BerryName) then
                        return CachedBush
                    end
                end
            end

            local Character = Player.Character or Player.CharacterAdded:Wait()
            local Position = Character:GetPivot().Position
            local BerryBushes = CollectionService:GetTagged("BerryBush")

            local Distance, Nearest = math.huge, nil

            for i = 1, #BerryBushes do
                local Bush = BerryBushes[i]
                local Parent = Bush.Parent

                if not Parent or not Parent:IsA("Model") then
                    continue
                end

                for _, BerryName in pairs(Bush:GetAttributes()) do
                    if not BerryArray or table.find(BerryArray, BerryName) then
                        local Magnitude = (Parent:GetPivot().Position - Position).Magnitude

                        if Magnitude < Distance then
                            Nearest, Distance = Bush, Magnitude
                        end
                    end
                end
            end

            self.Cached = Nearest

            return Nearest
        end
    })

    StaticsModule.DevilFruit = function()
        local Objects = workspace:GetChildren()
        local Nearest, Distance = nil, math.huge

        for i = 1, #Objects do
            local Fruit = Objects[i]

            if not Fruit.Name:find("Fruit") then continue end

            local Handle = Fruit:FindFirstChild("Handle")
            if not Handle then continue end

            if StaticsModule:IsOnWater(Handle.Position) then continue end
            if GateModule:IsAtSubmergIsland(Handle.Position) then continue end

            local Magnitude = Player:DistanceFromCharacter(Handle.Position)

            if Magnitude < Distance then
                Nearest, Distance = Handle, Magnitude
            end
        end

        return Nearest, Distance
    end

    StaticsModule.PartColors = function(Circle)
        for _, Part in Circle:GetChildren() do
            if Part:IsA("Part") and not StaticsModule:ValidPartColors(Part) then
                return Part
            end
        end
    end

    StaticsModule.Raids = function()
        for i = 5, 1, -1 do
            local Name = "Island " .. i

            for _, Island in Locations:GetChildren() do
                if Island.Name ~= Name then continue end

                if Player:DistanceFromCharacter(Island.Position) < 3500 then
                    return Island
                end
            end
        end
    end

    StaticsModule.PlayerShip = setmetatable({
        Cached = nil,
    }, {
        __call = function(self, Name)
            local Cached = self.Cached

            if Cached and Cached.Name == Name and Cached.Parent == Boats and Module:IsAlive(Cached) then
                if Cached:GetAttribute("IsBoat") and StaticsModule:IsOwnerShip(Cached) then
                    return Cached
                end
            end

            local Nearest, Distance = nil, HIDDEN_SETTINGS.SEA_EVENT_RANGE
            local Ships = Boats:GetChildren()

            for i = 1, #Ships do
                local Ship = Ships[i]

                if Ship.Name ~= Name then continue end
                if not Ship:GetAttribute("IsBoat") then continue end
                if not Module:IsAlive(Ship) then continue end
                if not StaticsModule:IsOwnerShip(Ship) then continue end

                local Magnitude = Player:DistanceFromCharacter(Ship:GetPivot().Position)

                if Magnitude < Distance then
                    Nearest, Distance = Ship, Magnitude
                end
            end

            self.Cached = Nearest
            return Nearest
        end,
    })

    StaticsModule.SeaBeasts = setmetatable({
        Cached = nil,
    }, {
        __call = function(self)
            local Cached = self.Cached

            if Cached and Cached.Parent == SeaBeasts and Module:IsAlive(Cached) then
                return Cached
            end

            local Nearest, Distance = nil, HIDDEN_SETTINGS.SEA_EVENT_RANGE
            local Beasts = SeaBeasts:GetChildren()

            for i = 1, #Beasts do
                local SeaBeast = Beasts[i]

                if not SeaBeast:IsA("Model") then continue end
                if not Module:IsAlive(SeaBeast) then continue end

                local RootPart = SeaBeast:FindFirstChild("HumanoidRootPart")
                if not RootPart then continue end

                local Magnitude = Player:DistanceFromCharacter(RootPart.Position)

                if Magnitude < Distance then
                    Nearest, Distance = SeaBeast, Magnitude
                end
            end

            self.Cached = Nearest

            return Nearest
        end,
    })

    StaticsModule.Ships = setmetatable({
        Cached = nil,
    }, {
        __call = function(self, Names)
            if self.Cached and Module:IsAlive(self.Cached) then
                return self.Cached
            end

            local Nearest, Distance = nil, HIDDEN_SETTINGS.SEA_EVENT_RANGE
            local Ships = Enemies:GetChildren()

            for i = 1, #Ships do
                local Ship = Ships[i]

                if not table.find(Names, Ship.Name) then continue end
                if not Module:IsAlive(Ship) then continue end
                if not Ship:FindFirstChild("Seat", true) then continue end

                local Magnitude = Player:DistanceFromCharacter(Ship:GetPivot().Position)

                if Magnitude < Distance then
                    Nearest, Distance = Ship, Magnitude
                end
            end

            self.Cached = Nearest

            return Nearest
        end,
    })

    StaticsModule.LavaRocks = setmetatable({}, {
        __call = function(self, VolcanoRocks)
            local Cached = self.LavaRock

            if Cached and Cached.Parent == VolcanoRocks then
                local LavaEffect = Cached:FindFirstChild("At1Beam", true)

                if LavaEffect and LavaEffect.Enabled then
                    return Cached
                end
            end

            if self.Debounce and (tick() - self.Debounce) < 0.25 then
                return nil
            end

            local Distance, Nearest = math.huge, nil
            local Rocks = VolcanoRocks:GetChildren()

            for i = 1, #Rocks do
                local Rock = Rocks[i]
                if not Rock:IsA("Model") then continue end

                local LavaEffect = Rock:FindFirstChild("At1Beam", true)
                if not LavaEffect or not LavaEffect.Enabled then continue end

                local Magnitude = Player:DistanceFromCharacter(Rock:GetPivot().Position)

                if Magnitude < Distance then
                    Nearest, Distance = Rock, Magnitude
                end
            end

            self.Debounce = tick()
            self.LavaRock = Nearest

            return Nearest
        end,
    })

    StaticsModule.Player = function(Condition)
        local PlayerList = Players:GetPlayers()
        local Nearest, Distance = nil, math.huge

        for i = 1, #PlayerList do
            local TargetPlayer = PlayerList[i]
            if Players.LocalPlayer == TargetPlayer then continue end

            if TargetPlayer:GetAttribute("PvpDisabled") then continue end
            if TargetPlayer:GetAttribute("IslandRaiding") then continue end

            local _Character = TargetPlayer.Character
            if not _Character or not Module:IsAlive(_Character) then continue end
            if Condition and not Condition(TargetPlayer) then continue end

            local InSafeZone = TargetPlayer:GetAttribute("InSafeZone")
            local InCombat = TargetPlayer:GetAttribute("InCombat")
            if InSafeZone and not InCombat then continue end

            local _PrimaryPart = _Character.PrimaryPart
            if not _PrimaryPart then continue end

            local Magnitude = Player:DistanceFromCharacter(_PrimaryPart.Position)
            if Magnitude < Distance then
                Nearest, Distance = TargetPlayer, Magnitude
            end
        end

        return Nearest
    end

    StaticsModule.FireFlower = function()
        local FireFlowers = workspace:FindFirstChild("FireFlowers")
        if not FireFlowers then return end

        for _, Flower in FireFlowers:GetChildren() do
            if Flower:IsA('Model') and Flower.PrimaryPart then
                return Flower
            end
        end
    end

    return StaticsModule
end)()

Module.LeviathanService = (function()
    local LeviathanService = {}

    local PlayerManager = Module.PlayerManager
    local SkillManager = Module.SkillManager

    function LeviathanService.__Breakable(Enemy, Break)
        return PlayerManager:IsAlive() or not Module:IsAlive(Enemy) or not _ENV.OnFarm or not (Break and Break())
    end

    function LeviathanService:GetClosestSegment()
        local Nearest, Distance = nil, math.huge

        for _, Segment in SeaBeasts:GetChildren() do
            if Segment.Name ~= "Leviathan Segment" then continue end
            if not Module:IsAlive(Segment) then continue end

            local RootPart = Segment:FindFirstChild("HumanoidRootPart")
            if not RootPart then continue end

            local Magnitude = Player:DistanceFromCharacter(RootPart.Position)
            if Magnitude < Distance then
                Nearest, Distance = RootPart, Magnitude
            end
        end

        return Nearest
    end

    function LeviathanService:GetLeviathanHead()
        for _, Leviathan in SeaBeasts:GetChildren() do
            if Leviathan.Name == "Leviathan" and Module:IsAlive(Leviathan) then
                return Leviathan:FindFirstChild("Head")
            end
        end
    end

    function LeviathanService:Kill(RootPart, Break)
        if not RootPart.Parent or not PlayerManager:IsAlive() or not Module:IsAlive(RootPart.Parent) then
            return
        end

        local Offset; repeat Heartbeat:Wait()
            PlayerManager:EnabledBuso()

            if not RootPart.Parent.Name:find('Segment') then
                Offset = CFrame.new(RootPart.Position.X, 60, RootPart.Position.Z)
            else
                Offset = RootPart.CFrame * CFrame.new(0, 21, 0)
            end

            local Distance = Player:DistanceFromCharacter(Offset.Position)

            if Settings.Overheater then
                self.__UseDragonstorm(Offset, Offset)
            else PlayerManager:Travel(Offset)
                if Distance <= 20 then
                    SkillManager:FireAllSkill(Offset)
                end
            end
        until not RootPart.Parent or self.__Breakable(RootPart.Parent, Break)
    end

    return LeviathanService
end)()

Module.SeaEventService = (function()
    local SeaEventService = {} do
        SeaEventService.__ShootDistance = 100
    end

    HIDDEN_SETTINGS.TERROR_SHARK_OFFSET = Vector3.new(0, 220, 0)
    HIDDEN_SETTINGS.GHOST_SHIP_OFFSET = Vector3.new(0, 0, 40)
    HIDDEN_SETTINGS.SEA_BEAST_OFFSET = CFrame.new(0, 450, 50)

    local StaticsModule = Module.StaticsModule
    local EnemiesModule = Module.EnemiesModule
    local PlayerManager = Module.PlayerManager
    local ItemsService = Module.ItemsService
    local SkillManager = Module.SkillManager

    SeaEventService.__Skilltable = function()
        return {
            ['Melee'] = Settings['Ocean Melee'],
            ['Sword'] = Settings['Ocean Sword'],
            ['Gun'] = Settings['Ocean Gun'],
            ['Blox Fruit'] = Settings['Ocean Fruit']
        }
    end

    SeaEventService.__Breakable = function(Enemy, Break)
        if not PlayerManager:IsAlive() or not Module:IsAlive(Enemy) then
            return true
        end

        if (Break and Break()) or not _ENV.OnFarm then
            return true
        end

        return false
    end

    SeaEventService.__EquipDragonstorm = function()
        if ItemsService:HaveItem("Dragonstorm") then
            return Module:ComF("LoadItem", "Dragonstorm")
        end
    end

    SeaEventService.__UseDragonstorm = function(SkillAt, Target)
        if not ItemsService:InCharacter("Dragonstorm") then
            return SeaEventService.__EquipDragonstorm()
        end

        PlayerManager:EquipTool("Gun", true)
        PlayerManager:Travel(Target)

        if Player:DistanceFromCharacter(Target.Position) <= 10 then
            SkillManager:FireSkill(SkillAt, { "X", "Z" })
        end
    end

    SeaEventService.__TerrorSharkDodge = function()
        for _, Skill in WorldOrigin:GetChildren() do
            local NameLower = Skill.Name:lower()
            if NameLower:find("sharkslam") or NameLower:find("spin") or NameLower:find("chargemodel") then
                return true
            end
        end
    end

    SeaEventService.__Enemies = function(Name)
        return EnemiesModule:GetEnemies(HIDDEN_SETTINGS.SEA_EVENT_RANGE, Name)
    end

    SeaEventService.__SeaBeast = function()
        return StaticsModule.SeaBeasts()
    end

    SeaEventService.__PirateShip = function()
        return StaticsModule.Ships({ "PirateGrandBrigade", "PirateBrigade" })
    end

    SeaEventService.__GhoshShip = function()
        return StaticsModule.Ships({ "FishBoat", "GhostShip" })
    end

    function SeaEventService:KillTerrorShark(Enemy, Break)
        if not PlayerManager:IsAlive() or not Module:IsAlive(Enemy) then
            return
        end

        repeat Heartbeat:Wait()
            PlayerManager:EnabledBuso()

            local Pivot = Enemy:GetPivot()
            local YAxis = PlayerManager:GetYAxis()
            local Health = PlayerManager:GetHealth()

            local Offset = Pivot + Vector3.new(0, YAxis, 0)
            local Escape = Pivot + HIDDEN_SETTINGS.TERROR_SHARK_OFFSET
            local TargetYAxis = CFrame.new(Pivot.Position.X, Escape.Position.Y, Pivot.Position.X)

            if Settings.Overheater then
                self.__UseDragonstorm(Pivot, Escape)
            else
                if SeaEventService.__TerrorSharkDodge() then
                    Character:PivotTo(TargetYAxis)
                    PlayerManager:Travel(Escape)
                    continue
                end

                if Health <= 35 then
                    Character:PivotTo(TargetYAxis)
                    PlayerManager:Travel(Escape)
                    continue
                end

                if Health <= 50 then continue end
                PlayerManager:EquipTool(Settings['Select Weapon'], true)
                PlayerManager:Travel(Offset)
            end
        until self.__Breakable(Enemy, Break)
    end

    function SeaEventService:KillShip(Enemy, Break)
        if not PlayerManager:IsAlive() or not Module:IsAlive(Enemy) then
            return
        end

        repeat Heartbeat:Wait()
            PlayerManager:EnabledBuso()

            local Engine = Enemy:FindFirstChild('Engine', true)
            local VehicleSeat = Enemy:FindFirstChild('VehicleSeat', true)
            if not Engine or not VehicleSeat then continue end

            local SkillAt = VehicleSeat.CFrame
            local Offset = Engine.CFrame + HIDDEN_SETTINGS.GHOST_SHIP_OFFSET
            local Distance = Player:DistanceFromCharacter(Offset.Position)

            if Settings.Overheater then
                self.__UseDragonstorm(SkillAt, Offset)
            elseif Distance < 20 then
                SkillManager:FireAllSkill(SkillAt, self.__Skilltable())
            end

            PlayerManager:Travel(Offset)
        until self.__Breakable(Enemy, Break)
    end

    function SeaEventService:KillSeaBeast(Enemy, Break)
        if not PlayerManager:IsAlive() or not Module:IsAlive(Enemy) then
            return
        end

        repeat Heartbeat:Wait()
            PlayerManager:EnabledBuso()

            local RootPart = Enemy:FindFirstChild("HumanoidRootPart")

            if not RootPart then continue end
            if RootPart.Position.Y ~= -179 then continue end

            local Offset = RootPart.CFrame * HIDDEN_SETTINGS.SEA_BEAST_OFFSET
            local Distance = Player:DistanceFromCharacter(Offset.Position)
            local SkillAt = RootPart.CFrame * CFrame.new(0, 220, 0)

            if Settings.Overheater then
                self.__UseDragonstorm(SkillAt, SkillAt)
            else
                if Distance > 60 then
                    PlayerManager:Travel(Offset)
                elseif Distance > 3 then
                    Character:PivotTo(Offset)
                end

                if Distance <= 20 then
                    SkillManager:FireAllSkill(SkillAt, self.__Skilltable())
                end 
            end
        until self.__Breakable(Enemy, Break)
    end

    SeaEventService.__Dictionary = {
        {
            Name = "Piranha",
            Enemy = function() return SeaEventService.__Enemies("Piranha") end,
        },
        {
            Name = "Terrorshark",
            Enemy = function() return SeaEventService.__Enemies("Terrorshark") end,
            Attack = function(...) return SeaEventService:KillTerrorShark(...) end
        },
        {
            Name = "Shark",
            Enemy = function() return SeaEventService.__Enemies("Shark") end,
        },
        {
            Name = "Fish Crew Member",
            Enemy = function() return SeaEventService.__Enemies("Fish Crew Member") end,
        },
        {
            Name = "Pirate Ship",
            Enemy = function() return SeaEventService.__PirateShip() end,
            Attack = function(...) return SeaEventService:KillShip(...) end
        },
        {
            Name = "Ghost Ship",
            Enemy = function() return SeaEventService.__GhoshShip() end,
            Attack = function(...) return SeaEventService:KillShip(...) end
        },
        {
            Name = "Sea Beast",
            Enemy = function() return SeaEventService.__SeaBeast() end,
            Attack = function(...) return SeaEventService:KillSeaBeast(...) end
        },
    }

    for _, Entry in SeaEventService.__Dictionary do
        if not Entry.Attack then
            Entry.Attack = function(Enemy, Break)
                return PlayerManager:Kills(Enemy, Break)
            end
        end
    end

    function SeaEventService:GetClosest()
        return self.__Dictionary
    end

    return SeaEventService
end)()

Module.HunterService = (function()
    local PlayerManager = Module.PlayerManager

    local HunterService = {} do
        HunterService.__Hits = {}
        HunterService.__SpeedConnect = nil
        HunterService.__JumpConnect = nil
        HunterService.__CachedTarget = nil
        HunterService.__CachedTick = nil
        HunterService.__RealMouse = Player:GetMouse()
        HunterService.__SoruFunction = nil
    end

    HunterService.__MouseProxy = setmetatable({}, {
        __index = function(_, Key)
            local RealMouse = HunterService.__RealMouse

            if Key == "Hit" then
                if Settings['Soru Target'] then
                    local Success, Target = pcall(HunterService.GetClosest, HunterService)
                    local TargetPart = Success and Target and Target.PrimaryPart

                    if TargetPart then
                        return TargetPart.CFrame
                    end
                end

                return RealMouse.Hit
            end

            local Value = RealMouse[ Key ]

            if typeof(Value) == "function" then
                return function(_, ...) return Value(RealMouse, ...) end
            end

            return Value
        end
    })

    local NVL_LINE = _ENV.NVL_LINE or Drawing.new("Line") do
        NVL_LINE.Color = Color3.fromRGB(255, 0, 127)
        NVL_LINE.Thickness = 2
        NVL_LINE.Transparency = 1
        NVL_LINE.Visible = false

        _ENV.NVL_LINE = NVL_LINE
    end

    local NVL_BOX = _ENV.NVL_BOX or Drawing.new("Square") do
        NVL_BOX.Color = Color3.fromRGB(255, 0, 127)
        NVL_BOX.Thickness = 2
        NVL_BOX.Transparency = 0.5
        NVL_BOX.Filled = true
        NVL_BOX.Visible = false

        _ENV.NVL_BOX = NVL_BOX
    end

    function HunterService:EnableSpeed()
        if self.__SpeedConnect then return end

        self.__SpeedConnect = Connect(Heartbeat, function(Delta)
            local MoveDirection = Humanoid.MoveDirection
            local Speed = Settings['Player Velocity'] or 1

            if MoveDirection.Magnitude > 0 then
                Character:TranslateBy(MoveDirection * Speed * Delta * 10)
            end
        end)
    end

    function HunterService:DisableSpeed()
        if self.__SpeedConnect then
            self.__SpeedConnect:Disconnect()
            self.__SpeedConnect = nil
        end
    end

    function HunterService:SetSpeed(Value)
        if Value then self:EnableSpeed() else self:DisableSpeed() end
    end

    function HunterService:EnableJump()
        if self.__JumpConnect then return end

        self.__JumpConnect = Connect(Heartbeat, function()
            if not Humanoid or not Humanoid.Parent then return end

            local Power = Settings['Jump Power'] or 50

            if Humanoid.UseJumpPower ~= true then
                Humanoid.UseJumpPower = true
            end

            if Humanoid.JumpPower ~= Power then
                Humanoid.JumpPower = Power
            end
        end)
    end

    function HunterService:DisableJump()
        if self.__JumpConnect then
            self.__JumpConnect:Disconnect()
            self.__JumpConnect = nil
        end

        if Humanoid and Humanoid.Parent then
            Humanoid.UseJumpPower = true
            Humanoid.JumpPower = 50
        end
    end

    function HunterService:SetJump(Value)
        if Value then self:EnableJump() else self:DisableJump() end
    end

    function HunterService:GetSoruFunction()
        local Model = Player.Character
        if not Model then return end

        local List = filtergc("function", {
            Constants = { "SoruCharges", "LastUse", "mobileSoru" }
        }, false)

        for i = 1, #List do
            local Function = List[i]
            local Success, Env = pcall(getfenv, Function)
            local Script = Success and Env and Env.script

            if typeof(Script) == "Instance" and Script:IsDescendantOf(Model) then
                return Function
            end

            local Source = debug.info(Function, "s")
            if Source and Source == Model:GetFullName() .. ".Soru" then
                return Function
            end
        end
    end

    function HunterService:ApplySoru()
        local Function = self:GetSoruFunction()
        if not Function then return false end

        for Index, Value in debug.getupvalues(Function) do
            if Value == self.__RealMouse or Value == self.__MouseProxy then
                if Value == self.__RealMouse then
                    debug.setupvalue(Function, Index, self.__MouseProxy)
                end

                self.__SoruFunction = Function
                return true
            end
        end

        return false
    end

    function HunterService:IsSoruValid()
        local Function = self.__SoruFunction
        local Model = Player.Character

        if not Function or not Model then return false end

        local Success, Env = pcall(getfenv, Function)
        local Script = Success and Env and Env.script

        return typeof(Script) == "Instance" and Script.Parent ~= nil and Script:IsDescendantOf(Model)
    end

    function HunterService:IsAlly(TargetPlayer)
        local LocalName = Player.Name
        local TargetName = TargetPlayer.Name

        if tostring(TargetPlayer.Team) == "Marines" and TargetPlayer.Team == Player.Team then
            return true
        end

        if Player:HasTag("Ally" .. TargetName) then
            return true
        end

        if TargetPlayer:HasTag("Ally" .. LocalName) then
            return true
        end

        return false
    end

    function HunterService:ProcessPlayers()
        local PlayerList = Players:GetPlayers()

        for i = 1, #PlayerList do
            local TargetPlayer = PlayerList[i]
            if Players.LocalPlayer == TargetPlayer then continue end

            if TargetPlayer:GetAttribute("PvpDisabled") then continue end
            if TargetPlayer:GetAttribute("IslandRaiding") then continue end

            if self:IsAlly(TargetPlayer) then continue end

            local _Character = TargetPlayer.Character
            if not _Character or not Module:IsAlive(_Character) then continue end

            local InSafeZone = TargetPlayer:GetAttribute("InSafeZone")
            local InCombat = TargetPlayer:GetAttribute("InCombat")
            if InSafeZone and not InCombat then continue end

            local _PrimaryPart = _Character.PrimaryPart
            if not _PrimaryPart then continue end

            local Magnitude = Player:DistanceFromCharacter(_PrimaryPart.Position)
            if Magnitude < (Settings['Detect Range'] or 750) then
                table.insert(self.__Hits, _Character)
            end
        end
    end

    function HunterService:ProcessMonsters()
        local EnemyList = Enemies:GetChildren()

        for i = 1, #EnemyList do
            local Enemy = EnemyList[i]

            if not Module:IsAlive(Enemy) then continue end
            if Enemy:GetAttribute('IsBoat') then continue end

            local _PrimaryPart = Enemy.PrimaryPart
            if not _PrimaryPart then continue end

            local Magnitude = Player:DistanceFromCharacter(_PrimaryPart.Position)
            if Magnitude < (Settings['Detect Range'] or 750) then
                table.insert(self.__Hits, Enemy)
            end
        end
    end

    function HunterService:UpdateProcess()
        self.__Hits = {}

        local Filter = Settings['Targets Filter'] or {}
        if table.find(Filter, "Players") then self:ProcessPlayers() end
        if table.find(Filter, "Monsters") then self:ProcessMonsters() end
    end

    function HunterService:GetClosest()
        if self.__CachedTarget and self.__CachedTick and (tick() - self.__CachedTick) < 0.15 then
            if Module:IsAlive(self.__CachedTarget) then
                return self.__CachedTarget
            end

            self.__CachedTarget = nil
            self.__CachedTick = nil
        end

        self:UpdateProcess()

        local Is360 = Settings['Detect Angle'] == "360°"
        local Nearest, Distance = nil, (Settings['Detect Range'] or 750)

        for i = 1, #self.__Hits do
            local Target = self.__Hits[i]
            local PrimaryPart = Target.PrimaryPart
            if not PrimaryPart then continue end

            local Magnitude = Player:DistanceFromCharacter(PrimaryPart.Position)

            if not Is360 then
                local _, IsOnScreen = Camera:WorldToViewportPoint(PrimaryPart.Position)
                if not IsOnScreen then continue end
            end

            if Magnitude < Distance then
                Distance = Magnitude
                Nearest = Target
            end
        end

        if Nearest then
            self.__CachedTarget = Nearest
            self.__CachedTick = tick()
        end

        return Nearest
    end

    _ENV.NVL_GET_CLOSEST = function()
        if not Settings['Silent Skill'] then return end
        return HunterService:GetClosest()
    end

    Connect(Render, function()
        local Closest = HunterService.__CachedTarget

        if not Closest or not Closest.Parent or not Closest.PrimaryPart or not PrimaryPart and not Module:IsAlive(Cached) then
            NVL_LINE.Visible = false
            NVL_BOX.Visible = false
            return
        end

        local TargetPart = Closest.PrimaryPart

        if Settings['Line Target'] then
            local FromScreen, FromVisible = Camera:WorldToViewportPoint(PrimaryPart.Position)
            local ToScreen, ToVisible = Camera:WorldToViewportPoint(TargetPart.Position)

            if FromVisible and ToVisible then
                NVL_LINE.From = Vector2.new(FromScreen.X, FromScreen.Y)
                NVL_LINE.To = Vector2.new(ToScreen.X, ToScreen.Y)
                NVL_LINE.Visible = true
            else
                NVL_LINE.Visible = false
            end
        else
            NVL_LINE.Visible = false
        end

        if Settings['Box Target'] then
            local TopScreen, TopVisible = Camera:WorldToViewportPoint(TargetPart.Position + Vector3.new(0, 3, 0))
            local BotScreen, BotVisible = Camera:WorldToViewportPoint(TargetPart.Position - Vector3.new(0, 3, 0))

            if TopVisible and BotVisible then
                local Height = math.abs(TopScreen.Y - BotScreen.Y)
                local Width = Height * 0.5

                NVL_BOX.Size = Vector2.new(Width, Height)
                NVL_BOX.Position = Vector2.new(TopScreen.X - Width / 2, TopScreen.Y)
                NVL_BOX.Visible = true
            else
                NVL_BOX.Visible = false
            end
        else
            NVL_BOX.Visible = false
        end
    end)

    Connect(Player.CharacterAdded, function()
        HunterService.__SoruFunction = nil
    end)

    return HunterService
end)()

Module.NpcService = (function()
    local NpcService = {
        __Cached = {},
        __Blocks = Module:Dictionary({
            "Advanced Fruit Dealer"
        }, true)
    }

    local PlayerManager = Module.PlayerManager

    local function NewNpcAdded(Npc: Instance)
        if NpcService.__Blocks[ Npc.Name ] then return end
        if Npc:GetAttribute("NPCLoaded") ~= nil then
            NpcService.__Cached[ Npc.Name ] = Npc:GetPivot()
        end
    end

    function NpcService:GetNilNpcs(Name)
        if self.__Cached[ Name ] then
            return self.__Cached[ Name ]
        end

        local Success, Instances = pcall(getnilinstances)
        if not Success then return end

        for _, Npc in Instances do
            if Npc.Name ~= Name then continue end

            local Pivot = Npc:GetPivot()
            self.__Cached[ Name ] = Pivot

            return Pivot
        end
    end

    function NpcService:GetNpcPivotByName(Name)
        local Npc = NPCs:FindFirstChild(Name)
        if Npc then return Npc:GetPivot() end

        local __Npc = ReplicatedStorage.NPCs:FindFirstChild(Name)
        if __Npc then return __Npc:GetPivot() end

        if self.__Blocks[ Name ] then
            return self:GetNilNpcs(Name)
        end

        local Cached = self.__Cached[ Name ]
        if Cached then return Cached end

        return self:GetNilNpcs(Name)
    end

    function NpcService:TravelTo(Name)
        local Pivot = self:GetNpcPivotByName(Name)
        if not Pivot then return end

        PlayerManager:Travel(Pivot)
        return true
    end

    task.spawn(function()
        for _, Npc in NPCs:GetChildren() do task.spawn(NewNpcAdded, Npc) end
        for _, Npc in ReplicatedStorage.NPCs:GetChildren() do task.spawn(NewNpcAdded, Npc) end
    end)

    return NpcService
end)()

Module.ServerManager = (function()
    local Alphabet = Module:Import('Modules/Alphabet')()
    local AlphabetSecret = HIDDEN_SETTINGS.APL_SECRET

    local Request = clonefunction(request)
    local __ServerBrowser = ReplicatedStorage:WaitForChild('__ServerBrowser')

    local ServerManager = {} do
        ServerManager.Url = "http://163.223.9.144/boss/%s"
        ServerManager.LastTokens = {}
        ServerManager.LastJoin = 0
        ServerManager.JoinCooldown = 1

        ServerManager.NAME_TAGES = {
            Island = {
                "Prehistoric Island", "Kitsune Shrine", "Mirage Island",
            },
            Boss = {
                "Tyrant of the Skies", "Cursed Captain", "Soul Reaper",
                "Cake Prince", "Dough King", "Darkbeard", "Rip Indra", "Elite",
            },
            Items = {
                "Legendary Sword", "Devil Fruits", "Berries",
            },
            Events = {
                "Legendary Haki", "Closest Fullmoon", "Pirate Raid", "The Fullmoon",
            },
        }

        ServerManager.Tags = {
            ['Prehistoric Island'] = "PrehistoricIsland",
            ['Tyrant of the Skies'] = "TyrantOfTheSkies",
            ['Legendary Sword'] = "SwordLegendary",
            ['Legendary Haki'] = "HakiLegendary",
            ['Kitsune Shrine'] = "KitsuneIsland",
            ['Cursed Captain'] = "CursedCaptain",
            ['Closest Fullmoon'] = "NearMoon",
            ['Soul Reaper'] = "SoulReaper",
            ['Cake Prince'] = "CakePrince",
            ['Pirate Raid'] = "CastleRaid",
            ['The Fullmoon'] = "Fullmoon",
            ['Mirage Island'] = "Mirage",
            ['Dough King'] = "DoughKing",
            ['Devil Fruits'] = "Fruits",
            ['Darkbeard'] = "Darkbeard",
            ['Rip Indra'] = "RipIndra",
            ['Berries'] = "Berry",
            ['Elite'] = "Elite",
        }
    end

    local function Notify(Title, Text)
        return StarterGui:SetCore("SendNotification", {
            Title = Title,
            Text = Text,
            Duration = 3
        })
    end

    function ServerManager:GetTagged(Tag)
        local Tagged = self.Tags[Tag]
        if not Tagged then
            return nil
        end

        return self.Url:format(Tagged)
    end

    function ServerManager:GetServer(Name)
        local Tag = self:GetTagged(Name)
        if not Tag then
            return nil
        end

        local Success, Result = pcall(Request, {
            Url = Tag,
            Method = "GET",
            Headers = {
                ["Content-Type"] = "application/json"
            }
        })

        if not Success or not Result then
            return nil
        end

        local Body = type(Result) == "table" and Result.Body or Result
        if type(Body) ~= "string" then
            return nil
        end

        local DecodeSuccess, Decode = pcall(function()
            return HttpService:JSONDecode(Body)
        end)

        if not DecodeSuccess or type(Decode) ~= "table" then
            return nil
        end

        local Servers = Decode.data
        if type(Servers) ~= "table" then
            return nil
        end

        local TargetName = self.Tags[Name]
        local LastToken = self.LastTokens[Name]
        local BestToken, MinPlayers = nil, math.huge

        for _, Data in ipairs(Servers) do
            if type(Data) ~= "table" then continue end
            if Data.Name ~= TargetName then continue end
            if type(Data.Players) ~= "number" then continue end
            if type(Data.JobId) ~= "string" then continue end
            if Data.JobId == LastToken then continue end
            if Data.Players >= MinPlayers then continue end
            if Data.Sea ~= workspace:GetAttribute('MAP') then continue end
            if game.JobId == Alphabet.Reverse(Data.JobId, AlphabetSecret) then continue end

            BestToken, MinPlayers = Data.JobId, Data.Players
        end

        return BestToken
    end

    function ServerManager:ToServer(Target)
        local CurrentTime = os.clock()

        if CurrentTime - self.LastJoin < self.JoinCooldown then
            return Notify("Server Manager", "In Cooldown")
        end

        local Token = self:GetServer(Target)

        if not Token then
            return Notify("Server Manager", "Server Not Found")
        end

        local DecodedToken = Alphabet.Reverse(Token, AlphabetSecret)
        if not DecodedToken then
            return Notify("Server Manager", "Alphabet Failed")
        end

        self.LastJoin = CurrentTime
        self.LastTokens[Target] = Token

        Notify("Server Manager", "Joining Server ...")

        return __ServerBrowser:InvokeServer("teleport", DecodedToken)
    end

    return ServerManager
end)()

Module.VisualManager = (function()
    local EspManager = Module:Import('Modules/EspManager')()
    local DataModule = Module.DataModule

    local DevilFruitsName = DataModule.__get('FruitIds')

    local GearColor = BrickColor.new("Pastel Blue")
    local DimColor = "rgb(160, 160, 160)"

    local function ToSet(List)
        local Set = {}

        for _, Value in List do
            Set[Value] = true
        end

        return Set
    end

    local VisualManager = {
        EspHandlers = {},
        EspInstaller = {},

        Flowers = {
            Flower1 = "Blue Flower",
            Flower2 = "Red Flower",
        },

        Islands = {
            PrehistoricIsland = "Prehistoric Island",
            KitsuneIsland = "Kitsune Island",
            MysticIsland = "Mirage Island",
            FrozenDimension = "Frozen Dimension",
        },

        Berries = {
            "Pink Pig Berry",
            "Purple Jelly Berry",
            "Red Cherry Berry",
            "Blue Icicle Berry",
            "Green Toad Berry",
            "Orange Berry",
            "White Cloud Berry",
            "Yellow Star Berry",
        },

        RealFruits = {
            "AppleSpawner",
            "PineappleSpawner",
            "BananaSpawner",
        },
    }

    local BerrySet = ToSet(VisualManager.Berries)

    local ConfigOf = setmetatable({}, { __mode = "k" })
    local BerryNames = setmetatable({}, { __mode = "k" })

    local function Resolve(Value)
        if type(Value) == "function" then
            return Value()
        end

        return Value
    end

    local function ChildrenOf(Root)
        local Instance = Resolve(Root)

        if not Instance then
            return {}
        end

        return Instance:GetChildren()
    end

    local function Filter(List, Predicate)
        local Result = {}

        for _, Item in List do
            if Predicate(Item) then
                Result[#Result + 1] = Item
            end
        end

        return Result
    end

    local function BerryConfig(Bush)
        if Bush:IsA("Configuration") then
            return Bush
        end

        return Bush:FindFirstChild("Berries") or Bush
    end

    local function ReadBerryName(Config)
        for _, Value in Config:GetAttributes() do
            if type(Value) == "string" and BerrySet[Value] then
                return Value
            end
        end

        return nil
    end

    function VisualManager:Text(Text, Distance)
        if not Settings["Distance Indicator"] or not Distance then
            return Text
        end

        return string.format(
            "%s<font color='%s'> [ %dm ]</font>",
            Text,
            DimColor,
            math.floor(Distance)
        )
    end

    function VisualManager:ToBerry(Model)
        local Config = ConfigOf[Model]

        if Config and Config.Parent then
            BerryNames[Model] = ReadBerryName(Config) or BerryNames[Model]
        end

        return BerryNames[Model] or "Unknown Berry"
    end

    function VisualManager:ToBloxFruit(Fruit)
        if not Fruit:IsA("Model") then
            return Fruit.Name
        end

        local Idle = Fruit:FindFirstChild("Idle", true)
        local FruitName = Idle and DevilFruitsName[tostring(Idle.AnimationId)]

        if not FruitName then
            return Fruit.Name
        end

        return FruitName .. " [ Spawned ]"
    end

    function VisualManager.NewChests()
        return Filter(CollectionService:GetTagged("_ChestTagged"), function(Chest) return not Chest:GetAttribute("IsDisabled") end)
    end

    function VisualManager.NewBerries()
        local Collects = {}
        local Seen = {}

        for _, Bush in CollectionService:GetTagged("BerryBush") do
            local Config = BerryConfig(Bush)
            local Model = Config.Parent
            local Name = ReadBerryName(Config)

            if Model and Name and not Seen[Model] then
                Seen[Model] = true
                ConfigOf[Model] = Config
                BerryNames[Model] = Name
                Collects[#Collects + 1] = Model
            end
        end

        return Collects
    end

    function VisualManager.NewFruits()
        local Collects = {}

        for _, FolderName in VisualManager.RealFruits do
            local Folder = workspace:FindFirstChild(FolderName)

            if Folder then
                for _, Fruit in Folder:GetChildren() do
                    if Fruit:IsA("Tool") then
                        Collects[#Collects + 1] = Fruit
                    end
                end
            end
        end

        return Collects
    end

    function VisualManager.NewGear()
        local MirageIsland = Map and Map:FindFirstChild("MysticIsland")

        if not MirageIsland then
            return {}
        end

        return Filter(MirageIsland:GetChildren(), function(Object) return Object:IsA("MeshPart") and Object.Name == 'Part' end)
    end

    function VisualManager:AddEsp(Flag, Config)
        self.EspHandlers[Flag] = Config
    end

    function VisualManager.OnToggle(Value, Select)
        local Selected = ToSet(Select or {})

        for Name, Handler in VisualManager.EspInstaller do
            Handler.Enabled = Value and Selected[Name] == true
        end
    end

    VisualManager:AddEsp("Spacial Island", {
        Color = Color3.fromRGB(255, 0, 127),
        Root = function() return Map end,
        Valid = function(Island) return VisualManager.Islands[Island.Name] ~= nil end,
        Label = function(Island) return VisualManager.Islands[Island.Name] end,
    })

    VisualManager:AddEsp("Devil Fruits", {
        Color = Color3.fromRGB(255, 0, 0),
        Root = workspace,
        Valid = function(Fruit) return Fruit.Name:find("Fruit", 1, true) ~= nil end,
        Label = function(Fruit) return VisualManager:ToBloxFruit(Fruit) end,
    })

    VisualManager:AddEsp("Sea Beast", {
        Color = Color3.fromRGB(0, 85, 127),
        Root = function() return SeaBeasts end,
        Valid = function(SeaBeast)
            local Health = SeaBeast:IsA("Model") and SeaBeast:FindFirstChild("Health")

            return Health and Health.Value > 0 or false
        end,
        Label = function(SeaBeast)
            local Health = SeaBeast:FindFirstChild("Health")

            if Health then
                return string.format("Sea Beast [ %d ]", Health.Value)
            end

            return "Sea Beast"
        end,
    })

    VisualManager:AddEsp("Flowers", {
        Color = Color3.fromRGB(255, 170, 255),
        Root = workspace,
        Valid = function(Flower) return Flower.Name:find("Flower", 1, true) ~= nil end,
        Label = function(Flower) return VisualManager.Flowers[Flower.Name] end,
    })

    VisualManager:AddEsp("Players", {
        Color = Color3.fromRGB(255, 255, 255),
        Root = function() return Characters end,
        Valid = function(Character)
            local Target = Players:GetPlayerFromCharacter(Character)

            return Target ~= nil and Target ~= Player
        end,
    })

    VisualManager:AddEsp("Chest", {
        Color = Color3.fromRGB(255, 255, 127),
        Collect = VisualManager.NewChests,
        Valid = function(Chest) return not Chest:GetAttribute("IsDisabled") end,
        Label = function() return "Chest" end,
    })

    VisualManager:AddEsp("Berries", {
        Color = Color3.fromRGB(101, 104, 255),
        Collect = VisualManager.NewBerries,
        Valid = function(Model)
            if Model.Parent == nil or BerryNames[Model] == nil then
                return false
            end

            local Config = ConfigOf[Model]

            if Config and Config.Parent then
                return ReadBerryName(Config) ~= nil
            end

            return true
        end,
        Label = function(Model) return VisualManager:ToBerry(Model) end,
    })

    VisualManager:AddEsp("Fruits", {
        Color = Color3.fromRGB(0, 255, 127),
        Collect = VisualManager.NewFruits,
        Valid = function(Fruit) return Fruit:IsA("Tool") and Fruit.Parent ~= nil end,
        Label = function(Fruit) return Fruit.Name end,
    })

    VisualManager:AddEsp("Gear", {
        Color = Color3.fromRGB(85, 255, 255),
        Collect = VisualManager.NewGear,
        Valid = function(Gear) return Gear:IsA("MeshPart") and Gear.Parent ~= nil end,
        Label = function() return "Gear" end,
    })

    VisualManager:AddEsp("Ship", {
        Color = Color3.fromRGB(115, 169, 255),
        Root = function() return Boats end,
        Valid = function(Ship) return Ship.Parent ~= nil and Ship:GetAttribute("IsBoat") == true end,
        Label = function(Ship)
            local Owner = Ship:FindFirstChild("Owner")

            if Owner and Owner.Value then
                return string.format("%s [ %s ]", Ship.Name, tostring(Owner.Value))
            end

            return Ship.Name
        end,
    })

    for Name, Config in VisualManager.EspHandlers do
        local Handler = EspManager.new(Name)

        Handler:SetEspColor(Config.Color)

        Handler:SetObjects(Config.Collect or function()
            return ChildrenOf(Config.Root)
        end)

        if Config.Valid then
            Handler:Validator(Config.Valid)
            Handler:SetAlwaysValidate()
        end

        if Config.Label then
            Handler:SetCustomEspDisplay(function(Object, Distance)
                return VisualManager:Text(Config.Label(Object) or Object.Name, Distance)
            end)
        end

        VisualManager.EspInstaller[Name] = Handler
    end

    return VisualManager
end)()

Module.RaceModule = (function()
    local StaticsModule = Module.StaticsModule

    local RaceModule = {} do
        RaceModule.UpgradeStatuses = {
            [0] = "Ready for trial.",
            [1] = "Need more training.",
            [2] = "%s ƒ",
            [3] = "Need more training.",
            [4] = "%s ƒ",
            [5] = "Race Complete",
            [6] = "%s/3",
            [7] = "%s ƒ.",
            [8] = "%s training left."
        }

        RaceModule.UpgradeColors = {
            [0] = Color3.fromRGB(0, 255, 127),
            [1] = Color3.fromRGB(255, 170, 0),
            [2] = Color3.fromRGB(170, 85, 255),
            [3] = Color3.fromRGB(255, 170, 0),
            [4] = Color3.fromRGB(170, 85, 255),
            [5] = Color3.fromRGB(0, 255, 127),
            [6] = Color3.fromRGB(0, 255, 127),
            [7] = Color3.fromRGB(170, 85, 255),
            [8] = Color3.fromRGB(255, 170, 0)
        }

        RaceModule.RaceDoors = {
            Fishman = CFrame.new(28224.057, 14889.427, -210.587),
            Human = CFrame.new(29237.295, 14889.427, -206.95),
            Cyborg = CFrame.new(28492, 14901, -426),
            Skypiea = CFrame.new(28967.408, 14918.075, 234.312),
            Ghoul = CFrame.new(28672.721, 14889.128, 454.596),
            Mink = CFrame.new(29020.66, 14889.427, -379.268),
        }

        RaceModule.CurrentDracoStage = 1
        RaceModule.DracoSequence = {
            "Relic1", "EndRelic1", "Relic2",
            "EndRelic2", "Relic3", "EndRelic3"
        }
    end

    function RaceModule:GetRaceStatus()
        if Character and not Character:FindFirstChild("RaceTransformed") then
            return Utils:Color("Unready", Color3.fromRGB(255, 65, 65))
        end

        local UpgradeRace, UpgradesDone, Fragments = Module:ComF("UpgradeRace", "Check")
        local UpgradeStatuses = self.UpgradeStatuses
        local UpgradeColors = self.UpgradeColors

        local Status = UpgradeStatuses[UpgradeRace] or "Unknown"
        local Color = UpgradeColors[UpgradeRace] or Color3.fromRGB(255, 255, 255)

        if UpgradeRace == 2 or UpgradeRace == 4 or UpgradeRace == 7 then
            Status = string.format(Status, tostring(Fragments or "?"))
        elseif UpgradeRace == 6 then
            Status = string.format(Status, tostring((UpgradesDone or 2) - 2))
        elseif UpgradeRace == 8 then
            Status = string.format(Status, tostring(10 - (UpgradesDone or 10)))
        end

        return Utils:Color(Status, Color)
    end

    function RaceModule:IsFruit(Self)
        for _, v in Self:GetChildren() do
            if v:IsA("Tool") and v:GetAttribute('OriginalName') then
                return v
            end
        end
    end

    function RaceModule:GetSkypiesPlayer()
        return StaticsModule.Player(function(__player)
            local Data = __player:FindFirstChild('Data')
            local Race = Data and Data:FindFirstChild('Race')

            return Race and Race.Value == 'Skypiea'
        end)
    end

    function RaceModule.__InitTempleOfTime()
        if Module.GameInfo.Sea == 3 then
            local MapStash = ReplicatedStorage:WaitForChild("MapStash", math.huge)
            local TempleOfTime = MapStash and MapStash:FindFirstChild("Temple of Time")

            if TempleOfTime then
                TempleOfTime.Parent = Map
            end
        end
    end

    return RaceModule
end)()

Module.MasteryModule = (function()
    local PlayerManager = Module.PlayerManager
    local EnemiesModule = Module.EnemiesModule
    local SkillManager = Module.SkillManager
    local QuestModule = Module.QuestModule

    local MasteryModule = {} do
        MasteryModule.__IsBringed = false
    end

    local EnemyGroups = {
        Bones = {
            Tag = "Bones",
            Monsters = { 
                "Reborn Skeleton", "Living Zombie",
                "Demonic Soul", "Posessed Mummy"
            }
        },
        Tiki = {
            Tag = "TyrantSkies",
            Monsters = {
                "Sun-kissed Warrior", "Skull Slayer",
                "Isle Champion", "Serpent Hunter"
            }
        }
    }

    function MasteryModule:ShouldBreak(Enemy, Break)
        return not _ENV.OnFarm or (Break and Break()) or not Module:IsAlive(Enemy) or not PlayerManager:IsAlive()
    end

    function MasteryModule:GetEnemies(Select)
        local EnemyGroup = EnemyGroups[Select]
        if EnemyGroup then
            return EnemiesModule:GetClosestByTag(EnemyGroup.Tag), EnemyGroup.Monsters
        end

        local Quest = QuestModule:GetQuest()
        if not Quest or not Quest.Monster then
            return nil, {}
        end

        return EnemiesModule:GetClosestByTag(Quest.Monster), Quest.Monster
    end

    function MasteryModule:IsAnyEnemyBelowThreshold(Threshold, Range, Position)
        for _, Enemy in Enemies:GetChildren() do
            local PrimaryPart = Enemy.PrimaryPart
            if not PrimaryPart or not Module:IsAlive(Enemy) then continue end
            if (PrimaryPart.Position - Position).Magnitude > Range then continue end

            local Humanoid = Enemy:FindFirstChildOfClass("Humanoid")
            if not Humanoid or Humanoid.MaxHealth <= 0 then continue end
            if Humanoid.Health / Humanoid.MaxHealth * 100 <= Threshold then
                return true
            end
        end
        return false
    end

    function MasteryModule:GetHealthPercent(Humanoid)
        if not Humanoid or Humanoid.MaxHealth <= 0 then return 0 end
        return Humanoid.Health / Humanoid.MaxHealth * 100
    end

    function MasteryModule:CanUseSkill(Humanoid, RootPart)
        if not Humanoid or not RootPart then return false end
        local Threshold = Settings["Mastery Health Threshold"]
        return self:IsAnyEnemyBelowThreshold(Threshold, 50, RootPart.Position) or self:GetHealthPercent(Humanoid) <= Threshold
    end

    function MasteryModule:HandleForMastery(Enemy, Break, Tool)
        if not Module:IsAlive(Enemy) or not PlayerManager:IsAlive() then return end

        local Humanoid = Enemy:FindFirstChildOfClass("Humanoid")
        local RootPart = Enemy:FindFirstChild("HumanoidRootPart")
        if not Humanoid or not RootPart then return end

        repeat
            Heartbeat:Wait()
            if self:ShouldBreak(Enemy, Break) then break end

            PlayerManager:EnabledBuso()

            local SkillReady = self:CanUseSkill(Humanoid, RootPart)
            local ActiveTool = SkillReady and Tool or "Melee"
            local Target = CFrame.new(RootPart.Position + Vector3.new(0, PlayerManager:GetYAxis(ActiveTool), 0))
            local Distance = Player:DistanceFromCharacter(Target.Position)

            PlayerManager:EquipTool(ActiveTool, true)

            if Distance <= 20 and not self.__IsBringed then
                PlayerManager:BringEnemies(Enemy)
                self.__IsBringed = EnemiesModule:IsOnRange(2)
            end

            if Distance <= 5 and SkillReady then
                SkillManager:FireSkill(RootPart.Position, Settings["Select Mastery Skill"])
            end

            if Distance > 3 then
                PlayerManager:Travel(Target)
            end
        until self:ShouldBreak(Enemy, Break)

        self.__IsBringed = false
    end

    return MasteryModule
end)()
