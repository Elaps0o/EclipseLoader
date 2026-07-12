-- ============================================================================
-- Eclipse UI Library v2.0
-- Custom UI replacing Obsidian. API-compatible surface for eclipse.lua.
-- Features: Window/Tabs/Groupbox/Toggle/Slider/Dropdown/Button/Label/Divider/
-- Input/KeyPicker(hold-toggle-always)/ColorPicker(HSV+alpha+hex)/Notify/
-- CustomCursor(RightShift)/ConfigManager/Watermark/Resize/Splash.
-- Heavy purple + black theme, gradient accents, tab slide-in animations.
-- ============================================================================

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UserInput     = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local CoreGui       = game:GetService("CoreGui")
local HttpService   = game:GetService("HttpService")
local Mouse         = game:GetService("Players").LocalPlayer:GetMouse()

local LP = Players.LocalPlayer

-- ============================================================================
-- THEME  (heavy purple + black)
-- ============================================================================
local THEME = {
    Background      = Color3.fromRGB(10, 8, 16),
    BackgroundAlt   = Color3.fromRGB(14, 11, 22),
    Panel           = Color3.fromRGB(18, 14, 28),
    PanelAlt        = Color3.fromRGB(24, 19, 38),
    PanelHi         = Color3.fromRGB(32, 24, 50),
    Stroke          = Color3.fromRGB(60, 40, 100),
    StrokeSoft      = Color3.fromRGB(40, 28, 70),
    Text            = Color3.fromRGB(235, 232, 245),
    TextDim         = Color3.fromRGB(165, 155, 190),
    TextMuted       = Color3.fromRGB(110, 100, 135),
    AccentA         = Color3.fromRGB(139, 60, 255),   -- deep purple
    AccentB         = Color3.fromRGB(196, 102, 255),  -- bright violet
    AccentC         = Color3.fromRGB(89, 30, 200),    -- dark purple
    Danger          = Color3.fromRGB(239, 68, 68),
    Success         = Color3.fromRGB(94, 220, 130),
    FontFamily      = Enum.Font.Gotham,
    FontFamilyBold  = Enum.Font.GothamBold,
    FontFamilyMed   = Enum.Font.GothamMedium,
}

local LOGO_URL = "rbxassetid://118820133561219"
-- Fallback: original ChatGPT image URL as ImageLabel Image string
local LOGO_URL_ALT = "https://raw.githubusercontent.com/Elaps0o/EclipseLoader/main/ChatGPT%20Image%20Jul%2012%2C%202026%2C%2001_21_51%20AM.png"

-- ============================================================================
-- CORE
-- ============================================================================
local Library = {}
Library.__index = Library

Library.Options    = {}
Library.Toggles    = {}
Library.Tabs       = {}
Library.Unloaded   = false
Library.Signals    = {}
Library._Unloads   = {}
Library.MinSize    = Vector2.new(720, 480)
Library.MaxSize    = Vector2.new(1500, 950)
Library.Theme      = THEME
Library.NotifySide = "Right"
Library.CursorEnabled = false

-- ============================================================================
-- LUCIDE ICONS (latte-soft/lucide-roblox)
-- ============================================================================
local _Lucide
local function _loadLucide()
    if _Lucide ~= nil then return _Lucide end
    local ok, mod = pcall(function()
        local src = game:HttpGet("https://raw.githubusercontent.com/latte-soft/lucide-roblox/master/lucide-roblox.luau")
        return loadstring(src)()
    end)
    _Lucide = ok and mod or false
    return _Lucide
end
function Library:Lucide(name, size)
    local L = _loadLucide(); if not L then return nil end
    local ok, a = pcall(L.GetAsset, name, size or 48)
    if not ok or not a then return nil end
    return a
end
function Library:LucideImage(parent, name, size)
    local a = Library:Lucide(name, size)
    local img = new("ImageLabel", { BackgroundTransparency = 1, Parent = parent,
        ImageColor3 = THEME.Text, ScaleType = Enum.ScaleType.Fit })
    if a then
        img.Image = a.Url; img.ImageRectSize = a.ImageRectSize; img.ImageRectOffset = a.ImageRectOffset
    end
    return img
end


local function new(class, props, children)
    local o = Instance.new(class)
    if props then for k, v in pairs(props) do o[k] = v end end
    if children then for _, c in ipairs(children) do c.Parent = o end end
    return o
end

local function corner(inst, r)
    return new("UICorner", { CornerRadius = UDim.new(0, r or 6), Parent = inst })
end

local function stroke(inst, color, thickness, transparency)
    return new("UIStroke", {
        Color = color or THEME.Stroke, Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = inst,
    })
end

local function pad(inst, l, r, t, b)
    return new("UIPadding", {
        PaddingLeft = UDim.new(0, l or 0), PaddingRight = UDim.new(0, r or 0),
        PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or 0),
        Parent = inst,
    })
end

local function tween(obj, t, style, dir, props)
    local ti = TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
    local tw = TweenService:Create(obj, ti, props)
    tw:Play()
    return tw
end

local function gradient(inst, colors, rot, transparency)
    local g = new("UIGradient", {
        Color = typeof(colors) == "ColorSequence" and colors or ColorSequence.new(colors[1], colors[2]),
        Rotation = rot or 0, Parent = inst,
    })
    if transparency then g.Transparency = transparency end
    return g
end

-- markdown -> RichText
local function esc(s) return (s:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")) end
local function mdToRich(text)
    if type(text) ~= "string" then return tostring(text or "") end
    if text:find("<%a") then return text end
    text = esc(text)
    text = text:gsub("%*%*(.-)%*%*", "<b>%1</b>")
    text = text:gsub("__(.-)__", "<b>%1</b>")
    text = text:gsub("~~(.-)~~", "<s>%1</s>")
    text = text:gsub("%*(.-)%*", "<i>%1</i>")
    text = text:gsub("`(.-)`", "<font color='rgb(196,102,255)'><i>%1</i></font>")
    text = text:gsub("%[(.-)%]%((.-)%)", "<u>%1</u>")
    return text
end
Library.MDtoRich = mdToRich

-- ============================================================================
-- SCREEN GUI ROOT
-- ============================================================================
local function makeScreen(name)
    local sg = new("ScreenGui", {
        Name = name, ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })
    local ok = pcall(function() sg.Parent = CoreGui end)
    if not ok then sg.Parent = LP:WaitForChild("PlayerGui") end
    return sg
end

local ROOT_GUI = makeScreen("EclipseUIRoot")
table.insert(Library._Unloads, function() pcall(function() ROOT_GUI:Destroy() end) end)

-- ============================================================================
-- CUSTOM CURSOR (Lua) - toggled by RightShift
-- ============================================================================
local CursorGui, CursorFrame
local function buildCursor()
    CursorGui = new("ScreenGui", {
        Name = "EclipseCursor", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true, DisplayOrder = 2147483647, Parent = ROOT_GUI.Parent,
    })
    CursorFrame = new("Frame", {
        Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5), Parent = CursorGui, ZIndex = 999,
    })
    -- diamond core
    local core = new("Frame", {
        Size = UDim2.fromScale(0.55, 0.55), Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 45,
        BackgroundColor3 = THEME.AccentB, BorderSizePixel = 0, Parent = CursorFrame,
    })
    corner(core, 3)
    gradient(core, ColorSequence.new(THEME.AccentB, THEME.AccentA), 45)
    stroke(core, Color3.fromRGB(255, 255, 255), 1, 0.4)
    -- outer glow ring
    local ring = new("Frame", {
        Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 45,
        BackgroundTransparency = 1, Parent = CursorFrame,
    })
    stroke(ring, THEME.AccentA, 1, 0.5)
    corner(ring, 4)
