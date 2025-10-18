-- SimpleUI_Deck.lua (Executor-ready)
-- Tính năng: Header with styled title, horizontal scrollable tab bar (drag to scroll), tabs, button, toggle, left-side toggle icon to show/hide
-- Usage:
-- local SimpleUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/SimpleUI_Deck.lua"))()
-- local ui = SimpleUI:CreateWindow({Title="HWAN HUB", Width=360, Height=520, ShowToggleIcon=true})
-- local main = ui:AddTab("Main")
-- main:AddButton("Say Hi", function() print("hi") end)
-- local t = main:AddToggle("AutoFarm", false, function(s) print("state", s) end)

local SimpleUI = {}
SimpleUI.__index = SimpleUI

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- executor helpers
local function getGuiParent()
    if type(gethui) == "function" then
        local ok, g = pcall(gethui)
        if ok and g then return g end
    end
    if type(get_hidden_gui) == "function" then
        local ok, g = pcall(get_hidden_gui)
        if ok and g then return g end
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

-- utils
local function new(class, props)
    local ok, inst = pcall(function() return Instance.new(class) end)
    if not ok then return end
    local obj = inst
    if props then
        for k,v in pairs(props) do
            pcall(function() obj[k] = v end)
        end
    end
    return obj
end

local function tween(inst, props, time)
    time = time or 0.18
    pcall(function()
        local info = TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(inst, info, props):Play()
    end)
end

-- default config
local DEFAULT = {
    Width = 360,
    Height = 520,
    Title = "Simple UI",
    ShowToggleIcon = true,
    Theme = {
        Main = Color3.fromRGB(18,18,18),
        Accent = Color3.fromRGB(45,120,210),
        Text = Color3.fromRGB(235,235,235),
        Sub = Color3.fromRGB(170,170,170),
        TabBg = Color3.fromRGB(40,40,40),
        Btn = Color3.fromRGB(50,50,50),
        ToggleBg = Color3.fromRGB(80,80,80)
    },
    Corner = UDim.new(0,12)
}

