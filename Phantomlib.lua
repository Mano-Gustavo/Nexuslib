--[[
    PHANTOM UI LIBRARY — V2.0
    Estilo: Obsidian-inspired | Dark | Sidebar | Two-column

    API:
        local Lib    = loadstring(...)()
        local Win    = Lib:CreateWindow({ Title, Footer, Keybind })
        local Tab    = Win:AddTab("Nome")
        local Left   = Tab:AddLeftGroupbox("Nome")
        local Right  = Tab:AddRightGroupbox("Nome")

        GB:AddToggle("Idx", { Text, Default, Tooltip, Callback })
            :AddColorPicker("Idx", { Default, Callback })
            :AddKeyPicker("Idx",   { Default, Mode, Callback })
        GB:AddButton({ Text, Func, Tooltip, Risky })
            :AddButton({ Text, Func })
        GB:AddSlider("Idx", { Text, Min, Max, Default, Suffix, Rounding, Callback })
        GB:AddDropdown("Idx", { Text, Values, Default, Multi, Callback })
        GB:AddInput("Idx", { Text, Placeholder, Numeric, Finished, Callback })
        GB:AddLabel(text, doesWrap)
        GB:AddDivider()

        Lib:Notify({ Title, Content, Duration })
        Lib:Unload()

    Globais após carregamento:
        Lib.Toggles["Idx"].Value
        Lib.Options["Idx"].Value
]]

-- ── Serviços ──────────────────────────────────────────────
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- ── Biblioteca ────────────────────────────────────────────
local Lib = {
    Toggles  = {},
    Options  = {},
    Signals  = {},
    Tabs     = {},
    Unloaded = false,
    Toggled  = false,
    ActiveTab = nil,

    Scheme = {
        Bg      = Color3.fromRGB(15, 15, 15),
        Main    = Color3.fromRGB(25, 25, 25),
        Accent  = Color3.fromRGB(125, 85, 255),
        Outline = Color3.fromRGB(40, 40, 40),
        Text    = Color3.new(1, 1, 1),
        Red     = Color3.fromRGB(255, 50, 50),
        Dark    = Color3.new(0, 0, 0),
    },
    TI = TweenInfo.new(0.1, Enum.EasingStyle.Quad),
}

local S = Lib.Scheme

-- ── ScreenGui ─────────────────────────────────────────────
local GuiName = "PhantomUI_V2"
if CoreGui:FindFirstChild(GuiName) then CoreGui[GuiName]:Destroy() end
local GUI = Instance.new("ScreenGui")
GUI.Name           = GuiName
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.DisplayOrder   = 999
GUI.ResetOnSpawn   = false
GUI.Parent         = CoreGui
Lib.ScreenGui      = GUI

-- ── Helpers ───────────────────────────────────────────────
local function New(cls, props, parent)
    local ok, obj = pcall(Instance.new, cls)
    if not ok then warn("[PhantomUI] Instance.new("..cls..") failed") return nil end
    for k, v in pairs(props or {}) do
        local ok2, e = pcall(function() obj[k] = v end)
        if not ok2 then warn("[PhantomUI] "..cls.."."..tostring(k)..": "..tostring(e)) end
    end
    if parent then obj.Parent = parent end
    return obj
end

local function Tw(o, p)
    if not o or not o.Parent then return end
    TweenService:Create(o, Lib.TI, p):Play()
end

