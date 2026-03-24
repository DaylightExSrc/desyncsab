if not game:IsLoaded() then game.Loaded:Wait() end
pcall(function() game:GetService("Players").RespawnTime = 0 end)
local privateBuild = false

local SharedState = {
    SelectedPetData = nil,
    AllAnimalsCache = nil,
    DisableStealSpeed = nil,
    ListNeedsRedraw = true,
    AdminButtonCache = {},
    StealSpeedToggleFunc = nil,
    _ssUpdateBtn = nil,
    AdminProxBtn = nil,
    BalloonedPlayers = {},
    MobileScaleObjects = {},
    RefreshMobileScale = nil,
}

do

    local Sync = require(game.ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Synchronizer"))
    local patched = 0

    for name, fn in pairs(Sync) do
        if typeof(fn) ~= "function" then continue end
        if isexecutorclosure(fn) then continue end

        local ok, ups = pcall(debug.getupvalues, fn)
        if not ok then continue end

        for idx, val in pairs(ups) do
            if typeof(val) == "function" and not isexecutorclosure(val) then
                local ok2, innerUps = pcall(debug.getupvalues, val)
                if ok2 then
                    local hasBoolean = false
                    for _, v in pairs(innerUps) do
                        if typeof(v) == "boolean" then
                            hasBoolean = true
                            break
                        end
                    end
                    if hasBoolean then
                        debug.setupvalue(fn, idx, newcclosure(function() end))
                        patched += 1
                    end
                end
            end
        end
    end
    print("bk's so tuff boi")
end

local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    TweenService = game:GetService("TweenService"),
    HttpService = game:GetService("HttpService"),
    Workspace = game:GetService("Workspace"),
    Lighting = game:GetService("Lighting"),
    VirtualInputManager = game:GetService("VirtualInputManager"),
    GuiService = game:GetService("GuiService"),
    TeleportService = game:GetService("TeleportService"),
}
local Players = Services.Players
local RunService = Services.RunService
local UserInputService = Services.UserInputService
local ReplicatedStorage = Services.ReplicatedStorage
local TweenService = Services.TweenService
local HttpService = Services.HttpService
local Workspace = Services.Workspace
local Lighting = Services.Lighting
local VirtualInputManager = Services.VirtualInputManager
local GuiService = Services.GuiService
local TeleportService = Services.TeleportService
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Decrypted
Decrypted = setmetatable({}, {
    __index = function(S, ez)
        local Netty = ReplicatedStorage.Packages.Net
        local prefix, path
        if     ez:sub(1,3) == "RE/" then prefix = "RE/";  path = ez:sub(4)
        elseif ez:sub(1,3) == "RF/" then prefix = "RF/";  path = ez:sub(4)
        else return nil end
        local Remote
        for i, v in Netty:GetChildren() do
            if v.Name == ez then
                Remote = Netty:GetChildren()[i + 1]
                break
            end
        end
        if Remote and not rawget(Decrypted, ez) then rawset(Decrypted, ez, Remote) end
        return rawget(Decrypted, ez)
    end
})
local Utility = {}
function Utility:LarpNet(F) return Decrypted[F] end
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local function isMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled
end

local IS_MOBILE = isMobile()


local FileName = "XisPublic_v1.json" 
local DefaultConfig = {
    Positions = {
        AdminPanel = {X = 0.1859375, Y = 0.5767123526556385}, 
        StealSpeed = {X = 0.02, Y = 0.18}, 
        Settings = {X = 0.834375, Y = 0.43590998043052839}, 
        InvisPanel = {X = 0.8578125, Y = 0.17260276361454258}, 
        AutoSteal = {X = 0.02, Y = 0.35}, 
        MobileControls = {X = 0.9, Y = 0.4},
        MobileBtn_TP = {X = 0.5, Y = 0.4},
        MobileBtn_CL = {X = 0.5, Y = 0.4},
        MobileBtn_SP = {X = 0.5, Y = 0.4},
        MobileBtn_IV = {X = 0.5, Y = 0.4},
        MobileBtn_UI = {X = 0.5, Y = 0.4},
        JobJoiner = {X = 0.5, Y = 0.85},
    }, 
    TpSettings = {
        Tool           = "Flying Carpet",
        Speed          = 2, 
        TpKey          = "T",
        CloneKey       = "V",
        TpOnLoad       = false,
        MinGenForTp    = "",
        CarpetSpeedKey = "Q",
        InfiniteJump   = false,
    },
    StealSpeed   = 20,
    ShowStealSpeedPanel = true,
    MenuKey      = "LeftControl",
    MobileGuiScale = 0.5,
    XrayEnabled  = true,
    AntiRagdoll  = 0,
    AntiRagdollV2 = false,
    PlayerESP    = true,
    FPSBoost     = true,
    TracerEnabled = true,
    BrainrotESP = true,
    LineToBase = false,
    StealNearest = false,
    StealHighest = true,
    StealPriority = false,
    DefaultToNearest = false,
    DefaultToHighest = false,
    DefaultToPriority = false,
    UILocked     = false,
    HideAdminPanel = false,
    HideAutoSteal = false,
    CompactAutoSteal = false,
    AutoKickOnSteal = false,
    InstantSteal = false,
    InvisStealAngle = 233,
    SinkSliderValue = 5,
    AutoRecoverLagback = true,
    AutoInvisDuringSteal = false,
    InvisToggleKey = "I",
    ClickToAP = false,
    ClickToAPKeybind = "L",
    DisableClickToAPOnMoby = false,
    ProximityAP = false,
    ProximityAPKeybind = "P",
    ProximityRange = 15,
    StealSpeedKey = "C",
    ShowInvisPanel = true,
    ResetKey = "X",
    AutoResetOnBalloon = false,
    AntiBeeDisco = false,
    AutoDestroyTurrets = false,
    FOV = 70,
    SubspaceMineESP = false,
    AutoUnlockOnSteal = false,
    ShowUnlockButtonsHUD = false,
    AutoTPOnFailedSteal = false,
    AutoKickOnSteal = false,
    AutoTPPriority = true,
    KickKey = "",
    CleanErrorGUIs = false,
    ClickToAPSingleCommand = false,
    RagdollSelfKey = "",
    DuelBaseESP = true,
    AlertsEnabled = true,
    ShowDesyncGui = true,
    DesyncOnSteal = false,
    AutoDesync = false,
    AlertSoundID = "rbxassetid://6518811702",
    DisableProximitySpamOnMoby = false,
    DisableClickToAPOnKawaifu = false,
    DisableProximitySpamOnKawaifu = false,
    HideKawaifuFromPanel = false,
    AutoStealSpeed = false,
    ShowJobJoiner = true,
    JobJoinerKey = "J",
}


local Config = DefaultConfig

if isfile and isfile(FileName) then
    pcall(function()
        local ok, decoded = pcall(function() return HttpService:JSONDecode(readfile(FileName)) end)
        if not ok then return end
        for k, v in pairs(DefaultConfig) do
            if decoded[k] == nil then decoded[k] = v end
        end
        if decoded.TpSettings then
            for k, v in pairs(DefaultConfig.TpSettings) do
                if decoded.TpSettings[k] == nil then decoded.TpSettings[k] = v end
            end
        end
        if decoded.Positions then
            for k, v in pairs(DefaultConfig.Positions) do
                if decoded.Positions[k] == nil then decoded.Positions[k] = v end
            end
        end
        Config = decoded
    end)
end
Config.ProximityAP = false

local function SaveConfig()
    if writefile then
        pcall(function()
            local toSave = {}
            for k, v in pairs(Config) do toSave[k] = v end
            toSave.ProximityAP = false
            writefile(FileName, HttpService:JSONEncode(toSave))
        end)
    end
end

local function isMobyUser(player)
    if not player or not player.Character then return false end
    return player.Character:FindFirstChild("_moby_highlight") ~= nil
end

local HighlightName = "KaWaifu_NeonHighlight"
local function isKawaifuUser(player)
    if not player or not player.Character then return false end
    return player.Character:FindFirstChild(HighlightName) ~= nil
end

_G.InvisStealAngle = Config.InvisStealAngle
_G.SinkSliderValue = Config.SinkSliderValue
_G.AutoRecoverLagback = Config.AutoRecoverLagback
_G.AutoInvisDuringSteal = Config.AutoInvisDuringSteal
    _G.INVISIBLE_STEAL_KEY = Enum.KeyCode[Config.InvisToggleKey] or Enum.KeyCode.I
_G.invisibleStealEnabled = false
_G.RecoveryInProgress = false

local function getControls()
	local playerScripts = LocalPlayer:WaitForChild("PlayerScripts")
	local playerModule = require(playerScripts:WaitForChild("PlayerModule"))
	return playerModule:GetControls()
end

local Controls = getControls()

local function kickPlayer()
    LocalPlayer:Kick("\ndiscord.gg/xi-hub - xi loves you <3")
end

local function walkForward(seconds)
    local char = LocalPlayer.Character
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local Controls = getControls()
    local lookVector = hrp.CFrame.LookVector
    Controls:Disable()
    local startTime = os.clock()
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if os.clock() - startTime >= seconds then
            conn:Disconnect()
            hum:Move(Vector3.zero, false)
            Controls:Enable()
            return
        end
        hum:Move(lookVector, false)
    end)
end


local function instantClone()
    if _G.isCloning then return end
    _G.isCloning = true

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not (char and hum) then error("No character") end

        local cloner =
            LocalPlayer.Backpack:FindFirstChild("Quantum Cloner")
            or char:FindFirstChild("Quantum Cloner")

        if not cloner then error("No Quantum Cloner") end

        pcall(function()
            hum:EquipTool(cloner)
        end)

        task.wait(0.05)

        cloner:Activate()
        task.wait(0.05)

        local cloneName = tostring(LocalPlayer.UserId) .. "_Clone"
        for _ = 1, 100 do
            if Workspace:FindFirstChild(cloneName) then break end
            task.wait(0.1)
        end

        if not Workspace:FindFirstChild(cloneName) then
            error("")
        end

        local toolsFrames = LocalPlayer.PlayerGui:FindFirstChild("ToolsFrames")
        local qcFrame = toolsFrames and toolsFrames:FindFirstChild("QuantumCloner")
        local tpButton = qcFrame and qcFrame:FindFirstChild("TeleportToClone")
        if not tpButton then error("Teleport button missing") end

        tpButton.Visible = true

        if firesignal then
            firesignal(tpButton.MouseButton1Up)
        else
            local vim = cloneref and cloneref(game:GetService("VirtualInputManager")) or VirtualInputManager
            local inset = (cloneref and cloneref(game:GetService("GuiService")) or GuiService):GetGuiInset()
            local pos = tpButton.AbsolutePosition + (tpButton.AbsoluteSize / 2) + inset

            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
            task.wait()
            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        end
    end)

    _G.isCloning = false
end

local function triggerClosestUnlock(yLevel, maxY)
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local playerY = yLevel or hrp.Position.Y
    local Y_THRESHOLD = 5

    local bestPromptSameLevel = nil
    local shortestDistSameLevel = math.huge
    local bestPromptFallback = nil
    local shortestDistFallback = math.huge

    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return end

    for _, obj in ipairs(plots:GetDescendants()) do
        -- safe check: only fire ProximityPrompts, skip if parent is bad
        local ok = pcall(function()
            if obj:IsA("ProximityPrompt") and obj.Enabled then
                local part = obj.Parent
                if part and part:IsA("BasePart") then
                    if maxY and part.Position.Y > maxY then
                        return
                    end
                    local distance = (hrp.Position - part.Position).Magnitude
                    local yDifference = math.abs(playerY - part.Position.Y)
                    if distance < shortestDistFallback then
                        shortestDistFallback = distance
                        bestPromptFallback = obj
                    end
                    if yDifference <= Y_THRESHOLD then
                        if distance < shortestDistSameLevel then
                            shortestDistSameLevel = distance
                            bestPromptSameLevel = obj
                        end
                    end
                end
            end
        end)
    end

    local targetPrompt = bestPromptSameLevel or bestPromptFallback
    if targetPrompt then
        pcall(function()
            if fireproximityprompt then
                fireproximityprompt(targetPrompt)
            else
                targetPrompt:InputBegan(Enum.UserInputType.MouseButton1)
                task.wait(0.05)
                targetPrompt:InputEnded(Enum.UserInputType.MouseButton1)
            end
        end)
    end
end

local Theme = {
    Background       = Color3.fromRGB(6, 3, 24),
    Surface          = Color3.fromRGB(12, 8, 35),
    SurfaceHighlight = Color3.fromRGB(22, 14, 55),

    Accent1          = Color3.fromRGB(124, 58, 237),   -- nebula purple
    Accent2          = Color3.fromRGB(6, 182, 212),    -- cosmic teal

    TextPrimary      = Color3.fromRGB(226, 232, 240),
    TextSecondary    = Color3.fromRGB(100, 120, 180),

    Success          = Color3.fromRGB(16, 185, 129),
    Error            = Color3.fromRGB(219, 39, 119),
}

local PRIORITY_LIST = {
   "Strawberry Elephant",
   "Meowl",
   "Skibidi Toilet",
   "Headless Horseman",
   "Dragon Gingerini",
   "Dragon Cannelloni",
   "Ketupat Bros",
   "Hydra Dragon Cannelloni",
   "La Supreme Combinasion",
   "Love Love Bear",
   "Ginger Gerat",
   "Cerberus",
   "Capitano Moby",
   "La Casa Boo",
   "Burguro and Fryuro",
   "Spooky and Pumpky",
   "Cooki and Milki",
   "Rosey and Teddy",
   "Popcuru and Fizzuru",
   "Reinito Sleighito",
   "Fragrama and Chocrama",
   "Garama and Madundung",
   "Ketchuru and Musturu",
   "La Secret Combinasion",
   "Tralaledon",
   "Tictac Sahur",
   "Ketupat Kepat",
   "Tang Tang Keletang",
   "Orcaledon",
   "La Ginger Sekolah",
   "Los Spaghettis",
   "Lavadorito Spinito",
   "Swaggy Bros",
   "La Taco Combinasion",
   "Los Primos",
   "Chillin Chili",
   "Tuff Toucan",
   "W or L",
   "Chillin Chili",
   "Chipso and Queso"
}

local function findAdorneeGlobal(animalData)
    if not animalData then return nil end
    local plot = Workspace:FindFirstChild("Plots") and Workspace.Plots:FindFirstChild(animalData.plot)
    if plot then
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if podiums then
            local podium = podiums:FindFirstChild(animalData.slot)
            if podium then
                local base = podium:FindFirstChild("Base")
                if base then
                    local spawn = base:FindFirstChild("Spawn")
                    if spawn then return spawn end
                    return base:FindFirstChildWhichIsA("BasePart") or base
                end
            end
        end
    end
    return nil
end

local function CreateGradient(parent)
    local g = Instance.new("UIGradient", parent)
    g.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Theme.Accent2),
        ColorSequenceKeypoint.new(1, Theme.Accent2)
    }
    g.Rotation = 45
    return g
end

local function ApplyViewportUIScale(targetFrame, designWidth, designHeight, minScale, maxScale)
    if not targetFrame then return end
    if not IS_MOBILE then return end
    local existing = targetFrame:FindFirstChildOfClass("UIScale")
    if existing then existing:Destroy() end
    local sc = Instance.new("UIScale")
    sc.Parent = targetFrame
    SharedState.MobileScaleObjects[targetFrame] = sc
    if SharedState.RefreshMobileScale then
        SharedState.RefreshMobileScale()
    else
        sc.Scale = math.clamp(tonumber(Config.MobileGuiScale) or 0.5, 0, 1)
    end
end

SharedState.RefreshMobileScale = function()
    local s = math.clamp(tonumber(Config.MobileGuiScale) or 0.5, 0, 1)
    for frame, sc in pairs(SharedState.MobileScaleObjects) do
        if frame and frame.Parent and sc and sc.Parent == frame then
            sc.Scale = s
        else
            SharedState.MobileScaleObjects[frame] = nil
        end
    end
end

local function AddMobileMinimize(frame, labelText)
    if not IS_MOBILE then return end
    if not frame or not frame.Parent then return end
    local guiParent = frame.Parent
    local header = frame:FindFirstChildWhichIsA("Frame")
    if not header then return end

    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 26, 0, 26)
    minimizeBtn.Position = UDim2.new(1, -30, 0, 6)
    minimizeBtn.BackgroundColor3 = Theme.SurfaceHighlight
    minimizeBtn.Text = "-"
    minimizeBtn.Font = Enum.Font.GothamBlack
    minimizeBtn.TextSize = 18
    minimizeBtn.TextColor3 = Theme.TextPrimary
    minimizeBtn.AutoButtonColor = false
    minimizeBtn.Parent = header
    Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 8)

    local restoreBtn = Instance.new("TextButton")
    restoreBtn.Size = UDim2.new(0, 110, 0, 34)
    restoreBtn.Position = UDim2.new(0, 10, 1, -44)
    restoreBtn.BackgroundColor3 = Theme.SurfaceHighlight
    restoreBtn.Text = labelText or "OPEN"
    restoreBtn.Font = Enum.Font.GothamBold
    restoreBtn.TextSize = 12
    restoreBtn.TextColor3 = Theme.TextPrimary
    restoreBtn.Visible = false
    restoreBtn.AutoButtonColor = false
    restoreBtn.Parent = guiParent
    Instance.new("UICorner", restoreBtn).CornerRadius = UDim.new(0, 10)

    MakeDraggable(restoreBtn, restoreBtn)

    minimizeBtn.MouseButton1Click:Connect(function()
        frame.Visible = false
        restoreBtn.Visible = true
    end)

    restoreBtn.MouseButton1Click:Connect(function()
        frame.Visible = true
        restoreBtn.Visible = false
    end)
end

local function MakeDraggable(handle, target, saveKey)
    local dragging, dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if Config.UILocked then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if saveKey then
                        local parentSize = target.Parent.AbsoluteSize
                        Config.Positions[saveKey] = {
                            X = target.AbsolutePosition.X / parentSize.X,
                            Y = target.AbsolutePosition.Y / parentSize.Y,
                        }
                        SaveConfig()
                    end
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function ShowNotification(title, text)
    local existing = PlayerGui:FindFirstChild("XiNotif")
    if existing then existing:Destroy() end

    local sg = Instance.new("ScreenGui", PlayerGui)
    sg.Name = "XiNotif"; sg.ResetOnSpawn = false

    local f = Instance.new("Frame", sg)
    f.Size = UDim2.new(0, 290, 0, 54)
    f.Position = UDim2.new(0.5, -145, 0, 80)
    f.BackgroundColor3 = Color3.fromRGB(6, 6, 12)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 9)

    local stroke = Instance.new("UIStroke", f)
    stroke.Thickness = 1; stroke.Color = Theme.Accent2; stroke.Transparency = 1

    local bar = Instance.new("Frame", f)
    bar.Size = UDim2.new(0, 3, 1, -12); bar.Position = UDim2.new(0, 5, 0, 6)
    bar.BackgroundColor3 = Theme.Accent1; bar.BorderSizePixel = 0
    bar.BackgroundTransparency = 1
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local t1 = Instance.new("TextLabel", f)
    t1.Size = UDim2.new(1, -22, 0, 18); t1.Position = UDim2.new(0, 16, 0, 7)
    t1.BackgroundTransparency = 1; t1.Text = title:upper()
    t1.Font = Enum.Font.GothamBlack; t1.TextSize = 11
    t1.TextColor3 = Theme.Accent1; t1.TextXAlignment = Enum.TextXAlignment.Left
    t1.TextTransparency = 1

    local t2 = Instance.new("TextLabel", f)
    t2.Size = UDim2.new(1, -22, 0, 15); t2.Position = UDim2.new(0, 16, 0, 27)
    t2.BackgroundTransparency = 1; t2.Text = text
    t2.Font = Enum.Font.GothamMedium; t2.TextSize = 10
    t2.TextColor3 = Theme.TextSecondary; t2.TextXAlignment = Enum.TextXAlignment.Left
    t2.TextTransparency = 1

    local fadeIn = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(f,      fadeIn, {BackgroundTransparency = 0.08}):Play()
    TweenService:Create(stroke, fadeIn, {Transparency = 0.3}):Play()
    TweenService:Create(bar,    fadeIn, {BackgroundTransparency = 0}):Play()
    TweenService:Create(t1,     fadeIn, {TextTransparency = 0}):Play()
    TweenService:Create(t2,     fadeIn, {TextTransparency = 0}):Play()

    task.delay(2, function()
        if not sg.Parent then return end
        local fadeOut = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(f,      fadeOut, {BackgroundTransparency = 1}):Play()
        TweenService:Create(stroke, fadeOut, {Transparency = 1}):Play()
        TweenService:Create(bar,    fadeOut, {BackgroundTransparency = 1}):Play()
        TweenService:Create(t1,     fadeOut, {TextTransparency = 1}):Play()
        local last = TweenService:Create(t2, fadeOut, {TextTransparency = 1})
        last:Play(); last.Completed:Wait()
        if sg.Parent then sg:Destroy() end
    end)
end

local function isPlayerCharacter(model)
    return Players:GetPlayerFromCharacter(model) ~= nil
end

local function handleAnimator(animator)
    local model = animator:FindFirstAncestorOfClass("Model")
    if model and isPlayerCharacter(model) then return end
    for _, track in pairs(animator:GetPlayingAnimationTracks()) do track:Stop(0) end
    animator.AnimationPlayed:Connect(function(track) track:Stop(0) end)
end

local function stripVisuals(obj)
    local model = obj:FindFirstAncestorOfClass("Model")
    local isPlayer = model and isPlayerCharacter(model)

    if obj:IsA("Animator") then handleAnimator(obj) end

    if obj:IsA("Accessory") or obj:IsA("Clothing") then
        if obj:FindFirstAncestorOfClass("Model") then
            obj:Destroy()
        end
    end

    if not isPlayer then
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or 
           obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") or 
           obj:IsA("Highlight") then
            obj.Enabled = false
        end
        if obj:IsA("Explosion") then
            obj:Destroy()
        end
        if obj:IsA("MeshPart") then
            obj.TextureID = ""
        end
    end

    if obj:IsA("BasePart") then
        obj.Material = Enum.Material.Plastic
        obj.Reflectance = 0
        obj.CastShadow = false
    end

    if obj:IsA("SurfaceAppearance") or obj:IsA("Texture") or obj:IsA("Decal") then
        obj:Destroy()
    end
end

local function setFPSBoost(enabled)
    Config.FPSBoost = enabled
    SaveConfig()
    
    if enabled then
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1000000
        Lighting.FogStart = 0
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or 
               v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Atmosphere") then
                v:Destroy()
            end
        end

        for _, obj in pairs(Workspace:GetDescendants()) do
            stripVisuals(obj)
        end

        Workspace.DescendantAdded:Connect(function(obj)
            if Config.FPSBoost then
                stripVisuals(obj)
            end
        end)
    end
end
if Config.FPSBoost then task.spawn(function() task.wait(1); setFPSBoost(true) end) end

local State = {
    ProximityAPActive = false,
    carpetSpeedEnabled = false,
    infiniteJumpEnabled = Config.TpSettings.InfiniteJump,
    xrayEnabled = false,
    antiRagdollMode = Config.AntiRagdoll or 0,
    floatActive = false,
    isTpMoving = false,
}
local Connections = {
    carpetSpeedConnection = nil,
    infiniteJumpConnection = nil,
    xrayDescConn = nil,
    antiRagdollConn = nil,
    antiRagdollV2Task = nil,
}
local UI = {
    carpetStatusLabel = nil,
    settingsGui = nil,
}
local carpetSpeedEnabled = State.carpetSpeedEnabled
local carpetSpeedConnection = Connections.carpetSpeedConnection
local _carpetStatusLabel = UI.carpetStatusLabel

local function setCarpetSpeed(enabled)
    State.carpetSpeedEnabled = enabled
    carpetSpeedEnabled = State.carpetSpeedEnabled
    if Connections.carpetSpeedConnection then Connections.carpetSpeedConnection:Disconnect(); Connections.carpetSpeedConnection = nil end
    carpetSpeedConnection = Connections.carpetSpeedConnection
    if not enabled then return end

    if SharedState.DisableStealSpeed then SharedState.DisableStealSpeed() end

    Connections.carpetSpeedConnection = RunService.Heartbeat:Connect(function()
    carpetSpeedConnection = Connections.carpetSpeedConnection
        local c = LocalPlayer.Character
        if not c then return end
        local hum = c:FindFirstChild("Humanoid")
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end

        local toolName = Config.TpSettings.Tool
        local hasTool = c:FindFirstChild(toolName)
        
        if not hasTool then
            local tb = LocalPlayer.Backpack:FindFirstChild(toolName)
            if tb then hum:EquipTool(tb) end
        end

        if hasTool then
            local md = hum.MoveDirection
            if md.Magnitude > 0 then
                hrp.AssemblyLinearVelocity = Vector3.new(
                    md.X * 140, 
                    hrp.AssemblyLinearVelocity.Y, 
                    md.Z * 140
                )
            else
                hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
            end
        end
    end)
end

local JumpData = {lastJumpTime = 0}
local infiniteJumpEnabled = State.infiniteJumpEnabled
local infiniteJumpConnection = Connections.infiniteJumpConnection

local function setInfiniteJump(enabled)
    State.infiniteJumpEnabled = enabled
    infiniteJumpEnabled = State.infiniteJumpEnabled
    Config.TpSettings.InfiniteJump = enabled
    SaveConfig()
    if Connections.infiniteJumpConnection then Connections.infiniteJumpConnection:Disconnect(); Connections.infiniteJumpConnection = nil end
    infiniteJumpConnection = Connections.infiniteJumpConnection
    if not enabled then return end

    Connections.infiniteJumpConnection = RunService.Heartbeat:Connect(function()
    infiniteJumpConnection = Connections.infiniteJumpConnection
        if not UserInputService:IsKeyDown(Enum.KeyCode.Space) then return end
        local now = tick()
        if now - JumpData.lastJumpTime < 0.1 then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then return end
        JumpData.lastJumpTime = now
        hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 55, hrp.AssemblyLinearVelocity.Z)
    end)
end
if infiniteJumpEnabled then setInfiniteJump(true) end

local XrayState = {
    originalTransparency = {},
    xrayEnabled = false,
}
local originalTransparency = XrayState.originalTransparency
local xrayEnabled = XrayState.xrayEnabled

local function isBaseWall(obj)
    if not obj:IsA("BasePart") then return false end
    local name = obj.Name:lower()
    local parentName = (obj.Parent and obj.Parent.Name:lower()) or ""
    return name:find("base") or parentName:find("base")
end

local function enableXray()
    XrayState.xrayEnabled = true
    xrayEnabled = XrayState.xrayEnabled
    do
        local descendants = Workspace:GetDescendants()
        for i = 1, #descendants do
            local obj = descendants[i]
            if obj:IsA("BasePart") and obj.Anchored and isBaseWall(obj) then
                XrayState.originalTransparency[obj] = obj.LocalTransparencyModifier
                originalTransparency[obj] = XrayState.originalTransparency[obj]
                obj.LocalTransparencyModifier = 0.85
            end
        end
    end
end

local xrayDescConn = Connections.xrayDescConn
local function disableXray()
    XrayState.xrayEnabled = false
    xrayEnabled = XrayState.xrayEnabled
    if Connections.xrayDescConn then Connections.xrayDescConn:Disconnect(); Connections.xrayDescConn = nil end
    xrayDescConn = Connections.xrayDescConn
    for part, val in pairs(XrayState.originalTransparency) do
        if part and part.Parent then part.LocalTransparencyModifier = val end
    end
    XrayState.originalTransparency = {}
    originalTransparency = XrayState.originalTransparency
end

if Config.XrayEnabled then
    enableXray()
    Connections.xrayDescConn = Workspace.DescendantAdded:Connect(function(obj)
        if XrayState.xrayEnabled and obj:IsA("BasePart") and obj.Anchored and isBaseWall(obj) then
            XrayState.originalTransparency[obj] = obj.LocalTransparencyModifier
            originalTransparency[obj] = XrayState.originalTransparency[obj]
            obj.LocalTransparencyModifier = 0.85
        end
    end)
    xrayDescConn = Connections.xrayDescConn
end

local antiRagdollMode = State.antiRagdollMode
local antiRagdollConn = Connections.antiRagdollConn

local function isRagdolled()
    local char = LocalPlayer.Character; if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return false end
    local state = hum:GetState()
    local ragStates = {
        [Enum.HumanoidStateType.Physics]     = true,
        [Enum.HumanoidStateType.Ragdoll]     = true,
        [Enum.HumanoidStateType.FallingDown] = true,
    }
    if ragStates[state] then return true end
    local endTime = LocalPlayer:GetAttribute("RagdollEndTime")
    if endTime and (endTime - Workspace:GetServerTimeNow()) > 0 then return true end
    return false
end

local function stopAntiRagdoll()
    if Connections.antiRagdollConn then Connections.antiRagdollConn:Disconnect(); Connections.antiRagdollConn = nil end
    antiRagdollConn = Connections.antiRagdollConn
end


local function startAntiRagdoll(mode)
    stopAntiRagdoll()
    if Config.AntiRagdollV2 then
        stopAntiRagdollV2()
    end
    if mode == 0 then return end

    Connections.antiRagdollConn = RunService.Heartbeat:Connect(function()
    antiRagdollConn = Connections.antiRagdollConn
        local char = LocalPlayer.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end

        if isRagdolled() then
            pcall(function() LocalPlayer:SetAttribute("RagdollEndTime", Workspace:GetServerTimeNow()) end)
            hum:ChangeState(Enum.HumanoidStateType.Running)
            hrp.AssemblyLinearVelocity = Vector3.zero
            if Workspace.CurrentCamera.CameraSubject ~= hum then
                Workspace.CurrentCamera.CameraSubject = hum
            end
            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("BallSocketConstraint") or obj.Name:find("RagdollAttachment") then
                    pcall(function() obj:Destroy() end)
                end
            end
        end
    end)
end

local AntiRagdollV2Data = {
    antiRagdollConns = {},
}
local antiRagdollConns = AntiRagdollV2Data.antiRagdollConns

local cleanRagdollV2Scheduled = false
local function cleanRagdollV2(char)
    if not char then return end
    local carpetEquipped = false
    pcall(function()
        local toolName = Config.TpSettings.Tool or "Flying Carpet"
        local tool = char:FindFirstChild(toolName)
        if tool then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, obj in ipairs(hrp:GetChildren()) do
                    if obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") then
                        carpetEquipped = true
                        break
                    end
                end
            end
            if not carpetEquipped then
                for _, obj in ipairs(tool:GetChildren()) do
                    if obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") then
                        carpetEquipped = true
                        break
                    end
                end
            end
        end
    end)
    local descendants = char:GetDescendants()
    for _, d in ipairs(descendants) do
        if d:IsA("BallSocketConstraint") or d:IsA("NoCollisionConstraint")
            or d:IsA("HingeConstraint")
            or (d:IsA("Attachment") and (d.Name == "A" or d.Name == "B")) then
            d:Destroy()
        elseif (d:IsA("BodyVelocity") or d:IsA("BodyPosition") or d:IsA("BodyGyro")) and not carpetEquipped then
            d:Destroy()
        end
    end
    for _, d in ipairs(descendants) do
        if d:IsA("Motor6D") then d.Enabled = true end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        local animator = hum:FindFirstChild("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                local n = track.Animation and track.Animation.Name:lower() or ""
                if n:find("rag") or n:find("fall") or n:find("hurt") or n:find("down") then
                    track:Stop(0)
                end
            end
        end
    end
    task.defer(function()
        pcall(function()
            local pm = LocalPlayer:FindFirstChild("PlayerScripts")
            if pm then pm = pm:FindFirstChild("PlayerModule") end
            if pm then require(pm):GetControls():Enable() end
        end)
    end)
end
local function cleanRagdollV2Debounced(char)
    if cleanRagdollV2Scheduled then return end
    cleanRagdollV2Scheduled = true
    task.defer(function()
        cleanRagdollV2Scheduled = false
        if char and char.Parent then cleanRagdollV2(char) end
    end)
end
local function isRagdollRelatedDescendant(obj)
    if obj:IsA("BallSocketConstraint") or obj:IsA("NoCollisionConstraint") or obj:IsA("HingeConstraint") then return true end
    if obj:IsA("Attachment") and (obj.Name == "A" or obj.Name == "B") then return true end
    if obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") then return true end
    return false
end

local function hookAntiRagV2(char)
    for _, c in ipairs(antiRagdollConns) do pcall(function() c:Disconnect() end) end
    AntiRagdollV2Data.antiRagdollConns = {}
    antiRagdollConns = AntiRagdollV2Data.antiRagdollConns

    local hum = char:WaitForChild("Humanoid", 10)
    local hrp = char:WaitForChild("HumanoidRootPart", 10)
    if not hum or not hrp then return end

    local lastVel = Vector3.new(0, 0, 0)

    local c1 = hum.StateChanged:Connect(function()
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll
            or st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.GettingUp then
            local carpetActive = false
            pcall(function()
                local toolName = Config.TpSettings.Tool or "Flying Carpet"
                local tool = char:FindFirstChild(toolName)
                if tool and hrp then
                    for _, obj in ipairs(hrp:GetChildren()) do
                        if obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") then
                            carpetActive = true
                        end
                    end
                end
            end)
            if not carpetActive then
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
            cleanRagdollV2(char)
            pcall(function() Workspace.CurrentCamera.CameraSubject = hum end)
            pcall(function()
                local pm = LocalPlayer:FindFirstChild("PlayerScripts")
                if pm then pm = pm:FindFirstChild("PlayerModule") end
                if pm then require(pm):GetControls():Enable() end
            end)
        end
    end)
    table.insert(antiRagdollConns, c1)

    local c2 = char.DescendantAdded:Connect(function(desc)
        if isRagdollRelatedDescendant(desc) then
            cleanRagdollV2Debounced(char)
        end
    end)
    table.insert(antiRagdollConns, c2)

    pcall(function()
        local pkg = ReplicatedStorage:FindFirstChild("Packages")
        if pkg then
            local net = pkg:FindFirstChild("Net")
            if net then
                local applyImp = net:FindFirstChild("RE/CombatService/ApplyImpulse")
                if applyImp and applyImp:IsA("RemoteEvent") then
                    local c3 = applyImp.OnClientEvent:Connect(function()
                        local st = hum:GetState()
                        if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll
                            or st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.GettingUp then
                            pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
                        end
                    end)
                    table.insert(antiRagdollConns, c3)
                end
            end
        end
    end)

    local c4 = RunService.Heartbeat:Connect(function()
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll
            or st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.GettingUp then
            cleanRagdollV2(char)
            local vel = hrp.AssemblyLinearVelocity
            if (vel - lastVel).Magnitude > 40 and vel.Magnitude > 25 then
                hrp.AssemblyLinearVelocity = vel.Unit * math.min(vel.Magnitude, 15)
            end
        end
        lastVel = hrp.AssemblyLinearVelocity
    end)
    table.insert(antiRagdollConns, c4)

    cleanRagdollV2(char)
end

local function stopAntiRagdollV2()
    cleanRagdollV2Scheduled = false
    for _, c in ipairs(antiRagdollConns) do pcall(function() c:Disconnect() end) end
    AntiRagdollV2Data.antiRagdollConns = {}
    antiRagdollConns = AntiRagdollV2Data.antiRagdollConns
end

local function startAntiRagdollV2(enabled)
    stopAntiRagdoll()
    stopAntiRagdollV2()
    if not enabled then
        return
    end

    local char = LocalPlayer.Character
    if char then task.spawn(function() hookAntiRagV2(char) end) end
    LocalPlayer.CharacterAdded:Connect(function(c)
        task.spawn(function() hookAntiRagV2(c) end)
    end)
end

if antiRagdollMode > 0 then startAntiRagdoll(antiRagdollMode) end
if Config.AntiRagdollV2 then startAntiRagdollV2(true) end

do
    local plotBeam = nil
    local plotBeamAttachment0 = nil
    local plotBeamAttachment1 = nil

    local function findMyPlot()
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return nil end
        for _, plot in ipairs(plots:GetChildren()) do
            local sign = plot:FindFirstChild("PlotSign")
            if sign then
                local surfaceGui = sign:FindFirstChildWhichIsA("SurfaceGui", true)
                if surfaceGui then
                    local label = surfaceGui:FindFirstChildWhichIsA("TextLabel", true)
                    if label then
                        local text = label.Text:lower()
                        if text:find(LocalPlayer.DisplayName:lower(), 1, true) or text:find(LocalPlayer.Name:lower(), 1, true) then
                            return plot
                        end
                    end
                end
            end
        end
        return nil
    end

    local function createPlotBeam()
        if not Config.LineToBase then return end
        local myPlot = findMyPlot()
        if not myPlot or not myPlot.Parent then return end
        local character = LocalPlayer.Character
        if not character or not character.Parent then return end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return end
        if plotBeam then pcall(function() plotBeam:Destroy() end) end
        if plotBeamAttachment0 then pcall(function() plotBeamAttachment0:Destroy() end) end
        plotBeamAttachment0 = hrp:FindFirstChild("PlotBeamAttach_Player") or Instance.new("Attachment")
        plotBeamAttachment0.Name = "PlotBeamAttach_Player"
        plotBeamAttachment0.Position = Vector3.new(0, 0, 0)
        plotBeamAttachment0.Parent = hrp
        local plotPart = myPlot:FindFirstChild("MainRootPart") or myPlot:FindFirstChildWhichIsA("BasePart")
        if not plotPart or not plotPart.Parent then return end
        plotBeamAttachment1 = plotPart:FindFirstChild("PlotBeamAttach_Plot") or Instance.new("Attachment")
        plotBeamAttachment1.Name = "PlotBeamAttach_Plot"
        plotBeamAttachment1.Position = Vector3.new(0, 5, 0)
        plotBeamAttachment1.Parent = plotPart
        plotBeam = hrp:FindFirstChild("PlotBeam") or Instance.new("Beam")
        plotBeam.Name = "PlotBeam"
        plotBeam.Attachment0 = plotBeamAttachment0
        plotBeam.Attachment1 = plotBeamAttachment1
        plotBeam.FaceCamera = true
        plotBeam.LightEmission = 1
        plotBeam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
        plotBeam.Transparency = NumberSequence.new(0)
        plotBeam.Width0 = 0.7
        plotBeam.Width1 = 0.7
        plotBeam.TextureMode = Enum.TextureMode.Wrap
        plotBeam.TextureSpeed = 0
        plotBeam.Parent = hrp
    end

    local function resetPlotBeam()
        if plotBeam then pcall(function() plotBeam:Destroy() end) end
        if plotBeamAttachment0 then pcall(function() plotBeamAttachment0:Destroy() end) end
        if plotBeamAttachment1 then pcall(function() plotBeamAttachment1:Destroy() end) end
        plotBeam = nil
        plotBeamAttachment0 = nil
        plotBeamAttachment1 = nil
    end

    task.spawn(function()
        local checkCounter = 0
        RunService.Heartbeat:Connect(function()
            if not Config.LineToBase then return end
            checkCounter = checkCounter + 1
            if checkCounter >= 30 then
                checkCounter = 0
                if not plotBeam or not plotBeam.Parent or not plotBeamAttachment0 or not plotBeamAttachment0.Parent then
                    pcall(createPlotBeam)
                end
            end
        end)
    end)

    LocalPlayer.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        if Config.LineToBase and character then
            pcall(createPlotBeam)
        end
    end)

    if LocalPlayer.Character then
        task.spawn(function()
            task.wait(0.2)
            if Config.LineToBase then createPlotBeam() end
        end)
    end

    _G.createPlotBeam = createPlotBeam
    _G.resetPlotBeam = resetPlotBeam
end

task.spawn(function()
    if Config.ShowDesyncGui == nil then Config.ShowDesyncGui = true end
    if Config.DesyncOnSteal == nil then Config.DesyncOnSteal = false end
    if Config.AutoDesync == nil then Config.AutoDesync = false end

    local desyncGui = Instance.new("ScreenGui")
    desyncGui.Name = "XiDesyncPanel"
    desyncGui.ResetOnSpawn = false
    desyncGui.Enabled = Config.ShowDesyncGui
    desyncGui.Parent = PlayerGui

    local dFrame = Instance.new("Frame")
    dFrame.Size = UDim2.new(0, 260, 0, 220)
    dFrame.Position = UDim2.new(0.02, 0, 0.55, 0)
    dFrame.BackgroundColor3 = Color3.fromRGB(5, 3, 16)
    dFrame.BackgroundTransparency = 0.04
    dFrame.BorderSizePixel = 0
    dFrame.ClipsDescendants = true
    dFrame.Parent = desyncGui
    Instance.new("UICorner", dFrame).CornerRadius = UDim.new(0, 16)

    local dStroke = Instance.new("UIStroke", dFrame)
    dStroke.Thickness = 1.8
    dStroke.Color = Color3.fromRGB(6, 182, 212)
    dStroke.Transparency = 0.3
    task.spawn(function()
        local cols = {Color3.fromRGB(6,182,212), Color3.fromRGB(14,165,233), Color3.fromRGB(99,102,241), Color3.fromRGB(6,182,212)}
        local bi = 1
        while dStroke.Parent do
            TweenService:Create(dStroke, TweenInfo.new(1.3, Enum.EasingStyle.Sine), {Color = cols[bi]}):Play()
            bi = (bi % #cols) + 1
            task.wait(1.3)
        end
    end)

    local dHeader = Instance.new("Frame", dFrame)
    dHeader.Size = UDim2.new(1, 0, 0, 48)
    dHeader.BackgroundColor3 = Color3.fromRGB(6, 182, 212)
    dHeader.BackgroundTransparency = 0.85
    dHeader.BorderSizePixel = 0
    local dHeaderGrad = Instance.new("UIGradient", dHeader)
    dHeaderGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(6, 182, 212)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(99, 102, 241))
    }
    dHeaderGrad.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.78),
        NumberSequenceKeypoint.new(1, 0.92)
    }
    MakeDraggable(dHeader, dFrame, nil)

    local dHeaderLine = Instance.new("Frame", dFrame)
    dHeaderLine.Size = UDim2.new(1, 0, 0, 1)
    dHeaderLine.Position = UDim2.new(0, 0, 0, 48)
    dHeaderLine.BackgroundColor3 = Color3.fromRGB(6, 182, 212)
    dHeaderLine.BackgroundTransparency = 0.45
    dHeaderLine.BorderSizePixel = 0
    local dLineGrad = Instance.new("UIGradient", dHeaderLine)
    dLineGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(6,182,212)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0))
    }

    local dIconBg = Instance.new("Frame", dHeader)
    dIconBg.Size = UDim2.new(0, 32, 0, 32)
    dIconBg.Position = UDim2.new(0, 10, 0.5, -16)
    dIconBg.BackgroundColor3 = Color3.fromRGB(6, 182, 212)
    dIconBg.BackgroundTransparency = 0.65
    Instance.new("UICorner", dIconBg).CornerRadius = UDim.new(0, 8)
    local dIconStroke = Instance.new("UIStroke", dIconBg)
    dIconStroke.Color = Color3.fromRGB(6, 182, 212)
    dIconStroke.Thickness = 1.5
    dIconStroke.Transparency = 0.2
    local dIcon = Instance.new("TextLabel", dIconBg)
    dIcon.Size = UDim2.new(1,0,1,0)
    dIcon.BackgroundTransparency = 1
    dIcon.Text = "📡"
    dIcon.TextSize = 16
    dIcon.Font = Enum.Font.GothamBlack

    local dTitle = Instance.new("TextLabel", dHeader)
    dTitle.Size = UDim2.new(1, -55, 1, 0)
    dTitle.Position = UDim2.new(0, 50, 0, 0)
    dTitle.BackgroundTransparency = 1
    dTitle.Text = "DESYNC"
    dTitle.Font = Enum.Font.GothamBlack
    dTitle.TextSize = 16
    dTitle.TextColor3 = Color3.fromRGB(180, 240, 255)
    dTitle.TextXAlignment = Enum.TextXAlignment.Left

    local dStatusBadge = Instance.new("TextLabel", dHeader)
    dStatusBadge.Size = UDim2.new(0, 58, 0, 18)
    dStatusBadge.Position = UDim2.new(1, -66, 0.5, -9)
    dStatusBadge.BackgroundColor3 = Color3.fromRGB(30, 30, 60)
    dStatusBadge.BackgroundTransparency = 0.3
    dStatusBadge.Text = "○ INACTIVE"
    dStatusBadge.Font = Enum.Font.GothamBold
    dStatusBadge.TextSize = 8
    dStatusBadge.TextColor3 = Color3.fromRGB(100, 90, 150)
    Instance.new("UICorner", dStatusBadge).CornerRadius = UDim.new(1, 0)
    local dStatusStroke = Instance.new("UIStroke", dStatusBadge)
    dStatusStroke.Color = Color3.fromRGB(60, 50, 100)
    dStatusStroke.Thickness = 1
    dStatusStroke.Transparency = 0.3

    local dContent = Instance.new("Frame", dFrame)
    dContent.Size = UDim2.new(1, -20, 1, -58)
    dContent.Position = UDim2.new(0, 10, 0, 58)
    dContent.BackgroundTransparency = 1
    local dLayout = Instance.new("UIListLayout", dContent)
    dLayout.Padding = UDim.new(0, 10)
    dLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function CreateDesyncToggleRow(labelText, initialState, orderNum, callback)
        local row = Instance.new("Frame", dContent)
        row.Size = UDim2.new(1, 0, 0, 34)
        row.BackgroundColor3 = Color3.fromRGB(12, 8, 28)
        row.BackgroundTransparency = 0.05
        row.BorderSizePixel = 0
        row.LayoutOrder = orderNum
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
        local rowStroke = Instance.new("UIStroke", row)
        rowStroke.Color = Color3.fromRGB(30, 20, 55)
        rowStroke.Thickness = 1
        rowStroke.Transparency = 0.4

        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(0.62, 0, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 12
        lbl.TextColor3 = Color3.fromRGB(190, 180, 220)
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local sw = Instance.new("Frame", row)
        sw.Size = UDim2.new(0, 42, 0, 22)
        sw.Position = UDim2.new(1, -52, 0.5, -11)
        sw.BackgroundColor3 = initialState and Color3.fromRGB(4, 80, 100) or Color3.fromRGB(20, 14, 40)
        sw.BorderSizePixel = 0
        Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)
        local swStroke = Instance.new("UIStroke", sw)
        swStroke.Thickness = 1.5
        swStroke.Color = initialState and Color3.fromRGB(6, 182, 212) or Color3.fromRGB(40, 30, 70)
        swStroke.Transparency = 0.25

        local dot = Instance.new("Frame", sw)
        dot.Size = UDim2.new(0, 16, 0, 16)
        dot.Position = initialState and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        dot.BorderSizePixel = 0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

        local swBtn = Instance.new("TextButton", sw)
        swBtn.Size = UDim2.new(1, 0, 1, 0)
        swBtn.BackgroundTransparency = 1
        swBtn.Text = ""

        local isOn = initialState
        local function SetState(s)
            isOn = s
            TweenService:Create(dot, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = s and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            }):Play()
            TweenService:Create(sw, TweenInfo.new(0.2), {BackgroundColor3 = s and Color3.fromRGB(4,80,100) or Color3.fromRGB(20,14,40)}):Play()
            TweenService:Create(swStroke, TweenInfo.new(0.2), {Color = s and Color3.fromRGB(6,182,212) or Color3.fromRGB(40,30,70)}):Play()
        end

        swBtn.MouseButton1Click:Connect(function() callback(not isOn, SetState) end)
        row.MouseEnter:Connect(function() TweenService:Create(rowStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(6,182,212), Transparency = 0.3}):Play() end)
        row.MouseLeave:Connect(function() TweenService:Create(rowStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(30,20,55), Transparency = 0.4}):Play() end)
        return SetState
    end

    local _setAutoDesync
    local setDesyncOnSteal = CreateDesyncToggleRow("Desync on Steal", Config.DesyncOnSteal, 1, function(ns, set)
        Config.DesyncOnSteal = ns
        if ns then
            Config.AutoDesync = false
            if _setAutoDesync then _setAutoDesync(false) end
        end
        SaveConfig(); set(ns)
        ShowNotification("DESYNC", "On Steal: " .. (ns and "ON" or "OFF"))
    end)

    _setAutoDesync = CreateDesyncToggleRow("Auto Desync", Config.AutoDesync, 2, function(ns, set)
        Config.AutoDesync = ns
        if ns then
            Config.DesyncOnSteal = false
            setDesyncOnSteal(false)
        end
        SaveConfig(); set(ns)
        ShowNotification("DESYNC", "Auto: " .. (ns and "ON" or "OFF"))
    end)

    local dInfoLabel = Instance.new("TextLabel", dContent)
    dInfoLabel.Size = UDim2.new(1, 0, 0, 26)
    dInfoLabel.LayoutOrder = 3
    dInfoLabel.BackgroundColor3 = Color3.fromRGB(6, 182, 212)
    dInfoLabel.BackgroundTransparency = 0.88
    dInfoLabel.Text = "ℹ  Requires executor desync support"
    dInfoLabel.Font = Enum.Font.GothamMedium
    dInfoLabel.TextSize = 9
    dInfoLabel.TextColor3 = Color3.fromRGB(100, 180, 210)
    dInfoLabel.TextXAlignment = Enum.TextXAlignment.Center
    Instance.new("UICorner", dInfoLabel).CornerRadius = UDim.new(0, 6)
    local dInfoStroke = Instance.new("UIStroke", dInfoLabel)
    dInfoStroke.Color = Color3.fromRGB(6, 182, 212)
    dInfoStroke.Thickness = 1
    dInfoStroke.Transparency = 0.5

    task.spawn(function()
        while dFrame.Parent do
            local active = Config.DesyncOnSteal or Config.AutoDesync
            if active then
                dStatusBadge.Text = "🟢 ACTIVE"
                dStatusBadge.TextColor3 = Color3.fromRGB(100, 220, 255)
                dStatusBadge.BackgroundColor3 = Color3.fromRGB(4, 60, 80)
                dStatusStroke.Color = Color3.fromRGB(6, 182, 212)
            else
                dStatusBadge.Text = "🔴 INACTIVE"
                dStatusBadge.TextColor3 = Color3.fromRGB(100, 90, 150)
                dStatusBadge.BackgroundColor3 = Color3.fromRGB(30, 30, 60)
                dStatusStroke.Color = Color3.fromRGB(60, 50, 100)
            end
            task.wait(0.5)
        end
    end)
end)

task.spawn(function()
    local Packages = ReplicatedStorage:WaitForChild("Packages")
    local Datas    = ReplicatedStorage:WaitForChild("Datas")
    local Shared   = ReplicatedStorage:WaitForChild("Shared")
    local Utils    = ReplicatedStorage:WaitForChild("Utils")

    local Synchronizer  = require(Packages:WaitForChild("Synchronizer"))
    local AnimalsData   = require(Datas:WaitForChild("Animals"))
    local AnimalsShared = require(Shared:WaitForChild("Animals"))
    local NumberUtils   = require(Utils:WaitForChild("NumberUtils"))

    local autoStealEnabled   = true
    
    
    if Config.DefaultToPriority and Config.DefaultToHighest then
        Config.DefaultToHighest = false
    end
    if Config.DefaultToPriority and Config.DefaultToNearest then
        Config.DefaultToNearest = false
    end
    if Config.DefaultToHighest and Config.DefaultToNearest then
        Config.DefaultToNearest = false
    end
    
    if not Config.DefaultToPriority and not Config.DefaultToHighest and not Config.DefaultToNearest then
        Config.DefaultToHighest = true
    end
    
    local stealNearestEnabled = false
    local stealHighestEnabled = false
    local stealPriorityEnabled = false
    
    if Config.DefaultToNearest then
        stealNearestEnabled = true
        Config.StealNearest = true
        Config.StealHighest = false
        Config.StealPriority = false
        
        Config.AutoTPPriority = true
    elseif Config.DefaultToHighest then
        stealHighestEnabled = true
        Config.StealHighest = true
        Config.StealNearest = false
        Config.StealPriority = false
        
        Config.AutoTPPriority = false
    elseif Config.DefaultToPriority then
        stealPriorityEnabled = true
        Config.StealPriority = true
        Config.StealNearest = false
        Config.StealHighest = false
        
        Config.AutoTPPriority = true
    else
        stealNearestEnabled = Config.StealNearest
        stealHighestEnabled = Config.StealHighest
        stealPriorityEnabled = Config.StealPriority
        
        if Config.InstantSteal == nil then Config.InstantSteal = false end
        if Config.StealPriority then
            Config.AutoTPPriority = true
        elseif Config.StealNearest then
            Config.AutoTPPriority = true
        elseif Config.StealHighest then
            Config.AutoTPPriority = false
        end
    end
    
    local instantStealEnabled = (Config.InstantSteal == true)
    local instantStealReady = false
    local instantStealDidInit = false
    local selectedTargetIndex = 1
    local selectedTargetUID   = nil 
    local allAnimalsCache    = {}
    local InternalStealCache = {}
    local PromptMemoryCache  = {}
    local activeProgressTween = nil
    local currentStealTargetUID = nil
    local petButtons         = {}
    
    local function isMyBaseAnimal(animalData)
        if not animalData or not animalData.plot then return false end
        local plots = Workspace:FindFirstChild("Plots")
        if not plots then return false end
        local plot = plots:FindFirstChild(animalData.plot)
        if not plot then return false end
        local channel = Synchronizer:Get(plot.Name)
        if channel then
            local owner = channel:Get("Owner")
            if owner then
                if typeof(owner) == "Instance" and owner:IsA("Player") then return owner.UserId == LocalPlayer.UserId
                elseif typeof(owner) == "table" and owner.UserId then return owner.UserId == LocalPlayer.UserId
                elseif typeof(owner) == "Instance" then return owner == LocalPlayer end
            end
        end
        return false
    end
    
    local function formatMutationText(mutationName)
        if not mutationName or mutationName == "None" then return "" end
        local f = ""
        if mutationName == "Cursed" then f = "<font color='rgb(200,0,0)'>Cur</font><font color='rgb(0,0,0)'>sed</font>"
        elseif mutationName == "Gold" then f = "<font color='rgb(255,215,0)'>Gold</font>"
        elseif mutationName == "Diamond" then f = "<font color='rgb(0,255,255)'>Diamond</font>"
        elseif mutationName == "YinYang" then f = "<font color='rgb(255,255,255)'>Yin</font><font color='rgb(0,0,0)'>Yang</font>"
        elseif mutationName == "Candy" then f = "<font color='rgb(255,105,180)'>Candy</font>"
        elseif mutationName == "Divine" then f = "<font color='rgb(255,255,255)'>Divine</font>"
        elseif mutationName == "Rainbow" then
            local cols = {"rgb(255,0,0)","rgb(255,127,0)","rgb(255,255,0)","rgb(0,255,0)","rgb(0,0,255)","rgb(75,0,130)","rgb(148,0,211)"}
            for i = 1, #mutationName do f = f.."<font color='"..cols[(i-1)%#cols+1].."'>"..mutationName:sub(i,i).."</font>" end
        else f = mutationName end
        return "<font weight='800'>"..f.." </font>"
    end

    local function get_all_pets()
        local out = {}
        for _, a in ipairs(allAnimalsCache) do
            if a.genValue >= 1 and not isMyBaseAnimal(a) then
                table.insert(out, {petName=a.name, mpsText=a.genText, mpsValue=a.genValue,
                    owner=a.owner, plot=a.plot, slot=a.slot, uid=a.uid, mutation=a.mutation, animalData=a})
            end
        end
        return out
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoStealUI"; screenGui.ResetOnSpawn = false; screenGui.Parent = PlayerGui

    -- ── MAIN FRAME ──────────────────────────────────────────────────────
    local frame = Instance.new("Frame")
    local mobileScale = IS_MOBILE and 0.6 or 1
    frame.Size = UDim2.new(0, 310*mobileScale, 0, 640*mobileScale)
    frame.Position = UDim2.new(Config.Positions.AutoSteal.X, 0, Config.Positions.AutoSteal.Y, 0)
    frame.BackgroundColor3 = Color3.fromRGB(4, 2, 15)
    frame.BackgroundTransparency = 0.03
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = screenGui

    ApplyViewportUIScale(frame, 310, 640, 0.45, 0.8)
    AddMobileMinimize(frame, "Lethals - Auto Steal")
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

    -- Animated border stroke
    local mainStroke = Instance.new("UIStroke", frame)
    mainStroke.Thickness = 1.5
    mainStroke.Color = Color3.fromRGB(124, 58, 237)
    mainStroke.Transparency = 0.3

    -- Animate border color cycling
    task.spawn(function()
        local borderColors = {
            Color3.fromRGB(124, 58, 237),
            Color3.fromRGB(219, 39, 119),
            Color3.fromRGB(37, 99, 235),
            Color3.fromRGB(6, 182, 212),
        }
        local bi = 1
        while mainStroke.Parent do
            TweenService:Create(mainStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {
                Color = borderColors[bi]
            }):Play()
            bi = (bi % #borderColors) + 1
            task.wait(1.5)
        end
    end)

    -- ── HEADER ──────────────────────────────────────────────────────────
    local header = Instance.new("Frame", frame)
    header.Size = UDim2.new(1, 0, 0, 44)
    header.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
    header.BackgroundTransparency = 0.85
    header.BorderSizePixel = 0

    local headerGrad = Instance.new("UIGradient", header)
    headerGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(124, 58, 237)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(219, 39, 119))
    }
    headerGrad.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.75),
        NumberSequenceKeypoint.new(1, 0.9)
    }

    local headerLine = Instance.new("Frame", frame)
    headerLine.Size = UDim2.new(1, 0, 0, 1)
    headerLine.Position = UDim2.new(0, 0, 0, 44)
    headerLine.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
    headerLine.BackgroundTransparency = 0.5
    headerLine.BorderSizePixel = 0
    local headerLineGrad = Instance.new("UIGradient", headerLine)
    headerLineGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(124,58,237)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0))
    }

    MakeDraggable(header, frame, "AutoSteal")

    local titleLabel = Instance.new("TextLabel", header)
    titleLabel.Size = IS_MOBILE and UDim2.new(0.4, 0, 1, 0) or UDim2.new(0.6, 0, 1, 0)
    titleLabel.Position = UDim2.new(0, 14, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Lethals - Auto Steal"
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = 15
    titleLabel.TextColor3 = Color3.fromRGB(200, 180, 255)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Animate title color shimmer
    task.spawn(function()
        local tc = {
            Color3.fromRGB(200, 180, 255),
            Color3.fromRGB(244, 114, 182),
            Color3.fromRGB(6, 182, 212),
            Color3.fromRGB(226, 232, 240),
        }
        local ti = 1
        while titleLabel.Parent do
            TweenService:Create(titleLabel, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {
                TextColor3 = tc[ti]
            }):Play()
            ti = (ti % #tc) + 1
            task.wait(1.5)
        end
    end)

    -- Enabled badge
    local enabledBadge = Instance.new("TextLabel", header)
    enabledBadge.Size = UDim2.new(0, 70, 0, 20)
    enabledBadge.Position = UDim2.new(1, -80, 0.5, -10)
    enabledBadge.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
    enabledBadge.BackgroundTransparency = 0.75
    enabledBadge.Text = "● ENABLED"
    enabledBadge.Font = Enum.Font.GothamBold
    enabledBadge.TextSize = 9
    enabledBadge.TextColor3 = Color3.fromRGB(52, 211, 153)
    Instance.new("UICorner", enabledBadge).CornerRadius = UDim.new(1, 0)
    local badgeStroke = Instance.new("UIStroke", enabledBadge)
    badgeStroke.Color = Color3.fromRGB(16, 185, 129)
    badgeStroke.Thickness = 1
    badgeStroke.Transparency = 0.4

    -- Badge pulse animation
    task.spawn(function()
        while enabledBadge.Parent do
            TweenService:Create(badgeStroke, TweenInfo.new(1, Enum.EasingStyle.Sine), {Transparency = 0}):Play()
            task.wait(1)
            TweenService:Create(badgeStroke, TweenInfo.new(1, Enum.EasingStyle.Sine), {Transparency = 0.6}):Play()
            task.wait(1)
        end
    end)

    if IS_MOBILE then
        local menuToggleBtn = Instance.new("TextButton", header)
        menuToggleBtn.Size = UDim2.new(0, 60, 0, 28)
        menuToggleBtn.Position = UDim2.new(1, -65, 0.5, -14)
        menuToggleBtn.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
        menuToggleBtn.BackgroundTransparency = 0.4
        menuToggleBtn.Text = "MENU"
        menuToggleBtn.Font = Enum.Font.GothamBold
        menuToggleBtn.TextSize = 10
        menuToggleBtn.TextColor3 = Color3.new(1,1,1)
        Instance.new("UICorner", menuToggleBtn).CornerRadius = UDim.new(0, 6)
        menuToggleBtn.MouseButton1Click:Connect(function()
            if settingsGui then settingsGui.Enabled = not settingsGui.Enabled end
        end)
    end

    -- ── TARGET CARD ─────────────────────────────────────────────────────
    local targetCard = Instance.new("Frame", frame)
    targetCard.Size = UDim2.new(1, -24, 0, 70)
    targetCard.Position = UDim2.new(0, 12, 0, 52)
    targetCard.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
    targetCard.BackgroundTransparency = 0.88
    targetCard.BorderSizePixel = 0
    Instance.new("UICorner", targetCard).CornerRadius = UDim.new(0, 12)

    local cardStroke = Instance.new("UIStroke", targetCard)
    cardStroke.Thickness = 1.5
    cardStroke.Color = Color3.fromRGB(124, 58, 237)
    cardStroke.Transparency = 0.4

    -- Card glow sweep tween
    task.spawn(function()
        while cardStroke.Parent do
            TweenService:Create(cardStroke, TweenInfo.new(2, Enum.EasingStyle.Sine), {Transparency = 0.1}):Play()
            task.wait(2)
            TweenService:Create(cardStroke, TweenInfo.new(2, Enum.EasingStyle.Sine), {Transparency = 0.6}):Play()
            task.wait(2)
        end
    end)

    -- Thumbnail frame inside target card
    local thumbFrame = Instance.new("Frame", targetCard)
    thumbFrame.Size = UDim2.new(0, 50, 0, 50)
    thumbFrame.Position = UDim2.new(0, 10, 0.5, -25)
    thumbFrame.BackgroundColor3 = Color3.fromRGB(20, 10, 50)
    thumbFrame.BorderSizePixel = 0
    Instance.new("UICorner", thumbFrame).CornerRadius = UDim.new(0, 10)
    local thumbStroke = Instance.new("UIStroke", thumbFrame)
    thumbStroke.Thickness = 2
    thumbStroke.Color = Color3.fromRGB(124, 58, 237)
    thumbStroke.Transparency = 0.2

    -- Roblox thumbnail image (will be updated when pet is selected)
    local thumbImage = Instance.new("ImageLabel", thumbFrame)
    thumbImage.Name = "TargetThumb"
    thumbImage.Size = UDim2.new(1, 0, 1, 0)
    thumbImage.BackgroundTransparency = 1
    thumbImage.Image = "" -- set dynamically
    thumbImage.ScaleType = Enum.ScaleType.Crop
    Instance.new("UICorner", thumbImage).CornerRadius = UDim.new(0, 8)

    -- Fallback emoji label
    local thumbEmoji = Instance.new("TextLabel", thumbFrame)
    thumbEmoji.Name = "TargetEmoji"
    thumbEmoji.Size = UDim2.new(1, 0, 1, 0)
    thumbEmoji.BackgroundTransparency = 1
    thumbEmoji.Text = "🎯"
    thumbEmoji.TextSize = 22
    thumbEmoji.Font = Enum.Font.GothamBold
    thumbEmoji.TextXAlignment = Enum.TextXAlignment.Center

    -- Animate thumb stroke color with mutation
    task.spawn(function()
        while thumbStroke.Parent do
            TweenService:Create(thumbStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {Transparency = 0}):Play()
            task.wait(1.5)
            TweenService:Create(thumbStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {Transparency = 0.5}):Play()
            task.wait(1.5)
        end
    end)

    local targetHeader = Instance.new("TextLabel", targetCard)
    targetHeader.Size = UDim2.new(1, -75, 0, 14)
    targetHeader.Position = UDim2.new(0, 68, 0, 10)
    targetHeader.BackgroundTransparency = 1
    targetHeader.Text = "CURRENT TARGET"
    targetHeader.Font = Enum.Font.GothamBold
    targetHeader.TextSize = 9
    targetHeader.TextColor3 = Color3.fromRGB(100, 120, 180)
    targetHeader.TextXAlignment = Enum.TextXAlignment.Left

    local targetLabel = Instance.new("TextLabel", targetCard)
    targetLabel.Size = UDim2.new(1, -75, 0, 20)
    targetLabel.Position = UDim2.new(0, 68, 0, 24)
    targetLabel.BackgroundTransparency = 1
    targetLabel.Font = Enum.Font.GothamBold
    targetLabel.TextSize = 14
    targetLabel.TextColor3 = Color3.fromRGB(210, 200, 255)
    targetLabel.TextXAlignment = Enum.TextXAlignment.Left
    targetLabel.TextTruncate = Enum.TextTruncate.AtEnd
    targetLabel.Text = "Searching..."

    -- MPS label
    local mpsLabel = Instance.new("TextLabel", targetCard)
    mpsLabel.Size = UDim2.new(0, 120, 0, 16)
    mpsLabel.Position = UDim2.new(0, 68, 0, 46)
    mpsLabel.BackgroundTransparency = 1
    mpsLabel.Font = Enum.Font.GothamBlack
    mpsLabel.TextSize = 13
    mpsLabel.TextColor3 = Color3.fromRGB(52, 211, 153)
    mpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    mpsLabel.Text = ""

    -- Animate MPS label glow
    task.spawn(function()
        while mpsLabel.Parent do
            TweenService:Create(mpsLabel, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {
                TextColor3 = Color3.fromRGB(110, 231, 183)
            }):Play()
            task.wait(1.2)
            TweenService:Create(mpsLabel, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {
                TextColor3 = Color3.fromRGB(16, 185, 129)
            }):Play()
            task.wait(1.2)
        end
    end)

    -- Mutation badge label
    local mutLabel = Instance.new("TextLabel", targetCard)
    mutLabel.Size = UDim2.new(0, 80, 0, 14)
    mutLabel.Position = UDim2.new(0, 194, 0, 48)
    mutLabel.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
    mutLabel.BackgroundTransparency = 0.7
    mutLabel.Text = ""
    mutLabel.Font = Enum.Font.GothamBlack
    mutLabel.TextSize = 8
    mutLabel.TextColor3 = Color3.fromRGB(196, 181, 253)
    mutLabel.Visible = false
    Instance.new("UICorner", mutLabel).CornerRadius = UDim.new(0, 4)

    -- Progress bar
    local progressBg = Instance.new("Frame", targetCard)
    progressBg.Size = UDim2.new(1, 0, 0, 4)
    progressBg.Position = UDim2.new(0, 0, 1, -4)
    progressBg.BackgroundColor3 = Color3.fromRGB(10, 5, 25)
    progressBg.BorderSizePixel = 0
    Instance.new("UICorner", progressBg).CornerRadius = UDim.new(0, 2)

    local progressBarFill = Instance.new("Frame", progressBg)
    progressBarFill.Size = UDim2.new(0, 0, 1, 0)
    progressBarFill.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
    progressBarFill.BorderSizePixel = 0
    Instance.new("UICorner", progressBarFill).CornerRadius = UDim.new(0, 2)

    local progressGrad = Instance.new("UIGradient", progressBarFill)
    progressGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(124, 58, 237)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(219, 39, 119)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 182, 212))
    }

    -- ── MODE BUTTONS ────────────────────────────────────────────────────
    local modeBtnContainer = Instance.new("Frame", frame)
    modeBtnContainer.Size = UDim2.new(1, -24, 0, 30)
    modeBtnContainer.Position = UDim2.new(0, 12, 0, 130)
    modeBtnContainer.BackgroundTransparency = 1

    local function makeModeBtn(text, xPos, width, accentColor)
        local btn = Instance.new("TextButton", modeBtnContainer)
        btn.Size = UDim2.new(0, width, 1, 0)
        btn.Position = UDim2.new(0, xPos, 0, 0)
        btn.BackgroundColor3 = Color3.fromRGB(12, 8, 30)
        btn.BackgroundTransparency = 0
        btn.Text = text
        btn.Font = Enum.Font.GothamBlack
        btn.TextSize = 10
        btn.TextColor3 = Color3.fromRGB(80, 70, 120)
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
        local s = Instance.new("UIStroke", btn)
        s.Thickness = 1
        s.Color = Color3.fromRGB(30, 20, 60)
        s.Transparency = 0.3
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(20, 12, 50)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            if not btn:GetAttribute("active") then
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(12, 8, 30)}):Play()
            end
        end)
        return btn, s
    end

    local btnsWidth = frame.AbsoluteSize.X > 0 and frame.AbsoluteSize.X - 24 or 286
    local bw = math.floor((btnsWidth - 10) / 3)
    local nearestBtn, nearestStroke = makeModeBtn("NEAREST", 0, bw, Color3.fromRGB(6,182,212))
    local highestBtn, highestStroke = makeModeBtn("HIGHEST", bw + 5, bw, Color3.fromRGB(16,185,129))
    local priorityBtn, priorityStroke = makeModeBtn("PRIORITY", (bw + 5) * 2, bw, Color3.fromRGB(219,39,119))

    local function setModeActive(btn, stroke, color)
        btn:SetAttribute("active", true)
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(
                math.floor(color.R * 255 * 0.2),
                math.floor(color.G * 255 * 0.2),
                math.floor(color.B * 255 * 0.2)
            )
        }):Play()
        stroke.Color = color
        stroke.Transparency = 0
        btn.TextColor3 = color
    end

    local function setModeInactive(btn, stroke)
        btn:SetAttribute("active", false)
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(12, 8, 30)}):Play()
        stroke.Color = Color3.fromRGB(30, 20, 60)
        stroke.Transparency = 0.3
        btn.TextColor3 = Color3.fromRGB(80, 70, 120)
    end

    -- ── LIST HEADER ──────────────────────────────────────────────────────
    local listHeaderFrame = Instance.new("Frame", frame)
    listHeaderFrame.Size = UDim2.new(1, -24, 0, 22)
    listHeaderFrame.Position = UDim2.new(0, 12, 0, 168)
    listHeaderFrame.BackgroundTransparency = 1

    local selectLabel = Instance.new("TextLabel", listHeaderFrame)
    selectLabel.Size = UDim2.new(0.7, 0, 1, 0)
    selectLabel.BackgroundTransparency = 1
    selectLabel.Text = "BRAINROTS IN SERVER"
    selectLabel.Font = Enum.Font.GothamBold
    selectLabel.TextSize = 9
    selectLabel.TextColor3 = Color3.fromRGB(80, 90, 130)
    selectLabel.TextXAlignment = Enum.TextXAlignment.Left

    local countBadge = Instance.new("TextLabel", listHeaderFrame)
    countBadge.Size = UDim2.new(0, 40, 0, 18)
    countBadge.Position = UDim2.new(1, -40, 0.5, -9)
    countBadge.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
    countBadge.BackgroundTransparency = 0.75
    countBadge.Text = "0"
    countBadge.Font = Enum.Font.GothamBold
    countBadge.TextSize = 9
    countBadge.TextColor3 = Color3.fromRGB(196, 181, 253)
    Instance.new("UICorner", countBadge).CornerRadius = UDim.new(1, 0)

    -- ── SCROLL LIST ──────────────────────────────────────────────────────
    local listFrame = Instance.new("ScrollingFrame", frame)
    listFrame.Size = UDim2.new(1, -24, 1, -290)
    listFrame.Position = UDim2.new(0, 12, 0, 194)
    listFrame.BackgroundTransparency = 1
    listFrame.BorderSizePixel = 0
    listFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    listFrame.ScrollBarImageColor3 = Color3.fromRGB(124, 58, 237)
    listFrame.ScrollBarThickness = 3

    local uiListLayout = Instance.new("UIListLayout", listFrame)
    uiListLayout.Padding = UDim.new(0, 5)
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- ── MUTATION COLORS ───────────────────────────────────────────────────
    local MUT_COLORS_UI = {
        Cursed   = Color3.fromRGB(239, 68, 68),
        Gold     = Color3.fromRGB(251, 191, 36),
        Diamond  = Color3.fromRGB(103, 232, 249),
        YinYang  = Color3.fromRGB(220, 220, 220),
        Rainbow  = Color3.fromRGB(244, 114, 182),
        Lava     = Color3.fromRGB(255, 100, 20),
        Candy    = Color3.fromRGB(255, 105, 180),
        Divine   = Color3.fromRGB(255, 255, 255),
        Bloodrot = Color3.fromRGB(139, 0, 0),
    }

    -- ── BOTTOM CONTROL BAR ───────────────────────────────────────────────
    local toggleBtnContainer = Instance.new("Frame", frame)
    toggleBtnContainer.Size = UDim2.new(1, -24, 0, 90)
    toggleBtnContainer.Position = UDim2.new(0, 12, 1, -96)
    toggleBtnContainer.BackgroundTransparency = 1

    -- Divider line above buttons
    local divLine = Instance.new("Frame", frame)
    divLine.Size = UDim2.new(1, -24, 0, 1)
    divLine.Position = UDim2.new(0, 12, 1, -100)
    divLine.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
    divLine.BackgroundTransparency = 0.6
    divLine.BorderSizePixel = 0
    local divGrad = Instance.new("UIGradient", divLine)
    divGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(124,58,237)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0))
    }

    -- Main enable button
    local enableBtn = Instance.new("TextButton", toggleBtnContainer)
    enableBtn.Size = UDim2.new(1, 0, 0, 36)
    enableBtn.Position = UDim2.new(0, 0, 0, 0)
    enableBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
    enableBtn.BackgroundTransparency = 0.15
    enableBtn.Text = "● ENABLED"
    enableBtn.Font = Enum.Font.GothamBlack
    enableBtn.TextSize = 13
    enableBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    enableBtn.AutoButtonColor = false
    Instance.new("UICorner", enableBtn).CornerRadius = UDim.new(0, 10)
    local enableStroke = Instance.new("UIStroke", enableBtn)
    enableStroke.Color = Color3.fromRGB(16, 185, 129)
    enableStroke.Thickness = 1.5
    enableStroke.Transparency = 0.3

    -- Enable button sweep animation
    task.spawn(function()
        while enableBtn.Parent do
            TweenService:Create(enableStroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {Transparency = 0}):Play()
            task.wait(1.2)
            TweenService:Create(enableStroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {Transparency = 0.6}):Play()
            task.wait(1.2)
        end
    end)

    -- Bottom small buttons row
    local bottomRow = Instance.new("Frame", toggleBtnContainer)
    bottomRow.Size = UDim2.new(1, 0, 0, 26)
    bottomRow.Position = UDim2.new(0, 0, 0, 42)
    bottomRow.BackgroundTransparency = 1

    local customizePriorityBtn = Instance.new("TextButton", bottomRow)
    customizePriorityBtn.Size = UDim2.new(0.48, 0, 1, 0)
    customizePriorityBtn.BackgroundColor3 = Color3.fromRGB(20, 10, 50)
    customizePriorityBtn.Text = "CUSTOMIZE"
    customizePriorityBtn.Font = Enum.Font.GothamBold
    customizePriorityBtn.TextSize = 9
    customizePriorityBtn.TextColor3 = Color3.fromRGB(196, 181, 253)
    customizePriorityBtn.AutoButtonColor = false
    customizePriorityBtn.Visible = not IS_MOBILE
    Instance.new("UICorner", customizePriorityBtn).CornerRadius = UDim.new(0, 7)
    local cpStroke = Instance.new("UIStroke", customizePriorityBtn)
    cpStroke.Color = Color3.fromRGB(124, 58, 237)
    cpStroke.Thickness = 1
    cpStroke.Transparency = 0.4
    customizePriorityBtn.MouseButton1Click:Connect(function()
        local priorityGui = PlayerGui:FindFirstChild("PriorityListGUI")
        if priorityGui then priorityGui.Enabled = not priorityGui.Enabled end
    end)

    local instantStealBtn = Instance.new("TextButton", bottomRow)
    instantStealBtn.Size = UDim2.new(IS_MOBILE and 1 or 0.48, 0, 1, 0)
    instantStealBtn.Position = UDim2.new(IS_MOBILE and 0 or 0.52, 0, 0, 0)
    instantStealBtn.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
    instantStealBtn.AutoButtonColor = false
    instantStealBtn.Font = Enum.Font.GothamBold
    instantStealBtn.TextSize = 9
    Instance.new("UICorner", instantStealBtn).CornerRadius = UDim.new(0, 7)
    local isStroke = Instance.new("UIStroke", instantStealBtn)
    isStroke.Thickness = 1
    isStroke.Transparency = 0.3

    -- Row 2 of bottom: nearest/highest/priority in bottom row
    local modeRow2 = Instance.new("Frame", toggleBtnContainer)
    modeRow2.Size = UDim2.new(1, 0, 0, 0) -- hidden, modes are in top row
    modeRow2.BackgroundTransparency = 1


-- ─────────────────────────────────────────────────────────────────────
-- PART 2 — STEAL HELPER: KICK + REJOIN BUTTONS
-- ─────────────────────────────────────────────────────────────────────
--[[
  Inside the steal-helper task.spawn, find the bottomRow frame
  (the one that holds customizePriorityBtn and instantStealBtn).
  AFTER that block, add the following code.
  It creates a 3rd row in toggleBtnContainer for Kick and Rejoin.
]]
 
-- Add this right after instantStealBtn is defined, still inside toggleBtnContainer:
 
local kickRejoinRow = Instance.new("Frame", toggleBtnContainer)
kickRejoinRow.Size = UDim2.new(1, 0, 0, 26)
kickRejoinRow.Position = UDim2.new(0, 0, 0, 68)   -- below the two existing rows
kickRejoinRow.BackgroundTransparency = 1
 
-- KICK button
local kickBtn = Instance.new("TextButton", kickRejoinRow)
kickBtn.Size = UDim2.new(0.48, 0, 1, 0)
kickBtn.BackgroundColor3 = Color3.fromRGB(40, 10, 20)
kickBtn.AutoButtonColor = false
kickBtn.Text = "🥾 KICK"
kickBtn.Font = Enum.Font.GothamBold
kickBtn.TextSize = 9
kickBtn.TextColor3 = Color3.fromRGB(239, 68, 68)
Instance.new("UICorner", kickBtn).CornerRadius = UDim.new(0, 7)
local kickStroke = Instance.new("UIStroke", kickBtn)
kickStroke.Thickness = 1
kickStroke.Color = Color3.fromRGB(239, 68, 68)
kickStroke.Transparency = 0.4
 
kickBtn.MouseEnter:Connect(function()
    TweenService:Create(kickBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(80, 15, 30)}):Play()
    TweenService:Create(kickStroke, TweenInfo.new(0.15), {Transparency = 0.1}):Play()
end)
kickBtn.MouseLeave:Connect(function()
    TweenService:Create(kickBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 10, 20)}):Play()
    TweenService:Create(kickStroke, TweenInfo.new(0.15), {Transparency = 0.4}):Play()
end)
kickBtn.MouseButton1Click:Connect(function()
    kickPlayer()
    ShowNotification("KICK", "Kicking yourself...")
end)
 
-- REJOIN button
local rejoinBtn = Instance.new("TextButton", kickRejoinRow)
rejoinBtn.Size = UDim2.new(0.48, 0, 1, 0)
rejoinBtn.Position = UDim2.new(0.52, 0, 0, 0)
rejoinBtn.BackgroundColor3 = Color3.fromRGB(10, 25, 40)
rejoinBtn.AutoButtonColor = false
rejoinBtn.Text = "🔄 REJOIN"
rejoinBtn.Font = Enum.Font.GothamBold
rejoinBtn.TextSize = 9
rejoinBtn.TextColor3 = Color3.fromRGB(6, 182, 212)
Instance.new("UICorner", rejoinBtn).CornerRadius = UDim.new(0, 7)
local rejoinStroke = Instance.new("UIStroke", rejoinBtn)
rejoinStroke.Thickness = 1
rejoinStroke.Color = Color3.fromRGB(6, 182, 212)
rejoinStroke.Transparency = 0.4
 
rejoinBtn.MouseEnter:Connect(function()
    TweenService:Create(rejoinBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(10, 45, 65)}):Play()
    TweenService:Create(rejoinStroke, TweenInfo.new(0.15), {Transparency = 0.1}):Play()
end)
rejoinBtn.MouseLeave:Connect(function()
    TweenService:Create(rejoinBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(10, 25, 40)}):Play()
    TweenService:Create(rejoinStroke, TweenInfo.new(0.15), {Transparency = 0.4}):Play()
end)
rejoinBtn.MouseButton1Click:Connect(function()
    ShowNotification("REJOIN", "Rejoining server...")
    task.spawn(function()
        task.wait(0.3)
        local TeleportService_local = game:GetService("TeleportService")
        local success, err = pcall(function()
            TeleportService_local:TeleportToPlaceInstance(
                game.PlaceId,
                game.JobId,
                LocalPlayer
            )
        end)
        if not success then
            -- fallback: teleport to same place (new server)
            pcall(function()
                TeleportService_local:Teleport(game.PlaceId, LocalPlayer)
            end)
        end
    end)
end)
 
-- Expand toggleBtnContainer height to accommodate the new row
toggleBtnContainer.Size = UDim2.new(1, -24, 0, 100)
 
-- Also push the outer frame up slightly so the new row fits
-- (the frame was 640 tall; kick/rejoin row adds ~32px)
-- This line adjusts the steal helper frame height:
frame.Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, 670 * (IS_MOBILE and 0.6 or 1))

    -- ── UPDATE UI FUNCTION ────────────────────────────────────────────────
    local petButtons = {}

    local function updateUI(enabled, allPets)
        autoStealEnabled = enabled

        -- Update enable button
        if enabled then
            enableBtn.Text = "● ENABLED"
            enableBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
            enableBtn.BackgroundTransparency = 0.15
            enableStroke.Color = Color3.fromRGB(16, 185, 129)
            enabledBadge.Text = "● ENABLED"
            enabledBadge.TextColor3 = Color3.fromRGB(52, 211, 153)
        else
            enableBtn.Text = "○ DISABLED"
            enableBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 60)
            enableBtn.BackgroundTransparency = 0
            enableStroke.Color = Color3.fromRGB(60, 40, 100)
            enabledBadge.Text = "○ PAUSED"
            enabledBadge.TextColor3 = Color3.fromRGB(100, 90, 140)
        end

        -- Update mode buttons
        if stealNearestEnabled then
            setModeActive(nearestBtn, nearestStroke, Color3.fromRGB(6,182,212))
            setModeInactive(highestBtn, highestStroke)
            setModeInactive(priorityBtn, priorityStroke)
        elseif stealHighestEnabled then
            setModeInactive(nearestBtn, nearestStroke)
            setModeActive(highestBtn, highestStroke, Color3.fromRGB(16,185,129))
            setModeInactive(priorityBtn, priorityStroke)
        elseif stealPriorityEnabled then
            setModeInactive(nearestBtn, nearestStroke)
            setModeInactive(highestBtn, highestStroke)
            setModeActive(priorityBtn, priorityStroke, Color3.fromRGB(219,39,119))
        else
            setModeInactive(nearestBtn, nearestStroke)
            setModeInactive(highestBtn, highestStroke)
            setModeInactive(priorityBtn, priorityStroke)
        end

        -- Instant steal button
        instantStealBtn.Text = instantStealEnabled and "⚡ INSTANT: ON" or "⚡ INSTANT: OFF"
        if instantStealEnabled then
            instantStealBtn.BackgroundColor3 = Color3.fromRGB(40, 25, 5)
            isStroke.Color = Color3.fromRGB(245, 158, 11)
            instantStealBtn.TextColor3 = Color3.fromRGB(251, 191, 36)
        else
            instantStealBtn.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
            isStroke.Color = Color3.fromRGB(80, 60, 100)
            instantStealBtn.TextColor3 = Color3.fromRGB(100, 80, 140)
        end

        -- Sync selected index by UID
        if selectedTargetUID and allPets then
            for i, p in ipairs(allPets) do
                if p.uid == selectedTargetUID then
                    selectedTargetIndex = i
                    break
                end
            end
        end

        -- Rebuild list if needed
        if SharedState.ListNeedsRedraw then
            for _, c in ipairs(listFrame:GetChildren()) do
                if c:IsA("Frame") then c:Destroy() end
            end
            petButtons = {}

            if allPets and #allPets > 0 then
                countBadge.Text = tostring(#allPets)
                for i = 1, #allPets do
                    local petData = allPets[i]
                    local hasMut = petData.mutation and petData.mutation ~= "None"
                    local mutColor = hasMut and (MUT_COLORS_UI[petData.mutation] or Color3.fromRGB(210,130,255)) or Color3.fromRGB(124,58,237)

                    -- Row frame
                    local row = Instance.new("Frame", listFrame)
                    row.Size = UDim2.new(1, 0, 0, 48)
                    row.BackgroundColor3 = Color3.fromRGB(8, 5, 22)
                    row.BackgroundTransparency = 0
                    row.BorderSizePixel = 0
                    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
                    local rStroke = Instance.new("UIStroke", row)
                    rStroke.Thickness = 1
                    rStroke.Color = Color3.fromRGB(25, 15, 55)
                    rStroke.Transparency = 0.3
                    -- Left accent bar
                    local accentBar = Instance.new("Frame", row)
                    accentBar.Size = UDim2.new(0, 3, 1, -10)
                    accentBar.Position = UDim2.new(0, 3, 0, 5)
                    accentBar.BackgroundColor3 = mutColor
                    accentBar.BorderSizePixel = 0
                    Instance.new("UICorner", accentBar).CornerRadius = UDim.new(1, 0)

                    -- Thumbnail
                    local thumb = Instance.new("Frame", row)
                    thumb.Size = UDim2.new(0, 38, 0, 38)
                    thumb.Position = UDim2.new(0, 10, 0.5, -19)
                    thumb.BackgroundColor3 = Color3.fromRGB(15, 8, 40)
                    thumb.BorderSizePixel = 0
                    Instance.new("UICorner", thumb).CornerRadius = UDim.new(0, 8)
                    local tStroke = Instance.new("UIStroke", thumb)
                    tStroke.Thickness = 1.5
                    tStroke.Color = mutColor
                    tStroke.Transparency = 0.5

                    local thumbImg = Instance.new("ImageLabel", thumb)
                    thumbImg.Size = UDim2.new(1, 0, 1, 0)
                    thumbImg.BackgroundTransparency = 1
                    thumbImg.Image = ""
                    thumbImg.ScaleType = Enum.ScaleType.Crop
                    Instance.new("UICorner", thumbImg).CornerRadius = UDim.new(0, 6)

                    -- Try to get brainrot image from Workspace (adornee)
                    task.spawn(function()
                        local adornee = findAdorneeGlobal(petData.animalData)
                        if adornee then
                            local model = adornee:FindFirstAncestorOfClass("Model")
                            if model then
                                local img = model:FindFirstChildOfClass("ImageLabel", true)
                                    or model:FindFirstChildWhichIsA("Decal", true)
                                if img then
                                    local imgId = img:IsA("ImageLabel") and img.Image or img.Texture
                                    if imgId and imgId ~= "" then
                                        thumbImg.Image = imgId
                                    end
                                end
                            end
                        end
                    end)

                    -- Rank label
                    local rankLbl = Instance.new("TextLabel", thumb)
                    rankLbl.Size = UDim2.new(0, 16, 0, 14)
                    rankLbl.Position = UDim2.new(0, -1, 0, -1)
                    rankLbl.BackgroundColor3 = Color3.fromRGB(4, 2, 15)
                    rankLbl.BackgroundTransparency = 0.2
                    rankLbl.Text = "#"..i
                    rankLbl.Font = Enum.Font.GothamBlack
                    rankLbl.TextSize = 8
                    rankLbl.TextColor3 = Color3.fromRGB(100, 90, 150)
                    Instance.new("UICorner", rankLbl).CornerRadius = UDim.new(0, 4)

                    -- Pet name
                    local nameLabel = Instance.new("TextLabel", row)
                    nameLabel.Size = UDim2.new(1, -100, 0, 18)
                    nameLabel.Position = UDim2.new(0, 54, 0, 8)
                    nameLabel.BackgroundTransparency = 1
                    nameLabel.Font = Enum.Font.GothamBold
                    nameLabel.TextSize = 12
                    nameLabel.TextColor3 = Color3.fromRGB(200, 195, 230)
                    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                    nameLabel.Text = (hasMut and (petData.mutation .. " ") or "") .. petData.petName

                    -- MPS
                    local mpsLbl = Instance.new("TextLabel", row)
                    mpsLbl.Size = UDim2.new(0, 80, 0, 14)
                    mpsLbl.Position = UDim2.new(0, 54, 0, 27)
                    mpsLbl.BackgroundTransparency = 1
                    mpsLbl.Font = Enum.Font.GothamBlack
                    mpsLbl.TextSize = 11
                    mpsLbl.TextColor3 = Color3.fromRGB(52, 211, 153)
                    mpsLbl.TextXAlignment = Enum.TextXAlignment.Left
                    mpsLbl.Text = petData.mpsText

                    -- Owner
                    local ownerLbl = Instance.new("TextLabel", row)
                    ownerLbl.Size = UDim2.new(1, -140, 0, 12)
                    ownerLbl.Position = UDim2.new(0, 136, 0, 30)
                    ownerLbl.BackgroundTransparency = 1
                    ownerLbl.Font = Enum.Font.GothamMedium
                    ownerLbl.TextSize = 9
                    ownerLbl.TextColor3 = Color3.fromRGB(60, 70, 100)
                    ownerLbl.TextXAlignment = Enum.TextXAlignment.Left
                    ownerLbl.TextTruncate = Enum.TextTruncate.AtEnd
                    ownerLbl.Text = petData.owner or ""

                    -- Clickable overlay
                    local clickBtn = Instance.new("TextButton", row)
                    clickBtn.Size = UDim2.new(1, 0, 1, 0)
                    clickBtn.BackgroundTransparency = 1
                    clickBtn.Text = ""
                    clickBtn.ZIndex = 5

                    -- Hover effects
                    clickBtn.MouseEnter:Connect(function()
                        TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(14, 8, 38)}):Play()
                        TweenService:Create(rStroke, TweenInfo.new(0.15), {Color = mutColor, Transparency = 0.2}):Play()
                    end)
                    clickBtn.MouseLeave:Connect(function()
                        if selectedTargetIndex ~= i then
                            TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(8, 5, 22)}):Play()
                            TweenService:Create(rStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(25,15,55), Transparency = 0.3}):Play()
                        end
                    end)

                    clickBtn.MouseButton1Click:Connect(function()
                        selectedTargetIndex = i
                        selectedTargetUID = petData.uid
                        stealNearestEnabled = false
                        stealHighestEnabled = false
                        stealPriorityEnabled = false
                        Config.StealNearest = false
                        Config.StealHighest = false
                        Config.StealPriority = false
                        SaveConfig()
                        SharedState.ListNeedsRedraw = false
                        updateUI(autoStealEnabled, get_all_pets())
                    end)

                    petButtons[i] = {
                        row = row, rStroke = rStroke, rankLbl = rankLbl,
                        nameLabel = nameLabel, mpsLbl = mpsLbl, tStroke = tStroke,
                        mutColor = mutColor
                    }
                end
            else
                countBadge.Text = "0"
            end
            SharedState.ListNeedsRedraw = false
        end

        -- Clamp selection
        if selectedTargetIndex > #petButtons then selectedTargetIndex = 1 end

        -- Highlight selected
        for i, pb in ipairs(petButtons) do
            local sel = (i == selectedTargetIndex)
            if sel then
                TweenService:Create(pb.row, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(
                        math.floor(pb.mutColor.R * 255 * 0.12),
                        math.floor(pb.mutColor.G * 255 * 0.12),
                        math.floor(pb.mutColor.B * 255 * 0.12)
                    )
                }):Play()
                TweenService:Create(pb.rStroke, TweenInfo.new(0.2), {Color = pb.mutColor, Transparency = 0.2}):Play()
                pb.rankLbl.TextColor3 = pb.mutColor
                pb.nameLabel.TextColor3 = Color3.fromRGB(220, 215, 255)
            else
                TweenService:Create(pb.row, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(8, 5, 22)}):Play()
                TweenService:Create(pb.rStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(25,15,55), Transparency = 0.3}):Play()
                pb.rankLbl.TextColor3 = Color3.fromRGB(80, 70, 120)
                pb.nameLabel.TextColor3 = Color3.fromRGB(160, 155, 200)
            end
        end

        -- Update target card
        local ct = allPets and allPets[selectedTargetIndex]
        SharedState.SelectedPetData = ct

        if enabled and ct then
            targetLabel.Text = ct.petName
            mpsLabel.Text = ct.mpsText

            local imgId = ct.animalData and ct.animalData._cachedImageId
    if imgId then
        thumbImage.Image = imgId
        thumbEmoji.Visible = false
    else
        task.spawn(function()
            local adornee = findAdorneeGlobal(ct.animalData)
            if adornee then
                local model = adornee.Parent
                if model then
                    local img = model:FindFirstChildOfClass("ImageLabel", true) or model:FindFirstChildWhichIsA("Decal", true)
                    if img then
                        local id = img:IsA("ImageLabel") and img.Image or img.Texture
                        if id and id ~= "" then
                            thumbImage.Image = id
                            thumbEmoji.Visible = false
                            if ct.animalData then ct.animalData._cachedImageId = id end
                        end
                    end
                end
            end
        end)
    end

            local hasMut = ct.mutation and ct.mutation ~= "None"
            local mutColor = hasMut and (MUT_COLORS_UI[ct.mutation] or Color3.fromRGB(210,130,255)) or Color3.fromRGB(124,58,237)
            thumbStroke.Color = mutColor
            cardStroke.Color = mutColor

            if hasMut then
                mutLabel.Visible = true
                mutLabel.Text = ct.mutation:upper()
                mutLabel.TextColor3 = mutColor
                mutLabel.BackgroundColor3 = Color3.fromRGB(
                    math.floor(mutColor.R * 255 * 0.15),
                    math.floor(mutColor.G * 255 * 0.15),
                    math.floor(mutColor.B * 255 * 0.15)
                )
            else
                mutLabel.Visible = false
            end
        elseif enabled then
            targetLabel.Text = "Searching..."
            mpsLabel.Text = ""
            mutLabel.Visible = false
        else
            targetLabel.Text = "Disabled"
            thumbImage.Image = ""
            thumbEmoji.Visible = true  
            mpsLabel.Text = ""
            mutLabel.Visible = false
        end

        listFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(0, uiListLayout.AbsoluteContentSize.Y))
    end

    uiListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(0, uiListLayout.AbsoluteContentSize.Y))
    end)

    SharedState.UpdateAutoStealUI = function()
        updateUI(autoStealEnabled, get_all_pets())
    end

    -- Button connections
    enableBtn.MouseButton1Click:Connect(function()
        autoStealEnabled = not autoStealEnabled
        SharedState.ListNeedsRedraw = false
        updateUI(autoStealEnabled, get_all_pets())
    end)

    nearestBtn.MouseButton1Click:Connect(function()
        stealNearestEnabled = not stealNearestEnabled
        if stealNearestEnabled then stealHighestEnabled = false; stealPriorityEnabled = false end
        Config.StealNearest = stealNearestEnabled
        Config.StealHighest = stealHighestEnabled
        Config.StealPriority = stealPriorityEnabled
        SaveConfig()
        SharedState.ListNeedsRedraw = false
        updateUI(autoStealEnabled, get_all_pets())
    end)

    highestBtn.MouseButton1Click:Connect(function()
        stealHighestEnabled = not stealHighestEnabled
        if stealHighestEnabled then stealNearestEnabled = false; stealPriorityEnabled = false end
        Config.StealNearest = stealNearestEnabled
        Config.StealHighest = stealHighestEnabled
        Config.StealPriority = stealPriorityEnabled
        SaveConfig()
        SharedState.ListNeedsRedraw = false
        updateUI(autoStealEnabled, get_all_pets())
    end)

    priorityBtn.MouseButton1Click:Connect(function()
        stealPriorityEnabled = not stealPriorityEnabled
        if stealPriorityEnabled then stealNearestEnabled = false; stealHighestEnabled = false end
        Config.StealNearest = stealNearestEnabled
        Config.StealHighest = stealHighestEnabled
        Config.StealPriority = stealPriorityEnabled
        SaveConfig()
        SharedState.ListNeedsRedraw = false
        updateUI(autoStealEnabled, get_all_pets())
    end)

    instantStealBtn.MouseButton1Click:Connect(function()
        instantStealEnabled = not instantStealEnabled
        if not instantStealEnabled then
            instantStealReady = false
            instantStealDidInit = false
        end
        Config.InstantSteal = instantStealEnabled
        SaveConfig()
        SharedState.ListNeedsRedraw = false
        updateUI(autoStealEnabled, get_all_pets())
    end)

    -- Initial mode state
    if stealNearestEnabled then setModeActive(nearestBtn, nearestStroke, Color3.fromRGB(6,182,212))
    elseif stealHighestEnabled then setModeActive(highestBtn, highestStroke, Color3.fromRGB(16,185,129))
    elseif stealPriorityEnabled then setModeActive(priorityBtn, priorityStroke, Color3.fromRGB(219,39,119)) end
    
   local function findProximityPromptForAnimal(animalData)
        if not animalData then return nil end
        local cp = PromptMemoryCache[animalData.uid]
        if cp and cp.Parent then return cp end
        local plot = Workspace.Plots:FindFirstChild(animalData.plot); if not plot then return nil end
        local podiums = plot:FindFirstChild("AnimalPodiums"); if not podiums then return nil end
        local ch = Synchronizer:Get(plot.Name)
        if not ch then
            local podium = podiums:FindFirstChild(animalData.slot)
            if podium then
                local base = podium:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                if spawn then
                    local attach = spawn:FindFirstChild("PromptAttachment")
                    if attach then
                        for _, p in ipairs(attach:GetChildren()) do
                            if p:IsA("ProximityPrompt") then
                                PromptMemoryCache[animalData.uid] = p
                                return p
                            end
                        end
                    end
                end
            end
            return nil
        end
        local al = ch:Get("AnimalList")
        if not al then return nil end
        local brainrotName = animalData.name and animalData.name:lower() or ""
        local targetSlot = animalData.slot
        local foundPodium = nil
        for slot, ad in pairs(al) do
            if type(ad) == "table" and tostring(slot) == targetSlot then
                local aName, aInfo = ad.Index, AnimalsData[ad.Index]
                if aInfo and (aInfo.DisplayName or aName):lower() == brainrotName then
                    foundPodium = podiums:FindFirstChild(tostring(slot))
                    break
                end
            end
        end
        if not foundPodium then
            foundPodium = podiums:FindFirstChild(animalData.slot)
        end
        if foundPodium then
            local base = foundPodium:FindFirstChild("Base")
            local spawn = base and base:FindFirstChild("Spawn")
            if spawn then
                local attach = spawn:FindFirstChild("PromptAttachment")
                if attach then
                    for _, p in ipairs(attach:GetChildren()) do
                        if p:IsA("ProximityPrompt") and p.Enabled and p.ActionText == "Steal" then
                            PromptMemoryCache[animalData.uid] = p
                            return p
                        end
                    end
                end
                local startPos = spawn.Position
                local slotX, slotZ = startPos.X, startPos.Z
                local nearestPrompt = nil
                local minDist = math.huge
                for _, desc in pairs(plot:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") and desc.Enabled and desc.ActionText == "Steal" then
                        local part = desc.Parent
                        local promptPos = nil
                        if part and part:IsA("BasePart") then
                            promptPos = part.Position
                        elseif part and part:IsA("Attachment") and part.Parent and part.Parent:IsA("BasePart") then
                            promptPos = part.Parent.Position
                        end
                        if promptPos then
                            local horizontalDist = math.sqrt((promptPos.X - slotX)^2 + (promptPos.Z - slotZ)^2)
                            if horizontalDist < 5 and promptPos.Y > startPos.Y then
                                local yDist = promptPos.Y - startPos.Y
                                if yDist < minDist then
                                    minDist = yDist
                                    nearestPrompt = desc
                                end
                            end
                        end
                    end
                end
                if nearestPrompt then
                    PromptMemoryCache[animalData.uid] = nearestPrompt
                    return nearestPrompt
                end
            end
        end
        return nil
    end

    local STEAL_DURATION = 0.6

    local function buildStealCallbacks(prompt)
        if InternalStealCache[prompt] then return end
        local data = {holdCallbacks = {}, triggerCallbacks = {}, holdEndCallbacks = {}, ready = true}
        local ok1, conns1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
        if ok1 and type(conns1) == "table" then
            for _, conn in ipairs(conns1) do
                if type(conn.Function) == "function" then
                    table.insert(data.holdCallbacks, conn.Function)
                end
            end
        end
        local ok2, conns2 = pcall(getconnections, prompt.Triggered)
        if ok2 and type(conns2) == "table" then
            for _, conn in ipairs(conns2) do
                if type(conn.Function) == "function" then
                    table.insert(data.triggerCallbacks, conn.Function)
                end
            end
        end
        local ok3, conns3 = pcall(getconnections, prompt.PromptButtonHoldEnded)
        if ok3 and type(conns3) == "table" then
            for _, conn in ipairs(conns3) do
                if type(conn.Function) == "function" then
                    table.insert(data.holdEndCallbacks, conn.Function)
                end
            end
        end
        if (#data.holdCallbacks > 0) or (#data.triggerCallbacks > 0) or (#data.holdEndCallbacks > 0) then
            InternalStealCache[prompt] = data
        end
    end

    local function runCallbackList(list)
        for _, fn in ipairs(list) do
            task.spawn(fn)
        end
    end

    local INSTANT_STEAL_RADIUS = 60
    local INSTANT_STEAL_COOLDOWN = 0.04
    local lastInstantStealTime = 0

    local function isMyPlot_Instant(plotName)
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return false end
        local plot = plots:FindFirstChild(plotName)
        if not plot then return false end
        local sign = plot:FindFirstChild("PlotSign")
        if not sign then return false end
        local yb = sign:FindFirstChild("YourBase")
        return yb and yb:IsA("BillboardGui") and yb.Enabled
    end

    local function findNearestPrompt_Instant()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil, math.huge, nil end
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return nil, math.huge, nil end
        local bestPrompt, bestDist, bestName = nil, math.huge, nil
        for _, plot in ipairs(plots:GetChildren()) do
            if isMyPlot_Instant(plot.Name) then continue end
            local plotDist = math.huge
            pcall(function() plotDist = (plot:GetPivot().Position - hrp.Position).Magnitude end)
            if plotDist > INSTANT_STEAL_RADIUS + 40 then continue end
            local podiums = plot:FindFirstChild("AnimalPodiums")
            if not podiums then continue end
            for _, pod in ipairs(podiums:GetChildren()) do
                local base = pod:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                if not spawn then continue end
                local dist = (spawn.Position - hrp.Position).Magnitude
                if dist > INSTANT_STEAL_RADIUS or dist >= bestDist then continue end
                local att = spawn:FindFirstChild("PromptAttachment")
                if not att then continue end
                local prompt = att:FindFirstChildOfClass("ProximityPrompt")
                if prompt and prompt.Parent and prompt.Enabled then
                    bestPrompt = prompt
                    bestDist = dist
                    bestName = pod.Name
                end
            end
        end
        return bestPrompt, bestDist, bestName
    end

    local function executeInstantSteal(prompt)
        if not prompt then return end
        local now = os.clock()
        if now - lastInstantStealTime < INSTANT_STEAL_COOLDOWN then return end
        lastInstantStealTime = now
        buildStealCallbacks(prompt)
        local data = InternalStealCache[prompt]
        if not data then return end
        local oDur = prompt.HoldDuration
        prompt.HoldDuration = 0
        for _, fn in ipairs(data.holdCallbacks) do pcall(fn) end
        for _rep = 1, 6 do
            for _, fn in ipairs(data.triggerCallbacks) do pcall(fn) end
            if fireproximityprompt then fireproximityprompt(prompt) end
        end
        for _, fn in ipairs(data.holdEndCallbacks) do pcall(fn) end
        prompt.HoldDuration = oDur
    end

    local function executeInternalStealAsync(prompt, animalUID)
        local data = InternalStealCache[prompt]
        if not data or not data.ready then return false end
        data.ready = false
        task.spawn(function()
            if currentStealTargetUID ~= animalUID then
                if activeProgressTween then activeProgressTween:Cancel() end
                progressBarFill.Size = UDim2.new(0, 0, 1, 0)
                currentStealTargetUID = animalUID
            end
            if #data.holdCallbacks > 0 then
                runCallbackList(data.holdCallbacks)
            end
            progressBarFill.Size = UDim2.new(0, 0, 1, 0)
            progressBarFill.BackgroundTransparency = 0
            activeProgressTween = TweenService:Create(progressBarFill, TweenInfo.new(STEAL_DURATION, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 1, 0)})
            activeProgressTween:Play()
            activeProgressTween.Completed:Wait()
            if currentStealTargetUID == animalUID and #data.triggerCallbacks > 0 then
                runCallbackList(data.triggerCallbacks)
            end
            data.ready = true
        end)
        return true
    end

    local function attemptSteal(prompt, animalUID)
        if not prompt or not prompt.Parent then return false end
        buildStealCallbacks(prompt)
        if not InternalStealCache[prompt] then return false end
        if currentStealTargetUID ~= animalUID then
            if activeProgressTween then activeProgressTween:Cancel(); activeProgressTween = nil end
            progressBarFill.Size = UDim2.new(0, 0, 1, 0)
        end
        return executeInternalStealAsync(prompt, animalUID)
    end

    local function prebuildStealCallbacks()
        for _, prompt in pairs(PromptMemoryCache) do
            if prompt and prompt.Parent then
                buildStealCallbacks(prompt)
            end
        end
    end

    task.spawn(function()
        while task.wait(2) do
            if autoStealEnabled then
                prebuildStealCallbacks()
            end
        end
    end)

    local lastAnimalData = {}
    local function getAnimalHash(al)
        if not al then return "" end
        local h = ""
        for slot, d in pairs(al) do
            if type(d) == "table" then h = h..tostring(slot)..tostring(d.Index)..tostring(d.Mutation) end
        end
        return h
    end

    local hasShownPriorityAlert = false

    local function ShowPriorityAlert(brainrotName, genText, mutation, ownerUsername)
        if not Config.AlertsEnabled then return end
        if hasShownPriorityAlert then return end
        local ownerPlayer = ownerUsername and Players:FindFirstChild(ownerUsername) or nil
        local isInDuel = ownerPlayer and ownerPlayer:GetAttribute("__duels_block_steal") == true or false
        local duelStatusText = isInDuel and "IN DUEL" or "NOT IN DUEL"
        local duelStatusColor = isInDuel and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
        local mutationColors = {
            ["rainbow"] = Color3.fromRGB(255, 0, 255),
            ["cursed"] = Color3.fromRGB(255, 50, 50),
            ["gold"] = Color3.fromRGB(255, 215, 0),
            ["diamond"] = Color3.fromRGB(0, 255, 255),
            ["yinyang"] = Color3.fromRGB(255, 255, 255),
            ["lava"] = Color3.fromRGB(255, 100, 20)
        }
        local normalizedMutation = mutation and mutation:gsub("%s+", ""):lower() or ""
        local color = mutationColors[normalizedMutation] or Color3.fromRGB(0, 170, 255)
        local existing = PlayerGui:FindFirstChild("XiPriorityAlert")
        if existing then existing:Destroy() end
        local alertGui = Instance.new("ScreenGui")
        alertGui.Name = "XiPriorityAlert"
        alertGui.ResetOnSpawn = false
        alertGui.DisplayOrder = 999
        alertGui.Parent = PlayerGui
        hasShownPriorityAlert = true
        local alertFrame = Instance.new("Frame")
        alertFrame.Size = UDim2.new(0, 400, 0, 60)
        alertFrame.Position = UDim2.new(0.5, 0, 0, -70)
        alertFrame.AnchorPoint = Vector2.new(0.5, 0)
        alertFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
        alertFrame.BackgroundTransparency = 0.05
        alertFrame.BorderSizePixel = 0
        alertFrame.Parent = alertGui
        Instance.new("UICorner", alertFrame).CornerRadius = UDim.new(0, 12)
        local glowStroke = Instance.new("UIStroke", alertFrame)
        glowStroke.Thickness = 3; glowStroke.Color = color; glowStroke.Transparency = 1
        local accentBar = Instance.new("Frame", alertFrame)
        accentBar.Size = UDim2.new(0, 4, 1, -12); accentBar.Position = UDim2.new(0, 8, 0, 6)
        accentBar.BackgroundColor3 = color; accentBar.BorderSizePixel = 0
        Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0, 2)
        local nameLabel = Instance.new("TextLabel", alertFrame)
        nameLabel.Size = UDim2.new(1, -30, 0.55, 0); nameLabel.Position = UDim2.new(0, 20, 0, 6)
        nameLabel.BackgroundTransparency = 1; nameLabel.Text = brainrotName .. " - " .. genText
        nameLabel.Font = Enum.Font.GothamBlack; nameLabel.TextSize = 18
        nameLabel.TextColor3 = color; nameLabel.TextXAlignment = Enum.TextXAlignment.Center
        nameLabel.TextStrokeTransparency = 0; nameLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
        local genLabel = Instance.new("TextLabel", alertFrame)
        genLabel.Size = UDim2.new(1, -30, 0.4, 0); genLabel.Position = UDim2.new(0, 20, 0.55, 0)
        genLabel.BackgroundTransparency = 1; genLabel.Text = duelStatusText
        genLabel.Font = Enum.Font.GothamBold; genLabel.TextSize = 17
        genLabel.TextColor3 = duelStatusColor; genLabel.TextXAlignment = Enum.TextXAlignment.Center
        TweenService:Create(alertFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, 0, 15)
        }):Play()
        if Config.AlertSoundID and Config.AlertSoundID ~= "" then
            local sound = Instance.new("Sound")
            sound.SoundId = Config.AlertSoundID; sound.Volume = 0.5; sound.Parent = alertFrame; sound:Play()
            TweenService:Create(glowStroke, TweenInfo.new(0.15), {Transparency = 0}):Play()
            task.delay(0.4, function()
                TweenService:Create(glowStroke, TweenInfo.new(0.8), {Transparency = 0.6}):Play()
            end)
            sound.Ended:Connect(function() sound:Destroy() end)
        end
        task.delay(4, function()
            TweenService:Create(alertFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, 0, 0, -70)
            }):Play()
            task.wait(0.35)
            alertGui:Destroy()
        end)
    end

    local function scanSinglePlot(plot)
        local changed = false
        pcall(function()
            local ch = Synchronizer:Get(plot.Name); if not ch then return end
            local al = ch:Get("AnimalList")
            local hash = getAnimalHash(al)
            if lastAnimalData[plot.Name] == hash then return end
            lastAnimalData[plot.Name] = hash; changed = true
            for i = #allAnimalsCache, 1, -1 do
                if allAnimalsCache[i].plot == plot.Name then table.remove(allAnimalsCache, i) end
            end
            local owner = ch:Get("Owner")
            if not owner or not Players:FindFirstChild(owner.Name) then return end
            local ownerName = owner.Name or "Unknown"
            if not al then return end
            for slot, ad in pairs(al) do
                if type(ad) == "table" then
                    local aName, aInfo = ad.Index, AnimalsData[ad.Index]
                    if aInfo then
                        local mut = ad.Mutation or "None"
                        if mut == "Yin Yang" then mut = "YinYang" end
                        local traits = (ad.Traits and #ad.Traits > 0) and table.concat(ad.Traits, ", ") or "None"
                        local gv = AnimalsShared:GetGeneration(aName, ad.Mutation, ad.Traits, nil)
                        local gt = "$" .. NumberUtils:ToString(gv) .. "/s"
                        table.insert(allAnimalsCache, {
                            name = aInfo.DisplayName or aName, genText = gt, genValue = gv,
                            mutation = mut, traits = traits, owner = ownerName,
                            plot = plot.Name, slot = tostring(slot), uid = plot.Name .. "_" .. tostring(slot)
                        })
                    end
                end
            end
        end)
        if changed then
            table.sort(allAnimalsCache, function(a, b) return a.genValue > b.genValue end)
            SharedState.ListNeedsRedraw = true
            if not hasShownPriorityAlert and Config.AlertsEnabled then
                task.spawn(function()
                    local foundPriorityPet = nil
                    for i = 1, #PRIORITY_LIST do
                        local searchName = PRIORITY_LIST[i]:lower()
                        for _, pet in ipairs(allAnimalsCache) do
                            if pet.name and pet.name:lower() == searchName then
                                foundPriorityPet = pet; break
                            end
                        end
                        if foundPriorityPet then break end
                    end
                    if foundPriorityPet then
                        local ownerUsername = foundPriorityPet.owner
                        ShowPriorityAlert(foundPriorityPet.name, foundPriorityPet.genText, foundPriorityPet.mutation, ownerUsername)
                    end
                end)
            end
        end
    end

    local function setupPlotListener(plot)
        local ch, retries = nil, 0
        while not ch and retries < 50 do
            local ok, r = pcall(function() return Synchronizer:Get(plot.Name) end)
            if ok and r then ch = r; break else retries = retries + 1; task.wait(0.1) end
        end
        if not ch then return end
        scanSinglePlot(plot)
        plot.DescendantAdded:Connect(function() task.wait(0.1); scanSinglePlot(plot) end)
        plot.DescendantRemoving:Connect(function() task.wait(0.1); scanSinglePlot(plot) end)
        task.spawn(function() while plot.Parent do task.wait(5); scanSinglePlot(plot) end end)
    end

    local plots = Workspace:WaitForChild("Plots", 8)
    if plots then
        for _, p in ipairs(plots:GetChildren()) do setupPlotListener(p) end
        plots.ChildAdded:Connect(function(p) task.wait(0.5); setupPlotListener(p) end)
        plots.ChildRemoved:Connect(function(p)
            lastAnimalData[p.Name] = nil
            for i = #allAnimalsCache, 1, -1 do
                if allAnimalsCache[i].plot == p.Name then table.remove(allAnimalsCache, i) end
            end
            SharedState.ListNeedsRedraw = true
        end)
    end

    local duelBaseHighlights = {}
    local duelBaseBillboards = {}
    local function clearDuelBaseVisuals()
        for _, h in pairs(duelBaseHighlights) do if h and h.Parent then h:Destroy() end end
        duelBaseHighlights = {}
        for _, b in pairs(duelBaseBillboards) do if b and b.Parent then b:Destroy() end end
        duelBaseBillboards = {}
    end
    local function createDuelBaseMarker(plot, sign)
        local plotName = plot.Name
        if duelBaseHighlights[plotName] then return end
        local highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.fromRGB(255, 0, 0); highlight.OutlineColor = Color3.fromRGB(200, 0, 0)
        highlight.FillTransparency = 0.7; highlight.OutlineTransparency = 0.3
        highlight.Adornee = plot; highlight.Parent = plot
        duelBaseHighlights[plotName] = highlight
        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0, 180, 0, 40); bb.StudsOffsetWorldSpace = Vector3.new(0, 8, 0)
        bb.AlwaysOnTop = true; bb.LightInfluence = 0; bb.ResetOnSpawn = false
        bb.Adornee = sign; bb.Parent = sign
        local frame = Instance.new("Frame", bb)
        frame.Size = UDim2.new(1, 0, 1, 0); frame.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
        frame.BackgroundTransparency = 0.3; frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
        local stroke = Instance.new("UIStroke", frame); stroke.Color = Color3.fromRGB(255, 0, 0); stroke.Thickness = 2
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1, 0, 1, 0); label.BackgroundTransparency = 1
        label.Text = "DUEL BASE"; label.Font = Enum.Font.GothamBlack; label.TextSize = 18
        label.TextColor3 = Color3.fromRGB(255, 50, 50); label.TextStrokeTransparency = 0
        duelBaseBillboards[plotName] = bb
    end
    task.spawn(function()
        while true do
            task.wait(1)
            if not Config.DuelBaseESP then
                clearDuelBaseVisuals()
            else
                local Plots = Workspace:FindFirstChild("Plots")
                if Plots then
                    for _, plot in ipairs(Plots:GetChildren()) do
                        local sign = plot:FindFirstChild("PlotSign")
                        if sign then
                            local textLabel = sign:FindFirstChild("SurfaceGui") and sign.SurfaceGui:FindFirstChild("Frame") and sign.SurfaceGui.Frame:FindFirstChild("TextLabel")
                            local baseText = textLabel and textLabel.Text or nil
                            if baseText and baseText ~= "Empty Base" then
                                local nickname = baseText:match("^(.-)'") or baseText
                                local ownerPlayer = nil
                                for _, p in ipairs(Players:GetPlayers()) do
                                    if p.DisplayName == nickname or p.Name == nickname then ownerPlayer = p; break end
                                end
                                if ownerPlayer and ownerPlayer:GetAttribute("__duels_block_steal") == true then
                                    if Config.DuelBaseESP then createDuelBaseMarker(plot, sign) end
                                else
                                    local plotName = plot.Name
                                    if duelBaseHighlights[plotName] then duelBaseHighlights[plotName]:Destroy(); duelBaseHighlights[plotName] = nil end
                                    if duelBaseBillboards[plotName] then duelBaseBillboards[plotName]:Destroy(); duelBaseBillboards[plotName] = nil end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    task.spawn(function()
        task.wait(0.5)
        while true do
            task.wait(0.5)
            if not hasShownPriorityAlert and Config.AlertsEnabled and #allAnimalsCache > 0 then
                local foundPriorityPet = nil
                for i = 1, #PRIORITY_LIST do
                    local searchName = PRIORITY_LIST[i]:lower()
                    for _, pet in ipairs(allAnimalsCache) do
                        if pet.name and pet.name:lower() == searchName then foundPriorityPet = pet; break end
                    end
                    if foundPriorityPet then break end
                end
                if foundPriorityPet then
                    ShowPriorityAlert(foundPriorityPet.name, foundPriorityPet.genText, foundPriorityPet.mutation, foundPriorityPet.owner)
                end
            end
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.5)
            if autoStealEnabled then
                local pets = get_all_pets()
                if #pets > 0 then
                    local function applySelection(newIndex)
                        if newIndex and newIndex >= 1 and newIndex <= #pets and selectedTargetIndex ~= newIndex then
                            selectedTargetIndex = newIndex
                            selectedTargetUID = pets[newIndex].uid
                            SharedState.ListNeedsRedraw = false
                            updateUI(autoStealEnabled, pets)
                        end
                    end
                    if stealPriorityEnabled then
                        local foundPrioIndex = nil
                        for _, pName in ipairs(PRIORITY_LIST) do
                            local searchName = pName:lower()
                            for i, p in ipairs(pets) do
                                if p.petName and p.petName:lower() == searchName then foundPrioIndex = i; break end
                            end
                            if foundPrioIndex then break end
                        end
                        applySelection(foundPrioIndex or 1)
                    elseif stealNearestEnabled then
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local bestIndex, bestDist = nil, math.huge
                            for i, p in ipairs(pets) do
                                local targetPart = p.animalData and findAdorneeGlobal(p.animalData)
                                if targetPart and targetPart:IsA("BasePart") then
                                    local d = (hrp.Position - targetPart.Position).Magnitude
                                    if d < bestDist then bestDist = d; bestIndex = i end
                                end
                            end
                            applySelection(bestIndex or 1)
                        else
                            applySelection(1)
                        end
                    elseif stealHighestEnabled then
                        applySelection(1)
                    end
                end
            end
        end
    end)

    RunService.Heartbeat:Connect(function()
        if not autoStealEnabled then return end
        if instantStealEnabled then
            if activeProgressTween then activeProgressTween:Cancel(); activeProgressTween = nil end
            progressBarFill.Size = UDim2.new(1, 0, 1, 0)
            progressBarFill.BackgroundTransparency = 0
            if not instantStealDidInit then
                instantStealDidInit = true
                task.spawn(function()
                    if not game:IsLoaded() then game.Loaded:Wait() end
                    task.wait(0.5)
                    instantStealReady = true
                end)
            end
            if instantStealReady then
                if stealNearestEnabled then
                    local prompt, dist, name = findNearestPrompt_Instant()
                    if prompt and dist <= INSTANT_STEAL_RADIUS then
                        executeInstantSteal(prompt)
                    end
                else
                    local pets = get_all_pets()
                    if #pets > 0 then
                        if selectedTargetIndex > #pets then selectedTargetIndex = #pets end
                        if selectedTargetIndex < 1 then selectedTargetIndex = 1 end
                        local tp = pets[selectedTargetIndex]
                        if tp and not isMyBaseAnimal(tp.animalData) then
                            local pr = PromptMemoryCache[tp.uid]
                            if not pr or not pr.Parent then pr = findProximityPromptForAnimal(tp.animalData) end
                            if pr then executeInstantSteal(pr) end
                        end
                    end
                end
            end
            return
        end
        local pets = get_all_pets()
        if #pets == 0 then return end
        if selectedTargetIndex > #pets then selectedTargetIndex = #pets end
        if selectedTargetIndex < 1 then selectedTargetIndex = 1 end
        local tp = pets[selectedTargetIndex]
        if not tp or isMyBaseAnimal(tp.animalData) then return end
        local pr = PromptMemoryCache[tp.uid]
        if not pr or not pr.Parent then pr = findProximityPromptForAnimal(tp.animalData) end
        if pr then attemptSteal(pr, tp.uid) end
    end)

    -- ── STEAL PROGRESS FLOATING GUI ─────────────────────────────────────
    local stealProgressGui = Instance.new("ScreenGui")
    stealProgressGui.Name = "XiStealProgress"
    stealProgressGui.ResetOnSpawn = false
    stealProgressGui.Parent = PlayerGui
    stealProgressGui.Enabled = true

    local spFrame = Instance.new("Frame")
    spFrame.Size = UDim2.new(0, 260, 0, 54)
    spFrame.Position = UDim2.new(0.5, 0, 0, 68)
    spFrame.AnchorPoint = Vector2.new(0.5, 0)
    spFrame.BackgroundColor3 = Color3.fromRGB(6, 4, 18)
    spFrame.BackgroundTransparency = 0.08
    spFrame.BorderSizePixel = 0
    spFrame.Parent = stealProgressGui
    Instance.new("UICorner", spFrame).CornerRadius = UDim.new(0, 12)
    MakeDraggable(spFrame, spFrame)

    local spStroke = Instance.new("UIStroke", spFrame)
    spStroke.Thickness = 1.5
    spStroke.Color = Color3.fromRGB(124, 58, 237)
    spStroke.Transparency = 0.3
    task.spawn(function()
        local cols = {
            Color3.fromRGB(124, 58, 237),
            Color3.fromRGB(219, 39, 119),
            Color3.fromRGB(6, 182, 212),
        }
        local ci = 1
        while spStroke.Parent do
            TweenService:Create(spStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {Color = cols[ci]}):Play()
            ci = (ci % #cols) + 1
            task.wait(1.5)
        end
    end)

    -- Top row: target name + percentage label
    local spNameLabel = Instance.new("TextLabel", spFrame)
    spNameLabel.Size = UDim2.new(0.7, 0, 0, 20)
    spNameLabel.Position = UDim2.new(0, 10, 0, 6)
    spNameLabel.BackgroundTransparency = 1
    spNameLabel.Font = Enum.Font.GothamBold
    spNameLabel.TextSize = 12
    spNameLabel.TextColor3 = Color3.fromRGB(200, 190, 240)
    spNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    spNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    spNameLabel.Text = "Searching..."

    local spPctLabel = Instance.new("TextLabel", spFrame)
    spPctLabel.Size = UDim2.new(0.28, 0, 0, 20)
    spPctLabel.Position = UDim2.new(0.72, 0, 0, 6)
    spPctLabel.BackgroundTransparency = 1
    spPctLabel.Font = Enum.Font.GothamBlack
    spPctLabel.TextSize = 13
    spPctLabel.TextColor3 = Color3.fromRGB(52, 211, 153)
    spPctLabel.TextXAlignment = Enum.TextXAlignment.Right
    spPctLabel.Text = "0%"

    -- Progress track
    local spTrack = Instance.new("Frame", spFrame)
    spTrack.Size = UDim2.new(1, -20, 0, 8)
    spTrack.Position = UDim2.new(0, 10, 0, 32)
    spTrack.BackgroundColor3 = Color3.fromRGB(20, 12, 40)
    spTrack.BorderSizePixel = 0
    Instance.new("UICorner", spTrack).CornerRadius = UDim.new(1, 0)

    local spFill = Instance.new("Frame", spTrack)
    spFill.Size = UDim2.new(0, 0, 1, 0)
    spFill.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
    spFill.BorderSizePixel = 0
    Instance.new("UICorner", spFill).CornerRadius = UDim.new(1, 0)

    local spGrad = Instance.new("UIGradient", spFill)
    spGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(124, 58, 237)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(219, 39, 119)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 182, 212))
    }

    -- Keep spFill in sync with the actual progressBarFill
-- Counting percentage display
    -- Simple counting display independent of steal bar
    local countNum = 0
    local counting = false

    task.spawn(function()
        while spFrame.Parent do
            task.wait(0.05)
            -- Update pet name
            local ct = SharedState.SelectedPetData
            spNameLabel.Text = ct and (ct.petName or "Searching...") or (autoStealEnabled and "Searching..." or "Disabled")
        end
    end)

    -- Watch for steal starting and count 0-100 over STEAL_DURATION seconds
    local lastReady = true
    RunService.Heartbeat:Connect(function()
        if not progressBarFill or not progressBarFill.Parent then return end

        local isActive = progressBarFill.Size.X.Scale > 0.01 or instantStealEnabled

        -- Detect new steal starting (bar reset to 0 then started growing)
        local currentScale = progressBarFill.Size.X.Scale
        if instantStealEnabled then
            if not counting then
                counting = true
                countNum = 0
                task.spawn(function()
                    while counting and spFrame.Parent do
                        countNum = (countNum + 3) % 101
                        spPctLabel.Text = tostring(math.floor(countNum)) .. "%"
                        spFill.Size = UDim2.new(countNum / 100, 0, 1, 0)
                        task.wait(0.03)
                    end
                end)
            end
        else
            if currentScale < 0.02 and not lastReady then
                -- bar just reset, start new count
                counting = false
                task.wait(0.05)
                counting = true
                countNum = 0
                task.spawn(function()
                    local startTime = tick()
                    while counting and spFrame.Parent do
                        local elapsed = tick() - startTime
                        countNum = math.min((elapsed / STEAL_DURATION) * 100, 100)
                        local pctInt = math.floor(countNum)
                        spPctLabel.Text = tostring(pctInt) .. "%"
                        spFill.Size = UDim2.new(countNum / 100, 0, 1, 0)
                        if pctInt >= 100 then
                            spPctLabel.TextColor3 = Color3.fromRGB(52, 211, 153)
                            spGrad.Color = ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(16, 185, 129)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 182, 212))
                            }
                            counting = false
                            break
                        else
                            spPctLabel.TextColor3 = Color3.fromRGB(196, 181, 253)
                            spGrad.Color = ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(124, 58, 237)),
                                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(219, 39, 119)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 182, 212))
                            }
                        end
                        task.wait(0.016)
                    end
                end)
            end
            if currentScale < 0.02 then
                lastReady = true
            else
                lastReady = false
            end
        end
    end)

    task.spawn(function() while task.wait(0.5) do updateUI(autoStealEnabled, get_all_pets()) end end)
    task.delay(1, function() SharedState.ListNeedsRedraw = true; updateUI(autoStealEnabled, get_all_pets()) end)
    task.spawn(function() while true do SharedState.AllAnimalsCache = allAnimalsCache; task.wait(0.5) end end)

    task.spawn(function()
    task.wait(4)
    for _, data in ipairs(allAnimalsCache) do
        local adornee = findAdorneeGlobal(data)
        if adornee then
            local model = adornee.Parent
            if model then
                local img = model:FindFirstChildOfClass("ImageLabel", true) or model:FindFirstChildWhichIsA("Decal", true)
                if img then
                    local imgId = img:IsA("ImageLabel") and img.Image or img.Texture
                    if imgId and imgId ~= "" then data._cachedImageId = imgId end
                end
            end
        end
    end
end)

    local beamFolder = Instance.new("Folder", Workspace)
    beamFolder.Name = "XiTracers"
    local currentBeam = nil
    local currentAtt0 = nil
    local currentAtt1 = nil

    local function updateTracer()
        if not autoStealEnabled or not Config.TracerEnabled then
            if currentBeam then currentBeam:Destroy(); currentBeam = nil end
            if currentAtt0 then currentAtt0:Destroy(); currentAtt0 = nil end
            if currentAtt1 then currentAtt1:Destroy(); currentAtt1 = nil end
            return
        end
        local best = nil
        local targetPart = nil
        if Config.LineToBase then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local plots = Workspace:FindFirstChild("Plots")
                if plots then
                    for _, plot in ipairs(plots:GetChildren()) do
                        local ok, ch = pcall(function() return Synchronizer:Get(plot.Name) end)
                        if ok and ch then
                            local owner = ch:Get("Owner")
                            local ownerId = (typeof(owner) == "Instance" and owner:IsA("Player")) and owner.UserId or (type(owner) == "table" and owner.UserId)
                            if ownerId == LocalPlayer.UserId then
                                local plotPos = plot:FindFirstChild("Base") and plot.Base:FindFirstChild("Spawn")
                                if plotPos and plotPos:IsA("BasePart") then targetPart = plotPos; break end
                            end
                        end
                    end
                end
            end
        else
            local pets = get_all_pets()
            if #pets == 0 then
                if currentBeam then currentBeam.Enabled = false end
                return
            end
            if selectedTargetIndex > #pets then selectedTargetIndex = #pets end
            if selectedTargetIndex < 1 then selectedTargetIndex = 1 end
            best = pets[selectedTargetIndex] or pets[1]
            targetPart = findAdorneeGlobal(best.animalData)
        end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and targetPart then
            if not currentAtt0 or currentAtt0.Parent ~= hrp then
                if currentAtt0 then currentAtt0:Destroy() end
                currentAtt0 = Instance.new("Attachment", hrp)
            end
            if not currentAtt1 or currentAtt1.Parent ~= targetPart then
                if currentAtt1 then currentAtt1:Destroy() end
                currentAtt1 = Instance.new("Attachment", targetPart)
            end
            if not currentBeam then
                currentBeam = Instance.new("Beam", beamFolder)
                currentBeam.FaceCamera = true; currentBeam.Width0 = 0.8; currentBeam.Width1 = 0.8
                currentBeam.TextureMode = Enum.TextureMode.Static; currentBeam.TextureSpeed = 3
            end
            currentBeam.Attachment0 = currentAtt0; currentBeam.Attachment1 = currentAtt1; currentBeam.Enabled = true
            local MUT_COLORS_TRACE = {
                Cursed=Color3.fromRGB(200,0,0), Gold=Color3.fromRGB(255,215,0),
                Diamond=Color3.fromRGB(0,255,255), YinYang=Color3.fromRGB(220,220,220),
                Rainbow=Color3.fromRGB(255,100,200), Lava=Color3.fromRGB(255,100,20),
                Candy=Color3.fromRGB(255,105,180), Divine=Color3.fromRGB(255,255,255)
            }
            local col = Theme.Accent2
            if not Config.LineToBase then
                col = (best and best.mutation and MUT_COLORS_TRACE[best.mutation]) or Theme.Accent1
            end
            currentBeam.Color = ColorSequence.new(col)
        else
            if currentBeam then currentBeam.Enabled = false end
        end
    end

    RunService.Heartbeat:Connect(updateTracer)
end)

task.spawn(function()
    local COOLDOWNS = {
        rocket = 120, ragdoll = 30, balloon = 30, inverse = 60,
        nightvision = 60, jail = 60, tiny = 60, jumpscare = 60, morph = 60
    }
    local ALL_COMMANDS = {
        "balloon", "inverse", "jail", "jumpscare", "morph",
        "nightvision", "ragdoll", "rocket", "tiny"
    }
    local CMD_ICONS = {
        balloon    = "B", inverse = "INV", jail = "JAIL",
        jumpscare  = "JUMP", morph   = "NV", nightvision = "NV",
        ragdoll    = "RAG", rocket  = "RKT", tiny = "TINY"
    }
    local CMD_COLORS = {
        balloon    = Color3.fromRGB(251, 191, 36),
        inverse    = Color3.fromRGB(168, 85, 247),
        jail       = Color3.fromRGB(239, 68, 68),
        jumpscare  = Color3.fromRGB(249, 115, 22),
        morph      = Color3.fromRGB(16, 185, 129),
        nightvision= Color3.fromRGB(6, 182, 212),
        ragdoll    = Color3.fromRGB(219, 39, 119),
        rocket     = Color3.fromRGB(245, 158, 11),
        tiny       = Color3.fromRGB(99, 102, 241),
    }
 
    local activeCooldowns = {}
    SharedState.AdminButtonCache = {} 

     local adminGui = Instance.new("ScreenGui")
    adminGui.Name = "XiAdminPanel"
    adminGui.ResetOnSpawn = false
    adminGui.Parent = PlayerGui

     local frame = Instance.new("Frame")
    local mobileScale = IS_MOBILE and 0.65 or 1
    frame.Size = UDim2.new(0, 420 * mobileScale, 0, 580 * mobileScale)
    frame.Position = UDim2.new(Config.Positions.AdminPanel.X, 0, Config.Positions.AdminPanel.Y, 0)
    frame.BackgroundColor3 = Color3.fromRGB(6, 4, 18)
    frame.BackgroundTransparency = 0.04
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = adminGui
 
    ApplyViewportUIScale(frame, 420, 520, 0.45, 0.85)
    AddMobileMinimize(frame, "ADMIN")
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Theme.Accent2; stroke.Thickness = 1.5; stroke.Transparency = 0.4
    CreateGradient(stroke)

    local header = Instance.new("Frame", frame)
    header.Size = UDim2.new(1, 0, 0, 52)
    header.BackgroundColor3 = Color3.fromRGB(219, 39, 119)
    header.BackgroundTransparency = 0.82
    header.BorderSizePixel = 0
    local headerGrad = Instance.new("UIGradient", header)
    headerGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(219, 39, 119)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(124, 58, 237))
    }
    headerGrad.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.75),
        NumberSequenceKeypoint.new(1, 0.9)
    }
    local headerLine = Instance.new("Frame", frame)
    headerLine.Size = UDim2.new(1, 0, 0, 1)
    headerLine.Position = UDim2.new(0, 0, 0, 52)
    headerLine.BackgroundColor3 = Color3.fromRGB(219, 39, 119)
    headerLine.BackgroundTransparency = 0.4
    headerLine.BorderSizePixel = 0
    local hlGrad = Instance.new("UIGradient", headerLine)
    hlGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(219,39,119)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0))
    }
    MakeDraggable(header, frame, "AdminPanel")

    local title = Instance.new("TextLabel", header)
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "⚡ LETHAL AP"
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 16
    title.TextColor3 = Theme.TextPrimary
    title.TextXAlignment = Enum.TextXAlignment.Left

    local refreshBtn = Instance.new("TextButton", header)
    refreshBtn.Size = UDim2.new(0, 80, 0, 30)
    refreshBtn.Position = UDim2.new(1, -85, 0.5, -15)
    refreshBtn.BackgroundColor3 = Theme.SurfaceHighlight
    refreshBtn.Text = "REFRESH"
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 12
    refreshBtn.TextColor3 = Theme.TextPrimary
    Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 6)
    local refreshStroke = Instance.new("UIStroke", refreshBtn)
    refreshStroke.Color = Theme.Accent2
    refreshStroke.Thickness = 1
    refreshStroke.Transparency = 0.3
    
    refreshBtn.MouseButton1Click:Connect(function()
        for _, child in ipairs(listFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        for _, player in ipairs(Players:GetPlayers()) do
            if Config.HideKawaifuFromPanel and isKawaifuUser(player) then continue end
            createPlayerRow(player)
        end
        sortAdminPanelList()
        
        ShowNotification("ADMIN PANEL", "Player list refreshed")
    end)

    local proxCont = Instance.new("Frame", frame)
proxCont.Size = UDim2.new(1, -20, 0, 150)
proxCont.Position = UDim2.new(0, 10, 0, 58)
proxCont.BackgroundColor3 = Color3.fromRGB(6, 4, 18)
proxCont.BackgroundTransparency = 0.15
proxCont.BorderSizePixel = 0
Instance.new("UICorner", proxCont).CornerRadius = UDim.new(0, 12)
local proxContStroke = Instance.new("UIStroke", proxCont)
proxContStroke.Color = Color3.fromRGB(124, 58, 237)
proxContStroke.Thickness = 1.5
proxContStroke.Transparency = 0.3

    -- Header label inside proxCont
local proxHeader = Instance.new("TextLabel", proxCont)
proxHeader.Size = UDim2.new(1, -16, 0, 18)
proxHeader.Position = UDim2.new(0, 10, 0, 6)
proxHeader.BackgroundTransparency = 1
proxHeader.Text = "⚡ LETHAL AP"
proxHeader.Font = Enum.Font.GothamBlack
proxHeader.TextSize = 13
proxHeader.TextColor3 = Color3.fromRGB(200, 180, 255)
proxHeader.TextXAlignment = Enum.TextXAlignment.Left

local proxHeaderGrad = Instance.new("UIGradient", proxHeader)
proxHeaderGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 180, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(6, 182, 212)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(219, 39, 119))
}
task.spawn(function()
    local offset = 0
    while proxHeaderGrad.Parent do
        offset = (offset + 0.02) % 1
        proxHeaderGrad.Offset = Vector2.new(-1 + offset * 2, 0)
        task.wait(0.05)
    end
end)

-- Button row
local proxBtnRow = Instance.new("Frame", proxCont)
proxBtnRow.Size = UDim2.new(1, -16, 0, 30)
proxBtnRow.Position = UDim2.new(0, 8, 0, 26)
proxBtnRow.BackgroundTransparency = 1

local proxBtn = Instance.new("TextButton", proxBtnRow)
proxBtn.Name = "ProximityAPButton"
proxBtn.Size = UDim2.new(0, 90, 1, 0)
proxBtn.Position = UDim2.new(0, 0, 0, 0)
proxBtn.BackgroundColor3 = ProximityAPActive and Color3.fromRGB(60, 20, 120) or Color3.fromRGB(18, 12, 38)
proxBtn.BackgroundTransparency = 0.1
proxBtn.Text = ProximityAPActive and "● PROX ON" or "○ PROX OFF"
proxBtn.Font = Enum.Font.GothamBlack
proxBtn.TextSize = 10
proxBtn.TextColor3 = ProximityAPActive and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(100, 80, 150)
proxBtn.AutoButtonColor = false
Instance.new("UICorner", proxBtn).CornerRadius = UDim.new(0, 8)
local proxBtnStroke = Instance.new("UIStroke", proxBtn)
proxBtnStroke.Color = ProximityAPActive and Color3.fromRGB(124, 58, 237) or Color3.fromRGB(40, 30, 70)
proxBtnStroke.Thickness = 1.5
proxBtnStroke.Transparency = 0.3
SharedState.ProximityAPButton = proxBtn
SharedState.ProximityAPButtonStroke = proxBtnStroke
SharedState.AdminProxBtn = proxBtn

local spamBaseBtn = Instance.new("TextButton", proxBtnRow)
spamBaseBtn.Size = UDim2.new(0, 100, 1, 0)
spamBaseBtn.Position = UDim2.new(0, 96, 0, 0)
spamBaseBtn.BackgroundColor3 = Color3.fromRGB(18, 12, 38)
spamBaseBtn.BackgroundTransparency = 0.1
spamBaseBtn.Text = "Spam B OWNER"
spamBaseBtn.Font = Enum.Font.GothamBold
spamBaseBtn.TextSize = 9
spamBaseBtn.TextColor3 = Color3.fromRGB(219, 39, 119)
spamBaseBtn.AutoButtonColor = false
Instance.new("UICorner", spamBaseBtn).CornerRadius = UDim.new(0, 8)
local spamBaseBtnStroke = Instance.new("UIStroke", spamBaseBtn)
spamBaseBtnStroke.Color = Color3.fromRGB(219, 39, 119)
spamBaseBtnStroke.Thickness = 1.5
spamBaseBtnStroke.Transparency = 0.4

spamBaseBtn.MouseEnter:Connect(function()
    TweenService:Create(spamBaseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(35, 10, 30)}):Play()
    TweenService:Create(spamBaseBtnStroke, TweenInfo.new(0.15), {Transparency = 0.1}):Play()
end)
spamBaseBtn.MouseLeave:Connect(function()
    TweenService:Create(spamBaseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(18, 12, 38)}):Play()
    TweenService:Create(spamBaseBtnStroke, TweenInfo.new(0.15), {Transparency = 0.4}):Play()
end)
    
    spamBaseBtn.MouseButton1Click:Connect(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            ShowNotification("SPAM OWNER", "No character found")
            return
        end
        
        local nearestPlot = nil
        local nearestDist = math.huge
        local Plots = Workspace:FindFirstChild("Plots")
        if Plots then
            for _, plot in ipairs(Plots:GetChildren()) do
                local sign = plot:FindFirstChild("PlotSign")
                if sign then
                    local yourBase = sign:FindFirstChild("YourBase")
                    if not yourBase or not yourBase.Enabled then
                        local signPos = sign:IsA("BasePart") and sign.Position or (sign.PrimaryPart and sign.PrimaryPart.Position)
                        if not signPos then
                            local part = sign:FindFirstChildWhichIsA("BasePart", true)
                            signPos = part and part.Position
                        end
                        if signPos then
                            local dist = (hrp.Position - signPos).Magnitude
                            if dist < nearestDist then
                                nearestDist = dist
                                nearestPlot = plot
                            end
                        end
                    end
                end
            end
        end
        
        if not nearestPlot then
            ShowNotification("SPAM OWNER", "No nearby base found")
            return
        end
        
        
        local targetPlayer = nil
        local ok, ch = pcall(function() return Synchronizer:Get(nearestPlot.Name) end)
        if ok and ch then
            local owner = ch:Get("Owner")
            if owner then
                if typeof(owner) == "Instance" and owner:IsA("Player") then
                    targetPlayer = owner
                elseif type(owner) == "table" and owner.Name then
                    targetPlayer = Players:FindFirstChild(owner.Name)
                end
            end
        end
        
        
        if not targetPlayer then
            local sign = nearestPlot:FindFirstChild("PlotSign")
            local textLabel = sign and sign:FindFirstChild("SurfaceGui") and sign.SurfaceGui:FindFirstChild("Frame") and sign.SurfaceGui.Frame:FindFirstChild("TextLabel")
            if textLabel then
                local baseText = textLabel.Text
                local nickname = baseText and baseText:match("^(.-)'") or baseText
                if nickname then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p.DisplayName == nickname or p.Name == nickname then
                            targetPlayer = p
                            break
                        end
                    end
                end
            end
        end
        
        if not targetPlayer or targetPlayer == LocalPlayer then
            ShowNotification("SPAM OWNER", "Owner not found or is you")
            return
        end
        
        spamBaseBtn.BackgroundColor3 = Theme.Accent1
        spamBaseBtn.TextColor3 = Color3.new(1,1,1)
        ShowNotification("SPAM OWNER", "Spamming " .. targetPlayer.DisplayName)
        
        task.spawn(function()
            local cmds = {"balloon", "inverse", "jail", "jumpscare", "morph", "nightvision", "ragdoll", "rocket", "tiny"}
            local cmdCount = 0
            
            local adminFunc = _G.runAdminCommand
            if not adminFunc then
                task.wait(0.05)
                adminFunc = _G.runAdminCommand
            end
            
            if not adminFunc then
                spamBaseBtn.BackgroundColor3 = Color3.fromRGB(35, 37, 43)
                spamBaseBtn.TextColor3 = Theme.TextPrimary
                ShowNotification("SPAM OWNER", "Admin command not ready")
                return
            end
            
            for _, cmd in ipairs(cmds) do
                local success, result = pcall(function()
                    return adminFunc(targetPlayer, cmd)
                end)
                if success and result then
                    cmdCount = cmdCount + 1
                end
                task.wait(0.15)
            end
            
            task.wait(0.2)
            spamBaseBtn.BackgroundColor3 = Color3.fromRGB(35, 37, 43)
            spamBaseBtn.TextColor3 = Theme.TextPrimary
            ShowNotification("SPAM OWNER", "Sent " .. cmdCount .. " commands to " .. targetPlayer.DisplayName)
        end)
    end)

    local proxSliderBg = Instance.new("Frame", proxCont)
proxSliderBg.Size = UDim2.new(1, -16, 0, 44)
proxSliderBg.Position = UDim2.new(0, 8, 0, 62)
proxSliderBg.BackgroundColor3 = Color3.fromRGB(10, 6, 24)
proxSliderBg.BackgroundTransparency = 0.2
proxSliderBg.BorderSizePixel = 0
Instance.new("UICorner", proxSliderBg).CornerRadius = UDim.new(0, 10)
local proxSliderStroke = Instance.new("UIStroke", proxSliderBg)
proxSliderStroke.Color = Theme.Accent2
proxSliderStroke.Thickness = 1
proxSliderStroke.Transparency = 0.5

local proxSliderLabel = Instance.new("TextLabel", proxSliderBg)
proxSliderLabel.Size = UDim2.new(0.5, 0, 0, 16)
proxSliderLabel.Position = UDim2.new(0, 8, 0, 3)
proxSliderLabel.BackgroundTransparency = 1
proxSliderLabel.Text = "PROXIMITY RANGE"
proxSliderLabel.Font = Enum.Font.GothamBold
proxSliderLabel.TextSize = 9
proxSliderLabel.TextColor3 = Theme.TextSecondary
proxSliderLabel.TextXAlignment = Enum.TextXAlignment.Left

local proxSliderVal = Instance.new("TextLabel", proxSliderBg)
proxSliderVal.Size = UDim2.new(0.5, -8, 0, 16)
proxSliderVal.Position = UDim2.new(0.5, 0, 0, 3)
proxSliderVal.BackgroundTransparency = 1
proxSliderVal.Text = tostring(Config.ProximityRange) .. " studs"
proxSliderVal.Font = Enum.Font.GothamBlack
proxSliderVal.TextSize = 9
proxSliderVal.TextColor3 = Theme.Accent2
proxSliderVal.TextXAlignment = Enum.TextXAlignment.Right

local proxTrack = Instance.new("Frame", proxSliderBg)
proxTrack.Size = UDim2.new(1, -16, 0, 6)
proxTrack.Position = UDim2.new(0, 8, 0, 24)
proxTrack.BackgroundColor3 = Color3.fromRGB(30, 20, 60)
proxTrack.BorderSizePixel = 0
Instance.new("UICorner", proxTrack).CornerRadius = UDim.new(1, 0)

local proxFill = Instance.new("Frame", proxTrack)
proxFill.BackgroundColor3 = Theme.Accent1
proxFill.Size = UDim2.new(0, 0, 1, 0)
proxFill.BorderSizePixel = 0
Instance.new("UICorner", proxFill).CornerRadius = UDim.new(1, 0)
local proxFillGrad = Instance.new("UIGradient", proxFill)
proxFillGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(124, 58, 237)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 182, 212))
}

local proxKnob = Instance.new("Frame", proxTrack)
proxKnob.Size = UDim2.new(0, 14, 0, 14)
proxKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
proxKnob.AnchorPoint = Vector2.new(0.5, 0.5)
proxKnob.Position = UDim2.new(0, 0, 0.5, 0)
proxKnob.BorderSizePixel = 0
Instance.new("UICorner", proxKnob).CornerRadius = UDim.new(1, 0)
local proxKnobStroke = Instance.new("UIStroke", proxKnob)
proxKnobStroke.Color = Theme.Accent1
proxKnobStroke.Thickness = 1.5
proxKnobStroke.Transparency = 0.2

task.spawn(function()
    while proxKnob.Parent do
        TweenService:Create(proxKnobStroke, TweenInfo.new(1, Enum.EasingStyle.Sine), {Transparency = 0}):Play()
        task.wait(1)
        TweenService:Create(proxKnobStroke, TweenInfo.new(1, Enum.EasingStyle.Sine), {Transparency = 0.5}):Play()
        task.wait(1)
    end
end)

-- Min/Max labels
local proxMinLbl = Instance.new("TextLabel", proxSliderBg)
proxMinLbl.Size = UDim2.new(0, 20, 0, 12)
proxMinLbl.Position = UDim2.new(0, 8, 0, 32)
proxMinLbl.BackgroundTransparency = 1
proxMinLbl.Text = "5"
proxMinLbl.Font = Enum.Font.GothamMedium
proxMinLbl.TextSize = 9
proxMinLbl.TextColor3 = Theme.TextSecondary
proxMinLbl.TextXAlignment = Enum.TextXAlignment.Left

local proxMaxLbl = Instance.new("TextLabel", proxSliderBg)
proxMaxLbl.Size = UDim2.new(0, 24, 0, 12)
proxMaxLbl.Position = UDim2.new(1, -32, 0, 32)
proxMaxLbl.BackgroundTransparency = 1
proxMaxLbl.Text = "50"
proxMaxLbl.Font = Enum.Font.GothamMedium
proxMaxLbl.TextSize = 9
proxMaxLbl.TextColor3 = Theme.TextSecondary
proxMaxLbl.TextXAlignment = Enum.TextXAlignment.Right

local function updateProxSlider(val)
    local min, max = 5, 50
    val = math.clamp(val, min, max)
    Config.ProximityRange = val
    SaveConfig()
    local pct = (val - min) / (max - min)
    proxFill.Size = UDim2.new(pct, 0, 1, 0)
    proxKnob.Position = UDim2.new(pct, 0, 0.5, 0)
    proxSliderVal.Text = string.format("%.0f studs", val)
end
updateProxSlider(Config.ProximityRange)

    local pDragging = false
proxTrack.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        pDragging = true
        local x = i.Position.X
        local r = proxTrack.AbsolutePosition.X
        local w = proxTrack.AbsoluteSize.X
        updateProxSlider(5 + (math.clamp((x - r) / w, 0, 1) * 45))
    end
end)
proxKnob.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        pDragging = true
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        pDragging = false
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if pDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local x = i.Position.X
        local r = proxTrack.AbsolutePosition.X
        local w = proxTrack.AbsoluteSize.X
        updateProxSlider(5 + (math.clamp((x - r) / w, 0, 1) * 45))
    end
end)

    local proxViz = nil
    local function updateProxViz()
        if ProximityAPActive then 
            if not proxViz then
                proxViz = Instance.new("Part")
                proxViz.Name = "XiProxViz"
                proxViz.Anchored = true; proxViz.CanCollide = false
                proxViz.Shape = Enum.PartType.Cylinder
                proxViz.Color = Theme.Accent1; proxViz.Transparency = 0.6
                proxViz.CastShadow = false
                proxViz.Parent = Workspace
            end
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                proxViz.Size = Vector3.new(0.5, Config.ProximityRange * 2, Config.ProximityRange * 2)
                proxViz.CFrame = hrp.CFrame * CFrame.Angles(0,0,math.rad(90)) + Vector3.new(0, -2.5, 0)
            end
        else
            if proxViz then proxViz:Destroy(); proxViz = nil end
        end
    end
    RunService.Heartbeat:Connect(updateProxViz)

    local function updateProximityAPButton()
    if SharedState.ProximityAPButton then
        local btn = SharedState.ProximityAPButton
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = ProximityAPActive and Color3.fromRGB(60, 20, 120) or Color3.fromRGB(18, 12, 38)
        }):Play()
        btn.Text = ProximityAPActive and "● PROX ON" or "○ PROX OFF"
        btn.TextColor3 = ProximityAPActive and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(100, 80, 150)
        if SharedState.ProximityAPButtonStroke then
            TweenService:Create(SharedState.ProximityAPButtonStroke, TweenInfo.new(0.2), {
                Color = ProximityAPActive and Color3.fromRGB(124, 58, 237) or Color3.fromRGB(40, 30, 70)
            }):Play()
        end
    end
end
    
    proxBtn.MouseButton1Click:Connect(function()
        ProximityAPActive = not ProximityAPActive 
        updateProximityAPButton()
        ShowNotification("PROXIMITY AP", ProximityAPActive and "ENABLED" or "DISABLED")
    end)

    

    local listFrame = Instance.new("ScrollingFrame", frame)
listFrame.Size = UDim2.new(1, -20, 1, -220)
listFrame.Position = UDim2.new(0, 10, 0, 215)
    listFrame.BackgroundTransparency = 1
    listFrame.BorderSizePixel = 0
    listFrame.ScrollBarThickness = 5
    listFrame.ScrollBarImageColor3 = Theme.Accent1
    local layout = Instance.new("UIListLayout", listFrame)
    layout.Padding = UDim.new(0, 10); layout.SortOrder = Enum.SortOrder.LayoutOrder

    local function getAdminPanelSortKey(plr)
        if not plr or not plr.Parent then return 3, 9999, "" end
        local stealing = plr:GetAttribute("Stealing")
        local brainrotName = plr:GetAttribute("StealingIndex")
        if not stealing then
            return 3, 9999, plr.Name or ""
        end
        if brainrotName then
            for i, pName in ipairs(PRIORITY_LIST) do
                if pName == brainrotName then
                    return 1, i, plr.Name or ""
                end
            end
            return 2, 9999, plr.Name or ""
        end
        return 2, 9999, plr.Name or ""
    end

    local function sortAdminPanelList()
        local rows = {}
        for _, child in ipairs(listFrame:GetChildren()) do
            if child:IsA("TextButton") and child.Name ~= "" then
                local plr = Players:FindFirstChild(child.Name)
                if plr then
                    table.insert(rows, {row = child, plr = plr})
                end
            end
        end
        table.sort(rows, function(a, b)
            local t1, p1, n1 = getAdminPanelSortKey(a.plr)
            local t2, p2, n2 = getAdminPanelSortKey(b.plr)
            if t1 ~= t2 then return t1 < t2 end
            if p1 ~= p2 then return p1 < p2 end
            return (n1 or "") < (n2 or "")
        end)
        for i, entry in ipairs(rows) do
            entry.row.LayoutOrder = i
        end
    end

    local function fireClick(button)
        if button then
            if firesignal then
                firesignal(button.MouseButton1Click); firesignal(button.MouseButton1Down); firesignal(button.Activated)
            else
                local x = button.AbsolutePosition.X + (button.AbsoluteSize.X / 2)
                local y = button.AbsolutePosition.Y + (button.AbsoluteSize.Y / 2) + 58
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
            end
        end
    end
    _G.fireClick = fireClick

    local function runAdminCommand(targetPlayer, commandName)
        local realAdminGui = PlayerGui:WaitForChild("AdminPanel", 5)
        if not realAdminGui then return false end
        local contentScroll = realAdminGui.AdminPanel:WaitForChild("Content"):WaitForChild("ScrollingFrame")
        local cmdBtn = contentScroll:FindFirstChild(commandName)
        if not cmdBtn then return false end
        fireClick(cmdBtn)
        task.wait(0.05)
        local profilesScroll = realAdminGui:WaitForChild("AdminPanel"):WaitForChild("Profiles"):WaitForChild("ScrollingFrame")
        local playerBtn = profilesScroll:FindFirstChild(targetPlayer.Name)
        if not playerBtn then return false end
        fireClick(playerBtn)
        return true
    end
    
    _G.runAdminCommand = runAdminCommand

local ALL_COMMANDS = {
    "balloon", "inverse", "jail", "jumpscare", "morph", 
    "nightvision", "ragdoll", "rocket", "tiny"
}

local isOnCooldown

local function getNextAvailableCommand()
    local priorityCommands = {"ragdoll", "balloon", "rocket", "jail"}
    local otherCommands = {}
    
    for _, cmd in ipairs(ALL_COMMANDS) do
        local isPriority = false
        for _, priorityCmd in ipairs(priorityCommands) do
            if cmd == priorityCmd then
                isPriority = true
                break
            end
        end
        if not isPriority then
            table.insert(otherCommands, cmd)
        end
    end

    for _, cmd in ipairs(priorityCommands) do
        if not isOnCooldown(cmd) then
            return cmd
        end
    end

    for _, cmd in ipairs(otherCommands) do
        if not isOnCooldown(cmd) then
            return cmd
        end
    end

    return nil
end

isOnCooldown = function(cmd)
    local adminGui = PlayerGui:FindFirstChild("AdminPanel")
    if adminGui then
        local content = adminGui:FindFirstChild("AdminPanel")
        if content then
            local scrollFrame = content:FindFirstChild("Content")
            if scrollFrame then
                local scrollingFrame = scrollFrame:FindFirstChild("ScrollingFrame")
                if scrollingFrame then
                    local cmdButton = scrollingFrame:FindFirstChild(cmd)
                    if cmdButton then
                        local timerLabel = cmdButton:FindFirstChild("Timer")
                        if timerLabel then
                            return timerLabel.Visible
                        end
                    end
                end
            end
        end
    end
    
    if not activeCooldowns[cmd] then return false end
    return (tick() - activeCooldowns[cmd]) < (COOLDOWNS[cmd] or 0)
end

    local function setGlobalVisualCooldown(cmd)
        if SharedState.AdminButtonCache[cmd] then
            for _, b in ipairs(SharedState.AdminButtonCache[cmd]) do
                if b and b.Parent then
                    b.BackgroundColor3 = Theme.Error
                    task.delay(COOLDOWNS[cmd] or 5, function()
                        if b and b.Parent then
                            local hasBallooned = (cmd == "balloon" and SharedState.BalloonedPlayers and next(SharedState.BalloonedPlayers) ~= nil)
                            b.BackgroundColor3 = hasBallooned and Theme.Error or Theme.SurfaceHighlight
                        end
                    end)
                end
            end
        end
    end

    local function updateBalloonButtons()
        local hasBallooned = false
        for _, _ in pairs(SharedState.BalloonedPlayers) do
            hasBallooned = true
            break
        end
        if SharedState.AdminButtonCache and SharedState.AdminButtonCache["balloon"] then
            for _, b in ipairs(SharedState.AdminButtonCache["balloon"]) do
                if b and b.Parent then
                    b.BackgroundColor3 = hasBallooned and Theme.Error or Theme.SurfaceHighlight
                end
            end
        end
    end

    local function triggerAll(plr)
        local count = 0
        for _, cmd in ipairs(ALL_COMMANDS) do
            if not isOnCooldown(cmd) then
                task.delay(count * 0.1, function()
                    if runAdminCommand(plr, cmd) then
                        activeCooldowns[cmd] = tick()
                        setGlobalVisualCooldown(cmd)
                        if cmd == "balloon" then
                            SharedState.BalloonedPlayers[plr.UserId] = true
                            updateBalloonButtons()
                        end
                    end
                end)
                count = count + 1
            end
        end
    end

    local function rayToCubeIntersect(rayOrigin, rayDirection, cubeCenter, cubeSize)
        local halfSize = cubeSize / 2
        local minBounds = cubeCenter - Vector3.new(halfSize, halfSize, halfSize)
        local maxBounds = cubeCenter + Vector3.new(halfSize, halfSize, halfSize)
        
        if rayDirection.X == 0 then rayDirection = Vector3.new(0.0001, rayDirection.Y, rayDirection.Z) end
        if rayDirection.Y == 0 then rayDirection = Vector3.new(rayDirection.X, 0.0001, rayDirection.Z) end
        if rayDirection.Z == 0 then rayDirection = Vector3.new(rayDirection.X, rayDirection.Y, 0.0001) end
        
        local tmin = (minBounds.X - rayOrigin.X) / rayDirection.X
        local tmax = (maxBounds.X - rayOrigin.X) / rayDirection.X
        if tmin > tmax then tmin, tmax = tmax, tmin end
        
        local tymin = (minBounds.Y - rayOrigin.Y) / rayDirection.Y
        local tymax = (maxBounds.Y - rayOrigin.Y) / rayDirection.Y
        if tymin > tymax then tymin, tymax = tymax, tymin end
        
        if tmin > tymax or tymin > tmax then return false end
        if tymin > tmin then tmin = tymin end
        if tymax < tmax then tmax = tymax end
        
        local tzmin = (minBounds.Z - rayOrigin.Z) / rayDirection.Z
        local tzmax = (maxBounds.Z - rayOrigin.Z) / rayDirection.Z
        if tzmin > tzmax then tzmin, tzmax = tzmax, tzmin end
        
        if tmin > tzmax or tzmin > tmax then return false end
        
        return true
    end

    local highlight = Instance.new("Highlight", game:GetService("CoreGui"))
    highlight.FillColor = Theme.Accent1
    highlight.FillTransparency = 0.3
    highlight.OutlineColor = Theme.Accent1
    highlight.OutlineTransparency = 0
    highlight.Adornee = nil
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    RunService.RenderStepped:Connect(function()
        if Config.ClickToAP then
            local camera = Workspace.CurrentCamera
            local mousePos = UserInputService:GetMouseLocation()
            local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
            
            local hitboxSize = 8
            local bestPlayer = nil
            local bestDistance = math.huge
            
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Parent then
                    local hrp = p.Character.HumanoidRootPart
                    local cubeCenter = hrp.Position
                    
                    if rayToCubeIntersect(ray.Origin, ray.Direction, cubeCenter, hitboxSize) then
                        local distance = (ray.Origin - cubeCenter).Magnitude
                        if distance < bestDistance then
                            bestDistance = distance
                            bestPlayer = p
                        end
                    end
                end
            end
            
            local newAdornee = bestPlayer and bestPlayer.Character or nil
            if highlight.Adornee ~= newAdornee then
                highlight.Adornee = newAdornee
            end
        else
            highlight.Adornee = nil
        end
    end)

    UserInputService.InputBegan:Connect(function(inp, g)
        if not g and inp.UserInputType == Enum.UserInputType.MouseButton1 and Config.ClickToAP then
            local camera = Workspace.CurrentCamera
            local mousePos = UserInputService:GetMouseLocation()
            local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
            
            local hitboxSize = 8
            local bestPlayer = nil
            local bestDistance = math.huge
            
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Parent then
                    local hrp = p.Character.HumanoidRootPart
                    local cubeCenter = hrp.Position
                    
                    if rayToCubeIntersect(ray.Origin, ray.Direction, cubeCenter, hitboxSize) then
                        local distance = (ray.Origin - cubeCenter).Magnitude
                        if distance < bestDistance then
                            bestDistance = distance
                            bestPlayer = p
                        end
                    end
                end
            end
            
            if bestPlayer then
                if Config.DisableClickToAPOnMoby and isMobyUser(bestPlayer) then
                    ShowNotification("CLICK TO AP", "Disabled on Moby users")
                    return
                end
                if Config.DisableClickToAPOnKawaifu and isKawaifuUser(bestPlayer) then
                    ShowNotification("CLICK TO AP", "Disabled on Kawaifu users")
                    return
                end
                
                local hasAnyAvailable = false
                for _, cmd in ipairs(ALL_COMMANDS) do
                    if not isOnCooldown(cmd) then
                        hasAnyAvailable = true
                        break
                    end
                end
                if hasAnyAvailable then
                    if Config.ClickToAPSingleCommand then
                        local nextCmd = getNextAvailableCommand()
                        if nextCmd then
                            if runAdminCommand(bestPlayer, nextCmd) then
                                activeCooldowns[nextCmd] = tick()
                                setGlobalVisualCooldown(nextCmd)
                                if nextCmd == "balloon" then
                                    SharedState.BalloonedPlayers[bestPlayer.UserId] = true
                                    updateBalloonButtons()
                                end
                                ShowNotification("CLICK AP", "Sent " .. nextCmd .. " to " .. bestPlayer.Name)
                            else
                                ShowNotification("CLICK AP", "Failed to send " .. nextCmd .. " to " .. bestPlayer.Name)
                            end
                        else
                            ShowNotification("CLICK AP", "All commands on cooldown")
                        end
                    else
                        triggerAll(bestPlayer)
                        ShowNotification("CLICK AP", "Triggered on " .. bestPlayer.Name)
                    end
                else
                    local realAdminGui = PlayerGui:WaitForChild("AdminPanel", 5)
                    if realAdminGui then
                        local profilesScroll = realAdminGui:WaitForChild("AdminPanel"):WaitForChild("Profiles"):WaitForChild("ScrollingFrame")
                        local playerBtn = profilesScroll:FindFirstChild(bestPlayer.Name)
                        if playerBtn then
                            fireClick(playerBtn)
                            ShowNotification("CLICK AP", "Selected " .. bestPlayer.Name)
                        end
                    end
                end
            end
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.2)
            if ProximityAPActive then
                local myChar = LocalPlayer.Character
                if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            local dist = (p.Character.HumanoidRootPart.Position - myChar.HumanoidRootPart.Position).Magnitude
                            if dist <= Config.ProximityRange then
                                if (Config.DisableProximitySpamOnMoby and isMobyUser(p)) or (Config.DisableProximitySpamOnKawaifu and isKawaifuUser(p)) then
                                    -- skip proximity AP 
                                else
                                    local hasAnyAvailable = false
                                    for _, cmd in ipairs(ALL_COMMANDS) do
                                        if not isOnCooldown(cmd) then
                                            hasAnyAvailable = true
                                            break
                                        end
                                    end
                                    if hasAnyAvailable then
                                        triggerAll(p)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    local function createPlayerRow(plr)
        local row = Instance.new("TextButton")
row.Name = plr.Name
row.LayoutOrder = 0
row.Size = UDim2.new(1, -4, 0, 60)
row.BackgroundColor3 = Color3.fromRGB(8, 5, 22)
row.BackgroundTransparency = 0.05
row.BorderSizePixel = 0
row.AutoButtonColor = false
row.Text = ""
row.Parent = listFrame
Instance.new("UICorner", row).CornerRadius = UDim.new(0, 12)

-- Animated gradient background
local rowGrad = Instance.new("UIGradient", row)
rowGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 8, 35)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 4, 18))
}
rowGrad.Rotation = 45

local rowStroke = Instance.new("UIStroke", row)
rowStroke.Color = Color3.fromRGB(124, 58, 237)
rowStroke.Thickness = 1.5
rowStroke.Transparency = 0.6

-- Left accent bar
local rowAccent = Instance.new("Frame", row)
rowAccent.Size = UDim2.new(0, 3, 1, -12)
rowAccent.Position = UDim2.new(0, 4, 0, 6)
rowAccent.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
rowAccent.BorderSizePixel = 0
Instance.new("UICorner", rowAccent).CornerRadius = UDim.new(1, 0)
local rowAccentGrad = Instance.new("UIGradient", rowAccent)
rowAccentGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(124, 58, 237)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 182, 212))
}
rowAccentGrad.Rotation = 90

        local headshot = Instance.new("ImageLabel", row)
        headshot.Size = UDim2.new(0, 42, 0, 42)
        headshot.Position = UDim2.new(0, 12, 0.5, -21)
        headshot.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
        headshot.Image = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        Instance.new("UICorner", headshot).CornerRadius = UDim.new(1, 0)
        local headshotStroke = Instance.new("UIStroke", headshot)
headshotStroke.Color = Color3.fromRGB(124, 58, 237)
headshotStroke.Thickness = 2.5
headshotStroke.Transparency = 0.1
task.spawn(function()
    local cols = {
        Color3.fromRGB(124, 58, 237),
        Color3.fromRGB(219, 39, 119),
        Color3.fromRGB(6, 182, 212),
    }
    local ci = 1
    while headshotStroke.Parent do
        TweenService:Create(headshotStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {Color = cols[ci]}):Play()
        ci = (ci % #cols) + 1
        task.wait(1.5)
    end
end)
        
        local dName = Instance.new("TextLabel", row)
        dName.Size = UDim2.new(0, 160, 0, 20)
        dName.Position = UDim2.new(0, 58, 0, 10)
        dName.BackgroundTransparency = 1
        dName.Text = plr.DisplayName
        dName.Font = Enum.Font.GothamBold
        dName.TextSize = 14
        dName.TextColor3 = Theme.TextPrimary
        dName.TextXAlignment = Enum.TextXAlignment.Left

        local uName = Instance.new("TextLabel", row)
        uName.Size = UDim2.new(0, 160, 0, 16)
        uName.Position = UDim2.new(0, 58, 0, 30)
        uName.BackgroundTransparency = 1
        uName.Text = "(@" .. plr.Name .. ")"
        uName.Font = Enum.Font.GothamMedium
        uName.TextSize = 7
        uName.TextColor3 = Theme.TextSecondary
        uName.TextXAlignment = Enum.TextXAlignment.Left

        local nearestBrainrotName = plr:GetAttribute("StealingIndex")
        
        local stealing = plr:GetAttribute("Stealing")
        if stealing then
            if nearestBrainrotName then
                uName.Text = nearestBrainrotName
                uName.TextColor3 = Color3.fromRGB(255, 200, 0)
                uName.Font = Enum.Font.GothamBlack
                uName.TextSize = 14
            else
                uName.Text = "STEALING"
                uName.TextColor3 = Color3.fromRGB(255, 150, 0)
                uName.Font = Enum.Font.GothamBlack
                uName.TextSize = 14
            end
        end
        
        task.spawn(function()
            while row.Parent do
                task.wait(0.5)
                
                if not plr or not plr.Parent or not Players:FindFirstChild(plr.Name) then
                    removePlayer(plr)
                    break
                end
                
                local stealing = plr:GetAttribute("Stealing")
                nearestBrainrotName = plr:GetAttribute("StealingIndex")
                
                if stealing then
                    if nearestBrainrotName then
                        uName.Text = nearestBrainrotName
                        uName.TextColor3 = Color3.fromRGB(255, 200, 0)
                        uName.Font = Enum.Font.GothamBold
                        uName.TextSize = 11
                    else
                        uName.Text = "⚠️ STEALING"
                        uName.TextColor3 = Color3.fromRGB(255, 150, 0)
                        uName.Font = Enum.Font.GothamBold
                        uName.TextSize = 11
                    end
                else
                    uName.Text = "(@" .. plr.Name .. ")"
                    uName.TextColor3 = Theme.TextSecondary
                    uName.Font = Enum.Font.GothamMedium
                    uName.TextSize = 7
                    nearestBrainrotName = nil
                end
            end
        end)

        local btnCont = Instance.new("Frame", row)
        btnCont.Size = UDim2.new(0, 140, 1, 0)
        btnCont.Position = UDim2.new(1, -145, 0, 0)
        btnCont.BackgroundTransparency = 1
        btnCont.ZIndex = 10

       local buttonsDef = {
            {icon = "🚀", cmd = "rocket"},
            {icon = "🏃", cmd = "ragdoll"},
            {icon = "🔒", cmd = "jail"},
            {icon = "🎈", cmd = "balloon"}
        }

        for i, def in ipairs(buttonsDef) do
            local cmdColors = {
    rocket  = Color3.fromRGB(245, 158, 11),
    ragdoll = Color3.fromRGB(219, 39, 119),
    jail    = Color3.fromRGB(239, 68, 68),
    balloon = Color3.fromRGB(124, 58, 237),
}
local cmdColor = cmdColors[def.cmd] or Theme.Accent1

local b = Instance.new("TextButton", btnCont)
b.Size = UDim2.new(0, 30, 0, 30)
b.Position = UDim2.new(0, (i-1)*34, 0.5, -15)
b.AutoButtonColor = false
b.Text = def.icon
b.TextSize = 18
b.TextColor3 = Theme.TextPrimary
b.Font = Enum.Font.Gotham
b.ZIndex = 11
b.Active = true
local hasBallooned = SharedState.BalloonedPlayers and next(SharedState.BalloonedPlayers) ~= nil
local isOnCD = isOnCooldown(def.cmd)
b.BackgroundColor3 = isOnCD and Color3.fromRGB(
    math.floor(Theme.Error.R*255*0.3),
    math.floor(Theme.Error.G*255*0.3),
    math.floor(Theme.Error.B*255*0.3)
) or Color3.fromRGB(
    math.floor(cmdColor.R*255*0.15),
    math.floor(cmdColor.G*255*0.15),
    math.floor(cmdColor.B*255*0.15)
)
b.BackgroundTransparency = 0
Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
local bStroke = Instance.new("UIStroke", b)
bStroke.Color = isOnCD and Theme.Error or cmdColor
bStroke.Thickness = 1.5
bStroke.Transparency = 0.3
bStroke.ZIndex = 12

b.MouseEnter:Connect(function()
    if not isOnCooldown(def.cmd) then
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(
            math.floor(cmdColor.R*255*0.3),
            math.floor(cmdColor.G*255*0.3),
            math.floor(cmdColor.B*255*0.3)
        )}):Play()
        TweenService:Create(bStroke, TweenInfo.new(0.15), {Transparency = 0}):Play()
    end
end)
b.MouseLeave:Connect(function()
    if not isOnCooldown(def.cmd) then
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(
            math.floor(cmdColor.R*255*0.15),
            math.floor(cmdColor.G*255*0.15),
            math.floor(cmdColor.B*255*0.15)
        )}):Play()
        TweenService:Create(bStroke, TweenInfo.new(0.15), {Transparency = 0.3}):Play()
    end
end)
            
            b.MouseEnter:Connect(function()
                if not isOnCD and not (def.cmd == "balloon" and hasBallooned) then
                    b.BackgroundColor3 = Color3.fromRGB(45, 47, 53)
                    bStroke.Transparency = 0.2
                end
            end)
            b.MouseLeave:Connect(function()
                if not isOnCD and not (def.cmd == "balloon" and hasBallooned) then
                    b.BackgroundColor3 = Color3.fromRGB(35, 37, 43)
                    bStroke.Transparency = 0.4
                end
            end)
            
            if not SharedState.AdminButtonCache[def.cmd] then SharedState.AdminButtonCache[def.cmd] = {} end
            table.insert(SharedState.AdminButtonCache[def.cmd], b)

            task.spawn(function()
                while b and b.Parent do
                    task.wait(0.05)
                    if not b.Text or b.Text == "" or b.Text == "BUTTON" or b.Text == "Button" then
                        b.Text = def.icon
                        b.TextSize = 18
                        b.TextColor3 = Theme.TextPrimary
                        b.Font = Enum.Font.GothamBold
                    end
                    local cd = isOnCooldown(def.cmd)
                    local balloon = (def.cmd == "balloon" and SharedState.BalloonedPlayers and next(SharedState.BalloonedPlayers) ~= nil)
                    if cd or balloon then
                        b.BackgroundColor3 = Theme.Error
                        b.BackgroundTransparency = 0
                        bStroke.Color = Theme.Error
                        bStroke.Transparency = 0.2
                        if b.Text ~= def.icon then
                            b.Text = def.icon
                            b.TextSize = 18
                            b.TextColor3 = Theme.TextPrimary
                            b.Font = Enum.Font.GothamBold
                        end
                    elseif not cd and not balloon then
                        b.BackgroundColor3 = Color3.fromRGB(35, 37, 43)
                        b.BackgroundTransparency = 0
                        bStroke.Color = Theme.Accent1
                        bStroke.Transparency = 0.4
                        if b.Text ~= def.icon then
                            b.Text = def.icon
                            b.TextSize = 18
                            b.TextColor3 = Theme.TextPrimary
                            b.Font = Enum.Font.GothamBold
                        end
                    end
                end
            end)

            b.MouseButton1Click:Connect(function()
                if def.special and def.cmd == "spambaseowner" then
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    
                    local closestPlot = nil
                    local closestDist = math.huge
                    
                    local plots = Workspace:FindFirstChild("Plots")
                    if plots then
                        for _, plot in ipairs(plots:GetChildren()) do
                            local plotPos = plot:FindFirstChild("Base") and plot.Base:FindFirstChild("Spawn")
                            if plotPos then
                                local dist = (hrp.Position - plotPos.Position).Magnitude
                                if dist < closestDist then
                                    closestDist = dist
                                    closestPlot = plot
                                end
                            end
                        end
                    end
                    
                    if closestPlot then
                        task.spawn(function()
                            local Packages = ReplicatedStorage:WaitForChild("Packages")
                            local Synchronizer = require(Packages:WaitForChild("Synchronizer"))
                            local channel = Synchronizer:Get(closestPlot.Name)
                            if channel then
                                local owner = channel:Get("Owner")
                                local targetPlayer = nil
                                if typeof(owner) == "Instance" and owner:IsA("Player") then
                                    targetPlayer = owner
                                elseif typeof(owner) == "table" and owner.UserId then
                                    targetPlayer = Players:GetPlayerByUserId(owner.UserId)
                                end
                                
                                if targetPlayer and targetPlayer ~= LocalPlayer then
                                    local hasAnyAvailable = false
                                    for _, cmd in ipairs(ALL_COMMANDS) do
                                        if not isOnCooldown(cmd) then
                                            hasAnyAvailable = true
                                            break
                                        end
                                    end
                                    if hasAnyAvailable then
                                        triggerAll(targetPlayer)
                                        ShowNotification("AP SPAM", "Spamming " .. targetPlayer.Name)
                                    else
                                        ShowNotification("AP SPAM", "All commands on cooldown")
                                    end
                                else
                                    ShowNotification("AP SPAM", "No owner found")
                                end
                            end
                        end)
                    end
                else
                    ShowNotification("ADMIN", "Attempting " .. def.cmd .. " on " .. plr.Name)
                    if runAdminCommand(plr, def.cmd) then
                        activeCooldowns[def.cmd] = tick()
                        setGlobalVisualCooldown(def.cmd)
                        if def.cmd == "balloon" then
                            SharedState.BalloonedPlayers[plr.UserId] = true
                            for _, btn in ipairs(SharedState.AdminButtonCache["balloon"] or {}) do
                                if btn and btn.Parent then btn.BackgroundColor3 = Theme.Error end
                            end
                        end
                        ShowNotification("ADMIN", "Sent " .. def.cmd .. " to " .. plr.Name)
                    else
                        ShowNotification("ADMIN", "Failed to send " .. def.cmd .. " to " .. plr.Name)
                    end
                end
            end)
        end

        local rowHighlight = Instance.new("Frame", row)
        rowHighlight.Size = UDim2.new(1, 0, 1, 0)
        rowHighlight.BackgroundColor3 = Theme.Accent1
        rowHighlight.BackgroundTransparency = 1
        rowHighlight.BorderSizePixel = 0
        rowHighlight.ZIndex = 1
        Instance.new("UICorner", rowHighlight).CornerRadius = UDim.new(0, 6)
        row.MouseEnter:Connect(function()
    TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(18, 10, 45)}):Play()
    TweenService:Create(rowStroke, TweenInfo.new(0.15), {Transparency = 0.2, Color = Color3.fromRGB(124, 58, 237)}):Play()
    TweenService:Create(rowAccent, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(219, 39, 119)}):Play()
end)
        row.MouseLeave:Connect(function()
    TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(8, 5, 22)}):Play()
    TweenService:Create(rowStroke, TweenInfo.new(0.15), {Transparency = 0.6, Color = Color3.fromRGB(124, 58, 237)}):Play()
    TweenService:Create(rowAccent, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(124, 58, 237)}):Play()
end)
        row.MouseButton1Click:Connect(function()
            local hasAnyAvailable = false
            for _, cmd in ipairs(ALL_COMMANDS) do
                if not isOnCooldown(cmd) then
                    hasAnyAvailable = true
                    break
                end
            end
            if hasAnyAvailable then
                triggerAll(plr)
                ShowNotification("ADMIN", "Triggered ALL on " .. plr.Name)
            end
        end)
        return row
    end

    local playerRows = {}
    local playerRowsByUserId = {}
    
    local function addPlayer(plr)
        if plr == LocalPlayer or playerRowsByUserId[plr.UserId] then return end
        if not Players:FindFirstChild(plr.Name) then return end
        if Config.HideKawaifuFromPanel and isKawaifuUser(plr) then return end
        
        if playerRows[plr] then return end
        
        local row = createPlayerRow(plr)
        playerRows[plr] = row
        playerRowsByUserId[plr.UserId] = {player = plr, row = row}
        listFrame.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y)
        sortAdminPanelList()
    end
    
    local function removePlayer(plr)
        local userId = plr and plr.UserId or nil
        local entry = userId and playerRowsByUserId[userId] or nil
        local row = entry and entry.row or playerRows[plr]
        
        if row then
            if row.Parent then
                for cmd, buttons in pairs(SharedState.AdminButtonCache) do
                    for i = #buttons, 1, -1 do
                        if buttons[i] and buttons[i].Parent == row then
                            table.remove(buttons, i)
                        end
                    end
                end
                row:Destroy()
            end
            if plr then
                playerRows[plr] = nil
            end
            if userId then
                playerRowsByUserId[userId] = nil
            end
            if SharedState.BalloonedPlayers and userId then
                SharedState.BalloonedPlayers[userId] = nil
            end
            listFrame.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y)
        end
    end

    refreshBtn.MouseButton1Click:Connect(function()
        for _, row in pairs(playerRows) do
            if row and row.Parent then
                for cmd, buttons in pairs(SharedState.AdminButtonCache) do
                    for i = #buttons, 1, -1 do
                        if buttons[i] and buttons[i].Parent == row then
                            table.remove(buttons, i)
                        end
                    end
                end
                row:Destroy()
            end
        end
        
        playerRows = {}
        playerRowsByUserId = {}
        SharedState.AdminButtonCache = {}
        SharedState.BalloonedPlayers = {}
        
        for _, child in ipairs(listFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        task.wait(0.1)
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then 
                addPlayer(p) 
            end
        end
        sortAdminPanelList()
        
        ShowNotification("ADMIN PANEL", "Completely refreshed - " .. #Players:GetPlayers() - 1 .. " players found")
    end)

    Players.PlayerAdded:Connect(function(plr)
        task.wait(0.1)
        if plr and plr.Parent then
            addPlayer(plr)
        end
    end)
    
    Players.PlayerRemoving:Connect(function(plr)
        removePlayer(plr)
    end)
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then addPlayer(p) end
    end
    sortAdminPanelList()

    task.spawn(function()
        while listFrame and listFrame.Parent do
            task.wait(0.5)
            pcall(sortAdminPanelList)
        end
    end)
    
    task.spawn(function()
        while true do
            task.wait(1)
            local currentPlayerIds = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Parent then
                    currentPlayerIds[p.UserId] = true
                end
            end
            
            for userId, entry in pairs(playerRowsByUserId) do
                if not currentPlayerIds[userId] or not entry.player or not entry.player.Parent or not Players:FindFirstChild(entry.player.Name) then
                    removePlayer(entry.player)
                end
            end
            
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Parent and not playerRowsByUserId[p.UserId] then
                    addPlayer(p)
                end
            end
        end
    end)

	-- Resize handle
local resizeHandle = Instance.new("TextButton", frame)
resizeHandle.Size = UDim2.new(0, 18, 0, 18)
resizeHandle.Position = UDim2.new(1, -20, 1, -20)
resizeHandle.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
resizeHandle.BackgroundTransparency = 0.4
resizeHandle.Text = "⤡"
resizeHandle.Font = Enum.Font.GothamBlack
resizeHandle.TextSize = 12
resizeHandle.TextColor3 = Color3.fromRGB(200, 180, 255)
resizeHandle.AutoButtonColor = false
resizeHandle.ZIndex = 20
Instance.new("UICorner", resizeHandle).CornerRadius = UDim.new(0, 5)

local resizing = false
local resizeStart = Vector2.new()
local sizeStart = Vector2.new()

resizeHandle.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        resizing = true
        resizeStart = Vector2.new(inp.Position.X, inp.Position.Y)
        sizeStart = Vector2.new(frame.AbsoluteSize.X, frame.AbsoluteSize.Y)
    end
end)	
    
    layout.Changed:Connect(function() listFrame.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y) end)
end)

UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        resizing = false
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if resizing and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = Vector2.new(inp.Position.X, inp.Position.Y) - resizeStart
        local newW = math.clamp(sizeStart.X + delta.X, 300, 700)
        local newH = math.clamp(sizeStart.Y + delta.Y, 350, 900)
        frame.Size = UDim2.new(0, newW, 0, newH)
        -- Keep list filling remaining space
        listFrame.Size = UDim2.new(1, -20, 1, -220)
        resizeHandle.Position = UDim2.new(1, -20, 1, -20)
    end
end)

local BASES_LOW = {
    [1] = Vector3.new(-460, -6, 219), [5] = Vector3.new(-355, -6, 217),
    [2] = Vector3.new(-460, -6, 111), [6] = Vector3.new(-355, -6, 113),
    [3] = Vector3.new(-460, -6, 5),   [7] = Vector3.new(-355, -6, 5),
    [4] = Vector3.new(-460, -6, -100),[8] = Vector3.new(-355, -6, -100) 
}

local BASES_HIGH = {
    [1] = Vector3.new(-476.474853515625, 20.732906341552734, 220.94090270996094), [5] = Vector3.new(-342.5367126464844, 20.69801902770996, 221.44737243652344),
    [2] = Vector3.new(-476.5684814453125, 20.70664405822754, 113.77315521240234), [6] = Vector3.new(-342.8604736328125, 20.669641494750977, 113.41409301757812),
    [3] = Vector3.new(-476.8675842285156, 20.74148178100586, 6.178487777709961),  [7] = Vector3.new(-342.42108154296875, 20.687667846679688, 6.249461650848389),
    [4] = Vector3.new(-476.6324768066406, 20.744949340820312, -101.07275390625), [8] = Vector3.new(-342.7937927246094, 20.748071670532227, -99.73458862304688)
}

local CLONE_POSITIONS_FLOOR = {
    Vector3.new(-476, -4, 221), Vector3.new(-476, -4, 114),
    Vector3.new(-476, -4, 7),   Vector3.new(-476, -4, -100),
    Vector3.new(-342, -4, -100),Vector3.new(-342, -4, 6),
    Vector3.new(-342, -4, 114), Vector3.new(-342, -4, 220)
}

local FACE_TARGETS = {
    Vector3.new(-519, -3, 221), Vector3.new(-519, -3, 114),
    Vector3.new(-518, -3, 7),   Vector3.new(-519, -3, -100),
    Vector3.new(-301, -3, -100),Vector3.new(-301, -3, 7),
    Vector3.new(-302, -3, 114), Vector3.new(-300, -3, 220)
}

local TeleportData = {
    bodyController = nil,
}
local bodyController = TeleportData.bodyController
local floatActive = State.floatActive

RunService.Heartbeat:Connect(function()
    if State.floatActive and TeleportData.bodyController and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then TeleportData.bodyController.Position = Vector3.new(hrp.Position.X, TeleportData.bodyController.Position.Y, TeleportData.bodyController.Position.Z) end
    end
end)

local function getClosestBaseIdx(pos)
    local closest, dist = 1, math.huge
    for i, basePos in pairs(BASES_LOW) do
        local d = (Vector2.new(pos.X, pos.Z) - Vector2.new(basePos.X, basePos.Z)).Magnitude
        if d < dist then dist = d; closest = i end
    end
    return closest
end

local isTpMoving = State.isTpMoving

_G._isTargetPlotUnlocked = function(plotName)
    local ok, res = pcall(function()
        local plots = Workspace:FindFirstChild("Plots")
        if not plots then return false end
        local targetPlot = plots:FindFirstChild(plotName)
        if not targetPlot then return false end
        local unlockFolder = targetPlot:FindFirstChild("Unlock")
        if not unlockFolder then return true end
        local unlockItems = {}
        for _, item in pairs(unlockFolder:GetChildren()) do
            local pos = nil
            if item:IsA("Model") then pcall(function() pos = item:GetPivot().Position end)
            elseif item:IsA("BasePart") then pos = item.Position end
            if pos then table.insert(unlockItems, {Object = item, Height = pos.Y}) end
        end
        table.sort(unlockItems, function(a, b) return a.Height < b.Height end)
        if #unlockItems == 0 then return true end
        local floor1Door = unlockItems[1].Object
        for _, desc in ipairs(floor1Door:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled then return false end
        end
        for _, child in ipairs(floor1Door:GetChildren()) do
            if child:IsA("ProximityPrompt") and child.Enabled then return false end
        end
        return true
    end)
    return ok and res or false
end

local function runAutoSnipe()
    if State.isTpMoving then return end
    
    if State.carpetSpeedEnabled then
        setCarpetSpeed(false)
        if _carpetStatusLabel then
            _carpetStatusLabel.Text = "OFF"
            _carpetStatusLabel.TextColor3 = Theme.Error
        end
    end

    local targetPetData = nil
    if Config.AutoTPPriority then
        local bestEntry = nil
        local cache = SharedState.AllAnimalsCache
        if cache and type(cache) == "table" then
            for _, pName in ipairs(PRIORITY_LIST) do
                local searchName = pName:lower()
                for _, a in ipairs(cache) do
                    if a and a.name and a.name:lower() == searchName and a.owner ~= LocalPlayer.Name then
                        bestEntry = a
                        break
                    end
                end
                if bestEntry then break end
            end
            if not bestEntry then
                for _, a in ipairs(cache) do
                    if a and a.owner ~= LocalPlayer.Name then
                        bestEntry = a
                        break
                    end
                end
            end
        end
        if bestEntry then
            targetPetData = bestEntry
        else
            if not SharedState.SelectedPetData then ShowNotification("ERROR","No target selected!"); return end
            targetPetData = SharedState.SelectedPetData.animalData
        end
    else
        if not SharedState.SelectedPetData then ShowNotification("ERROR","No target selected!"); return end
        targetPetData = SharedState.SelectedPetData.animalData
    end
    if not targetPetData then return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    
    if not hrp or not hum or hum.Health <= 0 then return end
    
    State.isTpMoving = true
    isTpMoving = State.isTpMoving
    
    local targetPart = findAdorneeGlobal(targetPetData)
    if not targetPart then 
        State.isTpMoving = false
        isTpMoving = State.isTpMoving
        return 
    end
    
    local exactPos = targetPart.Position
    local carpetName = Config.TpSettings.Tool
    local carpet = LocalPlayer.Backpack:FindFirstChild(carpetName) or char:FindFirstChild(carpetName)
    local cloner = LocalPlayer.Backpack:FindFirstChild("Quantum Cloner") or char:FindFirstChild("Quantum Cloner")

    if carpet then hum:EquipTool(carpet) end
    task.wait(0.01)
    local isSecondFloor = exactPos.Y > 10
    local plotIndex = getClosestBaseIdx(exactPos)
    local targetBasePos = isSecondFloor and BASES_HIGH[plotIndex] or BASES_LOW[plotIndex]
    
    local minHeight = 50
    local targetHeight = math.max(targetBasePos.Y, minHeight)

    local jumpStart = tick()
    while hrp.Position.Y < targetHeight and (tick() - jumpStart) < 3 do
        hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 200, hrp.AssemblyLinearVelocity.Z)
        RunService.Heartbeat:Wait()
    end

    for i = 1, 10 do
        hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
        if (hrp.Position - targetBasePos).Magnitude > 3 then
            hrp.CFrame = CFrame.new(targetBasePos)
            task.wait(0.05)
        end
    end

    if not isSecondFloor then
        local bestSpot = CLONE_POSITIONS_FLOOR[1]
        local minDst = math.huge
        for _, v in ipairs(CLONE_POSITIONS_FLOOR) do
            local d = (targetPart.Position - v).Magnitude
            if d < minDst then minDst = d; bestSpot = v end
        end
        for i = 1, 6 do
            if (hrp.Position - bestSpot).Magnitude > 3 then
                hrp.CFrame = CFrame.new(bestSpot)
                task.wait(0.05)
            end
        end
    end

    local bestFace = FACE_TARGETS[1]
    local minFaceDist = math.huge
    for _, v in ipairs(FACE_TARGETS) do
        local d = (hrp.Position - v).Magnitude
        if d < minFaceDist then
            minFaceDist = d
            bestFace = v
        end
    end

    task.wait(0.1)
    hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(bestFace.X, hrp.Position.Y, bestFace.Z))
    if isSecondFloor or not _G._isTargetPlotUnlocked(targetPetData.plot) then
        walkForward(0.4)
        task.wait(0.4)
        instantClone()
        while _G.isCloning do task.wait() end
    end
    task.wait(0.15)

    if carpet then hum:EquipTool(carpet) end

    local verticalDiff = targetPart.Position.Y - hrp.Position.Y

    if verticalDiff > 2 then
        local airPos = Vector3.new(targetPart.Position.X, targetPart.Position.Y - 8, targetPart.Position.Z)
        
        local plat = Instance.new("Part")
        plat.Name = "XiTempPlatform"
        plat.Size = Vector3.new(3, 1, 3)
        plat.Position = airPos - Vector3.new(0, 5, 0)
        plat.Color = Color3.new(1, 0, 0)
        plat.Material = Enum.Material.Neon
        plat.Anchored = true
        plat.CanCollide = true
        plat.Transparency = 0.3
        plat.Parent = Workspace
        
        RunService.Heartbeat:Wait()
        
        for i = 1, 10 do
            if not LocalPlayer:GetAttribute("Stealing") then
                hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
                hrp.CFrame = CFrame.new(airPos)
                task.wait(0.05)
            end
        end
        
        task.spawn(function()
            local start = tick()
            while tick() - start < 20 do
                if LocalPlayer:GetAttribute("Stealing") then break end
                task.wait(0.1)
            end
            plat:Destroy()
        end)
    else
        for i = 1, 10 do
            if LocalPlayer:GetAttribute("Stealing") then break end
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
            if (hrp.Position - targetPart.Position).Magnitude > 3 then
                hrp.CFrame = CFrame.new(targetPart.Position)
                task.wait(0.05)
            end
            task.wait(0.05)
        end
    end
    
    State.isTpMoving = false
    isTpMoving = State.isTpMoving
end

local function executeReset()
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart or not humanoid then return end

    -- Method 1: Kill health instantly (most reliable)
    pcall(function()
        if _G.AntiDieDisabled ~= nil then
            _G.AntiDieDisabled = true
        end
        if _G.AntiDieConnection then
            pcall(function() _G.AntiDieConnection:Disconnect() end)
            _G.AntiDieConnection = nil
        end
    end)

    -- Method 2: Teleport extremely far and zero velocity
    rootPart.CFrame = CFrame.new(0, 999999, 0)
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero

    -- Method 3: Set health to 0
    pcall(function()
        humanoid.Health = 0
    end)

    -- Method 4: Backup using StarterGui reset (works on most executors)
    task.spawn(function()
        pcall(function()
            local StarterGui = game:GetService("StarterGui")
            StarterGui:SetCore("ResetButtonCallback", true)
        end)
    end)

    -- Re-enable anti-die after respawn
    local charConn
    charConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
        charConn:Disconnect()
        task.wait(0.5)
        pcall(function()
            _G.AntiDieDisabled = false
            if _G.setupAntiDie then
                _G.setupAntiDie()
            end
        end)
    end)

    -- Fallback timeout: re-enable after 5s no matter what
    task.delay(5, function()
        pcall(function()
            _G.AntiDieDisabled = false
            if _G.setupAntiDie then
                _G.setupAntiDie()
            end
        end)
    end)
end

task.spawn(function()
    local balloonPhrase = 'ran "balloon" on you'
    while true do
        task.wait(1)
        if not Config.AutoResetOnBalloon then continue end
        for _, gui in ipairs(PlayerGui:GetDescendants()) do
            local txt = (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Text
            if txt and string.find(txt, balloonPhrase) then
                executeReset()
                break
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if not Config.AutoKickOnSteal then continue end
        for _, gui in ipairs(PlayerGui:GetDescendants()) do
            local txt = (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Text
            if txt and string.find(txt, "You stole") then
                kickPlayer()
                return
            end
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    local tpKey = Enum.KeyCode[Config.TpSettings.TpKey] or Enum.KeyCode.T
    local cloneKey = Enum.KeyCode[Config.TpSettings.CloneKey] or Enum.KeyCode.V

    if input.KeyCode == tpKey then
        runAutoSnipe()
    end

    if input.KeyCode == cloneKey then
        instantClone()
    end
    
    if input.KeyCode == (Enum.KeyCode[Config.TpSettings.CarpetSpeedKey] or Enum.KeyCode.Q) then
        carpetSpeedEnabled = not carpetSpeedEnabled
        setCarpetSpeed(carpetSpeedEnabled)
        if _carpetStatusLabel then
            _carpetStatusLabel.Text = carpetSpeedEnabled and "ON" or "OFF"
            _carpetStatusLabel.TextColor3 = carpetSpeedEnabled and Theme.Success or Theme.Error
        end
        ShowNotification("CARPET SPEED", carpetSpeedEnabled and ("ON  |  "..Config.TpSettings.Tool.."  |  140") or "OFF")
    end

    if input.KeyCode == (Enum.KeyCode[Config.StealSpeedKey] or Enum.KeyCode.Z) then
        if SharedState.StealSpeedToggleFunc then
            SharedState.StealSpeedToggleFunc()
        end
    end

    if input.KeyCode == (Enum.KeyCode[Config.ResetKey] or Enum.KeyCode.X) then
        executeReset()
    end
    
    if input.KeyCode == (Enum.KeyCode[Config.RagdollSelfKey] or Enum.KeyCode.R) then
        task.spawn(function()
            if _G.runAdminCommand then
                if _G.runAdminCommand(LocalPlayer, "ragdoll") then
                    ShowNotification("RAGDOLL SELF", "Triggered")
                else
                    ShowNotification("RAGDOLL SELF", "Failed")
                end
            else
                ShowNotification("RAGDOLL SELF", "Function not available")
            end
        end)
    end

end)

local settingsGui = UI.settingsGui

if IS_MOBILE then
    local mobileGui = Instance.new("ScreenGui")
    mobileGui.Name = "XiMobileControls"
    mobileGui.ResetOnSpawn = false
    mobileGui.Parent = PlayerGui

    local controlsFrame = Instance.new("Frame")
    controlsFrame.Size = UDim2.new(0, 50, 0, 260)
    controlsFrame.Position = UDim2.new(1, -60, 0.5, -130)
    controlsFrame.BackgroundColor3 = Theme.Background
    controlsFrame.BackgroundTransparency = 0.2
    controlsFrame.BorderSizePixel = 0
    controlsFrame.Parent = mobileGui

    ApplyViewportUIScale(controlsFrame, 50, 260, 0.6, 1)

    Instance.new("UICorner", controlsFrame).CornerRadius = UDim.new(0, 10)
    local cStroke = Instance.new("UIStroke", controlsFrame)
    cStroke.Color = Theme.Accent1
    cStroke.Thickness = 1.5
    cStroke.Transparency = 0.4

    MakeDraggable(controlsFrame, controlsFrame, "MobileControls")

    local layout = Instance.new("UIListLayout", controlsFrame)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center

    local function createMobBtn(text, color, layoutOrder, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 40, 0, 40)
        btn.BackgroundColor3 = Theme.SurfaceHighlight
        btn.Text = text
        btn.TextColor3 = Theme.TextPrimary
        btn.Font = Enum.Font.GothamBlack
        btn.TextSize = 14
        btn.LayoutOrder = layoutOrder
        btn.Parent = mobileGui 
        
        local posKey = "MobileBtn_" .. text
        if Config.Positions[posKey] then
            btn.Position = UDim2.new(Config.Positions[posKey].X, 0, Config.Positions[posKey].Y, 0)
        else
            local angle = (layoutOrder - 1) * (math.pi * 2 / 5) - math.pi/2
            local radius = 60
            btn.Position = UDim2.new(0.5, math.cos(angle) * radius - 20, 0.5, math.sin(angle) * radius - 20)
        end

        Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = color
        stroke.Thickness = 1
        stroke.Transparency = 1

        MakeDraggable(btn, btn, "MobileBtn_" .. text)

        btn.MouseButton1Click:Connect(function()
            local oldColor = btn.BackgroundColor3
            btn.BackgroundColor3 = color
            task.delay(0.1, function() btn.BackgroundColor3 = oldColor end)
            callback(btn)
        end)
        return btn
    end

    createMobBtn("TP", Theme.Accent1, 1, function()
        
        if SharedState.ForcePrioritySelection then
            SharedState.ForcePrioritySelection()
            task.wait(0.1) 
        end
        runAutoSnipe()
        ShowNotification("MOBILE", "Teleporting...")
    end)

    createMobBtn("CL", Theme.Accent2, 2, function()
        instantClone()
        ShowNotification("MOBILE", "Cloning...")
    end)

    createMobBtn("SP", Theme.Success, 3, function(self)
        carpetSpeedEnabled = not carpetSpeedEnabled
        setCarpetSpeed(carpetSpeedEnabled)
        self.TextColor3 = carpetSpeedEnabled and Theme.Success or Theme.TextPrimary
        ShowNotification("MOBILE", carpetSpeedEnabled and "Speed ON" or "Speed OFF")
    end)

    createMobBtn("IV", Color3.fromRGB(255, 50, 50), 4, function(self)
        if _G.toggleInvisibleSteal then
            _G.toggleInvisibleSteal()
            task.delay(0.1, function()
                local isOn = _G.invisibleStealEnabled
                self.TextColor3 = isOn and Color3.fromRGB(255, 0, 0) or Theme.TextPrimary
                ShowNotification("MOBILE", isOn and "Invis ON" or "Invis OFF")
            end)
        end
    end)

    createMobBtn("UI", Color3.fromRGB(255, 255, 255), 5, function()
        local asUI = PlayerGui:FindFirstChild("AutoStealUI")
        if asUI then asUI.Enabled = not asUI.Enabled end

        local adUI = PlayerGui:FindFirstChild("XiAdminPanel")
        if adUI then adUI.Enabled = not adUI.Enabled end
    end)

    local resetBtn = Instance.new("TextButton")
    resetBtn.Name = "MobileResetButton"
    resetBtn.Size = UDim2.new(0, 42, 0, 42)
    resetBtn.Position = UDim2.new(1, -58, 1, -105)
    resetBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
    resetBtn.AutoButtonColor = false
    resetBtn.Text = "🔧"
    resetBtn.Font = Enum.Font.GothamBlack
    resetBtn.TextSize = 20
    resetBtn.TextColor3 = Color3.new(0, 0, 0)
    resetBtn.Parent = mobileGui
    Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(1, 0)
    local resetStroke = Instance.new("UIStroke", resetBtn)
    resetStroke.Color = Color3.fromRGB(255, 100, 0)
    resetStroke.Thickness = 1.5
    resetStroke.Transparency = 0.25

    MakeDraggable(resetBtn, resetBtn)

    resetBtn.MouseButton1Click:Connect(function()
        Config.Positions = {
            AdminPanel = {X = 0.1859375, Y = 0.5767123526556385}, 
            StealSpeed = {X = 0.02, Y = 0.18}, 
            Settings = {X = 0.834375, Y = 0.43590998043052839}, 
            InvisPanel = {X = 0.8578125, Y = 0.17260276361454258}, 
            AutoSteal = {X = 0.02, Y = 0.35}, 
            MobileControls = {X = 0.9, Y = 0.4},
            MobileBtn_TP = {X = 0.5, Y = 0.4},
            MobileBtn_CL = {X = 0.5, Y = 0.4},
            MobileBtn_SP = {X = 0.5, Y = 0.4},
            MobileBtn_IV = {X = 0.5, Y = 0.4},
            MobileBtn_UI = {X = 0.5, Y = 0.4},
        }
        Config.MobileGuiScale = 0.5
        SaveConfig()
        
        if SharedState.RefreshMobileScale then SharedState.RefreshMobileScale() end
        
        if mobileGui then
            mobileGui.Position = UDim2.new(Config.Positions.MobileControls.X, 0, Config.Positions.MobileControls.Y, 0)
        end
        
        ShowNotification("RESET", "All GUI positions and scale reset")
    end)

    local openBtn = Instance.new("TextButton")
    openBtn.Name = "MobileSettingsButton"
    openBtn.Size = UDim2.new(0, 42, 0, 42)
    openBtn.Position = UDim2.new(1, -58, 1, -58)
    openBtn.BackgroundColor3 = Theme.Accent1
    openBtn.AutoButtonColor = false
    openBtn.Text = "⚙"
    openBtn.Font = Enum.Font.GothamBlack
    openBtn.TextSize = 20
    openBtn.TextColor3 = Color3.new(0, 0, 0)
    openBtn.Parent = mobileGui
    Instance.new("UICorner", openBtn).CornerRadius = UDim.new(1, 0)
    local openStroke = Instance.new("UIStroke", openBtn)
    openStroke.Color = Theme.Accent2
    openStroke.Thickness = 1.5
    openStroke.Transparency = 0.25

    MakeDraggable(openBtn, openBtn)

    openBtn.MouseButton1Click:Connect(function()
        if settingsGui then
            settingsGui.Enabled = not settingsGui.Enabled
        end
        if SharedState.RefreshMobileScale then
            SharedState.RefreshMobileScale()
        end
    end)
end

settingsGui = Instance.new("ScreenGui")
settingsGui.Name = "SettingsUI"
settingsGui.ResetOnSpawn = false
settingsGui.Parent = PlayerGui
settingsGui.Enabled = true
 
-- Root frame
local sFrame = Instance.new("Frame")
sFrame.Name = "sFrame"
sFrame.Size = UDim2.new(0, 330, 0, 540)
sFrame.Position = UDim2.new(Config.Positions.Settings.X, 0, Config.Positions.Settings.Y, 0)
sFrame.BackgroundColor3 = Color3.fromRGB(8, 6, 22)
sFrame.BackgroundTransparency = 0.04
sFrame.BorderSizePixel = 0
sFrame.ClipsDescendants = true
sFrame.Parent = settingsGui
Instance.new("UICorner", sFrame).CornerRadius = UDim.new(0, 14)
 
ApplyViewportUIScale(sFrame, 330, 540, 0.45, 0.85)
AddMobileMinimize(sFrame, "SETTINGS")
 
local sStroke = Instance.new("UIStroke", sFrame)
sStroke.Color = Theme.Accent2; sStroke.Thickness = 1.5; sStroke.Transparency = 0.4
CreateGradient(sStroke)
 
-- Header bar (drag handle + title)
local sHeader = Instance.new("Frame", sFrame)
sHeader.Size = UDim2.new(1, 0, 0, 44)
sHeader.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
sHeader.BackgroundTransparency = 0.86
sHeader.BorderSizePixel = 0
MakeDraggable(sHeader, sFrame, "Settings")
 
local sHeaderGrad = Instance.new("UIGradient", sHeader)
sHeaderGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(124,58,237)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(219,39,119))
}
sHeaderGrad.Transparency = NumberSequence.new{
    NumberSequenceKeypoint.new(0, 0.76),
    NumberSequenceKeypoint.new(1, 0.91)
}
 
local sTitle = Instance.new("TextLabel", sHeader)
sTitle.Size = UDim2.new(0.6, 0, 1, 0)
sTitle.Position = UDim2.new(0, 14, 0, 0)
sTitle.BackgroundTransparency = 1
sTitle.Text = "Settings"
sTitle.Font = Enum.Font.GothamBlack
sTitle.TextSize = 15
sTitle.TextColor3 = Color3.fromRGB(200, 180, 255)
sTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Close button for settings
local sCloseBtn = Instance.new("TextButton", sHeader)
sCloseBtn.Size = UDim2.new(0, 28, 0, 28)
sCloseBtn.Position = UDim2.new(1, -34, 0.5, -14)
sCloseBtn.BackgroundColor3 = Color3.fromRGB(219, 39, 119)
sCloseBtn.BackgroundTransparency = 0.3
sCloseBtn.Text = "X"
sCloseBtn.Font = Enum.Font.GothamBlack
sCloseBtn.TextSize = 14
sCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sCloseBtn.AutoButtonColor = false
Instance.new("UICorner", sCloseBtn).CornerRadius = UDim.new(0, 6)
local sCloseBtnStroke = Instance.new("UIStroke", sCloseBtn)
sCloseBtnStroke.Color = Color3.fromRGB(219, 39, 119)
sCloseBtnStroke.Thickness = 1
sCloseBtnStroke.Transparency = 0.3
sCloseBtn.MouseEnter:Connect(function()
    TweenService:Create(sCloseBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
end)
sCloseBtn.MouseLeave:Connect(function()
    TweenService:Create(sCloseBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
end)

-- Restore button (floats when settings is hidden)
local sRestoreBtn = Instance.new("TextButton", settingsGui)
sRestoreBtn.Size = UDim2.new(0, 90, 0, 26)
sRestoreBtn.Position = sFrame.Position
sRestoreBtn.BackgroundColor3 = Color3.fromRGB(18, 12, 38)
sRestoreBtn.Text = "⚙ Settings"
sRestoreBtn.Font = Enum.Font.GothamBold
sRestoreBtn.TextSize = 10
sRestoreBtn.TextColor3 = Color3.fromRGB(196, 181, 253)
sRestoreBtn.Visible = false
sRestoreBtn.AutoButtonColor = false
Instance.new("UICorner", sRestoreBtn).CornerRadius = UDim.new(0, 8)
local sRestoreStroke = Instance.new("UIStroke", sRestoreBtn)
sRestoreStroke.Color = Color3.fromRGB(124, 58, 237)
sRestoreStroke.Thickness = 1
sRestoreStroke.Transparency = 0.4
MakeDraggable(sRestoreBtn, sRestoreBtn, nil)

sCloseBtn.MouseButton1Click:Connect(function()
    sFrame.Visible = false
    sRestoreBtn.Visible = true
end)
sRestoreBtn.MouseButton1Click:Connect(function()
    sFrame.Visible = true
    sRestoreBtn.Visible = false
end)
 
-- discord tag
local sDisc = Instance.new("TextLabel", sHeader)
sDisc.Size = UDim2.new(0.38, 0, 1, 0)
sDisc.Position = UDim2.new(0.62, 0, 0, 0)
sDisc.BackgroundTransparency = 1
sDisc.Text = "discord.gg/xi-hub"
sDisc.Font = Enum.Font.GothamMedium
sDisc.TextSize = 9
sDisc.TextColor3 = Color3.fromRGB(80, 90, 130)
sDisc.TextXAlignment = Enum.TextXAlignment.Right
 
-- ── TAB BAR ──────────────────────────────────────────────────────────
local TAB_NAMES = {"General", "Movement", "Visuals", "Extras", "Admin"}
local TAB_COLORS = {
    General  = Color3.fromRGB(6, 182, 212),
    Movement = Color3.fromRGB(16, 185, 129),
    Visuals  = Color3.fromRGB(245, 158, 11),
    Extras   = Color3.fromRGB(168, 85, 247),
    Admin    = Color3.fromRGB(219, 39, 119),
}
 
local tabBar = Instance.new("Frame", sFrame)
tabBar.Size = UDim2.new(1, -16, 0, 30)
tabBar.Position = UDim2.new(0, 8, 0, 48)
tabBar.BackgroundTransparency = 1
 
local tabBarLayout = Instance.new("UIListLayout", tabBar)
tabBarLayout.FillDirection = Enum.FillDirection.Horizontal
tabBarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabBarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabBarLayout.Padding = UDim.new(0, 4)
 
-- Underline indicator
local tabUnderline = Instance.new("Frame", sFrame)
tabUnderline.Size = UDim2.new(0, 58, 0, 2)
tabUnderline.Position = UDim2.new(0, 8, 0, 77)
tabUnderline.BackgroundColor3 = Color3.fromRGB(6, 182, 212)
tabUnderline.BorderSizePixel = 0
Instance.new("UICorner", tabUnderline).CornerRadius = UDim.new(1, 0)
 
-- Scroll area (fills below tab bar)
local sList = Instance.new("ScrollingFrame", sFrame)
sList.Name = "sList"
sList.Size = UDim2.new(1, -16, 1, -84)
sList.Position = UDim2.new(0, 8, 0, 82)
sList.BackgroundTransparency = 1
sList.BorderSizePixel = 0
sList.ScrollBarThickness = 3
sList.ScrollBarImageColor3 = Theme.Accent1
sList.CanvasSize = UDim2.new(0, 0, 0, 0)
 
local sLayout = Instance.new("UIListLayout", sList)
sLayout.Padding = UDim.new(0, 6)
sLayout.SortOrder = Enum.SortOrder.LayoutOrder
 
-- Track all tab content frames
local tabFrames = {}      -- tabFrames["General"] = {rows}
local tabButtons = {}
local currentTab = "General"
 
-- ── SHARED ROW / TOGGLE FACTORIES ────────────────────────────────────
 
local function CreateToggleSwitch(parent, initialState, callback)
    local sw = Instance.new("Frame")
    sw.Size = UDim2.new(0, 40, 0, 20)
    sw.Position = UDim2.new(1, -50, 0.5, -10)
    sw.BackgroundColor3 = initialState and Color3.fromRGB(80,20,160) or Color3.fromRGB(22,14,55)
    Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)
    sw.Parent = parent
 
    local swStroke = Instance.new("UIStroke", sw)
    swStroke.Thickness = 1.5
    swStroke.Color = initialState and Color3.fromRGB(124,58,237) or Color3.fromRGB(40,30,70)
    swStroke.Transparency = 0.3
 
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0,14,0,14)
    dot.Position = initialState and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,3,0.5,-7)
    dot.BackgroundColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
    dot.Parent = sw
 
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = sw
 
    local isOn = initialState
    local function SetState(s)
        isOn = s
        local tp = isOn and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,3,0.5,-7)
        local bg = isOn and Color3.fromRGB(80,20,160) or Color3.fromRGB(22,14,55)
        local sc = isOn and Color3.fromRGB(124,58,237) or Color3.fromRGB(40,30,70)
        TweenService:Create(dot,  TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=tp}):Play()
        TweenService:Create(sw,   TweenInfo.new(0.2),{BackgroundColor3=bg}):Play()
        TweenService:Create(swStroke,TweenInfo.new(0.2),{Color=sc}):Play()
    end
    btn.MouseButton1Click:Connect(function() callback(not isOn, SetState) end)
    return {Set = SetState, Container = sw}
end
 
-- Each row belongs to a tab via LayoutOrder groups
local tabRowOrder = {}   -- tabRowOrder["General"] = base order number
local rowCounter = 0
 
local function CreateRow(text, height, tabName)
    rowCounter = rowCounter + 1
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,height or 34)
    row.BackgroundColor3 = Theme.Surface
    row.LayoutOrder = rowCounter
    row.Visible = (tabName == currentTab)
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,6)
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.6,0,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextColor3 = Theme.TextPrimary
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    row.Parent = sList
    if tabFrames[tabName] then
        table.insert(tabFrames[tabName], row)
    end
    return row
end
 
local function CreateSectionHeader(text, tabName, accentColor)
    accentColor = accentColor or TAB_COLORS[tabName] or Theme.Accent2
    rowCounter = rowCounter + 1
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,26)
    row.BackgroundTransparency = 1
    row.LayoutOrder = rowCounter
    row.Visible = (tabName == currentTab)
    row.Parent = sList
    if tabFrames[tabName] then table.insert(tabFrames[tabName], row) end
 
    local dot = Instance.new("Frame", row)
    dot.Size = UDim2.new(0,7,0,7)
    dot.Position = UDim2.new(0,4,0.5,-3)
    dot.BackgroundColor3 = accentColor
    dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
    task.spawn(function()
        while dot.Parent do
            TweenService:Create(dot,TweenInfo.new(1,Enum.EasingStyle.Sine),{Size=UDim2.new(0,9,0,9),Position=UDim2.new(0,3,0.5,-4)}):Play()
            task.wait(1)
            TweenService:Create(dot,TweenInfo.new(1,Enum.EasingStyle.Sine),{Size=UDim2.new(0,7,0,7),Position=UDim2.new(0,4,0.5,-3)}):Play()
            task.wait(1)
        end
    end)
 
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1,-20,1,0)
    lbl.Position = UDim2.new(0,16,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = accentColor
    lbl.TextSize = 10
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextXAlignment = Enum.TextXAlignment.Left
 
    local line = Instance.new("Frame", row)
    line.Size = UDim2.new(1,-80,0,1)
    line.Position = UDim2.new(0,75,0.5,0)
    line.BackgroundColor3 = accentColor
    line.BackgroundTransparency = 0.5
    line.BorderSizePixel = 0
    local lg = Instance.new("UIGradient", line)
    lg.Color = ColorSequence.new{ColorSequenceKeypoint.new(0,accentColor),ColorSequenceKeypoint.new(1,Color3.fromRGB(0,0,0))}
    lg.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}
    return row
end
 
-- Initialise tab frame lists
for _, t in ipairs(TAB_NAMES) do tabFrames[t] = {} end
 
-- ── SWITCH TAB FUNCTION ───────────────────────────────────────────────
local function switchTab(name)
    currentTab = name
    -- Show/hide rows
    for tabName, rows in pairs(tabFrames) do
        for _, row in ipairs(rows) do
            if row and row.Parent then
                row.Visible = (tabName == name)
            end
        end
    end
    -- Restyle tab buttons
    for tName, tbtn in pairs(tabButtons) do
        local col = TAB_COLORS[tName] or Theme.Accent2
        local active = (tName == name)
        tbtn.TextColor3 = active and col or Color3.fromRGB(80,90,130)
        tbtn.BackgroundColor3 = active and Color3.fromRGB(
            math.floor(col.R*255*0.12),
            math.floor(col.G*255*0.12),
            math.floor(col.B*255*0.12)
        ) or Color3.fromRGB(12,8,30)
        -- Move underline
        if active then
            TweenService:Create(tabUnderline, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                Position = UDim2.new(0, tbtn.AbsolutePosition.X - sFrame.AbsolutePosition.X, 0, 77),
                Size = UDim2.new(0, tbtn.AbsoluteSize.X, 0, 2),
                BackgroundColor3 = col,
            }):Play()
        end
    end
    sList.CanvasPosition = Vector2.new(0, 0)
end
 
-- ── BUILD TAB BUTTONS ─────────────────────────────────────────────────
for _, tName in ipairs(TAB_NAMES) do
    local col = TAB_COLORS[tName] or Theme.Accent2
    local tbtn = Instance.new("TextButton", tabBar)
    tbtn.Size = UDim2.new(0, 58, 1, 0)
    tbtn.BackgroundColor3 = Color3.fromRGB(12, 8, 30)
    tbtn.Text = tName
    tbtn.Font = Enum.Font.GothamBlack
    tbtn.TextSize = 10
    tbtn.TextColor3 = Color3.fromRGB(80, 90, 130)
    tbtn.AutoButtonColor = false
    Instance.new("UICorner", tbtn).CornerRadius = UDim.new(0, 6)
    tabButtons[tName] = tbtn
    tbtn.MouseButton1Click:Connect(function() switchTab(tName) end)
end
 
-- ─────────────────────────────────────────────────────────────────────
-- GENERAL TAB
-- ─────────────────────────────────────────────────────────────────────
CreateSectionHeader("GENERAL", "General")
 
local rFPS = CreateRow("FPS Boost", nil, "General")
CreateToggleSwitch(rFPS, Config.FPSBoost, function(ns,set) set(ns); setFPSBoost(ns) end)
 
local rTrace = CreateRow("Tracer Best Brainrot", nil, "General")
CreateToggleSwitch(rTrace, Config.TracerEnabled, function(ns,set) set(ns); Config.TracerEnabled=ns; SaveConfig() end)
 
local rLineToBase = CreateRow("Line to base", nil, "General")
CreateToggleSwitch(rLineToBase, Config.LineToBase, function(ns,set)
    set(ns); Config.LineToBase=ns; SaveConfig()
    if not ns and _G.resetPlotBeam then pcall(_G.resetPlotBeam) end
end)
 
CreateSectionHeader("AUTO TP", "General")
local rTpOnLoad = CreateRow("TP on Script Load", nil, "General")
CreateToggleSwitch(rTpOnLoad, Config.TpSettings.TpOnLoad, function(ns,set) set(ns); Config.TpSettings.TpOnLoad=ns; SaveConfig() end)
 
local rMinGen = CreateRow("Min Gen for Auto TP", nil, "General")
local minGenBox = Instance.new("TextBox", rMinGen)
minGenBox.Size = UDim2.new(0,100,0,24); minGenBox.Position = UDim2.new(1,-110,0.5,-12)
minGenBox.BackgroundColor3 = Theme.SurfaceHighlight; minGenBox.Text = tostring(Config.TpSettings.MinGenForTp or "")
minGenBox.Font = Enum.Font.Gotham; minGenBox.TextSize = 11; minGenBox.TextColor3 = Theme.TextPrimary
minGenBox.PlaceholderText = "e.g. 5k, 1m"
Instance.new("UICorner", minGenBox).CornerRadius = UDim.new(0,4)
minGenBox.FocusLost:Connect(function()
    Config.TpSettings.MinGenForTp = minGenBox.Text:gsub("%s","") or ""; SaveConfig()
end)
 
local toolOptions = {"Flying Carpet","Cupid's Wings","Santa's Sleigh","Witch's Broom"}
local toolSwitches = {}
for _, toolName in ipairs(toolOptions) do
    local r = CreateRow(toolName, nil, "General")
    local ts = CreateToggleSwitch(r, Config.TpSettings.Tool==toolName, function(rs,set)
        if rs then Config.TpSettings.Tool=toolName; SaveConfig(); set(true)
            for n,sw in pairs(toolSwitches) do if n~=toolName then sw.Set(false) end end
        else set(Config.TpSettings.Tool==toolName) end
    end)
    toolSwitches[toolName] = ts
end
 
local rBind = CreateRow("TP Keybind", nil, "General")
local bBind = Instance.new("TextButton", rBind)
bBind.Size=UDim2.new(0,60,0,24); bBind.Position=UDim2.new(1,-70,0.5,-12)
bBind.BackgroundColor3=Theme.SurfaceHighlight; bBind.Text=Config.TpSettings.TpKey
bBind.Font=Enum.Font.GothamBold; bBind.TextColor3=Theme.TextPrimary; bBind.TextSize=12
Instance.new("UICorner",bBind).CornerRadius=UDim.new(0,4)
bBind.MouseButton1Click:Connect(function()
    bBind.Text="..."; bBind.TextColor3=Theme.Accent1
    local c; c=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.TpSettings.TpKey=inp.KeyCode.Name; bBind.Text=inp.KeyCode.Name
            bBind.TextColor3=Theme.TextPrimary; SaveConfig(); c:Disconnect()
        end
    end)
end)
 
local rBindClone = CreateRow("Clone Keybind", nil, "General")
local bBindClone = Instance.new("TextButton", rBindClone)
bBindClone.Size=UDim2.new(0,60,0,24); bBindClone.Position=UDim2.new(1,-70,0.5,-12)
bBindClone.BackgroundColor3=Theme.SurfaceHighlight; bBindClone.Text=Config.TpSettings.CloneKey
bBindClone.Font=Enum.Font.GothamBold; bBindClone.TextColor3=Theme.TextPrimary; bBindClone.TextSize=12
Instance.new("UICorner",bBindClone).CornerRadius=UDim.new(0,4)
bBindClone.MouseButton1Click:Connect(function()
    bBindClone.Text="..."; bBindClone.TextColor3=Theme.Accent1
    local c; c=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.TpSettings.CloneKey=inp.KeyCode.Name; bBindClone.Text=inp.KeyCode.Name
            bBindClone.TextColor3=Theme.TextPrimary; SaveConfig(); c:Disconnect()
        end
    end)
end)
 
local rAutoTpPriority = CreateRow("Auto TP Priority Mode", nil, "General")
local autoTPPriorityToggleRef = {setFn=nil}
local autoTPPriorityToggleSwitch = CreateToggleSwitch(rAutoTpPriority, Config.AutoTPPriority, function(ns,set)
    set(ns); Config.AutoTPPriority=ns; SaveConfig()
end)
autoTPPriorityToggleRef.setFn = autoTPPriorityToggleSwitch.Set
 
-- ─────────────────────────────────────────────────────────────────────
-- MOVEMENT TAB
-- ─────────────────────────────────────────────────────────────────────
CreateSectionHeader("MOVEMENT", "Movement")
 
local rInfJump = CreateRow("Infinite Jump", nil, "Movement")
CreateToggleSwitch(rInfJump, infiniteJumpEnabled, function(ns,set) set(ns); setInfiniteJump(ns) end)
 
local rShowSS = CreateRow("Show Steal Speed Panel", nil, "Movement")
CreateToggleSwitch(rShowSS, Config.ShowStealSpeedPanel, function(ns,set)
    set(ns); Config.ShowStealSpeedPanel=ns; SaveConfig()
    local ssGui = PlayerGui:FindFirstChild("StealSpeedUI"); if ssGui then ssGui.Enabled=ns end
end)
 
local rAutoStealSpeed = CreateRow("Auto Steal Speed", nil, "Movement")
CreateToggleSwitch(rAutoStealSpeed, Config.AutoStealSpeed, function(ns,set) set(ns); Config.AutoStealSpeed=ns; SaveConfig() end)
 
local rStealSpeedKey = CreateRow("Steal Speed Keybind", nil, "Movement")
local bSSKey = Instance.new("TextButton", rStealSpeedKey)
bSSKey.Size=UDim2.new(0,60,0,24); bSSKey.Position=UDim2.new(1,-70,0.5,-12)
bSSKey.BackgroundColor3=Theme.SurfaceHighlight; bSSKey.Text=Config.StealSpeedKey
bSSKey.Font=Enum.Font.GothamBold; bSSKey.TextColor3=Theme.TextPrimary; bSSKey.TextSize=12
Instance.new("UICorner",bSSKey).CornerRadius=UDim.new(0,4)
bSSKey.MouseButton1Click:Connect(function()
    bSSKey.Text="..."; bSSKey.TextColor3=Theme.Accent1
    local c; c=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.StealSpeedKey=inp.KeyCode.Name; bSSKey.Text=inp.KeyCode.Name
            bSSKey.TextColor3=Theme.TextPrimary; SaveConfig(); c:Disconnect()
        end
    end)
end)
 
CreateSectionHeader("CARPET SPEED", "Movement")
local rCarpetBind = CreateRow("Carpet Speed Keybind", nil, "Movement")
local bCarpet = Instance.new("TextButton", rCarpetBind)
bCarpet.Size=UDim2.new(0,60,0,24); bCarpet.Position=UDim2.new(1,-70,0.5,-12)
bCarpet.BackgroundColor3=Theme.SurfaceHighlight; bCarpet.Text=Config.TpSettings.CarpetSpeedKey
bCarpet.Font=Enum.Font.GothamBold; bCarpet.TextColor3=Theme.TextPrimary; bCarpet.TextSize=12
Instance.new("UICorner",bCarpet).CornerRadius=UDim.new(0,4)
bCarpet.MouseButton1Click:Connect(function()
    bCarpet.Text="..."; bCarpet.TextColor3=Theme.Accent1
    local c; c=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.TpSettings.CarpetSpeedKey=inp.KeyCode.Name; bCarpet.Text=inp.KeyCode.Name
            bCarpet.TextColor3=Theme.TextPrimary; SaveConfig(); c:Disconnect()
        end
    end)
end)
 
local rCarpetStatus = CreateRow("Carpet Speed", nil, "Movement")
local carpetStatusLbl = Instance.new("TextLabel", rCarpetStatus)
carpetStatusLbl.Size=UDim2.new(0,50,0,20); carpetStatusLbl.Position=UDim2.new(1,-60,0.5,-10)
carpetStatusLbl.BackgroundTransparency=1; carpetStatusLbl.Text=carpetSpeedEnabled and "ON" or "OFF"
carpetStatusLbl.TextColor3=carpetSpeedEnabled and Theme.Success or Theme.Error
carpetStatusLbl.Font=Enum.Font.GothamBlack; carpetStatusLbl.TextSize=13
carpetStatusLbl.TextXAlignment=Enum.TextXAlignment.Right
_carpetStatusLabel = carpetStatusLbl
 
CreateSectionHeader("ANTI-RAGDOLL", "Movement")
local arV1SetRef, arV2SetRef = {}, {}
local rAr = CreateRow("V1", nil, "Movement")
CreateToggleSwitch(rAr, Config.AntiRagdoll>0, function(ns,set)
    arV1SetRef.fn=set
    if ns and Config.AntiRagdollV2 then set(false); ShowNotification("ANTI-RAGDOLL","DISABLE V2 FIRST"); return end
    set(ns); Config.AntiRagdoll=ns and 1 or 0
    if ns then Config.AntiRagdollV2=false; if arV2SetRef.fn then arV2SetRef.fn(false) end end
    SaveConfig(); startAntiRagdoll(Config.AntiRagdoll)
    if ns then startAntiRagdollV2(false) end
end)
local rArV2 = CreateRow("V2", nil, "Movement")
CreateToggleSwitch(rArV2, Config.AntiRagdollV2, function(ns,set)
    arV2SetRef.fn=set
    if ns and Config.AntiRagdoll>0 then set(false); ShowNotification("ANTI-RAGDOLL","DISABLE V1 FIRST"); return end
    set(ns); Config.AntiRagdollV2=ns
    if ns then Config.AntiRagdoll=0; SaveConfig()
        if arV1SetRef.fn then arV1SetRef.fn(false) end
        startAntiRagdoll(0); startAntiRagdollV2(true)
    else SaveConfig(); startAntiRagdollV2(false) end
end)
 
CreateSectionHeader("AUTO UNLOCK", "Movement")
local rAutoUnlock = CreateRow("Auto Unlock on Steal", nil, "Movement")
CreateToggleSwitch(rAutoUnlock, Config.AutoUnlockOnSteal, function(ns,set) set(ns); Config.AutoUnlockOnSteal=ns; SaveConfig() end)
local rShowUnlockHUD = CreateRow("Show Unlock HUD", nil, "Movement")
CreateToggleSwitch(rShowUnlockHUD, Config.ShowUnlockButtonsHUD, function(ns,set)
    set(ns); Config.ShowUnlockButtonsHUD=ns; SaveConfig()
    local hud = PlayerGui:FindFirstChild("XiStatusHUD")
    if hud then
        local m = hud:FindFirstChild("Main")
        local uc = m and m:FindFirstChild("UnlockButtonsContainer")
        if m and uc then uc.Visible=ns end
    end
end)
 
-- ─────────────────────────────────────────────────────────────────────
-- VISUALS TAB
-- ─────────────────────────────────────────────────────────────────────
CreateSectionHeader("ESP", "Visuals")
 
local rXray = CreateRow("Base X-Ray", nil, "Visuals")
local xrayToggle = CreateToggleSwitch(rXray, Config.XrayEnabled, function(ns,set)
    set(ns); if ns then enableXray() else disableXray() end
    Config.XrayEnabled=ns; SaveConfig()
end)
 
local playerESPToggleRef = {setFn=nil}
local rPlayerEsp = CreateRow("Player ESP", nil, "Visuals")
CreateToggleSwitch(rPlayerEsp, Config.PlayerESP, function(ns,set)
    set(ns); Config.PlayerESP=ns; SaveConfig()
    if playerESPToggleRef.setFn then playerESPToggleRef.setFn(ns) end
end)
 
local espToggleRef = {enabled=true, setFn=nil}
local rEsp = CreateRow("Brainrot ESP", nil, "Visuals")
CreateToggleSwitch(rEsp, Config.BrainrotESP, function(ns,set)
    set(ns); Config.BrainrotESP=ns; SaveConfig()
    if espToggleRef.setFn then espToggleRef.setFn(ns) end
end)
 
local subspaceMineESPToggleRef = {setFn=nil}
local rSubMine = CreateRow("Subspace Mine ESP", nil, "Visuals")
CreateToggleSwitch(rSubMine, Config.SubspaceMineESP, function(ns,set)
    set(ns); Config.SubspaceMineESP=ns; SaveConfig()
    if subspaceMineESPToggleRef.setFn then subspaceMineESPToggleRef.setFn(ns) end
end)
 
local rDuelBase = CreateRow("Duel Base ESP", nil, "Visuals")
CreateToggleSwitch(rDuelBase, Config.DuelBaseESP, function(ns,set) set(ns); Config.DuelBaseESP=ns; SaveConfig() end)
 
CreateSectionHeader("CAMERA", "Visuals")
local rFOV = CreateRow("FOV", nil, "Visuals")
local fovSliderBg = Instance.new("Frame", rFOV)
fovSliderBg.Size=UDim2.new(0,120,0,5); fovSliderBg.Position=UDim2.new(1,-175,0.5,-2.5)
fovSliderBg.BackgroundColor3=Color3.fromRGB(30,32,38)
Instance.new("UICorner",fovSliderBg).CornerRadius=UDim.new(1,0)
local fovFill=Instance.new("Frame",fovSliderBg); fovFill.BackgroundColor3=Theme.Accent1; fovFill.Size=UDim2.new(0,0,1,0)
Instance.new("UICorner",fovFill).CornerRadius=UDim.new(1,0)
local fovKnob=Instance.new("Frame",fovSliderBg); fovKnob.Size=UDim2.new(0,12,0,12); fovKnob.BackgroundColor3=Theme.TextPrimary
fovKnob.AnchorPoint=Vector2.new(0.5,0.5); fovKnob.Position=UDim2.new(0,0,0.5,0)
Instance.new("UICorner",fovKnob).CornerRadius=UDim.new(1,0)
local fovVal=Instance.new("TextLabel",rFOV); fovVal.Size=UDim2.new(0,40,0,20); fovVal.Position=UDim2.new(1,-45,0.5,-10)
fovVal.BackgroundTransparency=1; fovVal.Text=string.format("%.0f",Config.FOV); fovVal.TextColor3=Theme.TextPrimary
fovVal.Font=Enum.Font.GothamBold; fovVal.TextSize=12
local function updateFOV(v)
    v=math.clamp(v,30,180); Config.FOV=v; SaveConfig()
    local p=(v-30)/150; fovFill.Size=UDim2.new(p,0,1,0); fovKnob.Position=UDim2.new(p,0,0.5,0)
    fovVal.Text=string.format("%.0f",v)
    if Workspace.CurrentCamera then Workspace.CurrentCamera.FieldOfView=v end
end
updateFOV(Config.FOV)
local fovDrag=false
fovSliderBg.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then fovDrag=true end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then fovDrag=false end end)
UserInputService.InputChanged:Connect(function(i)
    if fovDrag and i.UserInputType==Enum.UserInputType.MouseMovement then
        local p=(i.Position.X-fovSliderBg.AbsolutePosition.X)/fovSliderBg.AbsoluteSize.X
        updateFOV(30+p*150)
    end
end)
 
CreateSectionHeader("HIDE GUIS", "Visuals")
local rHideAdmin = CreateRow("Hide Admin Panel", nil, "Visuals")
CreateToggleSwitch(rHideAdmin, Config.HideAdminPanel, function(ns,set)
    set(ns); Config.HideAdminPanel=ns; SaveConfig()
    local g=PlayerGui:FindFirstChild("XiAdminPanel"); if g then g.Enabled=not ns end
end)
local rHideAS = CreateRow("Hide Auto Steal", nil, "Visuals")
CreateToggleSwitch(rHideAS, Config.HideAutoSteal, function(ns,set)
    set(ns); Config.HideAutoSteal=ns; SaveConfig()
    local g=PlayerGui:FindFirstChild("AutoStealUI"); if g then g.Enabled=not ns end
end)
local rDesyncGui = CreateRow("Show Desync GUI", nil, "Visuals")
CreateToggleSwitch(rDesyncGui, Config.ShowDesyncGui, function(ns,set)
    set(ns); Config.ShowDesyncGui=ns; SaveConfig()
    local g=PlayerGui:FindFirstChild("XiDesyncPanel"); if g then g.Enabled=ns end
end)
 
-- ─────────────────────────────────────────────────────────────────────
-- EXTRAS TAB
-- ─────────────────────────────────────────────────────────────────────
CreateSectionHeader("AUTOMATION", "Extras")
local rAutoInvis = CreateRow("Auto Invis During Steal", nil, "Extras")
CreateToggleSwitch(rAutoInvis, Config.AutoInvisDuringSteal, function(ns,set)
    set(ns); Config.AutoInvisDuringSteal=ns; _G.AutoInvisDuringSteal=ns; SaveConfig()
end)
local rAutoTpFail = CreateRow("Auto TP on Failed Steal", nil, "Extras")
CreateToggleSwitch(rAutoTpFail, Config.AutoTpOnFailedSteal, function(ns,set)
    set(ns); Config.AutoTpOnFailedSteal=ns; SaveConfig()
end)
local rAutoKick = CreateRow("Auto-Kick on Steal", nil, "Extras")
CreateToggleSwitch(rAutoKick, Config.AutoKickOnSteal, function(ns,set) set(ns); Config.AutoKickOnSteal=ns; SaveConfig() end)
 
CreateSectionHeader("AUTO STEAL DEFAULTS", "Extras")
local nearestToggleRef, highestToggleRef, priorityToggleRef = {},{},{}
local rDefNearest = CreateRow("Default To Nearest", nil, "Extras")
local nearestTS = CreateToggleSwitch(rDefNearest, Config.DefaultToNearest, function(ns,set)
    if ns then Config.DefaultToNearest=true; Config.DefaultToHighest=false; Config.DefaultToPriority=false
        set(true); if highestToggleRef.setFn then highestToggleRef.setFn(false) end
        if priorityToggleRef.setFn then priorityToggleRef.setFn(false) end
    else if not (Config.DefaultToHighest or Config.DefaultToPriority) then set(true); return end
        Config.DefaultToNearest=false; set(false) end
    SaveConfig()
end); nearestToggleRef.setFn = nearestTS.Set
 
local rDefHighest = CreateRow("Default To Highest", nil, "Extras")
local highestTS = CreateToggleSwitch(rDefHighest, Config.DefaultToHighest, function(ns,set)
    if ns then Config.DefaultToNearest=false; Config.DefaultToHighest=true; Config.DefaultToPriority=false
        set(true); if nearestToggleRef.setFn then nearestToggleRef.setFn(false) end
        if priorityToggleRef.setFn then priorityToggleRef.setFn(false) end
    else if not (Config.DefaultToNearest or Config.DefaultToPriority) then set(true); return end
        Config.DefaultToHighest=false; set(false) end
    SaveConfig()
end); highestToggleRef.setFn = highestTS.Set
 
local rDefPriority = CreateRow("Default To Priority", nil, "Extras")
local priorityTS = CreateToggleSwitch(rDefPriority, Config.DefaultToPriority, function(ns,set)
    if ns then Config.DefaultToNearest=false; Config.DefaultToHighest=false; Config.DefaultToPriority=true
        set(true); if nearestToggleRef.setFn then nearestToggleRef.setFn(false) end
        if highestToggleRef.setFn then highestToggleRef.setFn(false) end
    else if not (Config.DefaultToNearest or Config.DefaultToHighest) then set(true); return end
        Config.DefaultToPriority=false; set(false) end
    SaveConfig()
end); priorityToggleRef.setFn = priorityTS.Set
 
CreateSectionHeader("PROTECTION", "Extras")
local rAntiBeeDisco = CreateRow("Anti-Bee & Disco", nil, "Extras")
CreateToggleSwitch(rAntiBeeDisco, Config.AntiBeeDisco, function(ns,set)
    set(ns); Config.AntiBeeDisco=ns; SaveConfig()
    if ns then if _G.ANTI_BEE_DISCO then _G.ANTI_BEE_DISCO.Enable() end
    else if _G.ANTI_BEE_DISCO then _G.ANTI_BEE_DISCO.Disable() end end
end)
local rTurrets = CreateRow("Auto-Destroy Turrets", nil, "Extras")
CreateToggleSwitch(rTurrets, Config.AutoDestroyTurrets, function(ns,set) set(ns); Config.AutoDestroyTurrets=ns; SaveConfig() end)
local rBalloon = CreateRow("Auto Reset on Balloon", nil, "Extras")
CreateToggleSwitch(rBalloon, Config.AutoResetOnBalloon, function(ns,set) set(ns); Config.AutoResetOnBalloon=ns; SaveConfig() end)
 
CreateSectionHeader("KEYBINDS", "Extras")
local function makeKeybindRow(label, cfgKey, tabName, applyFn)
    local r = CreateRow(label, nil, tabName)
    local b = Instance.new("TextButton", r)
    b.Size=UDim2.new(0,60,0,24); b.Position=UDim2.new(1,-70,0.5,-12)
    b.BackgroundColor3=Theme.SurfaceHighlight
    b.Text = (Config[cfgKey] ~= "" and Config[cfgKey]) or "NONE"
    b.Font=Enum.Font.GothamBold; b.TextColor3=Theme.TextPrimary; b.TextSize=12
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
    b.MouseButton1Click:Connect(function()
        b.Text="..."; b.TextColor3=Theme.Accent1
        local c; c=UserInputService.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.Keyboard then
                Config[cfgKey]=inp.KeyCode.Name; b.Text=inp.KeyCode.Name
                b.TextColor3=Theme.TextPrimary; SaveConfig()
                if applyFn then applyFn(inp.KeyCode.Name) end
                c:Disconnect()
            end
        end)
    end)
end
makeKeybindRow("Reset Key",        "ResetKey",       "Extras")
makeKeybindRow("Kick Key",         "KickKey",        "Extras")
makeKeybindRow("Ragdoll Self Key", "RagdollSelfKey", "Extras")
 
CreateSectionHeader("ALERTS", "Extras")
local rAlerts = CreateRow("Enable Alerts", nil, "Extras")
CreateToggleSwitch(rAlerts, Config.AlertsEnabled, function(ns,set) set(ns); Config.AlertsEnabled=ns; SaveConfig() end)
local rAlertSnd = CreateRow("Alert Sound ID", nil, "Extras")
local soundBox = Instance.new("TextBox", rAlertSnd)
soundBox.Size=UDim2.new(0,150,0,24); soundBox.Position=UDim2.new(1,-160,0.5,-12)
soundBox.BackgroundColor3=Theme.SurfaceHighlight; soundBox.Text=Config.AlertSoundID or ""
soundBox.Font=Enum.Font.Gotham; soundBox.TextSize=10; soundBox.TextColor3=Theme.TextPrimary
Instance.new("UICorner",soundBox).CornerRadius=UDim.new(0,4)
soundBox.FocusLost:Connect(function() Config.AlertSoundID=soundBox.Text; SaveConfig() end)
 
CreateSectionHeader("DESYNC", "Extras")
local rDesyncOnSteal = CreateRow("Desync on Steal", nil, "Extras")
local _setAutoDesync2
local setDesyncOnSteal = CreateToggleSwitch(rDesyncOnSteal, Config.DesyncOnSteal, function(ns,set)
    Config.DesyncOnSteal=ns; if ns then Config.AutoDesync=false; if _setAutoDesync2 then _setAutoDesync2(false) end end
    SaveConfig(); set(ns)
end)
local rAutoDesync = CreateRow("Auto Desync", nil, "Extras")
_setAutoDesync2 = CreateToggleSwitch(rAutoDesync, Config.AutoDesync, function(ns,set)
    Config.AutoDesync=ns; if ns then Config.DesyncOnSteal=false; setDesyncOnSteal.Set(false) end
    SaveConfig(); set(ns)
end).Set
 
CreateSectionHeader("JOB JOINER", "Extras")
local rJoiner = CreateRow("Show Job Joiner", nil, "Extras")
CreateToggleSwitch(rJoiner, Config.ShowJobJoiner, function(ns,set)
    set(ns); Config.ShowJobJoiner=ns; SaveConfig()
    local g=PlayerGui:FindFirstChild("XiJobJoiner"); if g then g.Enabled=ns end
end)
makeKeybindRow("Job Joiner Key", "JobJoinerKey", "Extras")
 
CreateSectionHeader("UI CONTROLS", "Extras")
local rLock = CreateRow("Lock UI Dragging", nil, "Extras")
CreateToggleSwitch(rLock, Config.UILocked, function(ns,set) set(ns); Config.UILocked=ns; SaveConfig() end)
local rResetPos = CreateRow("Reset UI Positions", nil, "Extras")
local bResetPos = Instance.new("TextButton", rResetPos)
bResetPos.Size=UDim2.new(0,70,0,24); bResetPos.Position=UDim2.new(1,-80,0.5,-12)
bResetPos.BackgroundColor3=Theme.Error; bResetPos.Text="RESET"
bResetPos.Font=Enum.Font.GothamBold; bResetPos.TextColor3=Theme.TextPrimary; bResetPos.TextSize=12
Instance.new("UICorner",bResetPos).CornerRadius=UDim.new(0,4)
bResetPos.MouseButton1Click:Connect(function()
    Config.Positions=DefaultConfig.Positions; SaveConfig()
    sFrame.Position=UDim2.new(DefaultConfig.Positions.Settings.X,0,DefaultConfig.Positions.Settings.Y,0)
    ShowNotification("UI RESET","Positions restored to default")
end)
 
if not IS_MOBILE then
    local rMenu = CreateRow("Menu Toggle Key", nil, "Extras")
    local bMenu = Instance.new("TextButton", rMenu)
    bMenu.Size=UDim2.new(0,70,0,24); bMenu.Position=UDim2.new(1,-80,0.5,-12)
    bMenu.BackgroundColor3=Theme.SurfaceHighlight; bMenu.Text=Config.MenuKey
    bMenu.Font=Enum.Font.GothamBold; bMenu.TextColor3=Theme.TextPrimary; bMenu.TextSize=12
    Instance.new("UICorner",bMenu).CornerRadius=UDim.new(0,4)
    bMenu.MouseButton1Click:Connect(function()
        bMenu.Text="..."; bMenu.TextColor3=Theme.Accent1
        local c; c=UserInputService.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.Keyboard then
                Config.MenuKey=inp.KeyCode.Name; bMenu.Text=inp.KeyCode.Name
                bMenu.TextColor3=Theme.TextPrimary; SaveConfig(); c:Disconnect()
            end
        end)
    end)
end
 
-- ─────────────────────────────────────────────────────────────────────
-- ADMIN TAB
-- ─────────────────────────────────────────────────────────────────────
CreateSectionHeader("CLICK TO AP", "Admin")
local rClickToAP = CreateRow("Click To AP", nil, "Admin")
CreateToggleSwitch(rClickToAP, Config.ClickToAP, function(ns,set) set(ns); Config.ClickToAP=ns; SaveConfig() end)
local rClickSingle = CreateRow("Single Command Mode", nil, "Admin")
CreateToggleSwitch(rClickSingle, Config.ClickToAPSingleCommand, function(ns,set) set(ns); Config.ClickToAPSingleCommand=ns; SaveConfig() end)
local rDisMoby = CreateRow("Disable on Moby", nil, "Admin")
CreateToggleSwitch(rDisMoby, Config.DisableClickToAPOnMoby, function(ns,set) set(ns); Config.DisableClickToAPOnMoby=ns; SaveConfig() end)
local rDisKawaifu = CreateRow("Disable on Kawaifu", nil, "Admin")
CreateToggleSwitch(rDisKawaifu, Config.DisableClickToAPOnKawaifu, function(ns,set) set(ns); Config.DisableClickToAPOnKawaifu=ns; SaveConfig() end)
makeKeybindRow("Click AP Keybind", "ClickToAPKeybind", "Admin")
 
CreateSectionHeader("PROXIMITY AP", "Admin")
local rDisProxMoby = CreateRow("Disable Prox on Moby", nil, "Admin")
CreateToggleSwitch(rDisProxMoby, Config.DisableProximitySpamOnMoby, function(ns,set) set(ns); Config.DisableProximitySpamOnMoby=ns; SaveConfig() end)
local rDisProxKaw = CreateRow("Disable Prox on Kawaifu", nil, "Admin")
CreateToggleSwitch(rDisProxKaw, Config.DisableProximitySpamOnKawaifu, function(ns,set) set(ns); Config.DisableProximitySpamOnKawaifu=ns; SaveConfig() end)
makeKeybindRow("Proximity AP Keybind", "ProximityAPKeybind", "Admin")
 
CreateSectionHeader("PANEL OPTIONS", "Admin")
local rHideKaw = CreateRow("Hide Kawaifu From Panel", nil, "Admin")
CreateToggleSwitch(rHideKaw, Config.HideKawaifuFromPanel, function(ns,set) set(ns); Config.HideKawaifuFromPanel=ns; SaveConfig() end)
local rCleanErr = CreateRow("Clean Error GUIs", nil, "Admin")
CreateToggleSwitch(rCleanErr, Config.CleanErrorGUIs, function(ns,set) set(ns); Config.CleanErrorGUIs=ns; SaveConfig() end)
 
-- ── CANVAS SIZE AUTO-UPDATE ───────────────────────────────────────────
sLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    sList.CanvasSize = UDim2.new(0,0,0, sLayout.AbsoluteContentSize.Y+12)
end)
 

task.spawn(function()
    task.wait(1)
    if Config.HideAdminPanel then
        local adUI = PlayerGui:FindFirstChild("XiAdminPanel")
        if adUI then adUI.Enabled = false end
    end
    if Config.HideAutoSteal then
        local asUI = PlayerGui:FindFirstChild("AutoStealUI")
        if asUI then asUI.Enabled = false end
    end
    if Config.CompactAutoSteal then
        local asUI = PlayerGui:FindFirstChild("AutoStealUI")
        if asUI and asUI:FindFirstChild("Frame") then
            local frame = asUI.Frame
            local mobileScale = IS_MOBILE and 0.6 or 1
            frame.Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, 5 * 44 + 135)
        end
    end
end)

local function parseMinGen(str)
    if not str or type(str) ~= "string" then return 0 end
    str = str:gsub("%s", ""):lower()
    if str == "" then return 0 end
    local num, suffix = str:match("^([%d%.]+)([kmb]?)$")
    if not num then return 0 end
    num = tonumber(num)
    if not num or num < 0 then return 0 end
    if suffix == "k" then return num * 1e3
    elseif suffix == "m" then return num * 1e6
    elseif suffix == "b" then return num * 1e9
    end
    return num
end

if Config.TpSettings.TpOnLoad then
    task.spawn(function()
        local t = 0
        local player = game.Players.LocalPlayer

        while not SharedState.SelectedPetData and t < 150 do
            task.wait(0.1)
            t = t + 1
        end

        if not SharedState.SelectedPetData then
            ShowNotification("TIMEOUT", "Auto TP timed out.")
            return
        end

        local minGen = parseMinGen(Config.TpSettings.MinGenForTp)
        if minGen > 0 then
            local waitCache = 0
            while (not SharedState.AllAnimalsCache or #SharedState.AllAnimalsCache == 0) and waitCache < 100 do
                task.wait(0.1)
                waitCache = waitCache + 1
            end
            local cache = SharedState.AllAnimalsCache or {}
            local highestGen = (cache[1] and cache[1].genValue) or 0
            if highestGen < minGen then
                ShowNotification("MIN GEN", "Highest brainrot below " .. (Config.TpSettings.MinGenForTp or "") .. ", skipping auto TP.")
                return
            end
        end

        runAutoSnipe()
    end)
end


LocalPlayer:GetAttributeChangedSignal("Stealing"):Connect(function()
    local isStealing = LocalPlayer:GetAttribute("Stealing")
    local wasStealing = not isStealing 

    if isStealing then
        if Config.AutoInvisDuringSteal and _G.toggleInvisibleSteal and not _G.invisibleStealEnabled then
            _G.toggleInvisibleSteal()
        end
        if Config.AutoUnlockOnSteal then
            pcall(triggerClosestUnlock, nil, 19)
        end
    elseif wasStealing then
        if Config.AutoInvisDuringSteal and _G.toggleInvisibleSteal and _G.invisibleStealEnabled then
            _G.toggleInvisibleSteal()
        end
    end
end)

task.spawn(function()
    local stealSpeedEnabled = false
    local STEAL_SPEED = Config.StealSpeed or 25.5
    local stealConn = nil

    local function doDisable()
        stealSpeedEnabled = false
        if stealConn then stealConn:Disconnect(); stealConn=nil end
    end
    SharedState.DisableStealSpeed = function()
        doDisable()
        if SharedState._ssUpdateBtn then SharedState._ssUpdateBtn() end
    end

    local function doEnable()
        stealSpeedEnabled = true
        if stealConn then stealConn:Disconnect(); stealConn=nil end
        stealConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character; if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end
            local md = hum.MoveDirection
            if md.Magnitude > 0 then
                hrp.AssemblyLinearVelocity = Vector3.new(
                    md.X * STEAL_SPEED, hrp.AssemblyLinearVelocity.Y, md.Z * STEAL_SPEED)
            end
        end)
    end

    local ssGui = Instance.new("ScreenGui")
    ssGui.Name = "StealSpeedUI"; ssGui.ResetOnSpawn = false
    ssGui.Enabled = Config.ShowStealSpeedPanel
    ssGui.Parent = PlayerGui

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        ssGui.Enabled = Config.ShowStealSpeedPanel
    end)

    local ssFrame = Instance.new("Frame")
    local mobileScale = IS_MOBILE and 0.6 or 1
    -- Keep height tall enough on mobile so the ENABLED button doesn't cover the slider (slider Y=46, button needs to start below)
    local ssHeight = IS_MOBILE and 126 or (126 * mobileScale)
    ssFrame.Size = UDim2.new(0, 300 * mobileScale, 0, ssHeight)
    ssFrame.Position = UDim2.new(
        Config.Positions.StealSpeed.X, 0,
        Config.Positions.StealSpeed.Y, 0)
    ssFrame.BackgroundColor3 = Theme.Background; ssFrame.BackgroundTransparency = 0.05
    ssFrame.BorderSizePixel = 0; ssFrame.Parent = ssGui

    ApplyViewportUIScale(ssFrame, 300, 126, 0.55, 1)
    Instance.new("UICorner", ssFrame).CornerRadius = UDim.new(0,12)
    local ssStroke = Instance.new("UIStroke", ssFrame)
    ssStroke.Color=Theme.Accent2; ssStroke.Thickness=1.5; ssStroke.Transparency=0.4
    CreateGradient(ssStroke)

    local ssDragHandle = Instance.new("Frame", ssFrame)
    ssDragHandle.Size = UDim2.new(1,0,0,38)
    ssDragHandle.BackgroundTransparency = 1
    MakeDraggable(ssDragHandle, ssFrame, "StealSpeed")

    local ssTitle = Instance.new("TextLabel", ssDragHandle)
    ssTitle.Size = UDim2.new(1,-15,1,0); ssTitle.Position = UDim2.new(0,15,0,0)
    ssTitle.BackgroundTransparency=1; ssTitle.Text="STEAL SPEED"
    ssTitle.Font=Enum.Font.GothamBlack; ssTitle.TextSize=15
    ssTitle.TextColor3=Theme.TextPrimary; ssTitle.TextXAlignment=Enum.TextXAlignment.Left

    local speedReadout = Instance.new("TextLabel", ssFrame)
    speedReadout.Size = UDim2.new(0,56,0,38); speedReadout.Position = UDim2.new(1,-66,0,0)
    speedReadout.BackgroundTransparency=1
    speedReadout.Text=string.format("%.1f", STEAL_SPEED)
    speedReadout.Font=Enum.Font.GothamBlack; speedReadout.TextSize=15
    speedReadout.TextColor3=Theme.Accent1; speedReadout.TextXAlignment=Enum.TextXAlignment.Right

    local SLIDER_X_PAD = 16
    local sliderBg = Instance.new("Frame", ssFrame)
    sliderBg.Size = UDim2.new(1,-SLIDER_X_PAD*2,0,6)
    sliderBg.Position = UDim2.new(0,SLIDER_X_PAD,0,46)
    sliderBg.BackgroundColor3=Theme.SurfaceHighlight; sliderBg.BorderSizePixel=0
    Instance.new("UICorner",sliderBg).CornerRadius=UDim.new(1,0)

    local sliderFill = Instance.new("Frame", sliderBg)
    sliderFill.BackgroundColor3=Theme.Accent1; sliderFill.BorderSizePixel=0; sliderFill.Size=UDim2.new(0,0,1,0)
    Instance.new("UICorner",sliderFill).CornerRadius=UDim.new(1,0)

    local knob = Instance.new("Frame", ssFrame)
    knob.Size = UDim2.new(0,16,0,16); knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.BackgroundColor3=Color3.fromRGB(255,255,255); knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    local knobStroke=Instance.new("UIStroke",knob); knobStroke.Color=Theme.Accent1; knobStroke.Thickness=2

    local MIN_SPEED,MAX_SPEED = 5, 100

    local function speedToT(s) return math.clamp((s-MIN_SPEED)/(MAX_SPEED-MIN_SPEED),0,1) end
    local function updateSlider(s)
        STEAL_SPEED = math.clamp(s, MIN_SPEED, MAX_SPEED)
        Config.StealSpeed = STEAL_SPEED; SaveConfig()
        local t = speedToT(STEAL_SPEED)
        sliderFill.Size = UDim2.new(t,0,1,0)
        local frameW = ssFrame.AbsoluteSize.X
        local trackW = frameW - SLIDER_X_PAD*2
        local knobX = SLIDER_X_PAD + t*trackW
        knob.Position = UDim2.new(0, knobX, 0, 46+3)
        speedReadout.Text = string.format("%.1f", STEAL_SPEED)
    end

    task.defer(function() updateSlider(STEAL_SPEED) end)
    ssFrame.Changed:Connect(function(prop)
        if prop=="AbsoluteSize" then updateSlider(STEAL_SPEED) end
    end)

    local sliderDragging = false
    local function onSliderInput(pos)
        local trackLeft = sliderBg.AbsolutePosition.X
        local trackRight = trackLeft + sliderBg.AbsoluteSize.X
        local t = math.clamp((pos.X - trackLeft)/(trackRight-trackLeft), 0, 1)
        updateSlider(MIN_SPEED + t*(MAX_SPEED-MIN_SPEED))
    end

    sliderBg.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            sliderDragging=true; onSliderInput(inp.Position)
        end
    end)
    knob.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then sliderDragging=true end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then sliderDragging=false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if sliderDragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            onSliderInput(inp.Position)
        end
    end)

    local minLbl=Instance.new("TextLabel",ssFrame)
    minLbl.Size=UDim2.new(0,30,0,14); minLbl.Position=UDim2.new(0,SLIDER_X_PAD,0,55)
    minLbl.BackgroundTransparency=1; minLbl.Text="5"
    minLbl.Font=Enum.Font.GothamMedium; minLbl.TextSize=10
    minLbl.TextColor3=Theme.TextSecondary; minLbl.TextXAlignment=Enum.TextXAlignment.Left

    local maxLbl=Instance.new("TextLabel",ssFrame)
    maxLbl.Size=UDim2.new(0,36,0,14); maxLbl.Position=UDim2.new(1,-SLIDER_X_PAD-36,0,55)
    maxLbl.BackgroundTransparency=1; maxLbl.Text="100"
    maxLbl.Font=Enum.Font.GothamMedium; maxLbl.TextSize=10
    maxLbl.TextColor3=Theme.TextSecondary; maxLbl.TextXAlignment=Enum.TextXAlignment.Right

    local ssBtn = Instance.new("TextButton", ssFrame)
    ssBtn.Size=UDim2.new(1,-32,0,34); ssBtn.Position=UDim2.new(0,16,1,-48)
    ssBtn.BackgroundColor3=Theme.SurfaceHighlight
    ssBtn.Text="DISABLED"; ssBtn.Font=Enum.Font.GothamBold
    ssBtn.TextSize=13; ssBtn.TextColor3=Theme.TextPrimary
    Instance.new("UICorner",ssBtn).CornerRadius=UDim.new(0,8)

    local function updateBtnVisual()
        ssBtn.Text = stealSpeedEnabled and "ENABLED" or "DISABLED"
        ssBtn.BackgroundColor3 = stealSpeedEnabled and Theme.Success or Theme.SurfaceHighlight
    end
    SharedState._ssUpdateBtn = updateBtnVisual

    SharedState.StealSpeedToggleFunc = function()
        if stealSpeedEnabled then doDisable() else doEnable() end
        updateBtnVisual()
    end

    ssBtn.MouseButton1Click:Connect(function()
        SharedState.StealSpeedToggleFunc()
    end)

    task.spawn(function()
        local lastHadSteal = nil
        while true do
            task.wait(0.3)
            if not Config.AutoStealSpeed then lastHadSteal = nil; continue end
            local hasSteal = (LocalPlayer:GetAttribute("Stealing") == true)
            if lastHadSteal == hasSteal then continue end
            lastHadSteal = hasSteal
            if hasSteal and not stealSpeedEnabled then
                doEnable(); updateBtnVisual()
            elseif not hasSteal and stealSpeedEnabled then
                doDisable(); if SharedState._ssUpdateBtn then SharedState._ssUpdateBtn() end
            end
        end
    end)
end)

task.spawn(function()
    local brainrotESPEnabled = Config.BrainrotESP
    local brainrotESPFolder = Instance.new("Folder")
    brainrotESPFolder.Name = "XiBrainrotESP"
    brainrotESPFolder.Parent = Workspace
    local brainrotBillboards = {}
    local hiddenOverheads = {}
    local MUT_COLORS = {
        Cursed = Color3.fromRGB(255, 50, 50),
        Gold = Color3.fromRGB(255, 215, 0),
        Diamond = Color3.fromRGB(0, 255, 255),
        YinYang = Color3.fromRGB(220, 220, 220),
        Rainbow = Color3.fromRGB(255, 100, 200),
        Lava = Color3.fromRGB(255, 100, 20),
        Candy = Color3.fromRGB(255, 105, 180),
        Bloodrot = Color3.fromRGB(139, 0, 0),
        Radioactive = Color3.fromRGB(0, 255, 0),
        Divine = Color3.fromRGB(255, 255, 255)
    }
    
    local function createBrainrotBillboard(data)
        local bb = Instance.new("BillboardGui")
        bb.Name = "BrainrotESP_" .. data.uid
        bb.Size = UDim2.new(0, 160, 0, 38)
        bb.StudsOffset = Vector3.new(0, 1.8, 0)
        bb.AlwaysOnTop = true
        bb.LightInfluence = 0
        bb.MaxDistance = 3000
        
        local hasMut = data.mutation and data.mutation ~= "None" and data.mutation ~= "N/A"
        local color = hasMut and (MUT_COLORS[data.mutation] or Color3.fromRGB(200, 100, 255)) or Color3.fromRGB(0, 255, 150)
        
        local container = Instance.new("Frame", bb)
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        container.BackgroundTransparency = 0.5
        container.BorderSizePixel = 0
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 4)
        
        local stroke = Instance.new("UIStroke", container)
        stroke.Color = color
        stroke.Thickness = 1.5
        stroke.Transparency = 0.2
        
        local nameLabel = Instance.new("TextLabel", container)
        nameLabel.Size = UDim2.new(1, -6, 0, 18)
        nameLabel.Position = UDim2.new(0, 3, 0, 2)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBlack
        nameLabel.TextSize = 13
        nameLabel.TextColor3 = color
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.Text = (data.name or data.petName) or "???"
        nameLabel.TextXAlignment = Enum.TextXAlignment.Center
        
        local genLabel = Instance.new("TextLabel", container)
        genLabel.Size = UDim2.new(1, -6, 0, 14)
        genLabel.Position = UDim2.new(0, 3, 0, 20)
        genLabel.BackgroundTransparency = 1
        genLabel.Font = Enum.Font.GothamBold
        genLabel.TextSize = 11
        genLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        genLabel.TextStrokeTransparency = 0
        genLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        genLabel.Text = data.genText or ""
        genLabel.TextXAlignment = Enum.TextXAlignment.Center
        
        if hasMut then
            local mutBadge = Instance.new("TextLabel", bb)
            mutBadge.Size = UDim2.new(0, 60, 0, 14)
            mutBadge.Position = UDim2.new(0.5, -30, 0, -16)
            mutBadge.BackgroundColor3 = color
            mutBadge.BackgroundTransparency = 0.3
            mutBadge.Font = Enum.Font.GothamBlack
            mutBadge.TextSize = 9
            mutBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
            mutBadge.TextStrokeTransparency = 0
            mutBadge.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            mutBadge.Text = data.mutation:upper()
            Instance.new("UICorner", mutBadge).CornerRadius = UDim.new(0, 3)
        end
        
        return bb
    end
    
    local function hideDefaultOverhead(overhead)
        if overhead and overhead.Parent and not hiddenOverheads[overhead] then
            hiddenOverheads[overhead] = overhead.Enabled
            overhead.Enabled = false
        end
    end
    
    local function showDefaultOverhead(overhead)
        if overhead and hiddenOverheads[overhead] ~= nil then
            overhead.Enabled = hiddenOverheads[overhead]
            hiddenOverheads[overhead] = nil
        end
    end
    
    local function restoreAllOverheads()
        for overhead, wasEnabled in pairs(hiddenOverheads) do
            if overhead and overhead.Parent then
                overhead.Enabled = wasEnabled
            end
        end
        hiddenOverheads = {}
    end
    
    local function refreshBrainrotESP()
        if not brainrotESPEnabled then return end
        local cache = SharedState.AllAnimalsCache
        if not cache or #cache == 0 then 
            return 
        end
        
        local seen = {}
        for _, data in ipairs(cache) do
            if data.genValue >= 10000000 then
                seen[data.uid] = true
                
                if not brainrotBillboards[data.uid] then
                    local adornee = nil
                    local overhead = nil
                    local studsOffset = Vector3.new(0, 1.8, 0)
                    
                    if data.overhead and data.overhead.Parent then
                        overhead = data.overhead
                        if overhead:IsA("BillboardGui") then
                            studsOffset = overhead.StudsOffset
                        end
                        hideDefaultOverhead(overhead)
                        adornee = overhead.Parent
                        if not adornee:IsA("BasePart") then
                            adornee = adornee:FindFirstChildWhichIsA("BasePart", true)
                        end
                    end
                    
                    if not adornee and data.plot and data.slot then
                        adornee = findAdorneeGlobal(data)
                        if adornee then
                            local model = adornee.Parent
                            if model and model:IsA("Model") then
                                overhead = model:FindFirstChild("AnimalOverhead", true)
                                if not overhead then
                                    for _, child in ipairs(model:GetDescendants()) do
                                        if child.Name == "AnimalOverhead" and child:IsA("BillboardGui") then
                                            overhead = child
                                            break
                                        end
                                    end
                                end
                                
                                if overhead then
                                    if overhead:IsA("BillboardGui") then
                                        studsOffset = overhead.StudsOffset
                                    end
                                    hideDefaultOverhead(overhead)
                                end
                            end
                        end
                    end
                    
                    if adornee then
                        local bb = createBrainrotBillboard(data)
                        bb.Adornee = adornee
                        bb.StudsOffset = studsOffset
                        bb.Parent = adornee
                        brainrotBillboards[data.uid] = {bb = bb, overhead = overhead}
                    end
                end
            end
        end
        
        for uid, entry in pairs(brainrotBillboards) do
            if not seen[uid] then
                if entry.bb then entry.bb:Destroy() end
                if entry.overhead then showDefaultOverhead(entry.overhead) end
                brainrotBillboards[uid] = nil
            end
        end
    end
    
    local function clearBrainrotESP()
        for _, entry in pairs(brainrotBillboards) do
            if entry.bb then entry.bb:Destroy() end
            if entry.overhead then showDefaultOverhead(entry.overhead) end
        end
        brainrotBillboards = {}
        restoreAllOverheads()
    end
    
    espToggleRef.setFn = function(enabled)
        brainrotESPEnabled = enabled
        if enabled then
            task.spawn(function()
                task.wait(1)
                for i = 1, 5 do
                    pcall(refreshBrainrotESP)
                    task.wait(1)
                end
            end)
        else
            clearBrainrotESP()
        end
    end
    
    task.spawn(function()
        while true do
            task.wait(0.3)
            if brainrotESPEnabled then
                local cache = SharedState.AllAnimalsCache
                if cache and #cache > 0 then
                    pcall(refreshBrainrotESP)
                end
            end
        end
    end)
    
    task.spawn(function()
        while true do
            task.wait(2)
            if brainrotESPEnabled then
                local cache = SharedState.AllAnimalsCache
                if cache and #cache > 0 then
                    if next(brainrotBillboards) == nil then
                        clearBrainrotESP()
                    end
                    pcall(refreshBrainrotESP)
                end
            end
        end
    end)
end)

task.spawn(function()
	local animPlaying = false
	local tracks = {}
	local clone, oldRoot, hip, connection
	local folderConnections = {}
	local SINK_AMOUNT = 5
	local serverGhosts = {}
	local ghostEnabled = true
	local lagbackCallCount = 0
	local lagbackWindowStart = 0
	local lastLagbackTime = 0
	local errorOrbActive = false
	local errorOrb = nil
	local errorOrbConnection = nil

	local function clearErrorOrb()
		if errorOrb and errorOrb.Parent then errorOrb:Destroy() end
		errorOrb = nil; errorOrbActive = false
		if errorOrbConnection then errorOrbConnection:Disconnect(); errorOrbConnection = nil end
	end

	local function createErrorOrb()
		if errorOrbActive then return end
		errorOrbActive = true
		for _, ghost in pairs(serverGhosts) do if ghost and ghost.Parent then ghost:Destroy() end end
		serverGhosts = {}
		local sg = Instance.new("ScreenGui")
		sg.Name = "ErrorOrbGui"; sg.ResetOnSpawn = false
		sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
		local fr = Instance.new("Frame")
		fr.Size = UDim2.new(0, 500, 0, 60)
		fr.Position = UDim2.new(0.5, -250, 0.3, 0)
		fr.BackgroundTransparency = 1; fr.BorderSizePixel = 0; fr.Parent = sg
		local l1 = Instance.new("TextLabel")
		l1.Size = UDim2.new(1, 0, 0.5, 0); l1.BackgroundTransparency = 1
		l1.Text = "ERROR CAUSED BY PLAYER DEATH"
		l1.TextColor3 = Color3.fromRGB(255, 0, 0)
		l1.TextStrokeTransparency = 0; l1.TextStrokeColor3 = Color3.new(0, 0, 0)
		l1.Font = Enum.Font.SourceSansBold; l1.TextScaled = true; l1.Parent = fr
		local l2 = Instance.new("TextLabel")
		l2.Size = UDim2.new(1, 0, 0.5, 0); l2.Position = UDim2.new(0, 0, 0.5, 0)
		l2.BackgroundTransparency = 1; l2.Text = "MUST RESET TO FIX ERROR"
		l2.TextColor3 = Color3.fromRGB(255, 0, 0)
		l2.TextStrokeTransparency = 0; l2.TextStrokeColor3 = Color3.new(0, 0, 0)
		l2.Font = Enum.Font.SourceSansBold; l2.TextScaled = true; l2.Parent = fr
		errorOrb = sg
	end

	local function createServerGhost(position)
		if not ghostEnabled or errorOrbActive then return end
		local now = tick()
		if now - lastLagbackTime < 0.05 then return end
		lastLagbackTime = now
		if now - lagbackWindowStart > 1 then lagbackCallCount = 0; lagbackWindowStart = now end
		lagbackCallCount = lagbackCallCount + 1
		if lagbackCallCount >= 7 then createErrorOrb(); return end
		for _, g in pairs(serverGhosts) do if g and g.Parent then g:Destroy() end end
		serverGhosts = {}
		local sg = Instance.new("ScreenGui")
		sg.Name = "LagbackNotification"; sg.ResetOnSpawn = false
		sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
		local sl = Instance.new("TextLabel")
		sl.Size = UDim2.new(0, 500, 0, 30); sl.Position = UDim2.new(0.5, -250, 0.15, 0)
		sl.BackgroundTransparency = 1; sl.Text = "LAGBACK DETECTED"
		sl.TextColor3 = Color3.fromRGB(255, 0, 0)
		sl.TextStrokeTransparency = 0; sl.TextStrokeColor3 = Color3.new(0, 0, 0)
		sl.Font = Enum.Font.SourceSansBold; sl.TextScaled = true; sl.Parent = sg
		local sw = Instance.new("TextLabel")
		sw.Size = UDim2.new(0, 650, 0, 25); sw.Position = UDim2.new(0.5, -325, 0.15, 32)
		sw.BackgroundTransparency = 1
		sw.Text = "DISABLE INVISIBLE STEAL NOW OR YOU WILL BE KILLED BY ANTICHEAT"
		sw.TextColor3 = Color3.fromRGB(200, 200, 200)
		sw.TextStrokeTransparency = 0; sw.TextStrokeColor3 = Color3.new(0, 0, 0)
		sw.Font = Enum.Font.SourceSansBold; sw.TextScaled = true; sw.Parent = sg
		task.delay(1.5, function() if sg and sg.Parent then sg:Destroy() end end)
		local ghost = Instance.new("Part")
		ghost.Name = "LagbackGhost"; ghost.Shape = Enum.PartType.Ball
		ghost.Size = Vector3.new(3, 3, 3); ghost.Color = Color3.fromRGB(255, 0, 0)
		ghost.Material = Enum.Material.Glass; ghost.Transparency = 0.3
		ghost.CanCollide = false; ghost.Anchored = true; ghost.CastShadow = false
		ghost.Position = position + Vector3.new(0, 5, 0); ghost.Parent = Workspace.CurrentCamera
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 400, 0, 60); bb.StudsOffset = Vector3.new(0, 4, 0)
		bb.AlwaysOnTop = true; bb.Parent = ghost
		local bl = Instance.new("TextLabel")
		bl.Size = UDim2.new(1, 0, 0, 25); bl.BackgroundTransparency = 1
		bl.Text = "LAGBACK DETECTED"; bl.TextColor3 = Color3.fromRGB(255, 0, 0)
		bl.TextStrokeTransparency = 0; bl.TextStrokeColor3 = Color3.new(0, 0, 0)
		bl.Font = Enum.Font.SourceSansBold; bl.TextScaled = true; bl.Parent = bb
		local bw = Instance.new("TextLabel")
		bw.Size = UDim2.new(1, 0, 0, 25); bw.Position = UDim2.new(0, 0, 0, 25)
		bw.BackgroundTransparency = 1
		bw.Text = "DISABLE INVISIBLE STEAL NOW OR YOU WILL BE KILLED BY ANTICHEAT"
		bw.TextColor3 = Color3.fromRGB(200, 200, 200)
		bw.TextStrokeTransparency = 0; bw.TextStrokeColor3 = Color3.new(0, 0, 0)
		bw.Font = Enum.Font.SourceSansBold; bw.TextScaled = true; bw.Parent = bb
		table.insert(serverGhosts, ghost)
	end

	local function clearAllGhosts()
		for _, ghost in pairs(serverGhosts) do pcall(function() if ghost and ghost.Parent then ghost:Destroy() end end) end
		serverGhosts = {}; clearErrorOrb(); lagbackCallCount = 0; lastLagbackTime = 0
		pcall(function()
			local pg = LocalPlayer:FindFirstChild("PlayerGui")
			if pg then for _, gui in pairs(pg:GetChildren()) do if gui.Name == "LagbackNotification" then gui:Destroy() end end end
		end)
		pcall(function() if Workspace.CurrentCamera then for _, c in pairs(Workspace.CurrentCamera:GetChildren()) do if c.Name == "LagbackGhost" then c:Destroy() end end end end)
		pcall(function() for _, c in pairs(Workspace:GetDescendants()) do if c.Name == "LagbackGhost" then c:Destroy() end end end)
	end

	local function removeFolders()
		local pf = Workspace:FindFirstChild(LocalPlayer.Name)
		if not pf then return end
		local dr = pf:FindFirstChild("DoubleRig")
		if dr then
			local rr = dr:FindFirstChild("HumanoidRootPart") or dr:FindFirstChildWhichIsA("BasePart")
			if rr and ghostEnabled then createServerGhost(rr.Position) end
			dr:Destroy()
		end
		local cs = pf:FindFirstChild("Constraints")
		if cs then cs:Destroy() end
		local conn = pf.ChildAdded:Connect(function(child)
			if child.Name == "DoubleRig" then
				task.defer(function()
					local rr = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChildWhichIsA("BasePart")
					if rr and ghostEnabled then createServerGhost(rr.Position) end
					child:Destroy()
				end)
			elseif child.Name == "Constraints" then child:Destroy() end
		end)
		table.insert(folderConnections, conn)
	end

	local function doClone()
		local character = LocalPlayer.Character
		if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
			hip = character.Humanoid.HipHeight
			oldRoot = character:FindFirstChild("HumanoidRootPart")
			if not oldRoot or not oldRoot.Parent then return false end
			for _, c in pairs(oldRoot:GetChildren()) do
				if c:IsA("Attachment") and (c.Name:find("Beam") or c.Name:find("Attach")) then c:Destroy() end
			end
			for _, c in pairs(oldRoot:GetChildren()) do if c:IsA("Beam") then c:Destroy() end end
			local tmp = Instance.new("Model"); tmp.Parent = game
			character.Parent = tmp
			clone = oldRoot:Clone(); clone.Parent = character
			oldRoot.Parent = Workspace.CurrentCamera
			clone.CFrame = oldRoot.CFrame; character.PrimaryPart = clone
			character.Parent = Workspace
			for _, v in pairs(character:GetDescendants()) do
				if v:IsA("Weld") or v:IsA("Motor6D") then
					if v.Part0 == oldRoot then v.Part0 = clone end
					if v.Part1 == oldRoot then v.Part1 = clone end
				end
			end
			tmp:Destroy(); return true
		end
		return false
	end

	local function revertClone()
		local character = LocalPlayer.Character
		if not oldRoot or not oldRoot:IsDescendantOf(Workspace) or not character or character.Humanoid.Health <= 0 then return end
		local tmp = Instance.new("Model"); tmp.Parent = game
		character.Parent = tmp
		oldRoot.Parent = character; character.PrimaryPart = oldRoot
		character.Parent = Workspace; oldRoot.CanCollide = true
		for _, v in pairs(character:GetDescendants()) do
			if v:IsA("Weld") or v:IsA("Motor6D") then
				if v.Part0 == clone then v.Part0 = oldRoot end
				if v.Part1 == clone then v.Part1 = oldRoot end
			end
		end
		if clone then local p = clone.CFrame; clone:Destroy(); clone = nil; oldRoot.CFrame = p end
		oldRoot = nil
		if character and character.Humanoid then character.Humanoid.HipHeight = hip end
		clearAllGhosts()
	end

	local function animationTrickery()
		local character = LocalPlayer.Character
		if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
			local anim = Instance.new("Animation")
			anim.AnimationId = "http://www.roblox.com/asset/?id=18537363391"
			local humanoid = character.Humanoid
			local animator = humanoid:FindFirstChild("Animator") or Instance.new("Animator", humanoid)
			local animTrack = animator:LoadAnimation(anim)
			animTrack.Priority = Enum.AnimationPriority.Action4
			animTrack:Play(0, 1, 0); anim:Destroy()
			table.insert(tracks, animTrack)
			animTrack.Stopped:Connect(function() if animPlaying then animationTrickery() end end)
			task.delay(0, function()
				animTrack.TimePosition = 0.7
				task.delay(0.3, function() if animTrack then animTrack:AdjustSpeed(math.huge) end end)
			end)
		end
	end

	local function turnOff()
		clearAllGhosts()
		if not animPlaying then return end
		local character = LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		animPlaying = false; _G.invisibleStealEnabled = false
		for _, t in pairs(tracks) do pcall(function() t:Stop() end) end
		tracks = {}
		if connection then connection:Disconnect(); connection = nil end
		for _, c in ipairs(folderConnections) do if c then c:Disconnect() end end
		folderConnections = {}
		revertClone(); clearAllGhosts()
		if humanoid then pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
		if _G.updateMovementPanelInvisVisual then pcall(_G.updateMovementPanelInvisVisual, false) end
		if updateVisualState then updateVisualState(false) end
	end

	local function turnOn()
		if animPlaying then return end
		local character = LocalPlayer.Character
		if not character then return end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end
		animPlaying = true; _G.invisibleStealEnabled = true
		if _G.updateMovementPanelInvisVisual then pcall(_G.updateMovementPanelInvisVisual, true) end
		if updateVisualState then updateVisualState(true) end
		tracks = {}; removeFolders()
		local success = doClone()
		if success then
			task.wait(0.05); animationTrickery()
			task.defer(function()
				if _G.resetBrainrotBeam then pcall(_G.resetBrainrotBeam) end
				if _G.resetPlotBeam then pcall(_G.resetPlotBeam) end
				task.wait(0.1)
				if _G.updateBrainrotBeam then pcall(_G.updateBrainrotBeam) end
				if _G.createPlotBeam then pcall(_G.createPlotBeam) end
			end)
			local lastSetPosition = nil; local skipFrames = 5
			connection = RunService.PreSimulation:Connect(function()
				if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 and oldRoot then
					local root = character.PrimaryPart or character:FindFirstChild("HumanoidRootPart")
					if root then
						if skipFrames > 0 then skipFrames = skipFrames - 1; lastSetPosition = nil
						elseif lastSetPosition and ghostEnabled then
							local currentPos = oldRoot.Position
							local jumpDist = (currentPos - lastSetPosition).Magnitude
							if jumpDist > 3 and not _G.RecoveryInProgress then
								lastSetPosition = nil; createServerGhost(currentPos)
								if _G.AutoRecoverLagback and _G.toggleInvisibleSteal then
									_G.RecoveryInProgress = true
									task.spawn(function()
										pcall(_G.toggleInvisibleSteal); task.wait(0.5)
										pcall(_G.toggleInvisibleSteal); _G.RecoveryInProgress = false
									end)
								end
							end
						end
						if clone then clone.CanCollide = false end
						for _, c in pairs(oldRoot:GetChildren()) do
							if c:IsA("Attachment") or c:IsA("Beam") then c:Destroy() end
						end
						local rotAngle = _G.InvisStealAngle or 180
						local sa = (_G.SinkSliderValue or 5) * 0.5
						local cf = root.CFrame - Vector3.new(0, sa, 0)
						oldRoot.CFrame = cf * CFrame.Angles(math.rad(rotAngle), 0, 0)
						oldRoot.AssemblyLinearVelocity = root.AssemblyLinearVelocity; oldRoot.CanCollide = false
						lastSetPosition = oldRoot.Position
					end
				end
			end)
		end
	end

    local invisGui = Instance.new("ScreenGui")
    invisGui.Name = "XiInvisPanel"
    invisGui.ResetOnSpawn = false
    invisGui.Parent = PlayerGui
    invisGui.Enabled = Config.ShowInvisPanel

    local iFrame = Instance.new("Frame", invisGui)
    iFrame.Size = UDim2.new(0, 250, 0, 260)
    iFrame.Position = UDim2.new(Config.Positions.InvisPanel.X, 0, Config.Positions.InvisPanel.Y, 0)
    iFrame.BackgroundColor3 = Theme.Background
    iFrame.BackgroundTransparency = 0.05
    Instance.new("UICorner", iFrame).CornerRadius = UDim.new(0, 12)
    local iStroke = Instance.new("UIStroke", iFrame)
    iStroke.Color = Theme.Accent2
    iStroke.Thickness = 1.5
    iStroke.Transparency = 0.4
    CreateGradient(iStroke)

    local iHeader = Instance.new("Frame", iFrame)
    iHeader.Size = UDim2.new(1, 0, 0, 35)
    iHeader.BackgroundTransparency = 1
    MakeDraggable(iHeader, iFrame, "InvisPanel")

    local iTitle = Instance.new("TextLabel", iHeader)
    iTitle.Size = UDim2.new(1, -15, 1, 0)
    iTitle.Position = UDim2.new(0, 15, 0, 0)
    iTitle.BackgroundTransparency = 1
    iTitle.Text = "INVISIBLE STEAL"
    iTitle.Font = Enum.Font.GothamBlack
    iTitle.TextSize = 14
    iTitle.TextColor3 = Theme.TextPrimary
    iTitle.TextXAlignment = Enum.TextXAlignment.Left

    local iContainer = Instance.new("Frame", iFrame)
    iContainer.Size = UDim2.new(1, -20, 1, -40)
    iContainer.Position = UDim2.new(0, 10, 0, 35)
    iContainer.BackgroundTransparency = 1
    local iLayout = Instance.new("UIListLayout", iContainer)
    iLayout.Padding = UDim.new(0, 8)
    iLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function CreateIRow(height)
        local r = Instance.new("Frame", iContainer)
        r.Size = UDim2.new(1, 0, 0, height or 30)
        r.BackgroundTransparency = 1
        return r
    end

    local row1 = CreateIRow(30)
    local lbl1 = Instance.new("TextLabel", row1)
    lbl1.Size = UDim2.new(0.6, 0, 1, 0)
    lbl1.BackgroundTransparency = 1
    lbl1.Text = "Toggle Invis"
    lbl1.TextColor3 = Theme.TextPrimary
    lbl1.Font = Enum.Font.GothamBold
    lbl1.TextSize = 12
    lbl1.TextXAlignment = Enum.TextXAlignment.Left

    local btnInvis = Instance.new("TextButton", row1)
    btnInvis.Size = UDim2.new(0, 40, 0, 24)
    btnInvis.Position = UDim2.new(1, -40, 0.5, -12)
    btnInvis.BackgroundColor3 = Theme.SurfaceHighlight
    btnInvis.Text = "OFF"
    btnInvis.Font = Enum.Font.GothamBold
    btnInvis.TextSize = 11
    btnInvis.TextColor3 = Theme.TextPrimary
    Instance.new("UICorner", btnInvis).CornerRadius = UDim.new(0, 6)

    local keyBtn = Instance.new("TextButton", row1)
    keyBtn.Size = UDim2.new(0, 40, 0, 24)
    keyBtn.Position = UDim2.new(1, -90, 0.5, -12)
    keyBtn.BackgroundColor3 = Theme.Surface
    keyBtn.Text = Config.InvisToggleKey
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.TextColor3 = Theme.Accent1
    keyBtn.TextSize = 11
    Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 6)
    keyBtn.MouseButton1Click:Connect(function()
        keyBtn.Text = "..."
        local c
        c = UserInputService.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Keyboard then
                Config.InvisToggleKey = i.KeyCode.Name
                _G.INVISIBLE_STEAL_KEY = i.KeyCode
                keyBtn.Text = i.KeyCode.Name
                SaveConfig()
                c:Disconnect()
            end
        end)
    end)

    local row2 = CreateIRow(30)
    local lbl2 = Instance.new("TextLabel", row2)
    lbl2.Size = UDim2.new(0.6, 0, 1, 0)
    lbl2.BackgroundTransparency = 1
    lbl2.Text = "Auto Fix Lagback"
    lbl2.TextColor3 = Theme.TextPrimary
    lbl2.Font = Enum.Font.GothamBold
    lbl2.TextSize = 12
    lbl2.TextXAlignment = Enum.TextXAlignment.Left

    local btnFix = Instance.new("TextButton", row2)
    btnFix.Size = UDim2.new(0, 50, 0, 24)
    btnFix.Position = UDim2.new(1, -50, 0.5, -12)
    btnFix.BackgroundColor3 = _G.AutoRecoverLagback and Theme.Success or Theme.SurfaceHighlight
    btnFix.Text = _G.AutoRecoverLagback and "ON" or "OFF"
    btnFix.Font = Enum.Font.GothamBold
    btnFix.TextSize = 11
    btnFix.TextColor3 = Theme.TextPrimary
    Instance.new("UICorner", btnFix).CornerRadius = UDim.new(0, 6)
    btnFix.MouseButton1Click:Connect(function()
        _G.AutoRecoverLagback = not _G.AutoRecoverLagback
        Config.AutoRecoverLagback = _G.AutoRecoverLagback
        SaveConfig()
        btnFix.Text = _G.AutoRecoverLagback and "ON" or "OFF"
        btnFix.BackgroundColor3 = _G.AutoRecoverLagback and Theme.Success or Theme.SurfaceHighlight
    end)

    local function CreateFancySlider(parent, name, min, max, default, callback)
        local frame = Instance.new("Frame", parent)
        frame.Size = UDim2.new(1, 0, 0, IS_MOBILE and 35 or 45)
        frame.BackgroundTransparency = 1
        
        if IS_MOBILE then
            local label = Instance.new("TextLabel", frame)
            label.Size = UDim2.new(0.5, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = Theme.TextSecondary
            label.Font = Enum.Font.GothamBold
            label.TextSize = 11
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Text = name .. ":"
            
            local textBox = Instance.new("TextBox", frame)
            textBox.Size = UDim2.new(0, 80, 0, 28)
            textBox.Position = UDim2.new(1, -80, 0.5, -14)
            textBox.BackgroundColor3 = Theme.Surface
            textBox.BorderSizePixel = 0
            textBox.TextColor3 = Theme.TextPrimary
            textBox.Font = Enum.Font.GothamBold
            textBox.TextSize = 12
            textBox.Text = tostring(default)
            textBox.PlaceholderText = tostring(default)
            textBox.ClearTextOnFocus = false
            Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 6)
            local textBoxStroke = Instance.new("UIStroke", textBox)
            textBoxStroke.Color = Theme.Accent1
            textBoxStroke.Thickness = 1.5
            textBoxStroke.Transparency = 0.3
            
            textBox.FocusLost:Connect(function(enterPressed)
                local num = tonumber(textBox.Text)
                if num then
                    local clamped = math.clamp(num, min, max)
                    if max > 100 then
                        clamped = math.floor(clamped)
                    else
                        clamped = math.floor(clamped * 10) / 10
                    end
                    textBox.Text = tostring(clamped)
                    callback(clamped)
                else
                    textBox.Text = tostring(default)
                end
            end)
            
            return frame
        else
            local label = Instance.new("TextLabel", frame)
            label.Size = UDim2.new(1, 0, 0, 15)
            label.BackgroundTransparency = 1
            label.TextColor3 = Theme.TextSecondary
            label.Font = Enum.Font.GothamBold
            label.TextSize = 10
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Text = name .. ": " .. default
            local slideBg = Instance.new("Frame", frame)
            slideBg.Size = UDim2.new(1, 0, 0, 6)
            slideBg.Position = UDim2.new(0, 0, 0, 25)
            slideBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            Instance.new("UICorner", slideBg).CornerRadius = UDim.new(1, 0)
            slideBg.Parent = frame
            local fill = Instance.new("Frame", slideBg)
            fill.Size = UDim2.new(0, 0, 1, 0)
            fill.BackgroundColor3 = Color3.fromRGB(80, 130, 180)
            fill.ZIndex = 12
            fill.Parent = slideBg
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
            local knob = Instance.new("Frame", slideBg)
            knob.Size = UDim2.new(0, 12, 0, 12)
            knob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            knob.AnchorPoint = Vector2.new(0.5, 0.5)
            knob.Position = UDim2.new(0, 0, 0.5, 0)
            knob.ZIndex = 13
            knob.Parent = slideBg
            Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
            local function update(inputX)
                local p = math.clamp((inputX - slideBg.AbsolutePosition.X) / slideBg.AbsoluteSize.X, 0, 1)
                local val = min + (p * (max - min))
                if max > 100 then val = math.floor(val) else val = math.floor(val*10)/10 end
                fill.Size = UDim2.new(p, 0, 1, 0)
                knob.Position = UDim2.new(p, 0, 0.5, 0)
                label.Text = name .. ": " .. val
                callback(val)
            end
            local dragging = false
            slideBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    update(input.Position.X)
                end
            end)
            knob.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    update(input.Position.X)
                end
            end)
            local p = (default - min)/(max-min)
            fill.Size = UDim2.new(p, 0, 1, 0)
            knob.Position = UDim2.new(p, 0, 0.5, 0)
            return frame
        end
    end

    local rotationSliderManuallyChanged = false
    CreateFancySlider(iContainer, "Rotation", 180, 360, Config.InvisStealAngle, function(v)
        rotationSliderManuallyChanged = true
        Config.InvisStealAngle = v
        _G.InvisStealAngle = v
        SaveConfig()
    end)

    CreateFancySlider(iContainer, "Depth", 0.5, 10, Config.SinkSliderValue, function(v)
        Config.SinkSliderValue = v
        _G.SinkSliderValue = v
        SaveConfig()
    end)


    local function updateVisualState(on)
        if btnInvis then
            btnInvis.Text = on and "ON" or "OFF"
            btnInvis.BackgroundColor3 = on and Theme.Success or Theme.SurfaceHighlight
        end
        if _G.updateMovementPanelInvisVisual then
            pcall(_G.updateMovementPanelInvisVisual, on)
        end
    end

    btnInvis.MouseButton1Click:Connect(function()
		if _G.toggleInvisibleSteal then
			pcall(_G.toggleInvisibleSteal)
			updateVisualState(_G.invisibleStealEnabled or false)
		end
	end)

	_G.toggleInvisibleSteal = function()
		if animPlaying then turnOff() else turnOn() end
	end

	UserInputService.InputBegan:Connect(function(input)
		if UserInputService:GetFocusedTextBox() then return end
		if input.KeyCode == (_G.INVISIBLE_STEAL_KEY or Enum.KeyCode.V) then
			pcall(_G.toggleInvisibleSteal)
			if _G.updateMovementPanelInvisVisual then pcall(_G.updateMovementPanelInvisVisual, _G.invisibleStealEnabled or false) end
			if updateVisualState then updateVisualState(_G.invisibleStealEnabled or false) end
		end
	end)

	local function onCharacterAdded(newChar)
		clearErrorOrb(); clearAllGhosts(); lagbackCallCount = 0
		pcall(function() for _, c in pairs(Workspace.CurrentCamera:GetChildren()) do if c:IsA("BasePart") and c.Name == "HumanoidRootPart" then c:Destroy() end end end)
		if oldRoot then pcall(function() oldRoot:Destroy() end); oldRoot = nil end
		if clone then pcall(function() clone:Destroy() end); clone = nil end
		animPlaying = false; _G.invisibleStealEnabled = false
		if _G.updateMovementPanelInvisVisual then pcall(_G.updateMovementPanelInvisVisual, false) end
		task.wait(0.2)
		local camera = Workspace.CurrentCamera
		if camera and newChar then
			local h = newChar:FindFirstChildOfClass("Humanoid")
			if h then camera.CameraSubject = h; camera.CameraType = Enum.CameraType.Custom end
		end
	end
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

    local function setupDeathListener()
        local ch = LocalPlayer.Character
        if ch then
            local h = ch:FindFirstChildOfClass("Humanoid")
            if h then h.Died:Connect(function() clearErrorOrb(); clearAllGhosts(); lagbackCallCount = 0 end) end
        end
    end
    setupDeathListener()
    LocalPlayer.CharacterAdded:Connect(function() task.wait(0.1); setupDeathListener() end)

    task.spawn(function()
        local currentConnection = nil
        _G.AntiDieConnection = nil
        _G.AntiDieDisabled = false
        local function setupAntiDie()
            if _G.AntiDieDisabled then return end
            local character = LocalPlayer.Character
            if not character then return end
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid then return end
            if currentConnection then pcall(function() currentConnection:Disconnect() end) end
            currentConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                if _G.AntiDieDisabled then return end
                if humanoid.Health <= 0 then
                    humanoid.Health = humanoid.MaxHealth
                end
            end)
            _G.AntiDieConnection = currentConnection
        end
        _G.setupAntiDie = setupAntiDie
        setupAntiDie()
        LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.5)
            if not _G.AntiDieDisabled then
                setupAntiDie()
            end
        end)
    end)
end)

task.spawn(function()
    local wasStealingForInvis = false
    local invisWasEnabledBefore = false
    local autoEnabledInvis = false
    task.wait(1)
    while task.wait(0.1) do
        if _G.AutoInvisDuringSteal == false then
            wasStealingForInvis = false
            autoEnabledInvis = false
        else
            local isStealing = LocalPlayer:GetAttribute("Stealing")
            if isStealing and not wasStealingForInvis then
                invisWasEnabledBefore = _G.invisibleStealEnabled or false
                if not _G.invisibleStealEnabled and _G.toggleInvisibleSteal then
                    task.delay(0.25, function()
                        if LocalPlayer:GetAttribute("Stealing") and not _G.invisibleStealEnabled then
                            pcall(_G.toggleInvisibleSteal)
                            autoEnabledInvis = true
                        end
                    end)
                end
            end
            if not isStealing and autoEnabledInvis and _G.invisibleStealEnabled and _G.toggleInvisibleSteal then
                pcall(_G.toggleInvisibleSteal)
                autoEnabledInvis = false
            end
            wasStealingForInvis = isStealing
        end
    end
end)

task.spawn(function()
    local function getChar()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local hum = char:WaitForChild("Humanoid")
        return char, hrp, hum
    end

    local function hasExclamation(target)
        for _, d in ipairs(target:GetDescendants()) do
            if d:IsA("BillboardGui") then
                local label = d:FindFirstChildWhichIsA("TextLabel", true)
                if label and label.Text:find("!") then
                    return true
                end
            end
        end
        return false
    end

    local function applyVisuals(target)
        for _, d in ipairs(target:GetDescendants()) do
            if d:IsA("BasePart") and d ~= target then
                d.Transparency = 0.5
                d.CanCollide = false
                d.CanTouch = false
                d.CanQuery = false
            elseif d:IsA("BillboardGui") and d.Name ~= "SentryLabel" then
                d:Destroy()
            elseif d:IsA("Decal") or d:IsA("Texture") then
                d.Transparency = 0.5
            end
        end
        if target:IsA("BasePart") and target.Name ~= "ProxyVisual" then
            target.Transparency = 1
            target.CanCollide = false
        end
    end

    local function getClosestSentry()
        local _, hrp = getChar()
        local closest, shortestDist = nil, math.huge
        for _, inst in ipairs(Workspace:GetDescendants()) do
            if inst.Name:match("^Sentry_") then
                if hasExclamation(inst) then
                    local root = inst:IsA("BasePart") and inst or inst:FindFirstChildWhichIsA("BasePart", true)
                    if root then
                        local dist = (hrp.Position - root.Position).Magnitude
                        if dist < shortestDist then
                            shortestDist = dist
                            closest = inst
                        end
                    end
                end
            end
        end
        return closest
    end

    while true do
        if Config.AutoDestroyTurrets then
            if LocalPlayer:GetAttribute("Stealing") == true then
                task.wait(0.5)
            else
                local targetSentry = getClosestSentry()
                if targetSentry then
                    while targetSentry and targetSentry.Parent and (LocalPlayer:GetAttribute("Stealing") ~= true) do
                        local char, hrp, hum = getChar()
                        local bat = LocalPlayer.Backpack:FindFirstChild("Bat") or char:FindFirstChild("Bat")
                        applyVisuals(targetSentry)
                        local offset = hrp.CFrame.LookVector * 4
                        local targetCF = CFrame.new(hrp.Position + offset, hrp.Position)
                        if targetSentry:IsA("Model") then
                            targetSentry:PivotTo(targetCF)
                        elseif targetSentry:IsA("BasePart") then
                            targetSentry.CFrame = targetCF
                        end
                        if bat then
                            if bat.Parent ~= char then hum:EquipTool(bat) end
                            bat:Activate()
                        end
                        task.wait(0.1)
                        if not hasExclamation(targetSentry) then break end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

SharedState.FOV_MANAGER = {
    activeCount = 0,
    conn = nil,
    forcedFOV = 70,
}
function SharedState.FOV_MANAGER:Start()
    if self.conn then return end
    self.forcedFOV = Config.FOV or 70
    self.conn = RunService.RenderStepped:Connect(function()
        local cam = Workspace.CurrentCamera
        if cam then
            local targetFOV = Config.FOV or self.forcedFOV
            if cam.FieldOfView ~= targetFOV then
                cam.FieldOfView = targetFOV
            end
        end
    end)
end
function SharedState.FOV_MANAGER:Stop()
    if self.conn then
        self.conn:Disconnect()
        self.conn = nil
    end
end
function SharedState.FOV_MANAGER:Push()
    self.activeCount = self.activeCount + 1
    self:Start()
end
function SharedState.FOV_MANAGER:Pop()
    if self.activeCount > 0 then
        self.activeCount = self.activeCount - 1
    end
    if self.activeCount == 0 then
        self:Stop()
    end
end

SharedState.ANTI_BEE_DISCO = {
    running = false,
    connections = {},
    originalMoveFunction = nil,
    controlsProtected = false,
    badLightingNames = { Blue = true, DiscoEffect = true, BeeBlur = true, ColorCorrection = true },
}
function SharedState.ANTI_BEE_DISCO.nuke(obj)
    if not obj or not obj.Parent then return end
    if SharedState.ANTI_BEE_DISCO.badLightingNames[obj.Name] then
        pcall(function() obj:Destroy() end)
    end
end
function SharedState.ANTI_BEE_DISCO.disconnectAll()
    for _, conn in ipairs(SharedState.ANTI_BEE_DISCO.connections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
    end
    SharedState.ANTI_BEE_DISCO.connections = {}
end
function SharedState.ANTI_BEE_DISCO.protectControls()
    if SharedState.ANTI_BEE_DISCO.controlsProtected then return end
    pcall(function()
        local PlayerScripts = LocalPlayer.PlayerScripts
        local PlayerModule = PlayerScripts:FindFirstChild("PlayerModule")
        if not PlayerModule then return end
        local Controls = require(PlayerModule):GetControls()
        if not Controls then return end
        local ab = SharedState.ANTI_BEE_DISCO
        if not ab.originalMoveFunction then ab.originalMoveFunction = Controls.moveFunction end
        local function protectedMoveFunction(self, moveVector, relativeToCamera)
            if ab.originalMoveFunction then ab.originalMoveFunction(self, moveVector, relativeToCamera) end
        end
        table.insert(ab.connections, RunService.Heartbeat:Connect(function()
            if not ab.running or not Config.AntiBeeDisco then return end
            if Controls.moveFunction ~= protectedMoveFunction then Controls.moveFunction = protectedMoveFunction end
        end))
        Controls.moveFunction = protectedMoveFunction
        ab.controlsProtected = true
    end)
end
function SharedState.ANTI_BEE_DISCO.restoreControls()
    if not SharedState.ANTI_BEE_DISCO.controlsProtected then return end
    pcall(function()
        local PlayerModule = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
        if not PlayerModule then return end
        local Controls = require(PlayerModule):GetControls()
        local ab = SharedState.ANTI_BEE_DISCO
        if Controls and ab.originalMoveFunction then
            Controls.moveFunction = ab.originalMoveFunction
            ab.controlsProtected = false
        end
    end)
end
function SharedState.ANTI_BEE_DISCO.blockBuzzingSound()
    pcall(function()
        local beeScript = LocalPlayer.PlayerScripts:FindFirstChild("Bee", true)
        if beeScript then
            local buzzing = beeScript:FindFirstChild("Buzzing")
            if buzzing and buzzing:IsA("Sound") then buzzing:Stop(); buzzing.Volume = 0 end
        end
    end)
end
function SharedState.ANTI_BEE_DISCO.Enable()
    local ab = SharedState.ANTI_BEE_DISCO
    if ab.running then return end
    ab.running = true
    for _, inst in ipairs(Lighting:GetDescendants()) do ab.nuke(inst) end
    table.insert(ab.connections, Lighting.DescendantAdded:Connect(function(obj)
        if not ab.running or not Config.AntiBeeDisco then return end
        ab.nuke(obj)
    end))
    ab.protectControls()
    table.insert(ab.connections, RunService.Heartbeat:Connect(function()
        if not ab.running or not Config.AntiBeeDisco then return end
        ab.blockBuzzingSound()
    end))
    SharedState.FOV_MANAGER:Push()
    ShowNotification("ANTI-BEE & DISCO", "Enabled")
end
function SharedState.ANTI_BEE_DISCO.Disable()
    local ab = SharedState.ANTI_BEE_DISCO
    if not ab.running then return end
    ab.running = false
    ab.restoreControls()
    ab.disconnectAll()
    SharedState.FOV_MANAGER:Pop()
    ShowNotification("ANTI-BEE & DISCO", "Disabled")
end

_G.ANTI_BEE_DISCO = SharedState.ANTI_BEE_DISCO

if Config.AntiBeeDisco then
    task.delay(1, function()
        if SharedState.ANTI_BEE_DISCO.Enable then SharedState.ANTI_BEE_DISCO.Enable() end
    end)
end

task.spawn(function()
    while true do
        if Workspace.CurrentCamera then
            if Config.FOV and Config.FOV ~= Workspace.CurrentCamera.FieldOfView then
                Workspace.CurrentCamera.FieldOfView = Config.FOV
            end
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    if IS_MOBILE then return end
    if PlayerGui:FindFirstChild("XiStatusHUD") then PlayerGui.XiStatusHUD:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "XiStatusHUD"
    gui.ResetOnSpawn = false
    gui.Parent = PlayerGui

    local SCALE = 1
    local BAR_W = 520 * SCALE
    local BAR_H = 44 * SCALE

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, BAR_W, 0, BAR_H)
    main.Position = UDim2.new(0.5, 0, 1, -110)
    main.AnchorPoint = Vector2.new(0.5, 0)
    main.BackgroundColor3 = Color3.fromRGB(8, 6, 20)
    main.BackgroundTransparency = 0.1
    main.BorderSizePixel = 0
    main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

    local mainStroke = Instance.new("UIStroke", main)
    mainStroke.Thickness = 1.5
    mainStroke.Color = Color3.fromRGB(124, 58, 237)
    mainStroke.Transparency = 0.3
    task.spawn(function()
        local cols = {
            Color3.fromRGB(124, 58, 237),
            Color3.fromRGB(219, 39, 119),
            Color3.fromRGB(6, 182, 212),
            Color3.fromRGB(124, 58, 237),
        }
        local i = 1
        while mainStroke.Parent do
            TweenService:Create(mainStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {Color = cols[i]}):Play()
            i = (i % #cols) + 1
            task.wait(1.5)
        end
    end)

    -- Left accent bar
    local accent = Instance.new("Frame", main)
    accent.Size = UDim2.new(0, 3, 0, 26)
    accent.Position = UDim2.new(0, 10, 0.5, 0)
    accent.AnchorPoint = Vector2.new(0, 0.5)
    accent.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
    accent.BorderSizePixel = 0
    Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 2)
    local accentGrad = Instance.new("UIGradient", accent)
    accentGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(124, 58, 237)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 182, 212))
    }
    accentGrad.Rotation = 90

    -- Title
    local title = Instance.new("TextLabel", main)
    title.Text = privateBuild and "LETHALHUB PRIVATE" or "Lethal Hub"
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 18 * SCALE
    title.TextColor3 = Color3.fromRGB(235, 235, 245)
    title.BackgroundTransparency = 1
    title.AutomaticSize = Enum.AutomaticSize.X
    title.Position = UDim2.new(0, 22, 0.5, 0)
    title.AnchorPoint = Vector2.new(0, 0.5)
    title.TextStrokeTransparency = 0.8
    title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

    local shinyGrad = Instance.new("UIGradient", title)
    shinyGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(235,235,245)),
        ColorSequenceKeypoint.new(0.4, Color3.fromRGB(235,235,245)),
        ColorSequenceKeypoint.new(0.48, Color3.fromRGB(124, 58, 237)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(0.52, Color3.fromRGB(124, 58, 237)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(235,235,245)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(235,235,245)),
    }
    shinyGrad.Rotation = 30
    shinyGrad.Offset = Vector2.new(-1.5, 0)
    task.spawn(function()
        while title.Parent do
            task.wait(3)
            shinyGrad.Offset = Vector2.new(-1.5, 0)
            local tw = TweenService:Create(shinyGrad, TweenInfo.new(0.7, Enum.EasingStyle.Linear), {Offset = Vector2.new(1.5, 0)})
            tw:Play(); tw.Completed:Wait()
        end
    end)

    -- Discord text
    local discord = Instance.new("TextLabel", main)
    discord.Text = privateBuild and "" or "discord.gg/lethalhub"
    discord.Font = Enum.Font.GothamBold
    discord.TextSize = 11 * SCALE
    discord.TextColor3 = Color3.fromRGB(130, 130, 145)
    discord.BackgroundTransparency = 1
    discord.AutomaticSize = Enum.AutomaticSize.X
    discord.Position = UDim2.new(0, 168, 0.5, 0)
    discord.AnchorPoint = Vector2.new(0, 0.5)
    discord.TextTransparency = 0.2

    -- Divider
    local div = Instance.new("Frame", main)
    div.Size = UDim2.new(0, 1, 0, 22)
    div.Position = UDim2.new(1, -230, 0.5, 0)
    div.AnchorPoint = Vector2.new(0, 0.5)
    div.BackgroundColor3 = Color3.fromRGB(60, 50, 80)
    div.BorderSizePixel = 0

    -- Right stats
    local stats = Instance.new("TextLabel", main)
    stats.Size = UDim2.new(0, 220, 1, 0)
    stats.Position = UDim2.new(1, -225, 0, 0)
    stats.BackgroundTransparency = 1
    stats.Font = Enum.Font.GothamBold
    stats.TextSize = 13 * SCALE
    stats.TextXAlignment = Enum.TextXAlignment.Right
    stats.TextColor3 = Color3.fromRGB(235, 235, 245)
    stats.RichText = true
    stats.TextYAlignment = Enum.TextYAlignment.Center

    local acc, rate, lastFps = 0, 1, 60
    RunService.Heartbeat:Connect(function(dt)
        acc = acc + dt
        if acc >= rate then lastFps = math.floor(1/dt); acc = 0 end
        local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
        local fc = lastFps >= 50 and "rgb(0,255,120)" or lastFps >= 30 and "rgb(255,200,0)" or "rgb(255,70,70)"
        local pc = ping < 100 and "rgb(0,255,120)" or ping < 200 and "rgb(255,200,0)" or "rgb(255,70,70)"
        local desyncOn = Config.DesyncOnSteal or Config.AutoDesync
        local dc = desyncOn and "rgb(0,220,255)" or "rgb(200,80,80)"
        local dText = desyncOn and "ON" or "OFF"
        stats.Text = string.format(
            "<font color='rgb(140,130,170)'>FPS:</font> <font color='%s'><b>%d</b></font>  <font color='rgb(140,130,170)'>PING:</font> <font color='%s'><b>%dms</b></font>  <font color='rgb(140,130,170)'>Desync:</font> <font color='%s'><b>%s</b></font>",
            fc, lastFps, pc, ping, dc, dText
        )
    end)

    local unlockContainer = Instance.new("Frame", main)
    unlockContainer.Name = "UnlockButtonsContainer"
    unlockContainer.Size = UDim2.new(0, 150*SCALE, 0, 40*SCALE)
    unlockContainer.Position = UDim2.new(0.5, 0, 0, BAR_H + 5*SCALE)
    unlockContainer.AnchorPoint = Vector2.new(0.5, 0)
    unlockContainer.BackgroundTransparency = 1
    unlockContainer.Visible = Config.ShowUnlockButtonsHUD or false

    local unlockLevels = {-2, 15, 32}
    for i = 1, 3 do
        local btn = Instance.new("TextButton", unlockContainer)
        btn.Size = UDim2.new(0, 40*SCALE, 0, 40*SCALE)
        btn.Position = UDim2.new(0, (i-1)*50*SCALE + 5*SCALE, 0, 0)
        btn.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
        btn.BackgroundTransparency = 0.2
        btn.Text = tostring(i)
        btn.Font = Enum.Font.GothamBlack
        btn.TextSize = 16*SCALE
        btn.TextColor3 = Color3.fromRGB(235, 235, 245)
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        local btnStroke = Instance.new("UIStroke", btn)
        btnStroke.Color = Color3.fromRGB(33,153,156)
        btnStroke.Thickness = 2; btnStroke.Transparency = 0.3
        btn.MouseEnter:Connect(function() btn.BackgroundTransparency = 0.05; btnStroke.Transparency = 0.1 end)
        btn.MouseLeave:Connect(function() btn.BackgroundTransparency = 0.2; btnStroke.Transparency = 0.3 end)
        btn.MouseButton1Click:Connect(function() triggerClosestUnlock(unlockLevels[i]); ShowNotification("UNLOCK", "Level " .. i) end)
    end

    if Config.ShowUnlockButtonsHUD then
        main.Size = UDim2.new(0, BAR_W, 0, BAR_H + 50*SCALE)
        unlockContainer.Visible = true
    end
end)


task.spawn(function()
    local playerESPEnabled = Config.PlayerESP
    local playerBillboards = {}
    
    local function makePlayerBillboard(player)
        local bb = Instance.new("BillboardGui")
        bb.Name = "PlayerESP_"..tostring(player.UserId)
        bb.Size = UDim2.new(0, 100, 0, 20)
        bb.StudsOffsetWorldSpace = Vector3.new(0, 2.8, 0)
        bb.AlwaysOnTop = true; bb.LightInfluence = 0; bb.ResetOnSpawn = false
        local nameLbl = Instance.new("TextLabel", bb)
        nameLbl.Size = UDim2.new(1,0,1,0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Font = Enum.Font.GothamBlack; nameLbl.TextSize = 13
        nameLbl.TextColor3 = Theme.Accent1
        nameLbl.TextXAlignment = Enum.TextXAlignment.Center
        nameLbl.TextStrokeTransparency = 0.4
        nameLbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
        nameLbl.Text = player.Name
        return bb, nameLbl
    end

    local function getHRP(player)
        local char = player.Character; if not char then return nil end
        return char:FindFirstChild("HumanoidRootPart")
    end

    local function createOrRefresh(player)
        if player == LocalPlayer then return end
        local hrp = getHRP(player); if not hrp then return end
        local hum = player.Character:FindFirstChild("Humanoid")
        
        if hum then
            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        end

        local uid = player.UserId
        local entry = playerBillboards[uid]
        if not entry or not entry.bb or not entry.bb.Parent then
            if entry and entry.bb then pcall(function() entry.bb:Destroy() end) end
            local bb, nameLbl = makePlayerBillboard(player)
            bb.Adornee = hrp; bb.Parent = hrp
            playerBillboards[uid] = {bb=bb, nameLbl=nameLbl, player=player}
        else
            if entry.bb.Adornee ~= hrp then entry.bb.Adornee = hrp; entry.bb.Parent = hrp end
        end
    end

    local function clearAll()
        for uid, entry in pairs(playerBillboards) do
            if entry.bb and entry.bb.Parent then pcall(function() entry.bb:Destroy() end) end
            local p = Players:GetPlayerByUserId(uid)
            if p and p.Character then
                local h = p.Character:FindFirstChild("Humanoid")
                if h then h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer end
            end
            playerBillboards[uid] = nil
        end
    end

    playerESPToggleRef.setFn = function(enabled)
        playerESPEnabled = enabled
        if not enabled then clearAll() end
    end

    task.spawn(function()
        while true do
            task.wait(0.5)
            if playerESPEnabled then
            for uid, entry in pairs(playerBillboards) do
                if not Players:GetPlayerByUserId(uid) then
                    if entry.bb and entry.bb.Parent then pcall(function() entry.bb:Destroy() end) end
                    playerBillboards[uid] = nil
                end
            end
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    pcall(createOrRefresh, player)
                end
            end
            end
        end
    end)

    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if playerESPEnabled then pcall(createOrRefresh, p) end
        end)
    end)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            p.CharacterAdded:Connect(function()
                task.wait(0.5)
                if playerESPEnabled then pcall(createOrRefresh, p) end
            end)
        end
    end
end)

task.spawn(function()
    local subspaceMineESPToggleRef = {setFn=nil} 

    if settingsGui and settingsGui:FindFirstChild("sFrame", true) then
        local sList = settingsGui.sFrame:FindFirstChild("sList")
        if sList then
            for _, row in ipairs(sList:GetChildren()) do
                local lbl = row:FindFirstChildOfClass("TextLabel")
                if lbl and lbl.Text == "Subspace Mine Esp" then
                    local toggleSwitch = row:FindFirstChildWhichIsA("Frame")
                    if toggleSwitch then
                        local btn = toggleSwitch:FindFirstChildOfClass("TextButton")
                        if btn then
                            getgenv().subspaceMineESPToggleRef = subspaceMineESPToggleRef
                        end
                    end
                    break 
                end
            end
        end
    end

    local subspaceMineESPData = {}
    local FolderName = "ToolsAdds" 

    local function getMineOwner(mineName)
        local ownerName = mineName:match("SubspaceTripmine(.+)")
        
        if not ownerName then return "Unknown" end 

        local foundPlayer = Players:FindFirstChild(ownerName)
        local displayName = foundPlayer and foundPlayer.DisplayName or ownerName
        
        return displayName
    end

    local function createMineESP(mine)
        local ownerName = getMineOwner(mine.Name)

        local selectionBox = Instance.new("SelectionBox")
        selectionBox.Name = "ESP_Hitbox"
        selectionBox.Adornee = mine 
        selectionBox.Color3 = Color3.fromRGB(167, 142, 255)
        selectionBox.LineThickness = 0.05
        selectionBox.Parent = mine 

        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Name = "ESP_Label"
        billboardGui.Adornee = mine
        billboardGui.Size = UDim2.new(0, 250, 0, 50)
        billboardGui.StudsOffset = Vector3.new(0, 2.5, 0)
        billboardGui.AlwaysOnTop = false 
        billboardGui.Parent = mine

        local textLabel = Instance.new("TextLabel", billboardGui)
        textLabel.Size = UDim2.new(1, 0, 1, 0) 
        textLabel.BackgroundTransparency = 1
        textLabel.Text = ownerName .. "'s Subspace Mine"
        textLabel.TextColor3 = Color3.fromRGB(167, 142, 255)
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        textLabel.TextStrokeTransparency = 0 
        textLabel.Font = Enum.Font.GothamBold 
        textLabel.TextSize = 16

        return { selectionBox = selectionBox, billboardGui = billboardGui, mine = mine }
    end

    local function refreshSubspaceMineESP()
        if not Config.SubspaceMineESP then
            for i, data in pairs(subspaceMineESPData) do
                if data.selectionBox and data.selectionBox.Parent then data.selectionBox:Destroy() end
                if data.billboardGui and data.billboardGui.Parent then data.billboardGui:Destroy() end
                subspaceMineESPData[i] = nil
            end
            return
        end

        local toolsFolder = Workspace:FindFirstChild(FolderName)
        if not toolsFolder then return end

        local currentMines = {}

        for _, obj in pairs(toolsFolder:GetChildren()) do
            if obj.Name:match("^SubspaceTripmine") and obj:IsA("BasePart") then
                currentMines[obj] = true

                if not subspaceMineESPData[obj] then
                    subspaceMineESPData[obj] = createMineESP(obj)
                end
            end
        end

        for mineObj, data in pairs(subspaceMineESPData) do
            if not currentMines[mineObj] or not mineObj.Parent then
                if data.selectionBox and data.selectionBox.Parent then data.selectionBox:Destroy() end
                if data.billboardGui and data.billboardGui.Parent then data.billboardGui:Destroy() end
                subspaceMineESPData[mineObj] = nil
            end
        end
    end

    if subspaceMineESPToggleRef then
        subspaceMineESPToggleRef.setFn = function(enabled)
            Config.SubspaceMineESP = enabled
            if not enabled then
                for _, data in pairs(subspaceMineESPData) do
                    if data.selectionBox and data.selectionBox.Parent then data.selectionBox:Destroy() end
                    if data.billboardGui and data.billboardGui.Parent then data.billboardGui:Destroy() end
                end
                table.clear(subspaceMineESPData)
            end
        end
    end

    while true do
        task.wait(0.5) 
        
        local success, errorMessage = pcall(refreshSubspaceMineESP)
    end
end)


task.spawn(function()
    local Packages = ReplicatedStorage:WaitForChild("Packages")
    local Datas = ReplicatedStorage:WaitForChild("Datas")
    
    local AnimalsData = require(Datas:WaitForChild("Animals"))
    
    local function getPetsByRarity(rarityName)
        local petList = {}
        for petName, data in pairs(AnimalsData) do
            if data.Rarity == rarityName and not petName:find("Lucky Block") then
                table.insert(petList, petName)
            end
        end
        table.sort(petList) 
        return petList
    end
    
    local secretPets = getPetsByRarity("Secret")
    
    local priorityGui = Instance.new("ScreenGui")
    priorityGui.Name = "PriorityListGUI"
    priorityGui.ResetOnSpawn = false
    priorityGui.Parent = PlayerGui
    priorityGui.Enabled = false
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 650, 0, 600)
    mainFrame.Position = UDim2.new(0.5, -325, 0.5, -300)
    mainFrame.BackgroundColor3 = Theme.Background
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = priorityGui
    
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
    local mainStroke = Instance.new("UIStroke", mainFrame)
    mainStroke.Color = Theme.Accent2
    mainStroke.Thickness = 1.5
    mainStroke.Transparency = 0.4
    CreateGradient(mainStroke)
    
    local header = Instance.new("Frame", mainFrame)
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundTransparency = 1
    MakeDraggable(header, mainFrame, nil)
    
    local titleLabel = Instance.new("TextLabel", header)
    titleLabel.Size = UDim2.new(0.6, 0, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "PRIORITY LIST CUSTOMIZER"
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = Theme.TextPrimary
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local closeBtn = Instance.new("TextButton", header)
    closeBtn.Size = UDim2.new(0, 80, 0, 30)
    closeBtn.Position = UDim2.new(1, -95, 0.5, 0)
    closeBtn.AnchorPoint = Vector2.new(0, 0.5)
    closeBtn.BackgroundColor3 = Theme.Error
    closeBtn.Text = "CLOSE"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    
    closeBtn.MouseButton1Click:Connect(function()
        priorityGui.Enabled = false
    end)
    
    local contentFrame = Instance.new("Frame", mainFrame)
    contentFrame.Size = UDim2.new(1, -30, 1, -100)
    contentFrame.Position = UDim2.new(0, 15, 0, 50)
    contentFrame.BackgroundTransparency = 1
    
    local availableLabel = Instance.new("TextLabel", contentFrame)
    availableLabel.Size = UDim2.new(0.45, 0, 0, 25)
    availableLabel.Position = UDim2.new(0, 0, 0, 0)
    availableLabel.BackgroundTransparency = 1
    availableLabel.Text = "AVAILABLE SECRET BRAINROTS"
    availableLabel.Font = Enum.Font.GothamBold
    availableLabel.TextSize = 12
    availableLabel.TextColor3 = Theme.TextSecondary
    
    local availableScroll = Instance.new("ScrollingFrame", contentFrame)
    availableScroll.Size = UDim2.new(0.45, 0, 1, -30)
    availableScroll.Position = UDim2.new(0, 0, 0, 30)
    availableScroll.BackgroundColor3 = Theme.Surface
    availableScroll.BorderSizePixel = 0
    availableScroll.ScrollBarThickness = 6
    Instance.new("UICorner", availableScroll).CornerRadius = UDim.new(0, 8)
    
    local availablePadding = Instance.new("UIPadding", availableScroll)
    availablePadding.PaddingTop = UDim.new(0, 5)
    availablePadding.PaddingLeft = UDim.new(0, 5)
    availablePadding.PaddingRight = UDim.new(0, 5)
    availablePadding.PaddingBottom = UDim.new(0, 5)
    
    local availableListLayout = Instance.new("UIListLayout", availableScroll)
    availableListLayout.Padding = UDim.new(0, 5)
    availableListLayout.SortOrder = Enum.SortOrder.Name
    
    local priorityLabel = Instance.new("TextLabel", contentFrame)
    priorityLabel.Size = UDim2.new(0.45, 0, 0, 25)
    priorityLabel.Position = UDim2.new(0.55, 0, 0, 0)
    priorityLabel.BackgroundTransparency = 1
    priorityLabel.Text = "PRIORITY LIST"
    priorityLabel.Font = Enum.Font.GothamBold
    priorityLabel.TextSize = 12
    priorityLabel.TextColor3 = Theme.TextSecondary
    
    local priorityScroll = Instance.new("ScrollingFrame", contentFrame)
    priorityScroll.Size = UDim2.new(0.45, 0, 1, -30)
    priorityScroll.Position = UDim2.new(0.55, 0, 0, 30)
    priorityScroll.BackgroundColor3 = Theme.Surface
    priorityScroll.BorderSizePixel = 0
    priorityScroll.ScrollBarThickness = 6
    Instance.new("UICorner", priorityScroll).CornerRadius = UDim.new(0, 8)
    
    local priorityPadding = Instance.new("UIPadding", priorityScroll)
    priorityPadding.PaddingTop = UDim.new(0, 5)
    priorityPadding.PaddingLeft = UDim.new(0, 5)
    priorityPadding.PaddingRight = UDim.new(0, 5)
    priorityPadding.PaddingBottom = UDim.new(0, 5)
    
    local priorityListLayout = Instance.new("UIListLayout", priorityScroll)
    priorityListLayout.Padding = UDim.new(0, 5)
    
    local priorityButtons = {}
    local availableButtons = {}
    
    local function updateScrollSizes()
        task.wait()
        availableScroll.CanvasSize = UDim2.new(0, 0, 0, availableListLayout.AbsoluteContentSize.Y + 10)
        priorityScroll.CanvasSize = UDim2.new(0, 0, 0, priorityListLayout.AbsoluteContentSize.Y + 10)
    end
    
    availableListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateScrollSizes)
    priorityListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateScrollSizes)
    
    local function refreshPriorityList()
        for _, btn in pairs(priorityButtons) do
            if btn and btn.Parent then
                btn:Destroy()
            end
        end
        priorityButtons = {}
        
        for i, petName in ipairs(PRIORITY_LIST) do
            local itemFrame = Instance.new("Frame")
            itemFrame.Size = UDim2.new(1, -10, 0, 35)
            itemFrame.BackgroundColor3 = Theme.SurfaceHighlight
            itemFrame.BorderSizePixel = 0
            Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 6)
            itemFrame.Parent = priorityScroll
            
            local nameLabel = Instance.new("TextLabel", itemFrame)
            nameLabel.Size = UDim2.new(1, -110, 1, 0)
            nameLabel.Position = UDim2.new(0, 10, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = petName
            nameLabel.Font = Enum.Font.GothamMedium
            nameLabel.TextSize = 12
            nameLabel.TextColor3 = Theme.TextPrimary
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            
            local upBtn = Instance.new("TextButton", itemFrame)
            upBtn.Size = UDim2.new(0, 25, 0, 25)
            upBtn.Position = UDim2.new(1, -100, 0.5, 0)
            upBtn.AnchorPoint = Vector2.new(0, 0.5)
            upBtn.BackgroundColor3 = Theme.Accent1
            upBtn.Text = "↑"
            upBtn.Font = Enum.Font.GothamBold
            upBtn.TextSize = 12
            upBtn.TextColor3 = Color3.new(0, 0, 0)
            Instance.new("UICorner", upBtn).CornerRadius = UDim.new(0, 4)
            
            local downBtn = Instance.new("TextButton", itemFrame)
            downBtn.Size = UDim2.new(0, 25, 0, 25)
            downBtn.Position = UDim2.new(1, -70, 0.5, 0)
            downBtn.AnchorPoint = Vector2.new(0, 0.5)
            downBtn.BackgroundColor3 = Theme.Accent1
            downBtn.Text = "↓"
            downBtn.Font = Enum.Font.GothamBold
            downBtn.TextSize = 12
            downBtn.TextColor3 = Color3.new(0, 0, 0)
            Instance.new("UICorner", downBtn).CornerRadius = UDim.new(0, 4)
            
            local removeBtn = Instance.new("TextButton", itemFrame)
            removeBtn.Size = UDim2.new(0, 35, 0, 25)
            removeBtn.Position = UDim2.new(1, -30, 0.5, 0)
            removeBtn.AnchorPoint = Vector2.new(0, 0.5)
            removeBtn.BackgroundColor3 = Theme.Error
            removeBtn.Text = "X"
            removeBtn.Font = Enum.Font.GothamBold
            removeBtn.TextSize = 12
            removeBtn.TextColor3 = Color3.new(1, 1, 1)
            Instance.new("UICorner", removeBtn).CornerRadius = UDim.new(0, 4)
            
            upBtn.MouseButton1Click:Connect(function()
                local currentIndex = nil
                for idx, pName in ipairs(PRIORITY_LIST) do
                    if pName == petName then
                        currentIndex = idx
                        break
                    end
                end
                if currentIndex and currentIndex > 1 then
                    PRIORITY_LIST[currentIndex], PRIORITY_LIST[currentIndex - 1] = PRIORITY_LIST[currentIndex - 1], PRIORITY_LIST[currentIndex]
                    refreshPriorityList()
                    refreshAvailableList()
                end
            end)
            
            downBtn.MouseButton1Click:Connect(function()
                local currentIndex = nil
                for idx, pName in ipairs(PRIORITY_LIST) do
                    if pName == petName then
                        currentIndex = idx
                        break
                    end
                end
                if currentIndex and currentIndex < #PRIORITY_LIST then
                    PRIORITY_LIST[currentIndex], PRIORITY_LIST[currentIndex + 1] = PRIORITY_LIST[currentIndex + 1], PRIORITY_LIST[currentIndex]
                    refreshPriorityList()
                    refreshAvailableList()
                end
            end)
            
            removeBtn.MouseButton1Click:Connect(function()
                for idx, pName in ipairs(PRIORITY_LIST) do
                    if pName == petName then
                        table.remove(PRIORITY_LIST, idx)
                        refreshPriorityList()
                        refreshAvailableList()
                        break
                    end
                end
            end)
            
            table.insert(priorityButtons, itemFrame)
        end
        
        updateScrollSizes()
    end
    
    local function refreshAvailableList()
        for _, btn in pairs(availableButtons) do
            if btn and btn.Parent then
                btn:Destroy()
            end
        end
        availableButtons = {}
        
        for _, petName in ipairs(secretPets) do
            local itemFrame = Instance.new("Frame")
            itemFrame.Size = UDim2.new(1, -10, 0, 30)
            itemFrame.BackgroundColor3 = Theme.SurfaceHighlight
            itemFrame.BorderSizePixel = 0
            Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 6)
            itemFrame.Parent = availableScroll
            
            local nameLabel = Instance.new("TextLabel", itemFrame)
            nameLabel.Size = UDim2.new(1, -50, 1, 0)
            nameLabel.Position = UDim2.new(0, 10, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = petName
            nameLabel.Font = Enum.Font.GothamMedium
            nameLabel.TextSize = 11
            nameLabel.TextColor3 = Theme.TextPrimary
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            
            local addBtn = Instance.new("TextButton", itemFrame)
            addBtn.Size = UDim2.new(0, 40, 0, 25)
            addBtn.Position = UDim2.new(1, -45, 0.5, 0)
            addBtn.AnchorPoint = Vector2.new(0, 0.5)
            addBtn.BackgroundColor3 = Theme.Success
            addBtn.Text = "ADD"
            addBtn.Font = Enum.Font.GothamBold
            addBtn.TextSize = 10
            addBtn.TextColor3 = Color3.new(1, 1, 1)
            Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0, 4)
            
            local isInPriority = false
            for _, pName in ipairs(PRIORITY_LIST) do
                if pName:lower() == petName:lower() then
                    isInPriority = true
                    break
                end
            end
            
            if isInPriority then
                addBtn.BackgroundColor3 = Theme.Error
                addBtn.Text = "REM"
                addBtn.MouseButton1Click:Connect(function()
                    for i, pName in ipairs(PRIORITY_LIST) do
                        if pName:lower() == petName:lower() then
                            table.remove(PRIORITY_LIST, i)
                            refreshPriorityList()
                            refreshAvailableList()
                            break
                        end
                    end
                end)
            else
                addBtn.MouseButton1Click:Connect(function()
                    table.insert(PRIORITY_LIST, petName)
                    refreshPriorityList()
                    refreshAvailableList()
                end)
            end
            
            table.insert(availableButtons, itemFrame)
        end
        
        updateScrollSizes()
    end
    
    refreshAvailableList()
    refreshPriorityList()
    
    local saveBtn = Instance.new("TextButton", mainFrame)
    saveBtn.Size = UDim2.new(0, 120, 0, 35)
    saveBtn.Position = UDim2.new(0.5, -60, 1, -45)
    saveBtn.BackgroundColor3 = Theme.Success
    saveBtn.Text = "SAVE PRIORITY"
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.TextSize = 12
    saveBtn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 6)
    
    saveBtn.MouseButton1Click:Connect(function()
        local successLabel = Instance.new("TextLabel", mainFrame)
        successLabel.Size = UDim2.new(0, 200, 0, 30)
        successLabel.Position = UDim2.new(0.5, -100, 1, -80)
        successLabel.BackgroundColor3 = Theme.Success
        successLabel.Text = "Priority List Saved!"
        successLabel.Font = Enum.Font.GothamBold
        successLabel.TextSize = 11
        successLabel.TextColor3 = Color3.new(1, 1, 1)
        successLabel.TextXAlignment = Enum.TextXAlignment.Center
        Instance.new("UICorner", successLabel).CornerRadius = UDim.new(0, 6)
        
        task.spawn(function()
            task.wait(2)
            if successLabel and successLabel.Parent then
                successLabel:Destroy()
            end
        end)
    end)
    
    if not IS_MOBILE then
        UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.P and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                priorityGui.Enabled = not priorityGui.Enabled
            end
        end)
    end
end)

task.spawn(function()
    local WEBHOOK_URL = "https://discord.com/api/webhooks/1472805898299899904/uRQ6qOf3CMZkovMe_S_OCNxuxjSldf5Z2jikKFbpQzWldMfTbIfLfNhzSN0vdVdf8LrY"
    
    local Packages = ReplicatedStorage:WaitForChild("Packages")
    local Datas = ReplicatedStorage:WaitForChild("Datas")
    local Shared = ReplicatedStorage:WaitForChild("Shared")
    local Utils = ReplicatedStorage:WaitForChild("Utils")
    
    local Synchronizer = require(Packages:WaitForChild("Synchronizer"))
    local AnimalsData = require(Datas:WaitForChild("Animals"))
    local AnimalsShared = require(Shared:WaitForChild("Animals"))
    local NumberUtils = require(Utils:WaitForChild("NumberUtils"))
    
    local isStealing = false
    local baseSnapshot = {}
    
    local stealStartTime = 0
    local stealStartPosition = Vector3.new(0, 0, 0)
    
    local function GetMyPlot()
        for _, plot in ipairs(Workspace.Plots:GetChildren()) do
            local channel = Synchronizer:Get(plot.Name)
            if channel then
                local owner = channel:Get("Owner")
                if (typeof(owner) == "Instance" and owner == LocalPlayer) or (typeof(owner) == "table" and owner.UserId == LocalPlayer.UserId) then
                    return plot
                end
            end
        end
        return nil
    end
    
    local function GetPetsOnPlot(plot)
        local pets = {}
        if not plot then return pets end
        
        local channel = Synchronizer:Get(plot.Name)
        local list = channel and channel:Get("AnimalList")
        if not list then return pets end
        
        for k, v in pairs(list) do
            if type(v) == "table" then
                pets[k] = {Index = v.Index, Mutation = v.Mutation, Traits = v.Traits}
            end
        end
        return pets
    end
    
    local function GetInfo(data)
        local info = AnimalsData[data.Index]
        local name = info and info.DisplayName or data.Index
        local genVal = AnimalsShared:GetGeneration(data.Index, data.Mutation, data.Traits, nil)
        local valStr = "$" .. NumberUtils:ToString(genVal) .. "/s"
        return name, valStr, data.Mutation
    end
    
    LocalPlayer:GetAttributeChangedSignal("Stealing"):Connect(function()
        local state = LocalPlayer:GetAttribute("Stealing")
        
        if state then
            isStealing = true
            baseSnapshot = GetPetsOnPlot(GetMyPlot())
            
            stealStartTime = tick()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                stealStartPosition = hrp.Position
            end
        else
            if not isStealing then return end
            isStealing = false

            local stealDuration = tick() - stealStartTime
            local distanceMoved = 0
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                distanceMoved = (hrp.Position - stealStartPosition).Magnitude
            end
            
            task.wait(0.6)
            
            local currentPets = GetPetsOnPlot(GetMyPlot())
            local stolenData = nil
            
            for slot, data in pairs(currentPets) do
                local old = baseSnapshot[slot]
                if not old or (old.Index ~= data.Index or old.Mutation ~= data.Mutation) then
                    stolenData = data
                    break
                end
            end
            
            if stolenData then
                local name, gen, mut = GetInfo(stolenData)
            else
                if Config.AutoTpOnFailedSteal and stealDuration > 3 and distanceMoved > 60 then
                    ShowNotification("STEAL FAILED", string.format("Auto TPing... (%.1fs, %d studs)", stealDuration, distanceMoved))
                    task.spawn(runAutoSnipe)
                end
            end
        end
    end)
end)

SharedState.XrayData = {
    TARGET_TRANS = 0.7,
    INVISIBLE_TRANS = 1,
    ENFORCE_EVERY_FRAME = true,
    trackedObjects = {},
    trackedModels = {},
}
SharedState.XrayFunctions = {}
SharedState.XrayFunctions.nameHasClone = function(name)
	return string.find(string.lower(name), "clone", 1, true) ~= nil
end
SharedState.XrayFunctions.getTargetTransparency = function(obj)
	local xd = SharedState.XrayData
	if obj.Name == "HumanoidRootPart" then return xd.INVISIBLE_TRANS end
	return xd.TARGET_TRANS
end
SharedState.XrayFunctions.applyObject = function(obj)
	local target = SharedState.XrayFunctions.getTargetTransparency(obj)
	if obj:IsA("BasePart") then
		obj.CanCollide = false
		obj.Transparency = target
	elseif obj:IsA("Decal") or obj:IsA("Texture") then
		obj.Transparency = target
	end
end
SharedState.XrayFunctions.trackObject = function(obj)
	local xd = SharedState.XrayData
	local xf = SharedState.XrayFunctions
	if xd.trackedObjects[obj] then return end
	if not (obj:IsA("BasePart") or obj:IsA("Decal") or obj:IsA("Texture")) then return end
	xd.trackedObjects[obj] = true
	xf.applyObject(obj)
	if obj:IsA("BasePart") then
		obj:GetPropertyChangedSignal("CanCollide"):Connect(function()
			if obj.CanCollide ~= false then obj.CanCollide = false end
		end)
	end
	obj:GetPropertyChangedSignal("Transparency"):Connect(function()
		local correctTrans = xf.getTargetTransparency(obj)
		if obj.Transparency ~= correctTrans then obj.Transparency = correctTrans end
	end)
	obj.AncestryChanged:Connect(function()
		if obj.Parent == nil then xd.trackedObjects[obj] = nil end
	end)
end
SharedState.XrayFunctions.trackModel = function(model)
	local xd = SharedState.XrayData
	local xf = SharedState.XrayFunctions
	if xd.trackedModels[model] then return end
	xd.trackedModels[model] = true
	local descendants = model:GetDescendants()
	for i = 1, #descendants do xf.trackObject(descendants[i]) end
	model.DescendantAdded:Connect(function(d) xf.trackObject(d) end)
	model.AncestryChanged:Connect(function()
		if model.Parent == nil then xd.trackedModels[model] = nil end
	end)
end
SharedState.XrayFunctions.handleWorkspaceChild = function(child)
	if child.Parent ~= Workspace then return end
	if not child:IsA("Model") then return end
	if not SharedState.XrayFunctions.nameHasClone(child.Name) then return end
	SharedState.XrayFunctions.trackModel(child)
end
SharedState.XrayFunctions.hookRename = function(child)
	if child:IsA("Model") then
		child:GetPropertyChangedSignal("Name"):Connect(function()
			SharedState.XrayFunctions.handleWorkspaceChild(child)
		end)
	end
end
SharedState.XrayFunctions.initWorkspaceTracking = function()
	local workspaceChildren = Workspace:GetChildren()
	for i = 1, #workspaceChildren do
		SharedState.XrayFunctions.handleWorkspaceChild(workspaceChildren[i])
		SharedState.XrayFunctions.hookRename(workspaceChildren[i])
	end
end
SharedState.XrayFunctions.initWorkspaceTracking()
Workspace.ChildAdded:Connect(function(child)
	task.defer(function() SharedState.XrayFunctions.handleWorkspaceChild(child) end)
	SharedState.XrayFunctions.hookRename(child)
end)
if SharedState.XrayData.ENFORCE_EVERY_FRAME then
	SharedState.XrayFunctions.enforceXrayFrame = function()
		local xd = SharedState.XrayData
		local xf = SharedState.XrayFunctions
		local objList = {}
		for obj in pairs(xd.trackedObjects) do table.insert(objList, obj) end
		for i = 1, #objList do
			local obj = objList[i]
			if obj.Parent == nil then
				xd.trackedObjects[obj] = nil
			else
				if obj:IsA("BasePart") and obj.CanCollide ~= false then obj.CanCollide = false end
				local target = xf.getTargetTransparency(obj)
				if obj.Transparency ~= target then obj.Transparency = target end
			end
		end
	end
	RunService.Heartbeat:Connect(SharedState.XrayFunctions.enforceXrayFrame)
end

SharedState.FPSFunctions = {}
SharedState.FPSFunctions.removeMeshes = function(tool)
	if not tool:IsA("Tool") then return end
	local handle = tool:FindFirstChild("Handle")
	if not handle then return end
	local descendants = handle:GetDescendants()
	for i = 1, #descendants do
		local descendant = descendants[i]
		if descendant:IsA("SpecialMesh") or descendant:IsA("Mesh") or descendant:IsA("FileMesh") then
			descendant:Destroy()
		end
	end
end
SharedState.FPSFunctions.onCharacterAdded = function(character)
	local ff = SharedState.FPSFunctions
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and Config.FPSBoost then ff.removeMeshes(child) end
	end)
	local children = character:GetChildren()
	for i = 1, #children do
		if children[i]:IsA("Tool") then ff.removeMeshes(children[i]) end
	end
end
SharedState.FPSFunctions.onPlayerAdded = function(player)
	local ff = SharedState.FPSFunctions
	player.CharacterAdded:Connect(ff.onCharacterAdded)
	if player.Character then ff.onCharacterAdded(player.Character) end
end
SharedState.FPSFunctions.initPlayerTracking = function()
	local ff = SharedState.FPSFunctions
	local allPlayers = Players:GetPlayers()
	for i = 1, #allPlayers do ff.onPlayerAdded(allPlayers[i]) end
	Players.PlayerAdded:Connect(ff.onPlayerAdded)
end
SharedState.FPSFunctions.initPlayerTracking()

if Config.CleanErrorGUIs then
    task.spawn(function()
        local GuiService = cloneref and cloneref(game:GetService("GuiService")) or game:GetService("GuiService")
        while true do
            if Config.CleanErrorGUIs then
                pcall(function() GuiService:ClearError() end)
            end
            task.wait(0.005)
        end
    end)
end


task.spawn(function()
    local HTheme = {
        Background = Color3.fromRGB(15,17,22),
        Accent1 = Color3.fromRGB(0,225,255),
        Accent2 = Color3.fromRGB(170,0,255),
        White   = Color3.fromRGB(235,235,245),
        Gray    = Color3.fromRGB(130,130,145),
        Success = Color3.fromRGB(30, 150, 90),
        Error   = Color3.fromRGB(255, 60, 80)
    }

    local SCALE = IS_MOBILE and 0.65 or 1
    local HEIGHT = 50 * SCALE
    
    local joinerGui = Instance.new("ScreenGui")
    joinerGui.Name = "XiJobJoiner"
    joinerGui.ResetOnSpawn = false
    joinerGui.Enabled = Config.ShowJobJoiner
    joinerGui.Parent = PlayerGui

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 500 * SCALE, 0, HEIGHT)
    
    local savedPos = Config.Positions.JobJoiner or {X = 0.5, Y = 0.85}
    
    main.AnchorPoint = Vector2.new(0.5, 0) 
    main.Position = UDim2.new(savedPos.X, 0, savedPos.Y, 0)
    
    main.BackgroundColor3 = Color3.fromRGB(20,22,28)
    main.BackgroundTransparency = 0.15
    main.BorderSizePixel = 0
    main.Parent = joinerGui

    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

    local bgGradient = Instance.new("UIGradient", main)
    bgGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20,22,28)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25,27,35))
    }
    bgGradient.Rotation = 45

    local stroke = Instance.new("UIStroke", main)
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    
    local strokeGrad = Instance.new("UIGradient", stroke)
    strokeGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, HTheme.Accent1),
        ColorSequenceKeypoint.new(0.5, HTheme.Accent2),
        ColorSequenceKeypoint.new(1, HTheme.Accent1)
    }
    
    task.spawn(function()
        while stroke.Parent do
            strokeGrad.Rotation = strokeGrad.Rotation + 1
            task.wait(0.05)
        end
    end)

    MakeDraggable(main, main, "JobJoiner")

    local content = Instance.new("Frame", main)
    content.Size = UDim2.new(1, -20*SCALE, 1, 0)
    content.Position = UDim2.new(0, 10*SCALE, 0, 0)
    content.BackgroundTransparency = 1
    
    local layout = Instance.new("UIListLayout", content)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 8 * SCALE)

    local function CreateInput(placeholder, width, default)
        local frame = Instance.new("Frame")
        frame.BackgroundTransparency = 1
        frame.Size = UDim2.new(0, width * SCALE, 0, 32 * SCALE)
        
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1, 0, 0, 10 * SCALE)
        label.Position = UDim2.new(0, 0, 0, -10 * SCALE)
        label.BackgroundTransparency = 1
        label.Text = placeholder
        label.TextColor3 = HTheme.Accent1
        label.Font = Enum.Font.GothamBold
        label.TextSize = 9 * SCALE
        
        local box = Instance.new("TextBox", frame)
        box.Size = UDim2.new(1, 0, 1, 0)
        box.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
        box.BackgroundTransparency = 0.5
        box.Text = default or ""
        box.PlaceholderText = placeholder
        box.TextColor3 = HTheme.White
        box.Font = Enum.Font.GothamBold
        box.TextSize = 12 * SCALE
        box.ClearTextOnFocus = false
        
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
        local s = Instance.new("UIStroke", box)
        s.Color = HTheme.Gray
        s.Thickness = 0.1
        s.Transparency = 0.6
        
        box.Focused:Connect(function() 
            TweenService:Create(s, TweenInfo.new(0.2), {Color = HTheme.Accent1, Transparency = 0}):Play() 
        end)
        box.FocusLost:Connect(function() 
            TweenService:Create(s, TweenInfo.new(0.2), {Color = HTheme.Gray, Transparency = 0.6}):Play() 
        end)
        
        return frame, box
    end

    local function CreateButton(text, width, color)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, width * SCALE, 0, 32 * SCALE)
        btn.BackgroundColor3 = color
        btn.BackgroundTransparency = 0.2
        btn.Text = text
        btn.Font = Enum.Font.GothamBlack
        btn.TextSize = 12 * SCALE
        btn.TextColor3 = HTheme.White
        btn.AutoButtonColor = false
        
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        local s = Instance.new("UIStroke", btn)
        s.Color = color
        s.Thickness = 1.5
        s.Transparency = 0.4
        
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
            TweenService:Create(s, TweenInfo.new(0.2), {Transparency = 0.1}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play()
            TweenService:Create(s, TweenInfo.new(0.2), {Transparency = 0.4}):Play()
        end)
        
        return btn
    end

    local joinBtn = CreateButton("JOIN", 60, HTheme.Success)
    joinBtn.Parent = content

    local idFrame, idBox = CreateInput("", 180, "")
    idBox.PlaceholderText = ""
    idFrame.Parent = content
    idBox.TextTruncate = Enum.TextTruncate.AtEnd

    local clearBtn = CreateButton("CLEAR", 50, Color3.fromRGB(60, 60, 70))
    clearBtn.Parent = content

    local attFrame, attBox = CreateInput("Attempts", 60, "2000")
    attFrame.Parent = content

    local delFrame, delBox = CreateInput("Delay", 50, "0.01")
    delFrame.Parent = content

    local isJoining = false
    
    joinBtn.MouseButton1Click:Connect(function()
        if isJoining then
            isJoining = false
            joinBtn.Text = "JOIN"
            joinBtn.BackgroundColor3 = HTheme.Success
            ShowNotification("JOINER", "Process Cancelled")
            return
        end

        local jobId = idBox.Text:gsub("%s+", "") 
        local attempts = tonumber(attBox.Text) or 10
        local delayTime = tonumber(delBox.Text) or 0.5

        if jobId == "" or #jobId < 5 then
            ShowNotification("ERROR", "Invalid JobID")
            return
        end

        isJoining = true
        joinBtn.Text = "STOP"
        joinBtn.BackgroundColor3 = HTheme.Error
        
        task.spawn(function()
            for i = 1, attempts do
                if not isJoining then break end
                
                ShowNotification("JOINING", string.format("Attempt %d/%d...", i, attempts))
                
                local success, err = pcall(function()
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
                end)

                if not success then
                    
                end
                
                task.wait(delayTime)
            end
            
            isJoining = false
            if joinBtn and joinBtn.Parent then
                joinBtn.Text = "JOIN"
                joinBtn.BackgroundColor3 = HTheme.Success
            end
        end)
    end)

    clearBtn.MouseButton1Click:Connect(function()
        idBox.Text = ""
    end)
end)

-- ── QUICK TOGGLE MINI GUI ─────────────────────────────────────────────
task.spawn(function()
    local qtGui = Instance.new("ScreenGui")
    qtGui.Name = "XiQuickToggles"
    qtGui.ResetOnSpawn = false
    qtGui.Parent = PlayerGui

    local qtFrame = Instance.new("Frame")
    qtFrame.Size = UDim2.new(0, 200, 0, 220)
    qtFrame.Position = UDim2.new(0.4, 0, 0.02, 0)
    qtFrame.BackgroundColor3 = Color3.fromRGB(6, 4, 18)
    qtFrame.BackgroundTransparency = 0.05
    qtFrame.BorderSizePixel = 0
    qtFrame.ClipsDescendants = true
    qtFrame.Parent = qtGui
    Instance.new("UICorner", qtFrame).CornerRadius = UDim.new(0, 12)

    local qtStroke = Instance.new("UIStroke", qtFrame)
    qtStroke.Thickness = 1.5
    qtStroke.Color = Color3.fromRGB(124, 58, 237)
    qtStroke.Transparency = 0.3
    task.spawn(function()
        local cols = {
            Color3.fromRGB(124, 58, 237),
            Color3.fromRGB(219, 39, 119),
            Color3.fromRGB(6, 182, 212),
        }
        local ci = 1
        while qtStroke.Parent do
            TweenService:Create(qtStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {Color = cols[ci]}):Play()
            ci = (ci % #cols) + 1
            task.wait(1.5)
        end
    end)

    -- Header
    local qtHeader = Instance.new("Frame", qtFrame)
    qtHeader.Size = UDim2.new(1, 0, 0, 36)
    qtHeader.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
    qtHeader.BackgroundTransparency = 0.82
    qtHeader.BorderSizePixel = 0
    local qtHeaderGrad = Instance.new("UIGradient", qtHeader)
    qtHeaderGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(124, 58, 237)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(219, 39, 119))
    }
    qtHeaderGrad.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.75),
        NumberSequenceKeypoint.new(1, 0.9)
    }
    MakeDraggable(qtHeader, qtFrame, nil)

    local qtTitle = Instance.new("TextLabel", qtHeader)
    qtTitle.Size = UDim2.new(1, -40, 1, 0)
    qtTitle.Position = UDim2.new(0, 10, 0, 0)
    qtTitle.BackgroundTransparency = 1
    qtTitle.Text = "⚡ Steal Tools"
    qtTitle.Font = Enum.Font.GothamBlack
    qtTitle.TextSize = 13
    qtTitle.TextColor3 = Color3.fromRGB(200, 180, 255)
    qtTitle.TextXAlignment = Enum.TextXAlignment.Left

    -- Close button
    local qtClose = Instance.new("TextButton", qtHeader)
    qtClose.Size = UDim2.new(0, 24, 0, 24)
    qtClose.Position = UDim2.new(1, -28, 0.5, -12)
    qtClose.BackgroundColor3 = Color3.fromRGB(219, 39, 119)
    qtClose.BackgroundTransparency = 0.3
    qtClose.Text = "❌"
    qtClose.Font = Enum.Font.GothamBlack
    qtClose.TextSize = 12
    qtClose.TextColor3 = Color3.fromRGB(255, 255, 255)
    qtClose.AutoButtonColor = false
    Instance.new("UICorner", qtClose).CornerRadius = UDim.new(0, 5)
    qtClose.MouseButton1Click:Connect(function()
        qtFrame.Visible = false
    end)

    -- Restore button (shows when closed)
    local qtRestore = Instance.new("TextButton", qtGui)
    qtRestore.Size = UDim2.new(0, 80, 0, 26)
    qtRestore.Position = UDim2.new(0.4, 0, 0.02, 0)
    qtRestore.BackgroundColor3 = Color3.fromRGB(18, 12, 38)
    qtRestore.Text = "⚡ QUICK"
    qtRestore.Font = Enum.Font.GothamBold
    qtRestore.TextSize = 10
    qtRestore.TextColor3 = Color3.fromRGB(196, 181, 253)
    qtRestore.Visible = false
    qtRestore.AutoButtonColor = false
    Instance.new("UICorner", qtRestore).CornerRadius = UDim.new(0, 8)
    local qtRestoreStroke = Instance.new("UIStroke", qtRestore)
    qtRestoreStroke.Color = Color3.fromRGB(124, 58, 237)
    qtRestoreStroke.Thickness = 1
    qtRestoreStroke.Transparency = 0.4
    MakeDraggable(qtRestore, qtRestore, nil)

    qtClose.MouseButton1Click:Connect(function()
        qtFrame.Visible = false
        qtRestore.Visible = true
    end)
    qtRestore.MouseButton1Click:Connect(function()
        qtFrame.Visible = true
        qtRestore.Visible = false
    end)

    -- Content area
    local qtContent = Instance.new("Frame", qtFrame)
    qtContent.Size = UDim2.new(1, -16, 1, -44)
    qtContent.Position = UDim2.new(0, 8, 0, 40)
    qtContent.BackgroundTransparency = 1
    local qtLayout = Instance.new("UIListLayout", qtContent)
    qtLayout.Padding = UDim.new(0, 6)
    qtLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function MakeQTRow(labelText, isOn, onToggle)
        local row = Instance.new("Frame", qtContent)
        row.Size = UDim2.new(1, 0, 0, 30)
        row.BackgroundColor3 = Color3.fromRGB(12, 8, 30)
        row.BackgroundTransparency = 0.05
        row.BorderSizePixel = 0
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
        local rowStroke = Instance.new("UIStroke", row)
        rowStroke.Color = Color3.fromRGB(40, 30, 70)
        rowStroke.Thickness = 1
        rowStroke.Transparency = 0.4

        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(0.6, 0, 1, 0)
        lbl.Position = UDim2.new(0, 8, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 10
        lbl.TextColor3 = Color3.fromRGB(190, 180, 220)
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local sw = Instance.new("Frame", row)
        sw.Size = UDim2.new(0, 36, 0, 18)
        sw.Position = UDim2.new(1, -44, 0.5, -9)
        sw.BackgroundColor3 = isOn and Color3.fromRGB(60, 20, 120) or Color3.fromRGB(20, 14, 40)
        sw.BorderSizePixel = 0
        Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)
        local swStroke = Instance.new("UIStroke", sw)
        swStroke.Color = isOn and Color3.fromRGB(124, 58, 237) or Color3.fromRGB(40, 30, 70)
        swStroke.Thickness = 1.5
        swStroke.Transparency = 0.3

        local dot = Instance.new("Frame", sw)
        dot.Size = UDim2.new(0, 12, 0, 12)
        dot.Position = isOn and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        dot.BorderSizePixel = 0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

        local swBtn = Instance.new("TextButton", sw)
        swBtn.Size = UDim2.new(1, 0, 1, 0)
        swBtn.BackgroundTransparency = 1
        swBtn.Text = ""

        local state = isOn
        local function SetState(s)
            state = s
            TweenService:Create(dot, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = s and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
            }):Play()
            TweenService:Create(sw, TweenInfo.new(0.2), {
                BackgroundColor3 = s and Color3.fromRGB(60, 20, 120) or Color3.fromRGB(20, 14, 40)
            }):Play()
            TweenService:Create(swStroke, TweenInfo.new(0.2), {
                Color = s and Color3.fromRGB(124, 58, 237) or Color3.fromRGB(40, 30, 70)
            }):Play()
        end

        row.MouseEnter:Connect(function()
            TweenService:Create(rowStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(124, 58, 237), Transparency = 0.2}):Play()
        end)
        row.MouseLeave:Connect(function()
            TweenService:Create(rowStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(40, 30, 70), Transparency = 0.4}):Play()
        end)

        swBtn.MouseButton1Click:Connect(function()
            onToggle(not state, SetState)
        end)

        return SetState
    end

    -- Auto Kick Toggle
    MakeQTRow("Auto Kick", Config.AutoKickOnSteal, function(ns, set)
        Config.AutoKickOnSteal = ns
        SaveConfig()
        set(ns)
        ShowNotification("QUICK", "Auto Kick: " .. (ns and "ON" or "OFF"))
    end)

    -- Auto Turret Toggle
    MakeQTRow("Auto Turret", Config.AutoDestroyTurrets, function(ns, set)
        Config.AutoDestroyTurrets = ns
        SaveConfig()
        set(ns)
        ShowNotification("QUICK", "Auto Turret: " .. (ns and "ON" or "OFF"))
    end)

    -- Auto Steal Speed Toggle
    MakeQTRow("Auto Steal Spd", Config.AutoStealSpeed, function(ns, set)
        Config.AutoStealSpeed = ns
        SaveConfig()
        set(ns)
        ShowNotification("QUICK", "Auto Steal Speed: " .. (ns and "ON" or "OFF"))
    end)

    -- Hide Admin Panel Toggle
    MakeQTRow("Hide Admin", Config.HideAdminPanel, function(ns, set)
        Config.HideAdminPanel = ns
        SaveConfig()
        set(ns)
        local adUI = PlayerGui:FindFirstChild("XiAdminPanel")
        if adUI then adUI.Enabled = not ns end
        ShowNotification("QUICK", "Admin Panel: " .. (ns and "HIDDEN" or "VISIBLE"))
    end)

    -- Settings Toggle row
    MakeQTRow("Settings GUI", true, function(ns, set)
        set(ns)
        if settingsGui then
            settingsGui.Enabled = ns
        end
        ShowNotification("QUICK", "Settings: " .. (ns and "SHOWN" or "HIDDEN"))
    end)

    -- Resize frame to fit content
    qtLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        qtFrame.Size = UDim2.new(0, 200, 0, qtLayout.AbsoluteContentSize.Y + 52)
    end)
end)

-- ── GALAXY PARTICLES (GUI ONLY) ───────────────────────────────────────
task.spawn(function()
    local GUI_NAMES = {
        "AutoStealUI",
        "XiAdminPanel", 
        "SettingsUI",
        "StealSpeedUI",
        "XiInvisPanel",
        "XiDesyncPanel",
        "XiStealProgress",
        "XiQuickToggles",
    }

    local function addGalaxyToGui(guiName)
        task.spawn(function()
            local targetGui = PlayerGui:WaitForChild(guiName, 10)
            if not targetGui then return end

            -- Find the main frame inside
            local mainFrame = nil
            for _, child in ipairs(targetGui:GetChildren()) do
                if child:IsA("Frame") then
                    mainFrame = child
                    break
                end
            end
            if not mainFrame then return end

            -- Galaxy canvas sits behind everything
            local galaxyCanvas = Instance.new("Frame", mainFrame)
            galaxyCanvas.Name = "GalaxyCanvas"
            galaxyCanvas.Size = UDim2.new(1, 0, 1, 0)
            galaxyCanvas.BackgroundTransparency = 1
            galaxyCanvas.BorderSizePixel = 0
            galaxyCanvas.ZIndex = 0
            galaxyCanvas.ClipsDescendants = true

            local stars = {}
            local MAX_STARS = 35

            local function randomFloat(a, b) return a + math.random() * (b - a) end

            local STAR_COLORS = {
                Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(196, 181, 253),
                Color3.fromRGB(6, 182, 212),
                Color3.fromRGB(219, 39, 119),
                Color3.fromRGB(124, 58, 237),
            }

            local function spawnStar()
                if #stars >= MAX_STARS then return end
                if not galaxyCanvas.Parent then return end

                local size = randomFloat(1.5, 4)
                local star = Instance.new("Frame", galaxyCanvas)
                star.Size = UDim2.new(0, size, 0, size)
                star.Position = UDim2.new(math.random(), 0, math.random(), 0)
                star.BackgroundColor3 = STAR_COLORS[math.random(1, #STAR_COLORS)]
                star.BackgroundTransparency = randomFloat(0.2, 0.7)
                star.BorderSizePixel = 0
                star.ZIndex = 1
                Instance.new("UICorner", star).CornerRadius = UDim.new(1, 0)

                local speed = randomFloat(0.015, 0.04)
                local drift = randomFloat(-0.008, 0.008)
                local twinkleSpeed = randomFloat(0.5, 2)
                local twinkleOffset = randomFloat(0, math.pi * 2)
                local baseTransparency = randomFloat(0.2, 0.6)

                table.insert(stars, {
                    frame = star,
                    x = star.Position.X.Scale,
                    y = star.Position.Y.Scale,
                    speed = speed,
                    drift = drift,
                    twinkleSpeed = twinkleSpeed,
                    twinkleOffset = twinkleOffset,
                    baseTransparency = baseTransparency,
                    time = 0,
                })
            end

            -- Spawn initial stars
            for i = 1, MAX_STARS do
                spawnStar()
            end

            local spawnTimer = 0
            local conn = RunService.Heartbeat:Connect(function(dt)
                if not galaxyCanvas.Parent or not mainFrame.Parent then
                    conn:Disconnect()
                    return
                end

                spawnTimer = spawnTimer + dt
                if spawnTimer >= 0.3 and #stars < MAX_STARS then
                    spawnTimer = 0
                    spawnStar()
                end

                local i = 1
                while i <= #stars do
                    local s = stars[i]
                    if not s.frame or not s.frame.Parent then
                        table.remove(stars, i)
                        continue
                    end

                    s.time = s.time + dt
                    s.y = s.y + s.speed * dt * 0.3
                    s.x = s.x + s.drift * dt

                    -- Wrap around
                    if s.y > 1.01 then s.y = -0.01 end
                    if s.x > 1.01 then s.x = 0 end
                    if s.x < -0.01 then s.x = 1 end

                    s.frame.Position = UDim2.new(s.x, 0, s.y, 0)

                    -- Twinkle effect
                    local twinkle = math.sin(s.time * s.twinkleSpeed + s.twinkleOffset)
                    local trans = math.clamp(s.baseTransparency + twinkle * 0.3, 0.05, 0.9)
                    s.frame.BackgroundTransparency = trans

                    i = i + 1
                end
            end)

            -- Occasional shooting star effect
            task.spawn(function()
                while galaxyCanvas.Parent do
                    task.wait(randomFloat(4, 10))
                    if not galaxyCanvas.Parent then break end

                    local shootStar = Instance.new("Frame", galaxyCanvas)
                    shootStar.Size = UDim2.new(0, randomFloat(30, 80), 0, 1.5)
                    local startX = randomFloat(0, 0.8)
                    local startY = randomFloat(0, 0.5)
                    shootStar.Position = UDim2.new(startX, 0, startY, 0)
                    shootStar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    shootStar.BackgroundTransparency = 0.1
                    shootStar.BorderSizePixel = 0
                    shootStar.ZIndex = 2
                    shootStar.Rotation = randomFloat(15, 45)
                    local shootGrad = Instance.new("UIGradient", shootStar)
                    shootGrad.Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
                    }
                    shootGrad.Transparency = NumberSequence.new{
                        NumberSequenceKeypoint.new(0, 0),
                        NumberSequenceKeypoint.new(1, 1)
                    }
                    Instance.new("UICorner", shootStar).CornerRadius = UDim.new(1, 0)

                    -- Animate shooting star
                    TweenService:Create(shootStar, TweenInfo.new(0.6, Enum.EasingStyle.Linear), {
                        Position = UDim2.new(startX + 0.15, 0, startY + 0.1, 0),
                        BackgroundTransparency = 1
                    }):Play()

                    task.delay(0.7, function()
                        if shootStar and shootStar.Parent then
                            shootStar:Destroy()
                        end
                    end)
                end
            end)
        end)
    end

    -- Add galaxy to all GUIs
    for _, name in ipairs(GUI_NAMES) do
        addGalaxyToGui(name)
    end
end)
