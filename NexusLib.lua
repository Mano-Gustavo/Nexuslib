--[[
    ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗
    ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝
    ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗
    ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║
    ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║
    ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝

    NEXUS UI LIBRARY — V1.0
    Autor   : NexusUI
    Uso     : Scripts de Roblox (ESP, Aimbot, Admin, etc.)
    Syntax  : Inspirada em Orion + Karpware + Mano Gustavo UI

    COMPONENTES:
        Button, Toggle, Slider, Dropdown, MultiDropdown,
        ColorPicker, TextBox, Label, Paragraph, Keybind

    SISTEMAS:
        Temas em tempo real, Save/Load Config, Notificações,
        Tooltips, Drag & Drop, Minimize, Keybind global,
        Sidebar de tabs, Sections, Search
--]]

return (function()

    -----------------------------------------------------------------------
    -- SERVIÇOS
    -----------------------------------------------------------------------
    local TS          = game:GetService("TweenService")
    local UIS         = game:GetService("UserInputService")
    local CoreGui     = game:GetService("CoreGui")
    local RunService  = game:GetService("RunService")
    local HttpService = game:GetService("HttpService")
    local Players     = game:GetService("Players")
    local LP          = Players.LocalPlayer

    -----------------------------------------------------------------------
    -- BIBLIOTECA PRINCIPAL
    -----------------------------------------------------------------------
    local Lib        = {}
    Lib.Options      = {}   -- Controle externo dos componentes
    Lib.Flags        = {}   -- Valores para Save/Load
    Lib._ThemeReg    = {}   -- Objetos para atualização de tema em tempo real

    local ConfigFolder = "NexusUI/Configs"

    -- Forward declaration obrigatória
    local BuildElems

    -----------------------------------------------------------------------
    -- TEMA PADRÃO (DARK MODERN)
    -----------------------------------------------------------------------
    local Theme = {
        Background   = Color3.fromRGB(18, 18, 22),
        Sidebar      = Color3.fromRGB(14, 14, 18),
        Surface      = Color3.fromRGB(26, 26, 34),
        SurfaceHover = Color3.fromRGB(34, 34, 44),
        Header       = Color3.fromRGB(20, 20, 26),
        Accent       = Color3.fromRGB(99, 102, 241),
        AccentDark   = Color3.fromRGB(72, 75, 210),
        Text         = Color3.fromRGB(232, 232, 245),
        TextMuted    = Color3.fromRGB(130, 130, 155),
        Border       = Color3.fromRGB(42, 42, 58),
        Success      = Color3.fromRGB(52, 211, 153),
        Error        = Color3.fromRGB(248, 113, 113),
        Warning      = Color3.fromRGB(251, 191, 36),
        Info         = Color3.fromRGB(99, 102, 241),
        Font         = Enum.Font.GothamMedium,
        FontBold     = Enum.Font.GothamBold,
    }

    -----------------------------------------------------------------------
    -- SCREENGUI
    -----------------------------------------------------------------------
    local GuiName = "NexusUI_V1"
    if CoreGui:FindFirstChild(GuiName) then CoreGui[GuiName]:Destroy() end
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name           = GuiName
    ScreenGui.Parent         = CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn   = false
    ScreenGui.DisplayOrder   = 999

    -----------------------------------------------------------------------
    -- HELPERS
    -----------------------------------------------------------------------
    local function New(cls, props, parent)
        local inst = Instance.new(cls)
        if parent then inst.Parent = parent end
        for k, v in pairs(props or {}) do inst[k] = v end
        return inst
    end

    local function Tween(obj, info, props)
        TS:Create(obj, info, props):Play()
    end

    local TI_Fast   = TweenInfo.new(0.15, Enum.EasingStyle.Quart)
    local TI_Medium = TweenInfo.new(0.25, Enum.EasingStyle.Quart)

    local function Reg(obj, prop, key)
        if not Lib._ThemeReg[key] then Lib._ThemeReg[key] = {} end
        table.insert(Lib._ThemeReg[key], {o = obj, p = prop})
        if Theme[key] then obj[prop] = Theme[key] end
    end

    local function Corner(parent, r)
        return New("UICorner", {CornerRadius = UDim.new(0, r or 8)}, parent)
    end

    local function Stroke(parent, col, thick)
        return New("UIStroke", {Color = col or Theme.Border, Thickness = thick or 1}, parent)
    end

    local function Pad(parent, t, b, l, r)
        local p = New("UIPadding", {}, parent)
        p.PaddingTop    = UDim.new(0, t or 0)
        p.PaddingBottom = UDim.new(0, b or 0)
        p.PaddingLeft   = UDim.new(0, l or 0)
        p.PaddingRight  = UDim.new(0, r or 0)
        return p
    end

    -----------------------------------------------------------------------
    -- SISTEMA DE TEMA
    -----------------------------------------------------------------------
    function Lib:SetTheme(t)
        for k, v in pairs(t) do Theme[k] = v end
        for key, list in pairs(Lib._ThemeReg) do
            if Theme[key] then
                for _, item in pairs(list) do
                    if item.o and item.o.Parent then
                        Tween(item.o, TI_Medium, {[item.p] = Theme[key]})
                    end
                end
            end
        end
    end

    -----------------------------------------------------------------------
    -- TOOLTIP
    -----------------------------------------------------------------------
    local TTip = New("Frame", {
        Parent                 = ScreenGui,
        BackgroundColor3       = Color3.fromRGB(22, 22, 32),
        Size                   = UDim2.fromOffset(0, 0),
        AutomaticSize          = Enum.AutomaticSize.XY,
        Visible                = false,
        ZIndex                 = 200,
        BackgroundTransparency = 0.05,
    })
    Corner(TTip, 6)
    Stroke(TTip, Theme.Border)
    Pad(TTip, 5, 5, 10, 10)
    local TTipLabel = New("TextLabel", {
        Parent                 = TTip,
        BackgroundTransparency = 1,
        Text                   = "",
        Font                   = Theme.Font,
        TextSize               = 12,
        TextColor3             = Theme.TextMuted,
        AutomaticSize          = Enum.AutomaticSize.XY,
        ZIndex                 = 201,
    })
    RunService.RenderStepped:Connect(function()
        if TTip.Visible then
            local mp      = UIS:GetMouseLocation()
            TTip.Position = UDim2.fromOffset(mp.X + 16, mp.Y + 16)
        end
    end)
    local function AddTooltip(obj, text)
        if not text or text == "" then return end
        obj.MouseEnter:Connect(function() TTipLabel.Text = text; TTip.Visible = true end)
        obj.MouseLeave:Connect(function() TTip.Visible = false end)
    end

    -----------------------------------------------------------------------
    -- NOTIFICAÇÕES
    -----------------------------------------------------------------------
    local NotifHolder = New("Frame", {
        Parent                 = ScreenGui,
        BackgroundTransparency = 1,
        Position               = UDim2.new(1, -16, 1, -16),
        AnchorPoint            = Vector2.new(1, 1),
        Size                   = UDim2.new(0, 320, 1, 0),
        ZIndex                 = 150,
    })
    New("UIListLayout", {
        Parent             = NotifHolder,
        SortOrder          = Enum.SortOrder.LayoutOrder,
        VerticalAlignment  = Enum.VerticalAlignment.Bottom,
        Padding            = UDim.new(0, 8),
    })

    function Lib:Notify(cfg)
        cfg = cfg or {}
        local title  = cfg.Title    or "Notificação"
        local text   = cfg.Text     or ""
        local dur    = cfg.Duration or 4
        local ntype  = cfg.Type     or "Info"
        local cols   = { Success = Theme.Success, Error = Theme.Error, Warning = Theme.Warning, Info = Theme.Accent }
        local col    = cols[ntype] or Theme.Accent

        local Card = New("Frame", {
            Parent                 = NotifHolder,
            BackgroundColor3       = Color3.fromRGB(20, 20, 30),
            Size                   = UDim2.new(1, 0, 0, 0),
            ClipsDescendants       = true,
            BackgroundTransparency = 0.05,
        })
        Corner(Card, 10)
        New("UIStroke", {Parent = Card, Color = col, Thickness = 1, Transparency = 0.5})
        New("Frame", {Parent = Card, BackgroundColor3 = col, Size = UDim2.new(0, 3, 1, 0), BorderSizePixel = 0})
        New("TextLabel", {
            Parent = Card, BackgroundTransparency = 1, Text = title,
            Font = Theme.FontBold, TextSize = 13, TextColor3 = col,
            Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 14, 0, 10),
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        New("TextLabel", {
            Parent = Card, BackgroundTransparency = 1, Text = text,
            Font = Theme.Font, TextSize = 12, TextColor3 = Theme.TextMuted,
            Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0, 14, 0, 30),
            TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
        })
        local PBar = New("Frame", {
            Parent = Card, BackgroundColor3 = col,
            Size = UDim2.new(1, -3, 0, 2), Position = UDim2.new(0, 3, 1, -2), BorderSizePixel = 0,
        })
        Tween(Card, TI_Medium, {Size = UDim2.new(1, 0, 0, 72)})
        Tween(PBar, TweenInfo.new(dur, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 3, 0, 2)})
        task.delay(dur, function()
            Tween(Card, TI_Medium, {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0)})
            task.wait(0.3); Card:Destroy()
        end)
    end

    -----------------------------------------------------------------------
    -- SAVE / LOAD CONFIG
    -----------------------------------------------------------------------
    function Lib:SaveConfig(name)
        if not writefile then return end
        if not isfolder("NexusUI") then makefolder("NexusUI") end
        if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
        local ok, data = pcall(HttpService.JSONEncode, HttpService, Lib.Flags)
        if ok then writefile(ConfigFolder.."/"..name..".json", data) end
    end

    function Lib:LoadConfig(name)
        if not readfile then return end
        local path = ConfigFolder.."/"..name..".json"
        if not isfile(path) then return end
        local ok, data = pcall(HttpService.JSONDecode, HttpService, readfile(path))
        if not ok then return end
        for flag, val in pairs(data) do
            if Lib.Options[flag] then pcall(Lib.Options[flag].Set, Lib.Options[flag], val) end
        end
    end

    function Lib:ResetConfig()
        Lib.Flags = {}
        for _, opt in pairs(Lib.Options) do if opt.Reset then pcall(opt.Reset, opt) end end
    end

    -----------------------------------------------------------------------
    -- DRAG
    -----------------------------------------------------------------------
    local function MakeDraggable(frame, handle)
        local dragging, dragStart, startPos, dragInput
        handle.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dragStart = i.Position; startPos = frame.Position
                i.Changed:Connect(function()
                    if i.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        handle.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch then dragInput = i end
        end)
        UIS.InputChanged:Connect(function(i)
            if i == dragInput and dragging then
                local d = i.Position - dragStart
                Tween(frame, TweenInfo.new(0.08), {
                    Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
                })
            end
        end)
    end

    -----------------------------------------------------------------------
    -- CRIAR JANELA
    -----------------------------------------------------------------------
    function Lib:CreateWindow(cfg)
        cfg = cfg or {}
        local title   = cfg.Title   or "Nexus Hub"
        local keybind = cfg.Keybind or Enum.KeyCode.RightControl
        local W, H    = 560, 380

        -- Janela principal
        local Win = New("Frame", {
            Parent           = ScreenGui,
            BackgroundColor3 = Theme.Background,
            Size             = UDim2.fromOffset(W, H),
            Position         = UDim2.fromScale(0.5, 0.5),
            AnchorPoint      = Vector2.new(0.5, 0.5),
            BorderSizePixel  = 0,
        })
        Corner(Win, 12)
        Stroke(Win, Theme.Border)
        Reg(Win, "BackgroundColor3", "Background")

        -- Topbar
        local Topbar = New("Frame", {
            Parent           = Win,
            BackgroundColor3 = Theme.Header,
            Size             = UDim2.new(1, 0, 0, 40),
            BorderSizePixel  = 0,
        })
        New("UICorner", {CornerRadius = UDim.new(0, 12), Parent = Topbar})
        New("Frame", {
            Parent           = Topbar,
            BackgroundColor3 = Theme.Header,
            Size             = UDim2.new(1, 0, 0, 12),
            Position         = UDim2.new(0, 0, 1, -12),
            BorderSizePixel  = 0,
        })
        Reg(Topbar, "BackgroundColor3", "Header")
        MakeDraggable(Win, Topbar)

        -- Título
        New("TextLabel", {
            Parent                 = Topbar,
            BackgroundTransparency = 1,
            Text                   = "  ◈  " .. title,
            Font                   = Theme.FontBold,
            TextSize               = 14,
            TextColor3             = Theme.Text,
            Size                   = UDim2.new(0.6, 0, 1, 0),
            Position               = UDim2.new(0, 6, 0, 0),
            TextXAlignment         = Enum.TextXAlignment.Left,
        })

        -- Botão minimizar
        local BtnMin = New("ImageButton", {
            Parent                 = Topbar,
            BackgroundTransparency = 1,
            Image                  = "rbxassetid://7072719338",
            ImageColor3            = Theme.TextMuted,
            Size                   = UDim2.fromOffset(20, 20),
            Position               = UDim2.new(1, -58, 0.5, -10),
            AutoButtonColor        = false,
        })
        -- Botão fechar
        local BtnClose = New("ImageButton", {
            Parent                 = Topbar,
            BackgroundTransparency = 1,
            Image                  = "rbxassetid://7072725342",
            ImageColor3            = Theme.TextMuted,
            Size                   = UDim2.fromOffset(20, 20),
            Position               = UDim2.new(1, -30, 0.5, -10),
            AutoButtonColor        = false,
        })
        BtnClose.MouseEnter:Connect(function() Tween(BtnClose, TI_Fast, {ImageColor3 = Theme.Error}) end)
        BtnClose.MouseLeave:Connect(function() Tween(BtnClose, TI_Fast, {ImageColor3 = Theme.TextMuted}) end)
        BtnClose.MouseButton1Click:Connect(function()
            Tween(Win, TI_Medium, {Size = UDim2.fromOffset(W, 0)})
            task.wait(0.25); Win.Visible = false
        end)

        local minimized = false
        BtnMin.MouseEnter:Connect(function() Tween(BtnMin, TI_Fast, {ImageColor3 = Theme.Warning}) end)
        BtnMin.MouseLeave:Connect(function() Tween(BtnMin, TI_Fast, {ImageColor3 = Theme.TextMuted}) end)
        BtnMin.MouseButton1Click:Connect(function()
            minimized = not minimized
            Tween(Win, TI_Medium, {Size = minimized and UDim2.fromOffset(W, 40) or UDim2.fromOffset(W, H)})
        end)

        -- Corpo
        local Body = New("Frame", {
            Parent                 = Win,
            BackgroundTransparency = 1,
            Position               = UDim2.new(0, 0, 0, 40),
            Size                   = UDim2.new(1, 0, 1, -40),
        })

        -- Sidebar
        local Sidebar = New("Frame", {
            Parent           = Body,
            BackgroundColor3 = Theme.Sidebar,
            Size             = UDim2.new(0, 132, 1, 0),
            BorderSizePixel  = 0,
            ClipsDescendants = true,
        })
        New("UICorner", {CornerRadius = UDim.new(0, 12), Parent = Sidebar})
        New("Frame", {
            Parent           = Sidebar,
            BackgroundColor3 = Theme.Sidebar,
            Size             = UDim2.new(0, 14, 1, 0),
            Position         = UDim2.new(1, -14, 0, 0),
            BorderSizePixel  = 0,
        })
        Reg(Sidebar, "BackgroundColor3", "Sidebar")

        -- Separador
        New("Frame", {
            Parent           = Body,
            BackgroundColor3 = Theme.Border,
            Size             = UDim2.new(0, 1, 1, 0),
            Position         = UDim2.new(0, 132, 0, 0),
            BorderSizePixel  = 0,
        })

        -- Lista de tabs na sidebar
        local TabList = New("Frame", {
            Parent                 = Sidebar,
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, 0, 1, -8),
            Position               = UDim2.new(0, 0, 0, 8),
        })
        New("UIListLayout", {
            Parent    = TabList,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 3),
        })
        Pad(TabList, 0, 0, 8, 8)

        -- Área de conteúdo
        local ContentArea = New("Frame", {
            Parent                 = Body,
            BackgroundTransparency = 1,
            Position               = UDim2.new(0, 140, 0, 6),
            Size                   = UDim2.new(1, -148, 1, -12),
            ClipsDescendants       = true,
        })

        -- Toggle com keybind
        local isOpen = true
        UIS.InputBegan:Connect(function(i, gp)
            if gp then return end
            if i.KeyCode == keybind then
                isOpen  = not isOpen
                Win.Visible = true
                Tween(Win, TI_Medium, {
                    Size = isOpen and UDim2.fromOffset(W, H) or UDim2.fromOffset(W, 40)
                })
            end
        end)

        -- Botão flutuante para mobile
        if UIS.TouchEnabled then
            local MobileBtn = New("ImageButton", {
                Parent           = ScreenGui,
                BackgroundColor3 = Theme.Accent,
                Size             = UDim2.fromOffset(48, 48),
                Position         = UDim2.new(0, 16, 0.5, 0),
                AutoButtonColor  = false,
                Image            = "rbxassetid://6034509993",
                ImageColor3      = Color3.new(1, 1, 1),
            })
            Corner(MobileBtn, 10)
            MobileBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                Win.Visible = isOpen
            end)
        end

        -----------------------------------------------------------------------
        -- SISTEMA DE TABS
        -----------------------------------------------------------------------
        local ActivePage    = nil
        local ActiveTabBtn  = nil

        local Window = {}

        function Window:CreateTab(tabName, icon)
            -- Página scrollável
            local Page = New("ScrollingFrame", {
                Parent                 = ContentArea,
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 1, 0),
                ScrollBarThickness     = 3,
                ScrollBarImageColor3   = Theme.Accent,
                CanvasSize             = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize    = Enum.AutomaticSize.Y,
                BorderSizePixel        = 0,
                Visible                = false,
            })
            New("UIListLayout", {Parent = Page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
            Pad(Page, 4, 8, 2, 8)

            -- Botão na sidebar
            local TBtn = New("TextButton", {
                Parent           = TabList,
                BackgroundColor3 = Theme.Sidebar,
                Size             = UDim2.new(1, 0, 0, 34),
                Text             = "",
                AutoButtonColor  = false,
                BorderSizePixel  = 0,
            })
            Corner(TBtn, 8)

            -- Indicador ativo
            local Indicator = New("Frame", {
                Parent           = TBtn,
                BackgroundColor3 = Theme.Accent,
                Size             = UDim2.new(0, 3, 0.6, 0),
                Position         = UDim2.new(0, 0, 0.2, 0),
                BorderSizePixel  = 0,
                Visible          = false,
            })
            Corner(Indicator, 2)

            local xOff = 10
            if icon and icon ~= "" then
                New("ImageLabel", {
                    Parent                 = TBtn,
                    BackgroundTransparency = 1,
                    Image                  = icon,
                    ImageColor3            = Theme.TextMuted,
                    Size                   = UDim2.fromOffset(16, 16),
                    Position               = UDim2.new(0, xOff, 0.5, -8),
                })
                xOff = xOff + 22
            end

            local TBtnLabel = New("TextLabel", {
                Parent                 = TBtn,
                BackgroundTransparency = 1,
                Text                   = tabName,
                Font                   = Theme.Font,
                TextSize               = 13,
                TextColor3             = Theme.TextMuted,
                Size                   = UDim2.new(1, -(xOff + 8), 1, 0),
                Position               = UDim2.new(0, xOff, 0, 0),
                TextXAlignment         = Enum.TextXAlignment.Left,
            })

            local function SelectTab()
                if ActivePage   then ActivePage.Visible = false end
                if ActiveTabBtn then
                    for _, c in pairs(ActiveTabBtn:GetChildren()) do
                        if c:IsA("Frame") then c.Visible = false end
                    end
                    local pl = ActiveTabBtn:FindFirstChildOfClass("TextLabel")
                    if pl then Tween(pl, TI_Fast, {TextColor3 = Theme.TextMuted}) end
                    Tween(ActiveTabBtn, TI_Fast, {BackgroundColor3 = Theme.Sidebar})
                end
                Page.Visible    = true
                ActivePage      = Page
                ActiveTabBtn    = TBtn
                Indicator.Visible = true
                Tween(TBtnLabel, TI_Fast, {TextColor3 = Theme.Text})
                Tween(TBtn, TI_Fast, {BackgroundColor3 = Theme.Surface})
            end

            TBtn.MouseButton1Click:Connect(SelectTab)
            TBtn.MouseEnter:Connect(function()
                if TBtn ~= ActiveTabBtn then Tween(TBtn, TI_Fast, {BackgroundColor3 = Theme.SurfaceHover}) end
            end)
            TBtn.MouseLeave:Connect(function()
                if TBtn ~= ActiveTabBtn then Tween(TBtn, TI_Fast, {BackgroundColor3 = Theme.Sidebar}) end
            end)

            if not ActivePage then SelectTab() end

            -- API da Tab
            local Tab = {}

            function Tab:CreateSection(secName)
                local SecFrame = New("Frame", {
                    Parent            = Page,
                    BackgroundColor3  = Theme.Surface,
                    Size              = UDim2.new(1, -4, 0, 0),
                    AutomaticSize     = Enum.AutomaticSize.Y,
                    BorderSizePixel   = 0,
                })
                Corner(SecFrame, 10)
                Stroke(SecFrame, Theme.Border)
                Reg(SecFrame, "BackgroundColor3", "Surface")

                -- Header
                local SecHead = New("Frame", {
                    Parent                 = SecFrame,
                    BackgroundTransparency = 1,
                    Size                   = UDim2.new(1, 0, 0, 30),
                })
                New("TextLabel", {
                    Parent                 = SecHead,
                    BackgroundTransparency = 1,
                    Text                   = secName,
                    Font                   = Theme.FontBold,
                    TextSize               = 11,
                    TextColor3             = Theme.Accent,
                    Size                   = UDim2.new(1, -20, 1, 0),
                    Position               = UDim2.new(0, 12, 0, 0),
                    TextXAlignment         = Enum.TextXAlignment.Left,
                })
                New("Frame", {
                    Parent           = SecHead,
                    BackgroundColor3 = Theme.Border,
                    Size             = UDim2.new(1, -12, 0, 1),
                    Position         = UDim2.new(0, 6, 1, -1),
                    BorderSizePixel  = 0,
                })

                -- Container dos elementos da section
                local Container = New("Frame", {
                    Parent            = SecFrame,
                    BackgroundTransparency = 1,
                    Position          = UDim2.new(0, 0, 0, 30),
                    Size              = UDim2.new(1, 0, 0, 0),
                    AutomaticSize     = Enum.AutomaticSize.Y,
                })
                New("UIListLayout", {Parent = Container, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)})
                Pad(Container, 0, 10, 8, 8)

                return BuildElems(Container)
            end

            -- Elementos diretos na tab
            local DirectContainer = New("Frame", {
                Parent            = Page,
                BackgroundTransparency = 1,
                Size              = UDim2.new(1, 0, 0, 0),
                AutomaticSize     = Enum.AutomaticSize.Y,
            })
            New("UIListLayout", {Parent = DirectContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)})
            Pad(DirectContainer, 2, 2, 2, 2)

            local DirectElems = BuildElems(DirectContainer)
            for k, v in pairs(DirectElems) do Tab[k] = v end

            return Tab
        end

        return Window
    end

    -----------------------------------------------------------------------
    -- BUILD ELEMS (definição real da função forward-declarada)
    -----------------------------------------------------------------------
    BuildElems = function(Container)
        local E = {}

        -- Frame base de elemento
        local function ElemBG(h, clip)
            local f = New("Frame", {
                Parent                 = Container,
                BackgroundColor3       = Theme.Surface,
                Size                   = UDim2.new(1, 0, 0, h or 36),
                BorderSizePixel        = 0,
                ClipsDescendants       = clip or false,
            })
            Corner(f, 8)
            Stroke(f, Theme.Border)
            Reg(f, "BackgroundColor3", "Surface")
            return f
        end

        -- Hover helpers
        local function HoverOn(f)  Tween(f, TI_Fast, {BackgroundColor3 = Theme.SurfaceHover}) end
        local function HoverOff(f) Tween(f, TI_Fast, {BackgroundColor3 = Theme.Surface}) end

        -- HitBox invisível sobre o frame
        local function HitBtn(parent, h)
            return New("TextButton", {
                Parent                 = parent,
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 0, h or 36),
                Text                   = "",
                ZIndex                 = 5,
            })
        end

        ---------------------------------------------------------------
        -- BUTTON
        ---------------------------------------------------------------
        function E:CreateButton(txt, callback, tooltip)
            local F = ElemBG(36)
            New("TextLabel", {
                Parent                 = F,
                BackgroundTransparency = 1,
                Text                   = txt,
                Font                   = Theme.Font,
                TextSize               = 13,
                TextColor3             = Theme.Text,
                Size                   = UDim2.new(1, -46, 1, 0),
                Position               = UDim2.new(0, 12, 0, 0),
                TextXAlignment         = Enum.TextXAlignment.Left,
            })
            New("ImageLabel", {
                Parent                 = F,
                BackgroundTransparency = 1,
                Image                  = "rbxassetid://6026568198",
                ImageColor3            = Theme.Accent,
                Size                   = UDim2.fromOffset(16, 16),
                Position               = UDim2.new(1, -26, 0.5, -8),
            })
            local Btn = HitBtn(F)
            Btn.MouseEnter:Connect(function() HoverOn(F) end)
            Btn.MouseLeave:Connect(function() HoverOff(F) end)
            Btn.MouseButton1Click:Connect(function()
                Tween(F, TweenInfo.new(0.08), {BackgroundColor3 = Theme.Accent})
                task.delay(0.12, function() HoverOn(F) end)
                pcall(callback)
            end)
            if tooltip then AddTooltip(F, tooltip) end
            local Obj = {}
            function Obj:SetTooltip(t) AddTooltip(F, t) end
            return Obj
        end

        ---------------------------------------------------------------
        -- TOGGLE
        ---------------------------------------------------------------
        function E:CreateToggle(txt, callback, default, tooltip)
            local flag  = txt
            local state = default or false
            local hooks = {}
            Lib.Flags[flag] = state

            local F = ElemBG(36)
            New("TextLabel", {
                Parent                 = F,
                BackgroundTransparency = 1,
                Text                   = txt,
                Font                   = Theme.Font,
                TextSize               = 13,
                TextColor3             = Theme.Text,
                Size                   = UDim2.new(1, -56, 1, 0),
                Position               = UDim2.new(0, 12, 0, 0),
                TextXAlignment         = Enum.TextXAlignment.Left,
            })
            local Track = New("Frame", {
                Parent           = F,
                BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(50, 50, 65),
                Size             = UDim2.fromOffset(38, 20),
                Position         = UDim2.new(1, -50, 0.5, -10),
            })
            Corner(Track, 10)
            local Knob = New("Frame", {
                Parent           = Track,
                BackgroundColor3 = Color3.new(1,1,1),
                Size             = UDim2.fromOffset(16, 16),
                Position         = state and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8),
            })
            Corner(Knob, 8)

            local function SetState(val, skipCB)
                state = val; Lib.Flags[flag] = state
                Tween(Track, TI_Fast, {BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(50,50,65)})
                Tween(Knob,  TI_Fast, {Position = state and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)})
                if not skipCB then
                    if state and hooks.OnEnable then pcall(hooks.OnEnable) end
                    if not state and hooks.OnDisable then pcall(hooks.OnDisable) end
                    pcall(callback, state)
                end
            end

            local Btn = HitBtn(F)
            Btn.MouseEnter:Connect(function() HoverOn(F) end)
            Btn.MouseLeave:Connect(function() HoverOff(F) end)
            Btn.MouseButton1Click:Connect(function() SetState(not state) end)
            if tooltip then AddTooltip(F, tooltip) end

            local Obj = {}
            function Obj:Set(v)      SetState(v, true) end
            function Obj:Reset()     SetState(false, true) end
            function Obj:OnEnable(f)  hooks.OnEnable = f end
            function Obj:OnDisable(f) hooks.OnDisable = f end
            function Obj:SetTooltip(t) AddTooltip(F, t) end
            Lib.Options[flag] = Obj
            return Obj
        end

        ---------------------------------------------------------------
        -- SLIDER
        ---------------------------------------------------------------
        function E:CreateSlider(txt, min, max, default, callback, tooltip)
            local flag  = txt
            local value = math.clamp(default or min, min, max)
            Lib.Flags[flag] = value

            local F = ElemBG(50)
            New("TextLabel", {
                Parent                 = F,
                BackgroundTransparency = 1,
                Text                   = txt,
                Font                   = Theme.Font,
                TextSize               = 13,
                TextColor3             = Theme.Text,
                Size                   = UDim2.new(0.65, 0, 0, 24),
                Position               = UDim2.new(0, 12, 0, 4),
                TextXAlignment         = Enum.TextXAlignment.Left,
            })
            local ValLbl = New("TextLabel", {
                Parent                 = F,
                BackgroundTransparency = 1,
                Text                   = tostring(value),
                Font                   = Theme.FontBold,
                TextSize               = 12,
                TextColor3             = Theme.Accent,
                Size                   = UDim2.new(0.35, -14, 0, 24),
                Position               = UDim2.new(0.65, 0, 0, 4),
                TextXAlignment         = Enum.TextXAlignment.Right,
            })
            local BarBG = New("Frame", {
                Parent           = F,
                BackgroundColor3 = Color3.fromRGB(38, 38, 52),
                Size             = UDim2.new(1, -24, 0, 4),
                Position         = UDim2.new(0, 12, 0, 35),
            })
            Corner(BarBG, 4)
            local Fill = New("Frame", {
                Parent           = BarBG,
                BackgroundColor3 = Theme.Accent,
                Size             = UDim2.new((value-min)/(max-min), 0, 1, 0),
            })
            Corner(Fill, 4)
            New("Frame", {
                Parent           = Fill,
                BackgroundColor3 = Color3.new(1,1,1),
                Size             = UDim2.fromOffset(10, 10),
                Position         = UDim2.new(1,-5,0.5,-5),
            })
            Corner(Fill:FindFirstChildOfClass("Frame"), 5)

            local HB = New("TextButton", {
                Parent                 = BarBG,
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 0, 22),
                Position               = UDim2.new(0, 0, 0.5, -11),
                Text                   = "",
                ZIndex                 = 5,
            })

            local function Update(v, skipCB)
                value = math.floor(math.clamp(v, min, max) * 10) / 10
                Lib.Flags[flag] = value
                ValLbl.Text = tostring(value)
                Tween(Fill, TweenInfo.new(0.05), {Size = UDim2.new((value-min)/(max-min), 0, 1, 0)})
                if not skipCB then pcall(callback, value) end
            end

            local dragging = false
            HB.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then dragging = true end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
            end)
            UIS.InputChanged:Connect(function(i)
                if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
                or i.UserInputType == Enum.UserInputType.Touch) then
                    local rel = math.clamp((i.Position.X - BarBG.AbsolutePosition.X)/BarBG.AbsoluteSize.X, 0, 1)
                    Update(min + (max-min)*rel)
                end
            end)

            F.MouseEnter:Connect(function() HoverOn(F) end)
            F.MouseLeave:Connect(function() HoverOff(F) end)
            if tooltip then AddTooltip(F, tooltip) end

            local Obj = {}
            function Obj:Set(v) Update(v, true) end
            function Obj:Reset() Update(default or min, true) end
            function Obj:SetTooltip(t) AddTooltip(F, t) end
            Lib.Options[flag] = Obj
            return Obj
        end

        ---------------------------------------------------------------
        -- DROPDOWN
        ---------------------------------------------------------------
        function E:CreateDropdown(txt, options, callback, defaultOpt, tooltip)
            local flag     = txt
            local selected = defaultOpt or (options and options[1]) or ""
            local expanded = false
            local H_c, H_o = 36, 28
            Lib.Flags[flag] = selected

            local F = New("Frame", {
                Parent                 = Container,
                BackgroundColor3       = Theme.Surface,
                Size                   = UDim2.new(1, 0, 0, H_c),
                ClipsDescendants       = true,
                BorderSizePixel        = 0,
            })
            Corner(F, 8); Stroke(F, Theme.Border)
            Reg(F, "BackgroundColor3", "Surface")

            local TitleLbl = New("TextLabel", {
                Parent                 = F,
                BackgroundTransparency = 1,
                Text                   = txt..": "..selected,
                Font                   = Theme.Font,
                TextSize               = 13,
                TextColor3             = Theme.Text,
                Size                   = UDim2.new(1,-44,0,H_c),
                Position               = UDim2.new(0,12,0,0),
                TextXAlignment         = Enum.TextXAlignment.Left,
            })
            local Arrow = New("ImageLabel", {
                Parent                 = F,
                BackgroundTransparency = 1,
                Image                  = "rbxassetid://6031091004",
                ImageColor3            = Theme.TextMuted,
                Size                   = UDim2.fromOffset(18,18),
                Position               = UDim2.new(1,-28,0,9),
            })
            local OptList = New("Frame", {
                Parent                 = F,
                BackgroundTransparency = 1,
                Position               = UDim2.new(0,0,0,H_c+2),
                Size                   = UDim2.new(1,0,0,0),
                AutomaticSize          = Enum.AutomaticSize.Y,
            })
            New("UIListLayout", {Parent=OptList, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,2)})
            Pad(OptList, 0, 0, 6, 6)

            local function SetSel(opt, skipCB)
                selected = opt; Lib.Flags[flag] = selected
                TitleLbl.Text = txt..": "..selected
                expanded = false
                Tween(F, TI_Fast, {Size=UDim2.new(1,0,0,H_c)})
                Tween(Arrow, TI_Fast, {Rotation=0})
                if not skipCB then pcall(callback, selected) end
            end

            local function BuildOpts(list)
                for _, c in pairs(OptList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
                for _, opt in pairs(list) do
                    local OBtn = New("TextButton", {
                        Parent=OptList, BackgroundColor3=Theme.SurfaceHover,
                        Size=UDim2.new(1,0,0,H_o), Text=opt,
                        Font=Theme.Font, TextSize=12, TextColor3=Theme.TextMuted,
                        AutoButtonColor=false,
                    })
                    Corner(OBtn, 6)
                    OBtn.MouseEnter:Connect(function() Tween(OBtn,TI_Fast,{BackgroundColor3=Theme.Border,TextColor3=Theme.Text}) end)
                    OBtn.MouseLeave:Connect(function() Tween(OBtn,TI_Fast,{BackgroundColor3=Theme.SurfaceHover,TextColor3=Theme.TextMuted}) end)
                    OBtn.MouseButton1Click:Connect(function() SetSel(opt) end)
                end
            end
            BuildOpts(options or {})

            local HeadBtn = HitBtn(F, H_c)
            HeadBtn.MouseButton1Click:Connect(function()
                expanded = not expanded
                local total = H_c + (#options * (H_o+2)) + 10
                Tween(F, TI_Fast, {Size=UDim2.new(1,0,0,expanded and total or H_c)})
                Tween(Arrow, TI_Fast, {Rotation=expanded and 180 or 0})
            end)

            if tooltip then AddTooltip(F, tooltip) end

            local Obj = {}
            function Obj:Set(v) SetSel(v, true) end
            function Obj:Reset() SetSel(options[1] or "", true) end
            function Obj:Refresh(list, clear)
                if clear then options = list else for _,v in pairs(list) do table.insert(options,v) end end
                BuildOpts(options)
            end
            function Obj:SetTooltip(t) AddTooltip(F, t) end
            Lib.Options[flag] = Obj
            return Obj
        end

        ---------------------------------------------------------------
        -- MULTI-SELECT DROPDOWN
        ---------------------------------------------------------------
        function E:CreateMultiDropdown(txt, options, callback, tooltip)
            local flag     = txt
            local selected = {}
            local expanded = false
            local H_c, H_o = 36, 28
            Lib.Flags[flag] = selected

            local F = New("Frame", {
                Parent                 = Container,
                BackgroundColor3       = Theme.Surface,
                Size                   = UDim2.new(1, 0, 0, H_c),
                ClipsDescendants       = true,
                BorderSizePixel        = 0,
            })
            Corner(F, 8); Stroke(F, Theme.Border)
            Reg(F, "BackgroundColor3", "Surface")

            local TitleLbl = New("TextLabel", {
                Parent                 = F,
                BackgroundTransparency = 1,
                Text                   = txt..": Nenhum",
                Font                   = Theme.Font, TextSize = 13,
                TextColor3             = Theme.Text,
                Size                   = UDim2.new(1,-44,0,H_c),
                Position               = UDim2.new(0,12,0,0),
                TextXAlignment         = Enum.TextXAlignment.Left,
            })
            local Arrow = New("ImageLabel", {
                Parent                 = F,
                BackgroundTransparency = 1,
                Image                  = "rbxassetid://6031091004",
                ImageColor3            = Theme.TextMuted,
                Size                   = UDim2.fromOffset(18,18),
                Position               = UDim2.new(1,-28,0,9),
            })
            local OptList = New("Frame", {
                Parent                 = F,
                BackgroundTransparency = 1,
                Position               = UDim2.new(0,0,0,H_c+2),
                Size                   = UDim2.new(1,0,0,0),
                AutomaticSize          = Enum.AutomaticSize.Y,
            })
            New("UIListLayout",{Parent=OptList,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2)})
            Pad(OptList,0,0,6,6)

            local function IsSel(o) for _,v in pairs(selected) do if v==o then return true end end return false end
            local function UpdateTitle()
                TitleLbl.Text = txt..": "..( #selected==0 and "Nenhum" or table.concat(selected,", ") )
                Lib.Flags[flag] = selected
                pcall(callback, selected)
            end

            for _, opt in pairs(options or {}) do
                local OBtn = New("TextButton",{
                    Parent=OptList, BackgroundColor3=Theme.SurfaceHover,
                    Size=UDim2.new(1,0,0,H_o), Text="", AutoButtonColor=false,
                })
                Corner(OBtn,6)
                local Check = New("Frame",{Parent=OBtn, BackgroundColor3=Color3.fromRGB(50,50,65), Size=UDim2.fromOffset(14,14), Position=UDim2.new(0,8,0.5,-7)})
                Corner(Check,4); Stroke(Check,Theme.Border)
                local Mark = New("TextLabel",{Parent=Check, BackgroundTransparency=1, Text="✓", Font=Theme.FontBold, TextSize=10, TextColor3=Theme.Accent, Size=UDim2.new(1,0,1,0), Visible=false})
                New("TextLabel",{Parent=OBtn, BackgroundTransparency=1, Text=opt, Font=Theme.Font, TextSize=12, TextColor3=Theme.TextMuted, Size=UDim2.new(1,-34,1,0), Position=UDim2.new(0,30,0,0), TextXAlignment=Enum.TextXAlignment.Left})
                OBtn.MouseEnter:Connect(function() Tween(OBtn,TI_Fast,{BackgroundColor3=Theme.Border}) end)
                OBtn.MouseLeave:Connect(function() Tween(OBtn,TI_Fast,{BackgroundColor3=Theme.SurfaceHover}) end)
                OBtn.MouseButton1Click:Connect(function()
                    if IsSel(opt) then
                        for i,v in pairs(selected) do if v==opt then table.remove(selected,i) break end end
                        Tween(Check,TI_Fast,{BackgroundColor3=Color3.fromRGB(50,50,65)}); Mark.Visible=false
                    else
                        table.insert(selected, opt)
                        Tween(Check,TI_Fast,{BackgroundColor3=Theme.Accent}); Mark.Visible=true
                    end
                    UpdateTitle()
                end)
            end

            local HeadBtn = HitBtn(F, H_c)
            HeadBtn.MouseButton1Click:Connect(function()
                expanded = not expanded
                local total = H_c + (#options*(H_o+2)) + 10
                Tween(F,TI_Fast,{Size=UDim2.new(1,0,0,expanded and total or H_c)})
                Tween(Arrow,TI_Fast,{Rotation=expanded and 180 or 0})
            end)

            if tooltip then AddTooltip(F, tooltip) end
            local Obj = {}
            function Obj:Get() return selected end
            function Obj:SetTooltip(t) AddTooltip(F, t) end
            Lib.Options[flag] = Obj
            return Obj
        end

        ---------------------------------------------------------------
        -- COLOR PICKER
        ---------------------------------------------------------------
        function E:CreateColorPicker(txt, default, callback, tooltip)
            local flag = txt
            local col  = default or Color3.fromRGB(255,255,255)
            local R, G, B = math.floor(col.R*255), math.floor(col.G*255), math.floor(col.B*255)
            local expanded = false
            local H_c, H_o = 36, 144
            Lib.Flags[flag] = {R=col.R,G=col.G,B=col.B}

            local F = New("Frame",{
                Parent=Container, BackgroundColor3=Theme.Surface,
                Size=UDim2.new(1,0,0,H_c), ClipsDescendants=true, BorderSizePixel=0,
            })
            Corner(F,8); Stroke(F,Theme.Border)
            Reg(F,"BackgroundColor3","Surface")

            New("TextLabel",{
                Parent=F, BackgroundTransparency=1, Text=txt,
                Font=Theme.Font, TextSize=13, TextColor3=Theme.Text,
                Size=UDim2.new(1,-70,0,H_c), Position=UDim2.new(0,12,0,0),
                TextXAlignment=Enum.TextXAlignment.Left,
            })
            local Preview = New("Frame",{
                Parent=F, BackgroundColor3=col,
                Size=UDim2.fromOffset(30,18), Position=UDim2.new(1,-44,0.5,-9),
            })
            Corner(Preview,5); Stroke(Preview,Theme.Border)

            local SliderArea = New("Frame",{
                Parent=F, BackgroundTransparency=1,
                Size=UDim2.new(1,0,0,H_o-H_c), Position=UDim2.new(0,0,0,H_c),
            })

            local function UpdateColor(skipCB)
                local c = Color3.fromRGB(R,G,B)
                Preview.BackgroundColor3 = c
                Lib.Flags[flag] = {R=c.R,G=c.G,B=c.B}
                if not skipCB then pcall(callback, c) end
            end

            local function MakeRGBSlider(axis, color, ypos, initV)
                New("TextLabel",{
                    Parent=SliderArea, BackgroundTransparency=1,
                    Text=axis, Font=Theme.FontBold, TextSize=12, TextColor3=color,
                    Size=UDim2.fromOffset(24,20), Position=UDim2.new(0,10,0,ypos),
                })
                local Bg = New("Frame",{
                    Parent=SliderArea, BackgroundColor3=Color3.fromRGB(38,38,52),
                    Size=UDim2.new(1,-72,0,4), Position=UDim2.new(0,38,0,ypos+8),
                })
                Corner(Bg,4)
                local FillC = New("Frame",{Parent=Bg, BackgroundColor3=color, Size=UDim2.new(initV/255,0,1,0)})
                Corner(FillC,4)
                local VLbl = New("TextLabel",{
                    Parent=SliderArea, BackgroundTransparency=1,
                    Text=tostring(initV), Font=Theme.Font, TextSize=11, TextColor3=Theme.TextMuted,
                    Size=UDim2.fromOffset(28,20), Position=UDim2.new(1,-36,0,ypos),
                    TextXAlignment=Enum.TextXAlignment.Right,
                })
                local HB = New("TextButton",{
                    Parent=Bg, BackgroundTransparency=1,
                    Size=UDim2.new(1,0,0,20), Position=UDim2.new(0,0,0.5,-10), Text="", ZIndex=4,
                })
                local dr = false
                HB.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=true end end)
                UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=false end end)
                UIS.InputChanged:Connect(function(i)
                    if dr and i.UserInputType==Enum.UserInputType.MouseMovement then
                        local rel = math.clamp((i.Position.X-Bg.AbsolutePosition.X)/Bg.AbsoluteSize.X,0,1)
                        local v   = math.floor(rel*255)
                        FillC.Size = UDim2.new(rel,0,1,0)
                        VLbl.Text  = tostring(v)
                        if axis=="R" then R=v elseif axis=="G" then G=v else B=v end
                        UpdateColor()
                    end
                end)
            end

            MakeRGBSlider("R", Color3.fromRGB(255,90,90), 8, R)
            MakeRGBSlider("G", Color3.fromRGB(80,220,80), 42, G)
            MakeRGBSlider("B", Color3.fromRGB(90,130,255), 76, B)

            local HeadBtn = HitBtn(F, H_c)
            HeadBtn.MouseButton1Click:Connect(function()
                expanded = not expanded
                Tween(F,TI_Fast,{Size=UDim2.new(1,0,0,expanded and H_o or H_c)})
            end)

            if tooltip then AddTooltip(F, tooltip) end

            local Obj = {}
            function Obj:Set(t)
                if not t then return end
                R=math.floor((t.R or 0)*255); G=math.floor((t.G or 0)*255); B=math.floor((t.B or 0)*255)
                UpdateColor(true)
            end
            function Obj:SetTooltip(t) AddTooltip(F, t) end
            Lib.Options[flag] = Obj
            return Obj
        end

        ---------------------------------------------------------------
        -- TEXTBOX
        ---------------------------------------------------------------
        function E:CreateTextBox(txt, placeholder, callback, tooltip)
            local F = ElemBG(56)
            New("TextLabel",{
                Parent=F, BackgroundTransparency=1, Text=txt,
                Font=Theme.Font, TextSize=13, TextColor3=Theme.Text,
                Size=UDim2.new(1,-12,0,22), Position=UDim2.new(0,12,0,4),
                TextXAlignment=Enum.TextXAlignment.Left,
            })
            local IBG = New("Frame",{
                Parent=F, BackgroundColor3=Theme.Background,
                Size=UDim2.new(1,-20,0,22), Position=UDim2.new(0,10,0,28),
            })
            Corner(IBG,6); Stroke(IBG,Theme.Border)
            local Input = New("TextBox",{
                Parent=IBG, BackgroundTransparency=1,
                Size=UDim2.new(1,-16,1,0), Position=UDim2.new(0,8,0,0),
                Text="", PlaceholderText=placeholder or "...",
                Font=Theme.Font, TextSize=12,
                TextColor3=Theme.Text, PlaceholderColor3=Theme.TextMuted,
                TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false,
            })
            Input.Focused:Connect(function()  Tween(IBG,TI_Fast,{BackgroundColor3=Theme.SurfaceHover}) end)
            Input.FocusLost:Connect(function()
                Tween(IBG,TI_Fast,{BackgroundColor3=Theme.Background})
                pcall(callback, Input.Text)
            end)
            if tooltip then AddTooltip(F, tooltip) end
            local Obj = {}
            function Obj:Set(v) Input.Text = v end
            function Obj:Get() return Input.Text end
            function Obj:SetTooltip(t) AddTooltip(F, t) end
            return Obj
        end

        ---------------------------------------------------------------
        -- LABEL
        ---------------------------------------------------------------
        function E:CreateLabel(txt, tooltip)
            local F = ElemBG(30)
            local Lbl = New("TextLabel",{
                Parent=F, BackgroundTransparency=1, Text=txt,
                Font=Theme.Font, TextSize=13, TextColor3=Theme.TextMuted,
                Size=UDim2.new(1,-20,1,0), Position=UDim2.new(0,12,0,0),
                TextXAlignment=Enum.TextXAlignment.Left,
            })
            if tooltip then AddTooltip(F, tooltip) end
            local Obj = {}
            function Obj:Set(v) Lbl.Text = v end
            return Obj
        end

        ---------------------------------------------------------------
        -- PARAGRAPH
        ---------------------------------------------------------------
        function E:CreateParagraph(title, content)
            local F = New("Frame",{
                Parent=Container, BackgroundColor3=Theme.Surface,
                Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
                BorderSizePixel=0,
            })
            Corner(F,8); Stroke(F,Theme.Border)
            Reg(F,"BackgroundColor3","Surface")
            local TLbl = New("TextLabel",{
                Parent=F, BackgroundTransparency=1, Text=title,
                Font=Theme.FontBold, TextSize=13, TextColor3=Theme.Text,
                Size=UDim2.new(1,-20,0,26), Position=UDim2.new(0,12,0,6),
                TextXAlignment=Enum.TextXAlignment.Left,
            })
            local CLbl = New("TextLabel",{
                Parent=F, BackgroundTransparency=1, Text=content,
                Font=Theme.Font, TextSize=12, TextColor3=Theme.TextMuted,
                Size=UDim2.new(1,-20,0,0), AutomaticSize=Enum.AutomaticSize.Y,
                Position=UDim2.new(0,12,0,30),
                TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true,
            })
            Pad(F,0,10,0,0)
            local Obj = {}
            function Obj:Set(t,c) if t then TLbl.Text=t end if c then CLbl.Text=c end end
            return Obj
        end

        ---------------------------------------------------------------
        -- KEYBIND
        ---------------------------------------------------------------
        function E:CreateKeybind(txt, default, callback, tooltip)
            local flag    = txt
            local current = default or Enum.KeyCode.Unknown
            local binding = false
            Lib.Flags[flag] = current.Name

            local F = ElemBG(36)
            New("TextLabel",{
                Parent=F, BackgroundTransparency=1, Text=txt,
                Font=Theme.Font, TextSize=13, TextColor3=Theme.Text,
                Size=UDim2.new(1,-100,1,0), Position=UDim2.new(0,12,0,0),
                TextXAlignment=Enum.TextXAlignment.Left,
            })
            local KLbl = New("TextButton",{
                Parent=F, BackgroundColor3=Theme.SurfaceHover,
                Size=UDim2.fromOffset(80,22), Position=UDim2.new(1,-90,0.5,-11),
                Text=current.Name, Font=Theme.FontBold, TextSize=11,
                TextColor3=Theme.Accent, AutoButtonColor=false,
            })
            Corner(KLbl,6); Stroke(KLbl,Theme.Border)

            local function UpdateKey(k)
                current=k; Lib.Flags[flag]=k.Name
                KLbl.Text=k.Name; binding=false
                Tween(KLbl,TI_Fast,{TextColor3=Theme.Accent,BackgroundColor3=Theme.SurfaceHover})
            end

            KLbl.MouseButton1Click:Connect(function()
                binding=true; KLbl.Text="...";
                Tween(KLbl,TI_Fast,{TextColor3=Theme.Warning})
            end)
            UIS.InputBegan:Connect(function(i, gp)
                if not binding then
                    if i.KeyCode==current then pcall(callback,current) end
                    return
                end
                if gp then return end
                if i.UserInputType==Enum.UserInputType.Keyboard then UpdateKey(i.KeyCode) end
            end)

            F.MouseEnter:Connect(function() HoverOn(F) end)
            F.MouseLeave:Connect(function() HoverOff(F) end)
            if tooltip then AddTooltip(F, tooltip) end

            local Obj = {}
            function Obj:Set(k) UpdateKey(k) end
            function Obj:SetTooltip(t) AddTooltip(F, t) end
            Lib.Options[flag] = Obj
            return Obj
        end

        ---------------------------------------------------------------
        -- SEPARADOR VISUAL
        ---------------------------------------------------------------
        function E:CreateSeparator()
            New("Frame",{
                Parent=Container, BackgroundColor3=Theme.Border,
                Size=UDim2.new(1,0,0,1), BorderSizePixel=0,
            })
        end

        return E
    end

    -----------------------------------------------------------------------
    -- RETORNA LIBRARY
    -----------------------------------------------------------------------
    return Lib

end)()
