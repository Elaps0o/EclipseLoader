-- ============================================================================
-- Eclipse UI Library v0.1 (Phase 1)
-- Custom UI to replace Obsidian. API-compatible surface for eclipse.lua.
-- Phase 1 covers: Window shell, Tabs, Groupboxes, Toggle, Slider, Dropdown,
-- Button, Label, Divider, Notify, splash w/ logo, resize handle.
-- Phase 2 will implement real ColorPicker / KeyPicker / Input.
-- Phase 3 will migrate eclipse.lua & polish.
-- ============================================================================

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UserInput     = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local CoreGui       = game:GetService("CoreGui")
local HttpService   = game:GetService("HttpService")

local LP = Players.LocalPlayer

-- ============================================================================
-- THEME
-- ============================================================================
local THEME = {
    Background      = Color3.fromRGB(18, 18, 22),
    Panel           = Color3.fromRGB(24, 24, 30),
    PanelAlt        = Color3.fromRGB(30, 30, 38),
    Stroke          = Color3.fromRGB(45, 45, 55),
    StrokeSoft      = Color3.fromRGB(38, 38, 46),
    Text            = Color3.fromRGB(230, 230, 235),
    TextDim         = Color3.fromRGB(150, 150, 160),
    TextMuted       = Color3.fromRGB(105, 105, 115),
    AccentA         = Color3.fromRGB(124, 58, 237),   -- purple
    AccentB         = Color3.fromRGB(168, 85, 247),   -- lighter purple
    Danger          = Color3.fromRGB(239, 68, 68),
    Success         = Color3.fromRGB(34, 197, 94),
    FontFamily      = Enum.Font.Gotham,
    FontFamilyBold  = Enum.Font.GothamBold,
    FontFamilyMed   = Enum.Font.GothamMedium,
}

local LOGO_URL = "https://raw.githubusercontent.com/Elaps0o/EclipseLoader/main/ChatGPT%20Image%20Jul%2012%2C%202026%2C%2001_21_51%20AM.png"

-- ============================================================================
-- CORE
-- ============================================================================
local Library = {}
Library.__index = Library

Library.Options   = {}
Library.Toggles   = {}
Library.Tabs      = {}
Library.Unloaded  = false
Library.Signals   = {}
Library._Unloads  = {}
Library.MinSize   = Vector2.new(700, 460)
Library.MaxSize   = Vector2.new(1400, 900)
Library.Theme     = THEME
Library.NotifySide = "Right"

-- ------------------------- helpers -------------------------
local function new(class, props, children)
    local o = Instance.new(class)
    if props then
        for k, v in pairs(props) do o[k] = v end
    end
    if children then
        for _, c in ipairs(children) do c.Parent = o end
    end
    return o
end

local function corner(inst, r)
    local c = new("UICorner", { CornerRadius = UDim.new(0, r or 6), Parent = inst })
    return c
end

local function stroke(inst, color, thickness, transparency)
    local s = new("UIStroke", {
        Color            = color or THEME.Stroke,
        Thickness        = thickness or 1,
        Transparency     = transparency or 0,
        ApplyStrokeMode  = Enum.ApplyStrokeMode.Border,
        Parent           = inst,
    })
    return s
end

local function padding(inst, top, right, bottom, left)
    local p = new("UIPadding", {
        PaddingTop    = UDim.new(0, top or 0),
        PaddingRight  = UDim.new(0, right or top or 0),
        PaddingBottom = UDim.new(0, bottom or top or 0),
        PaddingLeft   = UDim.new(0, left or right or top or 0),
        Parent        = inst,
    })
    return p
end

