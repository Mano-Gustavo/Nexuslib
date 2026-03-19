--[[
    ██████╗ ██╗  ██╗ █████╗ ███╗   ██╗████████╗ ██████╗ ███╗   ███╗
    ██╔══██╗██║  ██║██╔══██╗████╗  ██║╚══██╔══╝██╔═══██╗████╗ ████║
    ██████╔╝███████║███████║██╔██╗ ██║   ██║   ██║   ██║██╔████╔██║
    ██╔═══╝ ██╔══██║██╔══██║██║╚██╗██║   ██║   ██║   ██║██║╚██╔╝██║
    ██║     ██║  ██║██║  ██║██║ ╚████║   ██║   ╚██████╔╝██║ ╚═╝ ██║
    ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝

    PHANTOM UI LIBRARY — V1.0
    Estilo: Obsidian-inspired | Dark | Sidebar | Two-column Groupboxes

    API:
      local Lib    = loadstring(...)()
      local Win    = Lib:CreateWindow({ Title, Footer, Keybind })
      local Tab    = Win:AddTab("Nome")
      local Left   = Tab:AddLeftGroupbox("Nome")
      local Right  = Tab:AddRightGroupbox("Nome")

      Left:AddToggle("Idx", { Text, Default, Tooltip, Callback })
         :AddColorPicker("Idx", { Default, Callback })
         :AddKeyPicker("Idx",   { Default, Mode, Callback })
      Left:AddButton({ Text, Func, Tooltip })
         :AddButton({ Text, Func })           -- sub-botão na mesma linha
      Left:AddSlider("Idx",   { Text, Min, Max, Default, Suffix, Rounding, Callback })
      Left:AddDropdown("Idx", { Text, Values, Default, Multi, Callback })
      Left:AddInput("Idx",    { Text, Placeholder, Numeric, Callback })
      Left:AddLabel(text)
      Left:AddDivider()

      Lib:Notify({ Title, Content, Duration })
      Lib:Unload()

    Globais:
      Lib.Toggles["Idx"].Value
      Lib.Options["Idx"].Value
]]

-- ════════════════════════════════════════════════════════════
-- SERVIÇOS
-- ════════════════════════════════════════════════════════════
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ════════════════════════════════════════════════════════════
-- BIBLIOTECA
-- ════════════════════════════════════════════════════════════
local Library = {
    Toggles  = {},
    Options  = {},
    Signals  = {},
    Tabs     = {},
    Unloaded = false,
    Toggled  = false,

    -- Cores do tema
    Scheme = {
        Background = Color3.fromRGB(15, 15, 15),
        Main       = Color3.fromRGB(25, 25, 25),
        Accent     = Color3.fromRGB(125, 85, 255),
        Outline    = Color3.fromRGB(40, 40, 40),
        FontColor  = Color3.new(1, 1, 1),
        Red        = Color3.fromRGB(255, 50, 50),
        Dark       = Color3.new(0, 0, 0),
    },

    TI = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

-- ════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════
local S = Library.Scheme

local function New(cls, props, parent)
    local ok, obj = pcall(Instance.new, cls)
    if not ok then return nil end
    for k, v in pairs(props or {}) do
        local ok2, err = pcall(function() obj[k] = v end)
        if not ok2 then warn("[PhantomUI] New() prop error — "..tostring(k)..": "..tostring(err)) end
    end
    if parent then obj.Parent = parent end
    return obj
end

local function Tw(obj, props)
    if not obj or not obj.Parent then return end
    TweenService:Create(obj, Library.TI, props):Play()
end

local function Corner(p, r)
    return New("UICorner", { CornerRadius = UDim.new(0, r or 4) }, p)
end

local function Stroke(p, col, thick)
    local s = New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Transparency = 0 }, p)
    s.Color = col or S.Outline; s.Thickness = thick or 1
    return s
end

local function Pad(p, t, b, l, r)
    local pad = New("UIPadding", {}, p)
    pad.PaddingTop    = UDim.new(0, t or 0)
    pad.PaddingBottom = UDim.new(0, b or 0)
    pad.PaddingLeft   = UDim.new(0, l or 0)
    pad.PaddingRight  = UDim.new(0, r or 0)
    return pad
end

local function List(p, dir, pad, ha, va)
    return New("UIListLayout", {
        SortOrder           = Enum.SortOrder.LayoutOrder,
        FillDirection       = dir or Enum.FillDirection.Vertical,
        Padding             = UDim.new(0, pad or 0),
        HorizontalAlignment = ha or Enum.HorizontalAlignment.Left,
        VerticalAlignment   = va or Enum.VerticalAlignment.Top,
    }, p)
end

local function Label(parent, text, textSize, color, transparency, xAlign, size, pos)
    return New("TextLabel", {
        BackgroundTransparency = 1,
        Text                   = tostring(text),
        Font                   = Enum.Font.Code,
        TextSize               = textSize or 13,
        TextColor3             = color or S.FontColor,
        TextTransparency       = transparency or 0,
        Size                   = size or UDim2.new(1, 0, 1, 0),
        Position               = pos or UDim2.fromOffset(0, 0),
        TextXAlignment         = xAlign or Enum.TextXAlignment.Left,
        RichText               = false,
    }, parent)
end