end
buildCursor()
CursorGui.Enabled = false

RunService:BindToRenderStep("EclipseCursorTrack", Enum.RenderPriority.Camera.Value + 1, function()
    if CursorGui and CursorGui.Enabled then
        local mp = UserInput:GetMouseLocation()
        CursorFrame.Position = UDim2.fromOffset(mp.X, mp.Y)
    end
end)
table.insert(Library._Unloads, function() pcall(function() RunService:UnbindFromRenderStep("EclipseCursorTrack") end) end)

UserInput.InputBegan:Connect(function(i, gp)
    if i.KeyCode == Enum.KeyCode.RightShift then
        Library.CursorEnabled = not Library.CursorEnabled
        CursorGui.Enabled = Library.CursorEnabled
        Library:Notify({ Title = "Cursor", Description = Library.CursorEnabled and "Enabled (RightShift)" or "Disabled", Time = 2 })
    end
end)

-- ============================================================================
-- SPLASH  (small, corner)
-- ============================================================================
local function createSplash()
    local sg = new("ScreenGui", {
        Name = "EclipseSplash", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true,
        DisplayOrder = 999, Parent = ROOT_GUI.Parent,
    })
    local box = new("Frame", {
        Size = UDim2.fromOffset(240, 70), Position = UDim2.new(0.5, -120, 0, -80),
        BackgroundColor3 = THEME.Panel, BorderSizePixel = 0, Parent = sg,
    })
    corner(box, 10); stroke(box, THEME.Stroke, 1, 0.4)
    -- purple gradient bar
    local bar = new("Frame", { Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BorderSizePixel = 0, Parent = box })
    gradient(bar, ColorSequence.new(THEME.AccentA, THEME.AccentB), 0)
    local logo = new("ImageLabel", {
        Size = UDim2.fromOffset(46, 46), Position = UDim2.new(0, 12, 0.5, -23),
        BackgroundTransparency = 1, Image = LOGO_URL_ALT, Parent = box,
    })
    corner(logo, 8)
    new("TextLabel", {
        Size = UDim2.new(1, -70, 0, 22), Position = UDim2.new(0, 66, 0, 12),
        BackgroundTransparency = 1, Font = THEME.FontFamilyBold, TextSize = 16,
        Text = "ECLIPSE", TextColor3 = THEME.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = box,
    })
    local sub = new("TextLabel", {
        Size = UDim2.new(1, -70, 0, 16), Position = UDim2.new(0, 66, 0, 34),
        BackgroundTransparency = 1, Font = THEME.FontFamily, TextSize = 12,
        Text = "Loading...", TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Parent = box,
    })
    tween(box, 0.35, nil, nil, { Position = UDim2.new(0.5, -120, 0, 24) })
    return {
        Gui = sg, Sub = sub,
        Close = function()
            tween(box, 0.3, nil, nil, { Position = UDim2.new(0.5, -120, 0, -90) })
            task.delay(0.35, function() pcall(function() sg:Destroy() end) end)
        end,
    }
end

-- ============================================================================
-- NOTIFY
-- ============================================================================
local NotifyStack
local function ensureNotifyStack()
    if NotifyStack and NotifyStack.Parent then return NotifyStack end
    NotifyStack = new("Frame", {
        Name = "EclipseNotifyStack", BackgroundTransparency = 1,
        Size = UDim2.new(0, 320, 1, -100), Position = UDim2.new(1, -340, 0, 60),
        Parent = ROOT_GUI,
    })
    new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Top,
        HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8),
        Parent = NotifyStack,
    })

    return NotifyStack
end

function Library:Notify(opts)
    opts = opts or {}
    local title = opts.Title or "Notification"
    local desc  = opts.Description or opts.Text or ""
    local dur   = opts.Time or opts.Duration or 4
    local parent = ensureNotifyStack()
    local card = new("Frame", {
        Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = THEME.Panel,
        BorderSizePixel = 0, ClipsDescendants = true, Parent = parent,
    })
    corner(card, 8); stroke(card, THEME.StrokeSoft, 1, 0.3)
    local line = new("Frame", { Size = UDim2.new(0, 3, 1, 0), BorderSizePixel = 0, Parent = card })
    gradient(line, ColorSequence.new(THEME.AccentA, THEME.AccentB), 90)
    local titleLbl = new("TextLabel", {
        Size = UDim2.new(1, -18, 0, 18), Position = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1, Font = THEME.FontFamilyBold, TextSize = 14, RichText = true,
        Text = mdToRich(title), TextColor3 = THEME.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = card,
    })
    local descLbl = new("TextLabel", {
        Size = UDim2.new(1, -18, 1, -30), Position = UDim2.new(0, 12, 0, 28),
        BackgroundTransparency = 1, Font = THEME.FontFamily, TextSize = 12, RichText = true, TextWrapped = true,
        Text = mdToRich(desc), TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, Parent = card,
    })
    -- fade in
    card.BackgroundTransparency = 1
    for _, d in ipairs(card:GetDescendants()) do
        if d:IsA("TextLabel") then d.TextTransparency = 1 end
    end
    tween(card, 0.25, nil, nil, { BackgroundTransparency = 0 })
    tween(titleLbl, 0.3, nil, nil, { TextTransparency = 0 })
    tween(descLbl, 0.3, nil, nil, { TextTransparency = 0 })
    task.delay(dur, function()
        tween(card, 0.3, nil, nil, { BackgroundTransparency = 1 })
        tween(titleLbl, 0.25, nil, nil, { TextTransparency = 1 })
        tween(descLbl, 0.25, nil, nil, { TextTransparency = 1 })
        task.wait(0.35); pcall(function() card:Destroy() end)
    end)
end

-- ============================================================================
-- INTERNAL: option registry helper
-- ============================================================================
local function registerOption(id, obj)
    if not id then return obj end
    Library.Options[id] = obj
    return obj
end
local function registerToggle(id, obj)
    if not id then return obj end
    Library.Toggles[id] = obj
    return obj
end

-- ============================================================================
-- COLORPICKER POPUP  (Obsidian-style: SV square + hue bar + alpha + hex)
-- ============================================================================
local ActivePopup
local function closePopup()
    if ActivePopup then
        pcall(function() ActivePopup:Destroy() end)
        ActivePopup = nil
    end
end

