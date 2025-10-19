-- HwanUI.lua (fixed)
local HwanUI = {}
HwanUI.__index = HwanUI

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- Helpers
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
    if syn and syn.protect_gui then pcall(syn.protect_gui, g) end
    if protect_gui then pcall(protect_gui, g) end
end

local function new(class, props)
    local inst = Instance.new(class)
    if props then
        if type(props) == "table" then
            for k,v in pairs(props) do pcall(function() inst[k] = v end) end
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
local function brightenColor(c, amt) amt = amt or 0.06; return Color3.new(clamp(c.R+amt,0,1),clamp(c.G+amt,0,1),clamp(c.B+amt,0,1)) end
local function darkenColor(c, amt) amt = amt or 0.08; return Color3.new(clamp(c.R-amt,0,1),clamp(c.G-amt,0,1),clamp(c.B-amt,0,1)) end

-- Cleanup prior
if _G.HwanHubData then
    if _G.HwanHubData.conns then
        for _,c in ipairs(_G.HwanHubData.conns) do
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

local DEFAULT = {
    Width = 260,
    Height = 400,
    Title = "HWAN HUB",
    ShowToggleIcon = true,
    KeySystem = false,
    AccessKey = "hwandeptrai",
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
    Corner = UDim.new(0,12),
    ToggleKey = Enum.KeyCode.LeftAlt,
    TweenStyle = Enum.EasingStyle.Quad,
    TweenDir = Enum.EasingDirection.Out,
}

-- simple incremental id generator (safer than random collisions)
local _uid = 0
local function nextId()
    _uid = _uid + 1
    return tostring(_uid)
end

