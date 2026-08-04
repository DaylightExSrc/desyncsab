local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local HttpService       = game:GetService("HttpService")
local Stats             = game:GetService("Stats")

local lp        = Players.LocalPlayer
local playerGui = lp:WaitForChild("PlayerGui")

local ANTHROPIC_KEY = "sk-ant-api03-placeholder-replace-with-real-key"

-- ============================================================
-- STATE
-- ============================================================
local _enabled          = true
local _seen             = {}
local _focused          = nil
local _statsFound       = 0
local _lastCode         = nil

local _allMessagesMode  = false
local _autoSubmit       = true
local _submitThreshold  = 3
local _submitDelayMs    = 0
local _accumWords       = 0

local SUBMIT_DELAY_JITTER = 0.01

local function jitter(base, spreadPct)
    spreadPct = spreadPct or 0.25
    local delta = base * spreadPct
    return base + (math.random() * 2 - 1) * delta
end

-- ============================================================
-- THEME  (dark, minimal, deep-space black w/ starfield)
-- ============================================================
local T = {
    BG     = Color3.fromRGB(0,0,0),
    Panel  = Color3.fromRGB(255,255,255),
    Border = Color3.fromRGB(90,95,120),
    White  = Color3.fromRGB(235,235,240),
    Dim    = Color3.fromRGB(160,163,185),
    Green  = Color3.fromRGB(90,215,120),
    Red    = Color3.fromRGB(230,80,80),
    Purple = Color3.fromRGB(190,120,255),
    Accent = Color3.fromRGB(100,150,255),
    Star   = Color3.fromRGB(255,255,255),
}
local BG_TRANSPARENCY    = 0.55
local PANEL_TRANSPARENCY = 0.85
local F = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function Tw(o,i,p) TweenService:Create(o,i,p):Play() end
local function Corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 10); c.Parent=p end
local function Stroke(p,col,th)
    local s=Instance.new("UIStroke"); s.Color=col or T.Border
    s.Thickness=th or 1; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s
end
local function Pad(p,t,b,l,r)
    local pd=Instance.new("UIPadding")
    pd.PaddingTop=UDim.new(0,t or 0); pd.PaddingBottom=UDim.new(0,b or t or 0)
    pd.PaddingLeft=UDim.new(0,l or t or 0); pd.PaddingRight=UDim.new(0,r or l or t or 0)
    pd.Parent=p; return pd
end

pcall(function() if game.CoreGui:FindFirstChild("InfinityCodeRedeemPRIVATE") then game.CoreGui.InfinityCodeRedeemPRIVATE:Destroy() end end)
pcall(function() if playerGui:FindFirstChild("InfinityCodeRedeemPRIVATE") then playerGui.InfinityCodeRedeemPRIVATE:Destroy() end end)
pcall(function() if game.CoreGui:FindFirstChild("RainyCodeRedeemer") then game.CoreGui.RainyCodeRedeemer:Destroy() end end)
pcall(function() if playerGui:FindFirstChild("RainyCodeRedeemer") then playerGui.RainyCodeRedeemer:Destroy() end end)

local GUI = Instance.new("ScreenGui")
GUI.Name="InfinityCodeRedeemPRIVATE"; GUI.ResetOnSpawn=false; GUI.IgnoreGuiInset=true
GUI.DisplayOrder=999
-- Global ZIndexBehavior lets the starfield (low ZIndex) sit behind the
-- panel (high ZIndex) even though both are parented to the ScreenGui.
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Global
if not pcall(function() GUI.Parent=game.CoreGui end) then GUI.Parent=playerGui end

-- ============================================================
-- STARFIELD  (twinkling dots behind the whole HUD)
-- ============================================================
local function createStarField(parent, count, zIndex)
    count = count or 70
    zIndex = zIndex or 1
    for i=1,count do
        local size = math.random(1,3)
        local star = Instance.new("Frame")
        star.Name = "Star"
        star.Size = UDim2.new(0, size, 0, size)
        star.Position = UDim2.new(math.random(), math.random(-4,4), math.random(), math.random(-4,4))
        star.BackgroundColor3 = T.Star
        star.BorderSizePixel = 0
        star.ZIndex = zIndex
        star.Parent = parent
        Corner(star, size)

        local minT, maxT = 0.15, 0.9
        star.BackgroundTransparency = minT + math.random()*(maxT-minT)

        task.spawn(function()
            -- stagger start so stars don't all twinkle in sync
            task.wait(math.random()*2)
            while star and star.Parent do
                local dur = 1.1 + math.random()*2.4
                Tw(star, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = maxT})
                task.wait(dur)
                if not (star and star.Parent) then break end
                Tw(star, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = minT})
                task.wait(dur)
            end
        end)
    end
end
createStarField(GUI, 80)

