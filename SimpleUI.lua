-- SimpleUI.lua (Executor-ready single file)
-- Usage: local SimpleUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/SimpleUI.lua"))()
--        local ui = SimpleUI:CreateWindow({Title="Oceanris Hub", Width=420, Height=440})
--        local tab = ui:AddTab("Main")
--        tab:AddButton("Say Hi", function() print("hi") end)

local SimpleUI = {}
SimpleUI.__index = SimpleUI

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- helper: choose host for GUI (CoreGui or gethui hidden GUI)
local function getGuiParent()
    -- prefer gethui / get_hidden_gui when available (common in many executors)
    if type(gethui) == "function" then
        pcall(function() end)
        return gethui()
    end
    if type(get_hidden_gui) == "function" then
        return get_hidden_gui()
    end
    return game:GetService("CoreGui")
end

local function protectGui(g)
    -- protect gui for executors that support it
    if syn and syn.protect_gui then
        pcall(function() syn.protect_gui(g) end)
    end
    if protect_gui then
        pcall(function() protect_gui(g) end)
    end
end

-- simple instance creator
local function new(class, props)
    local obj = Instance.new(class)
    if props then
        for k,v in pairs(props) do
            pcall(function() obj[k] = v end)
        end
    end
    return obj
end

local function tween(instance, props, time, style, dir)
    time = time or 0.18
    style = style or Enum.EasingStyle.Quad
    dir = dir or Enum.EasingDirection.Out
    local ok,err = pcall(function()
        local info = TweenInfo.new(time, style, dir)
        TweenService:Create(instance, info, props):Play()
    end)
    if not ok then
        -- ignore tween errors
    end
end

-- dragging helper (works for mouse + touch)
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragStart
    local startPos
    local dragInput

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

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
            pcall(update, input)
        end
    end)
end

-- default theme
local DEFAULT = {
    Width = 380,
    Height = 420,
    Title = "Simple UI",
    Theme = {
        Main = Color3.fromRGB(30,30,30),
        Accent = Color3.fromRGB(60,135,200),
        Text = Color3.fromRGB(235,235,235),
        Sub = Color3.fromRGB(200,200,200),
        Btn = Color3.fromRGB(45,45,45),
        ToggleBg = Color3.fromRGB(85,85,85)
    },
    Corner = UDim.new(0,8)
}

