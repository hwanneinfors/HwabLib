-- HwanUI.lua
-- Finalized: tab sizing (4-tab standard), scroll when >3, selected tab highlight, SourceSansBold fonts, dropdown/slider/section, other UX tweaks

local HwanUI = {}
HwanUI.__index = HwanUI

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- Helpers: host GUI in executor-friendly place
local function getGuiParent()
    if type(gethui) == "function" then
        local ok, g = pcall(gethui)
        if ok and g then return g end
    end
    if type(get_hidden_gui) == "function" then
        local ok, g = pcall(get_hidden_gui)
        if ok and g then return g end
    end
    if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
        return LocalPlayer:FindFirstChild("PlayerGui")
    end
    return game:GetService("CoreGui")
end

local function protectGui(g)
    if syn and syn.protect_gui then
        pcall(syn.protect_gui, g)
    end
    if protect_gui then
        pcall(protect_gui, g)
    end
end

-- robust new: accepts props table OR a parent Instance
local function new(class, props)
    local inst = Instance.new(class)
    if props then
        if type(props) == "table" then
            for k,v in pairs(props) do
                pcall(function() inst[k] = v end)
            end
        else
            pcall(function() inst.Parent = props end)
        end
    end
    return inst
end

local function tween(inst, props, time, style, dir)
    time = time or 0.18
    style = style or Enum.EasingStyle.Quad
    dir = dir or Enum.EasingDirection.Out
    pcall(function()
        local info = TweenInfo.new(time, style, dir)
        TweenService:Create(inst, info, props):Play()
    end)
end

local function clamp(v,a,b) if v < a then return a end if v > b then return b end return v end
local function brightenColor(c, amt)
    amt = amt or 0.06
    return Color3.new(clamp(c.R + amt, 0, 1), clamp(c.G + amt, 0, 1), clamp(c.B + amt, 0, 1))
end
local function darkenColor(c, amt)
    amt = amt or 0.08
    return Color3.new(clamp(c.R - amt, 0, 1), clamp(c.G - amt, 0, 1), clamp(c.B - amt, 0, 1))
end

-- Clean old UI if present
if _G.HwanHubData then
    if _G.HwanHubData.conns then
        for _, c in ipairs(_G.HwanHubData.conns) do
            pcall(function()
                if c and c.Disconnect then c:Disconnect() end
                if c and c.disconnect then c:disconnect() end
            end)
        end
    end
    if _G.HwanHubData.screenGui and _G.HwanHubData.screenGui.Parent then
        pcall(function() _G.HwanHubData.screenGui:Destroy() end)
    end
    _G.HwanHubData = nil
end

-- Default config
local DEFAULT = {
    Width = 260,
    Height = 400,
    Title = "HWAN HUB",
    ShowToggleIcon = true,
    KeySystem = true,
    AccessKey = "hwandeptrai",
    KeyUrl = nil,
    Theme = {
        Main = Color3.fromRGB(18,18,18),
        TabBg = Color3.fromRGB(40,40,40),
        Accent = Color3.fromRGB(245,245,245),
        Text = Color3.fromRGB(235,235,235),
        InfoBg = Color3.fromRGB(10,10,10),
        InfoInner = Color3.fromRGB(18,18,18),
        Btn = Color3.fromRGB(50,50,50),
        ToggleBg = Color3.fromRGB(80,80,80),
    },
    Corner = UDim.new(0,12)
}