-- ============================================================
-- BACKGROUND MUSIC
-- Replace the SoundId below with your own owned/licensed track's
-- asset id (rbxassetid://########). If the id is invalid, Play()
-- just fails silently via pcall and the rest of the UI still works.
-- ============================================================
local Music = Instance.new("Sound")
Music.Name = "BGMusic"
Music.SoundId = "rbxassetid://142376088"
Music.Volume = 0.35
Music.Looped = true
Music.Parent = GUI

-- ============================================================
-- LOADING SCREEN
-- ============================================================
local LoadingScreen = Instance.new("Frame")
LoadingScreen.Name = "LoadingScreen"
LoadingScreen.Size = UDim2.new(1,0,1,0)
LoadingScreen.BackgroundColor3 = Color3.fromRGB(0,0,0)
LoadingScreen.BackgroundTransparency = 0
LoadingScreen.BorderSizePixel = 0
LoadingScreen.ZIndex = 500
LoadingScreen.Parent = GUI
createStarField(LoadingScreen, 55, 501)

local LogoWrap = Instance.new("Frame")
LogoWrap.Size = UDim2.new(0,320,0,110)
LogoWrap.AnchorPoint = Vector2.new(0.5,0.5)
LogoWrap.Position = UDim2.new(0.5,0,0.44,0)
LogoWrap.BackgroundTransparency = 1
LogoWrap.ZIndex = 501
LogoWrap.Parent = LoadingScreen

local LogoTitle = Instance.new("TextLabel")
LogoTitle.Size = UDim2.new(1,0,0,34)
LogoTitle.BackgroundTransparency = 1
LogoTitle.Text = "INFINITY"
LogoTitle.TextSize = 30
LogoTitle.Font = Enum.Font.GothamBlack
LogoTitle.TextColor3 = Color3.fromRGB(255,255,255)
LogoTitle.ZIndex = 502
LogoTitle.Parent = LogoWrap

local LogoSub = Instance.new("TextLabel")
LogoSub.Size = UDim2.new(1,0,0,18)
LogoSub.Position = UDim2.new(0,0,0,36)
LogoSub.BackgroundTransparency = 1
LogoSub.Text = "C O D E   R E D E E M"
LogoSub.TextSize = 13
LogoSub.Font = Enum.Font.GothamMedium
LogoSub.TextColor3 = T.Accent
LogoSub.ZIndex = 502
LogoSub.Parent = LogoWrap

local PrivateTag = Instance.new("TextLabel")
PrivateTag.Size = UDim2.new(1,0,0,14)
PrivateTag.Position = UDim2.new(0,0,0,58)
PrivateTag.BackgroundTransparency = 1
PrivateTag.Text = "P R I V A T E   A C C E S S"
PrivateTag.TextSize = 10
PrivateTag.Font = Enum.Font.GothamBold
PrivateTag.TextColor3 = T.Purple
PrivateTag.ZIndex = 502
PrivateTag.Parent = LogoWrap

local BarOuter = Instance.new("Frame")
BarOuter.Size = UDim2.new(0,260,0,6)
BarOuter.Position = UDim2.new(0.5,0,1,-6)
BarOuter.AnchorPoint = Vector2.new(0.5,0)
BarOuter.BackgroundColor3 = Color3.fromRGB(255,255,255)
BarOuter.BackgroundTransparency = 0.88
BarOuter.BorderSizePixel = 0
BarOuter.ZIndex = 502
BarOuter.Parent = LogoWrap
Corner(BarOuter,3)

local BarFill = Instance.new("Frame")
BarFill.Size = UDim2.new(0,0,1,0)
BarFill.BackgroundColor3 = T.Accent
BarFill.BorderSizePixel = 0
BarFill.ZIndex = 503
BarFill.Parent = BarOuter
Corner(BarFill,3)

local PctLbl = Instance.new("TextLabel")
PctLbl.Size = UDim2.new(0,200,0,14)
PctLbl.Position = UDim2.new(0.5,0,1,6)
PctLbl.AnchorPoint = Vector2.new(0.5,0)
PctLbl.BackgroundTransparency = 1
PctLbl.Text = "initializing"
PctLbl.TextSize = 10
PctLbl.Font = Enum.Font.GothamMedium
PctLbl.TextColor3 = T.Dim
PctLbl.ZIndex = 502
PctLbl.Parent = BarOuter

-- gentle breathing pulse on the logo while it loads
task.spawn(function()
    while LogoTitle and LogoTitle.Parent do
        Tw(LogoTitle, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency=0.35})
        task.wait(1.1)
        if not (LogoTitle and LogoTitle.Parent) then break end
        Tw(LogoTitle, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency=0})
        task.wait(1.1)
    end
end)

-- ============================================================
-- SHOOTING STARS  (rare streaks across the loading screen — a
-- couple per load, not a barrage)
-- ============================================================
local function spawnShootingStar(parent)
    if not (parent and parent.Parent) then return end

    local head = Instance.new("Frame")
    head.Name = "ShootingStar"
    head.AnchorPoint = Vector2.new(0.5,0.5)
    head.Size = UDim2.new(0,3,0,3)
    head.BackgroundColor3 = Color3.fromRGB(255,255,255)
    head.BackgroundTransparency = 0
    head.BorderSizePixel = 0
    head.Rotation = 32
    head.ZIndex = 505
    head.Parent = parent
    Corner(head,2)

    local trail = Instance.new("Frame")
    trail.AnchorPoint = Vector2.new(1,0.5)
    trail.Position = UDim2.new(0,0,0.5,0)
    trail.Size = UDim2.new(0,64,0,2)
    trail.BackgroundColor3 = Color3.fromRGB(255,255,255)
    trail.BorderSizePixel = 0
    trail.ZIndex = 504
    trail.Parent = head
    local grad = Instance.new("UIGradient")
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,1),
        NumberSequenceKeypoint.new(1,0.15),
    })
    grad.Parent = trail

    local startX = math.random(-5,35)/100
    local startY = math.random(-5,25)/100
    head.Position = UDim2.new(startX,0,startY,0)

    local dist = 0.4 + math.random()*0.18
    local endX, endY = startX+dist, startY+dist

    local dur = 0.65 + math.random()*0.35
    Tw(head, TweenInfo.new(dur, Enum.EasingStyle.Linear), {Position=UDim2.new(endX,0,endY,0)})
    task.delay(dur*0.55, function()
        if head and head.Parent then
            Tw(head, TweenInfo.new(dur*0.45), {BackgroundTransparency=1})
            Tw(trail, TweenInfo.new(dur*0.45), {BackgroundTransparency=1})
        end
    end)
    task.delay(dur+0.15, function() if head and head.Parent then head:Destroy() end end)