local function tween(inst, t, style, dir, props)
    local tw = TweenService:Create(inst, TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function safeParent(gui)
    local ok = pcall(function() gui.Parent = CoreGui end)
    if not ok then
        gui.Parent = LP:WaitForChild("PlayerGui")
    end
end

local function gradient(inst, c1, c2, rotation)
    local g = new("UIGradient", {
        Color    = ColorSequence.new(c1 or THEME.AccentA, c2 or THEME.AccentB),
        Rotation = rotation or 0,
        Parent   = inst,
    })
    return g
end

local function purpleGradient(inst, rot)
    return gradient(inst, THEME.AccentA, THEME.AccentB, rot or 90)
end

-- signal helper
local function signal()
    local s = { _cbs = {} }
    function s:Connect(fn) table.insert(self._cbs, fn); return { Disconnect = function() end } end
    function s:Fire(...) for _, c in ipairs(self._cbs) do task.spawn(c, ...) end end
    return s
end

-- ============================================================================
-- SPLASH (logo load)
-- ============================================================================
local function createSplash()
    local gui = new("ScreenGui", {
        Name = "EclipseUISplash",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 9999,
    })
    safeParent(gui)

    local dim = new("Frame", {
        BackgroundColor3 = Color3.fromRGB(0,0,0),
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1,1),
        Parent = gui,
    })
    tween(dim, 0.25, nil, nil, { BackgroundTransparency = 0.55 })

    local card = new("Frame", {
        BackgroundColor3 = THEME.Panel,
        Size = UDim2.fromOffset(340, 380),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Parent = dim,
    })
    corner(card, 14)
    stroke(card, THEME.Stroke, 1)

    local logo = new("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(220, 220),
        Position = UDim2.new(0.5, 0, 0, 30),
        AnchorPoint = Vector2.new(0.5, 0),
        Image = LOGO_URL,
        ScaleType = Enum.ScaleType.Fit,
        ImageTransparency = 1,
        Parent = card,
    })
    corner(logo, 12)
    tween(logo, 0.4, nil, nil, { ImageTransparency = 0 })

    local title = new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 22),
        Position = UDim2.new(0, 10, 0, 260),
        Font = THEME.FontFamilyBold,
        Text = "ECLIPSE HUB",
        TextColor3 = THEME.Text,
        TextSize = 18,
        Parent = card,
    })

    local sub = new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 16),
        Position = UDim2.new(0, 10, 0, 284),
        Font = THEME.FontFamily,
        Text = "Loading...",
        TextColor3 = THEME.TextDim,
        TextSize = 13,
        Parent = card,
    })

    -- progress bar
    local barBg = new("Frame", {
        BackgroundColor3 = THEME.PanelAlt,
        Size = UDim2.new(1, -40, 0, 4),
        Position = UDim2.new(0, 20, 1, -32),
        Parent = card,
    })
    corner(barBg, 4)
    local bar = new("Frame", {
        BackgroundColor3 = THEME.AccentA,
        Size = UDim2.fromScale(0, 1),
        Parent = barBg,
    })
    corner(bar, 4)
    purpleGradient(bar, 0)

    -- animate bar
    task.spawn(function()
        for i = 0, 100, 5 do
            if not bar.Parent then return end
            bar.Size = UDim2.new(i/100, 0, 1, 0)
            task.wait(0.03)
        end
    end)

    local function close()
        if not gui.Parent then return end
        tween(dim, 0.3, nil, nil, { BackgroundTransparency = 1 })
        tween(card, 0.3, nil, nil, { Size = UDim2.fromOffset(340, 300) })
        tween(logo, 0.25, nil, nil, { ImageTransparency = 1 })
        task.wait(0.35)
        gui:Destroy()
    end

    return { Gui = gui, Sub = sub, Close = close }
end

-- ============================================================================
-- MARKDOWN -> RICHTEXT
-- ============================================================================
local function mdToRich(s)
    s = tostring(s or "")
    s = s:gsub("%*%*(.-)%*%*", "<b>%1</b>")
    s = s:gsub("__(.-)__",     "<b>%1</b>")
    s = s:gsub("%*(.-)%*",     "<i>%1</i>")
    s = s:gsub("_(.-)_",       "<i>%1</i>")
    s = s:gsub("~~(.-)~~",     "<s>%1</s>")
    s = s:gsub("`([^`]+)`",    '<font face="RobotoMono"><b>%1</b></font>')
    s = s:gsub("%[([^%]]+)%]%(([^%)]+)%)", "<u>%1</u>")
    return s
end
Library._mdToRich = mdToRich

-- ============================================================================
-- NOTIFICATIONS
-- ============================================================================
local NotifyRoot
local function ensureNotifyRoot()
    if NotifyRoot and NotifyRoot.Parent then return NotifyRoot end
    NotifyRoot = new("ScreenGui", {
        Name = "EclipseUINotify",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 9998,
    })
    safeParent(NotifyRoot)

    local holder = new("Frame", {
        Name = "Holder",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -20, 1, -20),
        Size = UDim2.fromOffset(320, 600),
        Parent = NotifyRoot,
    })
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = holder,
    })
    return NotifyRoot
end

