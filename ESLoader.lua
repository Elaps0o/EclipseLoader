--[[
    ESLoader.lua  —  Eclipse Script Loader
    ---------------------------------------------------------------
    Detects the current Roblox game via `game.PlaceId` / `game.GameId`
    and streams the matching Eclipse loader script. Signs an auth
    token bound to the LocalPlayer and hands it to ec.lua via
    getgenv().ECLIPSE_AUTH so direct loadstrings are refused.

    Flow:
      1. Panel appears: game name + ToS checkbox + Copy Discord
         invite + Continue/Cancel.
      2. Continue stays LOCKED until the user (a) checks the ToS box
         AND (b) waits out a 10s runtime cooldown that starts when
         they copy the invite. Button shows "CONTINUE (LOCKED)" the
         whole time — no visible countdown.
      3. When both gates pass, Continue becomes clickable and, on
         press, injects the signed auth token then loadstrings the
         matching game script.
--]]

-- Clean up any previous instance so re-executing the loader always
-- shows a fresh UI.
pcall(function()
    local host = (gethui and gethui()) or game:GetService("CoreGui")
    local old = host:FindFirstChild("EclipseLoader")
    if old then old:Destroy() end
end)
getgenv().EclipseLoaderLoaded = true

local Players       = game:GetService("Players")
local CoreGui       = game:GetService("CoreGui")
local HttpService   = game:GetService("HttpService")
local TweenService  = game:GetService("TweenService")
local LocalPlayer   = Players.LocalPlayer

-------------------------------------------------------------------
-- CONFIG
-------------------------------------------------------------------
local DISCORD_INVITE = "https://discord.com/invite/5Drj4Hkdgu"
local UNLOCK_SECS    = 10
local SIG_SECRET     = "ES_v1_9f2a4c1e8b6d3a57f2e0c9b1a48d76e2c5f0"

local BOXSTRIKE_URL = "https://raw.githubusercontent.com/Elaps0o/EclipseLoader/refs/heads/main/ESloaders/ESBoxStrike"

local SCRIPTS = {
    {
        name = "[ECLIPSE HUB]: BloxStrike",
        url  = BOXSTRIKE_URL,
        ids  = { 114234929420007 },
        keywords = { "boxstrike", "bloxstrike" },
    },
}

local function fetchTitle()
    local ok, info = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)
    if ok and info and info.Name then return info.Name end
    return "this game"
end

local function resolveGame()
    local gid, pid = game.GameId, game.PlaceId
    for _, entry in ipairs(SCRIPTS) do
        for _, id in ipairs(entry.ids or {}) do
            if id == gid or id == pid then
                return { name = entry.name, url = entry.url }
            end
        end
    end
    local title = fetchTitle()
    local lower = string.lower(title)
    for _, entry in ipairs(SCRIPTS) do
        for _, kw in ipairs(entry.keywords or {}) do
            if string.find(lower, kw, 1, true) then
                return { name = entry.name, url = entry.url }
            end
        end
    end
    return { name = title, url = nil, unsupported = true }
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
-- AUTH TOKEN — signed handoff to ec.lua via getgenv().ECLIPSE_AUTH.
-- ec.lua recomputes the signature with the same SIG_SECRET and
-- rejects anything not bound to the current LocalPlayer.
-------------------------------------------------------------------
local function _sign(data)
    local payload = data .. "|" .. SIG_SECRET
    if crypt and type(crypt.hash) == "function" then
        local ok, h = pcall(crypt.hash, payload, "sha256"); if ok and h then return h end
    end
    if syn and syn.crypto and type(syn.crypto.hash) == "function" then
        local ok, h = pcall(syn.crypto.hash, "sha256", payload); if ok and h then return h end
    end
    local h1, h2 = 2166136261, 3735928559
    for i = 1, #payload do
        local b = string.byte(payload, i)
        h1 = (bit32.bxor(h1, b) * 16777619) % 0x100000000
        h2 = (bit32.bxor(h2, b * 131 + i) * 2246822519) % 0x100000000
    end
    return string.format("%08x%08x", h1, h2)
end

local function installAuthToken()
    local uid    = LocalPlayer.UserId
    local uname  = LocalPlayer.Name
    local issued = os.time()
    local token  = _sign(tostring(uid) .. "|" .. uname .. "|" .. tostring(issued))
    getgenv().ECLIPSE_AUTH = {
        userId   = uid,
        username = uname,
        issued   = issued,
        token    = token,
        v        = 1,
    }
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
local SUCCESS_ = Color3.fromRGB(80, 200, 120)
local UNLOCKED_= Color3.fromRGB(200, 200, 200)

local sg = Instance.new("ScreenGui")
sg.Name = "EclipseLoader"; sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.DisplayOrder = 2147483647
sg.IgnoreGuiInset = true
pcall(function() sg.Parent = (gethui and gethui()) or CoreGui end)