end

task.spawn(function()
    while LoadingScreen and LoadingScreen.Parent do
        task.wait(1.0 + math.random()*1.6)
        if LoadingScreen and LoadingScreen.Parent then
            spawnShootingStar(LoadingScreen)
        end
    end
end)

local WIN_W = 260

local Win = Instance.new("Frame")
Win.Name="Win"
Win.Size=UDim2.new(0,WIN_W,0,10)
Win.AutomaticSize=Enum.AutomaticSize.Y
Win.AnchorPoint=Vector2.new(0.5,0)
Win.Position=UDim2.new(0.5,0,0,110)
Win.BackgroundColor3=T.BG
Win.BackgroundTransparency=BG_TRANSPARENCY
Win.BorderSizePixel=0
Win.ZIndex=100
Win.Active=true
Win.Parent=GUI
Win.Visible=false
Corner(Win,22)
Stroke(Win, T.Border, 1)

local WinList=Instance.new("UIListLayout")
WinList.FillDirection=Enum.FillDirection.Vertical
WinList.Padding=UDim.new(0,14)
WinList.SortOrder=Enum.SortOrder.LayoutOrder
WinList.Parent=Win
Pad(Win,18,20,18,18)

-- drag by the window itself (no separate header bar, matches reference)
do
    local drag,ds,ws,mv
    Win.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            drag=true; mv=false; ds=inp.Position; ws=Win.Position
        end
    end)
    Win.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local d=inp.Position-ds
            if not mv and d.Magnitude<6 then return end
            mv=true
            Win.Position=UDim2.new(ws.X.Scale,ws.X.Offset+d.X,ws.Y.Scale,ws.Y.Offset+d.Y)
        end
    end)
end

-- ============================================================
-- TITLE
-- ============================================================
local Title=Instance.new("TextLabel")
Title.Size=UDim2.new(1,0,0,16)
Title.BackgroundTransparency=1
Title.Text="infinity code redeem · private  [F]"
Title.TextSize=11
Title.Font=Enum.Font.GothamBold
Title.TextColor3=T.White
Title.TextXAlignment=Enum.TextXAlignment.Left
Title.TextTruncate=Enum.TextTruncate.AtEnd
Title.LayoutOrder=1
Title.ZIndex=101
Title.Parent=Win

-- ============================================================
-- START / STOP BUTTON
-- ============================================================
local StartBtn=Instance.new("TextButton")
StartBtn.Size=UDim2.new(1,0,0,40)
StartBtn.BackgroundColor3=T.Panel
StartBtn.BackgroundTransparency=PANEL_TRANSPARENCY
StartBtn.AutoButtonColor=false
StartBtn.Text="start"
StartBtn.TextSize=13
StartBtn.Font=Enum.Font.GothamBold
StartBtn.TextColor3=T.White
StartBtn.LayoutOrder=2
StartBtn.ZIndex=101
StartBtn.Parent=Win
Corner(StartBtn,16)
Stroke(StartBtn,T.Border,1)

-- ============================================================
-- STATUS TEXT + COUNTER
-- ============================================================
local StatusWrap=Instance.new("Frame")
StatusWrap.Size=UDim2.new(1,0,0,34)
StatusWrap.BackgroundTransparency=1
StatusWrap.LayoutOrder=3
StatusWrap.ZIndex=101
StatusWrap.Parent=Win
local SWList=Instance.new("UIListLayout")
SWList.FillDirection=Enum.FillDirection.Vertical
SWList.Padding=UDim.new(0,3)
SWList.HorizontalAlignment=Enum.HorizontalAlignment.Center
SWList.Parent=StatusWrap

local StatusLbl=Instance.new("TextLabel")
StatusLbl.Size=UDim2.new(1,0,0,14)
StatusLbl.BackgroundTransparency=1
StatusLbl.Text="enabled"
StatusLbl.TextSize=11
StatusLbl.Font=Enum.Font.GothamBold
StatusLbl.TextColor3=T.Green
StatusLbl.TextXAlignment=Enum.TextXAlignment.Center
StatusLbl.LayoutOrder=1
StatusLbl.ZIndex=102
StatusLbl.Parent=StatusWrap

local CounterLbl=Instance.new("TextLabel")
CounterLbl.Size=UDim2.new(1,0,0,16)
CounterLbl.BackgroundTransparency=1
CounterLbl.Text="0/3"
CounterLbl.TextSize=13
CounterLbl.Font=Enum.Font.GothamBold
CounterLbl.TextColor3=T.White
CounterLbl.TextXAlignment=Enum.TextXAlignment.Center
CounterLbl.LayoutOrder=2
CounterLbl.ZIndex=102
CounterLbl.Parent=StatusWrap

local LastCodeLbl=Instance.new("TextLabel")
LastCodeLbl.Size=UDim2.new(1,0,0,12)
LastCodeLbl.BackgroundTransparency=1
LastCodeLbl.Text="last: —"
LastCodeLbl.TextSize=9
LastCodeLbl.Font=Enum.Font.GothamMedium
LastCodeLbl.TextColor3=T.Dim
LastCodeLbl.TextXAlignment=Enum.TextXAlignment.Center
LastCodeLbl.LayoutOrder=3
LastCodeLbl.ZIndex=102
LastCodeLbl.Parent=StatusWrap