function Library:Notify(a, b)
    local title, desc, time
    if typeof(a) == "table" then
        title = a.Title or "Eclipse"
        desc  = a.Description or a.Content or ""
        time  = a.Time or 5
    else
        title = "Eclipse"
        desc  = tostring(a or "")
        time  = tonumber(b) or 5
    end

    ensureNotifyRoot()
    local holder = NotifyRoot:FindFirstChild("Holder")

    local card = new("Frame", {
        BackgroundColor3 = THEME.Panel,
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundTransparency = 1,
        Parent = holder,
    })
    corner(card, 8)
    stroke(card, THEME.Stroke, 1)

    -- side bar (gradient)
    local side = new("Frame", {
        BackgroundColor3 = THEME.AccentA,
        Size = UDim2.new(0, 3, 1, -12),
        Position = UDim2.new(0, 8, 0, 6),
        BackgroundTransparency = 1,
        Parent = card,
    })
    corner(side, 2)
    purpleGradient(side, 90)

    local titleLbl = new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 8),
        Size = UDim2.new(1, -28, 0, 18),
        Font = THEME.FontFamilyBold,
        RichText = true,
        Text = mdToRich(title),
        TextColor3 = THEME.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1,
        Parent = card,
    })

    local descLbl = new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 28),
        Size = UDim2.new(1, -28, 0, 30),
        Font = THEME.FontFamily,
        RichText = true,
        Text = mdToRich(desc),
        TextColor3 = THEME.TextDim,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        TextTransparency = 1,
        Parent = card,
    })


    -- progress line (bottom)
    local prog = new("Frame", {
        BackgroundColor3 = THEME.AccentB,
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BorderSizePixel = 0,
        Parent = card,
    })
    purpleGradient(prog, 0)

    -- fade in
    tween(card, 0.2, nil, nil, { BackgroundTransparency = 0 })
    tween(side, 0.2, nil, nil, { BackgroundTransparency = 0 })
    tween(titleLbl, 0.25, nil, nil, { TextTransparency = 0 })
    tween(descLbl, 0.25, nil, nil, { TextTransparency = 0 })
    tween(prog, math.max(0.1, time), Enum.EasingStyle.Linear, nil, { Size = UDim2.new(0, 0, 0, 2) })

    task.delay(time, function()
        tween(card, 0.25, nil, nil, { BackgroundTransparency = 1 })
        tween(side, 0.25, nil, nil, { BackgroundTransparency = 1 })
        tween(titleLbl, 0.25, nil, nil, { TextTransparency = 1 })
        tween(descLbl, 0.25, nil, nil, { TextTransparency = 1 })
        task.wait(0.3)
        card:Destroy()
    end)

    return card
end

-- ============================================================================
-- STUB CONTROL (safe no-op for phase 1) — used by ColorPicker/KeyPicker/Input
-- Returns a chainable table with the methods eclipse.lua expects so nothing crashes.
-- ============================================================================
local function makeStubControl(kind, default)
    local ctrl = {
        Value      = default,
        Type       = kind,
        Changed    = signal(),
        Callbacks  = {},
    }
    function ctrl:OnChanged(fn) table.insert(self.Callbacks, fn); return self end
    function ctrl:SetValue(v) self.Value = v; for _, cb in ipairs(self.Callbacks) do pcall(cb, v) end; return self end
    function ctrl:SetValueRGB(c) self.Value = c; return self end
    function ctrl:GetState() return self.Value == true end
    function ctrl:SetText(t) self.Text = t; return self end
    function ctrl:AddColorPicker(idx, opts)
        opts = opts or {}
        local cp = makeStubControl("ColorPicker", opts.Default or Color3.new(1,1,1))
        Library.Options[idx] = cp
        return cp
    end
    function ctrl:AddKeyPicker(idx, opts)
        opts = opts or {}
        local kp = makeStubControl("KeyPicker", opts.Default or "None")
        Library.Options[idx] = kp
        return kp
    end
    return ctrl
end

-- ============================================================================
-- CONTROLS
-- ============================================================================
local function buildToggle(gb, idx, opts)
    opts = opts or {}
    local text     = opts.Text or idx
    local default  = opts.Default or false
    local tooltip  = opts.Tooltip
    local callback = opts.Callback

    local row = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
        Parent = gb.Container,
    })

    local box = new("Frame", {
        BackgroundColor3 = THEME.PanelAlt,
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.new(0, 0, 0.5, -8),
        Parent = row,
    })
    corner(box, 4)
    stroke(box, THEME.Stroke, 1)

    local fill = new("Frame", {
        BackgroundColor3 = THEME.AccentA,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Parent = box,
    })
    corner(fill, 4)
    purpleGradient(fill, 45)

    local lbl = new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 26, 0, 0),
        Size = UDim2.new(1, -26, 1, 0),
        Font = THEME.FontFamily,
        Text = text,
        TextColor3 = THEME.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local ctrl = {
        Value = default, Type = "Toggle",
        Callbacks = {}, Row = row, Label = lbl,
    }

    local function render()
        if ctrl.Value then
            tween(fill, 0.15, nil, nil, { BackgroundTransparency = 0 })
        else
            tween(fill, 0.15, nil, nil, { BackgroundTransparency = 1 })
        end
    end
    render()

    function ctrl:SetValue(v)
        self.Value = v and true or false
        render()
        for _, cb in ipairs(self.Callbacks) do pcall(cb, self.Value) end
        if callback then pcall(callback, self.Value) end
        return self
    end
    function ctrl:OnChanged(fn) table.insert(self.Callbacks, fn); return self end
    function ctrl:SetText(t) lbl.Text = t; return self end
    function ctrl:SetVisible(v) row.Visible = v end
    function ctrl:AddColorPicker(pIdx, o) local cp = makeStubControl("ColorPicker", (o or {}).Default or Color3.new(1,1,1)); Library.Options[pIdx] = cp; return cp end
    function ctrl:AddKeyPicker(pIdx, o) local kp = makeStubControl("KeyPicker", (o or {}).Default or "None"); Library.Options[pIdx] = kp; return kp end

    local btn = new("TextButton", {
        BackgroundTransparency = 1, Text = "",
        Size = UDim2.fromScale(1, 1), Parent = row,
    })
    btn.MouseButton1Click:Connect(function() ctrl:SetValue(not ctrl.Value) end)

    Library.Toggles[idx] = ctrl
    if opts.Default then ctrl:SetValue(true) end
    return ctrl