-- dragging util (for window)
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
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
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- MAIN: CreateWindow
function SimpleUI:CreateWindow(opts)
    opts = opts or {}
    local cfg = {}
    for k,v in pairs(DEFAULT) do cfg[k] = v end
    if opts.Width then cfg.Width = opts.Width end
    if opts.Height then cfg.Height = opts.Height end
    if opts.Title then cfg.Title = opts.Title end
    if opts.Theme then
        for k,v in pairs(opts.Theme) do cfg.Theme[k] = v end
    end
    if opts.ShowToggleIcon ~= nil then cfg.ShowToggleIcon = opts.ShowToggleIcon end

    local host = getGuiParent()
    local screenGui = new("ScreenGui", {Name = cfg.Title .. "_GUI", Parent = host, ResetOnSpawn = false})
    protectGui(screenGui)

    -- main frame
    local main = new("Frame", {
        Parent = screenGui,
        Name = "Main",
        Size = UDim2.new(0, cfg.Width, 0, cfg.Height),
        Position = UDim2.new(0.5, -cfg.Width/2, 0.5, -cfg.Height/2),
        BackgroundColor3 = cfg.Theme.Main,
        BorderSizePixel = 0,
        Active = true
    })
    new("UICorner", {Parent = main, CornerRadius = cfg.Corner})

    -- header area (logo + big title)
    local header = new("Frame", {Parent = main, Size = UDim2.new(1,0,0,84), BackgroundTransparency = 1})
    -- logo small square top-left inside main
    local logo = new("Frame", {
        Parent = header,
        Size = UDim2.new(0,56,0,56),
        Position = UDim2.new(0,12,0,8),
        BackgroundColor3 = cfg.Theme.TabBg,
        BorderSizePixel = 0
    })
    new("UICorner", {Parent = logo, CornerRadius = UDim.new(0,10)})
    -- small logo text (abbrev)
    local logoTxt = new("TextLabel", {
        Parent = logo,
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text = string.sub(cfg.Title,1,4),
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextColor3 = cfg.Theme.Accent
    })
    -- big title: split into two labels for color effect
    local titleFrame = new("Frame", {Parent = header, Size = UDim2.new(1, -100, 0, 56), Position = UDim2.new(0,84,0,8), BackgroundTransparency = 1})
    local titleLeft = new("TextLabel", {
        Parent = titleFrame, Text = string.upper(cfg.Title:match("^(%S+)") or cfg.Title),
        BackgroundTransparency = 1, TextColor3 = cfg.Theme.Accent, Font = Enum.Font.GothamBlack, TextSize = 34, Position = UDim2.new(0,0,0,0), Size = UDim2.new(0.6,0,1,0)
    })
    local titleRight = new("TextLabel", {
        Parent = titleFrame, Text = (" " .. (cfg.Title:match("%s(.+)$") or "")),
        BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(20,20,20), Font = Enum.Font.GothamBlack, TextSize = 34,
        Position = UDim2.new(0.58,0,0,0), Size = UDim2.new(0.42,0,1,0)
    })

    -- tab bar (scrollable horizontal) placed under header
    local tabBar = new("Frame", {Parent = main, Size = UDim2.new(1,0,0,54), Position = UDim2.new(0,0,0,84), BackgroundTransparency = 1})
    local tabScroll = new("ScrollingFrame", {
        Parent = tabBar,
        Size = UDim2.new(1, -24, 1, -12),
        Position = UDim2.new(0,12,0,6),
        BackgroundTransparency = 1,
        ScrollBarThickness = 6,
        CanvasSize = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        HorizontalScrollBarInset = Enum.ScrollBarInset.Always
    })
    tabScroll.VerticalScrollBarInset = Enum.ScrollBarInset.None
    tabScroll.ScrollBarImageColor3 = cfg.Theme.Sub

    local listLayout = new("UIListLayout", {Parent = tabScroll, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder})
    tabScroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function() end)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

    -- content area below tabs
    local contentArea = new("Frame", {Parent = main, Size = UDim2.new(1,0,1, - (84+54) ), Position = UDim2.new(0,0,0, 84+54), BackgroundTransparency = 1})
    local contentPadding = new("UIPadding", {Parent = contentArea, PaddingLeft = UDim.new(0,12), PaddingRight = UDim.new(0,12), PaddingTop = UDim.new(0,6), PaddingBottom = UDim.new(0,12)})

    local tabList = {}
    local activeTab = nil

    -- helper: clamp
    local function clamp(v,a,b) if v < a then return a end if v > b then return b end return v end

    -- implement drag-to-scroll for tabScroll (horizontal)
    do
        local dragging = false
        local dragStart = Vector2.new()
        local startCanvasX = 0
        tabScroll.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startCanvasX = tabScroll.CanvasPosition.X
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        tabScroll.InputChanged:Connect(function(input)
            -- nothing
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement or (dragging and input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                local maxX = math.max(tabScroll.AbsoluteCanvasSize.X - tabScroll.AbsoluteSize.X, 0)
                local newX = clamp(startCanvasX - delta.X, 0, maxX)
                tabScroll.CanvasPosition = Vector2.new(newX, 0)
            end
        end)
    end

    -- function to create tab
    local function addTab(name)
        local idx = #tabList + 1
        local btn = new("TextButton", {
            Parent = tabScroll, Text = name,
            Size = UDim2.new(0, 96, 0, 36),
            BackgroundColor3 = cfg.Theme.TabBg,
            TextColor3 = cfg.Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 15,
            AutoButtonColor = false,
            BorderSizePixel = 0
        })
        new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,8)})
        btn.MouseEnter:Connect(function() if UserInputService.MouseEnabled then tween(btn, {BackgroundColor3 = cfg.Theme.Accent}, 0.12) end end)
        btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = cfg.Theme.TabBg}, 0.12) end)

        -- content frame for this tab
        local content = new("Frame", {Parent = contentArea, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false})
        local layout = new("UIListLayout", {Parent = content, FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,10)})
        new("UIPadding", {Parent = content, PaddingLeft = UDim.new(0,6), PaddingRight = UDim.new(0,6), PaddingTop = UDim.new(0,6)})

        local tab = {Name = name, Button = btn, Content = content}

        function tab:AddButton(label, callback)
            local b = new("TextButton", {Parent = self.Content, Size = UDim2.new(1,0,0,36), BackgroundColor3 = cfg.Theme.Btn, TextColor3 = cfg.Theme.Text, Text = label, Font = Enum.Font.Gotham, TextSize = 15, AutoButtonColor=false })
            new("UICorner", {Parent = b, CornerRadius = UDim.new(0,8)})
            b.MouseButton1Click:Connect(function()
                if callback then pcall(callback) end
                tween(b, {BackgroundColor3 = cfg.Theme.Accent}, 0.06)
                task.wait(0.06)
                tween(b, {BackgroundColor3 = cfg.Theme.Btn}, 0.12)
            end)
            return b
        end

        function tab:AddToggle(label, initial, callback)
            local frame = new("Frame", {Parent = self.Content, Size = UDim2.new(1,0,0,30), BackgroundTransparency = 1})
            local lbl = new("TextLabel", {Parent = frame, Text = label, Size = UDim2.new(1, -58, 1, 0), BackgroundTransparency = 1, TextColor3 = cfg.Theme.Text, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
            local toggleBg = new("TextButton", {Parent = frame, Size = UDim2.new(0,46,0,26), Position = UDim2.new(1, -50, 0.5, -13), BackgroundColor3 = cfg.Theme.ToggleBg, BorderSizePixel = 0, AutoButtonColor=false })
            new("UICorner", {Parent = toggleBg, CornerRadius = UDim.new(0,12)})
            local dot = new("Frame", {Parent = toggleBg, Size = UDim2.new(0,18,0,18), Position = UDim2.new(0,4,0.5,-9), BackgroundColor3 = cfg.Theme.Text})
            new("UICorner", {Parent = dot, CornerRadius = UDim.new(1,0)})

            local state = initial and true or false
            local function setState(s, silent)
                state = s
                if s then
                    tween(toggleBg, {BackgroundColor3 = cfg.Theme.Accent}, 0.12)
                    tween(dot, {Position = UDim2.new(1, -22, 0.5, -9)}, 0.12)
                else
                    tween(toggleBg, {BackgroundColor3 = cfg.Theme.ToggleBg}, 0.12)
                    tween(dot, {Position = UDim2.new(0,4,0.5,-9)}, 0.12)
                end
                if callback and not silent then pcall(callback, state) end
            end
            toggleBg.MouseButton1Click:Connect(function() setState(not state) end)
            setState(state, true)
            return {Get = function() return state end, Set = function(v) setState( (v and true) or false ) end, UI = frame}
        end

        table.insert(tabList, tab)

        -- click behavior: show its content, highlight
        btn.MouseButton1Click:Connect(function()
            for _, t in ipairs(tabList) do
                t.Content.Visible = false
                tween(t.Button, {BackgroundColor3 = cfg.Theme.TabBg}, 0.12)
            end
            tab.Content.Visible = true
            tween(tab.Button, {BackgroundColor3 = cfg.Theme.Accent}, 0.12)
            activeTab = tab
        end)

        -- if first tab, activate
        if idx == 1 then
            task.defer(function()
                btn:CaptureFocus()
                btn.MouseButton1Click:Wait()
            end)
            -- but programmatically activate:
            for _, t in ipairs(tabList) do t.Content.Visible = false end
            tab.Content.Visible = true
            tween(tab.Button, {BackgroundColor3 = cfg.Theme.Accent}, 0.12)
            activeTab = tab
        end

        return tab
    end

    -- make main draggable using header area (so whole window can move)
    makeDraggable(main, header)

    -- left small toggle icon to show/hide main
    local toggleIcon
    if cfg.ShowToggleIcon then
        toggleIcon = new("TextButton", {
            Parent = screenGui,
            Name = "ToggleIcon",
            Size = UDim2.new(0,52,0,52),
            Position = UDim2.new(0,12,0.5,-26),
            BackgroundColor3 = cfg.Theme.TabBg,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = ""
        })
        new("UICorner", {Parent = toggleIcon, CornerRadius = UDim.new(0,10)})
        local tlogo = new("TextLabel", {Parent = toggleIcon, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = string.sub(cfg.Title,1,4):upper(), Font = Enum.Font.GothamBlack, TextSize = 18, TextColor3 = cfg.Theme.Accent})
        -- draggable icon
        makeDraggable(toggleIcon, toggleIcon)

        local visible = true
        local function setVisible(v)
            visible = v
            if visible then
                tween(main, {Position = main.Position}, 0.12) -- no-op for aesthetic
                main.Visible = true
                tween(toggleIcon, {BackgroundColor3 = cfg.Theme.TabBg}, 0.12)
            else
                -- animate main moving down off-screen
                tween(main, {Position = UDim2.new(main.Position.X.Scale, main.Position.X.Offset, 2, 0)}, 0.18)
                task.wait(0.16)
                main.Visible = false
                tween(toggleIcon, {BackgroundColor3 = Color3.fromRGB(60,60,60)}, 0.12)
            end
        end

        toggleIcon.MouseButton1Click:Connect(function()
            setVisible(not visible)
        end)

        -- double-click icon to center window
        local lastClick = 0
        toggleIcon.MouseButton1Click:Connect(function()
            local now = tick()
            if now - lastClick < 0.28 then
                -- double click: center main
                main.Position = UDim2.new(0.5, -cfg.Width/2, 0.5, -cfg.Height/2)
            end
            lastClick = now
        end)
    end

    -- close button (top-right inside header)
    local closeBtn = new("TextButton", {Parent = header, Text = "✕", Size = UDim2.new(0,36,0,26), Position = UDim2.new(1, -48, 0, 8), BackgroundColor3 = cfg.Theme.Main, TextColor3 = cfg.Theme.Sub, Font = Enum.Font.GothamSemibold, TextSize = 16, AutoButtonColor=false})
    new("UICorner", {Parent = closeBtn, CornerRadius = UDim.new(0,6)})
    closeBtn.MouseButton1Click:Connect(function()
        pcall(function() screenGui:Destroy() end)
    end)

    -- API
    local window = {}
    window.Root = screenGui
    window.Main = main
    window._config = cfg

    function window:AddTab(name) return addTab(name) end
    function window:Center() self.Main.Position = UDim2.new(0.5, -self._config.Width/2, 0.5, -self._config.Height/2) end
    function window:Destroy() pcall(function() screenGui:Destroy() end) end
    function window:SetVisible(v)
        if toggleIcon then
            if v then
                main.Visible = true
                tween(main, {Position = UDim2.new(0.5, -self._config.Width/2, 0.5, -self._config.Height/2)}, 0.18)
            else
                tween(main, {Position = UDim2.new(main.Position.X.Scale, main.Position.X.Offset, 2, 0)}, 0.16)
                task.wait(0.14)
                main.Visible = false
            end
        else
            main.Visible = v
        end
    end

    return window
end

return SimpleUI