-- CreateWindow (main API)
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

    local host = getGuiParent()

    local screenGui = new("ScreenGui", {Name = cfg.Title .. "_GUI", Parent = host, ResetOnSpawn = false})
    protectGui(screenGui)

    -- main frame
    local main = new("Frame", {
        Name = "Main",
        Parent = screenGui,
        Size = UDim2.new(0, cfg.Width, 0, cfg.Height),
        Position = UDim2.new(0.5, -cfg.Width/2, 0.5, -cfg.Height/2),
        BackgroundColor3 = cfg.Theme.Main,
        BorderSizePixel = 0,
        Active = true
    })
    new("UICorner", {Parent = main, CornerRadius = cfg.Corner})

    -- header
    local header = new("Frame", {Parent = main, Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1})
    local title = new("TextLabel", {
        Parent = header, Text = cfg.Title, Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0,12,0,0),
        BackgroundTransparency = 1, TextColor3 = cfg.Theme.Text, Font = Enum.Font.GothamSemibold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left
    })

    local closeBtn = new("TextButton", {
        Parent = header, Text = "✕", Size = UDim2.new(0,34,0,24), Position = UDim2.new(1, -44, 0.5, -12),
        BackgroundColor3 = cfg.Theme.Main, TextColor3 = cfg.Theme.Sub, Font = Enum.Font.GothamSemibold, TextSize = 16, AutoButtonColor=false
    })
    new("UICorner", {Parent = closeBtn, CornerRadius = UDim.new(0,6)})

    -- body: left tabs + right content (scroll)
    local body = new("Frame", {Parent = main, Size = UDim2.new(1,0,1,-36), Position = UDim2.new(0,0,0,36), BackgroundTransparency = 1})
    local left = new("Frame", {Parent = body, Size = UDim2.new(0,120,1,0), BackgroundTransparency = 1})
    local right = new("ScrollingFrame", {
        Parent = body, Size = UDim2.new(1, -120, 1, 0), Position = UDim2.new(0,120,0,0),
        BackgroundTransparency = 1, ScrollBarThickness = 6, CanvasSize = UDim2.new(0,0,0,0)
    })
    right.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local tabList = {}
    local activeTab = nil

    local function addTab(name)
        local idx = #tabList + 1
        local btn = new("TextButton", {
            Parent = left, Text = name, Size = UDim2.new(1, -12, 0, 34),
            Position = UDim2.new(0,6,0, 8 + (idx-1) * 40),
            BackgroundColor3 = cfg.Theme.Main, TextColor3 = cfg.Theme.Sub, Font = Enum.Font.Gotham, TextSize = 14, AutoButtonColor=false
        })
        new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,6)})
        btn.MouseEnter:Connect(function() if UserInputService.MouseEnabled then tween(btn, {BackgroundColor3 = cfg.Theme.Accent}, 0.12) end end)
        btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = cfg.Theme.Main}, 0.12) end)

        local content = new("Frame", {Parent = right, Size = UDim2.new(1, -20, 0, 10), BackgroundTransparency = 1, LayoutOrder = idx})
        local layout = new("UIListLayout", {Parent = content, FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,8)})
        local pad = new("UIPadding", {Parent = content, PaddingLeft = UDim.new(0,12), PaddingRight = UDim.new(0,12), PaddingTop = UDim.new(0,8), PaddingBottom = UDim.new(0,8)})

        local tab = {Name = name, Button = btn, Content = content}

        function tab:AddButton(label, callback)
            local b = new("TextButton", {Parent = self.Content, Size = UDim2.new(1,0,0,36), Text = label, BackgroundColor3 = cfg.Theme.Btn, TextColor3 = cfg.Theme.Text, Font = Enum.Font.Gotham, TextSize = 15, AutoButtonColor=false})
            new("UICorner", {Parent = b, CornerRadius = UDim.new(0,6)})
            b.MouseButton1Click:Connect(function()
                if callback then
                    pcall(callback)
                end
                tween(b, {BackgroundColor3 = cfg.Theme.Accent}, 0.06)
                task.wait(0.06)
                tween(b, {BackgroundColor3 = cfg.Theme.Btn}, 0.12)
            end)
            return b
        end

        function tab:AddLabel(txt)
            local l = new("TextLabel", {Parent = self.Content, Size = UDim2.new(1,0,0,20), Text = txt, BackgroundTransparency = 1, TextColor3 = cfg.Theme.Text, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
            return l
        end

        function tab:AddToggle(label, initial, callback)
            local frame = new("Frame", {Parent = self.Content, Size = UDim2.new(1,0,0,30), BackgroundTransparency = 1})
            local lbl = new("TextLabel", {Parent = frame, Text = label, Size = UDim2.new(1, -56, 1, 0), BackgroundTransparency = 1, TextColor3 = cfg.Theme.Text, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
            local toggleBg = new("TextButton", {Parent = frame, Size = UDim2.new(0,44,0,24), Position = UDim2.new(1, -50, 0.5, -12), BackgroundColor3 = cfg.Theme.ToggleBg, BorderSizePixel=0, AutoButtonColor=false})
            new("UICorner", {Parent = toggleBg, CornerRadius = UDim.new(0,12)})
            local dot = new("Frame", {Parent = toggleBg, Size = UDim2.new(0,18,0,18), Position = UDim2.new(0,4,0.5,-9), BackgroundColor3 = cfg.Theme.Text})
            new("UICorner", {Parent = dot, CornerRadius = UDim.new(1,0)})

            local state = (initial and true) or false
            local function setState(s, silent)
                state = s
                if s then
                    tween(toggleBg, {BackgroundColor3 = cfg.Theme.Accent}, 0.12)
                    tween(dot, {Position = UDim2.new(1, -22, 0.5, -9)}, 0.12)
                else
                    tween(toggleBg, {BackgroundColor3 = cfg.Theme.ToggleBg}, 0.12)
                    tween(dot, {Position = UDim2.new(0,4,0.5,-9)}, 0.12)
                end
                if callback and not silent then
                    pcall(function() callback(state) end)
                end
            end

            toggleBg.MouseButton1Click:Connect(function() setState(not state) end)
            setState(state, true)

            return {Get = function() return state end, Set = function(v) setState( (v and true) or false ) end, UI = frame}
        end

        table.insert(tabList, tab)

        -- tab click behavior
        btn.MouseButton1Click:Connect(function()
            activeTab = tab
            -- visual highlight
            for _,t in ipairs(tabList) do
                tween(t.Button, {BackgroundColor3 = cfg.Theme.Main}, 0.12)
            end
            tween(btn, {BackgroundColor3 = cfg.Theme.Accent}, 0.12)
            -- scroll to the content
            task.delay(0.03, function()
                pcall(function()
                    right.CanvasPosition = Vector2.new(0, tab.Content.AbsolutePosition.Y - right.AbsolutePosition.Y)
                end)
            end)
        end)

        return tab
    end

    -- default: create first tab placeholder
    -- drag
    makeDraggable(main, header)

    -- close behavior
    closeBtn.MouseButton1Click:Connect(function()
        tween(main, {Position = UDim2.new(main.Position.X.Scale, main.Position.X.Offset, 2, 0)}, 0.18)
        task.wait(0.16)
        pcall(function() screenGui:Destroy() end)
    end)

    -- API returned window
    local window = {}
    window.Root = screenGui
    window.Main = main
    window._config = cfg
    function window:AddTab(name) return addTab(name) end
    function window:Center()
        self.Main.Position = UDim2.new(0.5, -self._config.Width/2, 0.5, -self._config.Height/2)
    end
    function window:Destroy()
        pcall(function() screenGui:Destroy() end)
    end

    return window
end

return SimpleUI