end

local function buildButton(gb, opts)
    opts = opts or {}
    local text = opts.Text or "Button"
    local cb   = opts.Func or opts.Callback

    local btn = new("TextButton", {
        BackgroundColor3 = THEME.PanelAlt,
        Size = UDim2.new(1, 0, 0, 26),
        Font = THEME.FontFamilyMed,
        Text = text,
        TextColor3 = THEME.Text,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = gb.Container,
    })
    corner(btn, 5)
    stroke(btn, THEME.Stroke, 1)

    btn.MouseEnter:Connect(function() tween(btn, 0.12, nil, nil, { BackgroundColor3 = THEME.Stroke }) end)
    btn.MouseLeave:Connect(function() tween(btn, 0.12, nil, nil, { BackgroundColor3 = THEME.PanelAlt }) end)
    btn.MouseButton1Click:Connect(function() if cb then pcall(cb) end end)

    local ctrl = { Type = "Button", Instance = btn }
    function ctrl:SetText(t) btn.Text = t; return self end
    function ctrl:AddButton(o) return buildButton(gb, o) end
    function ctrl:DoClick() if cb then pcall(cb) end end
    return ctrl
end


local function buildLabel(gb, textOrOpts, maybeOpts)
    local text, opts
    if typeof(textOrOpts) == "table" then
        opts = textOrOpts; text = opts.Text or ""
    else
        text = tostring(textOrOpts or "")
        if typeof(maybeOpts) == "table" then
            opts = maybeOpts
        elseif typeof(maybeOpts) == "boolean" then
            opts = { DoesWrap = maybeOpts }
        else
            opts = {}
        end
    end

    local lbl = new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = THEME.FontFamily,
        RichText = true,
        Text = mdToRich(text),
        TextColor3 = THEME.TextDim,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = gb.Container,
    })
    if opts.DoesWrap then
        lbl.TextWrapped = true
        lbl.Size = UDim2.new(1, 0, 0, 32)
    end

    local ctrl = { Type = "Label", Instance = lbl, Value = text }
    function ctrl:SetText(t) lbl.Text = mdToRich(t); self.Value = t; return self end
    function ctrl:SetVisible(v) lbl.Visible = v end
    function ctrl:AddColorPicker(idx, o) local cp = makeStubControl("ColorPicker", (o or {}).Default or Color3.new(1,1,1)); Library.Options[idx] = cp; return cp end
    function ctrl:AddKeyPicker(idx, o) local kp = makeStubControl("KeyPicker", (o or {}).Default or "None"); Library.Options[idx] = kp; return kp end
    return ctrl
end


local function buildDivider(gb)
    local line = new("Frame", {
        BackgroundColor3 = THEME.StrokeSoft,
        Size = UDim2.new(1, 0, 0, 1),
        BorderSizePixel = 0,
        Parent = gb.Container,
    })
    return { Type = "Divider", Instance = line }
end

local function buildSlider(gb, idx, opts)
    opts = opts or {}
    local text     = opts.Text or idx
    local minV     = opts.Min or 0
    local maxV     = opts.Max or 100
    local default  = opts.Default or minV
    local rounding = opts.Rounding or 0
    local suffix   = opts.Suffix or ""
    local callback = opts.Callback

    local row = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        Parent = gb.Container,
    })

    local header = new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 14),
        Font = THEME.FontFamily,
        Text = text,
        TextColor3 = THEME.TextDim,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local valLbl = new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 60, 0, 14),
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Font = THEME.FontFamilyMed,
        Text = tostring(default) .. suffix,
        TextColor3 = THEME.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row,
    })

    local track = new("Frame", {
        BackgroundColor3 = THEME.PanelAlt,
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 1, -10),
        Parent = row,
    })
    corner(track, 3)
    stroke(track, THEME.Stroke, 1)

    local fill = new("Frame", {
        BackgroundColor3 = THEME.AccentA,
        Size = UDim2.fromScale(0, 1),
        Parent = track,
    })
    corner(fill, 3)
    purpleGradient(fill, 0)

    local ctrl = { Type = "Slider", Value = default, Callbacks = {}, Min = minV, Max = maxV }

    local function roundVal(v)
        local mult = 10 ^ rounding
        return math.floor(v * mult + 0.5) / mult
    end

    local function apply(v, silent)
        v = math.clamp(v, minV, maxV); v = roundVal(v)
        ctrl.Value = v
        local a = (v - minV) / math.max(maxV - minV, 1e-6)
        fill.Size = UDim2.fromScale(a, 1)
        valLbl.Text = tostring(v) .. suffix
        if not silent then
            for _, cb in ipairs(ctrl.Callbacks) do pcall(cb, v) end
            if callback then pcall(callback, v) end
        end
    end
    apply(default, true)

    function ctrl:SetValue(v) apply(v); return self end
    function ctrl:OnChanged(fn) table.insert(self.Callbacks, fn); return self end
    function ctrl:SetMin(v) minV = v; ctrl.Min = v; apply(ctrl.Value); return self end
    function ctrl:SetMax(v) maxV = v; ctrl.Max = v; apply(ctrl.Value); return self end

    -- drag
    local dragging = false
    local function fromInput(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        apply(minV + (maxV - minV) * rel)
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; fromInput(i.Position.X)
        end
    end)
    UserInput.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            fromInput(i.Position.X)
        end
    end)
    UserInput.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    Library.Options[idx] = ctrl
    return ctrl