function Library:SafeCall(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, err = pcall(fn, ...)
    if not ok then warn("[PhantomUI] Callback error: "..tostring(err)) end
end

function Library:GiveSignal(conn)
    table.insert(self.Signals, conn)
    return conn
end

-- ════════════════════════════════════════════════════════════
-- SCREENGUI
-- ════════════════════════════════════════════════════════════
local GuiName = "PhantomUI_V1"
if CoreGui:FindFirstChild(GuiName) then CoreGui[GuiName]:Destroy() end

local ScreenGui = New("ScreenGui", {
    Name           = GuiName,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder   = 999,
    ResetOnSpawn   = false,
}, CoreGui)
Library.ScreenGui = ScreenGui

-- ════════════════════════════════════════════════════════════
-- TOOLTIP
-- ════════════════════════════════════════════════════════════
local TTFrame = New("Frame", {
    BackgroundColor3       = S.Main,
    Size                   = UDim2.fromOffset(0, 0),
    AutomaticSize          = Enum.AutomaticSize.XY,
    Visible                = false,
    ZIndex                 = 200,
    BorderSizePixel        = 0,
    BackgroundTransparency = 0,
}, ScreenGui)
Corner(TTFrame, 3)
Stroke(TTFrame, S.Outline)
Pad(TTFrame, 4, 4, 8, 8)

local TTLabel = New("TextLabel", {
    BackgroundTransparency = 1,
    Text                   = "",
    Font                   = Enum.Font.Code,
    TextSize               = 12,
    TextColor3             = S.FontColor,
    TextTransparency       = 0.2,
    AutomaticSize          = Enum.AutomaticSize.XY,
    ZIndex                 = 201,
    RichText               = false,
}, TTFrame)

Library:GiveSignal(RunService.RenderStepped:Connect(function()
    if TTFrame.Visible then
        local mp = UserInputService:GetMouseLocation()
        TTFrame.Position = UDim2.fromOffset(mp.X + 14, mp.Y + 14)
    end
end))

local function AddTT(frame, tip)
    if not tip or tip == "" then return end
    frame.MouseEnter:Connect(function() TTLabel.Text = tip; TTFrame.Visible = true end)
    frame.MouseLeave:Connect(function() TTFrame.Visible = false end)
end

-- ════════════════════════════════════════════════════════════
-- NOTIFICAÇÕES
-- ════════════════════════════════════════════════════════════
local NHolder = New("Frame", {
    BackgroundTransparency = 1,
    AnchorPoint            = Vector2.new(1, 1),
    Position               = UDim2.new(1, -10, 1, -10),
    Size                   = UDim2.new(0, 280, 1, 0),
    ZIndex                 = 150,
    BorderSizePixel        = 0,
}, ScreenGui)
New("UIListLayout", {
    SortOrder         = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Padding           = UDim.new(0, 6),
}, NHolder)

function Library:Notify(cfg)
    cfg = cfg or {}
    local title   = tostring(cfg.Title   or "Aviso")
    local content = tostring(cfg.Content or "")
    local dur     = cfg.Duration or 4

    local Card = New("Frame", {
        BackgroundColor3 = S.Main,
        Size             = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        BorderSizePixel  = 0,
    }, NHolder)
    Corner(Card, 4)
    Stroke(Card, S.Accent)

    New("Frame", {
        BackgroundColor3 = S.Accent,
        Size             = UDim2.new(0, 2, 1, 0),
        BorderSizePixel  = 0,
    }, Card)

    Label(Card, title, 13, S.Accent, 0, Enum.TextXAlignment.Left,
        UDim2.new(1, -14, 0, 18), UDim2.fromOffset(10, 8))

    Label(Card, content, 12, S.FontColor, 0.2, Enum.TextXAlignment.Left,
        UDim2.new(1, -14, 0, 30), UDim2.fromOffset(10, 26))
    Card:FindFirstChildOfClass("TextLabel").TextWrapped = true

    local PBar = New("Frame", {
        BackgroundColor3 = S.Accent,
        Size             = UDim2.new(1, -2, 0, 2),
        Position         = UDim2.new(0, 2, 1, -2),
        BorderSizePixel  = 0,
    }, Card)

    Tw(Card, { Size = UDim2.new(1, 0, 0, 62) })
    TweenService:Create(PBar, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 2, 0, 2)
    }):Play()

    task.delay(dur, function()
        Tw(Card, { Size = UDim2.new(1, 0, 0, 0) })
        task.wait(0.15)
        if Card and Card.Parent then Card:Destroy() end
    end)
end

-- ════════════════════════════════════════════════════════════
-- DRAG
-- ════════════════════════════════════════════════════════════
local function MakeDraggable(frame, handle)
    local dragging, dStart, sPos
    handle.InputBegan:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        dragging = true; dStart = i.Position; sPos = frame.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end)
    Library:GiveSignal(UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dStart
            frame.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + d.X, sPos.Y.Scale, sPos.Y.Offset + d.Y)
        end
    end))
end