local function Corner(p, r) return New("UICorner",{CornerRadius=UDim.new(0,r or 4)},p) end
local function Stroke(p, c, t) local s=New("UIStroke",{ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Thickness=t or 1},p); s.Color=c or S.Outline; return s end
local function Pad(p,t,b,l,r) local x=New("UIPadding",{},p); x.PaddingTop=UDim.new(0,t or 0); x.PaddingBottom=UDim.new(0,b or 0); x.PaddingLeft=UDim.new(0,l or 0); x.PaddingRight=UDim.new(0,r or 0); return x end
local function ListLayout(p,dir,gap,ha) return New("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,FillDirection=dir or Enum.FillDirection.Vertical,Padding=UDim.new(0,gap or 0),HorizontalAlignment=ha or Enum.HorizontalAlignment.Left},p) end

local function Lbl(parent, text, size, col, transp, xalign, sz, pos)
    return New("TextLabel",{BackgroundTransparency=1,Text=tostring(text),Font=Enum.Font.Code,TextSize=size or 13,TextColor3=col or S.Text,TextTransparency=transp or 0,Size=sz or UDim2.new(1,0,1,0),Position=pos or UDim2.new(0,0,0,0),TextXAlignment=xalign or Enum.TextXAlignment.Left,RichText=false},parent)
end

function Lib:SafeCall(fn, ...) if type(fn)=="function" then local ok,e=pcall(fn,...); if not ok then warn("[PhantomUI] CB: "..tostring(e)) end end end
function Lib:Sig(c) table.insert(self.Signals,c); return c end

-- ── Menus flutuantes (renderizados no ScreenGui, acima de tudo) ──────────
local OpenMenus = {}
local function CloseAllMenus(except)
    for _, m in pairs(OpenMenus) do
        if m ~= except and m.Close then m:Close() end
    end
end

local function MakeFloatMenu(anchorFn, sizeFn)
    -- anchorFn() → UDim2 position no ScreenGui
    -- sizeFn()   → UDim2 size
    local Frame = New("Frame",{BackgroundColor3=S.Main,Size=UDim2.fromOffset(0,0),Visible=false,ZIndex=300,BorderSizePixel=0},GUI)
    Corner(Frame,4); Stroke(Frame,S.Outline)

    local Menu = { Frame=Frame, Open=false }
    table.insert(OpenMenus, Menu)

    function Menu:Show()
        CloseAllMenus(self)
        Frame.Position = anchorFn()
        Frame.Size     = sizeFn()
        Frame.Visible  = true
        self.Open      = true
    end
    function Menu:Close()
        Frame.Visible = false
        self.Open     = false
    end
    function Menu:Toggle()
        if self.Open then self:Close() else self:Show() end
    end
    return Menu
end

-- Fecha menus ao clicar fora
Lib:Sig(UserInputService.InputBegan:Connect(function(i)
    if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
    local mp = UserInputService:GetMouseLocation()
    for _, m in pairs(OpenMenus) do
        if m.Open and m.Frame and m.Frame.Visible then
            local ap = m.Frame.AbsolutePosition
            local as = m.Frame.AbsoluteSize
            if not (mp.X>=ap.X and mp.X<=ap.X+as.X and mp.Y>=ap.Y and mp.Y<=ap.Y+as.Y) then
                m:Close()
            end
        end
    end
end))

-- ── Tooltip ───────────────────────────────────────────────
local TTF = New("Frame",{BackgroundColor3=S.Main,AutomaticSize=Enum.AutomaticSize.XY,Visible=false,ZIndex=400,BorderSizePixel=0},GUI)
Corner(TTF,3); Stroke(TTF,S.Outline); Pad(TTF,4,4,8,8)
local TTL = New("TextLabel",{BackgroundTransparency=1,Text="",Font=Enum.Font.Code,TextSize=12,TextColor3=S.Text,TextTransparency=0.2,AutomaticSize=Enum.AutomaticSize.XY,ZIndex=401,RichText=false},TTF)

Lib:Sig(RunService.RenderStepped:Connect(function()
    if TTF.Visible then local m=UserInputService:GetMouseLocation(); TTF.Position=UDim2.fromOffset(m.X+14,m.Y+14) end
end))

local function AddTT(frame, tip)
    if not tip or tip=="" then return end
    frame.MouseEnter:Connect(function() TTL.Text=tip; TTF.Visible=true end)
    frame.MouseLeave:Connect(function() TTF.Visible=false end)
end

-- ── Notificações ─────────────────────────────────────────
local NH = New("Frame",{BackgroundTransparency=1,AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-10,1,-10),Size=UDim2.new(0,280,1,0),ZIndex=150,BorderSizePixel=0},GUI)
New("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,VerticalAlignment=Enum.VerticalAlignment.Bottom,Padding=UDim.new(0,6)},NH)

function Lib:Notify(cfg)
    cfg=cfg or {}
    local title=tostring(cfg.Title or "Aviso"); local content=tostring(cfg.Content or ""); local dur=cfg.Duration or 4
    local Card=New("Frame",{BackgroundColor3=S.Main,Size=UDim2.new(1,0,0,0),ClipsDescendants=true,BorderSizePixel=0},NH)
    Corner(Card,4); Stroke(Card,S.Accent)
    New("Frame",{BackgroundColor3=S.Accent,Size=UDim2.new(0,2,1,0),BorderSizePixel=0},Card)
    Lbl(Card,title,13,S.Accent,0,Enum.TextXAlignment.Left,UDim2.new(1,-14,0,18),UDim2.fromOffset(10,8))
    local cl=Lbl(Card,content,12,S.Text,0.2,Enum.TextXAlignment.Left,UDim2.new(1,-14,0,30),UDim2.fromOffset(10,26)); cl.TextWrapped=true
    local PB=New("Frame",{BackgroundColor3=S.Accent,Size=UDim2.new(1,-2,0,2),Position=UDim2.new(0,2,1,-2),BorderSizePixel=0},Card)
    Tw(Card,{Size=UDim2.new(1,0,0,64)})
    TweenService:Create(PB,TweenInfo.new(dur,Enum.EasingStyle.Linear),{Size=UDim2.new(0,2,0,2)}):Play()
    task.delay(dur,function() Tw(Card,{Size=UDim2.new(1,0,0,0)}); task.wait(0.15); if Card and Card.Parent then Card:Destroy() end end)
end

-- ── Drag ─────────────────────────────────────────────────
local function MakeDrag(frame, handle)
    local drag,ds,sp
    handle.InputBegan:Connect(function(i)
        if i.UserInputType~=Enum.UserInputType.MouseButton1 and i.UserInputType~=Enum.UserInputType.Touch then return end
        drag=true; ds=i.Position; sp=frame.Position
        i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then drag=false end end)
    end)
    Lib:Sig(UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-ds
            frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end))
end

