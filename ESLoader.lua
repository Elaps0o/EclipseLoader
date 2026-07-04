--[[
    ESLoader.lua  —  Eclipse Script Loader
    ---------------------------------------------------------------
    Detects the current Roblox game via `game.PlaceId` / `game.GameId`
    and streams the matching Eclipse loader script. Uses the same
    Obsidian keybind-list aesthetic as ec.lua: MAIN 20/20/20, OUTLINE
    40/40/40, Code font, thin UIStroke, no chrome, no gradients.

    Flow:
      1. Panel appears with:
          "You are about to load"
          <GAME NAME>            (Code font, bold, larger)
          [Continue]  [Cancel]
      2. Continue is disabled until the user proves they joined Discord:
          - "Copy invite link" button copies the invite to clipboard
            and starts a 30s runtime countdown on the Continue button.
          - The user CANNOT bypass the countdown.
      3. When the timer hits 0, Continue becomes clickable and, on
         press, loadstrings the matching game script.

    Add new games by extending the SCRIPTS table below.
--]]

if getgenv().EclipseLoaderLoaded then return end
getgenv().EclipseLoaderLoaded = true

local Players       = game:GetService("Players")
local CoreGui       = game:GetService("CoreGui")
local HttpService   = game:GetService("HttpService")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")
local UserInput     = game:GetService("UserInputService")
local LocalPlayer   = Players.LocalPlayer

-------------------------------------------------------------------
-- CONFIG
-------------------------------------------------------------------
local DISCORD_INVITE = "https://discord.gg/eclipsehub"
local UNLOCK_SECS    = 30

-- Map: PlaceId -> { name = "Display Name", url = "raw script url" }
-- Add extra entries as new game loaders ship.
local SCRIPTS = {
    -- BoxStrike (a.k.a. BloxStrike)
    [2384195953]  = { name = "BoxStrike", url = "https://raw.githubusercontent.com/Elaps0o/EclipseLoader/refs/heads/main/ESloaders/ESBoxStrike" },
    [12581487681] = { name = "BoxStrike", url = "https://raw.githubusercontent.com/Elaps0o/EclipseLoader/refs/heads/main/ESloaders/ESBoxStrike" },
}
-- Also allow lookup by GameId as a fallback:
local SCRIPTS_BY_UNIVERSE = {}

local function resolveGame()
    local pid = game.PlaceId
    local hit = SCRIPTS[pid] or SCRIPTS_BY_UNIVERSE[game.GameId]
    if hit then return hit end
    return { name = "Unknown Game", url = nil }
end

-------------------------------------------------------------------
-- HELPERS
-------------------------------------------------------------------
local function safeSetClipboard(text)
    local fn = (setclipboard or (syn and syn.write_clipboard) or (Clipboard and Clipboard.set) or toclipboard)
    if fn then pcall(fn, text); return true end
    return false
end

local function safeHttpGet(url)
    if not url then return nil end
    local ok, body = pcall(function()
        if syn and syn.request then
            return syn.request({ Url = url, Method = "GET" }).Body
        elseif http and http.request then
            return http.request({ Url = url, Method = "GET" }).Body
        elseif http_request then
            return http_request({ Url = url, Method = "GET" }).Body
        elseif request then
            return request({ Url = url, Method = "GET" }).Body
        end
        return game:HttpGet(url)
    end)
    if ok then return body end
    return nil
end