end

local function buildDropdown(gb, idx, opts)
    opts = opts or {}
    local text     = opts.Text or idx
    local values   = opts.Values or {}
    local multi    = opts.Multi or false
    local default  = opts.Default
    local callback = opts.Callback

    local row = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 42),
        Parent = gb.Container,
    })

    local header = new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 14),
        Font = THEME.FontFamily,
        Text = text,
        TextColor3 = THEME.TextDim,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local btn = new("TextButton", {
        BackgroundColor3 = THEME.PanelAlt,
        Position = UDim2.new(0, 0, 0, 18),
        Size = UDim2.new(1, 0, 0, 24),
        Font = THEME.FontFamilyMed,
        TextColor3 = THEME.Text,
        TextSize = 12,
        Text = "  Select...",
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        Parent = row,
    })
    corner(btn, 5)
    stroke(btn, THEME.Stroke, 1)
    padding(btn, 0, 22, 0, 8)

    local arrow = new("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        Font = THEME.FontFamilyBold,
        Text = "v",
        TextColor3 = THEME.TextDim,
        TextSize = 11,
        Parent = btn,
    })

    local ctrl = { Type = "Dropdown", Value = multi and {} or nil, Values = values, Callbacks = {}, Multi = multi }

    local function labelText()
        if multi then
            local list = {}
            for k, v in pairs(ctrl.Value or {}) do
                if v then table.insert(list, tostring(k)) end
            end
            if #list == 0 then return "  Select..." end
            return "  " .. table.concat(list, ", ")
        else
            return "  " .. tostring(ctrl.Value or "Select...")
        end
    end

    -- popup container (relative to dropdown row)
    local popup
    local function closePopup()
        if popup and popup.Parent then popup:Destroy() end
        popup = nil
    end

    local function openPopup()
        closePopup()
        local abs = btn.AbsolutePosition
        local size = btn.AbsoluteSize
        popup = new("Frame", {
            BackgroundColor3 = THEME.Panel,
            Position = UDim2.fromOffset(abs.X, abs.Y + size.Y + 4),
            Size = UDim2.fromOffset(size.X, math.min(#values * 22 + 8, 180)),
            Parent = Library.ScreenGui,
            ZIndex = 50,
        })
        corner(popup, 6)
        stroke(popup, THEME.Stroke, 1)
        padding(popup, 4)

        local scroll = new("ScrollingFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = THEME.AccentA,
            BorderSizePixel = 0,
            Parent = popup,
            ZIndex = 51,
        })
        new("UIListLayout", { Padding = UDim.new(0, 2), Parent = scroll })

        for _, v in ipairs(values) do
            local item = new("TextButton", {
                BackgroundColor3 = THEME.PanelAlt,
                Size = UDim2.new(1, 0, 0, 20),
                Font = THEME.FontFamily,
                Text = "  " .. tostring(v),
                TextColor3 = THEME.Text,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false,
                Parent = scroll,
                ZIndex = 52,
                BackgroundTransparency = 0.2,
            })
            corner(item, 4)
            local isSel = multi and (ctrl.Value[v] == true) or (ctrl.Value == v)
            if isSel then item.BackgroundColor3 = THEME.AccentA end

            item.MouseButton1Click:Connect(function()
                if multi then
                    ctrl.Value[v] = not ctrl.Value[v] or nil
                    if ctrl.Value[v] then
                        item.BackgroundColor3 = THEME.AccentA
                    else
                        item.BackgroundColor3 = THEME.PanelAlt
                    end
                else
                    ctrl.Value = v
                    closePopup()
                end
                btn.Text = labelText()
                for _, cb in ipairs(ctrl.Callbacks) do pcall(cb, ctrl.Value) end
                if callback then pcall(callback, ctrl.Value) end
            end)
        end

        -- click outside to close
        local conn
        conn = UserInput.InputBegan:Connect(function(i)
            if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if not popup or not popup.Parent then conn:Disconnect(); return end
            local mp = i.Position
            local ap = popup.AbsolutePosition; local as = popup.AbsoluteSize
            local bap = btn.AbsolutePosition; local bas = btn.AbsoluteSize
            local inPopup = mp.X >= ap.X and mp.X <= ap.X+as.X and mp.Y >= ap.Y and mp.Y <= ap.Y+as.Y
            local inBtn   = mp.X >= bap.X and mp.X <= bap.X+bas.X and mp.Y >= bap.Y and mp.Y <= bap.Y+bas.Y
            if not inPopup and not inBtn then closePopup(); conn:Disconnect() end
        end)
    end

    btn.MouseButton1Click:Connect(function()
        if popup then closePopup() else openPopup() end
    end)

    function ctrl:SetValue(v)
        if multi then
            self.Value = {}
            if typeof(v) == "table" then
                for kk, vv in pairs(v) do
                    if vv == true then self.Value[kk] = true
                    elseif typeof(kk) == "number" then self.Value[vv] = true end
                end
            end
        else
            self.Value = v
        end
        btn.Text = labelText()
        for _, cb in ipairs(self.Callbacks) do pcall(cb, self.Value) end
        if callback then pcall(callback, self.Value) end
        return self
    end
    function ctrl:OnChanged(fn) table.insert(self.Callbacks, fn); return self end
    function ctrl:SetValues(v)
        values = v or {}; self.Values = values
        if popup then closePopup(); openPopup() end
        return self
    end

    if default ~= nil then ctrl:SetValue(default) else btn.Text = labelText() end

    Library.Options[idx] = ctrl
    return ctrl
end

local function buildInput(gb, idx, opts)
    opts = opts or {}
    local text     = opts.Text or idx
    local default  = opts.Default or ""
    local placeholder = opts.Placeholder or opts.PlaceholderText or ""
    local callback = opts.Callback

    local row = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 42),
        Parent = gb.Container,
    })
    new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 14),
        Font = THEME.FontFamily, Text = text,
        TextColor3 = THEME.TextDim, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })
    local tb = new("TextBox", {
        BackgroundColor3 = THEME.PanelAlt,
        Position = UDim2.new(0, 0, 0, 18),
        Size = UDim2.new(1, 0, 0, 22),
        Font = THEME.FontFamily, TextSize = 12,
        TextColor3 = THEME.Text,
        PlaceholderColor3 = THEME.TextMuted,
        PlaceholderText = placeholder,
        Text = tostring(default),
        ClearTextOnFocus = false,
        Parent = row,
    })
    corner(tb, 5); stroke(tb, THEME.Stroke, 1); padding(tb, 0, 8, 0, 8)

    local ctrl = { Type = "Input", Value = default, Callbacks = {} }
    function ctrl:SetValue(v) tb.Text = tostring(v); self.Value = tostring(v); for _, cb in ipairs(self.Callbacks) do pcall(cb, self.Value) end; return self end
    function ctrl:OnChanged(fn) table.insert(self.Callbacks, fn); return self end
    tb.FocusLost:Connect(function()
        ctrl.Value = tb.Text
        for _, cb in ipairs(ctrl.Callbacks) do pcall(cb, ctrl.Value) end
        if callback then pcall(callback, ctrl.Value) end
    end)
    Library.Options[idx] = ctrl
    return ctrl