local dim = Instance.new("TextButton", sg)
dim.Name = "Backdrop"
dim.AutoButtonColor = false
dim.Text = ""
dim.Modal = true
dim.Active = true
dim.BackgroundColor3 = Color3.fromRGB(0,0,0)
dim.BackgroundTransparency = 1
dim.Size = UDim2.fromScale(1,1)
dim.Position = UDim2.fromScale(0,0)
dim.BorderSizePixel = 0
dim.ZIndex = 1

local panel = Instance.new("Frame", sg)
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(380, 260)
panel.BackgroundColor3 = MAIN_
panel.BorderSizePixel = 0
panel.ZIndex = 2
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 4)
local pStroke = Instance.new("UIStroke", panel)
pStroke.Color = OUTLINE_; pStroke.Thickness = 1

local header = Instance.new("TextLabel", panel)
header.BackgroundTransparency = 1
header.Size = UDim2.new(1, -20, 0, 20)
header.Position = UDim2.fromOffset(10, 12)
header.Font = Enum.Font.Code; header.TextSize = 12
header.TextColor3 = DIM_; header.TextXAlignment = Enum.TextXAlignment.Center
header.Text = "You are about to load"
header.ZIndex = 3

local resolved = resolveGame()
local resolvedName = resolved.name
local gameLbl = Instance.new("TextLabel", panel)
gameLbl.BackgroundTransparency = 1
gameLbl.Size = UDim2.new(1, -20, 0, 28)
gameLbl.Position = UDim2.fromOffset(10, 34)
gameLbl.Font = Enum.Font.Code; gameLbl.TextSize = 22
gameLbl.TextColor3 = FONT_; gameLbl.TextXAlignment = Enum.TextXAlignment.Center
gameLbl.Text = string.upper(resolvedName)
gameLbl.ZIndex = 3

local div = Instance.new("Frame", panel)
div.BackgroundColor3 = OUTLINE_; div.BorderSizePixel = 0
div.Position = UDim2.fromOffset(10, 70)
div.Size = UDim2.new(1, -20, 0, 1); div.ZIndex = 3

local gate = Instance.new("TextLabel", panel)
gate.BackgroundTransparency = 1
gate.Size = UDim2.new(1, -20, 0, 16)
gate.Position = UDim2.fromOffset(10, 80)
gate.Font = Enum.Font.Code; gate.TextSize = 11
gate.TextColor3 = DIM_; gate.TextXAlignment = Enum.TextXAlignment.Center
gate.Text = resolved.unsupported
    and ('No loader available for "' .. resolvedName .. '".')
    or  "Accept the Terms and join our Discord to unlock."
if resolved.unsupported then gate.TextColor3 = DANGER_ end
gate.ZIndex = 3

-- ToS checkbox row (checkbox + clickable label)
local tosRow = Instance.new("Frame", panel)
tosRow.BackgroundTransparency = 1
tosRow.Position = UDim2.fromOffset(10, 104)
tosRow.Size = UDim2.new(1, -20, 0, 22)
tosRow.ZIndex = 3

local tosBox = Instance.new("TextButton", tosRow)
tosBox.Size = UDim2.fromOffset(18, 18)
tosBox.Position = UDim2.fromOffset(0, 2)
tosBox.BackgroundColor3 = SUB_
tosBox.BorderSizePixel = 0
tosBox.AutoButtonColor = false
tosBox.Font = Enum.Font.Code; tosBox.TextSize = 14
tosBox.TextColor3 = SUCCESS_
tosBox.Text = ""
tosBox.ZIndex = 4
Instance.new("UICorner", tosBox).CornerRadius = UDim.new(0, 2)
local tosStroke = Instance.new("UIStroke", tosBox); tosStroke.Color = OUTLINE_; tosStroke.Thickness = 1

local tosLbl = Instance.new("TextButton", tosRow)
tosLbl.BackgroundTransparency = 1
tosLbl.Position = UDim2.fromOffset(26, 0)
tosLbl.Size = UDim2.new(1, -26, 1, 0)
tosLbl.AutoButtonColor = false
tosLbl.Font = Enum.Font.Code; tosLbl.TextSize = 11
tosLbl.TextColor3 = DIM_
tosLbl.TextXAlignment = Enum.TextXAlignment.Left
tosLbl.Text = "I have read and accept the Eclipse Hub Terms of Service."
tosLbl.ZIndex = 4

-- Copy invite button
local copyBtn = Instance.new("TextButton", panel)
copyBtn.Size = UDim2.new(1, -20, 0, 26)
copyBtn.Position = UDim2.fromOffset(10, 136)
copyBtn.BackgroundColor3 = SUB_; copyBtn.BorderSizePixel = 0
copyBtn.AutoButtonColor = false
copyBtn.Font = Enum.Font.Code; copyBtn.TextSize = 12
copyBtn.TextColor3 = FONT_
copyBtn.Text = "COPY DISCORD INVITE"
copyBtn.ZIndex = 3
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 3)
local cbStroke = Instance.new("UIStroke", copyBtn); cbStroke.Color = OUTLINE_; cbStroke.Thickness = 1

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

