local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local HttpService       = game:GetService("HttpService")

local lp        = Players.LocalPlayer
local playerGui = lp:WaitForChild("PlayerGui")

local ANTHROPIC_KEY = "sk-ant-api03-placeholder-replace-with-real-key"

-- ============================================================
-- STATE
-- ============================================================
local _enabled          = true
local _collapsed        = false
local _seen             = {}
local _focused          = nil
local _statsFound       = 0
local _lastFoundAt      = nil

local _allMessagesMode  = false
local _autoSubmit       = false
local _submitThreshold  = 3
local _accumWords       = 0

-- auto-submit timing (kept fast, still jittered so it's not a fixed-tick pattern)
local SUBMIT_DELAY_BASE   = 0.10
local SUBMIT_DELAY_JITTER = 0.35

local function jitter(base, spreadPct)
    spreadPct = spreadPct or 0.25
    local delta = base * spreadPct
    return base + (math.random() * 2 - 1) * delta
end

-- ============================================================
-- THEME
-- ============================================================
local T = {
    BG     = Color3.fromRGB(7,9,14),
    Card   = Color3.fromRGB(15,17,26),
    Card2  = Color3.fromRGB(12,14,21),
    Border = Color3.fromRGB(36,40,60),
    Accent = Color3.fromRGB(90,150,255),
    Rain   = Color3.fromRGB(150,195,255),
    Green  = Color3.fromRGB(70,210,100),
    Red    = Color3.fromRGB(255,70,70),
    Yellow = Color3.fromRGB(255,195,50),
    Orange = Color3.fromRGB(255,150,60),
    White  = Color3.fromRGB(220,230,255),
    Dim    = Color3.fromRGB(60,64,90),
    DimTxt = Color3.fromRGB(120,124,155),
}
local F      = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SWIPE  = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function Tw(o,i,p) TweenService:Create(o,i,p):Play() end
local function Corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=p end
local function Stroke(p,col,th)
    local s=Instance.new("UIStroke"); s.Color=col or T.Border
    s.Thickness=th or 1; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s
end

pcall(function() if game.CoreGui:FindFirstChild("SDLCPaste") then game.CoreGui.SDLCPaste:Destroy() end end)
pcall(function() if playerGui:FindFirstChild("SDLCPaste") then playerGui.SDLCPaste:Destroy() end end)
pcall(function() if game.CoreGui:FindFirstChild("RainyCodeRedeemer") then game.CoreGui.RainyCodeRedeemer:Destroy() end end)
pcall(function() if playerGui:FindFirstChild("RainyCodeRedeemer") then playerGui.RainyCodeRedeemer:Destroy() end end)

local GUI = Instance.new("ScreenGui")
GUI.Name="RainyCodeRedeemer"; GUI.ResetOnSpawn=false; GUI.IgnoreGuiInset=true
GUI.DisplayOrder=999
if not pcall(function() GUI.Parent=game.CoreGui end) then GUI.Parent=playerGui end

local WIN_W = 226

local Win = Instance.new("Frame")
Win.Name="Win"
Win.Size=UDim2.new(0,WIN_W,0,10)
Win.AutomaticSize=Enum.AutomaticSize.Y
Win.AnchorPoint=Vector2.new(1,0)
Win.Position=UDim2.new(1,-14,0,52)
Win.BackgroundColor3=T.BG
Win.BorderSizePixel=0
Win.ZIndex=100
Win.ClipsDescendants=true
Win.Parent=GUI
Corner(Win,10)

local WBorder=Stroke(Win, T.Accent, 1.4)
local WBG=Instance.new("UIGradient")
WBG.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(25,60,170)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150,195,255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(25,60,170)),
})
WBG.Rotation=0
WBG.Parent=WBorder
RunService.RenderStepped:Connect(function(dt) WBG.Rotation=(WBG.Rotation+dt*55)%360 end)

local WinList=Instance.new("UIListLayout")
WinList.FillDirection=Enum.FillDirection.Vertical
WinList.Padding=UDim.new(0,0)
WinList.SortOrder=Enum.SortOrder.LayoutOrder
WinList.HorizontalAlignment=Enum.HorizontalAlignment.Center
WinList.Parent=Win

-- ============================================================
-- HEADER  (with drifting star field behind the title)
-- ============================================================
local Hdr=Instance.new("Frame")
Hdr.Size=UDim2.new(1,0,0,38)
Hdr.BackgroundColor3=Color3.fromRGB(11,13,20)
Hdr.BorderSizePixel=0
Hdr.LayoutOrder=1
Hdr.Active=true
Hdr.ClipsDescendants=true
Hdr.ZIndex=101
Hdr.Parent=Win
Corner(Hdr,10)

