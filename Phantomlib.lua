--[[
    ▓▓▓  PHANTOM UI LIBRARY  ▓▓▓
    Estilo inspirado em Obsidian Library
    
    API:
        local Lib    = loadstring(...)()
        local Window = Lib:CreateWindow({ Title, Footer, Keybind })
        local Tab    = Window:AddTab("Nome")
        local Left   = Tab:AddLeftGroupbox("Nome")
        local Right  = Tab:AddRightGroupbox("Nome")

        Left:AddToggle("Idx", { Text, Default, Callback })
        Left:AddButton({ Text, Func })
        Left:AddSlider("Idx", { Text, Min, Max, Default, Suffix, Callback })
        Left:AddDropdown("Idx", { Text, Values, Default, Multi, Callback })
        Left:AddInput("Idx", { Text, Placeholder, Callback })
        Left:AddLabel(Text)
        Left:AddDivider()

        Toggle:AddColorPicker("Idx", { Default, Callback })
        Toggle:AddKeyPicker("Idx", { Default, Mode, Callback })

        Lib:Notify({ Title, Content, Duration })
        Lib:Unload()

    Acesso global:
        Lib.Toggles["Idx"].Value
        Lib.Options["Idx"].Value
]]

-- ════════════════════════════════════════════════
-- SERVIÇOS
-- ════════════════════════════════════════════════
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local Players            = game:GetService("Players")
local CoreGui            = game:GetService("CoreGui")
local TextService        = game:GetService("TextService")

local LocalPlayer        = Players.LocalPlayer
local Mouse              = LocalPlayer:GetMouse()

-- ════════════════════════════════════════════════
-- BIBLIOTECA
-- ════════════════════════════════════════════════
local Library = {
    Toggles  = {},
    Options  = {},
    Signals  = {},
    Unloaded = false,

    Scheme = {
        Background = Color3.fromRGB(15, 15, 15),
        Main       = Color3.fromRGB(25, 25, 25),
        Accent     = Color3.fromRGB(125, 85, 255),
        Outline    = Color3.fromRGB(40, 40, 40),
        Font       = Color3.new(1, 1, 1),
        Red        = Color3.fromRGB(255, 50, 50),
        Dark       = Color3.new(0, 0, 0),
    },

    Font      = Font.fromEnum(Enum.Font.Code),
    TweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Toggled   = false,

    Notifications = {},
    ActiveTab     = nil,
    Tabs          = {},
}

-- ════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════
local function New(cls, props, parent)
    local obj = Instance.new(cls)
    for k, v in pairs(props or {}) do
        -- resolve scheme strings
        if typeof(v) == "string" and Library.Scheme[v] then
            obj[k] = Library.Scheme[v]
        else
            obj[k] = v
        end
    end
    if parent then obj.Parent = parent end
    return obj
end

local function Tween(obj, props)
    TweenService:Create(obj, Library.TweenInfo, props):Play()
end

local function Corner(parent, r)
    return New("UICorner", { CornerRadius = UDim.new(0, r or 4) }, parent)
end

local function Stroke(parent, col, thick)
    local s = New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, parent)
    s.Color     = col or Library.Scheme.Outline
    s.Thickness = thick or 1
    return s
end

local function Pad(parent, t, b, l, r)
    local p = New("UIPadding", {}, parent)
    p.PaddingTop    = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft   = UDim.new(0, l or 0)
    p.PaddingRight  = UDim.new(0, r or 0)
    return p
end

local function GetTextSize(text, size, font, bounds)
    return TextService:GetTextSize(text, size, Enum.Font.Code, bounds or Vector2.new(math.huge, math.huge))
end

function Library:SafeCall(fn, ...)
    if type(fn) == "function" then
        local ok, err = pcall(fn, ...)
        if not ok then warn("[PhantomUI] Callback error:", err) end
    end
end

function Library:GiveSignal(conn)
    table.insert(self.Signals, conn)
    return conn
end

-- ════════════════════════════════════════════════
-- SCREENGUI
-- ════════════════════════════════════════════════
local GuiName = "PhantomUI_V1"
if CoreGui:FindFirstChild(GuiName) then CoreGui[GuiName]:Destroy() end

local ScreenGui = New("ScreenGui", {
    Name           = GuiName,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder   = 999,
    ResetOnSpawn   = false,
}, CoreGui)

Library.ScreenGui = ScreenGui

-- ════════════════════════════════════════════════
-- TOOLTIP
-- ════════════════════════════════════════════════
local TooltipFrame = New("Frame", {
    BackgroundColor3 = Library.Scheme.Main,
    Size             = UDim2.fromOffset(0, 0),
    AutomaticSize    = Enum.AutomaticSize.XY,
    Visible          = false,
    ZIndex           = 200,
    BorderSizePixel  = 0,
}, ScreenGui)
Corner(TooltipFrame, 3)
Stroke(TooltipFrame, Library.Scheme.Outline)
Pad(TooltipFrame, 4, 4, 8, 8)

local TooltipLabel = New("TextLabel", {
    BackgroundTransparency = 1,
    Text                   = "",
    FontFace               = Library.Font,
    TextSize               = 12,
    TextColor3             = Library.Scheme.Font,
    AutomaticSize          = Enum.AutomaticSize.XY,
    ZIndex                 = 201,
    RichText               = false,
}, TooltipFrame)

RunService.RenderStepped:Connect(function()
    if TooltipFrame.Visible then
        local mp = UserInputService:GetMouseLocation()
        TooltipFrame.Position = UDim2.fromOffset(mp.X + 14, mp.Y + 14)
    end
end)

local function AddTooltip(frame, tooltip)
    if not tooltip or tooltip == "" then return end
    frame.MouseEnter:Connect(function()
        TooltipLabel.Text = tooltip
        TooltipFrame.Visible = true
    end)
    frame.MouseLeave:Connect(function()
        TooltipFrame.Visible = false
    end)
end

-- ════════════════════════════════════════════════
-- NOTIFICAÇÕES
-- ════════════════════════════════════════════════
local NotifHolder = New("Frame", {
    BackgroundTransparency = 1,
    AnchorPoint            = Vector2.new(1, 1),
    Position               = UDim2.new(1, -10, 1, -10),
    Size                   = UDim2.new(0, 280, 1, 0),
    ZIndex                 = 150,
}, ScreenGui)

New("UIListLayout", {
    SortOrder         = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Padding           = UDim.new(0, 6),
}, NotifHolder)