local function openColorPopup(anchor, h, s, v, a, transparencyEnabled, cb)
    closePopup()
    local pop = new("Frame", {
        Size = UDim2.fromOffset(230, transparencyEnabled and 240 or 220),
        BackgroundColor3 = THEME.Panel, BorderSizePixel = 0, Parent = ROOT_GUI, ZIndex = 500,
    })
    ActivePopup = pop
    corner(pop, 8); stroke(pop, THEME.Stroke, 1, 0.2)
    -- position under anchor
    local ap = anchor.AbsolutePosition; local as = anchor.AbsoluteSize
    pop.Position = UDim2.fromOffset(ap.X, ap.Y + as.Y + 6)
    -- SV square
    local sv = new("ImageLabel", {
        Size = UDim2.fromOffset(180, 140), Position = UDim2.fromOffset(10, 10),
        BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0,
        Image = "rbxassetid://4155801252",  -- SV overlay (white->transparent horiz, black bottom)
        Parent = pop, ZIndex = 501,
    })
    corner(sv, 4)
    local svDot = new("Frame", {
        Size = UDim2.fromOffset(8, 8), BackgroundColor3 = Color3.new(1,1,1),
        BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Parent = sv, ZIndex = 502,
    })
    corner(svDot, 4); stroke(svDot, Color3.new(0,0,0), 1, 0.2)
    -- hue slider
    local hue = new("ImageLabel", {
        Size = UDim2.fromOffset(20, 140), Position = UDim2.fromOffset(200, 10),
        BackgroundTransparency = 1, Image = "rbxassetid://3641079629", Parent = pop, ZIndex = 501,
    })
    corner(hue, 3)
    local hueDot = new("Frame", {
        Size = UDim2.new(1, 4, 0, 3), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, h, 0), BackgroundColor3 = Color3.new(1,1,1),
        BorderSizePixel = 0, Parent = hue, ZIndex = 502,
    })
    -- alpha slider (optional)
    local alpha, alphaDot
    if transparencyEnabled then
        alpha = new("Frame", {
            Size = UDim2.fromOffset(210, 12), Position = UDim2.fromOffset(10, 156),
            BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, Parent = pop, ZIndex = 501,
        })
        corner(alpha, 3)
        gradient(alpha, ColorSequence.new(Color3.new(1,1,1), Color3.fromHSV(h, s, v)), 0)
        alphaDot = new("Frame", {
            Size = UDim2.new(0, 3, 1, 4), AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(a, 0, 0.5, 0), BackgroundColor3 = Color3.new(0,0,0),
            BorderSizePixel = 0, Parent = alpha, ZIndex = 502,
        })
    end
    -- hex input
    local hexY = transparencyEnabled and 180 or 160
    local hex = new("TextBox", {
        Size = UDim2.fromOffset(140, 24), Position = UDim2.fromOffset(10, hexY),
        BackgroundColor3 = THEME.PanelAlt, BorderSizePixel = 0, Text = "", PlaceholderText = "#RRGGBB",
        Font = THEME.FontFamily, TextSize = 12, TextColor3 = THEME.Text, ClearTextOnFocus = false,
        Parent = pop, ZIndex = 501,
    })
    corner(hex, 4); stroke(hex, THEME.StrokeSoft)
    local preview = new("Frame", {
        Size = UDim2.fromOffset(70, 24), Position = UDim2.fromOffset(160, hexY),
        BackgroundColor3 = Color3.fromHSV(h, s, v), BorderSizePixel = 0, Parent = pop, ZIndex = 501,
    })
    corner(preview, 4); stroke(preview, THEME.StrokeSoft)

    local function update()
        local c = Color3.fromHSV(h, s, v)
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svDot.Position = UDim2.new(s, 0, 1 - v, 0)
        hueDot.Position = UDim2.new(0.5, 0, h, 0)
        preview.BackgroundColor3 = c
        hex.Text = string.format("#%02X%02X%02X", math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5))
        if alpha then
            alpha:FindFirstChildOfClass("UIGradient").Color = ColorSequence.new(Color3.new(1,1,1), c)
            alphaDot.Position = UDim2.new(a, 0, 0.5, 0)
        end
        cb(c, 1 - a, h, s, v)
    end
    update()

    local dragging
    sv.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = "sv" end
    end)
    hue.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = "hue" end
    end)
    if alpha then
        alpha.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = "alpha" end
        end)
    end
    UserInput.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = nil end
    end)
    UserInput.InputChanged:Connect(function(i)
        if not dragging or i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local mp = UserInput:GetMouseLocation()
        if dragging == "sv" then
            local rel = mp - sv.AbsolutePosition
            s = math.clamp(rel.X / sv.AbsoluteSize.X, 0, 1)
            v = 1 - math.clamp(rel.Y / sv.AbsoluteSize.Y, 0, 1)
        elseif dragging == "hue" then
            local rel = mp - hue.AbsolutePosition
            h = math.clamp(rel.Y / hue.AbsoluteSize.Y, 0, 1)
        elseif dragging == "alpha" then
            local rel = mp - alpha.AbsolutePosition
            a = math.clamp(rel.X / alpha.AbsoluteSize.X, 0, 1)
        end
        update()
    end)
    hex.FocusLost:Connect(function()
        local t = hex.Text:gsub("#",""):gsub("%s","")
        if #t == 6 then
            local r = tonumber(t:sub(1,2),16); local g = tonumber(t:sub(3,4),16); local b = tonumber(t:sub(5,6),16)
            if r and g and b then
                local c = Color3.fromRGB(r,g,b); h,s,v = Color3.toHSV(c); update()
            end
        end
    end)
    -- click outside to close
    local conn
    conn = UserInput.InputBegan:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
        local mp = UserInput:GetMouseLocation()
        local p1, p2 = pop.AbsolutePosition, pop.AbsolutePosition + pop.AbsoluteSize
        if mp.X < p1.X or mp.X > p2.X or mp.Y < p1.Y or mp.Y > p2.Y then
            conn:Disconnect(); closePopup()
        end
    end)
    return pop
end

-- ============================================================================
-- KEYPICKER MODE POPUP  (right-click -> Hold/Toggle/Always dropdown)
-- ============================================================================
local function openModePopup(anchor, current, cb)
    closePopup()
    local pop = new("Frame", {
        Size = UDim2.fromOffset(140, 92), BackgroundColor3 = THEME.Panel,
        BorderSizePixel = 0, Parent = ROOT_GUI, ZIndex = 500,
    })
    ActivePopup = pop
    corner(pop, 6); stroke(pop, THEME.Stroke, 1, 0.2)
    local line = new("Frame", { Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0, Parent = pop, ZIndex = 501 })
    gradient(line, ColorSequence.new(THEME.AccentA, THEME.AccentB), 0)
    local ap, as = anchor.AbsolutePosition, anchor.AbsoluteSize
    pop.Position = UDim2.fromOffset(ap.X, ap.Y + as.Y + 4)
    local layout = new("UIListLayout", { Padding = UDim.new(0, 2), Parent = pop, SortOrder = Enum.SortOrder.LayoutOrder })
    pad(pop, 4, 4, 6, 4)
    local modes = { "Always", "Toggle", "Hold" }
    for _, m in ipairs(modes) do
        local b = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = (m == current) and THEME.PanelHi or THEME.PanelAlt,
            BorderSizePixel = 0, AutoButtonColor = false, Font = THEME.FontFamily, TextSize = 12,
            Text = m, TextColor3 = (m == current) and THEME.AccentB or THEME.Text, Parent = pop, ZIndex = 501,
        })
        corner(b, 4)
        b.MouseButton1Click:Connect(function() cb(m); closePopup() end)
        b.MouseEnter:Connect(function() if m ~= current then tween(b, 0.15, nil, nil, { BackgroundColor3 = THEME.PanelHi }) end end)
        b.MouseLeave:Connect(function() if m ~= current then tween(b, 0.15, nil, nil, { BackgroundColor3 = THEME.PanelAlt }) end end)
    end
    local conn
    conn = UserInput.InputBegan:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local mp = UserInput:GetMouseLocation()
        local p1, p2 = pop.AbsolutePosition, pop.AbsolutePosition + pop.AbsoluteSize
        if mp.X < p1.X or mp.X > p2.X or mp.Y < p1.Y or mp.Y > p2.Y then
            conn:Disconnect(); closePopup()
        end
    end)