end

-- ============================================================================
-- GROUPBOX
-- ============================================================================
local Groupbox = {}
Groupbox.__index = Groupbox

function Groupbox:AddToggle(idx, opts)   return buildToggle(self, idx, opts) end
function Groupbox:AddSlider(idx, opts)   return buildSlider(self, idx, opts) end
function Groupbox:AddDropdown(idx, opts) return buildDropdown(self, idx, opts) end
function Groupbox:AddInput(idx, opts)    return buildInput(self, idx, opts) end
function Groupbox:AddButton(opts, cb)
    if typeof(opts) == "string" then opts = { Text = opts, Func = cb } end
    return buildButton(self, opts)
end
function Groupbox:AddLabel(t, o) return buildLabel(self, t, o) end
function Groupbox:AddDivider()   return buildDivider(self) end
-- Phase 1 stubs (safe): return chainable object; hosts nothing visible yet
function Groupbox:AddDependencyBox() return setmetatable({ Container = self.Container }, Groupbox) end

local function buildGroupbox(parent, name, side)
    local box = new("Frame", {
        BackgroundColor3 = THEME.Panel,
        Size = UDim2.new(1, 0, 0, 40),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = parent,
    })
    corner(box, 8); stroke(box, THEME.Stroke, 1)

    local head = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 26),
        Parent = box,
    })
    new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        Font = THEME.FontFamilyBold, Text = name,
        TextColor3 = THEME.Text, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = head,
    })
    local accent = new("Frame", {
        BackgroundColor3 = THEME.AccentA,
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = head,
    })
    purpleGradient(accent, 0)

    local container = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 30),
        Size = UDim2.new(1, -20, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = box,
    })
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = container })
    padding(box, 0, 0, 10, 0)

    local gb = setmetatable({ Container = container, Frame = box, Name = name }, Groupbox)
    return gb