function Library:Notify(cfg)
    cfg = cfg or {}
    local title    = cfg.Title    or "Aviso"
    local content  = cfg.Content  or ""
    local duration = cfg.Duration or 4

    local Card = New("Frame", {
        BackgroundColor3 = Library.Scheme.Main,
        Size             = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        BorderSizePixel  = 0,
    }, NotifHolder)
    Corner(Card, 4)
    local CardStroke = Stroke(Card, Library.Scheme.Accent)

    -- Barra colorida esquerda
    New("Frame", {
        BackgroundColor3 = Library.Scheme.Accent,
        Size             = UDim2.new(0, 2, 1, 0),
        BorderSizePixel  = 0,
    }, Card)

    New("TextLabel", {
        BackgroundTransparency = 1,
        Text                   = title,
        FontFace               = Library.Font,
        TextSize               = 13,
        TextColor3             = Library.Scheme.Accent,
        Size                   = UDim2.new(1, -14, 0, 18),
        Position               = UDim2.fromOffset(10, 8),
        TextXAlignment         = Enum.TextXAlignment.Left,
        RichText               = false,
    }, Card)

    New("TextLabel", {
        BackgroundTransparency = 1,
        Text                   = content,
        FontFace               = Library.Font,
        TextSize               = 12,
        TextColor3             = Library.Scheme.Font,
        TextTransparency       = 0.2,
        Size                   = UDim2.new(1, -14, 0, 28),
        Position               = UDim2.fromOffset(10, 26),
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextWrapped            = true,
        RichText               = false,
    }, Card)

    -- Progress bar
    local PBar = New("Frame", {
        BackgroundColor3 = Library.Scheme.Accent,
        Size             = UDim2.new(1, -2, 0, 2),
        Position         = UDim2.new(0, 2, 1, -2),
        BorderSizePixel  = 0,
    }, Card)

    -- Anima entrada
    Tween(Card, { Size = UDim2.new(1, 0, 0, 62) })
    TweenService:Create(PBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 2, 0, 2)
    }):Play()

    task.delay(duration, function()
        Tween(Card, { Size = UDim2.new(1, 0, 0, 0) })
        task.wait(0.15)
        Card:Destroy()
    end)
end

-- ════════════════════════════════════════════════
-- DRAG
-- ════════════════════════════════════════════════
local function MakeDraggable(frame, handle)
    local dragging, dragStart, startPos, dragConn
    handle.InputBegan:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        dragging  = true
        dragStart = i.Position
        startPos  = frame.Position
        dragConn  = i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then
                dragging = false
                if dragConn then dragConn:Disconnect() end
            end
        end)
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

