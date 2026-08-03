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
local _seen             = {}
local _focused          = nil
local _statsFound       = 0
local _lastCode         = nil

local _allMessagesMode  = false
local _sammyMode        = false
local _autoSubmit       = true
local _submitThreshold  = 3
local _submitDelayMs    = 0
local _accumWords       = 0

local SUBMIT_DELAY_JITTER = 0.35

local SAMMY_NAME = "spydersammy"
local function textMentionsSammy(txt)
    if not txt then return false end
    return tostring(txt):lower():find(SAMMY_NAME, 1, true) ~= nil
end

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

pcall(function() if game.CoreGui:FindFirstChild("RainyCodeRedeemer") then game.CoreGui.RainyCodeRedeemer:Destroy() end end)
pcall(function() if playerGui:FindFirstChild("RainyCodeRedeemer") then playerGui.RainyCodeRedeemer:Destroy() end end)

local GUI = Instance.new("ScreenGui")
GUI.Name="RainyCodeRedeemer"; GUI.ResetOnSpawn=false; GUI.IgnoreGuiInset=true
GUI.DisplayOrder=999
-- Global ZIndexBehavior lets the starfield (low ZIndex) sit behind the
-- panel (high ZIndex) even though both are parented to the ScreenGui.
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Global
if not pcall(function() GUI.Parent=game.CoreGui end) then GUI.Parent=playerGui end

-- ============================================================
-- STARFIELD  (twinkling dots behind the whole HUD)
-- ============================================================
local function createStarField(parent, count)
    count = count or 70
    for i=1,count do
        local size = math.random(1,3)
        local star = Instance.new("Frame")
        star.Name = "Star"
        star.Size = UDim2.new(0, size, 0, size)
        star.Position = UDim2.new(math.random(), math.random(-4,4), math.random(), math.random(-4,4))
        star.BackgroundColor3 = T.Star
        star.BorderSizePixel = 0
        star.ZIndex = 1
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
Corner(Win,14)
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
Title.Text="rainy code redeemer  [F]"
Title.TextSize=12
Title.Font=Enum.Font.GothamBold
Title.TextColor3=T.White
Title.TextXAlignment=Enum.TextXAlignment.Left
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
Corner(StartBtn,10)
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
    Corner(minus,6)
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
    Corner(plus,6)
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

local _, AutoSwitch  = makeSwitchRow(Win, 6, "auto-on", T.Green, true)
local _, AllSwitch   = makeSwitchRow(Win, 7, "all messages", T.Accent, false)
local _, SammySwitch = makeSwitchRow(Win, 8, "sammy mode", T.Purple, false)

-- ============================================================
-- RIDDLE POPUP (only shows while actively solving)
-- ============================================================
local RiddleCard=Instance.new("Frame")
RiddleCard.Size=UDim2.new(1,0,0,0)
RiddleCard.AutomaticSize=Enum.AutomaticSize.Y
RiddleCard.BackgroundColor3=T.Panel
RiddleCard.BackgroundTransparency=PANEL_TRANSPARENCY
RiddleCard.BorderSizePixel=0
RiddleCard.LayoutOrder=9
RiddleCard.Visible=false
RiddleCard.ZIndex=101
RiddleCard.Parent=Win
Corner(RiddleCard,8)
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
Footer.Text="rainy code redeemer"
Footer.TextSize=7
Footer.Font=Enum.Font.GothamMedium
Footer.TextColor3=T.Dim
Footer.TextXAlignment=Enum.TextXAlignment.Center
Footer.LayoutOrder=10
Footer.ZIndex=101
Footer.Parent=Win

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

SammySwitch.btn.MouseButton1Click:Connect(function()
    _sammyMode = not _sammyMode
    SammySwitch:set(_sammyMode)
    if _sammyMode then
        setStatus("sammy only", T.Purple)
    else
        applyEnabledVisual()
    end
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
    LEADERBOARD=true, INVENTORY=true, BACKPACK=true, EQUIPPED=true,
    PLEASE=true, WELCOME=true, WARNING=true, UPDATE=true, UPDATES=true,
    -- common short/med UI words (still filtered by min length, kept here for safety)
    SHOP=true, MENU=true, TRADE=true, TRADING=true, CLOSE=true, OPEN=true,
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

    -- Accept pure-numeric tokens too (best:upper() == best is true for
    -- digit-only strings since upper() doesn't touch digits), not just
    -- ones that contain at least one letter.
    local isAllCaps = best == best:upper()
    if not isAllCaps then return false, nil end

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

    if _sammyMode then
        local fromSammy = (sourceName and textMentionsSammy(sourceName)) or textMentionsSammy(txt)
        if not fromSammy then return end
    end

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
        local passesGate = _sammyMode or classify(obj)

        if passesGate then
            watchLabel(obj)
            if #txt>1 then processGlobal(txt, sourceName) end
        end
        obj:GetPropertyChangedSignal("Text"):Connect(function()
            local t=obj.Text or ""
            if _sammyMode or classify(obj) then
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