end

-- ============================================================================
-- BUILDERS (controls)
-- ============================================================================
local function attachLabelBar(parent, text)
    local wrap = new("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Parent = parent })
    new("TextLabel", {
        Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1,
        Font = THEME.FontFamily, TextSize = 12, RichText = true, Text = mdToRich(text or ""),
        TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Parent = wrap,
    })
    return wrap
end

-- ----- TOGGLE -----
local function buildToggle(parent, text, opts)
    opts = opts or {}
    local state = opts.Default == true
    local row = new("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Parent = parent })
    local box = new("TextButton", {
        Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 8, 0.5, -8),
        BackgroundColor3 = THEME.PanelAlt, BorderSizePixel = 0, AutoButtonColor = false, Text = "", Parent = row,
    })
    corner(box, 4); stroke(box, THEME.StrokeSoft)
    local fill = new("Frame", {
        Size = UDim2.new(0, 0, 0, 0), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = THEME.AccentB, BorderSizePixel = 0, Parent = box,
    })
    corner(fill, 3); gradient(fill, ColorSequence.new(THEME.AccentA, THEME.AccentB), 45)
    local lbl = new("TextLabel", {
        Size = UDim2.new(1, -32, 1, 0), Position = UDim2.new(0, 30, 0, 0), BackgroundTransparency = 1,
        Font = THEME.FontFamily, TextSize = 13, RichText = true, Text = mdToRich(text or ""),
        TextColor3 = THEME.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })
    local obj = { _addons = {} }
    function obj:GetState() return state end
    function obj:SetValue(v, silent)
        state = v and true or false
        tween(fill, 0.15, nil, nil, {
            Size = state and UDim2.fromScale(1,1) or UDim2.fromScale(0,0),
        })
        if not silent and self.Callback then pcall(self.Callback, state) end
        for _, cb in ipairs(self._changed or {}) do pcall(cb, state) end
    end
    obj._changed = {}
    function obj:OnChanged(cb) table.insert(self._changed, cb); pcall(cb, state); return self end
    function obj:SetVisible(v) row.Visible = v end
    function obj:SetDisabled(d) box.Active = not d; lbl.TextTransparency = d and 0.5 or 0 end
    box.MouseButton1Click:Connect(function() obj:SetValue(not state) end)
    lbl.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then obj:SetValue(not state) end end)
    obj:SetValue(state, true)
    -- allow addons (keypicker/colorpicker chained)
    function obj:AddKeyPicker(id, kopts)
        local kp = Library._buildKeyPickerInline(row, kopts)
        if id then Library.Options[id] = kp end
        table.insert(self._addons, kp); return kp
    end
    function obj:AddColorPicker(id, copts)
        local cp = Library._buildColorPickerInline(row, copts)
        if id then Library.Options[id] = cp end
        table.insert(self._addons, cp); return cp
    end
    if opts.Callback then obj.Callback = opts.Callback end
    return obj
end

-- ----- SLIDER -----
local function buildSlider(parent, text, opts)
    opts = opts or {}
    local min, max = opts.Min or 0, opts.Max or 100
    local rounding = opts.Rounding or 0
    local value = math.clamp(opts.Default or min, min, max)
    local suffix = opts.Suffix or ""
    local wrap = new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = parent })
    local head = new("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Parent = wrap })
    local lbl = new("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 4, 0, 0), BackgroundTransparency = 1,
        Font = THEME.FontFamily, TextSize = 12, RichText = true, Text = mdToRich(text or ""),
        TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Parent = head,
    })
    local val = new("TextLabel", {
        Size = UDim2.new(0, 60, 1, 0), Position = UDim2.new(1, -60, 0, 0), BackgroundTransparency = 1,
        Font = THEME.FontFamilyMed, TextSize = 12, Text = "", TextColor3 = THEME.AccentB,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = head,
    })
    local track = new("Frame", {
        Size = UDim2.new(1, -8, 0, 6), Position = UDim2.new(0, 4, 0, 24),
        BackgroundColor3 = THEME.PanelAlt, BorderSizePixel = 0, Parent = wrap,
    })
    corner(track, 3)
    local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = THEME.AccentB, BorderSizePixel = 0, Parent = track })
    corner(fill, 3); gradient(fill, ColorSequence.new(THEME.AccentA, THEME.AccentB), 0)
    local grab = new("Frame", {
        Size = UDim2.fromOffset(12, 12), Position = UDim2.fromScale(0, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, Parent = track,
    })
    corner(grab, 6); stroke(grab, THEME.AccentB, 2)

    local obj = {}
    obj._changed = {}
    function obj:GetValue() return value end
    function obj:SetValue(v, silent)
        v = math.clamp(v, min, max)
        if rounding == 0 then v = math.floor(v + 0.5)
        else v = math.floor(v * 10^rounding + 0.5) / 10^rounding end
        value = v
        local p = (v - min) / math.max(1, (max - min))
        tween(fill, 0.1, nil, nil, { Size = UDim2.fromScale(p, 1) })
        tween(grab, 0.1, nil, nil, { Position = UDim2.new(p, 0, 0.5, 0) })
        val.Text = tostring(v) .. suffix
        if not silent and self.Callback then pcall(self.Callback, v) end
        for _, cb in ipairs(self._changed) do pcall(cb, v) end
    end
    function obj:OnChanged(cb) table.insert(self._changed, cb); pcall(cb, value); return self end
    function obj:SetVisible(v) wrap.Visible = v end
    function obj:SetDisabled(d) track.Active = not d end

    local dragging = false
    local function setFromMouse()
        local mp = UserInput:GetMouseLocation()
        local rel = (mp.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
        obj:SetValue(min + math.clamp(rel, 0, 1) * (max - min))
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; setFromMouse() end
    end)
    UserInput.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInput.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then setFromMouse() end
    end)
    obj:SetValue(value, true)
    if opts.Callback then obj.Callback = opts.Callback end
    return obj
end