local HdrBG=Instance.new("UIGradient")
HdrBG.Color=ColorSequence.new(Color3.fromRGB(13,15,23), Color3.fromRGB(9,10,17))
HdrBG.Rotation=90
HdrBG.Parent=Hdr

local HdrFill=Instance.new("Frame")
HdrFill.Size=UDim2.new(1,0,0,10)
HdrFill.Position=UDim2.new(0,0,1,-10)
HdrFill.BackgroundColor3=Color3.fromRGB(11,13,20)
HdrFill.BorderSizePixel=0
HdrFill.ZIndex=101
HdrFill.Parent=Hdr

local HdrLine=Instance.new("Frame")
HdrLine.Size=UDim2.new(1,0,0,1)
HdrLine.Position=UDim2.new(0,0,1,0)
HdrLine.BackgroundColor3=T.Rain
HdrLine.BackgroundTransparency=0.5
HdrLine.BorderSizePixel=0
HdrLine.ZIndex=102
HdrLine.Parent=Hdr

-- star field: small dots drifting left-to-right, twinkling, behind the title
local StarField=Instance.new("Frame")
StarField.Size=UDim2.new(1,0,1,0)
StarField.BackgroundTransparency=1
StarField.ZIndex=101
StarField.Parent=Hdr

local stars = {}
for i=1,16 do
    local star=Instance.new("Frame")
    local sz = math.random(1,2)
    star.Size=UDim2.new(0,sz,0,sz)
    star.Position=UDim2.new(0, math.random(0,WIN_W), 0, math.random(3,33))
    star.BackgroundColor3 = (i%3==0) and T.Rain or T.White
    star.BackgroundTransparency = math.random(20,70)/100
    star.BorderSizePixel=0
    star.ZIndex=101
    star.Parent=StarField
    Corner(star,2)
    table.insert(stars, {obj=star, speed=math.random(6,22), x=star.Position.X.Offset})
end
RunService.Heartbeat:Connect(function(dt)
    for _,s in ipairs(stars) do
        s.x = s.x + s.speed*dt
        if s.x > WIN_W+4 then s.x = -4 end
        s.obj.Position = UDim2.new(0, s.x, s.obj.Position.Y.Scale, s.obj.Position.Y.Offset)
    end
end)
-- gentle twinkle loop
task.spawn(function()
    while true do
        for _,s in ipairs(stars) do
            Tw(s.obj, TweenInfo.new(jitter(1.4,0.5)), {BackgroundTransparency = math.random(15,80)/100})
        end
        task.wait(jitter(1.2,0.3))
    end
end)

local Logo=Instance.new("Frame")
Logo.Size=UDim2.new(0,18,0,18)
Logo.Position=UDim2.new(0,9,0.5,-9)
Logo.BackgroundColor3=T.Accent
Logo.BorderSizePixel=0
Logo.ZIndex=103
Logo.Parent=Hdr
Corner(Logo,5)
local LogoBG=Instance.new("UIGradient")
LogoBG.Color=ColorSequence.new(Color3.fromRGB(150,195,255), Color3.fromRGB(40,80,220))
LogoBG.Rotation=135
LogoBG.Parent=Logo
local LogoTxt=Instance.new("TextLabel")
LogoTxt.Size=UDim2.new(1,0,1,0)
LogoTxt.BackgroundTransparency=1
LogoTxt.Text="R"
LogoTxt.TextSize=10
LogoTxt.Font=Enum.Font.GothamBlack
LogoTxt.TextColor3=Color3.fromRGB(8,8,12)
LogoTxt.TextXAlignment=Enum.TextXAlignment.Center
LogoTxt.TextYAlignment=Enum.TextYAlignment.Center
LogoTxt.ZIndex=104
LogoTxt.Parent=Logo

-- title: auto-shrinks to fit ("RAINY CODE REDEEMER") via TextScaled
local TitleBox=Instance.new("Frame")
TitleBox.Size=UDim2.new(0,116,0,15)
TitleBox.Position=UDim2.new(0,31,0.5,-8)
TitleBox.BackgroundTransparency=1
TitleBox.ZIndex=103
TitleBox.Parent=Hdr

local TitleL=Instance.new("TextLabel")
TitleL.Size=UDim2.new(1,0,1,0)
TitleL.BackgroundTransparency=1
TitleL.Text="RAINY CODE REDEEMER"
TitleL.TextScaled=true
TitleL.Font=Enum.Font.GothamBlack
TitleL.TextColor3=T.Rain
TitleL.TextXAlignment=Enum.TextXAlignment.Left
TitleL.TextYAlignment=Enum.TextYAlignment.Center
TitleL.ZIndex=104
TitleL.Parent=TitleBox
local TitleFit=Instance.new("UITextSizeConstraint")
TitleFit.MaxTextSize=11
TitleFit.MinTextSize=6
TitleFit.Parent=TitleL