local function tween(inst, time, props)
    local t = TweenService:Create(inst, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    t:Play(); return t
end

-------------------------------------------------------------------
-- UI (keybind-list style)
-------------------------------------------------------------------
local MAIN_    = Color3.fromRGB(20, 20, 20)
local OUTLINE_ = Color3.fromRGB(40, 40, 40)
local SUB_     = Color3.fromRGB(28, 28, 28)
local FONT_    = Color3.fromRGB(235, 235, 235)
local DIM_     = Color3.fromRGB(150, 150, 150)
local ACCENT_  = Color3.fromRGB(90, 170, 255)
local DANGER_  = Color3.fromRGB(220, 90, 90)

local sg = Instance.new("ScreenGui")
sg.Name = "EclipseLoader"; sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.DisplayOrder = 200
pcall(function() sg.Parent = (gethui and gethui()) or CoreGui end)

-- Dim backdrop
local dim = Instance.new("Frame", sg)
dim.BackgroundColor3 = Color3.fromRGB(0,0,0)
dim.BackgroundTransparency = 0.45
dim.Size = UDim2.fromScale(1,1); dim.BorderSizePixel = 0
dim.ZIndex = 1

local panel = Instance.new("Frame", sg)
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(380, 220)
panel.BackgroundColor3 = MAIN_
panel.BorderSizePixel = 0
panel.ZIndex = 2
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 4)
local pStroke = Instance.new("UIStroke", panel)
pStroke.Color = OUTLINE_; pStroke.Thickness = 1

-- Header line
local header = Instance.new("TextLabel", panel)
header.BackgroundTransparency = 1
header.Size = UDim2.new(1, -20, 0, 20)
header.Position = UDim2.fromOffset(10, 12)
header.Font = Enum.Font.Code; header.TextSize = 12
header.TextColor3 = DIM_; header.TextXAlignment = Enum.TextXAlignment.Center
header.Text = "You are about to load"
header.ZIndex = 3

-- Game name (bold, Code)
local resolved = resolveGame()
local gameLbl = Instance.new("TextLabel", panel)
gameLbl.BackgroundTransparency = 1
gameLbl.Size = UDim2.new(1, -20, 0, 28)
gameLbl.Position = UDim2.fromOffset(10, 34)
gameLbl.Font = Enum.Font.Code; gameLbl.TextSize = 22
gameLbl.TextColor3 = FONT_; gameLbl.TextXAlignment = Enum.TextXAlignment.Center
gameLbl.Text = string.upper(resolved.name)
gameLbl.ZIndex = 3

-- Divider
local div = Instance.new("Frame", panel)
div.BackgroundColor3 = OUTLINE_; div.BorderSizePixel = 0
div.Position = UDim2.fromOffset(10, 70)
div.Size = UDim2.new(1, -20, 0, 1); div.ZIndex = 3

-- Discord gate
local gate = Instance.new("TextLabel", panel)
gate.BackgroundTransparency = 1
gate.Size = UDim2.new(1, -20, 0, 16)
gate.Position = UDim2.fromOffset(10, 80)
gate.Font = Enum.Font.Code; gate.TextSize = 11
gate.TextColor3 = DIM_; gate.TextXAlignment = Enum.TextXAlignment.Center
gate.Text = "Join our Discord to unlock (30s cooldown)."
gate.ZIndex = 3

-- Copy invite button
local copyBtn = Instance.new("TextButton", panel)
copyBtn.Size = UDim2.new(1, -20, 0, 26)
copyBtn.Position = UDim2.fromOffset(10, 104)
copyBtn.BackgroundColor3 = SUB_; copyBtn.BorderSizePixel = 0
copyBtn.AutoButtonColor = false
copyBtn.Font = Enum.Font.Code; copyBtn.TextSize = 12
copyBtn.TextColor3 = FONT_
copyBtn.Text = "COPY DISCORD INVITE"
copyBtn.ZIndex = 3
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 3)
local cbStroke = Instance.new("UIStroke", copyBtn); cbStroke.Color = OUTLINE_; cbStroke.Thickness = 1

-- Buttons row
local function makeButton(text, x, wScale, wOff, color)
    local b = Instance.new("TextButton", panel)
    b.Position = UDim2.new(0, x, 1, -46)
    b.Size = UDim2.new(wScale, wOff, 0, 34)
    b.BackgroundColor3 = SUB_; b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Font = Enum.Font.Code; b.TextSize = 13
    b.TextColor3 = color or FONT_
    b.Text = text; b.ZIndex = 3
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 3)
    local s = Instance.new("UIStroke", b); s.Color = OUTLINE_; s.Thickness = 1
    return b, s