-- ----- DROPDOWN -----
local function buildDropdown(parent, text, opts)
    opts = opts or {}
    local values = opts.Values or {}
    local multi = opts.Multi == true
    local value = multi and {} or (opts.Default or (values[1]))
    if multi and opts.Default then
        if type(opts.Default) == "table" then value = opts.Default
        else value = { [opts.Default] = true } end
    end
    local wrap = new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Parent = parent })
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Position = UDim2.new(0, 4, 0, 0),
        Font = THEME.FontFamily, TextSize = 12, Text = text or "", TextColor3 = THEME.TextDim,
        TextXAlignment = Enum.TextXAlignment.Left, RichText = true, Parent = wrap,
    })
    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, 16),
        BackgroundColor3 = THEME.PanelAlt, BorderSizePixel = 0, AutoButtonColor = false, Text = "",
        Parent = wrap,
    })
    corner(btn, 5); stroke(btn, THEME.StrokeSoft)
    local disp = new("TextLabel", {
        Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1,
        Font = THEME.FontFamily, TextSize = 12, Text = "", TextColor3 = THEME.Text,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = btn,
    })
    local arrow = new("TextLabel", {
        Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -22, 0.5, -10), BackgroundTransparency = 1,
        Font = THEME.FontFamilyBold, TextSize = 12, Text = "▾", TextColor3 = THEME.AccentB, Parent = btn,
    })

    local obj = {}; obj._changed = {}
    local function textFor()
        if multi then
            local list = {}
            for k, v in pairs(value) do if v then table.insert(list, k) end end
            table.sort(list)
            return (#list == 0) and "None" or table.concat(list, ", ")
        else
            return tostring(value or "None")
        end
    end
    function obj:GetValue() return value end
    function obj:SetValue(v, silent)
        if multi then
            if type(v) == "table" then value = v end
        else value = v end
        disp.Text = textFor()
        if not silent and self.Callback then pcall(self.Callback, value) end
        for _, cb in ipairs(self._changed) do pcall(cb, value) end
    end
    function obj:OnChanged(cb) table.insert(self._changed, cb); pcall(cb, value); return self end
    function obj:SetValues(vs) values = vs end
    function obj:SetVisible(v) wrap.Visible = v end
    function obj:SetDisabled(d) btn.Active = not d end
    obj:SetValue(value, true)

    local open = false
    local list
    local function toggle()
        if open then
            if list then tween(list, 0.15, nil, nil, { Size = UDim2.new(1, 0, 0, 0) }); task.delay(0.17, function() if list then list:Destroy() list = nil end end) end
            tween(arrow, 0.15, nil, nil, { Rotation = 0 })
            open = false; return
        end
        open = true
        tween(arrow, 0.15, nil, nil, { Rotation = 180 })
        list = new("Frame", {
            Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 1, 4),
            BackgroundColor3 = THEME.Panel, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 200, Parent = btn,
        })
        corner(list, 5); stroke(list, THEME.Stroke, 1, 0.2)
        local scroll = new("ScrollingFrame", {
            Size = UDim2.new(1, -4, 1, -4), Position = UDim2.fromOffset(2, 2),
            BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
            ScrollBarImageColor3 = THEME.AccentA, CanvasSize = UDim2.new(), ZIndex = 201,
            AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = list,
        })
        local ll = new("UIListLayout", { Padding = UDim.new(0, 2), Parent = scroll })
        for _, v in ipairs(values) do
            local isSel = multi and value[v] or value == v
            local it = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = isSel and THEME.PanelHi or THEME.PanelAlt,
                BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 202,
                Font = THEME.FontFamily, TextSize = 12, Text = "  " .. tostring(v),
                TextColor3 = isSel and THEME.AccentB or THEME.Text,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = scroll,
            })
            corner(it, 4)
            it.MouseEnter:Connect(function() if not isSel then tween(it, 0.12, nil, nil, { BackgroundColor3 = THEME.PanelHi }) end end)
            it.MouseLeave:Connect(function() if not isSel then tween(it, 0.12, nil, nil, { BackgroundColor3 = THEME.PanelAlt }) end end)
            it.MouseButton1Click:Connect(function()
                if multi then
                    local t = {}
                    for k, vv in pairs(value) do t[k] = vv end
                    t[v] = not t[v]
                    obj:SetValue(t)
                    -- refresh visual
                    toggle(); toggle()
                else
                    obj:SetValue(v); toggle()
                end
            end)
        end
        local h = math.min(180, math.max(24, #values * 24 + 4))
        tween(list, 0.18, nil, nil, { Size = UDim2.new(1, 0, 0, h) })
    end
    btn.MouseButton1Click:Connect(toggle)
    if opts.Callback then obj.Callback = opts.Callback end
    return obj
end

-- ----- BUTTON -----
local function buildButton(parent, text, opts)
    opts = opts or {}
    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = THEME.PanelHi, BorderSizePixel = 0,
        AutoButtonColor = false, Font = THEME.FontFamilyMed, TextSize = 13, Text = text or "Button",
        TextColor3 = THEME.Text, Parent = parent,
    })
    corner(btn, 5); stroke(btn, THEME.Stroke, 1, 0.3)
    local grad = gradient(btn, ColorSequence.new(THEME.AccentC, THEME.AccentA), 45)
    grad.Transparency = NumberSequence.new(0.7)
    btn.MouseEnter:Connect(function() tween(btn, 0.15, nil, nil, { BackgroundColor3 = THEME.AccentA }) end)
    btn.MouseLeave:Connect(function() tween(btn, 0.15, nil, nil, { BackgroundColor3 = THEME.PanelHi }) end)
    local obj = { Instance = btn }
    function obj:OnClick(cb) btn.MouseButton1Click:Connect(function() pcall(cb) end); return self end
    function obj:AddButton(t2, cb2)
        btn.Size = UDim2.new(0.5, -3, 0, 28)
        local b2 = buildButton(parent, t2, {})
        b2.Instance.Size = UDim2.new(0.5, -3, 0, 28)
        b2.Instance.Position = UDim2.new(0.5, 3, 0, 0)
        b2:OnClick(cb2)
        return b2
    end
    function obj:SetText(t) btn.Text = t end
    function obj:SetVisible(v) btn.Visible = v end
    function obj:SetDisabled(d) btn.Active = not d; btn.TextTransparency = d and 0.4 or 0 end
    if opts.Func then obj:OnClick(opts.Func) end
    return obj
end

-- ----- LABEL -----
local function buildLabel(parent, text, maybeOpts)
    local wrap = maybeOpts == true or (type(maybeOpts) == "table" and maybeOpts.DoesWrap)
    local lbl = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, wrap and 40 or 18), BackgroundTransparency = 1,
        Font = THEME.FontFamily, TextSize = 12, RichText = true, Text = mdToRich(text or ""),
        TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = wrap or false, AutomaticSize = wrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
        Parent = parent,
    })
    local obj = { Instance = lbl }
    function obj:SetText(t) lbl.Text = mdToRich(t) end
    function obj:SetVisible(v) lbl.Visible = v end
    return obj
end

-- ----- DIVIDER -----
local function buildDivider(parent)
    local d = new("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = THEME.StrokeSoft, BorderSizePixel = 0, Parent = parent })
    return { Instance = d, SetVisible = function(_, v) d.Visible = v end }
end

-- ----- INPUT -----
local function buildInput(parent, text, opts)
    opts = opts or {}
    local wrap = new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Parent = parent })
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Position = UDim2.new(0, 4, 0, 0),
        Font = THEME.FontFamily, TextSize = 12, Text = text or "", TextColor3 = THEME.TextDim,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = wrap,
    })
    local tb = new("TextBox", {
        Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, 16),
        BackgroundColor3 = THEME.PanelAlt, BorderSizePixel = 0, Font = THEME.FontFamily, TextSize = 12,
        Text = opts.Default or "", PlaceholderText = opts.Placeholder or "", TextColor3 = THEME.Text,
        PlaceholderColor3 = THEME.TextMuted, ClearTextOnFocus = false,
        Parent = wrap,
    })
    corner(tb, 5); stroke(tb, THEME.StrokeSoft); pad(tb, 8, 8, 0, 0)
    local obj = {}; obj._changed = {}
    function obj:GetValue() return tb.Text end
    function obj:SetValue(v, silent) tb.Text = tostring(v or "")
        if not silent and self.Callback then pcall(self.Callback, tb.Text) end
        for _, cb in ipairs(self._changed) do pcall(cb, tb.Text) end
    end
    function obj:OnChanged(cb) table.insert(self._changed, cb); return self end
    function obj:SetVisible(v) wrap.Visible = v end
    function obj:SetDisabled(d) tb.TextEditable = not d end
    tb.FocusLost:Connect(function() obj:SetValue(tb.Text) end)
    if opts.Callback then obj.Callback = opts.Callback end
    return obj