-- ============================================================
-- STEPPER ROW HELPER  (label left, - value + right)
-- ============================================================
local function makeStepperRow(parent, order, labelText, valueText)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,22)
    row.BackgroundTransparency=1
    row.LayoutOrder=order
    row.ZIndex=101
    row.Parent=parent

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(0,80,1,0)
    lbl.BackgroundTransparency=1
    lbl.Text=labelText
    lbl.TextSize=10.5
    lbl.Font=Enum.Font.GothamMedium
    lbl.TextColor3=T.Dim
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.ZIndex=102
    lbl.Parent=row

    local minus=Instance.new("TextButton")
    minus.Size=UDim2.new(0,26,0,22)
    minus.AnchorPoint=Vector2.new(1,0)
    minus.Position=UDim2.new(1,-84,0,0)
    minus.BackgroundColor3=T.Panel
    minus.BackgroundTransparency=PANEL_TRANSPARENCY
    minus.AutoButtonColor=false
    minus.Text="-"
    minus.TextSize=13
    minus.Font=Enum.Font.GothamBold
    minus.TextColor3=T.White
    minus.ZIndex=102
    minus.Parent=row
    Corner(minus,9)
    Stroke(minus,T.Border,1)

    local val=Instance.new("TextLabel")
    val.Size=UDim2.new(0,44,1,0)
    val.AnchorPoint=Vector2.new(1,0)
    val.Position=UDim2.new(1,-40,0,0)
    val.BackgroundTransparency=1
    val.Text=valueText
    val.TextSize=11
    val.Font=Enum.Font.GothamBold
    val.TextColor3=T.White
    val.TextXAlignment=Enum.TextXAlignment.Center
    val.ZIndex=102
    val.Parent=row

    local plus=Instance.new("TextButton")
    plus.Size=UDim2.new(0,26,0,22)
    plus.AnchorPoint=Vector2.new(1,0)
    plus.Position=UDim2.new(1,0,0,0)
    plus.BackgroundColor3=T.Panel
    plus.BackgroundTransparency=PANEL_TRANSPARENCY
    plus.AutoButtonColor=false
    plus.Text="+"
    plus.TextSize=13
    plus.Font=Enum.Font.GothamBold
    plus.TextColor3=T.White
    plus.ZIndex=102
    plus.Parent=row
    Corner(plus,9)
    Stroke(plus,T.Border,1)

    return {row=row, minus=minus, plus=plus, val=val}
end

local WordsRow = makeStepperRow(Win, 4, "words", "3")
local DelayRow = makeStepperRow(Win, 5, "delay", "0ms")

-- ============================================================
-- SWITCH ROW HELPER  (label left, toggle right)
-- ============================================================
local function makeSwitch(parent, onColor, initialOn)
    local track=Instance.new("Frame")
    track.Size=UDim2.new(0,34,0,18)
    track.AnchorPoint=Vector2.new(1,0.5)
    track.Position=UDim2.new(1,0,0.5,0)
    track.BackgroundColor3 = initialOn and onColor or T.Panel
    track.BackgroundTransparency = PANEL_TRANSPARENCY
    track.BorderSizePixel=0
    track.ZIndex=102
    track.Parent=parent
    Corner(track,9)
    local trackStroke=Stroke(track, initialOn and onColor or T.Border, 1)

    local knob=Instance.new("Frame")
    knob.Size=UDim2.new(0,14,0,14)
    knob.Position = initialOn and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
    knob.BackgroundColor3=T.White
    knob.BackgroundTransparency=0.1
    knob.BorderSizePixel=0
    knob.ZIndex=103
    knob.Parent=track
    Corner(knob,7)

    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,1,0)
    btn.BackgroundTransparency=1
    btn.Text=""
    btn.ZIndex=104
    btn.Parent=track

    local api = {track=track, knob=knob, btn=btn, on=initialOn}
    function api:set(on)
        api.on = on
        if on then
            Tw(track, F, {BackgroundColor3=onColor, BackgroundTransparency=PANEL_TRANSPARENCY-0.15})
            Tw(trackStroke, F, {Color=onColor})
            Tw(knob, F, {Position=UDim2.new(1,-16,0.5,-7)})
        else
            Tw(track, F, {BackgroundColor3=T.Panel, BackgroundTransparency=PANEL_TRANSPARENCY})
            Tw(trackStroke, F, {Color=T.Border})
            Tw(knob, F, {Position=UDim2.new(0,2,0.5,-7)})
        end
    end
    return api
end

local function makeSwitchRow(parent, order, labelText, onColor, initialOn)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,22)
    row.BackgroundTransparency=1
    row.LayoutOrder=order
    row.ZIndex=101
    row.Parent=parent

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-46,1,0)
    lbl.BackgroundTransparency=1
    lbl.Text=labelText
    lbl.TextSize=10.5
    lbl.Font=Enum.Font.GothamMedium
    lbl.TextColor3=T.Dim
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.ZIndex=102
    lbl.Parent=row

    local sw = makeSwitch(row, onColor, initialOn)
    return row, sw
end

local _, AutoSwitch     = makeSwitchRow(Win, 6, "auto-on", T.Green, true)
local _, AllSwitch      = makeSwitchRow(Win, 7, "all messages", T.Accent, false)