local TitleSub=Instance.new("TextLabel")
TitleSub.Size=UDim2.new(1,0,0,8)
TitleSub.Position=UDim2.new(0,31,0.5,7)
TitleSub.BackgroundTransparency=1
TitleSub.Text="SAB code watcher"
TitleSub.TextSize=6
TitleSub.Font=Enum.Font.GothamMedium
TitleSub.TextColor3=T.DimTxt
TitleSub.TextXAlignment=Enum.TextXAlignment.Left
TitleSub.ZIndex=103
TitleSub.Parent=Hdr

local CollapseBtn=Instance.new("TextButton")
CollapseBtn.Size=UDim2.new(0,18,0,18)
CollapseBtn.AnchorPoint=Vector2.new(1,0.5)
CollapseBtn.Position=UDim2.new(1,-42,0.5,0)
CollapseBtn.BackgroundTransparency=1
CollapseBtn.Text="▾"
CollapseBtn.TextSize=13
CollapseBtn.Font=Enum.Font.GothamBold
CollapseBtn.TextColor3=T.DimTxt
CollapseBtn.ZIndex=104
CollapseBtn.Parent=Hdr

-- ============================================================
-- SWITCH COMPONENT (replaces plain ON/OFF text buttons)
-- ============================================================
local function makeSwitch(parent, anchorX, anchorY, initialOn, onColor, zBase)
    zBase = zBase or 103
    local track=Instance.new("Frame")
    track.Size=UDim2.new(0,30,0,15)
    track.AnchorPoint=Vector2.new(1,0.5)
    track.Position=UDim2.new(1,anchorX,0.5,anchorY)
    track.BackgroundColor3 = initialOn and onColor or T.Dim
    track.BorderSizePixel=0
    track.ZIndex=zBase
    track.Parent=parent
    Corner(track,8)
    local trackStroke=Stroke(track, initialOn and onColor or T.Border, 1)

    local knob=Instance.new("Frame")
    knob.Size=UDim2.new(0,11,0,11)
    knob.Position = initialOn and UDim2.new(1,-13,0.5,-5.5) or UDim2.new(0,2,0.5,-5.5)
    knob.BackgroundColor3=T.White
    knob.BorderSizePixel=0
    knob.ZIndex=zBase+1
    knob.Parent=track
    Corner(knob,6)

    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,1,0)
    btn.BackgroundTransparency=1
    btn.Text=""
    btn.ZIndex=zBase+2
    btn.Parent=track

    local api = {track=track, knob=knob, btn=btn, on=initialOn}
    function api:set(on)
        api.on = on
        if on then
            Tw(track, SWIPE, {BackgroundColor3=onColor})
            Tw(trackStroke, SWIPE, {Color=onColor})
            Tw(knob, SWIPE, {Position=UDim2.new(1,-13,0.5,-5.5)})
        else
            Tw(track, SWIPE, {BackgroundColor3=T.Dim})
            Tw(trackStroke, SWIPE, {Color=T.Border})
            Tw(knob, SWIPE, {Position=UDim2.new(0,2,0.5,-5.5)})
        end
    end
    return api
end

local KillSwitch = makeSwitch(Hdr, -8, 0, true, T.Green, 103)

do
    local drag,ds,ws,mv
    Hdr.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            drag=true; mv=false; ds=inp.Position; ws=Win.Position
        end
    end)
    Hdr.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local d=inp.Position-ds
            if not mv and d.Magnitude<5 then return end
            mv=true
            Win.Position=UDim2.new(ws.X.Scale,ws.X.Offset+d.X,ws.Y.Scale,ws.Y.Offset+d.Y)
        end
    end)
end

-- ============================================================
-- BODY
-- ============================================================
local Body=Instance.new("Frame")
Body.Size=UDim2.new(1,0,0,0)
Body.AutomaticSize=Enum.AutomaticSize.Y
Body.BackgroundTransparency=1
Body.BorderSizePixel=0
Body.LayoutOrder=2
Body.ZIndex=101
Body.ClipsDescendants=true
Body.Parent=Win

local BL=Instance.new("UIListLayout")
BL.FillDirection=Enum.FillDirection.Vertical
BL.Padding=UDim.new(0,5)
BL.HorizontalAlignment=Enum.HorizontalAlignment.Center
BL.Parent=Body

local BPad=Instance.new("UIPadding")
BPad.PaddingTop=UDim.new(0,7); BPad.PaddingBottom=UDim.new(0,9)
BPad.PaddingLeft=UDim.new(0,8); BPad.PaddingRight=UDim.new(0,8)
BPad.Parent=Body

-- Status card
local StatusCard=Instance.new("Frame")
StatusCard.Size=UDim2.new(1,0,0,26)
StatusCard.BackgroundColor3=T.Card
StatusCard.BorderSizePixel=0
StatusCard.LayoutOrder=1
StatusCard.ZIndex=102
StatusCard.Parent=Body
Corner(StatusCard,7)
Stroke(StatusCard,T.Border,1)