end

-- Tabbox (stubs to real horizontal switch)
local Tabbox = {}
Tabbox.__index = Tabbox
function Tabbox:AddTab(name)
    -- treat each subtab as its own groupbox stacked
    return buildGroupbox(self.Container, name)
end

local function buildTabbox(parent)
    local holder = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = parent,
    })
    new("UIListLayout", { Padding = UDim.new(0, 8), Parent = holder })
    return setmetatable({ Container = holder }, Tabbox)
end

-- ============================================================================
-- TAB
-- ============================================================================
local Tab = {}
Tab.__index = Tab

function Tab:AddLeftGroupbox(name)  return buildGroupbox(self.Left, name, "L") end
function Tab:AddRightGroupbox(name) return buildGroupbox(self.Right, name, "R") end
function Tab:AddLeftTabbox()        return buildTabbox(self.Left) end
function Tab:AddRightTabbox()       return buildTabbox(self.Right) end

-- ============================================================================
-- WINDOW
-- ============================================================================
local Window = {}
Window.__index = Window

local function buildTab(win, name, icon)
    -- tab button in sidebar
    local btn = new("TextButton", {
        BackgroundColor3 = THEME.Background,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        Font = THEME.FontFamilyMed,
        Text = "  " .. name,
        TextColor3 = THEME.TextDim,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        Parent = win.Sidebar,
    })
    corner(btn, 5)

    -- animated underline (grows on select)
    local line = new("Frame", {
        BackgroundColor3 = THEME.AccentA,
        Position = UDim2.new(0, 8, 1, -3),
        Size = UDim2.fromOffset(0, 2),
        Parent = btn,
    })
    corner(line, 2)
    purpleGradient(line, 0)

    -- content
    local content = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        Parent = win.Content,
    })

    local columns = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Parent = content,
    })
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 10),
        Parent = columns,
    })

    local function makeCol()
        local col = new("ScrollingFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0.5, -5, 1, 0),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = THEME.AccentA,
            BorderSizePixel = 0,
            Parent = columns,
        })
        new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = col })
        padding(col, 4, 6, 4, 2)
        return col
    end

    local left  = makeCol()
    local right = makeCol()

    local tab = setmetatable({
        Name = name, Button = btn, Content = content,
        Left = left, Right = right, Line = line,
    }, Tab)

    btn.MouseButton1Click:Connect(function()
        win:SelectTab(tab)
    end)

    btn.MouseEnter:Connect(function()
        if win.ActiveTab ~= tab then tween(btn, 0.12, nil, nil, { TextColor3 = THEME.Text }) end
    end)
    btn.MouseLeave:Connect(function()
        if win.ActiveTab ~= tab then tween(btn, 0.12, nil, nil, { TextColor3 = THEME.TextDim }) end
    end)

    table.insert(win.TabList, tab)
    if not win.ActiveTab then win:SelectTab(tab) end
    return tab
end

function Window:AddTab(name, icon) return buildTab(self, name, icon) end
function Window:AddKeyTab(name)    return buildTab(self, name) end

function Window:SelectTab(tab)
    for _, t in ipairs(self.TabList) do
        t.Content.Visible = false
        tween(t.Button, 0.15, nil, nil, { TextColor3 = THEME.TextDim, BackgroundTransparency = 1 })
        tween(t.Line, 0.2, nil, nil, { Size = UDim2.fromOffset(0, 2) })
    end
    self.ActiveTab = tab
    tab.Content.Visible = true
    tween(tab.Button, 0.15, nil, nil, { TextColor3 = THEME.Text, BackgroundTransparency = 0.85 })
    tween(tab.Line, 0.25, Enum.EasingStyle.Quart, nil, { Size = UDim2.fromOffset(math.max(60, tab.Button.AbsoluteSize.X - 20), 2) })
end