-- ============================================================
-- RIDDLE POPUP (only shows while actively solving)
-- ============================================================
local RiddleCard=Instance.new("Frame")
RiddleCard.Size=UDim2.new(1,0,0,0)
RiddleCard.AutomaticSize=Enum.AutomaticSize.Y
RiddleCard.BackgroundColor3=T.Panel
RiddleCard.BackgroundTransparency=PANEL_TRANSPARENCY
RiddleCard.BorderSizePixel=0
RiddleCard.LayoutOrder=8
RiddleCard.Visible=false
RiddleCard.ZIndex=101
RiddleCard.Parent=Win
Corner(RiddleCard,14)
Stroke(RiddleCard,T.Purple,1)
Pad(RiddleCard,6,6,9,9)
local RLL=Instance.new("UIListLayout")
RLL.Padding=UDim.new(0,2)
RLL.Parent=RiddleCard
local RTag=Instance.new("TextLabel")
RTag.Size=UDim2.new(1,0,0,10)
RTag.BackgroundTransparency=1
RTag.Text="riddle solver"
RTag.TextSize=8
RTag.Font=Enum.Font.GothamBold
RTag.TextColor3=T.Purple
RTag.TextXAlignment=Enum.TextXAlignment.Left
RTag.ZIndex=102
RTag.Parent=RiddleCard
local RMsg=Instance.new("TextLabel")
RMsg.Size=UDim2.new(1,0,0,14)
RMsg.BackgroundTransparency=1
RMsg.Text=""
RMsg.TextSize=10.5
RMsg.Font=Enum.Font.GothamMedium
RMsg.TextColor3=T.White
RMsg.TextXAlignment=Enum.TextXAlignment.Left
RMsg.TextWrapped=true
RMsg.ZIndex=102
RMsg.Parent=RiddleCard

-- ============================================================
-- FOOTER
-- ============================================================
local Footer=Instance.new("TextLabel")
Footer.Size=UDim2.new(1,0,0,10)
Footer.BackgroundTransparency=1
Footer.Text="infinity code redeem · private"
Footer.TextSize=7
Footer.Font=Enum.Font.GothamMedium
Footer.TextColor3=T.Dim
Footer.TextXAlignment=Enum.TextXAlignment.Center
Footer.LayoutOrder=9
Footer.ZIndex=101
Footer.Parent=Win

-- ============================================================
-- BOTTOM STATUS BANNER  (logo · branding · live fps/ping)
-- ============================================================
local Banner=Instance.new("Frame")
Banner.Name="StatusBanner"
Banner.Size=UDim2.new(0,300,0,32)
Banner.AnchorPoint=Vector2.new(0.5,1)
Banner.Position=UDim2.new(0.5,0,1,-14)
Banner.BackgroundColor3=T.BG
Banner.BackgroundTransparency=BG_TRANSPARENCY
Banner.BorderSizePixel=0
Banner.ZIndex=90
Banner.Parent=GUI
Corner(Banner,14)
Stroke(Banner,T.Border,1)
Pad(Banner,0,0,10,10)

local BannerList=Instance.new("UIListLayout")
BannerList.FillDirection=Enum.FillDirection.Horizontal
BannerList.VerticalAlignment=Enum.VerticalAlignment.Center
BannerList.Padding=UDim.new(0,8)
BannerList.SortOrder=Enum.SortOrder.LayoutOrder
BannerList.Parent=Banner

local LogoBadge=Instance.new("Frame")
LogoBadge.Size=UDim2.new(0,20,0,20)
LogoBadge.BackgroundColor3=T.Accent
LogoBadge.BackgroundTransparency=0.15
LogoBadge.BorderSizePixel=0
LogoBadge.LayoutOrder=1
LogoBadge.ZIndex=91
LogoBadge.Parent=Banner
Corner(LogoBadge,7)

local LogoGlyph=Instance.new("TextLabel")
LogoGlyph.Size=UDim2.new(1,0,1,0)
LogoGlyph.BackgroundTransparency=1
LogoGlyph.Text="∞"
LogoGlyph.TextSize=14
LogoGlyph.Font=Enum.Font.GothamBlack
LogoGlyph.TextColor3=Color3.fromRGB(255,255,255)
LogoGlyph.ZIndex=92
LogoGlyph.Parent=LogoBadge

local BannerName=Instance.new("TextLabel")
BannerName.Size=UDim2.new(0,150,1,0)
BannerName.BackgroundTransparency=1
BannerName.Text="Infinity's Code Redeemer"
BannerName.TextSize=10.5
BannerName.Font=Enum.Font.GothamBold
BannerName.TextColor3=T.White
BannerName.TextXAlignment=Enum.TextXAlignment.Left
BannerName.TextTruncate=Enum.TextTruncate.AtEnd
BannerName.LayoutOrder=2
BannerName.ZIndex=91
BannerName.Parent=Banner

local FpsLbl=Instance.new("TextLabel")
FpsLbl.Size=UDim2.new(0,52,1,0)
FpsLbl.BackgroundTransparency=1
FpsLbl.Text="FPS --"
FpsLbl.TextSize=10
FpsLbl.Font=Enum.Font.GothamMedium
FpsLbl.TextColor3=T.Green
FpsLbl.TextXAlignment=Enum.TextXAlignment.Right
FpsLbl.LayoutOrder=3
FpsLbl.ZIndex=91
FpsLbl.Parent=Banner

local PingLbl=Instance.new("TextLabel")
PingLbl.Size=UDim2.new(0,68,1,0)
PingLbl.BackgroundTransparency=1
PingLbl.Text="PING --"
PingLbl.TextSize=10
PingLbl.Font=Enum.Font.GothamMedium
PingLbl.TextColor3=T.Accent
PingLbl.TextXAlignment=Enum.TextXAlignment.Right
PingLbl.LayoutOrder=4
PingLbl.ZIndex=91
PingLbl.Parent=Banner

-- live FPS readout, smoothed over ~0.5s windows
do
    local frames, clockStart = 0, os.clock()
    RunService.RenderStepped:Connect(function()
        frames += 1
        local now = os.clock()
        local elapsed = now - clockStart
        if elapsed >= 0.5 then
            local fps = math.floor((frames/elapsed) + 0.5)
            FpsLbl.Text = "FPS "..fps
            frames, clockStart = 0, now
        end
    end)