local SDot=Instance.new("Frame")
SDot.Size=UDim2.new(0,6,0,6)
SDot.Position=UDim2.new(0,8,0.5,-3)
SDot.BackgroundColor3=T.Dim
SDot.BorderSizePixel=0
SDot.ZIndex=103
SDot.Parent=StatusCard
Corner(SDot,3)

local SLbl=Instance.new("TextLabel")
SLbl.Size=UDim2.new(1,-22,1,0)
SLbl.Position=UDim2.new(0,18,0,0)
SLbl.BackgroundTransparency=1
SLbl.Text="Click the code box first"
SLbl.TextSize=10
SLbl.Font=Enum.Font.GothamMedium
SLbl.TextColor3=T.Dim
SLbl.TextXAlignment=Enum.TextXAlignment.Left
SLbl.TextYAlignment=Enum.TextYAlignment.Center
SLbl.ZIndex=103
SLbl.Parent=StatusCard

-- Code card
local CodeCard=Instance.new("Frame")
CodeCard.Size=UDim2.new(1,0,0,58)
CodeCard.BackgroundColor3=T.Card
CodeCard.BorderSizePixel=0
CodeCard.LayoutOrder=2
CodeCard.ClipsDescendants=true
CodeCard.ZIndex=102
CodeCard.Parent=Body
Corner(CodeCard,7)
local CodeStroke=Stroke(CodeCard,T.Border,1)
local CodeBG=Instance.new("UIGradient")
CodeBG.Color=ColorSequence.new(Color3.fromRGB(14,16,24),Color3.fromRGB(10,12,18))
CodeBG.Rotation=90
CodeBG.Parent=CodeCard

local CodeSmall=Instance.new("TextLabel")
CodeSmall.Size=UDim2.new(0,70,0,12)
CodeSmall.Position=UDim2.new(0,9,0,5)
CodeSmall.BackgroundTransparency=1
CodeSmall.Text="DETECTED"
CodeSmall.TextSize=7
CodeSmall.Font=Enum.Font.GothamBold
CodeSmall.TextColor3=T.Dim
CodeSmall.TextXAlignment=Enum.TextXAlignment.Left
CodeSmall.ZIndex=103
CodeSmall.Parent=CodeCard

local ConfBadge=Instance.new("Frame")
ConfBadge.Size=UDim2.new(0,42,0,13)
ConfBadge.AnchorPoint=Vector2.new(1,0)
ConfBadge.Position=UDim2.new(1,-9,0,5)
ConfBadge.BackgroundColor3=T.Dim
ConfBadge.BackgroundTransparency=0.15
ConfBadge.BorderSizePixel=0
ConfBadge.ZIndex=103
ConfBadge.Visible=false
ConfBadge.Parent=CodeCard
Corner(ConfBadge,4)
local ConfTxt=Instance.new("TextLabel")
ConfTxt.Size=UDim2.new(1,0,1,0)
ConfTxt.BackgroundTransparency=1
ConfTxt.Text="LOW"
ConfTxt.TextSize=7
ConfTxt.Font=Enum.Font.GothamBlack
ConfTxt.TextColor3=Color3.fromRGB(8,8,12)
ConfTxt.TextXAlignment=Enum.TextXAlignment.Center
ConfTxt.TextYAlignment=Enum.TextYAlignment.Center
ConfTxt.ZIndex=104
ConfTxt.Parent=ConfBadge

local CodeVal=Instance.new("TextLabel")
CodeVal.Size=UDim2.new(1,-10,0,22)
CodeVal.Position=UDim2.new(0,9,0,17)
CodeVal.BackgroundTransparency=1
CodeVal.Text="—"
CodeVal.TextSize=17
CodeVal.Font=Enum.Font.GothamBlack
CodeVal.TextColor3=T.Dim
CodeVal.TextXAlignment=Enum.TextXAlignment.Left
CodeVal.TextYAlignment=Enum.TextYAlignment.Center
CodeVal.ZIndex=103
CodeVal.Parent=CodeCard

local DecayTrack=Instance.new("Frame")
DecayTrack.Size=UDim2.new(1,-18,0,3)
DecayTrack.Position=UDim2.new(0,9,1,-11)
DecayTrack.BackgroundColor3=Color3.fromRGB(28,30,42)
DecayTrack.BorderSizePixel=0
DecayTrack.ZIndex=103
DecayTrack.Parent=CodeCard
Corner(DecayTrack,2)
local DecayFill=Instance.new("Frame")
DecayFill.Size=UDim2.new(0,0,1,0)
DecayFill.BackgroundColor3=T.Accent
DecayFill.BorderSizePixel=0
DecayFill.ZIndex=104
DecayFill.Parent=DecayTrack
Corner(DecayFill,2)