-- Create main window
function HwanUI:CreateWindow(title, opts)
    opts = opts or {}
    local cfg = {}
    for k,v in pairs(DEFAULT) do cfg[k] = v end
    if title and type(title) == "string" then cfg.Title = title end
    for k,v in pairs(opts) do
        if k == "Theme" and type(v) == "table" then
            for kk,vv in pairs(v) do cfg.Theme[kk] = vv end
        else
            cfg[k] = v
        end
    end

    local conns = {}
    local notifQueue = {}
    local notifShowing = false

    local host = getGuiParent()
    local screenGui = new("ScreenGui")
    screenGui.Name = (cfg.Title:gsub("%s+", "") or "HwanHub") .. "_GUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = host
    protectGui(screenGui)

    -- MAIN FRAME
    local Frame = new("Frame", {
        Parent = screenGui,
        Name = "Main",
        Size = UDim2.new(0, cfg.Width, 0, 0),
        Position = UDim2.new(0, 16, 0.5, -cfg.Height/2),
        BackgroundColor3 = cfg.Theme.Main,
        BorderSizePixel = 0,
        Active = true
    })
    new("UICorner", {Parent = Frame, CornerRadius = cfg.Corner})

    local frameStroke = new("UIStroke", {Parent = Frame})
    frameStroke.Thickness = 2
    frameStroke.Transparency = 0.8
    frameStroke.Color = Color3.fromRGB(255,255,255)

    -- TITLE AREA
    local TitleFrame = new("Frame", {Parent = Frame, Size = UDim2.new(1, -16, 0, 100), Position = UDim2.new(0,8,0,8), BackgroundTransparency = 1})

    -- Title label with gradient (rotating)
    local TitleMain = new("TextLabel", {
        Parent = TitleFrame,
        Size = UDim2.new(1,0,0,54),
        Position = UDim2.new(0,0,0,4),
        BackgroundTransparency = 1,
        Text = string.upper(cfg.Title),
        Font = Enum.Font.LuckiestGuy,
        TextSize = 44,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextStrokeTransparency = 0,
        TextStrokeColor3 = Color3.fromRGB(255,255,255),
        TextTransparency = 0,
        TextColor3 = cfg.Theme.Main
    })
    local titleGrad = new("UIGradient", {Parent = TitleMain})
    titleGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120,120,120)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0)),
    })
    titleGrad.Rotation = 0

    -- Tabs container (under title)
    local TabsFrame = new("Frame", {Parent = TitleFrame, Size = UDim2.new(1,0,0,36), Position = UDim2.new(0,0,0,56), BackgroundTransparency = 1})
    local TabsHolder = new("Frame", {Parent = TabsFrame, Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1})
    new("UICorner", {Parent = TabsHolder, CornerRadius = UDim.new(0,8)})

    -- Divider: place slightly lower so it doesn't overlap tabs
    local dividerY = 104 -- moved down a bit
    local divider0 = new("Frame", {Parent = Frame, Name = "Divider0", Size = UDim2.new(1,-16,0,2), Position = UDim2.new(0,8,0,dividerY), BackgroundColor3 = Color3.fromRGB(45,45,45), BorderSizePixel = 0})
    divider0.ClipsDescendants = true

    -- InfoBar
    local InfoBar = new("Frame", {Parent = screenGui, Name = "InfoBar", Size = UDim2.new(0, 360, 0, 36), Position = UDim2.new(1, -376, 0, 16), BackgroundColor3 = cfg.Theme.InfoBg, BorderSizePixel = 0, ZIndex = 50})
    new("UICorner", {Parent = InfoBar, CornerRadius = UDim.new(0,8)})
    InfoBar.BackgroundTransparency = 0.06
    local InfoInner = new("Frame", {Parent = InfoBar, Size = UDim2.new(1, -8, 1, -8), Position = UDim2.new(0,4,0,4), BackgroundColor3 = cfg.Theme.InfoInner, BorderSizePixel = 0, ZIndex = 51})
    new("UICorner", {Parent = InfoInner, CornerRadius = UDim.new(0,6)})
    local InfoText = new("TextLabel", {Parent = InfoInner, Size = UDim2.new(1,-4,1,0), Position = UDim2.new(0,2,0,0), BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, TextColor3 = cfg.Theme.Text, Text = "TIME: 00:00:00 | FPS: 0 | PING: 0 ms (0%CV)", ZIndex = 52})

    -- Floating Hwan icon/button (with rotating gradient on text)
    local HwanBtn = new("Frame", {Parent = screenGui, Name = "HwanBtn", Size = UDim2.new(0,56,0,56), Position = UDim2.new(0, 90, 0, 64), BackgroundColor3 = InfoBar.BackgroundColor3, BorderSizePixel = 0, ZIndex = 60, Active = true, Visible = (cfg.ShowToggleIcon ~= false)})
    new("UICorner", {Parent = HwanBtn, CornerRadius = UDim.new(0,10)})
    local HwanInner = new("Frame", {Parent = HwanBtn, Size = UDim2.new(1,-8,1,-8), Position = UDim2.new(0,4,0,4), BackgroundColor3 = InfoInner.BackgroundColor3, BorderSizePixel = 0, ZIndex = 61})
    new("UICorner", {Parent = HwanInner, CornerRadius = UDim.new(0,8)})
    local HwanTop = new("TextLabel", {Parent = HwanInner, Size = UDim2.new(1,0,0.4,0), Position = UDim2.new(0,0,0,7), BackgroundTransparency = 1, Font = Enum.Font.LuckiestGuy, Text = string.sub(cfg.Title,1,4):upper(), TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(255,255,255), ZIndex = 62, TextTransparency = 0, TextScaled = true})
    local HwanBottom = new("TextLabel", {Parent = HwanInner, Size = UDim2.new(1,0,0.4,0), Position = UDim2.new(0,0,0.5,5), BackgroundTransparency = 1, Font = Enum.Font.LuckiestGuy, Text = "HUB", TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(255,255,255), ZIndex = 62, TextTransparency = 0, TextScaled = true})
    local h_g_top = new("UIGradient", {Parent = HwanTop})
    h_g_top.Color = titleGrad.Color
    h_g_top.Rotation = 0
    local h_g_bottom = new("UIGradient", {Parent = HwanBottom})
    h_g_bottom.Color = titleGrad.Color
    h_g_bottom.Rotation = 0

    -- Content area
    local contentYStart = dividerY + 8
    local contentArea = new("Frame", {Parent = Frame, Size = UDim2.new(1,0,1, -contentYStart), Position = UDim2.new(0,0,0,contentYStart), BackgroundTransparency = 1})
    new("UIPadding", {Parent = contentArea, PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingTop = UDim.new(0,6), PaddingBottom = UDim.new(0,12)})
    local pages = {}
    local tabList = {}
    local darkTabText = darkenColor(cfg.Theme.Text, 0.18) -- unselected tab text color (slightly darker)

    -- Tab scroll
    local tabScroll = new("ScrollingFrame", {Parent = TabsHolder, Size = UDim2.new(1,0,1,0), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, ScrollBarThickness = 0, ScrollBarImageTransparency = 1, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.X, HorizontalScrollBarInset = Enum.ScrollBarInset.Always})
    local padding = 8
    local listLayout = new("UIListLayout", {Parent = tabScroll, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,padding), SortOrder = Enum.SortOrder.LayoutOrder})
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    -- helper to update layout: use 4-tab standard for slot width, keep that size for all tabs
    local function updateTabsLayout()
        local count = #tabList
        local avail = math.max(tabScroll.AbsoluteSize.X, cfg.Width) -- fallback
        if count == 0 then return end

        -- compute slot width using the 4-tab standard
        local fixedSlots = 4
        local totalPaddingFor4 = padding * (fixedSlots + 1)
        local slotWidth = math.floor((avail - totalPaddingFor4) / fixedSlots)
        slotWidth = clamp(slotWidth, 64, 180)

        -- apply same width to ALL tabs
        for _, t in ipairs(tabList) do
            if t and t.Button then
                t.Button.Size = UDim2.new(0, slotWidth, 0, 36)
            end
        end

        -- compute canvas size for actual number of tabs
        local totalWidth = padding * (#tabList + 1) + #tabList * slotWidth

        if #tabList > 3 then
            -- allow scrolling when more than 3 tabs
            tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
            tabScroll.CanvasSize = UDim2.new(0, totalWidth, 0, 0)
        else
            -- 3 or fewer: center them, disable scrolling
            tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
            tabScroll.CanvasSize = UDim2.new(0, math.max(totalWidth, avail), 0, 0)
            tabScroll.CanvasPosition = Vector2.new(0,0)
        end
    end

    -- call update when size changes
    table.insert(conns, tabScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() updateTabsLayout() end))

    -- drag-to-scroll and input handling (keeps previous behavior)
    do
        local dragging = false
        local dragStart = Vector2.new()
        local startCanvasX = 0
        local conn1 = tabScroll.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startCanvasX = tabScroll.CanvasPosition.X
                local endedConn
                endedConn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        if endedConn then pcall(function() endedConn:Disconnect() end) end
                    end
                end)
                table.insert(conns, endedConn)
            end
        end)
        table.insert(conns, conn1)
        local conn2 = UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                local maxX = math.max(tabScroll.AbsoluteCanvasSize.X - tabScroll.AbsoluteSize.X, 0)
                local newX = clamp(startCanvasX - delta.X, 0, maxX)
                tabScroll.CanvasPosition = Vector2.new(newX, 0)
            end
        end)
        table.insert(conns, conn2)
    end

    -- ensure selected tab visible (tween CanvasPosition)
    local function ensureTabVisible(btn)
        pcall(function()
            local btnAbs = btn.AbsolutePosition.X
            local btnW = btn.AbsoluteSize.X
            local scrollAbs = tabScroll.AbsolutePosition.X
            local scrollW = tabScroll.AbsoluteSize.X
            local curCanvas = tabScroll.CanvasPosition.X
            local target = btnAbs - scrollAbs + curCanvas - (scrollW/2 - btnW/2)
            local maxX = math.max(tabScroll.AbsoluteCanvasSize.X - tabScroll.AbsoluteSize.X, 0)
            target = clamp(target, 0, maxX)
            pcall(function()
                TweenService:Create(tabScroll, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CanvasPosition = Vector2.new(target,0)}):Play()
            end)
        end)
    end

    -- helper: create a new tab
    local function createTab(name)
        local idx = #tabList + 1
        local btn = new("TextButton", {
            Parent = tabScroll,
            Text = name,
            Size = UDim2.new(0, 96, 0, 36),
            BackgroundColor3 = cfg.Theme.TabBg,
            TextColor3 = darkTabText,
            Font = Enum.Font.SourceSansBold,
            TextSize = 18,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            AutoButtonColor = false,
            BorderSizePixel = 0
        })
        new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,10)})

        local content = new("Frame", {Parent = contentArea, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false})
        new("UIListLayout", {Parent = content, FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,10)})
        new("UIPadding", {Parent = content, PaddingLeft = UDim.new(0,6), PaddingRight = UDim.new(0,6), PaddingTop = UDim.new(0,6)})

        table.insert(pages, content)

        local tab = {Name = name, Button = btn, Content = content}

        -- hover
        local enterConn = btn.MouseEnter:Connect(function() if UserInputService.MouseEnabled then tween(btn, {BackgroundColor3 = brightenColor(cfg.Theme.TabBg, 0.06)}, 0.12) end end)
        table.insert(conns, enterConn)
        local leaveConn = btn.MouseLeave:Connect(function() if btn ~= nil then
            -- if not selected, return to base color
            if btn.TextColor3 ~= Color3.fromRGB(255,255,255) then
                tween(btn, {BackgroundColor3 = cfg.Theme.TabBg}, 0.12)
            else
                -- if selected, keep it slightly bright
                tween(btn, {BackgroundColor3 = brightenColor(cfg.Theme.TabBg, 0.08)}, 0.12)
            end
        end end)
        table.insert(conns, leaveConn)

        function tab:CreateButton(label, callback)
            local b = new("TextButton", {Parent = self.Content, Size = UDim2.new(1,0,0,36), BackgroundColor3 = cfg.Theme.Btn, TextColor3 = cfg.Theme.Text, Text = label, Font = Enum.Font.SourceSansBold, TextSize = 16, AutoButtonColor=false })
            new("UICorner", {Parent = b, CornerRadius = UDim.new(0,10)})
            local be = b.MouseEnter:Connect(function() if UserInputService.MouseEnabled then tween(b, {BackgroundColor3 = brightenColor(cfg.Theme.Btn, 0.06)}, 0.12) end end)
            table.insert(conns, be)
            local bl = b.MouseLeave:Connect(function() tween(b, {BackgroundColor3 = cfg.Theme.Btn}, 0.12) end)
            table.insert(conns, bl)
            local clickConn = b.MouseButton1Click:Connect(function()
                if callback then pcall(callback) end
                tween(b, {BackgroundColor3 = brightenColor(cfg.Theme.Btn, 0.12)}, 0.06)
                task.wait(0.06)
                tween(b, {BackgroundColor3 = cfg.Theme.Btn}, 0.12)
            end)
            table.insert(conns, clickConn)
            return b
        end

        function tab:CreateToggle(label, initial, callback)
            local frame = new("Frame", {Parent = self.Content, Size = UDim2.new(1,0,0,30), BackgroundTransparency = 1})
            local lbl = new("TextLabel", {Parent = frame, Text = label, Size = UDim2.new(1, -58, 1, 0), BackgroundTransparency = 1, TextColor3 = cfg.Theme.Text, Font = Enum.Font.SourceSansBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left})
            local toggleBg = new("Frame", {Parent = frame, Size = UDim2.new(0,46,0,26), Position = UDim2.new(1, -50, 0.5, -13), BackgroundColor3 = cfg.Theme.ToggleBg, BorderSizePixel = 0})
            new("UICorner", {Parent = toggleBg, CornerRadius = UDim.new(0,12)})
            -- dot colors: OFF should be darker, ON should be brighter
            local dotOffColor = darkenColor(Color3.fromRGB(200,200,200), 0.16) -- darker when OFF
            local dotOnColor  = Color3.fromRGB(230,230,230) -- brighter when ON
            local dot = new("Frame", {Parent = toggleBg, Size = UDim2.new(0,18,0,18), Position = UDim2.new(0,4,0.5,-9), BackgroundColor3 = dotOffColor})
            new("UICorner", {Parent = dot, CornerRadius = UDim.new(1,0)})

            local state = initial and true or false
            local function setState(s, silent)
                state = s
                if s then
                    tween(dot, {Position = UDim2.new(1, -22, 0.5, -9), BackgroundColor3 = dotOnColor}, 0.12)
                else
                    tween(dot, {Position = UDim2.new(0,4,0.5,-9), BackgroundColor3 = dotOffColor}, 0.12)
                end
                if callback and not silent then pcall(callback, state) end
            end

            local clickBtn = new("TextButton", {Parent = toggleBg, Size = UDim2.new(1,0,1,0), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, AutoButtonColor = false, Text = ""})
            new("UICorner", {Parent = clickBtn, CornerRadius = UDim.new(0,12)})
            local toggleConn = clickBtn.MouseButton1Click:Connect(function() setState(not state) end)
            table.insert(conns, toggleConn)
            setState(state, true)
            return {Get = function() return state end, Set = function(v) setState((v and true) or false) end, UI = frame}
        end

        function tab:CreateLabel(text)
            local l = new("TextLabel", {Parent = self.Content, Size = UDim2.new(1,0,0,20), Text = text, BackgroundTransparency = 1, TextColor3 = cfg.Theme.Text, Font = Enum.Font.SourceSansBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
            return l
        end

        -- Section: a subtle labeled divider (visual grouping)
        function tab:CreateSection(title)
            local sec = new("Frame", {Parent = self.Content, Size = UDim2.new(1,0,0,40), BackgroundTransparency = 1})
            local bg = new("Frame", {Parent = sec, Size = UDim2.new(1,0,0,32), Position = UDim2.new(0,0,0,4), BackgroundColor3 = Color3.fromRGB(28,28,28), BorderSizePixel = 0})
            new("UICorner", {Parent = bg, CornerRadius = UDim.new(0,8)})
            local lbl = new("TextLabel", {Parent = bg, Text = title, Size = UDim2.new(1,-12,1,0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold, TextSize = 15, TextColor3 = cfg.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left})
            return sec
        end

        -- Dropdown: opens a side-panel (floating) next to main GUI
        function tab:CreateDropdown(label, options, callback)
            options = options or {}
            local frame = new("Frame", {Parent = self.Content, Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1})
            local lbl = new("TextLabel", {Parent = frame, Text = label, Size = UDim2.new(1, -120, 1, 0), BackgroundTransparency = 1, TextColor3 = cfg.Theme.Text, Font = Enum.Font.SourceSansBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left})
            local btn = new("TextButton", {Parent = frame, Size = UDim2.new(0, 112, 0, 28), Position = UDim2.new(1, -116, 0.5, -14), BackgroundColor3 = cfg.Theme.Btn, Text = "Select", Font = Enum.Font.SourceSansBold, TextSize = 14, TextColor3 = cfg.Theme.Text, AutoButtonColor = false})
            new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,8)})

            -- create panel (hidden) parented to screenGui so it can be placed beside main
            local panel
            local function showPanel()
                if panel and panel.Parent then panel:Destroy() end
                panel = new("Frame", {Parent = screenGui, Size = UDim2.new(0,180,0, 24 + #options*32), BackgroundColor3 = cfg.Theme.InfoInner, ZIndex = 200})
                new("UICorner", {Parent = panel, CornerRadius = UDim.new(0,8)})
                -- position panel to the right of Frame (main)
                pcall(function()
                    local absX = Frame.AbsolutePosition.X
                    local absY = Frame.AbsolutePosition.Y
                    local x = absX + Frame.AbsoluteSize.X + 8
                    local y = absY + (TitleFrame.AbsoluteSize.Y or 0) + 8
                    panel.Position = UDim2.new(0, x, 0, y)
                end)
                for i, opt in ipairs(options) do
                    local row = new("TextButton", {Parent = panel, Size = UDim2.new(1, -12, 0, 28), Position = UDim2.new(0,6,0, 8 + (i-1)*32), BackgroundColor3 = cfg.Theme.InfoInner, Text = tostring(opt), Font = Enum.Font.SourceSansBold, TextSize = 15, TextColor3 = cfg.Theme.Text, AutoButtonColor = false})
                    new("UICorner", {Parent = row, CornerRadius = UDim.new(0,6)})
                    row.MouseEnter:Connect(function() tween(row, {BackgroundColor3 = brightenColor(cfg.Theme.InfoInner, 0.06)}, 0.12) end)
                    row.MouseLeave:Connect(function() tween(row, {BackgroundColor3 = cfg.Theme.InfoInner}, 0.12) end)
                    row.MouseButton1Click:Connect(function()
                        if callback then pcall(callback, opt) end
                        btn.Text = tostring(opt)
                        pcall(function() panel:Destroy() end)
                    end)
                end
            end

            local openConn = btn.MouseButton1Click:Connect(function()
                showPanel()
            end)
            table.insert(conns, openConn)

            return {UI = frame, Set = function(v) btn.Text = tostring(v) end}
        end

        -- Slider: basic horizontal slider with drag and callback (value in [min,max])
        function tab:CreateSlider(label, minVal, maxVal, default, callback)
            minVal = minVal or 0; maxVal = maxVal or 100; default = default or minVal
            local frame = new("Frame", {Parent = self.Content, Size = UDim2.new(1,0,0,40), BackgroundTransparency = 1})
            local lbl = new("TextLabel", {Parent = frame, Text = label, Size = UDim2.new(1, -12, 0, 14), Position = UDim2.new(0,6,0,0), BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold, TextSize = 14, TextColor3 = cfg.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left})
            local barBg = new("Frame", {Parent = frame, Size = UDim2.new(1,-24,0,12), Position = UDim2.new(0,12,0,20), BackgroundColor3 = cfg.Theme.ToggleBg, BorderSizePixel = 0})
            new("UICorner", {Parent = barBg, CornerRadius = UDim.new(0,6)})
            local fill = new("Frame", {Parent = barBg, Size = UDim2.new(0,0,1,0), Position = UDim2.new(0,0,0,0), BackgroundColor3 = brightenColor(cfg.Theme.Btn, 0.08)})
            new("UICorner", {Parent = fill, CornerRadius = UDim.new(0,6)})
            local knob = new("Frame", {Parent = barBg, Size = UDim2.new(0,14,0,14), Position = UDim2.new(0, -7, 0.5, -7), BackgroundColor3 = Color3.fromRGB(240,240,240)})
            new("UICorner", {Parent = knob, CornerRadius = UDim.new(1,0)})

            local function setValueFromPercent(p)
                p = clamp(p, 0, 1)
                fill.Size = UDim2.new(p,0,1,0)
                knob.Position = UDim2.new(p, -7, 0.5, -7)
                local value = minVal + (maxVal - minVal) * p
                if callback then pcall(callback, value) end
            end

            -- init default
            local defaultPct = (default - minVal) / math.max(1, (maxVal - minVal))
            setValueFromPercent(defaultPct)

            -- dragging logic
            local dragging = false
            knob.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then dragging = false end
                    end)
                end
            end)
            local moveConn
            moveConn = UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local absX = input.Position.X
                    local left = barBg.AbsolutePosition.X
                    local width = barBg.AbsoluteSize.X
                    local pct = (absX - left) / math.max(1, width)
                    setValueFromPercent(pct)
                end
            end)
            table.insert(conns, moveConn)

            return {UI = frame, Set = function(v) local p = (v - minVal) / (maxVal - minVal); setValueFromPercent(p) end}
        end

        table.insert(tabList, tab)
        -- update layout when new tab added
        updateTabsLayout()

        local clickConn = btn.MouseButton1Click:Connect(function()
            for _,t in ipairs(tabList) do
                t.Content.Visible = false
                tween(t.Button, {BackgroundColor3 = cfg.Theme.TabBg}, 0.12)
                if t.Button then t.Button.TextColor3 = darkTabText end
            end
            tab.Content.Visible = true
            tween(tab.Button, {BackgroundColor3 = brightenColor(cfg.Theme.TabBg, 0.08)}, 0.12)
            tab.Button.TextColor3 = Color3.fromRGB(255,255,255)
            -- ensure visible when scrolled
            ensureTabVisible(tab.Button)
        end)
        table.insert(conns, clickConn)

        -- auto-activate first tab
        if #tabList == 1 then
            tab.Content.Visible = true
            tween(tab.Button, {BackgroundColor3 = brightenColor(cfg.Theme.TabBg, 0.08)}, 0.12)
            tab.Button.TextColor3 = Color3.fromRGB(255,255,255)
        end

        return tab
    end

    -- Make Frame, InfoBar, HwanBtn draggable
    local function makeDraggable(gui, handle)
        handle = handle or gui
        pcall(function() handle.Active = true end)
        local dragging, dragInput, dragStart, startPos
        local c1 = handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = gui.Position
                local endedConn
                endedConn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        if endedConn then pcall(function() endedConn:Disconnect() end) end
                    end
                end)
                table.insert(conns, endedConn)
            end
        end)
        table.insert(conns, c1)
        local c2 = handle.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        table.insert(conns, c2)
        local c3 = UserInputService.InputChanged:Connect(function(input)
            if dragging and input == dragInput then
                local delta = input.Position - dragStart
                gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        table.insert(conns, c3)
    end

    makeDraggable(Frame)
    makeDraggable(InfoBar)
    makeDraggable(HwanBtn)

    -- HwanBtn click toggles main visibility
    local visible = true
    local hwanConn = HwanBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            visible = not visible
            Frame.Visible = visible
            pcall(function()
                tween(HwanInner, {Size = UDim2.new(1,-6,1,-6)}, 0.12)
                task.wait(0.12)
                tween(HwanInner, {Size = UDim2.new(1,-8,1,-8)}, 0.12)
            end)
        end
    end)
    table.insert(conns, hwanConn)

    -- Hotkey LeftAlt toggle
    local altConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.LeftAlt then
            visible = not visible
            Frame.Visible = visible
            if not visible then
                for _, t in ipairs(tabList) do if t and t.Content then t.Content.Visible = false end end
            end
        end
    end)
    table.insert(conns, altConn)

    -- InfoBar update & rotate gradients for title/icon
    local pingSamples = {}
    local maxPingSamples = 30
    local pingTimer = 0
    local pingInterval = 0.25
    local renderConn = RunService.RenderStepped:Connect(function(dt)
        -- rotate gradients
        if titleGrad then titleGrad.Rotation = (titleGrad.Rotation + 0.9) % 360 end
        if h_g_top then h_g_top.Rotation = (h_g_top.Rotation + 1.2) % 360 end
        if h_g_bottom then h_g_bottom.Rotation = (h_g_bottom.Rotation + 1.2) % 360 end

        local timeStr = os.date("%H:%M:%S")
        local fps = 0
        if dt > 0 then fps = math.floor(1/dt + 0.5) end

        pingTimer = pingTimer + dt
        local pingMs = 0
        if pingTimer >= pingInterval then
            pingTimer = pingTimer - pingInterval
            local ok, pingValue = pcall(function() return game:GetService("Stats").Network.ServerStatsItem["Data Ping"] end)
            if ok and pingValue and typeof(pingValue.GetValueString) == "function" then
                local ok2, str = pcall(function() return pingValue:GetValueString() end)
                if ok2 and str then pingMs = tonumber(str:match("%d+")) or 0 end
            end
            table.insert(pingSamples, pingMs)
            if #pingSamples > maxPingSamples then table.remove(pingSamples, 1) end
        else
            if #pingSamples > 0 then pingMs = pingSamples[#pingSamples] end
        end

        local mean, std = 0, 0
        if #pingSamples > 0 then
            local sum = 0
            for _, v in ipairs(pingSamples) do sum = sum + v end
            mean = sum / #pingSamples
            local sqsum = 0
            for _, v in ipairs(pingSamples) do sqsum = sqsum + (v - mean) * (v - mean) end
            std = math.sqrt(sqsum / #pingSamples)
        end
        local cvPercent = 0
        if mean > 0 then cvPercent = math.floor((std / mean) * 100 + 0.5) end

        InfoText.Text = string.format("TIME : %s   |   FPS: %d   |   PING: %d ms (%d%%CV)", timeStr, fps, pingMs, cvPercent)
    end)
    table.insert(conns, renderConn)

    -- open tween
    local finalSize = UDim2.new(0, cfg.Width, 0, cfg.Height)
    local openTween = TweenService:Create(Frame, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = finalSize})

    -- Notifications
    local function processNextNotification()
        if notifShowing then return end
        local text = table.remove(notifQueue, 1)
        if not text then return end
        notifShowing = true

        local notif = new("Frame", {Parent = screenGui, Size = UDim2.new(0, 240, 0, 64), Position = UDim2.new(1, -260, 1, -96), BackgroundColor3 = InfoInner.BackgroundColor3, BorderSizePixel = 0, ZIndex = 120})
        new("UICorner", {Parent = notif, CornerRadius = UDim.new(0,8)})
        local header = new("TextLabel", {Parent = notif, Size = UDim2.new(1, -12, 0, 26), Position = UDim2.new(0,10,0,10), BackgroundTransparency = 1, Font = TitleMain.Font, TextSize = 20, Text = cfg.Title, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = cfg.Theme.Text, ZIndex = 121})
        local body = new("TextLabel", {Parent = notif, Size = UDim2.new(1, -12, 0, 26), Position = UDim2.new(0,10,0,32), BackgroundTransparency = 1, Font = Enum.Font.SourceSans, TextSize = 17, Text = text, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = cfg.Theme.Text, ZIndex = 121})
        notif.BackgroundTransparency = 1
        header.TextTransparency = 1
        body.TextTransparency = 1

        local inTween = TweenService:Create(notif, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
        local hTween = TweenService:Create(header, TweenInfo.new(0.12), {TextTransparency = 0})
        local bTween = TweenService:Create(body, TweenInfo.new(0.12), {TextTransparency = 0})
        inTween:Play(); hTween:Play(); bTween:Play()

        task.delay(1.5, function()
            local outTween = TweenService:Create(notif, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
            local hOut = TweenService:Create(header, TweenInfo.new(0.12), {TextTransparency = 1})
            local bOut = TweenService:Create(body, TweenInfo.new(0.12), {TextTransparency = 1})
            outTween:Play(); hOut:Play(); bOut:Play()
            outTween.Completed:Wait()
            pcall(function() notif:Destroy() end)
            notifShowing = false
            processNextNotification()
        end)
    end

    local function showNotification(text)
        table.insert(notifQueue, text)
        processNextNotification()
    end

    -- Key system
    local function createKeyUI(onAuth)
        local kFrame = new("Frame", {Parent = screenGui, Name = "KeyPrompt", Size = UDim2.new(0, 460, 0, 140), Position = UDim2.new(0.5, -230, 0.38, -70), BackgroundColor3 = cfg.Theme.Main, BorderSizePixel = 0, ZIndex = 100, Active = true})
        new("UICorner", {Parent = kFrame, CornerRadius = UDim.new(0,10)})
        local titleLbl = new("TextLabel", {Parent = kFrame, Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0,10,0,8), BackgroundTransparency = 1, Font = Enum.Font.FredokaOne, TextSize = 18, Text = cfg.Title .. " | Key System", TextColor3 = cfg.Theme.Text, TextXAlignment = Enum.TextXAlignment.Center})
        local inputBox = new("TextBox", {Parent = kFrame, Size = UDim2.new(1, -40, 0, 36), Position = UDim2.new(0,20,0,48), PlaceholderText = "Enter your key here!", Font = Enum.Font.SourceSans, TextSize = 18, Text = "", ClearTextOnFocus = false, BackgroundColor3 = cfg.Theme.ToggleBg, TextColor3 = cfg.Theme.Text, BorderSizePixel = 0})
        new("UICorner", {Parent = inputBox, CornerRadius = UDim.new(0,6)})
        new("UIPadding", {Parent = inputBox, PaddingLeft = UDim.new(0,12), PaddingRight = UDim.new(0,10)})

        local getBtn = new("TextButton", {Parent = kFrame, Size = UDim2.new(0,120,0,36), Position = UDim2.new(0.5, -130, 0, 96), BackgroundColor3 = cfg.Theme.Btn, Font = Enum.Font.FredokaOne, TextSize = 16, Text = "Get key", TextColor3 = cfg.Theme.Text})
        new("UICorner", {Parent = getBtn, CornerRadius = UDim.new(0,6)})
        local checkBtn = new("TextButton", {Parent = kFrame, Size = UDim2.new(0,120,0,36), Position = UDim2.new(0.5, 10, 0, 96), BackgroundColor3 = cfg.Theme.Btn, Font = Enum.Font.FredokaOne, TextSize = 16, Text = "Check Key", TextColor3 = cfg.Theme.Text})
        new("UICorner", {Parent = checkBtn, CornerRadius = UDim.new(0,6)})
        local msg = new("TextLabel", {Parent = kFrame, Size = UDim2.new(1, -20, 0, 18), Position = UDim2.new(0,10,1, -22), BackgroundTransparency = 1, Font = Enum.Font.SourceSans, TextSize = 14, Text = "", TextColor3 = Color3.fromRGB(200,200,200), TextXAlignment = Enum.TextXAlignment.Center})

        local function tryKey(key)
            if key and type(key) == "string" and string.lower(key) == string.lower(cfg.AccessKey or "") then
                showNotification("Valid Key!")
                onAuth()
                pcall(function() kFrame:Destroy() end)
            else
                showNotification("Invalid Key!")
                pcall(function() inputBox.Text = "" end)
            end
        end

        local checkConn = checkBtn.MouseButton1Click:Connect(function() tryKey(inputBox.Text) end)
        table.insert(conns, checkConn)
        local getConn = getBtn.MouseButton1Click:Connect(function()
            pcall(function()
                if cfg.KeyUrl and setclipboard then
                    setclipboard(cfg.KeyUrl)
                elseif setclipboard then
                    setclipboard("https://facebook.com/hwanthichhat")
                end
            end)
            showNotification("Copied to clipboard!")
        end)
        table.insert(conns, getConn)
        local focusConn = inputBox.FocusLost:Connect(function(enter) if enter then tryKey(inputBox.Text) end end)
        table.insert(conns, focusConn)

        makeDraggable(kFrame)
    end

    -- public API
    local window = {}
    window.Root = screenGui
    window.Main = Frame
    window._config = cfg
    function window:CreateTab(name) return createTab(name) end
    function window:Notify(text) showNotification(text) end
    function window:Center() Frame.Position = UDim2.new(0, 16, 0.5, -cfg.Height/2) end
    function window:SetVisible(v) Frame.Visible = v end
    function window:Destroy()
        for _, c in ipairs(conns) do
            pcall(function()
                if c and c.Disconnect then c:Disconnect()
                elseif c and c.disconnect then c:disconnect()
                end
            end)
        end
        pcall(function() screenGui:Destroy() end)
        _G.HwanHubData = nil
    end

    _G.HwanHubData = { screenGui = screenGui, conns = conns, auth = false }

    -- show/hide and key handling
    task.spawn(function()
        if cfg.KeySystem then
            Frame.Visible = false
            HwanBtn.Visible = false
            createKeyUI(function()
                _G.HwanHubData.auth = true
                Frame.Visible = true
                HwanBtn.Visible = (cfg.ShowToggleIcon ~= false)
                openTween:Play()
                showNotification("Welcome to " .. (cfg.Title or "Hwan Hub"))
            end)
        else
            _G.HwanHubData.auth = true
            Frame.Visible = true
            HwanBtn.Visible = (cfg.ShowToggleIcon ~= false)
            task.wait(0.06)
            openTween:Play()
        end
    end)

    return window
end

return HwanUI