end

-- live ping readout, polled once a second
task.spawn(function()
    while true do
        local ok, ping = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        if ok and ping then
            PingLbl.Text = "PING "..math.floor(ping).."ms"
        end
        task.wait(1)
    end
end)

-- ============================================================
-- UI HELPERS
-- ============================================================
local function setStatus(msg, col)
    col = col or T.Dim
    StatusLbl.Text = msg
    Tw(StatusLbl, F, {TextColor3=col})
end

local function refreshCounter()
    CounterLbl.Text = tostring(_accumWords).."/"..tostring(_submitThreshold)
end

local function setLastCode(code)
    _lastCode = code
    LastCodeLbl.Text = "last: "..(code or "—")
end

local function flashStart()
    Tw(StartBtn, TweenInfo.new(0.08), {BackgroundColor3=T.Green, BackgroundTransparency=PANEL_TRANSPARENCY-0.2})
    task.delay(0.15, function() Tw(StartBtn, TweenInfo.new(0.25), {BackgroundColor3=T.Panel, BackgroundTransparency=PANEL_TRANSPARENCY}) end)
end

local function showRiddle(msg, col)
    RMsg.Text=msg; RMsg.TextColor3=col or T.White
    RiddleCard.Visible=true
end
local function hideRiddle() RiddleCard.Visible=false end

-- ============================================================
-- TOGGLES
-- ============================================================
local function applyEnabledVisual()
    if _enabled then
        StartBtn.Text = "stop"
        setStatus(_focused and "watching" or "enabled", _focused and T.Green or T.White)
    else
        StartBtn.Text = "start"
        setStatus("disabled", T.Red)
    end
end

local function toggleEnabled()
    _enabled = not _enabled
    applyEnabledVisual()
    flashStart()
end

StartBtn.MouseButton1Click:Connect(toggleEnabled)

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.F then
        toggleEnabled()
    end
end)

AutoSwitch.btn.MouseButton1Click:Connect(function()
    _autoSubmit = not _autoSubmit
    AutoSwitch:set(_autoSubmit)
    _accumWords = 0
    refreshCounter()
end)

AllSwitch.btn.MouseButton1Click:Connect(function()
    _allMessagesMode = not _allMessagesMode
    AllSwitch:set(_allMessagesMode)
end)

WordsRow.minus.MouseButton1Click:Connect(function()
    _submitThreshold = math.max(1, _submitThreshold - 1)
    WordsRow.val.Text = tostring(_submitThreshold)
    refreshCounter()
end)
WordsRow.plus.MouseButton1Click:Connect(function()
    _submitThreshold = math.min(20, _submitThreshold + 1)
    WordsRow.val.Text = tostring(_submitThreshold)
    refreshCounter()
end)

DelayRow.minus.MouseButton1Click:Connect(function()
    _submitDelayMs = math.max(0, _submitDelayMs - 50)
    DelayRow.val.Text = _submitDelayMs.."ms"
end)
DelayRow.plus.MouseButton1Click:Connect(function()
    _submitDelayMs = math.min(3000, _submitDelayMs + 50)
    DelayRow.val.Text = _submitDelayMs.."ms"
end)

UserInputService.TextBoxFocused:Connect(function(box)
    _focused=box
    _accumWords=0
    refreshCounter()
    applyEnabledVisual()
end)
UserInputService.TextBoxFocusReleased:Connect(function(box)
    if _focused==box then
        _focused=nil
        applyEnabledVisual()
    end
end)

-- ============================================================
-- PASTE / SUBMIT LOGIC
-- ============================================================
local function countWords(text)
    local n = 0
    for _ in text:gmatch("%S+") do n += 1 end
    return n
end

local function appendToBox(text)
    if not text or text=="" then return false end
    if not _focused or not _focused.Parent then
        setStatus("click the box!", T.Red)
        return false
    end
    local box = _focused
    local cur=box.Text or ""
    box.Text = (cur=="") and text or (cur.." "..text)

    _accumWords += countWords(text)
    refreshCounter()

    if _autoSubmit and _accumWords >= _submitThreshold then
        task.delay((_submitDelayMs/1000) + jitter(0.08, SUBMIT_DELAY_JITTER), function()
            if box and box.Parent then
                setStatus("submitting...", T.Accent)
                box:ReleaseFocus(true) -- simulates pressing Enter
                task.delay(0.3, applyEnabledVisual)
            end
            _accumWords = 0
            refreshCounter()
        end)
    end
    return true
end

-- ============================================================
-- RIDDLE SOLVING
-- ============================================================
local RIDDLE_KW={
    "when was","how old","what year","what month","birthday","age of",
    "released","release date","hint","riddle","figure out","guess",
    "first letter","combine","spell","backwards","months","years",
    "old is","how many","what is","do you know","can you","which month",
    "which year","how long","since when",
}
local function isRiddle(txt)
    local l=txt:lower()
    for _,p in ipairs(RIDDLE_KW) do if l:find(p,1,true) then return true end end
    return false
end

local SAB={rm="MAY",ry="2024",rf="MAY2024",sa="24",c="MAY24"}
local function solveLocal(txt)
    local l=txt:lower()
    if (l:find("month") or l:find("when")) and (l:find("sab") or l:find("steal") or l:find("releas")) then return SAB.rm end
    if l:find("year") and (l:find("sab") or l:find("releas")) then return SAB.ry end
    if (l:find("when") or l:find("date")) and (l:find("sab") or l:find("steal") or l:find("releas")) then return SAB.rf end
    if (l:find("age") or l:find("old")) and l:find("sammy") then return SAB.sa end
    if (l:find("age") or l:find("old")) and (l:find("month") or l:find("when") or l:find("releas")) then return SAB.c end
    if l:find("may") and l:find("24") then return SAB.c end
    return nil