-- All messages row
local AllRow=Instance.new("Frame")
AllRow.Size=UDim2.new(1,0,0,24)
AllRow.BackgroundColor3=T.Card
AllRow.BorderSizePixel=0
AllRow.LayoutOrder=3
AllRow.ZIndex=102
AllRow.Parent=Body
Corner(AllRow,7)
Stroke(AllRow,T.Border,1)
local AllLbl=Instance.new("TextLabel")
AllLbl.Size=UDim2.new(1,-46,1,0)
AllLbl.Position=UDim2.new(0,9,0,0)
AllLbl.BackgroundTransparency=1
AllLbl.Text="All messages mode"
AllLbl.TextSize=9
AllLbl.Font=Enum.Font.GothamMedium
AllLbl.TextColor3=T.DimTxt
AllLbl.TextXAlignment=Enum.TextXAlignment.Left
AllLbl.ZIndex=103
AllLbl.Parent=AllRow
local AllSwitch = makeSwitch(AllRow, -8, 0, false, T.Accent, 103)

-- Auto-submit row
local AutoRow=Instance.new("Frame")
AutoRow.Size=UDim2.new(1,0,0,24)
AutoRow.BackgroundColor3=T.Card
AutoRow.BorderSizePixel=0
AutoRow.LayoutOrder=4
AutoRow.ZIndex=102
AutoRow.Parent=Body
Corner(AutoRow,7)
Stroke(AutoRow,T.Border,1)
local AutoLbl=Instance.new("TextLabel")
AutoLbl.Size=UDim2.new(0,66,1,0)
AutoLbl.Position=UDim2.new(0,9,0,0)
AutoLbl.BackgroundTransparency=1
AutoLbl.Text="Auto-submit"
AutoLbl.TextSize=9
AutoLbl.Font=Enum.Font.GothamMedium
AutoLbl.TextColor3=T.DimTxt
AutoLbl.TextXAlignment=Enum.TextXAlignment.Left
AutoLbl.ZIndex=103
AutoLbl.Parent=AutoRow

local MinusBtn=Instance.new("TextButton")
MinusBtn.Size=UDim2.new(0,16,0,16)
MinusBtn.AnchorPoint=Vector2.new(1,0.5)
MinusBtn.Position=UDim2.new(1,-86,0.5,0)
MinusBtn.BackgroundColor3=T.Card2
MinusBtn.BorderSizePixel=0
MinusBtn.AutoButtonColor=false
MinusBtn.Text="−"
MinusBtn.TextSize=11
MinusBtn.Font=Enum.Font.GothamBold
MinusBtn.TextColor3=T.White
MinusBtn.ZIndex=103
MinusBtn.Parent=AutoRow
Corner(MinusBtn,4)
Stroke(MinusBtn,T.Border,1)

local ThreshLbl=Instance.new("TextLabel")
ThreshLbl.Size=UDim2.new(0,26,1,0)
ThreshLbl.AnchorPoint=Vector2.new(1,0.5)
ThreshLbl.Position=UDim2.new(1,-57,0.5,0)
ThreshLbl.BackgroundTransparency=1
ThreshLbl.Text="3 wds"
ThreshLbl.TextSize=8
ThreshLbl.Font=Enum.Font.GothamBold
ThreshLbl.TextColor3=T.White
ThreshLbl.TextXAlignment=Enum.TextXAlignment.Center
ThreshLbl.ZIndex=103
ThreshLbl.Parent=AutoRow

local PlusBtn=Instance.new("TextButton")
PlusBtn.Size=UDim2.new(0,16,0,16)
PlusBtn.AnchorPoint=Vector2.new(1,0.5)
PlusBtn.Position=UDim2.new(1,-40,0.5,0)
PlusBtn.BackgroundColor3=T.Card2
PlusBtn.BorderSizePixel=0
PlusBtn.AutoButtonColor=false
PlusBtn.Text="+"
PlusBtn.TextSize=11
PlusBtn.Font=Enum.Font.GothamBold
PlusBtn.TextColor3=T.White
PlusBtn.ZIndex=103
PlusBtn.Parent=AutoRow
Corner(PlusBtn,4)
Stroke(PlusBtn,T.Border,1)

local AutoSwitch = makeSwitch(AutoRow, -8, 0, false, T.Green, 103)