end

local cancelBtn, cancelStroke = makeButton("CANCEL", 10, 0.5, -14, DANGER_)
local continueBtn, continueStroke = makeButton("CONTINUE  (LOCKED)", 0, 0.5, -14, DIM_)
continueBtn.Position = UDim2.new(0.5, 4, 1, -46)

-- Interaction state
local unlocked = false
local timerRunning = false

local function refreshContinue(remaining)
    if unlocked then
        continueBtn.Text = "CONTINUE"
        continueBtn.TextColor3 = ACCENT_
        continueStroke.Color = ACCENT_
    elseif remaining then
        continueBtn.Text = string.format("CONTINUE  (%ds)", remaining)
        continueBtn.TextColor3 = DIM_
        continueStroke.Color = OUTLINE_
    else
        continueBtn.Text = "CONTINUE  (LOCKED)"
        continueBtn.TextColor3 = DIM_
        continueStroke.Color = OUTLINE_
    end
end

-- Hover/press micro-feedback
local function bindHover(btn, stroke, hi, lo)
    btn.MouseEnter:Connect(function() stroke.Color = hi end)
    btn.MouseLeave:Connect(function() stroke.Color = lo end)
end
bindHover(copyBtn,   cbStroke,      ACCENT_, OUTLINE_)
bindHover(cancelBtn, cancelStroke,  DANGER_, OUTLINE_)

local function close()
    tween(panel, 0.18, { Size = UDim2.fromOffset(380, 0) })
    tween(dim,   0.18, { BackgroundTransparency = 1 })
    task.wait(0.2)
    sg:Destroy()
end

cancelBtn.MouseButton1Click:Connect(function()
    close()
end)

copyBtn.MouseButton1Click:Connect(function()
    local ok = safeSetClipboard(DISCORD_INVITE)
    copyBtn.Text = ok and ("COPIED  ·  " .. DISCORD_INVITE) or ("OPEN: " .. DISCORD_INVITE)
    if timerRunning or unlocked then return end
    timerRunning = true
    task.spawn(function()
        local remaining = UNLOCK_SECS
        while remaining > 0 do
            refreshContinue(remaining)
            task.wait(1)
            remaining = remaining - 1
        end
        unlocked = true
        refreshContinue(nil)
        bindHover(continueBtn, continueStroke, ACCENT_, ACCENT_)
    end)
end)

continueBtn.MouseButton1Click:Connect(function()
    if not unlocked then return end
    if not resolved.url then
        gameLbl.Text = "UNSUPPORTED"
        gate.Text = "No loader available for this PlaceId (" .. tostring(game.PlaceId) .. ")."
        gate.TextColor3 = DANGER_
        return
    end
    continueBtn.Text = "LOADING..."
    continueBtn.TextColor3 = DIM_
    task.spawn(function()
        local body = safeHttpGet(resolved.url)
        if not body then
            gate.Text = "Failed to fetch script."
            gate.TextColor3 = DANGER_
            continueBtn.Text = "CONTINUE"
            continueBtn.TextColor3 = ACCENT_
            return
        end
        local fn, err = loadstring(body)
        if not fn then
            gate.Text = "Compile error: " .. tostring(err):sub(1, 60)
            gate.TextColor3 = DANGER_
            return
        end
        close()
        task.wait(0.05)
        local ok, runErr = pcall(fn)
        if not ok then warn("[ESLoader] runtime error:", runErr) end
    end)
end)

-- Open animation
panel.Size = UDim2.fromOffset(380, 0)
dim.BackgroundTransparency = 1
tween(panel, 0.28, { Size = UDim2.fromOffset(380, 220) })
tween(dim,   0.28, { BackgroundTransparency = 0.45 })
refreshContinue(nil)