end

local function callAI(prompt)
    if not ANTHROPIC_KEY or ANTHROPIC_KEY=="" then return nil end
    local ok,result=pcall(function()
        local body=HttpService:JSONEncode({
            model="claude-sonnet-4-6",
            max_tokens=40,
            system="Decode Roblox promo codes for Steal a Brainrot (SAB). SAB released May 2024. Sammy is 24. Output ONLY the code uppercase no spaces nothing else.",
            messages={{role="user",content=prompt}}
        })
        local resp=HttpService:RequestAsync({
            Url="https://api.anthropic.com/v1/messages",
            Method="POST",
            Headers={
                ["Content-Type"]="application/json",
                ["x-api-key"]=ANTHROPIC_KEY,
                ["anthropic-version"]="2023-06-01",
            },
            Body=body,
        })
        if resp.StatusCode==200 then
            local data=HttpService:JSONDecode(resp.Body)
            if data and data.content and data.content[1] then return data.content[1].text end
        end
        return nil
    end)
    if ok and result then return tostring(result):match("^%s*([A-Z0-9_%-]+)%s*$") end
    return nil
end

-- ============================================================
-- DETECTION — strict shape-based code matcher
-- A real code, per how Sammy actually posts them, is ONE clean
-- word (letters/digits only) — sometimes prefixed by an emoji —
-- with no spaces inside it. We pull the longest word-like token
-- out of the raw text and validate its shape, instead of trying
-- to guess from GUI object names (which was the source of both
-- the false positives and the missed real codes).
-- ============================================================
local NOT_CODES = {
    -- rarity / item tags
    COMMON=true, UNCOMMON=true, RARE=true, EPIC=true, LEGENDARY=true,
    MYTHIC=true, SECRET=true, GODLY=true, BRAINROT=true, LIMITED=true,
    -- generic UI chrome
    SETTINGS=true, INVENTORY=true, LOADING=true, CONFIRM=true, CANCEL=true,
    REWARD=true, REWARDS=true, DAILY=true, WEEKLY=true, MONTHLY=true,
    PREMIUM=true, DISCORD=true, WEBSITE=true, FOLLOWERS=true, SUBSCRIBE=true,
    LEADERBOARD=true, BACKPACK=true, EQUIPPED=true,
    PLEASE=true, WELCOME=true, WARNING=true, UPDATE=true, UPDATES=true,
    SHOP=true, MENU=true, TRADE=true, TRADING=true, CLOSE=true, OPEN=true,
    -- reported false positives
    UNCLAIMED=true, GLOBAL=true, AND=true, SEND=true,
}

local MIN_CODE_LEN, MAX_CODE_LEN = 1, 18

-- returns isCode(bool), theWord(string|nil)
local function findCodeShape(raw)
    if not raw or raw=="" then return false, nil end
    local best = nil
    for w in raw:gmatch("%w+") do
        -- longest alnum run in the string — this naturally skips over
        -- leading emoji glyphs / punctuation without needing to strip them
        if (not best) or #w > #best then best = w end
    end
    if not best then return false, nil end

    local len = #best
    if len < MIN_CODE_LEN or len > MAX_CODE_LEN then return false, nil end

    -- Case no longer matters here — detection runs whenever the script is
    -- enabled (the start button is on), and should catch lowercase and
    -- mixed-case tokens too, not just ALL CAPS ones.
    if NOT_CODES[best:upper()] then return false, nil end

    -- reject if the raw text has more than one real word in it — genuine
    -- code drops are a single token, sentences/labels with several words
    -- (e.g. player names, HUD rows) are not
    local wordCount = 0
    for _ in raw:gmatch("%w+") do wordCount += 1 end
    if wordCount > 1 then return false, nil end

    return true, best
end

-- ============================================================
-- ANNOUNCEMENT-SOURCE FILTERING
-- Only used to skip obviously-irrelevant UI regions (backpack,
-- leaderboard, tooltips, etc). The actual "is this a code" call
-- is made by findCodeShape() above, not by guessing object names.
-- ============================================================
local BAD={
    "backpack","inventory","chatmain","leaderboard","hudgui",
    "systemmessage","joinmsg","leavemsg","tutorial","tooltip","loading",
    "quest","mission","eventlabel","gameevent","settings","shop","menu",
}
local function classify(obj)
    local n=(obj.Name or ""):lower()
    local pn=((obj.Parent and obj.Parent.Name) or ""):lower()
    for _,b in ipairs(BAD) do if n:find(b) or pn:find(b) then return false end end
    return true
end