-- Riddle card
local RiddleCard=Instance.new("Frame")
RiddleCard.Size=UDim2.new(1,0,0,0)
RiddleCard.AutomaticSize=Enum.AutomaticSize.Y
RiddleCard.BackgroundColor3=Color3.fromRGB(30,24,8)
RiddleCard.BorderSizePixel=0
RiddleCard.LayoutOrder=5
RiddleCard.Visible=false
RiddleCard.ZIndex=102
RiddleCard.Parent=Body
Corner(RiddleCard,7)
Stroke(RiddleCard,T.Yellow,1)
local RiddlePad=Instance.new("UIPadding")
RiddlePad.PaddingTop=UDim.new(0,5); RiddlePad.PaddingBottom=UDim.new(0,6)
RiddlePad.PaddingLeft=UDim.new(0,8); RiddlePad.PaddingRight=UDim.new(0,8)
RiddlePad.Parent=RiddleCard
local RLL=Instance.new("UIListLayout")
RLL.FillDirection=Enum.FillDirection.Vertical
RLL.Padding=UDim.new(0,2)
RLL.Parent=RiddleCard
local RTag=Instance.new("TextLabel")
RTag.Size=UDim2.new(1,0,0,11)
RTag.BackgroundTransparency=1
RTag.Text="🧩 RIDDLE SOLVER"
RTag.TextSize=7; RTag.Font=Enum.Font.GothamBold
RTag.TextColor3=T.Yellow
RTag.TextXAlignment=Enum.TextXAlignment.Left
RTag.ZIndex=103; RTag.Parent=RiddleCard
local RMsg=Instance.new("TextLabel")
RMsg.Size=UDim2.new(1,0,0,14)
RMsg.BackgroundTransparency=1; RMsg.Text=""
RMsg.TextSize=10; RMsg.Font=Enum.Font.GothamMedium
RMsg.TextColor3=T.White; RMsg.TextXAlignment=Enum.TextXAlignment.Left
RMsg.TextWrapped=true; RMsg.ZIndex=103; RMsg.Parent=RiddleCard

-- Stats footer
local StatsRow=Instance.new("Frame")
StatsRow.Size=UDim2.new(1,0,0,16)
StatsRow.BackgroundTransparency=1
StatsRow.LayoutOrder=6
StatsRow.ZIndex=102
StatsRow.Parent=Body
local StatsL=Instance.new("TextLabel")
StatsL.Size=UDim2.new(0.5,0,1,0)
StatsL.BackgroundTransparency=1
StatsL.Text="Found: 0"
StatsL.TextSize=8
StatsL.Font=Enum.Font.GothamMedium
StatsL.TextColor3=T.DimTxt
StatsL.TextXAlignment=Enum.TextXAlignment.Left
StatsL.ZIndex=103
StatsL.Parent=StatsRow
local StatsR=Instance.new("TextLabel")
StatsR.Size=UDim2.new(0.5,0,1,0)
StatsR.Position=UDim2.new(0.5,0,0,0)
StatsR.BackgroundTransparency=1
StatsR.Text="Last: —"
StatsR.TextSize=8
StatsR.Font=Enum.Font.GothamMedium
StatsR.TextColor3=T.DimTxt
StatsR.TextXAlignment=Enum.TextXAlignment.Right
StatsR.ZIndex=103
StatsR.Parent=StatsRow

-- ============================================================
-- UI HELPERS
-- ============================================================
local function setStatus(msg, col)
    col=col or T.Dim
    SLbl.Text=msg; SLbl.TextColor3=col; SDot.BackgroundColor3=col
end

local CONF_COLORS = {HIGH=T.Green, MED=T.Yellow, LOW=T.Orange}

local _decayConn = nil
local function runDecayBar(seconds)
    if _decayConn then _decayConn:Disconnect(); _decayConn=nil end
    local elapsed = 0
    DecayFill.Size = UDim2.new(1,0,1,0)
    Tw(DecayFill, TweenInfo.new(0.1), {BackgroundColor3=T.Accent})
    _decayConn = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        local pct = math.clamp(1 - (elapsed/seconds), 0, 1)
        DecayFill.Size = UDim2.new(pct,0,1,0)
        if pct <= 0.25 then DecayFill.BackgroundColor3 = T.Red end
        if pct <= 0 then _decayConn:Disconnect(); _decayConn=nil end
    end)
end

local function updateStats()
    _statsFound += 1
    _lastFoundAt = os.date("%H:%M:%S")
    StatsL.Text = "Found: "..tostring(_statsFound)
    StatsR.Text = "Last: "..tostring(_lastFoundAt)
end

local function flashCode(code, col, confidence, decaySeconds)
    col = col or T.Accent
    CodeVal.Text = code
    CodeVal.TextColor3 = col
    Tw(CodeStroke, TweenInfo.new(0.1), {Color=col})
    task.delay(jitter(0.6,0.3), function()
        Tw(CodeStroke, TweenInfo.new(0.5), {Color=T.Border})
    end)
    if confidence then
        ConfBadge.Visible = true
        ConfTxt.Text = confidence
        Tw(ConfBadge, TweenInfo.new(0.15), {BackgroundColor3=CONF_COLORS[confidence] or T.Dim})
    else
        ConfBadge.Visible = false
    end
    runDecayBar(decaySeconds or 20)
    updateStats()