-- ════════════════════════════════════════════════════════════
-- GROUPBOX BUILDER
-- ════════════════════════════════════════════════════════════
local function BuildGB(container)
    local GB = { Container=container, Elements={} }

    -- ── Toggle ────────────────────────────────────────────
    function GB:AddToggle(idx, info)
        info=info or {}
        local text=tostring(info.Text or idx); local default=info.Default==true
        local tip=info.Tooltip; local cb=info.Callback or function() end
        local Toggle={Value=default,Text=text,Type="Toggle",_ch={},Addons={},TextLabel=nil}

        local Row=New("TextButton",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,18),Text="",AutoButtonColor=false,BorderSizePixel=0},container)

        -- Checkbox
        local Box=New("Frame",{BackgroundColor3=S.Main,Size=UDim2.fromOffset(14,14),Position=UDim2.fromOffset(0,2),BorderSizePixel=0},Row)
        Corner(Box,2); local BS=Stroke(Box,S.Outline)
        local Check=New("TextLabel",{BackgroundTransparency=1,Text="✓",Font=Enum.Font.GothamBold,TextSize=11,TextColor3=S.Accent,Size=UDim2.new(1,0,1,0),Visible=default,TextXAlignment=Enum.TextXAlignment.Center,RichText=false},Box)

        -- Texto + addons à direita
        local TLbl=Lbl(Row,text,14,S.Text,default and 0 or 0.4,Enum.TextXAlignment.Left,UDim2.new(1,-22,1,0),UDim2.fromOffset(20,0))
        Toggle.TextLabel=TLbl

        local AddF=New("Frame",{BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),Size=UDim2.fromOffset(0,18),AutomaticSize=Enum.AutomaticSize.X,BorderSizePixel=0},Row)
        ListLayout(AddF,Enum.FillDirection.Horizontal,4,Enum.HorizontalAlignment.Right)

        local function Set(v,skip)
            Toggle.Value=v; Check.Visible=v
            Tw(TLbl,{TextTransparency=v and 0 or 0.4})
            Tw(BS,{Color=v and S.Accent or S.Outline})
            Lib.Toggles[idx]=Toggle
            if not skip then Lib:SafeCall(cb,v); for _,fn in pairs(Toggle._ch) do Lib:SafeCall(fn,v) end end
        end

        Row.MouseButton1Click:Connect(function() Set(not Toggle.Value) end)
        Row.MouseEnter:Connect(function()  Tw(TLbl,{TextTransparency=Toggle.Value and 0 or 0.15}) end)
        Row.MouseLeave:Connect(function()  Tw(TLbl,{TextTransparency=Toggle.Value and 0 or 0.4}) end)
        if tip then AddTT(Row,tip) end

        function Toggle:Set(v) Set(v,false) end
        function Toggle:OnChanged(fn) table.insert(self._ch,fn) end
        Lib.Toggles[idx]=Toggle

        -- ── ColorPicker Addon ────────────────────────────
        function Toggle:AddColorPicker(cpIdx, cpInfo)
            cpInfo=cpInfo or {}
            local cpDef=cpInfo.Default or Color3.new(1,1,1)
            local cpCB=cpInfo.Callback or function() end
            local CP={Value=cpDef,Type="ColorPicker",_ch={}}

            -- Botão preview (pequeno quadrado colorido)
            local Prev=New("TextButton",{BackgroundColor3=cpDef,Size=UDim2.fromOffset(18,18),Text="",AutoButtonColor=false,BorderSizePixel=1,BorderColor3=S.Dark},AddF)
            Corner(Prev,2)

            -- HSV state
            local H,Sat,V=cpDef:ToHSV()

            local function UpdateCP(skip)
                local col=Color3.fromHSV(H,Sat,V)
                CP.Value=col; Prev.BackgroundColor3=col
                Lib.Options[cpIdx]=CP
                if not skip then Lib:SafeCall(cpCB,col); for _,fn in pairs(CP._ch) do Lib:SafeCall(fn,col) end end
            end

            -- Menu flutuante com paleta HSV
            local menuW,menuH = 238,240
            local FloatMenu=MakeFloatMenu(
                function()
                    local ap=Prev.AbsolutePosition; local as=Prev.AbsoluteSize
                    local sx=ap.X+as.X+4; local sy=ap.Y
                    -- evita sair da tela
                    local vp=GUI.AbsoluteSize
                    if sx+menuW>vp.X then sx=ap.X-menuW-4 end
                    if sy+menuH>vp.Y then sy=vp.Y-menuH-4 end
                    return UDim2.fromOffset(sx,sy)
                end,
                function() return UDim2.fromOffset(menuW,menuH) end
            )
            Pad(FloatMenu.Frame,8,8,8,8)
            ListLayout(FloatMenu.Frame,nil,8)

            -- Área de cor: mapa de saturação + barra de hue
            local ColorArea=New("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,180)},FloatMenu.Frame)
            ListLayout(ColorArea,Enum.FillDirection.Horizontal,6)

            -- Mapa Sat/Val (200×180)
            local SatMap=New("TextButton",{BackgroundColor3=Color3.fromHSV(H,1,1),Size=UDim2.fromOffset(196,180),Text="",AutoButtonColor=false,BorderSizePixel=0},ColorArea)
            -- Gradiente branco→transparente horizontal
            New("Frame",{BackgroundColor3=Color3.new(1,1,1),Size=UDim2.new(1,0,1,0),BorderSizePixel=0},SatMap)
                :SetAttribute("__grad","h")
            do
                local wg=New("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))})},SatMap:FindFirstChildOfClass("Frame"))
                wg.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})
            end
            -- Gradiente preto→transparente vertical
            local darkLayer=New("Frame",{BackgroundColor3=Color3.new(0,0,0),Size=UDim2.new(1,0,1,0),BorderSizePixel=0},SatMap)
            New("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(0,0,0)),ColorSequenceKeypoint.new(1,Color3.new(0,0,0))})
                ,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}),Rotation=90},darkLayer)
            -- Cursor do sat/val
            local SatCur=New("Frame",{BackgroundColor3=Color3.new(1,1,1),AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(7,7),Position=UDim2.fromScale(Sat,1-V),BorderSizePixel=1,BorderColor3=Color3.new(0,0,0),ZIndex=5},SatMap)
            Corner(SatCur,4)

            -- Barra de Hue (18×180)
            local HueBar=New("TextButton",{Size=UDim2.fromOffset(18,180),Text="",AutoButtonColor=false,BorderSizePixel=0},ColorArea)
            local HueSeq={}; for i=0,1,0.1 do table.insert(HueSeq,ColorSequenceKeypoint.new(math.min(i,1),Color3.fromHSV(i,1,1))) end
            New("UIGradient",{Color=ColorSequence.new(HueSeq),Rotation=90},HueBar)
            local HueCur=New("Frame",{BackgroundColor3=Color3.new(1,1,1),AnchorPoint=Vector2.new(0.5,0.5),BorderColor3=Color3.new(0,0,0),BorderSizePixel=1,Position=UDim2.fromScale(0.5,H),Size=UDim2.new(1,2,0,2),ZIndex=5},HueBar)

            -- Row de inputs (Hex + RGB)
            local InfoRow=New("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,22)},FloatMenu.Frame)
            ListLayout(InfoRow,Enum.FillDirection.Horizontal,6)
            New("UIFlexItem",{FlexMode=Enum.UIFlexMode.Fill,Parent=InfoRow})

            local HexBox=New("TextBox",{BackgroundColor3=S.Bg,Size=UDim2.fromScale(1,1),Text="#"..cpDef:ToHex(),Font=Enum.Font.Code,TextSize=13,TextColor3=S.Text,ClearTextOnFocus=false,BorderSizePixel=0,RichText=false},InfoRow)
            Corner(HexBox,3); Stroke(HexBox,S.Outline); Pad(HexBox,0,0,6,0)

            local RGBBox=New("TextBox",{BackgroundColor3=S.Bg,Size=UDim2.fromScale(1,1),Text=math.floor(cpDef.R*255)..","..math.floor(cpDef.G*255)..","..math.floor(cpDef.B*255),Font=Enum.Font.Code,TextSize=13,TextColor3=S.Text,ClearTextOnFocus=false,BorderSizePixel=0,RichText=false},InfoRow)
            Corner(RGBBox,3); Stroke(RGBBox,S.Outline); Pad(RGBBox,0,0,6,0)

            local function Refresh()
                SatMap.BackgroundColor3=Color3.fromHSV(H,1,1)
                SatCur.Position=UDim2.fromScale(Sat,1-V)
                HueCur.Position=UDim2.fromScale(0.5,H)
                HexBox.Text="#"..CP.Value:ToHex()
                RGBBox.Text=math.floor(CP.Value.R*255)..","..math.floor(CP.Value.G*255)..","..math.floor(CP.Value.B*255)
            end

            -- Drag Sat/Val map
            local dragSat=false
            SatMap.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                    dragSat=true
                end
            end)
            Lib:Sig(UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragSat=false end
            end))
            Lib:Sig(RunService.RenderStepped:Connect(function()
                if not dragSat then return end
                local mx=math.clamp(Mouse.X,SatMap.AbsolutePosition.X,SatMap.AbsolutePosition.X+SatMap.AbsoluteSize.X)
                local my=math.clamp(Mouse.Y,SatMap.AbsolutePosition.Y,SatMap.AbsolutePosition.Y+SatMap.AbsoluteSize.Y)
                Sat=math.clamp((mx-SatMap.AbsolutePosition.X)/math.max(SatMap.AbsoluteSize.X,1),0,1)
                V  =1-math.clamp((my-SatMap.AbsolutePosition.Y)/math.max(SatMap.AbsoluteSize.Y,1),0,1)
                UpdateCP(false); Refresh()
            end))

            -- Drag Hue bar
            local dragHue=false
            HueBar.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragHue=true end
            end)
            Lib:Sig(UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragHue=false end
            end))
            Lib:Sig(RunService.RenderStepped:Connect(function()
                if not dragHue then return end
                local my=math.clamp(Mouse.Y,HueBar.AbsolutePosition.Y,HueBar.AbsolutePosition.Y+HueBar.AbsoluteSize.Y)
                H=math.clamp((my-HueBar.AbsolutePosition.Y)/math.max(HueBar.AbsoluteSize.Y,1),0,1)
                UpdateCP(false); Refresh()
            end))

            -- Hex input
            HexBox.FocusLost:Connect(function(enter)
                if not enter then return end
                local ok,col=pcall(Color3.fromHex,HexBox.Text:gsub("#",""))
                if ok and col then H,Sat,V=col:ToHSV(); UpdateCP(false); Refresh() end
            end)
            -- RGB input
            RGBBox.FocusLost:Connect(function(enter)
                if not enter then return end
                local r,g,b=RGBBox.Text:match("(%d+)[,%s]+(%d+)[,%s]+(%d+)")
                if r and g and b then H,Sat,V=Color3.fromRGB(tonumber(r),tonumber(g),tonumber(b)):ToHSV(); UpdateCP(false); Refresh() end
            end)

            -- Toggle popup
            Prev.MouseButton1Click:Connect(function() FloatMenu:Toggle() end)

            function CP:Set(col) H,Sat,V=col:ToHSV(); UpdateCP(false); Refresh() end
            function CP:OnChanged(fn) table.insert(self._ch,fn) end
            Lib.Options[cpIdx]=CP
            UpdateCP(true); Refresh()
            return Toggle  -- encadeamento
        end

        -- ── KeyPicker Addon ──────────────────────────────
        function Toggle:AddKeyPicker(kpIdx, kpInfo)
            kpInfo=kpInfo or {}
            local kpVal=tostring(kpInfo.Default or "None")
            local kpMode=kpInfo.Mode or "Toggle"
            local kpCB=kpInfo.Callback or function() end
            local KP={Value=kpVal,Mode=kpMode,Type="KeyPicker",Binding=false}

            local KBtn=New("TextButton",{BackgroundColor3=S.Main,Size=UDim2.fromOffset(56,16),Text="["..kpVal.."]",Font=Enum.Font.Code,TextSize=11,TextColor3=S.Text,TextTransparency=0.3,AutoButtonColor=false,BorderSizePixel=0,RichText=false},AddF)
            Corner(KBtn,3); Stroke(KBtn,S.Outline)

            -- Right-click: mode menu
            local modeMenu=MakeFloatMenu(
                function()
                    local ap=KBtn.AbsolutePosition; return UDim2.fromOffset(ap.X,ap.Y+18)
                end,
                function() return UDim2.fromOffset(80,63) end
            )
            Pad(modeMenu.Frame,2,2,0,0)
            for _,mode in ipairs({"Toggle","Hold","Always"}) do
                local mb=New("TextButton",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,20),Text=mode,Font=Enum.Font.Code,TextSize=12,TextColor3=S.Text,TextTransparency=kpMode==mode and 0 or 0.45,AutoButtonColor=false,BorderSizePixel=0,RichText=false},modeMenu.Frame)
                Pad(mb,0,0,6,0)
                mb.MouseEnter:Connect(function() Tw(mb,{TextTransparency=0}) end)
                mb.MouseLeave:Connect(function() Tw(mb,{TextTransparency=KP.Mode==mode and 0 or 0.45}) end)
                mb.MouseButton1Click:Connect(function() KP.Mode=mode; modeMenu:Close() end)
            end
            KBtn.MouseButton2Click:Connect(function() modeMenu:Toggle() end)

            -- Left-click: bind key
            local Picking=false
            KBtn.MouseButton1Click:Connect(function()
                if Picking then return end
                Picking=true; KP.Binding=true
                KBtn.Text="[...]"; Tw(KBtn,{TextColor3=S.Accent})
                local conn; conn=UserInputService.InputBegan:Connect(function(i,gp)
                    if gp then return end
                    if i.UserInputType==Enum.UserInputType.Keyboard then
                        KP.Value=i.KeyCode==Enum.KeyCode.Escape and "None" or i.KeyCode.Name
                        KP.Binding=false; Picking=false
                        KBtn.Text="["..KP.Value.."]"
                        Tw(KBtn,{TextColor3=S.Text})
                        Lib.Options[kpIdx]=KP
                        conn:Disconnect()
                    end
                end)
            end)

            -- Escuta tecla
            Lib:Sig(UserInputService.InputBegan:Connect(function(i,gp)
                if KP.Binding or gp or Picking then return end
                if UserInputService:GetFocusedTextBox() then return end
                if i.UserInputType~=Enum.UserInputType.Keyboard then return end
                if i.KeyCode.Name~=KP.Value then return end
                if KP.Mode=="Toggle" then Toggle:Set(not Toggle.Value); Lib:SafeCall(kpCB,Toggle.Value)
                elseif KP.Mode=="Hold" then Toggle:Set(true); Lib:SafeCall(kpCB,true)
                elseif KP.Mode=="Always" then Lib:SafeCall(kpCB,true) end
            end))
            Lib:Sig(UserInputService.InputEnded:Connect(function(i)
                if KP.Mode=="Hold" and i.UserInputType==Enum.UserInputType.Keyboard and i.KeyCode.Name==KP.Value then
                    Toggle:Set(false); Lib:SafeCall(kpCB,false)
                end
            end))

            Lib.Options[kpIdx]=KP
            return Toggle  -- encadeamento
        end

        Set(default,true)
        table.insert(GB.Elements,{Text=text,Type="Toggle",Holder=Row,Visible=true})
        return Toggle
    end

    -- ── Button ────────────────────────────────────────────
    function GB:AddButton(info)
        info=info or {}
        local text=tostring(info.Text or "Button"); local func=info.Func or info.Callback or function() end
        local risky=info.Risky; local tip=info.Tooltip; local disabled=info.Disabled

        local Row=New("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,20),BorderSizePixel=0},container)
        ListLayout(Row,Enum.FillDirection.Horizontal,6)
        New("UIFlexItem",{FlexMode=Enum.UIFlexMode.Fill},Row)

        local Btn=New("TextButton",{BackgroundColor3=S.Main,Size=UDim2.fromScale(1,1),Text=text,Font=Enum.Font.Code,TextSize=14,TextColor3=risky and S.Red or S.Text,TextTransparency=0.4,AutoButtonColor=false,Active=not disabled,BorderSizePixel=0,RichText=false},Row)
        Corner(Btn,3); Stroke(Btn,S.Outline)
        Btn.MouseEnter:Connect(function() if not disabled then Tw(Btn,{TextTransparency=0}) end end)
        Btn.MouseLeave:Connect(function() Tw(Btn,{TextTransparency=disabled and 0.7 or 0.4}) end)
        Btn.MouseButton1Click:Connect(function() if not disabled then Lib:SafeCall(func) end end)
        if tip then AddTT(Btn,tip) end

        local BObj={_row=Row,Type="Button",Text=text}
        function BObj:AddButton(si)
            si=si or {}
            local sb=New("TextButton",{BackgroundColor3=S.Main,Size=UDim2.fromScale(1,1),Text=tostring(si.Text or ""),Font=Enum.Font.Code,TextSize=14,TextColor3=S.Text,TextTransparency=0.4,AutoButtonColor=false,BorderSizePixel=0,RichText=false},Row)
            Corner(sb,3); Stroke(sb,S.Outline)
            sb.MouseEnter:Connect(function() Tw(sb,{TextTransparency=0}) end)
            sb.MouseLeave:Connect(function() Tw(sb,{TextTransparency=0.4}) end)
            sb.MouseButton1Click:Connect(function() Lib:SafeCall(si.Func or si.Callback or function() end) end)
            return BObj
        end
        table.insert(GB.Elements,{Text=text,Type="Button",Holder=Row,Visible=true})
        return BObj
    end

    -- ── Slider ────────────────────────────────────────────
    function GB:AddSlider(idx, info)
        info=info or {}
        local text=tostring(info.Text or idx); local min=tonumber(info.Min) or 0; local max=tonumber(info.Max) or 100
        local default=math.clamp(tonumber(info.Default) or min,min,max); local suffix=tostring(info.Suffix or "")
        local round=tonumber(info.Rounding) or 0; local tip=info.Tooltip; local cb=info.Callback or function() end
        local SL={Value=default,Type="Slider",_ch={}}

        local Wrap=New("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,36),BorderSizePixel=0},container)
        Lbl(Wrap,text,13,S.Text,0.2,Enum.TextXAlignment.Left,UDim2.new(0.65,0,0,16))
        local VL=New("TextLabel",{BackgroundTransparency=1,Text=tostring(default)..suffix,Font=Enum.Font.Code,TextSize=12,TextColor3=S.Accent,Size=UDim2.new(0.35,-4,0,16),Position=UDim2.new(0.65,4,0,0),TextXAlignment=Enum.TextXAlignment.Right,RichText=false},Wrap)

        local Track=New("Frame",{BackgroundColor3=S.Outline,Size=UDim2.new(1,0,0,4),Position=UDim2.fromOffset(0,22),BorderSizePixel=0},Wrap)
        Corner(Track,2)
        local ratio=max~=min and (default-min)/(max-min) or 0
        local Fill=New("Frame",{BackgroundColor3=S.Accent,Size=UDim2.new(ratio,0,1,0),BorderSizePixel=0},Track); Corner(Fill,2)
        local Thumb=New("Frame",{BackgroundColor3=Color3.new(1,1,1),AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(8,8),Position=UDim2.new(1,0,0.5,0),BorderSizePixel=0},Fill); Corner(Thumb,4)
        local HB=New("TextButton",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,0,0.5,-10),Text="",ZIndex=5,BorderSizePixel=0},Track)

        local function Rd(v)
            if round==0 then return math.floor(v+0.5) end
            local m=10^round; return math.floor(v*m+0.5)/m
        end
        local function Update(v,skip)
            v=math.clamp(v,min,max); SL.Value=Rd(v)
            local r=max~=min and (v-min)/(max-min) or 0
            Tw(Fill,{Size=UDim2.new(r,0,1,0)}); VL.Text=tostring(SL.Value)..suffix
            Lib.Options[idx]=SL
            if not skip then Lib:SafeCall(cb,SL.Value); for _,fn in pairs(SL._ch) do Lib:SafeCall(fn,SL.Value) end end
        end

        local drag=false
        HB.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true end end)
        Lib:Sig(UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end end))
        Lib:Sig(UserInputService.InputChanged:Connect(function(i)
            if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
                local rel=math.clamp((i.Position.X-Track.AbsolutePosition.X)/math.max(Track.AbsoluteSize.X,1),0,1)
                Update(min+(max-min)*rel)
            end
        end))
        if tip then AddTT(Wrap,tip) end
        function SL:Set(v) Update(v,false) end; function SL:OnChanged(fn) table.insert(self._ch,fn) end
        Lib.Options[idx]=SL; Update(default,true)
        table.insert(GB.Elements,{Text=text,Type="Slider",Holder=Wrap,Visible=true})
        return SL
    end

    -- ── Dropdown ─────────────────────────────────────────
    function GB:AddDropdown(idx, info)
        info=info or {}
        local text=tostring(info.Text or idx); local vals=info.Values or {}
        local multi=info.Multi; local tip=info.Tooltip; local cb=info.Callback or function() end
        local disabled=info.Disabled

        local default
        if multi then default={}
        elseif type(info.Default)=="number" then default=vals[info.Default]
        else default=info.Default or vals[1] end

        local Drop={Value=multi and {} or default,Values=vals,Multi=multi,Type="Dropdown",_ch={}}

        local Wrap=New("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,38),BorderSizePixel=0},container)
        Lbl(Wrap,text,13,S.Text,0.2,Enum.TextXAlignment.Left,UDim2.new(1,0,0,15))

        local Head=New("TextButton",{BackgroundColor3=S.Main,Size=UDim2.new(1,0,0,22),Position=UDim2.fromOffset(0,16),Text="",AutoButtonColor=false,Active=not disabled,BorderSizePixel=0,ZIndex=2},Wrap)
        Corner(Head,3); Stroke(Head,S.Outline)

        local function DispText()
            if multi then
                local ks={}; for k,v in pairs(Drop.Value) do if v then table.insert(ks,tostring(k)) end end
                return #ks==0 and "---" or table.concat(ks,", ")
            end
            return tostring(Drop.Value or "---")
        end

        local HL=New("TextLabel",{BackgroundTransparency=1,Text=DispText(),Font=Enum.Font.Code,TextSize=13,TextColor3=S.Text,TextTransparency=disabled and 0.6 or 0.25,Size=UDim2.new(1,-22,1,0),Position=UDim2.fromOffset(7,0),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3,RichText=false},Head)
        local Arr=New("TextLabel",{BackgroundTransparency=1,Text="v",Font=Enum.Font.Code,TextSize=11,TextColor3=S.Text,TextTransparency=0.4,Size=UDim2.fromOffset(14,22),Position=UDim2.new(1,-16,0,0),ZIndex=3,RichText=false},Head)

        -- Menu flutuante (renderizado no ScreenGui acima de tudo)
        local menuW,HO=0,20
        local FloatDrop=MakeFloatMenu(
            function()
                local ap=Head.AbsolutePosition; local as=Head.AbsoluteSize
                local sy=ap.Y+as.Y+2
                local totalH=math.min(#vals,8)*HO+4
                if sy+totalH>GUI.AbsoluteSize.Y then sy=ap.Y-totalH-2 end
                return UDim2.fromOffset(ap.X,sy)
            end,
            function()
                menuW=Head.AbsoluteSize.X
                return UDim2.fromOffset(menuW,math.min(#vals,8)*HO+4)
            end
        )
        local MenuSF=New("ScrollingFrame",{BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),ScrollBarThickness=3,ScrollBarImageColor3=S.Outline,BorderSizePixel=0,CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},FloatDrop.Frame)
        ListLayout(MenuSF,nil,0)
        Pad(MenuSF,2,2,0,0)

        local function SetVal(v,skip)
            Drop.Value=v; HL.Text=DispText()
            Lib.Options[idx]=Drop
            if not skip then Lib:SafeCall(cb,v); for _,fn in pairs(Drop._ch) do Lib:SafeCall(fn,v) end end
        end

        local OptBtns={}
        local function BuildOpts(vlist)
            for _,c in pairs(MenuSF:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
            OptBtns={}
            for _,opt in ipairs(vlist) do
                local sel=multi and Drop.Value[opt]==true or Drop.Value==opt
                local OB=New("TextButton",{BackgroundColor3=sel and S.Outline or S.Main,Size=UDim2.new(1,0,0,HO),Text="",AutoButtonColor=false,BorderSizePixel=0},MenuSF)
                Pad(OB,0,0,8,8)
                local OL=Lbl(OB,tostring(opt),13,S.Text,sel and 0 or 0.4,Enum.TextXAlignment.Left)
                -- checkmark
                local CK=New("TextLabel",{BackgroundTransparency=1,Text=sel and "✓" or "",Font=Enum.Font.Code,TextSize=12,TextColor3=S.Accent,Size=UDim2.fromOffset(16,HO),Position=UDim2.new(1,-18,0,0),TextXAlignment=Enum.TextXAlignment.Right,RichText=false},OB)
                OB.MouseEnter:Connect(function() Tw(OB,{BackgroundColor3=S.Outline}) end)
                OB.MouseLeave:Connect(function() Tw(OB,{BackgroundColor3=sel and S.Outline or S.Main}) end)
                OB.MouseButton1Click:Connect(function()
                    if multi then
                        Drop.Value[opt]=not Drop.Value[opt]
                        sel=Drop.Value[opt]; CK.Text=sel and "✓" or ""; Tw(OL,{TextTransparency=sel and 0 or 0.4}); Tw(OB,{BackgroundColor3=sel and S.Outline or S.Main})
                        SetVal(Drop.Value)
                    else
                        SetVal(opt); FloatDrop:Close(); Arr.Text="v"; BuildOpts(Drop.Values)
                    end
                end)
                table.insert(OptBtns,{btn=OB,ck=CK,lbl=OL,opt=opt,sel=sel})
            end
        end
        BuildOpts(vals)

        Head.MouseButton1Click:Connect(function()
            if disabled then return end
            if FloatDrop.Open then FloatDrop:Close(); Arr.Text="v"
            else BuildOpts(Drop.Values); FloatDrop:Show(); Arr.Text="^" end
        end)

        -- update arrow on close
        local orig=FloatDrop.Close
        function FloatDrop:Close() orig(self); Arr.Text="v" end

        if tip then AddTT(Head,tip) end
        function Drop:Set(v) SetVal(v,false); BuildOpts(self.Values) end
        function Drop:SetValues(v) Drop.Values=v; BuildOpts(v) end
        function Drop:OnChanged(fn) table.insert(self._ch,fn) end
        Lib.Options[idx]=Drop; SetVal(default,true)
        table.insert(GB.Elements,{Text=text,Type="Dropdown",Holder=Wrap,Visible=true})
        return Drop
    end

    -- ── Input ─────────────────────────────────────────────
    function GB:AddInput(idx, info)
        info=info or {}
        local text=tostring(info.Text or idx); local holder=tostring(info.Placeholder or "")
        local numeric=info.Numeric; local tip=info.Tooltip; local cb=info.Callback or function() end; local finished=info.Finished
        local IN={Value=tostring(info.Default or ""),Type="Input",_ch={}}

        local Wrap=New("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,36),BorderSizePixel=0},container)
        Lbl(Wrap,text,13,S.Text,0.2,Enum.TextXAlignment.Left,UDim2.new(1,0,0,15))
        local IBG=New("Frame",{BackgroundColor3=S.Main,Size=UDim2.new(1,0,0,20),Position=UDim2.fromOffset(0,16),BorderSizePixel=0},Wrap)
        Corner(IBG,3); local IS=Stroke(IBG,S.Outline); Pad(IBG,0,0,6,6)
        local Box=New("TextBox",{BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),Text=IN.Value,PlaceholderText=holder,PlaceholderColor3=Color3.fromRGB(70,70,70),Font=Enum.Font.Code,TextSize=13,TextColor3=S.Text,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,RichText=false},IBG)
        Box.Focused:Connect(function() Tw(IS,{Color=S.Accent}) end)
        Box.FocusLost:Connect(function(enter)
            Tw(IS,{Color=S.Outline}); local v=Box.Text
            if numeric then v=tonumber(v) or IN.Value end; IN.Value=v; Lib.Options[idx]=IN
            if not finished or enter then Lib:SafeCall(cb,v); for _,fn in pairs(IN._ch) do Lib:SafeCall(fn,v) end end
        end)
        if not finished then Box:GetPropertyChangedSignal("Text"):Connect(function() IN.Value=Box.Text; Lib:SafeCall(cb,Box.Text) end) end
        if tip then AddTT(IBG,tip) end
        function IN:Set(v) Box.Text=tostring(v); IN.Value=v end; function IN:Get() return IN.Value end; function IN:OnChanged(fn) table.insert(self._ch,fn) end
        Lib.Options[idx]=IN
        table.insert(GB.Elements,{Text=text,Type="Input",Holder=Wrap,Visible=true})
        return IN
    end

    -- ── Label ─────────────────────────────────────────────
    function GB:AddLabel(text, wrap)
        local LB=New("TextLabel",{BackgroundTransparency=1,Text=tostring(text),Font=Enum.Font.Code,TextSize=13,TextColor3=S.Text,TextTransparency=0.4,Size=UDim2.new(1,0,0,wrap and 0 or 16),AutomaticSize=wrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=wrap or false,RichText=false},container)
        local LO={Type="Label",Holder=LB,Text=tostring(text),Visible=true}
        function LO:SetText(t) LB.Text=tostring(t); self.Text=tostring(t) end
        table.insert(GB.Elements,LO); return LO
    end

    -- ── Divider ───────────────────────────────────────────
    function GB:AddDivider()
        local D=New("Frame",{BackgroundColor3=S.Outline,Size=UDim2.new(1,0,0,1),BorderSizePixel=0},container)
        table.insert(GB.Elements,{Type="Divider",Holder=D,Visible=true}); return GB
    end

    return GB
end

-- ════════════════════════════════════════════════════════════
-- CREATE WINDOW
-- ════════════════════════════════════════════════════════════
function Lib:CreateWindow(cfg)
    cfg=cfg or {}
    local title=tostring(cfg.Title or "Phantom Hub"); local footer=tostring(cfg.Footer or "v1.0")
    local keybind=cfg.Keybind or Enum.KeyCode.RightControl

    -- Frame principal
    local MF=New("Frame",{BackgroundColor3=S.Bg,Size=UDim2.fromOffset(740,540),Position=UDim2.fromScale(0.5,0.5),AnchorPoint=Vector2.new(0.5,0.5),BorderSizePixel=0,ClipsDescendants=false},GUI)
    Corner(MF,5); Stroke(MF,S.Outline); Lib.MainFrame=MF

    -- Topbar
    local TB=New("Frame",{BackgroundColor3=S.Main,Size=UDim2.new(1,0,0,36),BorderSizePixel=0},MF)
    New("Frame",{BackgroundColor3=S.Outline,Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BorderSizePixel=0},TB)
    MakeDrag(MF,TB)
    Lbl(TB,title,14,S.Text,0,Enum.TextXAlignment.Left,UDim2.new(0.5,0,1,0),UDim2.fromOffset(10,0))
    Lbl(TB,footer,12,S.Text,0.55,Enum.TextXAlignment.Right,UDim2.new(0.5,-10,1,0),UDim2.new(0.5,0,0,0))

    -- Search bar
    local SBar=New("Frame",{BackgroundColor3=S.Main,Size=UDim2.new(1,0,0,28),Position=UDim2.fromOffset(0,36),BorderSizePixel=0},MF)
    New("Frame",{BackgroundColor3=S.Outline,Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BorderSizePixel=0},SBar)
    local SBox=New("TextBox",{BackgroundTransparency=1,PlaceholderText="Pesquisar...",PlaceholderColor3=Color3.fromRGB(80,80,80),Text="",Font=Enum.Font.Code,TextSize=13,TextColor3=S.Text,Size=UDim2.new(1,-16,1,0),Position=UDim2.fromOffset(8,0),TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,RichText=false},SBar)

    -- Sidebar
    local SBW=128
    local SB=New("Frame",{BackgroundColor3=S.Main,Size=UDim2.new(0,SBW,1,-64),Position=UDim2.fromOffset(0,64),BorderSizePixel=0},MF)
    New("Frame",{BackgroundColor3=S.Outline,Size=UDim2.new(0,1,1,0),Position=UDim2.new(1,-1,0,0),BorderSizePixel=0},SB)
    local SBL=New("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BorderSizePixel=0},SB)
    ListLayout(SBL)

    -- Content
    local CA=New("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(SBW,64),Size=UDim2.new(1,-SBW,1,-64),ClipsDescendants=true,BorderSizePixel=0},MF)

    -- Keybind toggle
    Lib:Sig(UserInputService.InputBegan:Connect(function(i,gp)
        if gp or Lib.Unloaded then return end
        if UserInputService:GetFocusedTextBox() then return end
        if i.KeyCode==keybind then Lib.Toggled=not Lib.Toggled; MF.Visible=Lib.Toggled end
    end))

    -- Mobile button
    if UserInputService.TouchEnabled then
        local MB=New("TextButton",{BackgroundColor3=S.Accent,Size=UDim2.fromOffset(46,46),Position=UDim2.new(0,10,0.5,0),Text="☰",Font=Enum.Font.Code,TextSize=20,TextColor3=S.Text,AutoButtonColor=false,BorderSizePixel=0,ZIndex=100},GUI)
        Corner(MB,8)
        MB.MouseButton1Click:Connect(function() Lib.Toggled=not Lib.Toggled; MF.Visible=Lib.Toggled end)
    end

    -- ── Window API ────────────────────────────────────────
    local Win={}
    local ActPg=nil; local ActBtn=nil

    function Win:AddTab(name)
        name=tostring(name)

        -- Tab declaration BEFORE SelectTab
        local Tab={Groupboxes={}}

        local TBtn=New("TextButton",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,28),Text="",AutoButtonColor=false,BorderSizePixel=0},SBL)
        local Ind=New("Frame",{BackgroundColor3=S.Accent,Size=UDim2.new(0,2,0.6,0),Position=UDim2.new(0,0,0.2,0),BorderSizePixel=0,Visible=false},TBtn)
        Corner(Ind,1)
        local TL=Lbl(TBtn,name,13,S.Text,0.55,Enum.TextXAlignment.Left,UDim2.new(1,-12,1,0),UDim2.fromOffset(10,0))

        local Page=New("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),Visible=false,BorderSizePixel=0},CA)

        local function MakeCol(xS,xO,wS,wO)
            local c=New("ScrollingFrame",{BackgroundTransparency=1,Position=UDim2.new(xS,xO,0,6),Size=UDim2.new(wS,wO,1,-12),ScrollBarThickness=2,ScrollBarImageColor3=S.Outline,CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,BorderSizePixel=0},Page)
            ListLayout(c,nil,6); return c
        end
        local LC=MakeCol(0,6,0.5,-9); local RC=MakeCol(0.5,3,0.5,-9)

        local function SelTab()
            if ActPg then ActPg.Visible=false end
            if ActBtn then
                ActBtn.i.Visible=false; Tw(ActBtn.l,{TextTransparency=0.55}); Tw(ActBtn.b,{BackgroundTransparency=1})
            end
            Page.Visible=true; ActPg=Page; Ind.Visible=true
            Tw(TL,{TextTransparency=0}); Tw(TBtn,{BackgroundTransparency=0.9})
            ActBtn={b=TBtn,l=TL,i=Ind}; Lib.ActiveTab=Tab
        end

        TBtn.MouseButton1Click:Connect(SelTab)
        TBtn.MouseEnter:Connect(function() if Page~=ActPg then Tw(TBtn,{BackgroundTransparency=0.95}) end end)
        TBtn.MouseLeave:Connect(function() if Page~=ActPg then Tw(TBtn,{BackgroundTransparency=1}) end end)
        if not ActPg then SelTab() end

        local function MakeGB(col, gbName)
            gbName=tostring(gbName)
            local GBH=New("Frame",{BackgroundColor3=S.Bg,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BorderSizePixel=0},col)
            Corner(GBH,4); Stroke(GBH,S.Outline)
            local GT=Lbl(GBH,gbName,14,S.Text,0,Enum.TextXAlignment.Left,UDim2.new(1,0,0,32)); Pad(GT,0,0,12,0)
            New("Frame",{BackgroundColor3=S.Outline,Size=UDim2.new(1,0,0,1),Position=UDim2.fromOffset(0,32),BorderSizePixel=0},GBH)
            local GBC=New("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(0,33),Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BorderSizePixel=0},GBH)
            ListLayout(GBC,nil,6); Pad(GBC,6,8,8,8)
            local GB=BuildGB(GBC); GB.Holder=GBH; Tab.Groupboxes[gbName]=GB; return GB
        end

        function Tab:AddLeftGroupbox(n)  return MakeGB(LC,n) end
        function Tab:AddRightGroupbox(n) return MakeGB(RC,n) end

        table.insert(Lib.Tabs,Tab)
        return Tab
    end

    -- Search
    SBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q=SBox.Text:lower():match("^%s*(.-)%s*$")
        if not Lib.ActiveTab then return end
        for _,gb in pairs(Lib.ActiveTab.Groupboxes) do
            if q=="" then
                gb.Holder.Visible=true
                for _,el in ipairs(gb.Elements) do if el.Holder and el.Holder.Parent then el.Holder.Visible=el.Visible end end
            else
                local n=0
                for _,el in ipairs(gb.Elements) do
                    if el.Holder and el.Holder.Parent then
                        if el.Type~="Divider" and el.Text and el.Text:lower():find(q,1,true) and el.Visible then
                            el.Holder.Visible=true; n+=1
                        elseif el.Type~="Divider" then el.Holder.Visible=false end
                    end
                end
                gb.Holder.Visible=n>0
            end
        end
    end)

    Lib.Toggled=true; MF.Visible=true
    return Win
end

-- ── Unload ────────────────────────────────────────────────
function Lib:Unload()
    Lib.Unloaded=true
    for _,c in ipairs(Lib.Signals) do if c and c.Connected then c:Disconnect() end end
    if GUI and GUI.Parent then GUI:Destroy() end
end

getgenv().PhantomLib=Lib
return Lib