end

-- ----- KEYPICKER (inline, appears at right side of a toggle row) -----
function Library._buildKeyPickerInline(row, opts)
    opts = opts or {}
    local key = opts.Default or "None"
    local mode = opts.Mode or "Toggle"
    local text = opts.Text
    local btn = new("TextButton", {
        Size = UDim2.fromOffset(60, 18), Position = UDim2.new(1, -66, 0.5, -9),
        BackgroundColor3 = THEME.PanelAlt, BorderSizePixel = 0, AutoButtonColor = false,
        Font = THEME.FontFamily, TextSize = 11, Text = "[" .. tostring(key) .. "]",
        TextColor3 = THEME.AccentB, Parent = row,
    })
    corner(btn, 4); stroke(btn, THEME.StrokeSoft)
    local obj = { _changed = {}, _clicks = {} }
    local state = false
    local listening = false
    function obj:GetState() return state end
    function obj:GetKey() return key end
    function obj:GetMode() return mode end
    function obj:SetValue(v)
        if type(v) == "table" then key = v[1] or key; mode = v[2] or mode
        else key = v end
        btn.Text = "[" .. tostring(key) .. "]"
        for _, cb in ipairs(self._changed) do pcall(cb, key, mode) end
    end
    function obj:OnChanged(cb) table.insert(self._changed, cb); return self end
    function obj:OnClick(cb) table.insert(self._clicks, cb); return self end
    function obj:SetVisible(v) btn.Visible = v end

    btn.MouseButton1Click:Connect(function()
        listening = true; btn.Text = "[...]"
    end)
    btn.MouseButton2Click:Connect(function()
        openModePopup(btn, mode, function(m)
            mode = m
            for _, cb in ipairs(obj._changed) do pcall(cb, key, mode) end
        end)
    end)
    UserInput.InputBegan:Connect(function(i, gp)
        if listening and (i.UserInputType == Enum.UserInputType.Keyboard or
                          i.UserInputType == Enum.UserInputType.MouseButton1 or
                          i.UserInputType == Enum.UserInputType.MouseButton2 or
                          i.UserInputType == Enum.UserInputType.MouseButton3) then
            local nm
            if i.UserInputType == Enum.UserInputType.Keyboard then nm = i.KeyCode.Name
            else nm = i.UserInputType.Name end
            if nm == "Escape" then nm = "None" end
            listening = false; obj:SetValue(nm); return
        end
        if gp then return end
        local match = (i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode.Name == key)
            or (i.UserInputType.Name == key)
        if match then
            if mode == "Toggle" then state = not state
            elseif mode == "Hold" then state = true
            elseif mode == "Always" then state = true end
            for _, cb in ipairs(obj._clicks) do pcall(cb) end
            for _, cb in ipairs(obj._changed) do pcall(cb, key, mode) end
        end
    end)
    UserInput.InputEnded:Connect(function(i)
        local match = (i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode.Name == key)
            or (i.UserInputType.Name == key)
        if match and mode == "Hold" then state = false end
    end)
    if mode == "Always" then state = true end
    if opts.Text then
        -- optional right label
    end
    return obj
end

-- ----- COLORPICKER (inline) -----
function Library._buildColorPickerInline(row, opts)
    opts = opts or {}
    local color = opts.Default or Color3.fromRGB(255, 255, 255)
    local trans = opts.Transparency or 0
    local transparencyEnabled = opts.Transparency ~= nil
    local h, s, v = Color3.toHSV(color)
    local a = 1 - trans
    local swatch = new("TextButton", {
        Size = UDim2.fromOffset(28, 16), Position = UDim2.new(1, -34, 0.5, -8),
        BackgroundColor3 = color, BorderSizePixel = 0, AutoButtonColor = false, Text = "",
        Parent = row,
    })
    corner(swatch, 4); stroke(swatch, THEME.StrokeSoft)
    local obj = { _changed = {} }
    function obj:GetColor() return color end
    function obj:GetValue() return color end
    function obj:GetValueRGB() return color end
    function obj:GetTransparency() return trans end
    function obj:SetValueRGB(c, t)
        color = c; if t ~= nil then trans = t end
        swatch.BackgroundColor3 = color
        h, s, v = Color3.toHSV(color); a = 1 - trans
        for _, cb in ipairs(self._changed) do pcall(cb, color, trans) end
        if self.Callback then pcall(self.Callback, color, trans) end
    end
    obj.SetValue = obj.SetValueRGB
    function obj:OnChanged(cb) table.insert(self._changed, cb); return self end
    function obj:SetVisible(v) swatch.Visible = v end
    swatch.MouseButton1Click:Connect(function()
        openColorPopup(swatch, h, s, v, a, transparencyEnabled, function(c, t, nh, ns, nv)
            h, s, v = nh, ns, nv; a = 1 - t
            color = c; trans = t
            swatch.BackgroundColor3 = c
            for _, cb in ipairs(obj._changed) do pcall(cb, c, t) end
            if obj.Callback then pcall(obj.Callback, c, t) end
        end)
    end)
    if opts.Callback then obj.Callback = opts.Callback end
    return obj
end