-- ════════════════════════════════════════════════
-- CREATE WINDOW
-- ════════════════════════════════════════════════
function Library:CreateWindow(cfg)
    cfg = cfg or {}
    local title   = cfg.Title   or "Phantom Hub"
    local footer  = cfg.Footer  or "v1.0"
    local keybind = cfg.Keybind or Enum.KeyCode.RightControl

    -- ── Janela Principal ──────────────────────────────
    local MainFrame = New("Frame", {
        Name             = "MainFrame",
        BackgroundColor3 = Library.Scheme.Background,
        Size             = UDim2.fromOffset(740, 560),
        Position         = UDim2.fromScale(0.5, 0.5),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    }, ScreenGui)
    Corner(MainFrame, 5)
    Stroke(MainFrame, Library.Scheme.Outline)

    MainFrame.Visible = false

    -- ── Topbar ────────────────────────────────────────
    local Topbar = New("Frame", {
        BackgroundColor3 = Library.Scheme.Main,
        Size             = UDim2.new(1, 0, 0, 38),
        BorderSizePixel  = 0,
    }, MainFrame)

    -- linha embaixo do topbar
    New("Frame", {
        BackgroundColor3 = Library.Scheme.Outline,
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BorderSizePixel  = 0,
    }, Topbar)

    MakeDraggable(MainFrame, Topbar)

    New("TextLabel", {
        BackgroundTransparency = 1,
        Text                   = title,
        FontFace               = Library.Font,
        TextSize               = 14,
        TextColor3             = Library.Scheme.Font,
        Size                   = UDim2.new(0.5, 0, 1, 0),
        Position               = UDim2.fromOffset(10, 0),
        TextXAlignment         = Enum.TextXAlignment.Left,
        RichText               = false,
    }, Topbar)

    -- Footer no canto direito do topbar
    New("TextLabel", {
        BackgroundTransparency = 1,
        Text                   = footer,
        FontFace               = Library.Font,
        TextSize               = 12,
        TextColor3             = Library.Scheme.Font,
        TextTransparency       = 0.55,
        Size                   = UDim2.new(0.5, -10, 1, 0),
        Position               = UDim2.new(0.5, 0, 0, 0),
        TextXAlignment         = Enum.TextXAlignment.Right,
        RichText               = false,
    }, Topbar)

    -- ── Search Bar ────────────────────────────────────
    local SearchBar = New("Frame", {
        BackgroundColor3 = Library.Scheme.Main,
        Size             = UDim2.new(1, 0, 0, 30),
        Position         = UDim2.fromOffset(0, 38),
        BorderSizePixel  = 0,
    }, MainFrame)

    New("Frame", {
        BackgroundColor3 = Library.Scheme.Outline,
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BorderSizePixel  = 0,
    }, SearchBar)

    local SearchBox = New("TextBox", {
        BackgroundTransparency = 1,
        PlaceholderText        = "Pesquisar...",
        PlaceholderColor3      = Color3.fromRGB(90, 90, 90),
        Text                   = "",
        FontFace               = Library.Font,
        TextSize               = 13,
        TextColor3             = Library.Scheme.Font,
        Size                   = UDim2.new(1, -20, 1, 0),
        Position               = UDim2.fromOffset(10, 0),
        TextXAlignment         = Enum.TextXAlignment.Left,
        ClearTextOnFocus       = false,
        RichText               = false,
    }, SearchBar)

    -- ── Sidebar ───────────────────────────────────────
    local Sidebar = New("Frame", {
        BackgroundColor3 = Library.Scheme.Main,
        Size             = UDim2.new(0, 128, 1, -68),
        Position         = UDim2.fromOffset(0, 68),
        BorderSizePixel  = 0,
    }, MainFrame)

    New("Frame", {
        BackgroundColor3 = Library.Scheme.Outline,
        Size             = UDim2.new(0, 1, 1, 0),
        Position         = UDim2.new(1, -1, 0, 0),
        BorderSizePixel  = 0,
    }, Sidebar)

    local SidebarList = New("Frame", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
    }, Sidebar)

    New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 0),
    }, SidebarList)

    -- ── Content Area ──────────────────────────────────
    local ContentArea = New("Frame", {
        BackgroundTransparency = 1,
        Position               = UDim2.fromOffset(128, 68),
        Size                   = UDim2.new(1, -128, 1, -68),
        ClipsDescendants       = true,
    }, MainFrame)

    -- ── Keybind Toggle ────────────────────────────────
    Library:GiveSignal(UserInputService.InputBegan:Connect(function(i, gp)
        if gp or Library.Unloaded then return end
        if UserInputService:GetFocusedTextBox() then return end
        if i.KeyCode == keybind then
            Library.Toggled = not Library.Toggled
            MainFrame.Visible = Library.Toggled
        end
    end))

    -- ── Window API ────────────────────────────────────
    local Window      = {}
    local ActiveTab   = nil
    local ActiveBtn   = nil

    function Window:AddTab(name)
        -- Botão na sidebar
        local TabBtn = New("TextButton", {
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, 0, 0, 30),
            Text                   = "",
            BorderSizePixel        = 0,
            AutoButtonColor        = false,
        }, SidebarList)

        -- Indicador lateral (accent bar)
        local Indicator = New("Frame", {
            BackgroundColor3 = Library.Scheme.Accent,
            Size             = UDim2.new(0, 2, 0.65, 0),
            Position         = UDim2.new(0, 0, 0.175, 0),
            BorderSizePixel  = 0,
            Visible          = false,
        }, TabBtn)

        local TabLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Text                   = name,
            FontFace               = Library.Font,
            TextSize               = 13,
            TextColor3             = Library.Scheme.Font,
            TextTransparency       = 0.55,
            Size                   = UDim2.new(1, -10, 1, 0),
            Position               = UDim2.fromOffset(10, 0),
            TextXAlignment         = Enum.TextXAlignment.Left,
            RichText               = false,
        }, TabBtn)

        -- Página da tab
        local TabPage = New("Frame", {
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, 0, 1, 0),
            Visible                = false,
        }, ContentArea)

        -- Duas colunas
        local LeftCol = New("ScrollingFrame", {
            BackgroundTransparency = 1,
            Position               = UDim2.fromOffset(6, 6),
            Size                   = UDim2.new(0.5, -9, 1, -12),
            ScrollBarThickness     = 2,
            ScrollBarImageColor3   = Library.Scheme.Outline,
            CanvasSize             = UDim2.fromOffset(0, 0),
            AutomaticCanvasSize    = Enum.AutomaticSize.Y,
            BorderSizePixel        = 0,
        }, TabPage)

        New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 6),
        }, LeftCol)

        local RightCol = New("ScrollingFrame", {
            BackgroundTransparency = 1,
            Position               = UDim2.new(0.5, 3, 0, 6),
            Size                   = UDim2.new(0.5, -9, 1, -12),
            ScrollBarThickness     = 2,
            ScrollBarImageColor3   = Library.Scheme.Outline,
            CanvasSize             = UDim2.fromOffset(0, 0),
            AutomaticCanvasSize    = Enum.AutomaticSize.Y,
            BorderSizePixel        = 0,
        }, TabPage)

        New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 6),
        }, RightCol)

        local function SelectTab()
            if ActiveTab then ActiveTab.Visible = false end
            if ActiveBtn then
                ActiveBtn.Indicator.Visible = false
                Tween(ActiveBtn.Label, { TextTransparency = 0.55 })
                Tween(ActiveBtn.Frame, { BackgroundTransparency = 1 })
            end
            TabPage.Visible    = true
            ActiveTab          = TabPage
            Indicator.Visible  = true
            Tween(TabLabel, { TextTransparency = 0 })
            Tween(TabBtn, { BackgroundTransparency = 0.92 })
            Library.ActiveTab = Tab
        end

        TabBtn.MouseButton1Click:Connect(SelectTab)
        TabBtn.MouseEnter:Connect(function()
            if TabPage ~= ActiveTab then
                Tween(TabBtn, { BackgroundTransparency = 0.96 })
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if TabPage ~= ActiveTab then
                Tween(TabBtn, { BackgroundTransparency = 1 })
            end
        end)

        -- guarda refs no botão para o select desativar
        TabBtn.Indicator = Indicator
        TabBtn.Label     = TabLabel
        TabBtn.Frame     = TabBtn

        if not ActiveTab then SelectTab() end

        -- ── Tab API ───────────────────────────────────
        local Tab = { _left = LeftCol, _right = RightCol, Groupboxes = {} }

        local function MakeGroupbox(col, name)
            local Holder = New("Frame", {
                BackgroundColor3 = Library.Scheme.Background,
                Size             = UDim2.new(1, 0, 0, 0),
                AutomaticSize    = Enum.AutomaticSize.Y,
                BorderSizePixel  = 0,
            }, col)
            Corner(Holder, 4)
            Stroke(Holder, Library.Scheme.Outline)

            -- Título
            New("TextLabel", {
                BackgroundTransparency = 1,
                Text                   = name,
                FontFace               = Library.Font,
                TextSize               = 14,
                TextColor3             = Library.Scheme.Font,
                Size                   = UDim2.new(1, 0, 0, 32),
                Position               = UDim2.fromOffset(0, 0),
                TextXAlignment         = Enum.TextXAlignment.Left,
                RichText               = false,
            }, Holder):SetAttribute("Pad", true)

            -- Linha divisória do título
            New("Frame", {
                BackgroundColor3 = Library.Scheme.Outline,
                Size             = UDim2.new(1, 0, 0, 1),
                Position         = UDim2.fromOffset(0, 32),
                BorderSizePixel  = 0,
            }, Holder)

            -- Container dos elementos
            local Container = New("Frame", {
                BackgroundTransparency = 1,
                Position               = UDim2.fromOffset(0, 33),
                Size                   = UDim2.new(1, 0, 0, 0),
                AutomaticSize          = Enum.AutomaticSize.Y,
            }, Holder)
            Pad(Container, 6, 8, 8, 8)

            New("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding   = UDim.new(0, 6),
            }, Container)

            -- Groupbox API
            local GB = { Container = Container, Holder = Holder, Elements = {} }

            -- Adiciona label de título com padding
            local TitleLabel = Holder:FindFirstChildWhichIsA("TextLabel")
            if TitleLabel then
                Pad(TitleLabel, 0, 0, 10, 0)
            end

            -- ── TOGGLE ──────────────────────────────────
            function GB:AddToggle(idx, info)
                info = info or {}
                local text     = info.Text     or idx
                local default  = info.Default  or false
                local tooltip  = info.Tooltip
                local callback = info.Callback or function() end
                local disabled = info.Disabled or false

                local Toggle = {
                    Value    = default,
                    Text     = text,
                    Disabled = disabled,
                    Type     = "Toggle",
                    Addons   = {},
                    _changed = {},
                }

                local Row = New("TextButton", {
                    BackgroundTransparency = 1,
                    Size                   = UDim2.new(1, 0, 0, 18),
                    Text                   = "",
                    AutoButtonColor        = false,
                    Active                 = not disabled,
                }, Container)

                -- Checkbox box
                local Box = New("Frame", {
                    BackgroundColor3 = Library.Scheme.Main,
                    Size             = UDim2.fromOffset(14, 14),
                    Position         = UDim2.fromOffset(0, 2),
                    BorderSizePixel  = 0,
                }, Row)
                Corner(Box, 2)
                local BoxStroke = Stroke(Box, Library.Scheme.Outline)

                -- Checkmark (linha diagonal simulada com label)
                local Check = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Text                   = "✓",
                    FontFace               = Library.Font,
                    TextSize               = 12,
                    TextColor3             = Library.Scheme.Accent,
                    Size                   = UDim2.new(1, 0, 1, 0),
                    Visible                = default,
                    TextXAlignment         = Enum.TextXAlignment.Center,
                    RichText               = false,
                }, Box)

                -- Label texto
                local TextLbl = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Text                   = text,
                    FontFace               = Library.Font,
                    TextSize               = 14,
                    TextColor3             = Library.Scheme.Font,
                    TextTransparency       = disabled and 0.6 or (default and 0.0 or 0.4),
                    Size                   = UDim2.new(1, -22, 1, 0),
                    Position               = UDim2.fromOffset(20, 0),
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    RichText               = false,
                }, Row)

                -- Addons (ColorPicker, KeyPicker) ficam na mesma linha
                local AddonsFrame = New("Frame", {
                    BackgroundTransparency = 1,
                    AnchorPoint            = Vector2.new(1, 0.5),
                    Position               = UDim2.new(1, 0, 0.5, 0),
                    Size                   = UDim2.fromOffset(0, 18),
                    AutomaticSize          = Enum.AutomaticSize.X,
                }, Row)
                New("UIListLayout", {
                    FillDirection        = Enum.FillDirection.Horizontal,
                    HorizontalAlignment  = Enum.HorizontalAlignment.Right,
                    Padding              = UDim.new(0, 4),
                    SortOrder            = Enum.SortOrder.LayoutOrder,
                }, AddonsFrame)

                local function SetValue(val, skipCB)
                    Toggle.Value = val
                    Check.Visible = val
                    Tween(TextLbl, { TextTransparency = val and 0 or (disabled and 0.6 or 0.4) })
                    if val then
                        Tween(BoxStroke, { Color = Library.Scheme.Accent })
                    else
                        Tween(BoxStroke, { Color = Library.Scheme.Outline })
                    end
                    Library.Toggles[idx] = Toggle
                    if not skipCB then Library:SafeCall(callback, val) end
                    for _, fn in pairs(Toggle._changed) do Library:SafeCall(fn, val) end
                end

                Row.MouseButton1Click:Connect(function()
                    if disabled then return end
                    SetValue(not Toggle.Value)
                end)
                Row.MouseEnter:Connect(function()
                    if not disabled then Tween(TextLbl, { TextTransparency = Toggle.Value and 0 or 0.2 }) end
                end)
                Row.MouseLeave:Connect(function()
                    Tween(TextLbl, { TextTransparency = Toggle.Value and 0 or (disabled and 0.6 or 0.4) })
                end)

                if tooltip then AddTooltip(Row, tooltip) end

                function Toggle:Set(val)     SetValue(val, false) end
                function Toggle:OnChanged(fn) table.insert(self._changed, fn) end

                Library.Toggles[idx] = Toggle
                Toggle.Row           = Row
                Toggle.AddonsFrame   = AddonsFrame

                table.insert(GB.Elements, Toggle)

                -- ── COLOR PICKER ADDON ───────────────────────
                function Toggle:AddColorPicker(cpIdx, cpInfo)
                    cpInfo = cpInfo or {}
                    local cpDefault  = cpInfo.Default  or Color3.new(1,1,1)
                    local cpCallback = cpInfo.Callback or function() end
                    local cpTooltip  = cpInfo.Tooltip

                    local CP = {
                        Value = cpDefault,
                        Type  = "ColorPicker",
                        _changed = {},
                    }

                    -- Preview box (abre o picker ao clicar)
                    local PreviewBtn = New("TextButton", {
                        BackgroundColor3 = cpDefault,
                        Size             = UDim2.fromOffset(16, 16),
                        Text             = "",
                        AutoButtonColor  = false,
                        BorderSizePixel  = 0,
                    }, AddonsFrame)
                    Corner(PreviewBtn, 3)
                    Stroke(PreviewBtn, Library.Scheme.Outline)

                    -- Janela do color picker (popup)
                    local PickerOpen = false
                    local PickerFrame = New("Frame", {
                        BackgroundColor3 = Library.Scheme.Main,
                        Size             = UDim2.fromOffset(200, 130),
                        Position         = UDim2.new(0, -202, 0, 0),
                        Visible          = false,
                        ZIndex           = 20,
                        BorderSizePixel  = 0,
                    }, PreviewBtn)
                    Corner(PickerFrame, 4)
                    Stroke(PickerFrame, Library.Scheme.Outline)
                    Pad(PickerFrame, 8, 8, 8, 8)

                    local R = math.floor(cpDefault.R * 255)
                    local G = math.floor(cpDefault.G * 255)
                    local B = math.floor(cpDefault.B * 255)

                    local function UpdateCP(skipCB)
                        local col = Color3.fromRGB(R, G, B)
                        CP.Value = col
                        PreviewBtn.BackgroundColor3 = col
                        Library.Options[cpIdx] = CP
                        if not skipCB then
                            Library:SafeCall(cpCallback, col)
                            for _, fn in pairs(CP._changed) do Library:SafeCall(fn, col) end
                        end
                    end

                    local function MakeRGBSlider(axis, color, yPos, initVal)
                        local AxisLabel = New("TextLabel", {
                            BackgroundTransparency = 1,
                            Text                   = axis,
                            FontFace               = Library.Font,
                            TextSize               = 11,
                            TextColor3             = color,
                            Size                   = UDim2.fromOffset(12, 14),
                            Position               = UDim2.fromOffset(0, yPos),
                            ZIndex                 = 21,
                        }, PickerFrame)

                        local Track = New("Frame", {
                            BackgroundColor3 = Library.Scheme.Background,
                            Size             = UDim2.new(1, -36, 0, 4),
                            Position         = UDim2.new(0, 16, 0, yPos + 5),
                            BorderSizePixel  = 0,
                            ZIndex           = 21,
                        }, PickerFrame)
                        Corner(Track, 2)

                        local Fill = New("Frame", {
                            BackgroundColor3 = color,
                            Size             = UDim2.new(initVal / 255, 0, 1, 0),
                            BorderSizePixel  = 0,
                            ZIndex           = 22,
                        }, Track)
                        Corner(Fill, 2)

                        local ValLbl = New("TextLabel", {
                            BackgroundTransparency = 1,
                            Text                   = tostring(initVal),
                            FontFace               = Library.Font,
                            TextSize               = 11,
                            TextColor3             = Library.Scheme.Font,
                            TextTransparency       = 0.3,
                            Size                   = UDim2.fromOffset(20, 14),
                            Position               = UDim2.new(1, -18, 0, yPos),
                            TextXAlignment         = Enum.TextXAlignment.Right,
                            ZIndex                 = 21,
                        }, PickerFrame)

                        local HB = New("TextButton", {
                            BackgroundTransparency = 1,
                            Size                   = UDim2.new(1, 0, 0, 18),
                            Position               = UDim2.new(0, 0, 0, yPos - 3),
                            Text                   = "",
                            ZIndex                 = 23,
                        }, Track)

                        local dragging = false
                        HB.InputBegan:Connect(function(i)
                            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
                        end)
                        UserInputService.InputEnded:Connect(function(i)
                            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                        end)
                        UserInputService.InputChanged:Connect(function(i)
                            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                                local rel = math.clamp((i.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                                local val = math.floor(rel * 255)
                                Fill.Size = UDim2.new(rel, 0, 1, 0)
                                ValLbl.Text = tostring(val)
                                if axis == "R" then R = val
                                elseif axis == "G" then G = val
                                else B = val end
                                UpdateCP()
                            end
                        end)
                    end

                    MakeRGBSlider("R", Color3.fromRGB(255, 90, 90),  0, R)
                    MakeRGBSlider("G", Color3.fromRGB(80, 220, 80),  32, G)
                    MakeRGBSlider("B", Color3.fromRGB(90, 130, 255), 64, B)

                    -- Hex input
                    local HexBox = New("TextBox", {
                        BackgroundColor3 = Library.Scheme.Background,
                        Size             = UDim2.new(1, 0, 0, 20),
                        Position         = UDim2.fromOffset(0, 100),
                        Text             = string.format("#%02X%02X%02X", R, G, B),
                        FontFace         = Library.Font,
                        TextSize         = 12,
                        TextColor3       = Library.Scheme.Font,
                        ClearTextOnFocus = false,
                        ZIndex           = 21,
                        BorderSizePixel  = 0,
                    }, PickerFrame)
                    Corner(HexBox, 3)
                    Pad(HexBox, 0, 0, 6, 0)
                    Stroke(HexBox, Library.Scheme.Outline)

                    HexBox.FocusLost:Connect(function()
                        local hex = HexBox.Text:gsub("#", "")
                        if #hex == 6 then
                            R = tonumber(hex:sub(1,2), 16) or R
                            G = tonumber(hex:sub(3,4), 16) or G
                            B = tonumber(hex:sub(5,6), 16) or B
                            UpdateCP()
                        end
                    end)

                    PreviewBtn.MouseButton1Click:Connect(function()
                        PickerOpen = not PickerOpen
                        PickerFrame.Visible = PickerOpen
                    end)

                    -- fecha ao clicar fora
                    UserInputService.InputBegan:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton1 and PickerOpen then
                            local mp = UserInputService:GetMouseLocation()
                            local abs = PickerFrame.AbsolutePosition
                            local sz  = PickerFrame.AbsoluteSize
                            if mp.X < abs.X or mp.X > abs.X + sz.X or mp.Y < abs.Y or mp.Y > abs.Y + sz.Y then
                                if mp.X < PreviewBtn.AbsolutePosition.X or mp.X > PreviewBtn.AbsolutePosition.X + 16 then
                                    PickerOpen = false
                                    PickerFrame.Visible = false
                                end
                            end
                        end
                    end)

                    function CP:Set(col)
                        R = math.floor(col.R * 255)
                        G = math.floor(col.G * 255)
                        B = math.floor(col.B * 255)
                        UpdateCP(false)
                    end
                    function CP:OnChanged(fn) table.insert(self._changed, fn) end

                    Library.Options[cpIdx] = CP
                    if cpTooltip then AddTooltip(PreviewBtn, cpTooltip) end

                    return Toggle
                end

                -- ── KEYPICKER ADDON ──────────────────────────
                function Toggle:AddKeyPicker(kpIdx, kpInfo)
                    kpInfo = kpInfo or {}
                    local kpDefault  = kpInfo.Default  or "None"
                    local kpMode     = kpInfo.Mode     or "Toggle"
                    local kpCallback = kpInfo.Callback or function() end

                    local KP = {
                        Value   = kpDefault,
                        Mode    = kpMode,
                        Type    = "KeyPicker",
                        Binding = false,
                    }

                    local KPBtn = New("TextButton", {
                        BackgroundColor3 = Library.Scheme.Main,
                        Size             = UDim2.fromOffset(60, 16),
                        Text             = "[" .. kpDefault .. "]",
                        FontFace         = Library.Font,
                        TextSize         = 11,
                        TextColor3       = Library.Scheme.Font,
                        TextTransparency = 0.3,
                        AutoButtonColor  = false,
                        BorderSizePixel  = 0,
                    }, AddonsFrame)
                    Corner(KPBtn, 3)
                    Stroke(KPBtn, Library.Scheme.Outline)

                    local function UpdateKPBtn()
                        KPBtn.Text = "[" .. KP.Value .. "]"
                    end

                    KPBtn.MouseButton1Click:Connect(function()
                        KP.Binding = true
                        KPBtn.Text = "[...]"
                        Tween(KPBtn, { TextColor3 = Library.Scheme.Accent })
                    end)

                    Library:GiveSignal(UserInputService.InputBegan:Connect(function(i, gp)
                        if not KP.Binding then
                            if i.KeyCode.Name == KP.Value and not gp then
                                if kpMode == "Toggle" then
                                    Toggle:Set(not Toggle.Value)
                                elseif kpMode == "Hold" then
                                    Toggle:Set(true)
                                end
                                Library:SafeCall(kpCallback, Toggle.Value)
                            end
                            return
                        end
                        if gp then return end
                        if i.UserInputType == Enum.UserInputType.Keyboard then
                            KP.Value = i.KeyCode.Name
                            KP.Binding = false
                            UpdateKPBtn()
                            Tween(KPBtn, { TextColor3 = Library.Scheme.Font })
                            Library.Options[kpIdx] = KP
                        end
                    end))

                    Library:GiveSignal(UserInputService.InputEnded:Connect(function(i)
                        if kpMode == "Hold" and i.KeyCode.Name == KP.Value then
                            Toggle:Set(false)
                            Library:SafeCall(kpCallback, false)
                        end
                    end))

                    Library.Options[kpIdx] = KP
                    return Toggle
                end

                SetValue(default, true)
                return Toggle
            end

            -- ── BUTTON ──────────────────────────────────
            function GB:AddButton(info)
                info = info or {}
                local text    = info.Text    or "Button"
                local func    = info.Func    or info.Callback or function() end
                local risky   = info.Risky   or false
                local tooltip = info.Tooltip
                local disabled = info.Disabled or false

                local Row = New("Frame", {
                    BackgroundTransparency = 1,
                    Size                   = UDim2.new(1, 0, 0, 20),
                }, Container)

                New("UIListLayout", {
                    FillDirection      = Enum.FillDirection.Horizontal,
                    HorizontalFlex     = Enum.UIFlexAlignment.Fill,
                    Padding            = UDim.new(0, 6),
                    SortOrder          = Enum.SortOrder.LayoutOrder,
                }, Row)

                local Btn = New("TextButton", {
                    BackgroundColor3 = Library.Scheme.Main,
                    Size             = UDim2.fromScale(1, 1),
                    Text             = text,
                    FontFace         = Library.Font,
                    TextSize         = 14,
                    TextColor3       = risky and Library.Scheme.Red or Library.Scheme.Font,
                    TextTransparency = disabled and 0.6 or 0.4,
                    AutoButtonColor  = false,
                    Active           = not disabled,
                    BorderSizePixel  = 0,
                }, Row)
                Corner(Btn, 3)
                local BtnStroke = Stroke(Btn, Library.Scheme.Outline)

                Btn.MouseEnter:Connect(function()
                    if not disabled then Tween(Btn, { TextTransparency = 0 }) end
                end)
                Btn.MouseLeave:Connect(function()
                    Tween(Btn, { TextTransparency = disabled and 0.6 or 0.4 })
                end)
                Btn.MouseButton1Click:Connect(function()
                    if disabled then return end
                    Library:SafeCall(func)
                end)

                if tooltip then AddTooltip(Btn, tooltip) end

                local BtnObj = { Text = text, Type = "Button" }

                -- Suporte a :AddButton() em cadeia (sub-botão)
                function BtnObj:AddButton(subInfo)
                    subInfo = subInfo or {}
                    local subText = subInfo.Text or "Button"
                    local subFunc = subInfo.Func or subInfo.Callback or function() end

                    local SubBtn = New("TextButton", {
                        BackgroundColor3 = Library.Scheme.Main,
                        Size             = UDim2.fromScale(1, 1),
                        Text             = subText,
                        FontFace         = Library.Font,
                        TextSize         = 14,
                        TextColor3       = Library.Scheme.Font,
                        TextTransparency = 0.4,
                        AutoButtonColor  = false,
                        BorderSizePixel  = 0,
                    }, Row)
                    Corner(SubBtn, 3)
                    Stroke(SubBtn, Library.Scheme.Outline)

                    SubBtn.MouseEnter:Connect(function() Tween(SubBtn, { TextTransparency = 0 }) end)
                    SubBtn.MouseLeave:Connect(function() Tween(SubBtn, { TextTransparency = 0.4 }) end)
                    SubBtn.MouseButton1Click:Connect(function() Library:SafeCall(subFunc) end)

                    return BtnObj
                end

                table.insert(GB.Elements, { Text = text, Type = "Button", Holder = Row, Visible = not disabled })
                return BtnObj
            end

            -- ── SLIDER ──────────────────────────────────
            function GB:AddSlider(idx, info)
                info = info or {}
                local text     = info.Text     or idx
                local min      = info.Min      or 0
                local max      = info.Max      or 100
                local default  = math.clamp(info.Default or min, min, max)
                local suffix   = info.Suffix   or ""
                local rounding = info.Rounding or 0
                local tooltip  = info.Tooltip
                local callback = info.Callback or function() end

                local Slider = {
                    Value = default,
                    Type  = "Slider",
                    _changed = {},
                }

                local Wrapper = New("Frame", {
                    BackgroundTransparency = 1,
                    Size                   = UDim2.new(1, 0, 0, 38),
                }, Container)

                -- Label
                New("TextLabel", {
                    BackgroundTransparency = 1,
                    Text                   = text,
                    FontFace               = Library.Font,
                    TextSize               = 13,
                    TextColor3             = Library.Scheme.Font,
                    TextTransparency       = 0.2,
                    Size                   = UDim2.new(0.65, 0, 0, 18),
                    Position               = UDim2.fromOffset(0, 0),
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    RichText               = false,
                }, Wrapper)

                local ValLbl = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Text                   = tostring(default) .. suffix,
                    FontFace               = Library.Font,
                    TextSize               = 12,
                    TextColor3             = Library.Scheme.Accent,
                    Size                   = UDim2.new(0.35, -4, 0, 18),
                    Position               = UDim2.new(0.65, 4, 0, 0),
                    TextXAlignment         = Enum.TextXAlignment.Right,
                    RichText               = false,
                }, Wrapper)

                -- Track
                local Track = New("Frame", {
                    BackgroundColor3 = Library.Scheme.Outline,
                    Size             = UDim2.new(1, 0, 0, 4),
                    Position         = UDim2.fromOffset(0, 24),
                    BorderSizePixel  = 0,
                }, Wrapper)
                Corner(Track, 2)

                local ratio = (default - min) / (max - min)
                local Fill = New("Frame", {
                    BackgroundColor3 = Library.Scheme.Accent,
                    Size             = UDim2.new(ratio, 0, 1, 0),
                    BorderSizePixel  = 0,
                }, Track)
                Corner(Fill, 2)

                -- Thumb
                New("Frame", {
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    AnchorPoint      = Vector2.new(0.5, 0.5),
                    Size             = UDim2.fromOffset(8, 8),
                    Position         = UDim2.new(ratio, 0, 0.5, 0),
                    BorderSizePixel  = 0,
                }, Fill)
                Corner(Fill:FindFirstChildOfClass("Frame"), 4)

                local HitBox = New("TextButton", {
                    BackgroundTransparency = 1,
                    Size                   = UDim2.new(1, 0, 0, 20),
                    Position               = UDim2.new(0, 0, 0.5, -10),
                    Text                   = "",
                    ZIndex                 = 5,
                }, Track)

                local function Round(v)
                    if rounding == 0 then return math.floor(v + 0.5) end
                    return math.floor(v * (10^rounding) + 0.5) / (10^rounding)
                end

                local function UpdateSlider(v, skipCB)
                    local clamped = math.clamp(v, min, max)
                    Slider.Value  = Round(clamped)
                    local r = (clamped - min) / (max - min)
                    Tween(Fill, { Size = UDim2.new(r, 0, 1, 0) })
                    local thumb = Fill:FindFirstChildOfClass("Frame")
                    if thumb then thumb.Position = UDim2.new(1, 0, 0.5, 0) end
                    ValLbl.Text = tostring(Slider.Value) .. suffix
                    Library.Options[idx] = Slider
                    if not skipCB then
                        Library:SafeCall(callback, Slider.Value)
                        for _, fn in pairs(Slider._changed) do Library:SafeCall(fn, Slider.Value) end
                    end
                end

                local dragging = false
                HitBox.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
                end)
                Library:GiveSignal(UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end))
                Library:GiveSignal(UserInputService.InputChanged:Connect(function(i)
                    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                        local rel = math.clamp((i.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                        UpdateSlider(min + (max - min) * rel)
                    end
                end))

                if tooltip then AddTooltip(Wrapper, tooltip) end

                function Slider:Set(v) UpdateSlider(v, false) end
                function Slider:OnChanged(fn) table.insert(self._changed, fn) end

                Library.Options[idx] = Slider
                UpdateSlider(default, true)

                table.insert(GB.Elements, { Text = text, Type = "Slider", Holder = Wrapper, Visible = true })
                return Slider
            end

            -- ── DROPDOWN ────────────────────────────────
            function GB:AddDropdown(idx, info)
                info = info or {}
                local text     = info.Text     or idx
                local values   = info.Values   or {}
                local multi    = info.Multi    or false
                local tooltip  = info.Tooltip
                local callback = info.Callback or function() end
                local disabled = info.Disabled or false

                -- resolve default
                local default
                if multi then
                    default = {}
                else
                    if typeof(info.Default) == "number" then
                        default = values[info.Default]
                    else
                        default = info.Default or (values[1])
                    end
                end

                local Drop = {
                    Value    = multi and {} or default,
                    Values   = values,
                    Multi    = multi,
                    Type     = "Dropdown",
                    _open    = false,
                    _changed = {},
                }

                local H_closed = 22
                local H_opt    = 20

                local Wrapper = New("Frame", {
                    BackgroundTransparency = 1,
                    Size                   = UDim2.new(1, 0, 0, 38),
                    ClipsDescendants       = false,
                }, Container)

                New("TextLabel", {
                    BackgroundTransparency = 1,
                    Text                   = text,
                    FontFace               = Library.Font,
                    TextSize               = 13,
                    TextColor3             = Library.Scheme.Font,
                    TextTransparency       = 0.2,
                    Size                   = UDim2.new(1, 0, 0, 16),
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    RichText               = false,
                }, Wrapper)

                local Head = New("TextButton", {
                    BackgroundColor3 = Library.Scheme.Main,
                    Size             = UDim2.new(1, 0, 0, H_closed),
                    Position         = UDim2.fromOffset(0, 17),
                    Text             = "",
                    AutoButtonColor  = false,
                    Active           = not disabled,
                    BorderSizePixel  = 0,
                    ZIndex           = 10,
                }, Wrapper)
                Corner(Head, 3)
                Stroke(Head, Library.Scheme.Outline)

                local function GetDisplayText()
                    if multi then
                        local keys = {}
                        for k, v in pairs(Drop.Value) do if v then table.insert(keys, k) end end
                        return #keys == 0 and "Nenhum" or table.concat(keys, ", ")
                    end
                    return tostring(Drop.Value or "Selecionar")
                end

                local HeadLabel = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Text                   = GetDisplayText(),
                    FontFace               = Library.Font,
                    TextSize               = 13,
                    TextColor3             = Library.Scheme.Font,
                    TextTransparency       = disabled and 0.6 or 0.3,
                    Size                   = UDim2.new(1, -24, 1, 0),
                    Position               = UDim2.fromOffset(8, 0),
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    RichText               = false,
                    ZIndex                 = 11,
                }, Head)

                -- Seta
                local Arrow = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Text                   = "▾",
                    FontFace               = Library.Font,
                    TextSize               = 14,
                    TextColor3             = Library.Scheme.Font,
                    TextTransparency       = 0.4,
                    Size                   = UDim2.fromOffset(16, H_closed),
                    Position               = UDim2.new(1, -20, 0, 0),
                    ZIndex                 = 11,
                }, Head)

                -- Menu de opções (aparece acima do container)
                local Menu = New("Frame", {
                    BackgroundColor3 = Library.Scheme.Main,
                    Size             = UDim2.new(1, 0, 0, 0),
                    Position         = UDim2.new(0, 0, 1, 2),
                    Visible          = false,
                    ZIndex           = 50,
                    BorderSizePixel  = 0,
                    ClipsDescendants = true,
                }, Head)
                Corner(Menu, 3)
                Stroke(Menu, Library.Scheme.Outline)

                local MenuList = New("Frame", {
                    BackgroundTransparency = 1,
                    Size                   = UDim2.new(1, 0, 0, 0),
                    AutomaticSize          = Enum.AutomaticSize.Y,
                    ZIndex                 = 51,
                }, Menu)
                New("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding   = UDim.new(0, 0),
                }, MenuList)
                Pad(MenuList, 2, 2, 0, 0)

                local function SetValue(val, skipCB)
                    Drop.Value = val
                    HeadLabel.Text = GetDisplayText()
                    Library.Options[idx] = Drop
                    if not skipCB then
                        Library:SafeCall(callback, val)
                        for _, fn in pairs(Drop._changed) do Library:SafeCall(fn, val) end
                    end
                end

                local OptionBtns = {}

                local function BuildOptions(vals)
                    for _, c in pairs(MenuList:GetChildren()) do
                        if c:IsA("TextButton") then c:Destroy() end
                    end
                    OptionBtns = {}

                    for _, opt in ipairs(vals) do
                        local OptBtn = New("TextButton", {
                            BackgroundTransparency = 1,
                            Size                   = UDim2.new(1, 0, 0, H_opt),
                            Text                   = "",
                            AutoButtonColor        = false,
                            ZIndex                 = 52,
                            BorderSizePixel        = 0,
                        }, MenuList)

                        -- Check
                        local IsChecked = multi and (Drop.Value[opt] == true) or (Drop.Value == opt)
                        local Check2 = New("TextLabel", {
                            BackgroundTransparency = 1,
                            Text                   = IsChecked and "✓" or "",
                            FontFace               = Library.Font,
                            TextSize               = 12,
                            TextColor3             = Library.Scheme.Accent,
                            Size                   = UDim2.fromOffset(14, H_opt),
                            Position               = UDim2.fromOffset(4, 0),
                            ZIndex                 = 53,
                        }, OptBtn)

                        New("TextLabel", {
                            BackgroundTransparency = 1,
                            Text                   = tostring(opt),
                            FontFace               = Library.Font,
                            TextSize               = 13,
                            TextColor3             = Library.Scheme.Font,
                            TextTransparency       = IsChecked and 0 or 0.4,
                            Size                   = UDim2.new(1, -20, 1, 0),
                            Position               = UDim2.fromOffset(20, 0),
                            TextXAlignment         = Enum.TextXAlignment.Left,
                            ZIndex                 = 53,
                        }, OptBtn)

                        OptBtn.MouseEnter:Connect(function()
                            Tween(OptBtn, { BackgroundTransparency = 0.85 })
                        end)
                        OptBtn.MouseLeave:Connect(function()
                            Tween(OptBtn, { BackgroundTransparency = 1 })
                        end)
                        OptBtn.MouseButton1Click:Connect(function()
                            if multi then
                                Drop.Value[opt] = not Drop.Value[opt]
                                Check2.Text = Drop.Value[opt] and "✓" or ""
                                local lbl = OptBtn:FindFirstChild("TextLabel", true)
                                SetValue(Drop.Value)
                            else
                                SetValue(opt)
                                -- fecha dropdown
                                Drop._open = false
                                Tween(Menu, { Size = UDim2.new(1, 0, 0, 0) })
                                task.delay(0.15, function() Menu.Visible = false end)
                                Tween(Arrow, { Rotation = 0 })
                                BuildOptions(Drop.Values)
                            end
                        end)

                        table.insert(OptionBtns, { Btn = OptBtn, Check = Check2, Opt = opt })
                    end
                end

                BuildOptions(values)

                local function ToggleMenu()
                    if disabled then return end
                    Drop._open = not Drop._open
                    if Drop._open then
                        Menu.Visible = true
                        local totalH = #values * H_opt + 4
                        Tween(Menu, { Size = UDim2.new(1, 0, 0, totalH) })
                        Tween(Arrow, { Rotation = 180 })
                    else
                        Tween(Menu, { Size = UDim2.new(1, 0, 0, 0) })
                        task.delay(0.15, function() Menu.Visible = false end)
                        Tween(Arrow, { Rotation = 0 })
                    end
                end

                Head.MouseButton1Click:Connect(ToggleMenu)

                -- fecha ao clicar fora
                Library:GiveSignal(UserInputService.InputBegan:Connect(function(i)
                    if Drop._open and i.UserInputType == Enum.UserInputType.MouseButton1 then
                        local mp  = UserInputService:GetMouseLocation()
                        local abs = Menu.AbsolutePosition
                        local sz  = Menu.AbsoluteSize
                        if mp.X < abs.X or mp.X > abs.X + sz.X or mp.Y < abs.Y or mp.Y > abs.Y + sz.Y then
                            local habs = Head.AbsolutePosition
                            if not (mp.X >= habs.X and mp.X <= habs.X + Head.AbsoluteSize.X and mp.Y >= habs.Y and mp.Y <= habs.Y + H_closed) then
                                Drop._open = false
                                Tween(Menu, { Size = UDim2.new(1, 0, 0, 0) })
                                task.delay(0.15, function() Menu.Visible = false end)
                                Tween(Arrow, { Rotation = 0 })
                            end
                        end
                    end
                end))

                if tooltip then AddTooltip(Head, tooltip) end

                function Drop:Set(val) SetValue(val, false) end
                function Drop:SetValues(vals)
                    Drop.Values = vals
                    BuildOptions(vals)
                end
                function Drop:OnChanged(fn) table.insert(self._changed, fn) end

                Library.Options[idx] = Drop
                SetValue(default, true)

                table.insert(GB.Elements, { Text = text, Type = "Dropdown", Holder = Wrapper, Visible = true })
                return Drop
            end

            -- ── INPUT ────────────────────────────────────
            function GB:AddInput(idx, info)
                info = info or {}
                local text        = info.Text        or idx
                local placeholder = info.Placeholder or ""
                local numeric     = info.Numeric      or false
                local tooltip     = info.Tooltip
                local callback    = info.Callback     or function() end
                local finished    = info.Finished     or false

                local Input = {
                    Value = info.Default or "",
                    Type  = "Input",
                    _changed = {},
                }

                local Wrapper = New("Frame", {
                    BackgroundTransparency = 1,
                    Size                   = UDim2.new(1, 0, 0, 38),
                }, Container)

                New("TextLabel", {
                    BackgroundTransparency = 1,
                    Text                   = text,
                    FontFace               = Library.Font,
                    TextSize               = 13,
                    TextColor3             = Library.Scheme.Font,
                    TextTransparency       = 0.2,
                    Size                   = UDim2.new(1, 0, 0, 16),
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    RichText               = false,
                }, Wrapper)

                local InputBG = New("Frame", {
                    BackgroundColor3 = Library.Scheme.Main,
                    Size             = UDim2.new(1, 0, 0, 20),
                    Position         = UDim2.fromOffset(0, 17),
                    BorderSizePixel  = 0,
                }, Wrapper)
                Corner(InputBG, 3)
                local InputStroke = Stroke(InputBG, Library.Scheme.Outline)
                Pad(InputBG, 0, 0, 6, 6)

                local Box = New("TextBox", {
                    BackgroundTransparency = 1,
                    Size                   = UDim2.new(1, 0, 1, 0),
                    Text                   = Input.Value,
                    PlaceholderText        = placeholder,
                    PlaceholderColor3      = Color3.fromRGB(80, 80, 80),
                    FontFace               = Library.Font,
                    TextSize               = 13,
                    TextColor3             = Library.Scheme.Font,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    ClearTextOnFocus       = false,
                    RichText               = false,
                }, InputBG)

                Box.Focused:Connect(function()
                    Tween(InputStroke, { Color = Library.Scheme.Accent })
                end)
                Box.FocusLost:Connect(function(enter)
                    Tween(InputStroke, { Color = Library.Scheme.Outline })
                    local val = Box.Text
                    if numeric then val = tonumber(val) or Input.Value end
                    Input.Value = val
                    Library.Options[idx] = Input
                    if not finished or enter then
                        Library:SafeCall(callback, val)
                        for _, fn in pairs(Input._changed) do Library:SafeCall(fn, val) end
                    end
                end)

                Box:GetPropertyChangedSignal("Text"):Connect(function()
                    if not finished then
                        Input.Value = Box.Text
                        Library.Options[idx] = Input
                        Library:SafeCall(callback, Box.Text)
                    end
                end)

                if tooltip then AddTooltip(InputBG, tooltip) end

                function Input:Set(v) Box.Text = tostring(v); Input.Value = v end
                function Input:OnChanged(fn) table.insert(self._changed, fn) end

                Library.Options[idx] = Input
                table.insert(GB.Elements, { Text = text, Type = "Input", Holder = Wrapper, Visible = true })
                return Input
            end

            -- ── LABEL ────────────────────────────────────
            function GB:AddLabel(text, doesWrap)
                local Lbl = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Text                   = text,
                    FontFace               = Library.Font,
                    TextSize               = 13,
                    TextColor3             = Library.Scheme.Font,
                    TextTransparency       = 0.4,
                    Size                   = UDim2.new(1, 0, 0, doesWrap and 0 or 16),
                    AutomaticSize          = doesWrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    TextWrapped            = doesWrap or false,
                    RichText               = false,
                }, Container)

                local LblObj = { Type = "Label", Holder = Lbl, Text = text, Visible = true }
                function LblObj:SetText(t) Lbl.Text = t; self.Text = t end
                table.insert(GB.Elements, LblObj)
                return LblObj
            end

            -- ── DIVIDER ──────────────────────────────────
            function GB:AddDivider()
                local Div = New("Frame", {
                    BackgroundColor3 = Library.Scheme.Outline,
                    Size             = UDim2.new(1, 0, 0, 1),
                    BorderSizePixel  = 0,
                }, Container)
                table.insert(GB.Elements, { Type = "Divider", Holder = Div, Visible = true })
                return GB
            end

            -- ── RESIZE ───────────────────────────────────
            function GB:Resize()
                -- auto handled by AutomaticSize
            end

            Tab.Groupboxes[name] = GB
            return GB
        end

        function Tab:AddLeftGroupbox(name)
            return MakeGroupbox(LeftCol, name)
        end

        function Tab:AddRightGroupbox(name)
            return MakeGroupbox(RightCol, name)
        end

        table.insert(Library.Tabs, Tab)
        return Tab
    end

    -- ── Search ────────────────────────────────────────
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = SearchBox.Text:lower():match("^%s*(.-)%s*$")
        if query == "" then
            -- restore all
            for _, tab in ipairs(Library.Tabs) do
                for _, gb in pairs(tab.Groupboxes) do
                    gb.Holder.Visible = true
                    for _, el in ipairs(gb.Elements) do
                        el.Holder.Visible = el.Visible
                    end
                end
            end
            return
        end

        local activeTab = Library.ActiveTab
        if not activeTab then return end

        for _, gb in pairs(activeTab.Groupboxes) do
            local found = 0
            for _, el in ipairs(gb.Elements) do
                if el.Text and el.Text:lower():find(query, 1, true) and el.Visible then
                    el.Holder.Visible = true
                    found += 1
                elseif el.Type ~= "Divider" then
                    el.Holder.Visible = false
                end
            end
            gb.Holder.Visible = found > 0
        end
    end)

    -- Mostra janela
    Library.Toggled = true
    MainFrame.Visible = true

    return Window
end

-- ════════════════════════════════════════════════
-- UNLOAD
-- ════════════════════════════════════════════════
function Library:Unload()
    Library.Unloaded = true
    for _, conn in ipairs(Library.Signals) do
        if conn and conn.Connected then conn:Disconnect() end
    end
    if ScreenGui and ScreenGui.Parent then
        ScreenGui:Destroy()
    end
end

-- ════════════════════════════════════════════════
-- SCHEME UPDATE
-- ════════════════════════════════════════════════
function Library:SetScheme(newScheme)
    for k, v in pairs(newScheme) do
        Library.Scheme[k] = v
    end
end

getgenv().PhantomLib = Library
return Library