function HwanUI:CreateWindow(title, opts)
    opts = opts or {}
    local cfg = {}
    for k,v in pairs(DEFAULT) do
        if type(v) == "table" then
            cfg[k] = {}
            for kk,vv in pairs(v) do cfg[k][kk] = vv end
        else
            cfg[k] = v
        end
    end
    if title and type(title) == "string" then cfg.Title = title end
    for k,v in pairs(opts) do
        if k == "Theme" and type(v) == "table" then
            for kk,vv in pairs(v) do cfg.Theme[kk] = vv end
        else
            cfg[k] = v
        end
    end

    local conns = {}
    local host = getGuiParent()
    local screenGui = new("ScreenGui")
    screenGui.Name = (cfg.Title:gsub("%s+","") or "HwanHub") .. "_GUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = host
    protectGui(screenGui)

    -- state for dropdowns to restore on show/hide
    local dropdownStates = {}

    -- preventWindowDrag implemented as a counter (safer for nested interactions)
    local preventWindowDragCount = 0
    local function pushPreventWindowDrag()
        preventWindowDragCount = preventWindowDragCount + 1
    end
    local function popPreventWindowDrag()
        preventWindowDragCount = math.max(0, preventWindowDragCount - 1)
    end
    local function isPreventWindowDrag()
        return preventWindowDragCount > 0
    end

    -- MAIN FRAME
    local Frame = new("Frame", {
        Parent = screenGui,
        Name = "Main",
        Size = UDim2.new(0, cfg.Width, 0, 0),
        Position = UDim2.new(0, 16, 0.5, -cfg.Height/2),
        BackgroundColor3 = cfg.Theme.Main,
        BorderSizePixel = 0,
        Active = true,
        ZIndex = 10,
    })
    new("UICorner", {Parent = Frame, CornerRadius = cfg.Corner})
    local frameStroke = new("UIStroke", {Parent = Frame})
    frameStroke.Thickness = 2; frameStroke.Transparency = 0.85; frameStroke.Color = Color3.fromRGB(20,20,20)

    -- Title area
    local TitleFrame = new("Frame", {Parent = Frame, Size = UDim2.new(1, -16, 0, 96), Position = UDim2.new(0,8,0,8), BackgroundTransparency = 1})
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
        TextColor3 = cfg.Theme.Accent,
        ZIndex = 11,
    })
    local titleGrad = new("UIGradient", {Parent = TitleMain})
    titleGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120,120,120)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0))})
    titleGrad.Rotation = 0
    local titleStroke = new("UIStroke", {Parent = TitleMain}); titleStroke.Thickness = 2; titleStroke.Color = Color3.fromRGB(12,12,12)

    -- Tabs
    local TabsFrame = new("Frame", {Parent = TitleFrame, Size = UDim2.new(1,0,0,36), Position = UDim2.new(0,0,0,56), BackgroundTransparency = 1})
    local TabsHolder = new("Frame", {Parent = TabsFrame, Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1})
    new("UICorner", {Parent = TabsHolder, CornerRadius = UDim.new(0,8)})

    -- Divider0 (moved down a little)
    local dividerY = 100 -- nhích xuống 4px so với 96
    local divider0 = new("Frame", {Parent = Frame, Name = "Divider0", Size = UDim2.new(1,-16,0,2), Position = UDim2.new(0,8,0,dividerY), BackgroundColor3 = Color3.fromRGB(45,45,45), BorderSizePixel = 0})
    divider0.ClipsDescendants = true

    -- InfoBar & toggle icon (restore previous compact icon look)
    local InfoBar = new("Frame", {Parent = screenGui, Name = "InfoBar", Size = UDim2.new(0, 360, 0, 36), Position = UDim2.new(1, -376, 0, 16), BackgroundColor3 = cfg.Theme.InfoBg, BorderSizePixel = 0, ZIndex = 50})
    new("UICorner", {Parent = InfoBar, CornerRadius = UDim.new(0,8)})
    InfoBar.BackgroundTransparency = 0.06
    local InfoInner = new("Frame", {Parent = InfoBar, Size = UDim2.new(1, -8, 1, -8), Position = UDim2.new(0,4,0,4), BackgroundColor3 = cfg.Theme.InfoInner, BorderSizePixel = 0, ZIndex = 51})
    new("UICorner", {Parent = InfoInner, CornerRadius = UDim.new(0,6)})
    local InfoText = new("TextLabel", {Parent = InfoInner, Size = UDim2.new(1,-4,1,0), Position = UDim2.new(0,2,0,0), BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, TextColor3 = cfg.Theme.Text, ZIndex = 52})

    -- Toggle icon: restore original compact design (small square)
    local HwanBtn = new("TextButton", {Parent = screenGui, Name = "HwanBtn", Size = UDim2.new(0,56,0,56), Position = UDim2.new(0, 90, 0, 64), BackgroundColor3 = InfoBar.BackgroundColor3, BorderSizePixel = 0, ZIndex = 60, Active = true, Visible = (cfg.ShowToggleIcon ~= false)})
    new("UICorner", {Parent = HwanBtn, CornerRadius = UDim.new(0,10)})
    HwanBtn.AutoButtonColor = false
    local HwanInner = new("Frame", {Parent = HwanBtn, Size = UDim2.new(1,-8,1,-8), Position = UDim2.new(0,4,0,4), BackgroundColor3 = InfoInner.BackgroundColor3, BorderSizePixel = 0, ZIndex = 61})
    new("UICorner", {Parent = HwanInner, CornerRadius = UDim.new(0,8)})
    local HwanTop = new("TextLabel", {Parent = HwanInner, Size = UDim2.new(1,0,0.45,0), Position = UDim2.new(0,0,0,6), BackgroundTransparency = 1, Font = Enum.Font.LuckiestGuy, Text = string.sub(cfg.Title,1,4):upper(), TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(255,255,255), ZIndex = 62, TextColor3 = cfg.Theme.Accent})
    local HwanBottom = new("TextLabel", {Parent = HwanInner, Size = UDim2.new(1,0,0.45,0), Position = UDim2.new(0,0,0.55,0), BackgroundTransparency = 1, Font = Enum.Font.LuckiestGuy, Text = "HUB", TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(255,255,255), ZIndex = 62, TextColor3 = cfg.Theme.Accent})

    -- Content area
    local contentYStart = dividerY + 8
    local contentArea = new("Frame", {Parent = Frame, Size = UDim2.new(1,0,1, -contentYStart), Position = UDim2.new(0,0,0,contentYStart), BackgroundTransparency = 1})
    new("UIPadding", {Parent = contentArea, PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingTop = UDim.new(0,6), PaddingBottom = UDim.new(0,12)})
    local pages = {}
    local tabList = {}
    local darkTabText = darkenColor(cfg.Theme.Text, 0.18)

    -- Tab scrolling
    local tabScroll = new("ScrollingFrame", {Parent = TabsHolder, Size = UDim2.new(1,0,1,0), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, ScrollBarThickness = 0, ScrollBarImageTransparency = 1, AutomaticCanvasSize = Enum.AutomaticSize.X})
    local padding = 8
    local listLayout = new("UIListLayout", {Parent = tabScroll, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,padding), SortOrder = Enum.SortOrder.LayoutOrder})
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    -- layout helper (4-tab standard)
    local function updateTabsLayout()
        local count = #tabList
        local avail = math.max(tabScroll.AbsoluteSize.X, cfg.Width)
        if count == 0 then return end
        local fixedSlots = 4
        local totalPaddingFor4 = padding * (fixedSlots + 1)
        local slotWidth = math.floor((avail - totalPaddingFor4) / fixedSlots)
        slotWidth = clamp(slotWidth, 64, 180)
        for _,t in ipairs(tabList) do
            if t and t.Button then t.Button.Size = UDim2.new(0, slotWidth, 0, 36) end
        end
        local totalWidth = padding * (#tabList + 1) + #tabList * slotWidth
        if #tabList > 3 then
            tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
            tabScroll.CanvasSize = UDim2.new(0, totalWidth, 0, 0)
        else
            tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
            tabScroll.CanvasSize = UDim2.new(0, math.max(totalWidth, avail), 0, 0)
            tabScroll.CanvasPosition = Vector2.new(0,0)
        end
    end
    table.insert(conns, tabScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateTabsLayout))
    task.defer(updateTabsLayout)

    -- drag-to-scroll for tab bar
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
            tween(tabScroll, {CanvasPosition = Vector2.new(target,0)}, 0.22, cfg.TweenStyle, cfg.TweenDir)
        end)
    end

    -- left label & right control layout
    local LABEL_WIDTH = 0.40
    local CONTROL_WIDTH = 0.56

    -- create tab
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

        local enterConn = btn.MouseEnter:Connect(function() if UserInputService.MouseEnabled then tween(btn, {BackgroundColor3 = brightenColor(cfg.Theme.TabBg, 0.06)}, 0.12, cfg.TweenStyle, cfg.TweenDir) end end)
        table.insert(conns, enterConn)
        local leaveConn = btn.MouseLeave:Connect(function() if btn then if btn.TextColor3 ~= Color3.fromRGB(255,255,255) then tween(btn, {BackgroundColor3 = cfg.Theme.TabBg}, 0.12, cfg.TweenStyle, cfg.TweenDir) else tween(btn, {BackgroundColor3 = brightenColor(cfg.Theme.TabBg, 0.08)}, 0.12, cfg.TweenStyle, cfg.TweenDir) end end end)
        table.insert(conns, leaveConn)

        -- CreateButton (label left, control right)
        function tab:CreateButton(label, callback)
            local row = new("Frame", {Parent = self.Content, Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1})
            local lbl = new("TextLabel", {Parent = row, Text = label, Size = UDim2.new(LABEL_WIDTH, -8, 1, 0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, TextColor3 = cfg.Theme.Text, Font = Enum.Font.SourceSansBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left})
            local b = new("TextButton", {Parent = row, Size = UDim2.new(CONTROL_WIDTH, -8, 1, 0), Position = UDim2.new(LABEL_WIDTH, 4, 0, 0), BackgroundColor3 = cfg.Theme.Btn, Text = label, Font = Enum.Font.SourceSansBold, TextSize = 14, TextColor3 = cfg.Theme.Text, AutoButtonColor=false})
            new("UICorner", {Parent = b, CornerRadius = UDim.new(0,8)})
            b.TextTruncate = Enum.TextTruncate.AtEnd
            b.TextXAlignment = Enum.TextXAlignment.Center
            b.TextYAlignment = Enum.TextYAlignment.Center
            b.TextWrapped = false
            local be = b.MouseEnter:Connect(function() if UserInputService.MouseEnabled then tween(b, {BackgroundColor3 = brightenColor(cfg.Theme.Btn, 0.06)}, 0.12, cfg.TweenStyle, cfg.TweenDir) end end)
            table.insert(conns, be)
            local bl = b.MouseLeave:Connect(function() tween(b, {BackgroundColor3 = cfg.Theme.Btn}, 0.12, cfg.TweenStyle, cfg.TweenDir) end)
            table.insert(conns, bl)
            local clickConn = b.MouseButton1Click:Connect(function()
                if callback then pcall(callback) end
                tween(b, {BackgroundColor3 = brightenColor(cfg.Theme.Btn, 0.12)}, 0.06, cfg.TweenStyle, cfg.TweenDir)
                task.wait(0.06)
                tween(b, {BackgroundColor3 = cfg.Theme.Btn}, 0.12, cfg.TweenStyle, cfg.TweenDir)
            end)
            table.insert(conns, clickConn)
            return b
        end

        -- CreateToggle: make it compact like old shorter width
        function tab:CreateToggle(label, initial, callback)
            local frame = new("Frame", {Parent = self.Content, Size = UDim2.new(1,0,0,30), BackgroundTransparency = 1})
            local lbl = new("TextLabel", {Parent = frame, Text = label, Size = UDim2.new(LABEL_WIDTH, -8, 1, 0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, TextColor3 = cfg.Theme.Text, Font = Enum.Font.SourceSansBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left})
            local toggleBg = new("Frame", {Parent = frame, Size = UDim2.new(CONTROL_WIDTH, -8,0,26), Position = UDim2.new(LABEL_WIDTH, 4, 0.5, -13), BackgroundColor3 = cfg.Theme.ToggleBg, BorderSizePixel = 0})
            new("UICorner", {Parent = toggleBg, CornerRadius = UDim.new(0,12)})
            toggleBg.Active = true
            local dotOffColor = darkenColor(Color3.fromRGB(200,200,200), 0.16)
            local dotOnColor  = Color3.fromRGB(230,230,230)
            local dot = new("Frame", {Parent = toggleBg, Size = UDim2.new(0,18,0,18), Position = UDim2.new(0,4,0.5,-9), BackgroundColor3 = dotOffColor})
            new("UICorner", {Parent = dot, CornerRadius = UDim.new(1,0)})
            local state = initial and true or false
            local function setState(s, silent)
                state = s
                if s then
                    tween(dot, {Position = UDim2.new(1, -22, 0.5, -9), BackgroundColor3 = dotOnColor}, 0.12, cfg.TweenStyle, cfg.TweenDir)
                else
                    tween(dot, {Position = UDim2.new(0,4,0.5,-9), BackgroundColor3 = dotOffColor}, 0.12, cfg.TweenStyle, cfg.TweenDir)
                end
                if callback and not silent then pcall(callback, state) end
            end
            local clickBtn = new("TextButton", {Parent = toggleBg, Size = UDim2.new(1,0,1,0), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, AutoButtonColor = false, Text = ""})
            local toggleConn = clickBtn.MouseButton1Click:Connect(function() setState(not state) end)
            table.insert(conns, toggleConn)
            setState(state, true)
            return {Get = function() return state end, Set = function(v) setState((v and true) or false) end, UI = frame}
        end

        -- Label
        function tab:CreateLabel(text)
            local l = new("TextLabel", {Parent = self.Content, Size = UDim2.new(1,0,0,20), Text = text, BackgroundTransparency = 1, TextColor3 = cfg.Theme.Text, Font = Enum.Font.SourceSansBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
            return l
        end

        -- Section
        function tab:CreateSection(title)
            local sec = new("Frame", {Parent = self.Content, Size = UDim2.new(1,0,0,40), BackgroundTransparency = 1})
            local bg = new("Frame", {Parent = sec, Size = UDim2.new(1,0,0,32), Position = UDim2.new(0,0,0,4), BackgroundColor3 = Color3.fromRGB(28,28,28), BorderSizePixel = 0})
            new("UICorner", {Parent = bg, CornerRadius = UDim.new(0,8)})
            local lbl = new("TextLabel", {Parent = bg, Text = title, Size = UDim2.new(1,-12,1,0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold, TextSize = 15, TextColor3 = cfg.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left})
            return sec
        end

        -- Dropdown: label left, button right, panel toggles; panel has border & same style
        function tab:CreateDropdown(label, options, callback)
            options = options or {}
            local id = nextId()
            dropdownStates[id] = dropdownStates[id] or {open = false, selection = nil, options = options}

            local frame = new("Frame", {Parent = self.Content, Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1})
            local lbl = new("TextLabel", {Parent = frame, Text = label, Size = UDim2.new(LABEL_WIDTH, -8, 1, 0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, TextColor3 = cfg.Theme.Text, Font = Enum.Font.SourceSansBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left})
            local btn = new("TextButton", {Parent = frame, Size = UDim2.new(CONTROL_WIDTH, -8, 1, 0), Position = UDim2.new(LABEL_WIDTH, 4, 0, 0), BackgroundColor3 = cfg.Theme.Btn, Text = "Select", Font = Enum.Font.SourceSansBold, TextSize = 14, TextColor3 = cfg.Theme.Text, AutoButtonColor = false})
            new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,8)})
            btn.TextTruncate = Enum.TextTruncate.AtEnd; btn.TextXAlignment = Enum.TextXAlignment.Center

            local panel = nil
            local panelOpen = dropdownStates[id].open
            local dropdownConns = {} -- local conns for this dropdown (so we can clean up on destroy)

            local function destroyPanel()
                if panel and panel.Parent then
                    pcall(function() tween(panel, {BackgroundTransparency = 1}, 0.12, cfg.TweenStyle, cfg.TweenDir) end)
                    task.wait(0.12)
                    pcall(function() panel:Destroy() end)
                end
                -- disconnect local dropdown connections
                for _,dc in ipairs(dropdownConns) do
                    pcall(function()
                        if dc and dc.Disconnect then dc:Disconnect() elseif dc and dc.disconnect then dc:disconnect() end
                    end)
                end
                dropdownConns = {}
                panel = nil
                panelOpen = false
                dropdownStates[id].open = false
            end

            local function createPanel()
                if panel and panel.Parent then pcall(function() panel:Destroy() end) end
                panel = new("Frame", {Parent = screenGui, Size = UDim2.new(0,220,0, 16 + #options*32), BackgroundColor3 = cfg.Theme.InfoInner, ZIndex = 200, BackgroundTransparency = 1})
                new("UICorner", {Parent = panel, CornerRadius = UDim.new(0,8)})
                local stroke = new("UIStroke", {Parent = panel}); stroke.Color = Color3.fromRGB(20,20,20); stroke.Thickness = 2; stroke.Transparency = 0.8
                -- position
                pcall(function()
                    local absX = Frame.AbsolutePosition.X
                    local absY = Frame.AbsolutePosition.Y
                    local x = absX + Frame.AbsoluteSize.X + 8
                    local y = absY + (TitleFrame.AbsoluteSize.Y or 0) + 8
                    local screenSize = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1920,1080)
                    local panelW, panelH = 220, (16 + #options*32)
                    x = clamp(x, 8, screenSize.X - panelW - 8)
                    y = clamp(y, 8, screenSize.Y - panelH - 8)
                    panel.Position = UDim2.new(0, x, 0, y)
                end)
                -- populate
                for i,opt in ipairs(options) do
                    local row = new("TextButton", {Parent = panel, Size = UDim2.new(1, -12, 0, 28), Position = UDim2.new(0,6,0, 8 + (i-1)*32), BackgroundColor3 = cfg.Theme.InfoInner, Text = tostring(opt), Font = Enum.Font.SourceSans, TextSize = 15, TextColor3 = cfg.Theme.Text, AutoButtonColor = false})
                    new("UICorner", {Parent = row, CornerRadius = UDim.new(0,6)})
                    row.TextTruncate = Enum.TextTruncate.AtEnd; row.TextWrapped = false
                    row.MouseEnter:Connect(function() tween(row, {BackgroundColor3 = brightenColor(cfg.Theme.InfoInner, 0.06)}, 0.12, cfg.TweenStyle, cfg.TweenDir) end)
                    row.MouseLeave:Connect(function() tween(row, {BackgroundColor3 = cfg.Theme.InfoInner}, 0.12, cfg.TweenStyle, cfg.TweenDir) end)
                    row.MouseButton1Click:Connect(function()
                        dropdownStates[id].selection = opt
                        if callback then pcall(callback, opt) end
                        btn.Text = tostring(opt)
                        -- per request: DO NOT auto-close on select (remain open)
                    end)
                end
                -- animate in
                tween(panel, {BackgroundTransparency = 0}, 0.16, cfg.TweenStyle, cfg.TweenDir)
                for _,c in ipairs(panel:GetChildren()) do
                    if c:IsA("TextButton") or c:IsA("TextLabel") then
                        c.TextTransparency = 1
                        tween(c, {TextTransparency = 0}, 0.16, cfg.TweenStyle, cfg.TweenDir)
                    end
                end
                panelOpen = true
                dropdownStates[id].open = true
                -- follow Frame movement
                local follow = Frame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
                    if panel and panel.Parent then
                        pcall(function()
                            local absX = Frame.AbsolutePosition.X
                            local absY = Frame.AbsolutePosition.Y
                            local x = absX + Frame.AbsoluteSize.X + 8
                            local y = absY + (TitleFrame.AbsoluteSize.Y or 0) + 8
                            panel.Position = UDim2.new(0, clamp(x,8, (Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize.X or 1920)-panel.AbsoluteSize.X.Offset-8), 0, clamp(y,8, (Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize.Y or 1080)-panel.AbsoluteSize.Y.Offset-8))
                        end)
                    end
                end)
                table.insert(dropdownConns, follow)
                -- close panel when main GUI hidden, but remember state so it reopens when GUI shown
                local vis = Frame:GetPropertyChangedSignal("Visible"):Connect(function()
                    if not Frame.Visible and panel and panel.Parent then
                        destroyPanel()
                    end
                end)
                table.insert(dropdownConns, vis)
            end

            local function togglePanel()
                if panelOpen and panel and panel.Parent then
                    destroyPanel()
                else
                    createPanel()
                end
            end

            local openConn = btn.MouseButton1Click:Connect(function()
                togglePanel()
            end)
            table.insert(conns, openConn)

            -- when main GUI becomes visible again, restore dropdown if it was open at hide time
            -- keep a single property-changed connection to Frame.Visible (cleanup when window destroyed via conns)
            table.insert(conns, Frame:GetPropertyChangedSignal("Visible"):Connect(function()
                if Frame.Visible and dropdownStates[id] and dropdownStates[id].open then
                    -- recreate panel if not present
                    if not (panel and panel.Parent) then
                        createPanel()
                    end
                end
            end))

            return {UI = frame, Set = function(v) btn.Text = tostring(v) end, _id = id}
        end

        -- CreateSlider (label left, bar right). ensure knob starts left and dragging doesn't move GUI
        function tab:CreateSlider(label, minVal, maxVal, default, callback)
            minVal = minVal or 0; maxVal = maxVal or 100; default = (default==nil) and minVal or default
            local frame = new("Frame", {Parent = self.Content, Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1})
            local lbl = new("TextLabel", {Parent = frame, Text = label, Size = UDim2.new(LABEL_WIDTH, -8, 0, 14), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold, TextSize = 16, TextColor3 = cfg.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left})
            local barBg = new("Frame", {Parent = frame, Size = UDim2.new(CONTROL_WIDTH, -12,0,12), Position = UDim2.new(LABEL_WIDTH, 4, 0, 20-6), BackgroundColor3 = cfg.Theme.ToggleBg, BorderSizePixel = 0})
            new("UICorner", {Parent = barBg, CornerRadius = UDim.new(0,6)})
            barBg.Active = true
            local fill = new("Frame", {Parent = barBg, Size = UDim2.new(0,0,1,0), Position = UDim2.new(0,0,0,0), BackgroundColor3 = brightenColor(cfg.Theme.Btn, 0.08)})
            new("UICorner", {Parent = fill, CornerRadius = UDim.new(0,6)})
            local knob = new("Frame", {Parent = barBg, Size = UDim2.new(0,14,0,14), Position = UDim2.new(0, -7, 0.5, -7), BackgroundColor3 = Color3.fromRGB(240,240,240)})
            new("UICorner", {Parent = knob, CornerRadius = UDim.new(1,0)})
            knob.Active = true

            local range = maxVal - minVal
            local function setValueFromPercent(p, skipTween)
                p = clamp(p,0,1)
                local value = minVal + (maxVal-minVal)*p
                if not skipTween then
                    tween(fill, {Size = UDim2.new(p,0,1,0)}, 0.08, cfg.TweenStyle, cfg.TweenDir)
                    tween(knob, {Position = UDim2.new(p, -7, 0.5, -7)}, 0.08, cfg.TweenStyle, cfg.TweenDir)
                else
                    fill.Size = UDim2.new(p,0,1,0)
                    knob.Position = UDim2.new(p, -7, 0.5, -7)
                end
                if callback then pcall(callback, value) end
            end

            local defaultPct = (range==0) and 0 or ((default - minVal)/range)
            setValueFromPercent(defaultPct, true)

            local dragging = false
            local upConn
            knob.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    pushPreventWindowDrag()
                    upConn = input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            dragging = false
                            popPreventWindowDrag()
                            if upConn then pcall(function() upConn:Disconnect() end) end
                        end
                    end)
                end
            end)
            local moveConn = UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local absX = input.Position.X
                    local left = barBg.AbsolutePosition.X
                    local width = barBg.AbsoluteSize.X
                    local pct = (absX - left) / math.max(1, width)
                    setValueFromPercent(pct, true)
                end
            end)
            table.insert(conns, moveConn)

            -- clicking bar: jump but prevent window drag briefly
            local barClickConn = barBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    pushPreventWindowDrag()
                    task.defer(function() task.wait(0.14); popPreventWindowDrag() end)
                    local mx = (LocalPlayer and LocalPlayer:GetMouse() and LocalPlayer:GetMouse().X) or input.Position.X
                    local left = barBg.AbsolutePosition.X
                    local width = barBg.AbsoluteSize.X
                    local pct = (mx - left) / math.max(1, width)
                    setValueFromPercent(pct, false)
                end
            end)
            table.insert(conns, barClickConn)

            return {UI = frame, Set = function(v) local r = maxVal-minVal if r==0 then setValueFromPercent(0,false) else setValueFromPercent((v-minVal)/r,false) end end}
        end

        table.insert(tabList, tab)
        updateTabsLayout()

        local clickConn = btn.MouseButton1Click:Connect(function()
            for _,t in ipairs(tabList) do
                if t.Content and t.Content.Visible then
                    tween(t.Content, {Position = UDim2.new(0,0,0,6)}, 0.12, cfg.TweenStyle, cfg.TweenDir)
                    t.Content.Visible = false
                end
                if t.Button then tween(t.Button, {BackgroundColor3 = cfg.Theme.TabBg}, 0.12, cfg.TweenStyle, cfg.TweenDir) end
                if t.Button then t.Button.TextColor3 = darkTabText end
            end
            tab.Content.Position = UDim2.new(0,0,0,6)
            tab.Content.Visible = true
            tween(tab.Content, {Position = UDim2.new(0,0,0,0)}, 0.18, cfg.TweenStyle, cfg.TweenDir)
            tween(tab.Button, {BackgroundColor3 = brightenColor(cfg.Theme.TabBg, 0.08)}, 0.12, cfg.TweenStyle, cfg.TweenDir)
            tab.Button.TextColor3 = Color3.fromRGB(255,255,255)
            ensureTabVisible(tab.Button)
        end)
        table.insert(conns, clickConn)

        if #tabList == 1 then
            tab.Content.Visible = true
            tab.Content.Position = UDim2.new(0,0,0,0)
            tween(tab.Button, {BackgroundColor3 = brightenColor(cfg.Theme.TabBg, 0.08)}, 0.12, cfg.TweenStyle, cfg.TweenDir)
            tab.Button.TextColor3 = Color3.fromRGB(255,255,255)
        end

        return tab
    end

    -- draggable: respect preventWindowDrag
    local function makeDraggable(gui, handle)
        handle = handle or gui
        pcall(function() handle.Active = true end)
        local dragging, dragInput, dragStart, startPos
        local c1 = handle.InputBegan:Connect(function(input)
            if isPreventWindowDrag() then return end
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

    -- toggle main visibility (restore old icon behavior)
    local visible = true
    local function hideAllFloatingPanels()
        for _,obj in ipairs(screenGui:GetChildren()) do
            if obj:IsA("Frame") and obj ~= Frame and obj ~= InfoBar and obj ~= HwanBtn then
                pcall(function() obj:Destroy() end)
            end
        end
        -- ensure dropdownStates reflect closed panels
        for k,_ in pairs(dropdownStates) do
            dropdownStates[k].open = false
        end
    end

    local hwanConn = HwanBtn.MouseButton1Click:Connect(function()
        visible = not visible
        if visible then
            Frame.Visible = true
            tween(Frame, {Size = UDim2.new(0, cfg.Width, 0, cfg.Height)}, 0.28, cfg.TweenStyle, cfg.TweenDir)
            -- restore dropdowns that were open when hidden (dropdownStates maintained)
            for id,st in pairs(dropdownStates) do
                if st.open then
                    -- Frame Visible change connection will trigger recreate
                end
            end
        else
            tween(Frame, {Size = UDim2.new(0, cfg.Width, 0, 0)}, 0.18, cfg.TweenStyle, cfg.TweenDir)
            Frame.Visible = false
            hideAllFloatingPanels()
        end
        pcall(function()
            tween(HwanInner, {Size = UDim2.new(1,-6,1,-6)}, 0.12, cfg.TweenStyle, cfg.TweenDir)
            task.wait(0.12)
            tween(HwanInner, {Size = UDim2.new(1,-8,1,-8)}, 0.12, cfg.TweenStyle, cfg.TweenDir)
        end)
    end)
    table.insert(conns, hwanConn)

    -- hotkey toggle
    local altConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == (cfg.ToggleKey or Enum.KeyCode.LeftAlt) then
            visible = not visible
            if visible then
                Frame.Visible = true
                tween(Frame, {Size = UDim2.new(0, cfg.Width, 0, cfg.Height)}, 0.28, cfg.TweenStyle, cfg.TweenDir)
            else
                tween(Frame, {Size = UDim2.new(0, cfg.Width, 0, 0)}, 0.18, cfg.TweenStyle, cfg.TweenDir)
                Frame.Visible = false
                hideAllFloatingPanels()
            end
        end
    end)
    table.insert(conns, altConn)

    -- rotate gradient + info update
    local pingSamples = {}
    local maxPingSamples = 30
    local pingTimer = 0
    local pingInterval = 0.25
    local renderConn = RunService.RenderStepped:Connect(function(dt)
        if titleGrad then titleGrad.Rotation = (titleGrad.Rotation + 0.9) % 360 end
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
        local mean, std = 0,0
        if #pingSamples > 0 then
            local sum = 0
            for _,v in ipairs(pingSamples) do sum = sum + v end
            mean = sum/#pingSamples
            local sqsum = 0
            for _,v in ipairs(pingSamples) do sqsum = sqsum + (v-mean)*(v-mean) end
            std = math.sqrt(sqsum/#pingSamples)
        end
        local cvPercent = 0
        if mean > 0 then cvPercent = math.floor((std/mean)*100 + 0.5) end
        InfoText.Text = string.format("TIME : %s   |   FPS: %d   |   PING: %d ms (%d%%CV)", timeStr, fps, pingMs, cvPercent)
    end)
    table.insert(conns, renderConn)

    -- notifications
    local notifQueue = {}
    local notifShowing = false
    local function processNextNotification()
        if notifShowing then return end
        local text = table.remove(notifQueue, 1)
        if not text then return end
        notifShowing = true
        local notif = new("Frame", {Parent = screenGui, Size = UDim2.new(0, 240, 0, 64), Position = UDim2.new(1, -260, 1, -96), BackgroundColor3 = InfoInner.BackgroundColor3, BorderSizePixel = 0, ZIndex = 120})
        new("UICorner", {Parent = notif, CornerRadius = UDim.new(0,8)})
        new("UIStroke", {Parent = notif, Color = Color3.fromRGB(18,18,18), Thickness = 2, Transparency = 0.75})
        local header = new("TextLabel", {Parent = notif, Size = UDim2.new(1, -12, 0, 26), Position = UDim2.new(0,10,0,10), BackgroundTransparency = 1, Font = TitleMain.Font, TextSize = 20, Text = cfg.Title, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = cfg.Theme.Text, ZIndex = 121})
        local body = new("TextLabel", {Parent = notif, Size = UDim2.new(1, -12, 0, 26), Position = UDim2.new(0,10,0,32), BackgroundTransparency = 1, Font = Enum.Font.SourceSans, TextSize = 17, Text = text, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = cfg.Theme.Text, ZIndex = 121})
        notif.BackgroundTransparency = 1; header.TextTransparency = 1; body.TextTransparency = 1
        tween(notif, {BackgroundTransparency = 0}, 0.12, cfg.TweenStyle, cfg.TweenDir)
        tween(header, {TextTransparency = 0}, 0.12, cfg.TweenStyle, cfg.TweenDir)
        tween(body, {TextTransparency = 0}, 0.12, cfg.TweenStyle, cfg.TweenDir)
        task.delay(1.5, function()
            tween(notif, {BackgroundTransparency = 1}, 0.12, cfg.TweenStyle, cfg.TweenDir)
            tween(header, {TextTransparency = 1}, 0.12, cfg.TweenStyle, cfg.TweenDir)
            tween(body, {TextTransparency = 1}, 0.12, cfg.TweenStyle, cfg.TweenDir)
            task.wait(0.12)
            pcall(function() notif:Destroy() end)
            notifShowing = false
            processNextNotification()
        end)
    end
    local function showNotification(text) table.insert(notifQueue, text) processNextNotification() end

    -- public API
    local window = {}
    window.Root = screenGui
    window.Main = Frame
    window._config = cfg
    function window:CreateTab(name) return createTab(name) end
    function window:Notify(text) showNotification(text) end
    function window:Center() Frame.Position = UDim2.new(0, 16, 0.5, -cfg.Height/2) end
    function window:SetVisible(v)
        if not v then
            hideAllFloatingPanels()
            Frame.Visible = false
        else
            Frame.Visible = true
            tween(Frame, {Size = UDim2.new(0, cfg.Width, 0, cfg.Height)}, 0.28, cfg.TweenStyle, cfg.TweenDir)
            -- restore dropdowns
            for id,st in pairs(dropdownStates) do
                if st.open then
                    -- Frame.Visible change connection will recreate
                end
            end
        end
    end
    function window:Destroy()
        for _,c in ipairs(conns) do
            pcall(function()
                if c and c.Disconnect then c:Disconnect()
                elseif c and c.disconnect then c:disconnect() end
            end)
        end
        pcall(function() screenGui:Destroy() end)
        _G.HwanHubData = nil
    end

    _G.HwanHubData = { screenGui = screenGui, conns = conns, auth = true }

    -- open animation
    task.spawn(function()
        Frame.Visible = true
        tween(Frame, {Size = UDim2.new(0, cfg.Width, 0, cfg.Height)}, 0.36, cfg.TweenStyle, cfg.TweenDir)
    end)

    return window
end

return HwanUI