if resolved.unsupported then
    copyBtn.Visible = false
    continueBtn.Visible = false
    tosRow.Visible = false
    cancelBtn.AnchorPoint = Vector2.new(0.5, 0)
    cancelBtn.Position = UDim2.new(0.5, 0, 1, -46)
    cancelBtn.Size = UDim2.new(0, 200, 0, 34)
end

-- State
local tosAccepted   = false
local cooldownDone  = false
local timerRunning  = false
local unlocked      = false

local function refreshContinue()
    unlocked = tosAccepted and cooldownDone
    if unlocked then
        continueBtn.Text = "CONTINUE"
        continueBtn.TextColor3 = UNLOCKED_
        continueStroke.Color = UNLOCKED_
    else
        continueBtn.Text = "CONTINUE  (LOCKED)"
        continueBtn.TextColor3 = DIM_
        continueStroke.Color = OUTLINE_
    end
end

local function setTos(v)
    tosAccepted = v
    if v then
        tosBox.Text = "X"
        tosStroke.Color = SUCCESS_
        tosLbl.TextColor3 = FONT_
    else
        tosBox.Text = ""
        tosStroke.Color = OUTLINE_
        tosLbl.TextColor3 = DIM_
    end
    refreshContinue()
end
tosBox.MouseButton1Click:Connect(function() setTos(not tosAccepted) end)
tosLbl.MouseButton1Click:Connect(function() setTos(not tosAccepted) end)

local function bindHover(btn, stroke, hi, lo)
    btn.MouseEnter:Connect(function() stroke.Color = hi end)
    btn.MouseLeave:Connect(function() stroke.Color = lo end)
end
bindHover(copyBtn,   cbStroke,      ACCENT_, OUTLINE_)
bindHover(cancelBtn, cancelStroke,  DANGER_, OUTLINE_)

local function close()
    local drop = UDim2.fromOffset(0, 10)
    for _, btn in ipairs({ copyBtn, continueBtn, cancelBtn, tosBox, tosLbl }) do
        tween(btn, 0.16, {
            BackgroundTransparency = 1, TextTransparency = 1,
            Position = btn.Position + drop,
        })
    end
    for _, s in ipairs({ cbStroke, cancelStroke, continueStroke, tosStroke }) do
        tween(s, 0.16, { Transparency = 1 })
    end
    task.wait(0.14)
    for _, lbl in ipairs({ header, gameLbl, gate }) do
        tween(lbl, 0.12, { TextTransparency = 1 })
    end
    tween(div, 0.12, { BackgroundTransparency = 1 })
    task.wait(0.1)
    tween(pStroke, 0.22, { Transparency = 1 })
    tween(panel, 0.22, {
        Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1,
    })
    tween(dim, 0.22, { BackgroundTransparency = 1 })
    task.wait(0.26)
    pcall(function() sg:Destroy() end)
end

cancelBtn.MouseButton1Click:Connect(function() close() end)

local copyBaseText = "COPY DISCORD INVITE"

copyBtn.MouseButton1Click:Connect(function()
    local ok = safeSetClipboard(DISCORD_INVITE)
    if ok then
        copyBtn.Text = "COPIED TO CLIPBOARD"
        copyBtn.TextColor3 = SUCCESS_
        cbStroke.Color = SUCCESS_
        tween(copyBtn, 0.2, { BackgroundColor3 = Color3.fromRGB(28, 46, 34) })
        task.delay(1.6, function()
            copyBtn.Text = copyBaseText
            copyBtn.TextColor3 = FONT_
            cbStroke.Color = OUTLINE_
            tween(copyBtn, 0.2, { BackgroundColor3 = SUB_ })
        end)
    else
        copyBtn.Text = "OPEN: " .. DISCORD_INVITE
    end
    if timerRunning or cooldownDone then return end
    timerRunning = true
    task.spawn(function()
        task.wait(UNLOCK_SECS)
        cooldownDone = true
        refreshContinue()
        bindHover(continueBtn, continueStroke, UNLOCKED_, UNLOCKED_)
    end)
end)

continueBtn.MouseButton1Click:Connect(function()
    if not unlocked then return end
    if not resolved.url then
        gate.Text = 'No loader available for "' .. resolvedName .. '".'
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
            continueBtn.TextColor3 = UNLOCKED_
            return
        end
        local fn, err = loadstring(body)
        if not fn then
            gate.Text = "Compile error: " .. tostring(err):sub(1, 60)
            gate.TextColor3 = DANGER_
            return
        end
        installAuthToken()
        close()
        task.wait(0.05)
        local ok, runErr = pcall(fn)
        if not ok then warn("[ESLoader] runtime error:", runErr) end
    end)
end)

-- Open animation
panel.Size = UDim2.fromOffset(0, 0)
dim.BackgroundTransparency = 1
local openTI = TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
TweenService:Create(panel, openTI, { Size = UDim2.fromOffset(380, 260) }):Play()
tween(dim, 0.32, { BackgroundTransparency = 0.55 })
setTos(false)
refreshContinue()