-- ============================================================================
-- CREATE WINDOW (main shell)
-- ============================================================================
function Library:CreateWindow(cfg)
    cfg = cfg or {}
    local title      = cfg.Title or "Eclipse Hub"
    local footer     = cfg.Footer or "v3.0.0"
    local size       = cfg.Size or UDim2.fromOffset(880, 580)
    local center     = cfg.Center ~= false
    local resizable  = cfg.Resizable ~= false
    local toggleKey  = cfg.ToggleKeybind or Enum.KeyCode.RightShift
    self.NotifySide  = cfg.NotifySide or "Right"

    -- splash
    local splash = createSplash()

    local gui = new("ScreenGui", {
        Name = "EclipseUI",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 9997,
    })
    safeParent(gui)
    self.ScreenGui = gui

    local root = new("Frame", {
        BackgroundColor3 = THEME.Background,
        Size = size,
        Parent = gui,
    })
    if center then
        root.AnchorPoint = Vector2.new(0.5, 0.5)
        root.Position = UDim2.fromScale(0.5, 0.5)
    else
        root.Position = UDim2.fromOffset(80, 80)
    end
    corner(root, 10)
    stroke(root, THEME.Stroke, 1)
    self.MainFrame = root

    -- top bar
    local top = new("Frame", {
        BackgroundColor3 = THEME.Panel,
        Size = UDim2.new(1, 0, 0, 36),
        Parent = root,
    })
    corner(top, 10)
    -- kill bottom rounding
    new("Frame", {
        BackgroundColor3 = THEME.Panel,
        Size = UDim2.new(1, 0, 0, 12),
        Position = UDim2.new(0, 0, 1, -12),
        BorderSizePixel = 0,
        Parent = top,
    })

    local logo = new("ImageLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 6),
        Size = UDim2.fromOffset(24, 24),
        Image = LOGO_URL,
        ScaleType = Enum.ScaleType.Fit,
        Parent = top,
    })
    corner(logo, 4)

    new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(42, 0),
        Size = UDim2.new(1, -180, 1, 0),
        Font = THEME.FontFamilyBold, Text = title,
        TextColor3 = THEME.Text, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = top,
    })

    local footLbl = new("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(200, 20),
        Font = THEME.FontFamily, Text = footer,
        TextColor3 = THEME.TextDim, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = top,
    })
    self.FooterLabel = footLbl
    function self:SetFooter(t) footLbl.Text = t end

    -- accent line under top
    local underline = new("Frame", {
        BackgroundColor3 = THEME.AccentA,
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = top,
    })
    purpleGradient(underline, 0)

    -- sidebar
    local sidebar = new("Frame", {
        BackgroundColor3 = THEME.Panel,
        Position = UDim2.new(0, 0, 0, 36),
        Size = UDim2.new(0, 160, 1, -36),
        Parent = root,
    })
    new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sidebar })
    padding(sidebar, 8, 6, 8, 6)

    local content = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 168, 0, 44),
        Size = UDim2.new(1, -176, 1, -52),
        Parent = root,
    })

    -- drag from top
    do
        local dragging, dragStart, startPos
        top.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; dragStart = i.Position; startPos = root.Position
            end
        end)
        UserInput.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                local d = i.Position - dragStart
                root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
        UserInput.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
    end

    -- resize handle (bottom-right)
    if resizable then
        local handle = new("Frame", {
            BackgroundColor3 = THEME.AccentA,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -4, 1, -4),
            Size = UDim2.fromOffset(12, 12),
            BackgroundTransparency = 0.6,
            Parent = root,
        })
        corner(handle, 3)
        purpleGradient(handle, 45)

        local resizing, startInput, startSize
        handle.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = true; startInput = i.Position; startSize = root.AbsoluteSize
            end
        end)
        UserInput.InputChanged:Connect(function(i)
            if resizing and i.UserInputType == Enum.UserInputType.MouseMovement then
                local d = i.Position - startInput
                local w = math.clamp(startSize.X + d.X, self.MinSize.X, self.MaxSize.X)
                local h = math.clamp(startSize.Y + d.Y, self.MinSize.Y, self.MaxSize.Y)
                root.Size = UDim2.fromOffset(w, h)
            end
        end)
        UserInput.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end
        end)
    end

    -- toggle key
    UserInput.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.KeyCode == toggleKey then
            self:Toggle()
        end
    end)

    local win = setmetatable({
        Root = root, Sidebar = sidebar, Content = content, TabList = {}, ActiveTab = nil,
    }, Window)

    self.Window = win

    -- close splash after minimum load window
    task.spawn(function()
        task.wait(1.2)
        splash.Sub.Text = "Ready"
        task.wait(0.3)
        splash.Close()
    end)

    if cfg.AutoShow == false then root.Visible = false end
    return win
end

function Library:Toggle(state)
    if not self.MainFrame then return end
    if state == nil then state = not self.MainFrame.Visible end
    self.MainFrame.Visible = state
end
function Library:SetVisible(v) self:Toggle(v) end

function Library:OnUnload(fn)
    if typeof(fn) == "function" then table.insert(self._Unloads, fn) end
end

function Library:Unload()
    if self.Unloaded then return end
    self.Unloaded = true
    for _, fn in ipairs(self._Unloads) do pcall(fn) end
    if self.ScreenGui then pcall(function() self.ScreenGui:Destroy() end) end
    if NotifyRoot then pcall(function() NotifyRoot:Destroy() end) end
end

-- Convenience stubs for Obsidian compatibility (no-ops that don't crash)
function Library:UpdateColorsUsingRegistry() end
function Library:GetDarkerColor(c) return Color3.new(c.R*0.75, c.G*0.75, c.B*0.75) end
Library.KeybindFrame = nil

return Library