end

local function showRiddle(msg, col)
    RMsg.Text=msg; RMsg.TextColor3=col or T.White
    RiddleCard.Visible=true
end
local function hideRiddle() RiddleCard.Visible=false end

-- ============================================================
-- TOGGLES
-- ============================================================
KillSwitch.btn.MouseButton1Click:Connect(function()
    _enabled = not _enabled
    KillSwitch:set(_enabled)
    if _enabled then
        setStatus(_focused and "Ready — watching" or "Click the code box first", _focused and T.Green or T.Dim)
    else
        setStatus("Paused",T.Dim)
    end
end)

CollapseBtn.MouseButton1Click:Connect(function()
    _collapsed = not _collapsed
    if _collapsed then
        Body.Visible = false
        Tw(CollapseBtn, F, {Rotation=-90})
    else
        Body.Visible = true
        Tw(CollapseBtn, F, {Rotation=0})
    end
end)

AllSwitch.btn.MouseButton1Click:Connect(function()
    _allMessagesMode = not _allMessagesMode
    AllSwitch:set(_allMessagesMode)
    if _allMessagesMode then
        setStatus("All messages mode ON",T.Accent)
    else
        setStatus(_focused and "Ready — watching" or "Click the code box first", _focused and T.Green or T.Dim)
    end
end)

AutoSwitch.btn.MouseButton1Click:Connect(function()
    _autoSubmit = not _autoSubmit
    AutoSwitch:set(_autoSubmit)
    _accumWords = 0
end)

MinusBtn.MouseButton1Click:Connect(function()
    _submitThreshold = math.max(1, _submitThreshold - 1)
    ThreshLbl.Text = _submitThreshold.." wds"
end)
PlusBtn.MouseButton1Click:Connect(function()
    _submitThreshold = math.min(20, _submitThreshold + 1)
    ThreshLbl.Text = _submitThreshold.." wds"
end)