-- ════════════════════════════════════════════════════════════
-- BUILDER DE ELEMENTOS (Groupbox API)
-- ════════════════════════════════════════════════════════════
local function BuildGroupbox(container)
    local GB = { Container = container, Elements = {} }

    -- ── TOGGLE ────────────────────────────────────────────
    function GB:AddToggle(idx, info)
        info = info or {}
        local text     = tostring(info.Text    or idx)
        local default  = info.Default  == true
        local tooltip  = info.Tooltip
        local callback = info.Callback or function() end

        local Toggle = { Value = default, Text = text, Type = "Toggle", _changed = {}, Addons = {} }

        local Row = New("TextButton", {
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, 0, 0, 18),
            Text                   = "",
            AutoButtonColor        = false,
            BorderSizePixel        = 0,
        }, container)

        -- Checkbox
        local Box = New("Frame", {
            BackgroundColor3 = S.Main,
            Size             = UDim2.fromOffset(14, 14),
            Position         = UDim2.fromOffset(0, 2),
            BorderSizePixel  = 0,
        }, Row)
        Corner(Box, 2)
        local BoxStroke = Stroke(Box, S.Outline)

        local CheckMark = New("TextLabel", {
            BackgroundTransparency = 1,
            Text                   = "✓",
            Font                   = Enum.Font.GothamBold,
            TextSize               = 11,
            TextColor3             = S.Accent,
            Size                   = UDim2.new(1, 0, 1, 0),
            Visible                = default,
            TextXAlignment         = Enum.TextXAlignment.Center,
            RichText               = false,
        }, Box)

        -- Texto
        local TextLbl = New("TextLabel", {
            BackgroundTransparency = 1,
            Text                   = text,
            Font                   = Enum.Font.Code,
            TextSize               = 14,
            TextColor3             = S.FontColor,
            TextTransparency       = default and 0 or 0.4,
            Size                   = UDim2.new(1, -22, 1, 0),
            Position               = UDim2.fromOffset(20, 0),
            TextXAlignment         = Enum.TextXAlignment.Left,
            RichText               = false,
        }, Row)

        -- Frame para addons (ColorPicker, KeyPicker) alinhados à direita
        local AddonsF = New("Frame", {
            BackgroundTransparency = 1,
            AnchorPoint            = Vector2.new(1, 0.5),
            Position               = UDim2.new(1, 0, 0.5, 0),
            Size                   = UDim2.fromOffset(0, 18),
            AutomaticSize          = Enum.AutomaticSize.X,
            BorderSizePixel        = 0,
        }, Row)
        List(AddonsF, Enum.FillDirection.Horizontal, 4, Enum.HorizontalAlignment.Right)

        local function SetState(val, skipCB)
            Toggle.Value   = val
            CheckMark.Visible = val
            Tw(TextLbl,  { TextTransparency = val and 0 or 0.4 })
            Tw(BoxStroke, { Color = val and S.Accent or S.Outline })
            Library.Toggles[idx] = Toggle
            if not skipCB then
                Library:SafeCall(callback, val)
                for _, fn in pairs(Toggle._changed) do Library:SafeCall(fn, val) end
            end
        end

        Row.MouseButton1Click:Connect(function() SetState(not Toggle.Value) end)
        Row.MouseEnter:Connect(function()  Tw(TextLbl, { TextTransparency = Toggle.Value and 0 or 0.15 }) end)
        Row.MouseLeave:Connect(function()  Tw(TextLbl, { TextTransparency = Toggle.Value and 0 or 0.4  }) end)

        if tooltip then AddTT(Row, tooltip) end

        function Toggle:Set(val)       SetState(val, false) end
        function Toggle:OnChanged(fn)  table.insert(self._changed, fn) end

        -- ── COLOR PICKER ADDON ───────────────────────────
        function Toggle:AddColorPicker(cpIdx, cpInfo)
            cpInfo = cpInfo or {}
            local cpDef  = cpInfo.Default  or Color3.new(1, 1, 1)
            local cpCB   = cpInfo.Callback or function() end
            local cpTip  = cpInfo.Tooltip

            local CP = { Value = cpDef, Type = "ColorPicker", _changed = {} }

            local Preview = New("TextButton", {
                BackgroundColor3 = cpDef,
                Size             = UDim2.fromOffset(16, 16),
                Text             = "",
                AutoButtonColor  = false,
                BorderSizePixel  = 0,
            }, AddonsF)
            Corner(Preview, 3)
            Stroke(Preview, S.Outline)

            -- Popup picker
            local POpen = false
            local PFrame = New("Frame", {
                BackgroundColor3 = S.Main,
                Size             = UDim2.fromOffset(190, 120),
                Position         = UDim2.new(1, 4, 0, 0),
                Visible          = false,
                ZIndex           = 30,
                BorderSizePixel  = 0,
            }, Preview)
            Corner(PFrame, 4)
            Stroke(PFrame, S.Outline)
            Pad(PFrame, 8, 8, 8, 8)

            local R = math.floor(cpDef.R * 255)
            local G = math.floor(cpDef.G * 255)
            local B = math.floor(cpDef.B * 255)

            local function UpdateCP(skipCB)
                local col = Color3.fromRGB(R, G, B)
                CP.Value = col
                Preview.BackgroundColor3 = col
                Library.Options[cpIdx] = CP
                if not skipCB then
                    Library:SafeCall(cpCB, col)
                    for _, fn in pairs(CP._changed) do Library:SafeCall(fn, col) end
                end
            end

            local function MakeRGBBar(axis, axisColor, yPos, initVal)
                New("TextLabel", {
                    BackgroundTransparency = 1,
                    Text                   = axis,
                    Font                   = Enum.Font.Code,
                    TextSize               = 11,
                    TextColor3             = axisColor,
                    Size                   = UDim2.fromOffset(10, 14),
                    Position               = UDim2.fromOffset(0, yPos),
                    ZIndex                 = 31,
                    RichText               = false,
                }, PFrame)

                local Track = New("Frame", {
                    BackgroundColor3 = S.Background,
                    Size             = UDim2.new(1, -34, 0, 4),
                    Position         = UDim2.new(0, 14, 0, yPos + 5),
                    BorderSizePixel  = 0,
                    ZIndex           = 31,
                }, PFrame)
                Corner(Track, 2)

                local Fill = New("Frame", {
                    BackgroundColor3 = axisColor,
                    Size             = UDim2.new(initVal / 255, 0, 1, 0),
                    BorderSizePixel  = 0,
                    ZIndex           = 32,
                }, Track)
                Corner(Fill, 2)

                local VLbl = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Text                   = tostring(initVal),
                    Font                   = Enum.Font.Code,
                    TextSize               = 11,
                    TextColor3             = S.FontColor,
                    TextTransparency       = 0.4,
                    Size                   = UDim2.fromOffset(24, 14),
                    Position               = UDim2.new(1, -22, 0, yPos),
                    TextXAlignment         = Enum.TextXAlignment.Right,
                    ZIndex                 = 31,
                    RichText               = false,
                }, PFrame)

                local HB = New("TextButton", {
                    BackgroundTransparency = 1,
                    Size                   = UDim2.new(1, 0, 0, 18),
                    Position               = UDim2.new(0, 0, 0, -3),
                    Text                   = "",
                    ZIndex                 = 33,
                    BorderSizePixel        = 0,
                }, Track)

                local dr = false
                HB.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then dr = true end
                end)
                Library:GiveSignal(UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then dr = false end
                end))
                Library:GiveSignal(UserInputService.InputChanged:Connect(function(i)
                    if dr and i.UserInputType == Enum.UserInputType.MouseMovement then
                        local rel = math.clamp((i.Position.X - Track.AbsolutePosition.X) / math.max(Track.AbsoluteSize.X, 1), 0, 1)
                        local val = math.floor(rel * 255)
                        Fill.Size   = UDim2.new(rel, 0, 1, 0)
                        VLbl.Text   = tostring(val)
                        if axis == "R" then R = val elseif axis == "G" then G = val else B = val end
                        UpdateCP()
                    end
                end))
            end

            MakeRGBBar("R", Color3.fromRGB(255, 80, 80),  0,  R)
            MakeRGBBar("G", Color3.fromRGB(80, 210, 80),  30, G)
            MakeRGBBar("B", Color3.fromRGB(80, 120, 255), 60, B)

            -- Hex input
            local HexBox = New("TextBox", {
                BackgroundColor3 = S.Background,
                Size             = UDim2.new(1, 0, 0, 18),
                Position         = UDim2.fromOffset(0, 94),
                Text             = string.format("#%02X%02X%02X", R, G, B),
                Font             = Enum.Font.Code,
                TextSize         = 12,
                TextColor3       = S.FontColor,
                ClearTextOnFocus = false,
                ZIndex           = 31,
                BorderSizePixel  = 0,
                RichText         = false,
            }, PFrame)
            Corner(HexBox, 3)
            Stroke(HexBox, S.Outline)
            Pad(HexBox, 0, 0, 6, 0)

            HexBox.FocusLost:Connect(function()
                local hex = HexBox.Text:gsub("[^%x]", "")
                if #hex == 6 then
                    R = tonumber(hex:sub(1,2), 16) or R
                    G = tonumber(hex:sub(3,4), 16) or G
                    B = tonumber(hex:sub(5,6), 16) or B
                    UpdateCP()
                    HexBox.Text = string.format("#%02X%02X%02X", R, G, B)
                end
            end)

            Preview.MouseButton1Click:Connect(function()
                POpen = not POpen
                PFrame.Visible = POpen
            end)

            Library:GiveSignal(UserInputService.InputBegan:Connect(function(i)
                if POpen and i.UserInputType == Enum.UserInputType.MouseButton1 then
                    local mp  = UserInputService:GetMouseLocation()
                    local ap  = PFrame.AbsolutePosition
                    local as  = PFrame.AbsoluteSize
                    local pap = Preview.AbsolutePosition
                    if not (mp.X >= ap.X and mp.X <= ap.X + as.X and mp.Y >= ap.Y and mp.Y <= ap.Y + as.Y) then
                        if not (mp.X >= pap.X and mp.X <= pap.X + 16 and mp.Y >= pap.Y and mp.Y <= pap.Y + 16) then
                            POpen = false; PFrame.Visible = false
                        end
                    end
                end
            end))

            if cpTip then AddTT(Preview, cpTip) end

            function CP:Set(col)
                R = math.floor(col.R * 255); G = math.floor(col.G * 255); B = math.floor(col.B * 255)
                UpdateCP(false)
            end
            function CP:OnChanged(fn) table.insert(self._changed, fn) end

            Library.Options[cpIdx] = CP
            UpdateCP(true)
            return Toggle -- permite encadeamento
        end

        -- ── KEYPICKER ADDON ──────────────────────────────
        function Toggle:AddKeyPicker(kpIdx, kpInfo)
            kpInfo = kpInfo or {}
            local kpDef  = tostring(kpInfo.Default or "None")
            local kpMode = kpInfo.Mode     or "Toggle"
            local kpCB   = kpInfo.Callback or function() end

            local KP = { Value = kpDef, Mode = kpMode, Type = "KeyPicker", Binding = false }

            local KBtn = New("TextButton", {
                BackgroundColor3 = S.Main,
                Size             = UDim2.fromOffset(58, 16),
                Text             = "[" .. kpDef .. "]",
                Font             = Enum.Font.Code,
                TextSize         = 11,
                TextColor3       = S.FontColor,
                TextTransparency = 0.3,
                AutoButtonColor  = false,
                BorderSizePixel  = 0,
                RichText         = false,
            }, AddonsF)
            Corner(KBtn, 3)
            Stroke(KBtn, S.Outline)

            KBtn.MouseButton1Click:Connect(function()
                KP.Binding = true
                KBtn.Text = "[...]"
                Tw(KBtn, { TextColor3 = S.Accent })
            end)

            Library:GiveSignal(UserInputService.InputBegan:Connect(function(i, gp)
                if KP.Binding then
                    if gp then return end
                    if i.UserInputType == Enum.UserInputType.Keyboard then
                        KP.Value   = i.KeyCode.Name
                        KP.Binding = false
                        KBtn.Text  = "[" .. KP.Value .. "]"
                        Tw(KBtn, { TextColor3 = S.FontColor })
                        Library.Options[kpIdx] = KP
                    end
                    return
                end
                if gp then return end
                if i.KeyCode.Name == KP.Value then
                    if kpMode == "Toggle" then Toggle:Set(not Toggle.Value)
                    elseif kpMode == "Hold" then Toggle:Set(true)
                    elseif kpMode == "Always" then Library:SafeCall(kpCB, true) end
                end
            end))

            Library:GiveSignal(UserInputService.InputEnded:Connect(function(i)
                if kpMode == "Hold" and i.KeyCode.Name == KP.Value then
                    Toggle:Set(false)
                    Library:SafeCall(kpCB, false)
                end
            end))

            Library.Options[kpIdx] = KP
            return Toggle
        end

        SetState(default, true)
        Library.Toggles[idx] = Toggle
        table.insert(GB.Elements, { Text = text, Type = "Toggle", Holder = Row, Visible = true })
        return Toggle
    end

    -- ── BUTTON ────────────────────────────────────────────
    function GB:AddButton(info)
        info = info or {}
        local text    = tostring(info.Text or "Button")
        local func    = info.Func or info.Callback or function() end
        local risky   = info.Risky   or false
        local tip     = info.Tooltip
        local disabled = info.Disabled or false

        local Row = New("Frame", {
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, 0, 0, 20),
            BorderSizePixel        = 0,
        }, container)
        List(Row, Enum.FillDirection.Horizontal, 6)
        New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }, Row)

        local Btn = New("TextButton", {
            BackgroundColor3 = S.Main,
            Size             = UDim2.fromScale(1, 1),
            Text             = text,
            Font             = Enum.Font.Code,
            TextSize         = 14,
            TextColor3       = risky and S.Red or S.FontColor,
            TextTransparency = 0.4,
            AutoButtonColor  = false,
            Active           = not disabled,
            BorderSizePixel  = 0,
            RichText         = false,
        }, Row)
        Corner(Btn, 3)
        Stroke(Btn, S.Outline)

        Btn.MouseEnter:Connect(function()  if not disabled then Tw(Btn, { TextTransparency = 0 })   end end)
        Btn.MouseLeave:Connect(function()  Tw(Btn, { TextTransparency = disabled and 0.7 or 0.4 }) end)
        Btn.MouseButton1Click:Connect(function() if not disabled then Library:SafeCall(func) end end)

        if tip then AddTT(Btn, tip) end

        local BtnObj = { Text = text, Type = "Button", _row = Row }

        -- Sub-botão na mesma linha
        function BtnObj:AddButton(subInfo)
            subInfo = subInfo or {}
            local sBtnF = New("TextButton", {
                BackgroundColor3 = S.Main,
                Size             = UDim2.fromScale(1, 1),
                Text             = tostring(subInfo.Text or "Button"),
                Font             = Enum.Font.Code,
                TextSize         = 14,
                TextColor3       = S.FontColor,
                TextTransparency = 0.4,
                AutoButtonColor  = false,
                BorderSizePixel  = 0,
                RichText         = false,
            }, Row)
            Corner(sBtnF, 3)
            Stroke(sBtnF, S.Outline)
            sBtnF.MouseEnter:Connect(function()  Tw(sBtnF, { TextTransparency = 0 }) end)
            sBtnF.MouseLeave:Connect(function()  Tw(sBtnF, { TextTransparency = 0.4 }) end)
            sBtnF.MouseButton1Click:Connect(function()
                Library:SafeCall(subInfo.Func or subInfo.Callback or function() end)
            end)
            return BtnObj
        end

        table.insert(GB.Elements, { Text = text, Type = "Button", Holder = Row, Visible = not disabled })
        return BtnObj
    end

    -- ── SLIDER ────────────────────────────────────────────
    function GB:AddSlider(idx, info)
        info = info or {}
        local text     = tostring(info.Text or idx)
        local min      = tonumber(info.Min)     or 0
        local max      = tonumber(info.Max)     or 100
        local default  = math.clamp(tonumber(info.Default) or min, min, max)
        local suffix   = tostring(info.Suffix   or "")
        local rounding = tonumber(info.Rounding) or 0
        local tip      = info.Tooltip
        local callback = info.Callback or function() end

        local Slider = { Value = default, Type = "Slider", _changed = {} }

        local Wrap = New("Frame", {
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, 0, 0, 36),
            BorderSizePixel        = 0,
        }, container)

        Label(Wrap, text, 13, S.FontColor, 0.2, Enum.TextXAlignment.Left,
              UDim2.new(0.65, 0, 0, 16), UDim2.fromOffset(0, 0))

        local ValLbl = New("TextLabel", {
            BackgroundTransparency = 1,
            Text                   = tostring(default) .. suffix,
            Font                   = Enum.Font.Code,
            TextSize               = 12,
            TextColor3             = S.Accent,
            Size                   = UDim2.new(0.35, -4, 0, 16),
            Position               = UDim2.new(0.65, 4, 0, 0),
            TextXAlignment         = Enum.TextXAlignment.Right,
            RichText               = false,
        }, Wrap)

        local Track = New("Frame", {
            BackgroundColor3 = S.Outline,
            Size             = UDim2.new(1, 0, 0, 4),
            Position         = UDim2.fromOffset(0, 22),
            BorderSizePixel  = 0,
        }, Wrap)
        Corner(Track, 2)

        local ratio = max ~= min and (default - min) / (max - min) or 0
        local Fill  = New("Frame", {
            BackgroundColor3 = S.Accent,
            Size             = UDim2.new(ratio, 0, 1, 0),
            BorderSizePixel  = 0,
        }, Track)
        Corner(Fill, 2)

        local Thumb = New("Frame", {
            BackgroundColor3 = Color3.new(1,1,1),
            AnchorPoint      = Vector2.new(0.5, 0.5),
            Size             = UDim2.fromOffset(8, 8),
            Position         = UDim2.new(1, 0, 0.5, 0),
            BorderSizePixel  = 0,
        }, Fill)
        Corner(Thumb, 4)

        local HitBox = New("TextButton", {
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, 0, 0, 20),
            Position               = UDim2.new(0, 0, 0.5, -10),
            Text                   = "",
            ZIndex                 = 5,
            BorderSizePixel        = 0,
        }, Track)

        local function RoundVal(v)
            if rounding == 0 then return math.floor(v + 0.5) end
            local m = 10 ^ rounding
            return math.floor(v * m + 0.5) / m
        end

        local function UpdateSlider(v, skipCB)
            local clamped  = math.clamp(v, min, max)
            Slider.Value   = RoundVal(clamped)
            local r        = max ~= min and (clamped - min) / (max - min) or 0
            Tw(Fill, { Size = UDim2.new(r, 0, 1, 0) })
            ValLbl.Text    = tostring(Slider.Value) .. suffix
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
                local rel = math.clamp((i.Position.X - Track.AbsolutePosition.X) / math.max(Track.AbsoluteSize.X, 1), 0, 1)
                UpdateSlider(min + (max - min) * rel)
            end
        end))

        if tip then AddTT(Wrap, tip) end

        function Slider:Set(v) UpdateSlider(v, false) end
        function Slider:OnChanged(fn) table.insert(self._changed, fn) end

        Library.Options[idx] = Slider
        UpdateSlider(default, true)
        table.insert(GB.Elements, { Text = text, Type = "Slider", Holder = Wrap, Visible = true })
        return Slider
    end

    -- ── DROPDOWN ──────────────────────────────────────────
    function GB:AddDropdown(idx, info)
        info = info or {}
        local text     = tostring(info.Text or idx)
        local values   = info.Values   or {}
        local multi    = info.Multi    or false
        local tip      = info.Tooltip
        local callback = info.Callback or function() end
        local disabled = info.Disabled or false

        local default
        if multi then
            default = {}
        elseif type(info.Default) == "number" then
            default = values[info.Default]
        else
            default = info.Default or values[1]
        end

        local Drop = { Value = multi and {} or default, Values = values, Multi = multi, Type = "Dropdown", _open = false, _changed = {} }

        local HC, HO = 20, 19

        local Wrap = New("Frame", {
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, 0, 0, 36),
            ClipsDescendants       = false,
            BorderSizePixel        = 0,
        }, container)

        Label(Wrap, text, 13, S.FontColor, 0.2, Enum.TextXAlignment.Left,
              UDim2.new(1, 0, 0, 14), UDim2.fromOffset(0, 0))

        local Head = New("TextButton", {
            BackgroundColor3 = S.Main,
            Size             = UDim2.new(1, 0, 0, HC),
            Position         = UDim2.fromOffset(0, 16),
            Text             = "",
            AutoButtonColor  = false,
            Active           = not disabled,
            BorderSizePixel  = 0,
            ZIndex           = 10,
        }, Wrap)
        Corner(Head, 3)
        Stroke(Head, S.Outline)

        local function GetDisplayText()
            if multi then
                local keys = {}
                for k, v in pairs(Drop.Value) do if v then table.insert(keys, tostring(k)) end end
                return #keys == 0 and "Nenhum" or table.concat(keys, ", ")
            end
            return tostring(Drop.Value or "Selecionar")
        end

        local HeadLbl = New("TextLabel", {
            BackgroundTransparency = 1,
            Text                   = GetDisplayText(),
            Font                   = Enum.Font.Code,
            TextSize               = 13,
            TextColor3             = S.FontColor,
            TextTransparency       = disabled and 0.6 or 0.25,
            Size                   = UDim2.new(1, -20, 1, 0),
            Position               = UDim2.fromOffset(7, 0),
            TextXAlignment         = Enum.TextXAlignment.Left,
            RichText               = false,
            ZIndex                 = 11,
        }, Head)

        local Arrow = New("TextLabel", {
            BackgroundTransparency = 1,
            Text                   = "v",
            Font                   = Enum.Font.Code,
            TextSize               = 11,
            TextColor3             = S.FontColor,
            TextTransparency       = 0.4,
            Size                   = UDim2.fromOffset(14, HC),
            Position               = UDim2.new(1, -16, 0, 0),
            ZIndex                 = 11,
            RichText               = false,
        }, Head)

        local Menu = New("Frame", {
            BackgroundColor3 = S.Main,
            Size             = UDim2.new(1, 0, 0, 0),
            Position         = UDim2.new(0, 0, 1, 2),
            Visible          = false,
            ZIndex           = 50,
            BorderSizePixel  = 0,
            ClipsDescendants = true,
        }, Head)
        Corner(Menu, 3)
        Stroke(Menu, S.Outline)

        local MenuList = New("Frame", {
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, 0, 0, 0),
            AutomaticSize          = Enum.AutomaticSize.Y,
            ZIndex                 = 51,
        }, Menu)
        List(MenuList, nil, 0)
        Pad(MenuList, 2, 2, 0, 0)

        local function SetValue(val, skipCB)
            Drop.Value = val
            HeadLbl.Text = GetDisplayText()
            Library.Options[idx] = Drop
            if not skipCB then
                Library:SafeCall(callback, val)
                for _, fn in pairs(Drop._changed) do Library:SafeCall(fn, val) end
            end
        end

        local function BuildOpts(vals)
            for _, c in pairs(MenuList:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            for _, opt in ipairs(vals) do
                local optStr = tostring(opt)
                local OBtn = New("TextButton", {
                    BackgroundTransparency = 1,
                    Size                   = UDim2.new(1, 0, 0, HO),
                    Text                   = "",
                    AutoButtonColor        = false,
                    ZIndex                 = 52,
                    BorderSizePixel        = 0,
                }, MenuList)

                local isChecked = multi and Drop.Value[opt] == true or Drop.Value == opt
                local Check2 = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Text                   = isChecked and "✓" or "",
                    Font                   = Enum.Font.Code,
                    TextSize               = 12,
                    TextColor3             = S.Accent,
                    Size                   = UDim2.fromOffset(14, HO),
                    Position               = UDim2.fromOffset(4, 0),
                    ZIndex                 = 53,
                    RichText               = false,
                }, OBtn)

                local OptLbl = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Text                   = optStr,
                    Font                   = Enum.Font.Code,
                    TextSize               = 13,
                    TextColor3             = S.FontColor,
                    TextTransparency       = isChecked and 0 or 0.4,
                    Size                   = UDim2.new(1, -20, 1, 0),
                    Position               = UDim2.fromOffset(20, 0),
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    ZIndex                 = 53,
                    RichText               = false,
                }, OBtn)

                OBtn.MouseEnter:Connect(function() Tw(OBtn, { BackgroundTransparency = 0.85 }) end)
                OBtn.MouseLeave:Connect(function() Tw(OBtn, { BackgroundTransparency = 1    }) end)
                OBtn.MouseButton1Click:Connect(function()
                    if multi then
                        Drop.Value[opt] = not Drop.Value[opt]
                        Check2.Text = Drop.Value[opt] and "✓" or ""
                        Tw(OptLbl, { TextTransparency = Drop.Value[opt] and 0 or 0.4 })
                        SetValue(Drop.Value)
                    else
                        SetValue(opt)
                        Drop._open = false
                        Tw(Menu, { Size = UDim2.new(1, 0, 0, 0) })
                        task.delay(0.15, function() if Menu then Menu.Visible = false end end)
                        Arrow.Text = "v"
                        BuildOpts(Drop.Values)
                    end
                end)
            end
        end

        BuildOpts(values)

        local function ToggleMenu()
            if disabled then return end
            Drop._open = not Drop._open
            if Drop._open then
                Menu.Visible = true
                Tw(Menu, { Size = UDim2.new(1, 0, 0, #values * HO + 4) })
                Arrow.Text = "^"
            else
                Tw(Menu, { Size = UDim2.new(1, 0, 0, 0) })
                task.delay(0.15, function() if Menu then Menu.Visible = false end end)
                Arrow.Text = "v"
            end
        end

        Head.MouseButton1Click:Connect(ToggleMenu)

        Library:GiveSignal(UserInputService.InputBegan:Connect(function(i)
            if not Drop._open then return end
            if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            local mp  = UserInputService:GetMouseLocation()
            local ap  = Menu.AbsolutePosition
            local as  = Menu.AbsoluteSize
            local hap = Head.AbsolutePosition
            if not (mp.X >= ap.X and mp.X <= ap.X + as.X and mp.Y >= ap.Y and mp.Y <= ap.Y + as.Y) then
                if not (mp.X >= hap.X and mp.X <= hap.X + Head.AbsoluteSize.X and mp.Y >= hap.Y and mp.Y <= hap.Y + HC) then
                    Drop._open = false
                    Tw(Menu, { Size = UDim2.new(1, 0, 0, 0) })
                    task.delay(0.15, function() if Menu then Menu.Visible = false end end)
                    Arrow.Text = "v"
                end
            end
        end))

        if tip then AddTT(Head, tip) end

        function Drop:Set(val)         SetValue(val, false) end
        function Drop:SetValues(vals)  Drop.Values = vals; BuildOpts(vals) end
        function Drop:OnChanged(fn)    table.insert(self._changed, fn) end

        Library.Options[idx] = Drop
        SetValue(default, true)
        table.insert(GB.Elements, { Text = text, Type = "Dropdown", Holder = Wrap, Visible = true })
        return Drop
    end

    -- ── INPUT ─────────────────────────────────────────────
    function GB:AddInput(idx, info)
        info = info or {}
        local text     = tostring(info.Text        or idx)
        local holder   = tostring(info.Placeholder or "")
        local numeric  = info.Numeric   or false
        local tip      = info.Tooltip
        local callback = info.Callback  or function() end
        local finished = info.Finished  or false

        local Input = { Value = tostring(info.Default or ""), Type = "Input", _changed = {} }

        local Wrap = New("Frame", {
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, 0, 0, 36),
            BorderSizePixel        = 0,
        }, container)

        Label(Wrap, text, 13, S.FontColor, 0.2, Enum.TextXAlignment.Left,
              UDim2.new(1, 0, 0, 14), UDim2.fromOffset(0, 0))

        local IBG = New("Frame", {
            BackgroundColor3 = S.Main,
            Size             = UDim2.new(1, 0, 0, 20),
            Position         = UDim2.fromOffset(0, 16),
            BorderSizePixel  = 0,
        }, Wrap)
        Corner(IBG, 3)
        local IStroke = Stroke(IBG, S.Outline)
        Pad(IBG, 0, 0, 6, 6)

        local Box = New("TextBox", {
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, 0, 1, 0),
            Text                   = Input.Value,
            PlaceholderText        = holder,
            PlaceholderColor3      = Color3.fromRGB(75, 75, 75),
            Font                   = Enum.Font.Code,
            TextSize               = 13,
            TextColor3             = S.FontColor,
            TextXAlignment         = Enum.TextXAlignment.Left,
            ClearTextOnFocus       = false,
            RichText               = false,
        }, IBG)

        Box.Focused:Connect(function()   Tw(IStroke, { Color = S.Accent }) end)
        Box.FocusLost:Connect(function(enter)
            Tw(IStroke, { Color = S.Outline })
            local val = Box.Text
            if numeric then val = tonumber(val) or Input.Value end
            Input.Value = val
            Library.Options[idx] = Input
            if not finished or enter then
                Library:SafeCall(callback, val)
                for _, fn in pairs(Input._changed) do Library:SafeCall(fn, val) end
            end
        end)

        if not finished then
            Box:GetPropertyChangedSignal("Text"):Connect(function()
                Input.Value = Box.Text
                Library:SafeCall(callback, Box.Text)
            end)
        end

        if tip then AddTT(IBG, tip) end

        function Input:Set(v)       Box.Text = tostring(v); Input.Value = v end
        function Input:OnChanged(fn) table.insert(self._changed, fn) end

        Library.Options[idx] = Input
        table.insert(GB.Elements, { Text = text, Type = "Input", Holder = Wrap, Visible = true })
        return Input
    end

    -- ── LABEL ─────────────────────────────────────────────
    function GB:AddLabel(text, doesWrap)
        local Lbl = New("TextLabel", {
            BackgroundTransparency = 1,
            Text                   = tostring(text),
            Font                   = Enum.Font.Code,
            TextSize               = 13,
            TextColor3             = S.FontColor,
            TextTransparency       = 0.4,
            Size                   = UDim2.new(1, 0, 0, doesWrap and 0 or 16),
            AutomaticSize          = doesWrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            TextXAlignment         = Enum.TextXAlignment.Left,
            TextWrapped            = doesWrap or false,
            RichText               = false,
        }, container)

        local LObj = { Type = "Label", Holder = Lbl, Text = tostring(text), Visible = true }
        function LObj:SetText(t) Lbl.Text = tostring(t); self.Text = tostring(t) end
        table.insert(GB.Elements, LObj)
        return LObj
    end

    -- ── DIVIDER ───────────────────────────────────────────
    function GB:AddDivider()
        local Div = New("Frame", {
            BackgroundColor3 = S.Outline,
            Size             = UDim2.new(1, 0, 0, 1),
            BorderSizePixel  = 0,
        }, container)
        table.insert(GB.Elements, { Type = "Divider", Holder = Div, Visible = true })
        return GB
    end

    return GB
end

-- ════════════════════════════════════════════════════════════
-- CREATE WINDOW
-- ════════════════════════════════════════════════════════════
function Library:CreateWindow(cfg)
    cfg = cfg or {}
    local title   = tostring(cfg.Title   or "Phantom Hub")
    local footer  = tostring(cfg.Footer  or "v1.0")
    local keybind = cfg.Keybind or Enum.KeyCode.RightControl

    -- ── Frame principal ───────────────────────────────────
    local MainFrame = New("Frame", {
        Name             = "MainFrame",
        BackgroundColor3 = S.Background,
        Size             = UDim2.fromOffset(740, 540),
        Position         = UDim2.fromScale(0.5, 0.5),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BorderSizePixel  = 0,
        ClipsDescendants = false,
    }, ScreenGui)
    Corner(MainFrame, 5)
    Stroke(MainFrame, S.Outline)
    Library.MainFrame = MainFrame

    -- ── Topbar ────────────────────────────────────────────
    local Topbar = New("Frame", {
        BackgroundColor3 = S.Main,
        Size             = UDim2.new(1, 0, 0, 36),
        BorderSizePixel  = 0,
    }, MainFrame)
    New("Frame", {
        BackgroundColor3 = S.Outline,
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BorderSizePixel  = 0,
    }, Topbar)
    MakeDraggable(MainFrame, Topbar)

    New("TextLabel", {
        BackgroundTransparency = 1,
        Text                   = title,
        Font                   = Enum.Font.Code,
        TextSize               = 14,
        TextColor3             = S.FontColor,
        Size                   = UDim2.new(0.5, 0, 1, 0),
        Position               = UDim2.fromOffset(10, 0),
        TextXAlignment         = Enum.TextXAlignment.Left,
        RichText               = false,
    }, Topbar)

    New("TextLabel", {
        BackgroundTransparency = 1,
        Text                   = footer,
        Font                   = Enum.Font.Code,
        TextSize               = 12,
        TextColor3             = S.FontColor,
        TextTransparency       = 0.55,
        Size                   = UDim2.new(0.5, -10, 1, 0),
        Position               = UDim2.new(0.5, 0, 0, 0),
        TextXAlignment         = Enum.TextXAlignment.Right,
        RichText               = false,
    }, Topbar)

    -- ── Search Bar ────────────────────────────────────────
    local SearchBar = New("Frame", {
        BackgroundColor3 = S.Main,
        Size             = UDim2.new(1, 0, 0, 28),
        Position         = UDim2.fromOffset(0, 36),
        BorderSizePixel  = 0,
    }, MainFrame)
    New("Frame", {
        BackgroundColor3 = S.Outline,
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BorderSizePixel  = 0,
    }, SearchBar)

    local SearchBox = New("TextBox", {
        BackgroundTransparency = 1,
        PlaceholderText        = "Pesquisar...",
        PlaceholderColor3      = Color3.fromRGB(85, 85, 85),
        Text                   = "",
        Font                   = Enum.Font.Code,
        TextSize               = 13,
        TextColor3             = S.FontColor,
        Size                   = UDim2.new(1, -16, 1, 0),
        Position               = UDim2.fromOffset(8, 0),
        TextXAlignment         = Enum.TextXAlignment.Left,
        ClearTextOnFocus       = false,
        RichText               = false,
    }, SearchBar)

    -- ── Sidebar ───────────────────────────────────────────
    local SBWidth = 128
    local Sidebar = New("Frame", {
        BackgroundColor3 = S.Main,
        Size             = UDim2.new(0, SBWidth, 1, -64),
        Position         = UDim2.fromOffset(0, 64),
        BorderSizePixel  = 0,
    }, MainFrame)
    New("Frame", {
        BackgroundColor3 = S.Outline,
        Size             = UDim2.new(0, 1, 1, 0),
        Position         = UDim2.new(1, -1, 0, 0),
        BorderSizePixel  = 0,
    }, Sidebar)

    local SBList = New("Frame", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        BorderSizePixel        = 0,
    }, Sidebar)
    List(SBList)

    -- ── Content ───────────────────────────────────────────
    local Content = New("Frame", {
        BackgroundTransparency = 1,
        Position               = UDim2.fromOffset(SBWidth, 64),
        Size                   = UDim2.new(1, -SBWidth, 1, -64),
        ClipsDescendants       = true,
        BorderSizePixel        = 0,
    }, MainFrame)

    -- ── Toggle keybind ────────────────────────────────────
    Library:GiveSignal(UserInputService.InputBegan:Connect(function(i, gp)
        if gp or Library.Unloaded then return end
        if UserInputService:GetFocusedTextBox() then return end
        if i.KeyCode == keybind then
            Library.Toggled = not Library.Toggled
            MainFrame.Visible = Library.Toggled
        end
    end))

    -- ════════════════════════════════════════════════════════
    -- WINDOW API
    -- ════════════════════════════════════════════════════════
    local Window    = {}
    local ActivePg  = nil
    local ActiveBtn = nil

    function Window:AddTab(name)
        name = tostring(name)

        -- ── Botão na sidebar ─────────────────────────────
        local TBtn = New("TextButton", {
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, 0, 0, 28),
            Text                   = "",
            AutoButtonColor        = false,
            BorderSizePixel        = 0,
        }, SBList)

        local Ind = New("Frame", {
            BackgroundColor3 = S.Accent,
            Size             = UDim2.new(0, 2, 0.6, 0),
            Position         = UDim2.new(0, 0, 0.2, 0),
            BorderSizePixel  = 0,
            Visible          = false,
        }, TBtn)
        Corner(Ind, 1)

        local TLbl = New("TextLabel", {
            BackgroundTransparency = 1,
            Text                   = name,
            Font                   = Enum.Font.Code,
            TextSize               = 13,
            TextColor3             = S.FontColor,
            TextTransparency       = 0.55,
            Size                   = UDim2.new(1, -12, 1, 0),
            Position               = UDim2.fromOffset(10, 0),
            TextXAlignment         = Enum.TextXAlignment.Left,
            RichText               = false,
        }, TBtn)

        -- ── Página de conteúdo ────────────────────────────
        local Page = New("Frame", {
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, 0, 1, 0),
            Visible                = false,
            BorderSizePixel        = 0,
        }, Content)

        -- Duas colunas
        local function MakeCol(xScale, xOffset, wScale, wOffset)
            local col = New("ScrollingFrame", {
                BackgroundTransparency = 1,
                Position               = UDim2.new(xScale, xOffset, 0, 6),
                Size                   = UDim2.new(wScale, wOffset, 1, -12),
                ScrollBarThickness     = 2,
                ScrollBarImageColor3   = S.Outline,
                CanvasSize             = UDim2.fromOffset(0, 0),
                AutomaticCanvasSize    = Enum.AutomaticSize.Y,
                BorderSizePixel        = 0,
            }, Page)
            List(col, nil, 6)
            return col
        end

        local LeftCol  = MakeCol(0,   6, 0.5, -9)
        local RightCol = MakeCol(0.5, 3, 0.5, -9)

        -- ── Tab API (declarado antes do SelectTab para evitar referência nil) ─
        local Tab = { _left = LeftCol, _right = RightCol, Groupboxes = {} }

        -- ── Selecionar tab ────────────────────────────────
        local function SelectTab()
            if ActivePg  then ActivePg.Visible = false end
            if ActiveBtn then
                ActiveBtn._ind.Visible = false
                Tw(ActiveBtn._lbl, { TextTransparency = 0.55 })
                Tw(ActiveBtn._btn, { BackgroundTransparency = 1 })
            end
            Page.Visible = true; ActivePg = Page
            Ind.Visible  = true
            Tw(TLbl, { TextTransparency = 0 })
            Tw(TBtn, { BackgroundTransparency = 0.9 })
            ActiveBtn = { _btn = TBtn, _lbl = TLbl, _ind = Ind }
            Library.ActiveTab = Tab
        end

        TBtn.MouseButton1Click:Connect(SelectTab)
        TBtn.MouseEnter:Connect(function()
            if Page ~= ActivePg then Tw(TBtn, { BackgroundTransparency = 0.95 }) end
        end)
        TBtn.MouseLeave:Connect(function()
            if Page ~= ActivePg then Tw(TBtn, { BackgroundTransparency = 1 }) end
        end)

        if not ActivePg then SelectTab() end

        local function MakeGB(col, gbName)
            gbName = tostring(gbName)

            local GBHolder = New("Frame", {
                BackgroundColor3 = S.Background,
                Size             = UDim2.new(1, 0, 0, 0),
                AutomaticSize    = Enum.AutomaticSize.Y,
                BorderSizePixel  = 0,
            }, col)
            Corner(GBHolder, 4)
            Stroke(GBHolder, S.Outline)

            -- Cabeçalho
            local GBTitle = New("TextLabel", {
                BackgroundTransparency = 1,
                Text                   = gbName,
                Font                   = Enum.Font.Code,
                TextSize               = 14,
                TextColor3             = S.FontColor,
                Size                   = UDim2.new(1, 0, 0, 32),
                TextXAlignment         = Enum.TextXAlignment.Left,
                RichText               = false,
            }, GBHolder)
            Pad(GBTitle, 0, 0, 12, 0)

            New("Frame", {
                BackgroundColor3 = S.Outline,
                Size             = UDim2.new(1, 0, 0, 1),
                Position         = UDim2.fromOffset(0, 32),
                BorderSizePixel  = 0,
            }, GBHolder)

            -- Container dos elementos
            local GBContainer = New("Frame", {
                BackgroundTransparency = 1,
                Position               = UDim2.fromOffset(0, 33),
                Size                   = UDim2.new(1, 0, 0, 0),
                AutomaticSize          = Enum.AutomaticSize.Y,
                BorderSizePixel        = 0,
            }, GBHolder)
            List(GBContainer, nil, 6)
            Pad(GBContainer, 6, 8, 8, 8)

            local GB = BuildGroupbox(GBContainer)
            GB.Holder = GBHolder
            Tab.Groupboxes[gbName] = GB
            return GB
        end

        function Tab:AddLeftGroupbox(n)  return MakeGB(LeftCol, n)  end
        function Tab:AddRightGroupbox(n) return MakeGB(RightCol, n) end

        table.insert(Library.Tabs, Tab)
        return Tab
    end

    -- ── Search ────────────────────────────────────────────
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = SearchBox.Text:lower():match("^%s*(.-)%s*$")
        if not Library.ActiveTab then return end

        for _, gb in pairs(Library.ActiveTab.Groupboxes) do
            if query == "" then
                gb.Holder.Visible = true
                for _, el in ipairs(gb.Elements) do
                    if el.Holder and el.Holder.Parent then
                        el.Holder.Visible = el.Visible
                    end
                end
            else
                local found = 0
                for _, el in ipairs(gb.Elements) do
                    if el.Holder and el.Holder.Parent then
                        if el.Type ~= "Divider" and el.Text and el.Text:lower():find(query, 1, true) and el.Visible then
                            el.Holder.Visible = true; found += 1
                        elseif el.Type ~= "Divider" then
                            el.Holder.Visible = false
                        end
                    end
                end
                gb.Holder.Visible = found > 0
            end
        end
    end)

    -- Mostra ao iniciar
    Library.Toggled = true
    MainFrame.Visible = true

    return Window
end

-- ════════════════════════════════════════════════════════════
-- UNLOAD
-- ════════════════════════════════════════════════════════════
function Library:Unload()
    Library.Unloaded = true
    for _, c in ipairs(Library.Signals) do
        if c and c.Connected then c:Disconnect() end
    end
    if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
end

getgenv().PhantomLib = Library
return Library