-- ============================================================================
-- GROUPBOX FACTORY
-- ============================================================================
local function makeGroupbox(container, title)
    local box = new("Frame", {
        Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = THEME.Panel,
        BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.Y, Parent = container,
    })
    corner(box, 6); stroke(box, THEME.StrokeSoft, 1, 0.3)
    local head = new("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Parent = box })
    new("TextLabel", {
        Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1,
        Font = THEME.FontFamilyBold, TextSize = 12, Text = string.upper(title or ""),
        TextColor3 = THEME.AccentB, TextXAlignment = Enum.TextXAlignment.Left, Parent = head,
    })
    local line = new("Frame", { Size = UDim2.new(1, -20, 0, 1), Position = UDim2.new(0, 10, 1, -1),
        BackgroundColor3 = THEME.StrokeSoft, BorderSizePixel = 0, Parent = head })
    local body = new("Frame", {
        Size = UDim2.new(1, -20, 0, 0), Position = UDim2.new(0, 10, 0, 30),
        BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Parent = box,
    })
    new("UIListLayout", { Padding = UDim.new(0, 6), Parent = body, SortOrder = Enum.SortOrder.LayoutOrder })
    pad(body, 0, 0, 0, 10)

    local gb = {}
    function gb:AddToggle(id, o) o = o or {}; return registerToggle(id, buildToggle(body, o.Text, o)) end
    function gb:AddSlider(id, o) o = o or {}; return registerOption(id, buildSlider(body, o.Text, o)) end
    function gb:AddDropdown(id, o) o = o or {}; return registerOption(id, buildDropdown(body, o.Text, o)) end
    function gb:AddButton(o) if type(o) == "string" then return buildButton(body, o) end
        return buildButton(body, o.Text, o) end
    function gb:AddLabel(t, w) return buildLabel(body, t, w) end
    function gb:AddDivider() return buildDivider(body) end
    function gb:AddInput(id, o) o = o or {}; return registerOption(id, buildInput(body, o.Text, o)) end
    function gb:AddDependencyBox()
        local sub = new("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y, Parent = body })
        new("UIListLayout", { Padding = UDim.new(0, 6), Parent = sub })
        local dep = {}
        for k, v in pairs(gb) do dep[k] = function(_, ...) return v(gb, ...) end end
        dep.SetupDependencies = function() end
        return dep
    end
    return gb
end

-- ============================================================================
-- WINDOW
-- ============================================================================
function Library:CreateWindow(cfg)
    cfg = cfg or {}
    local title = cfg.Title or "Eclipse"
    local sub = cfg.Subtitle or ""
    local w, h = cfg.Size and cfg.Size.X or 780, cfg.Size and cfg.Size.Y or 520

    -- splash
    local splash = createSplash()
    task.delay(0.6, function() if splash then splash.Close() end end)

    local root = new("Frame", {
        Size = UDim2.fromOffset(w, h), Position = UDim2.new(0.5, -w/2, 0.5, -h/2),
        BackgroundColor3 = THEME.Background, BorderSizePixel = 0, Parent = ROOT_GUI,
        ClipsDescendants = true,
    })
    corner(root, 10); stroke(root, THEME.Stroke, 1, 0.3)

    -- top bar
    local top = new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = THEME.BackgroundAlt,
        BorderSizePixel = 0, Parent = root })
    corner(top, 10)
    new("Frame", { Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = THEME.BackgroundAlt, BorderSizePixel = 0, Parent = top }) -- kill bottom radius
    local topLine = new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, 0),
        BorderSizePixel = 0, Parent = top })
    gradient(topLine, ColorSequence.new(THEME.AccentA, THEME.AccentB), 0)

    local logo = new("ImageLabel", { Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(12, 8),
        BackgroundTransparency = 1, Image = LOGO_URL_ALT, Parent = top })
    corner(logo, 5)
    new("TextLabel", { Size = UDim2.new(0, 200, 0, 18), Position = UDim2.fromOffset(44, 6),
        BackgroundTransparency = 1, Font = THEME.FontFamilyBold, TextSize = 13, Text = title,
        TextColor3 = THEME.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = top })
    new("TextLabel", { Size = UDim2.new(0, 220, 0, 14), Position = UDim2.fromOffset(44, 22),
        BackgroundTransparency = 1, Font = THEME.FontFamily, TextSize = 11, Text = sub,
        TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Parent = top })

    -- drag
    do
        local dragging, ds, sp
        top.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; ds = i.Position; sp = root.Position
            end
        end)
        UserInput.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                local d = i.Position - ds
                root.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end)
        UserInput.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
    end

    -- sidebar
    local side = new("Frame", { Size = UDim2.new(0, 130, 1, -40), Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = THEME.BackgroundAlt, BorderSizePixel = 0, Parent = root })
    new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = side })
    pad(side, 8, 8, 12, 8)

    -- content area
    local content = new("Frame", { Size = UDim2.new(1, -130, 1, -40), Position = UDim2.new(0, 130, 0, 40),
        BackgroundTransparency = 1, ClipsDescendants = true, Parent = root })

    local tabs = {}
    local activeTab

    -- resize handle (obsidian-style: two diagonal ticks)
    local rez = new("TextButton", { Size = UDim2.fromOffset(16, 16), Position = UDim2.new(1, -16, 1, -16),
        BackgroundTransparency = 1, AutoButtonColor = false, Text = "", ZIndex = 50, Parent = root })
    local function _rezBar(off, len)
        local b = new("Frame", { Size = UDim2.fromOffset(len, 2), BackgroundColor3 = THEME.AccentB,
            BorderSizePixel = 0, Position = UDim2.fromOffset(16 - off - len, 16 - off - 1), Parent = rez })
        b.Rotation = -45; corner(b, 1)
    end
    _rezBar(2, 12); _rezBar(6, 7)

    do
        local rd, rs, rsz
        rez.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                rd = true; rs = i.Position; rsz = root.AbsoluteSize
            end
        end)
        UserInput.InputChanged:Connect(function(i)
            if rd and i.UserInputType == Enum.UserInputType.MouseMovement then
                local d = i.Position - rs
                local nw = math.clamp(rsz.X + d.X, Library.MinSize.X, Library.MaxSize.X)
                local nh = math.clamp(rsz.Y + d.Y, Library.MinSize.Y, Library.MaxSize.Y)
                root.Size = UDim2.fromOffset(nw, nh)
            end
        end)
        UserInput.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then rd = false end end)
    end

    local win = { Root = root, Tabs = tabs, ScreenGui = ROOT_GUI }

    function win:AddTab(name)
        local tabBtn = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = THEME.BackgroundAlt,
            BorderSizePixel = 0, AutoButtonColor = false, Font = THEME.FontFamilyMed, TextSize = 12,
            Text = name, TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Parent = side,
        })
        pad(tabBtn, 12, 6, 0, 0); corner(tabBtn, 5)
        local ind = new("Frame", { Size = UDim2.new(0, 3, 0, 0), Position = UDim2.new(0, 2, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5), BorderSizePixel = 0, Parent = tabBtn })
        corner(ind, 2); gradient(ind, ColorSequence.new(THEME.AccentA, THEME.AccentB), 90)

        local page = new("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 3, ScrollBarImageColor3 = THEME.AccentA,
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = content, Visible = false,
        })
        pad(page, 12, 12, 12, 12)
        local cols = new("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y, Parent = page })
        local left = new("Frame", { Size = UDim2.new(0.5, -6, 0, 0), BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y, Parent = cols })
        local right = new("Frame", { Size = UDim2.new(0.5, -6, 0, 0), Position = UDim2.new(0.5, 6, 0, 0),
            BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Parent = cols })
        new("UIListLayout", { Padding = UDim.new(0, 10), Parent = left, SortOrder = Enum.SortOrder.LayoutOrder })
        new("UIListLayout", { Padding = UDim.new(0, 10), Parent = right, SortOrder = Enum.SortOrder.LayoutOrder })

        local tab = { Name = name, Btn = tabBtn, Page = page }
        function tab:AddLeftGroupbox(title) return makeGroupbox(left, title) end
        function tab:AddRightGroupbox(title) return makeGroupbox(right, title) end
        function tab:AddLeftTabbox() return { AddTab = function(_, n) return tab:AddLeftGroupbox(n) end } end
        function tab:AddRightTabbox() return { AddTab = function(_, n) return tab:AddRightGroupbox(n) end } end

        tabBtn.MouseButton1Click:Connect(function() win:SelectTab(tab) end)
        tabBtn.MouseEnter:Connect(function()
            if activeTab ~= tab then tween(tabBtn, 0.15, nil, nil, { BackgroundColor3 = THEME.Panel }) end
        end)
        tabBtn.MouseLeave:Connect(function()
            if activeTab ~= tab then tween(tabBtn, 0.15, nil, nil, { BackgroundColor3 = THEME.BackgroundAlt }) end
        end)

        table.insert(tabs, tab)
        if #tabs == 1 then win:SelectTab(tab) end
        return tab
    end

    function win:SelectTab(tab)
        if activeTab == tab then return end
        if activeTab then
            activeTab.Page.Visible = false
            tween(activeTab.Btn, 0.15, nil, nil, { BackgroundColor3 = THEME.BackgroundAlt, TextColor3 = THEME.TextDim })
            local oldInd = activeTab.Btn:FindFirstChildOfClass("Frame")
            if oldInd then tween(oldInd, 0.15, nil, nil, { Size = UDim2.new(0, 3, 0, 0) }) end
        end
        activeTab = tab
        tab.Page.Visible = true
        tween(tab.Btn, 0.15, nil, nil, { BackgroundColor3 = THEME.Panel, TextColor3 = THEME.Text })
        local ind = tab.Btn:FindFirstChildOfClass("Frame")
        if ind then tween(ind, 0.2, nil, nil, { Size = UDim2.new(0, 3, 0, 20) }) end
        -- content slide-in animation
        tab.Page.Position = UDim2.new(0, 0, 0, 12)
        tab.Page.CanvasPosition = Vector2.new(0, 0)
        for _, d in ipairs(tab.Page:GetDescendants()) do
            if d:IsA("Frame") and d.BackgroundTransparency < 1 then
                local orig = d.BackgroundTransparency
                d.BackgroundTransparency = 1
                tween(d, 0.35, nil, nil, { BackgroundTransparency = orig })
            end
        end
        tween(tab.Page, 0.25, Enum.EasingStyle.Quart, nil, { Position = UDim2.fromScale(0, 0) })
    end

    function win:Unload() Library:Unload() end
    function win:OnUnload(cb) table.insert(Library._Unloads, cb) end

    return win
end

-- ============================================================================
-- CONFIG MANAGER
-- ============================================================================
Library.ConfigManager = {}
local CONFIG_FOLDER = "EclipseConfigs"
local function ensureFolder()
    if not isfolder or not makefolder then return end
    if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
end
ensureFolder()

function Library.ConfigManager:List()
    local list = {}
    if listfiles and isfolder and isfolder(CONFIG_FOLDER) then
        for _, f in ipairs(listfiles(CONFIG_FOLDER)) do
            local n = f:match("([^/\\]+)%.json$")
            if n then table.insert(list, n) end
        end
    end
    return list
end

local function serialize()
    local data = { toggles = {}, options = {} }
    for id, t in pairs(Library.Toggles) do
        data.toggles[id] = { value = t:GetState() }
    end
    for id, o in pairs(Library.Options) do
        local ok, val
        if o.GetValue then ok, val = pcall(o.GetValue, o)
        elseif o.GetColor then ok, val = pcall(function() return { color = { o:GetColor().R, o:GetColor().G, o:GetColor().B }, t = o:GetTransparency() } end)
        elseif o.GetKey then ok, val = pcall(function() return { o:GetKey(), o:GetMode() } end)
        end
        if ok then data.options[id] = val end
    end
    return HttpService:JSONEncode(data)
end

local function deserialize(str)
    local ok, data = pcall(HttpService.JSONDecode, HttpService, str)
    if not ok or type(data) ~= "table" then return end
    for id, t in pairs(data.toggles or {}) do
        if Library.Toggles[id] then pcall(function() Library.Toggles[id]:SetValue(t.value) end) end
    end
    for id, v in pairs(data.options or {}) do
        local o = Library.Options[id]
        if o then
            if type(v) == "table" and v.color then
                pcall(function() o:SetValueRGB(Color3.new(v.color[1], v.color[2], v.color[3]), v.t or 0) end)
            elseif o.SetValue then pcall(function() o:SetValue(v) end)
            end
        end
    end
end

function Library.ConfigManager:Save(name)
    if not writefile then return false, "No file API" end
    ensureFolder(); writefile(CONFIG_FOLDER .. "/" .. name .. ".json", serialize())
    return true
end
function Library.ConfigManager:Load(name)
    if not readfile then return false end
    local ok, s = pcall(readfile, CONFIG_FOLDER .. "/" .. name .. ".json")
    if not ok then return false end
    deserialize(s); return true
end
function Library.ConfigManager:Delete(name)
    if delfile then pcall(delfile, CONFIG_FOLDER .. "/" .. name .. ".json"); return true end
end
function Library.ConfigManager:SetAutoload(name)
    if writefile then writefile(CONFIG_FOLDER .. "/_autoload.txt", name or "") end
end
function Library.ConfigManager:GetAutoload()
    if readfile and isfile and isfile(CONFIG_FOLDER .. "/_autoload.txt") then
        return readfile(CONFIG_FOLDER .. "/_autoload.txt")
    end
end
function Library.ConfigManager:Autoload()
    local n = self:GetAutoload()
    if n and n ~= "" then task.wait(0.4); pcall(function() self:Load(n) end) end
end

-- Convenience: build a Config UI into an existing groupbox
function Library:BuildConfigUI(groupbox)
    local nameInput = groupbox:AddInput("cfg_name", { Text = "Config Name", Default = "" })
    local dropdown  = groupbox:AddDropdown("cfg_list", { Text = "Saved Configs", Values = Library.ConfigManager:List() })
    local function refresh() dropdown:SetValues(Library.ConfigManager:List()) end
    groupbox:AddButton({ Text = "Save", Func = function()
        local n = nameInput:GetValue(); if n == "" then Library:Notify({ Title = "Config", Description = "Name required" }); return end
        Library.ConfigManager:Save(n); refresh(); Library:Notify({ Title = "Config", Description = "Saved **" .. n .. "**" })
    end })
    groupbox:AddButton({ Text = "Load", Func = function()
        local n = dropdown:GetValue(); if not n then return end
        Library.ConfigManager:Load(n); Library:Notify({ Title = "Config", Description = "Loaded **" .. n .. "**" })
    end })
    groupbox:AddButton({ Text = "Delete", Func = function()
        local n = dropdown:GetValue(); if not n then return end
        Library.ConfigManager:Delete(n); refresh(); Library:Notify({ Title = "Config", Description = "Deleted " .. n })
    end })
    groupbox:AddButton({ Text = "Set Autoload", Func = function()
        local n = dropdown:GetValue(); if not n then return end
        Library.ConfigManager:SetAutoload(n); Library:Notify({ Title = "Config", Description = "Autoload = " .. n })
    end })
    groupbox:AddButton({ Text = "Refresh", Func = refresh })
end

-- ============================================================================
-- UNLOAD
-- ============================================================================
function Library:Unload()
    Library.Unloaded = true
    for _, fn in ipairs(Library._Unloads) do pcall(fn) end
    Library._Unloads = {}
    pcall(function() ROOT_GUI:Destroy() end)
    if CursorGui then pcall(function() CursorGui:Destroy() end) end
end
function Library:OnUnload(cb) table.insert(Library._Unloads, cb) end

-- ============================================================================
-- IMAGE LOADER (Obsidian-style helper)
-- ============================================================================
Library.Assets = {}
function Library:GetImage(url)
    if self.Assets[url] then return self.Assets[url] end
    local id = url
    if url:match("^https?://") and getcustomasset and writefile then
        local ok, data = pcall(function() return game:HttpGet(url) end)
        if ok then
            local path = "EclipseAssets_" .. HttpService:GenerateGUID(false):sub(1, 8) .. ".png"
            pcall(writefile, path, data)
            local ok2, asset = pcall(getcustomasset, path)
            if ok2 then id = asset end
        end
    end
    self.Assets[url] = id
    return id
end

return Library