UserInputService.TextBoxFocused:Connect(function(box)
    _focused=box
    _accumWords=0
    if _enabled then setStatus("Ready — watching",T.Green) end
end)
UserInputService.TextBoxFocusReleased:Connect(function(box)
    if _focused==box then
        _focused=nil
        if _enabled then setStatus("Click the code box first",T.Dim) end
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
        setStatus("Click the code box first!",T.Yellow)
        return false
    end
    local box = _focused
    local cur=box.Text or ""
    box.Text = (cur=="") and text or (cur.." "..text)
    setStatus("Appended!",T.Green)

    _accumWords += countWords(text)

    if _autoSubmit and _accumWords >= _submitThreshold then
        task.delay(jitter(SUBMIT_DELAY_BASE, SUBMIT_DELAY_JITTER), function()
            if box and box.Parent then
                setStatus("Auto-submitting...",T.Accent)
                box:ReleaseFocus(true) -- simulates pressing Enter
                setStatus("Submitted!",T.Green)
            end
            _accumWords = 0
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
-- DETECTION — word extraction + scoring
-- ============================================================
-- scores an individual token: uppercase+digit mix reads like a real
-- promo code (HIGH); pure uppercase word is plausible (MED); anything
-- else is weak (LOW)
local function scoreToken(tok)
    local hasDigit = tok:match("%d") ~= nil
    local isAllCaps = tok == tok:upper() and tok:match("%a") ~= nil
    local len = #tok
    if isAllCaps and hasDigit and len>=4 and len<=14 then return "HIGH" end
    if isAllCaps and len>=3 then return "MED" end
    return "LOW"
end
local RANK = {HIGH=3, MED=2, LOW=1}

-- returns text, confidence
-- bypass=true (All Messages mode): keep every token no matter how short,
-- confidence always LOW since nothing was actually vetted
local function extractWords(txt, bypass)
    if bypass then
        local words={}
        for w in txt:gmatch("%S+") do
            local clean=w:gsub("[^A-Za-z0-9]","")
            if #clean>=1 then table.insert(words,clean) end
        end
        if #words==0 then return nil end
        return table.concat(words," "), "LOW"
    end

    local words={}
    local best = "LOW"
    for w in txt:gmatch("%S+") do
        local clean=w:gsub("[^A-Za-z0-9]","")
        if #clean>=2 then
            local isUpper=clean==clean:upper() and clean:match("[A-Z]")
            local isLower=clean==clean:lower() and clean:match("[a-z]") and #clean>=3
            if isUpper or isLower then
                table.insert(words,clean)
                local s = scoreToken(clean)
                if RANK[s] > RANK[best] then best = s end
            end
        end
    end
    if #words==0 then return nil end
    -- long word salads are inherently weaker signal even if one token scored high
    if #words>4 and best=="HIGH" then best="MED" end
    return table.concat(words," "), best
end

-- ============================================================
-- ANNOUNCEMENT-SOURCE FILTERING
-- Only real code announcements should trigger detection — not
-- system messages (join/leave/chat system text) or generic game
-- event/UI labels. These lists are intentionally narrow; widen the
-- GOOD list if your game's announcer frame uses a different name.
-- ============================================================
local BAD={
    "backpack","inventory","chatmain","bubblechat","overhead","nametag",
    "leaderboard","hudgui","systemmessage","joinmsg","leavemsg","tutorial",
    "tooltip","loading","quest","mission","eventlabel","gameevent",
}
local GOOD={
    "announce","announcement","broadcast","banner","sammy","codealert",
    "codepopup","promobanner","globalannounce",
}
local function classify(obj)
    local n=(obj.Name or ""):lower()
    local pn=((obj.Parent and obj.Parent.Name) or ""):lower()
    local gpn=((obj.Parent and obj.Parent.Parent and obj.Parent.Parent.Name) or ""):lower()
    for _,b in ipairs(BAD) do if n:find(b) or pn:find(b) then return false end end
    for _,g in ipairs(GOOD) do
        if n:find(g) or pn:find(g) or gpn:find(g) then return true end
    end
    return false
end

local function processGlobal(txt)
    if not _enabled then return end
    if not txt or type(txt)~="string" or #txt<2 then return end
    if _seen[txt] then return end
    _seen[txt]=true
    task.delay(jitter(20,0.2), function() _seen[txt]=nil end)

    if isRiddle(txt) then
        showRiddle("Solving...",T.Yellow)
        setStatus("Riddle detected...",T.Yellow)
        local ans=solveLocal(txt)
        if ans then
            showRiddle("Answer: "..ans,T.Green)
            setStatus("Solved: "..ans,T.Green)
            local pasted = appendToBox(ans)
            flashCode(ans, T.Green, "HIGH", 20)
            if not pasted then showRiddle("Answer: "..ans.." (paste box not focused)", T.Yellow) end
            task.delay(jitter(4,0.25),hideRiddle); return
        end
        showRiddle("Asking AI...",T.Yellow)
        task.spawn(function()
            local ai=callAI("Sammy said: \""..txt.."\". SAB=May2024,Sammy=24. Code only.")
            if ai then
                showRiddle("AI: "..ai,T.Green)
                setStatus("AI solved: "..ai,T.Green)
                local pasted = appendToBox(ai)
                flashCode(ai, T.Green, "MED", 20)
                if not pasted then showRiddle("AI: "..ai.." (paste box not focused)", T.Yellow) end
                task.delay(jitter(4,0.25),hideRiddle)
            else
                showRiddle("Could not solve",T.Red)
                setStatus("Riddle unsolved",T.Red)
                task.delay(jitter(3,0.2),function()
                    hideRiddle()
                    setStatus(_focused and "Ready — watching" or "Click the code box first", _focused and T.Green or T.Dim)
                end)
            end
        end)
        return
    end

    local words, confidence = extractWords(txt, _allMessagesMode)
    if words then
        local pasted = appendToBox(words)
        flashCode(words, CONF_COLORS[confidence], confidence, 20)
        if not pasted then flashCode(words, T.Yellow, confidence, 20) end
    end
end

local _watched={}
local function watchLabel(obj)
    if _watched[obj] then return end
    _watched[obj]=true
    obj:GetPropertyChangedSignal("Text"):Connect(function() processGlobal(obj.Text) end)
end

playerGui.DescendantAdded:Connect(function(obj)
    task.wait(jitter(0.04,0.5))
    if obj:IsA("TextLabel") then
        local txt=obj.Text or ""
        -- classify() is the announcement-source gate: it must pass regardless
        -- of All Messages mode, since that setting only affects word shape,
        -- not which UI elements count as an "announcement" in the first place
        if classify(obj) then
            watchLabel(obj)
            if #txt>1 then processGlobal(txt) end
        end
        obj:GetPropertyChangedSignal("Text"):Connect(function()
            local t=obj.Text or ""
            if classify(obj) then
                if not _watched[obj] then watchLabel(obj) end
                processGlobal(t)
            end
        end)
    end
end)

pcall(function()
    local tcs=game:GetService("TextChatService")
    if tcs and tcs.MessageReceived then
        tcs.MessageReceived:Connect(function(msg)
            if not msg then return end
            -- Roblox's built-in system messages (joins/leaves/system notices)
            -- carry no TextSource — skip those, only real chat/announcer text
            if msg.TextSource == nil then return end
            local chanName = (msg.TextChannel and msg.TextChannel.Name or ""):lower()
            if chanName:find("system") then return end
            processGlobal(msg.Text or "")
        end)
    end
end)

-- direct game remotes for actual promo-code flags — always trusted,
-- these aren't generic UI/system text, they're the game's own code data
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

setStatus("Click the code box first",T.Dim)