local function processGlobal(txt, sourceName)
    if not _enabled then return end
    if not txt or type(txt)~="string" or #txt<2 then return end

    if _seen[txt] then return end
    _seen[txt]=true
    task.delay(jitter(20,0.2), function() _seen[txt]=nil end)

    if isRiddle(txt) then
        showRiddle("solving...",T.Dim)
        setStatus("riddle...",T.Purple)
        local ans=solveLocal(txt)
        if ans then
            showRiddle("answer: "..ans,T.Green)
            setLastCode(ans)
            local pasted = appendToBox(ans)
            flashStart()
            _statsFound += 1
            if not pasted then showRiddle("answer: "..ans.." (click the box)", T.Red) end
            task.delay(jitter(4,0.25),function() hideRiddle(); applyEnabledVisual() end); return
        end
        showRiddle("asking ai...",T.Dim)
        task.spawn(function()
            local ai=callAI("Sammy said: \""..txt.."\". SAB=May2024,Sammy=24. Code only.")
            if ai then
                showRiddle("ai: "..ai,T.Green)
                setLastCode(ai)
                local pasted = appendToBox(ai)
                flashStart()
                _statsFound += 1
                if not pasted then showRiddle("ai: "..ai.." (click the box)", T.Red) end
                task.delay(jitter(4,0.25),function() hideRiddle(); applyEnabledVisual() end)
            else
                showRiddle("could not solve",T.Red)
                task.delay(jitter(3,0.2),function() hideRiddle(); applyEnabledVisual() end)
            end
        end)
        return
    end

    local isCode, word = findCodeShape(txt)
    if _allMessagesMode and not isCode then
        -- All Messages mode still lets anything through as a manual
        -- override/testing aid, but tags it LOW confidence since it
        -- wasn't actually validated as code-shaped
        word = txt:gsub("%s+"," "):gsub("^%s+",""):gsub("%s+$","")
        if word ~= "" then
            local pasted = appendToBox(word)
            setLastCode(word)
            flashStart()
            _statsFound += 1
            if not pasted then setStatus("click the box!", T.Red) end
        end
        return
    end
    if isCode then
        local pasted = appendToBox(word)
        setLastCode(word)
        flashStart()
        _statsFound += 1
        if not pasted then setStatus("click the box!", T.Red) end
    end
end

local _watched={}
local function watchLabel(obj)
    if _watched[obj] then return end
    _watched[obj]=true
    local sourceName = obj.Name .. " " .. ((obj.Parent and obj.Parent.Name) or "")
    obj:GetPropertyChangedSignal("Text"):Connect(function() processGlobal(obj.Text, sourceName) end)
end

playerGui.DescendantAdded:Connect(function(obj)
    task.wait(jitter(0.04,0.5))
    if obj:IsA("TextLabel") then
        local txt=obj.Text or ""
        local sourceName = obj.Name .. " " .. ((obj.Parent and obj.Parent.Name) or "")
        local passesGate = classify(obj)

        if passesGate then
            watchLabel(obj)
            if #txt>1 then processGlobal(txt, sourceName) end
        end
        obj:GetPropertyChangedSignal("Text"):Connect(function()
            local t=obj.Text or ""
            if classify(obj) then
                if not _watched[obj] then watchLabel(obj) end
                processGlobal(t, sourceName)
            end
        end)
    end
end)

pcall(function()
    local tcs=game:GetService("TextChatService")
    if tcs and tcs.MessageReceived then
        tcs.MessageReceived:Connect(function(msg)
            if not msg then return end
            if msg.TextSource == nil then return end
            local chanName = (msg.TextChannel and msg.TextChannel.Name or ""):lower()
            if chanName:find("system") then return end

            local senderName = ""
            pcall(function()
                local plr = Players:GetPlayerByUserId(msg.TextSource.UserId)
                if plr then senderName = plr.Name .. " " .. plr.DisplayName end
            end)

            processGlobal(msg.Text or "", senderName)
        end)
    end
end)

pcall(function()
    local shared=ReplicatedStorage:WaitForChild("Shared",5)
    if not shared then return end
    local flags=shared:WaitForChild("Flags",5); if not flags then return end
    local cf=flags:WaitForChild("CodesFlags",5); if not cf then return end
    cf.ChildAdded:Connect(function(obj)
        processGlobal(obj.Name)
        if obj:IsA("StringValue") then
            processGlobal(tostring(obj.Value))
            obj:GetPropertyChangedSignal("Value"):Connect(function() processGlobal(tostring(obj.Value)) end)
        end
    end)
end)

pcall(function()
    local ctrl=ReplicatedStorage:WaitForChild("Controllers",5)
    if not ctrl then return end
    local cc=ctrl:WaitForChild("CodesController",5); if not cc then return end
    cc.DescendantAdded:Connect(function(obj)
        if obj:IsA("StringValue") then processGlobal(tostring(obj.Value)) end
        processGlobal(obj.Name)
    end)
end)

refreshCounter()
applyEnabledVisual()

-- ============================================================
-- RUN LOADING SEQUENCE → reveal HUD → start music
-- ============================================================
task.spawn(function()
    local steps = {
        {0.18, "initializing"},
        {0.40, "loading modules"},
        {0.62, "syncing codes"},
        {0.85, "connecting"},
        {1.00, "ready"},
    }
    for _,step in ipairs(steps) do
        local target, label = step[1], step[2]
        PctLbl.Text = label
        Tw(BarFill, TweenInfo.new(0.5 + math.random()*0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size=UDim2.new(target,0,1,0)})
        task.wait(0.55 + math.random()*0.4)
    end
    task.wait(0.4)

    -- fade the loading screen out
    Tw(LoadingScreen, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency=1})
    for _,lbl in ipairs({LogoTitle, LogoSub, PrivateTag, PctLbl}) do
        Tw(lbl, TweenInfo.new(0.4), {TextTransparency=1})
    end
    Tw(BarOuter, TweenInfo.new(0.4), {BackgroundTransparency=1})
    Tw(BarFill, TweenInfo.new(0.4), {BackgroundTransparency=1})
    task.wait(0.6)
    LoadingScreen:Destroy()

    -- reveal the HUD with a soft pop-in
    Win.Visible = true
    local scale = Instance.new("UIScale")
    scale.Scale = 0.85
    scale.Parent = Win
    Tw(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale=1})

    -- start music once the HUD is up
    pcall(function() Music:Play() end)
end)
