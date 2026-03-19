# NEXUS UI LIBRARY — Documentação Completa V1.0

UI Library para Scripts de Roblox | Dark Modern | Sidebar Tabs | 11 Componentes

---

## ÍNDICE

1. Introdução
2. Instalação
3. Criando a Janela (CreateWindow)
4. Tabs e Sections
5. Componentes
6. Sistema de Temas
7. Notificações
8. Save / Load Config
9. Flags & Options
10. Exemplo Completo
11. Boas Práticas

---

## 1. INTRODUÇÃO

A NexusUI é uma UI Library / Framework para Roblox, criada para facilitar a construção de menus complexos, organizados e escaláveis. Ela cuida completamente da interface — estados, animações, temas e persistência — deixando toda a lógica do jogo na responsabilidade do seu script.

### Para quem é

- Scripts de ESP, Aimbot e Hitbox Expander
- Painéis de Admin e ferramentas de desenvolvedor
- Scripts avançados que precisam de interface organizada
- Qualquer script que precise de configurações salváveis

### Recursos Principais

| Recurso           | Descrição                                                          |
|-------------------|--------------------------------------------------------------------|
| Sidebar de Tabs   | Abas laterais com indicador animado e ícone opcional               |
| Sections          | Grupos visuais dentro de cada tab                                  |
| 11 Componentes    | Button, Toggle, Slider, Dropdown, MultiDropdown, ColorPicker, TextBox, Label, Paragraph, Keybind, Separator |
| Sistema de Temas  | Troca de tema em tempo real com animação suave                     |
| Notificações      | 4 tipos: Success, Error, Warning, Info com barra de progresso      |
| Save / Load       | Salva e carrega configurações em JSON automaticamente              |
| Drag & Drop       | Janela arrastável pela topbar                                      |
| Tooltips          | Texto ao passar o mouse sobre qualquer elemento                    |
| Minimize / Fechar | Botões animados com keybind global para toggle                     |
| Mobile Support    | Botão flutuante automático para dispositivos touch                 |

---

## 2. INSTALAÇÃO

A library é carregada remotamente via HttpGet. Use sempre o link RAW do GitHub.

```lua
-- Carregamento remoto (recomendado)
local Lib = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Mano-Gustavo/Nexuslib/refs/heads/main/NexusLib.lua"
))()

-- Carregamento local (para teste)
local Lib = loadstring(readfile("NexusLib.lua"))()
```

> IMPORTANTE: A library retorna uma tabela. Se `Lib` for nil, o carregamento falhou.
> Sempre use o link RAW do GitHub (raw.githubusercontent.com), não o link normal da página.

---

## 3. CRIANDO A JANELA (CreateWindow)

A janela é o container raiz de toda a interface. Deve ser criada antes de qualquer Tab ou componente.

```lua
local Window = Lib:CreateWindow({
    Title   = "Meu Hub",             -- Título exibido na topbar
    Keybind = Enum.KeyCode.RightControl  -- Tecla para mostrar/ocultar
})
```

### Parâmetros

| Parâmetro | Tipo          | Padrão         | Descrição                        |
|-----------|---------------|----------------|----------------------------------|
| Title     | string        | "Nexus Hub"    | Título da barra superior         |
| Keybind   | Enum.KeyCode  | RightControl   | Tecla para togglear a janela     |

### O que a janela oferece

- Sistema de abas na sidebar esquerda
- Botão minimizar (colapsa para a topbar)
- Botão fechar (oculta com animação)
- Drag & Drop pela topbar
- Toggle por keybind global
- Botão mobile automático para dispositivos touch

---

## 4. TABS E SECTIONS

### 4.1 Criando Tabs

Tabs são as abas da sidebar. Cada tab é independente e exibe seu próprio conteúdo.

```lua
local TabMain    = Window:CreateTab("Main")
local TabVisuals = Window:CreateTab("Visuals")
local TabConfig  = Window:CreateTab("Config")

-- Com ícone (ID de asset do Roblox)
local TabESP = Window:CreateTab("ESP", "rbxassetid://XXXXXXX")
```

> A primeira Tab criada é selecionada automaticamente.

### 4.2 Criando Sections

Sections são blocos visuais dentro de uma Tab, usadas para agrupar elementos relacionados.

```lua
local SecCombate  = TabMain:CreateSection("Combate")
local SecVisual   = TabMain:CreateSection("Visual")
local SecMovement = TabMain:CreateSection("Movimento")
```

### 4.3 Hierarquia da UI

```
Lib
└── Window  (CreateWindow)
    └── Tab  (Window:CreateTab)
        ├── Section  (Tab:CreateSection)
        │   └── Componente  (Sec:CreateButton, Sec:CreateToggle, etc.)
        └── Componente direto  (Tab:CreateButton, Tab:CreateToggle, etc.)
```

> Elementos podem ser criados diretamente na Tab sem Section. Sections são recomendadas para organização.

---

## 5. COMPONENTES

Todos os componentes retornam um objeto com métodos de controle.
Podem ser criados tanto em uma Section (`Sec:Create...`) quanto diretamente numa Tab (`Tab:Create...`).

---

### 5.1 Button

Executa uma ação quando clicado. Ideal para teleporte, reset, execuções manuais.

```lua
local Btn = Sec:CreateButton(
    "Reset Character",    -- Nome do botão
    function()            -- Callback
        print("Clicou!")
    end,
    "Reseta o personagem" -- Tooltip (opcional)
)

-- Métodos disponíveis:
Btn:SetTooltip("Novo tooltip")
```

---

### 5.2 Toggle

Liga ou desliga uma feature. Salva o estado automaticamente nas Flags.

```lua
local Toggle = Sec:CreateToggle(
    "Auto Farm",        -- Nome (vira a Flag)
    function(Value)     -- Callback (recebe true/false)
        print(Value)
    end,
    false,              -- Estado padrão
    "Liga o Auto Farm"  -- Tooltip (opcional)
)

-- Hooks para separar a lógica:
Toggle:OnEnable(function()
    -- Inicia loop, ativa ESP, etc.
end)

Toggle:OnDisable(function()
    -- Para loop, desativa ESP, etc.
end)

-- Controle programático:
Toggle:Set(true)   -- Liga sem disparar callback
Toggle:Reset()     -- Volta para false
```

---

### 5.3 Slider

Valor numérico arrastável. Salva o valor nas Flags.

```lua
local Slider = Sec:CreateSlider(
    "FOV Radius",              -- Nome
    50,                        -- Mínimo
    500,                       -- Máximo
    100,                       -- Padrão
    function(Value)            -- Callback
        print(Value)
    end,
    "Define o tamanho do FOV"  -- Tooltip (opcional)
)

-- Controle programático:
Slider:Set(200)   -- Define valor
Slider:Reset()    -- Volta para o padrão (100)
```

---

### 5.4 Dropdown

Lista de opções, apenas uma seleção por vez.

```lua
local Drop = Sec:CreateDropdown(
    "Weapon",
    {"Gun", "Knife", "Sword"},   -- Opções
    function(Selected)
        print(Selected)
    end,
    "Gun",                       -- Padrão (opcional)
    "Selecione a arma"           -- Tooltip (opcional)
)

-- Controle programático:
Drop:Set("Knife")                    -- Seleciona opção
Drop:Refresh({"A", "B"}, true)       -- Atualiza lista (true = limpa atual)
Drop:Reset()                         -- Volta para a primeira opção
```

---

### 5.5 MultiDropdown

Dropdown com seleção múltipla. Retorna uma tabela com os itens selecionados.

```lua
local Multi = Sec:CreateMultiDropdown(
    "Targets",
    {"Players", "NPCs", "Bosses"},
    function(Selected)   -- recebe tabela
        for _, v in pairs(Selected) do
            print(v)
        end
    end,
    "Selecione os alvos" -- Tooltip (opcional)
)

-- Pegar os selecionados:
local lista = Multi:Get()
```

---

### 5.6 ColorPicker

Seletor de cor RGB. Expansível ao clicar. Retorna Color3.

```lua
local Picker = Sec:CreateColorPicker(
    "ESP Color",
    Color3.fromRGB(255, 0, 0),   -- Cor padrão
    function(Color)              -- Recebe Color3
        print(Color)
    end,
    "Cor do ESP"                 -- Tooltip (opcional)
)

-- Controle programático:
-- Recebe tabela com R, G, B normalizados (0 a 1)
Picker:Set({R = 1, G = 0, B = 0})
```

---

### 5.7 TextBox

Caixa de entrada de texto. O callback dispara ao perder o foco (Enter ou clicar fora).

```lua
local Box = Sec:CreateTextBox(
    "Player Name",        -- Label
    "Digite o nome...",   -- Placeholder
    function(Text)
        print(Text)
    end,
    "Nome do alvo"        -- Tooltip (opcional)
)

-- Controle programático:
Box:Set("Jogador123")   -- Define texto
Box:Get()               -- Retorna texto atual
```

---

### 5.8 Label

Texto informativo, sem interação. Útil para status e informações dinâmicas.

```lua
local Lbl = Sec:CreateLabel("Status: Idle")

-- Atualiza o texto:
Lbl:Set("Status: Running")
```

---

### 5.9 Paragraph

Bloco de texto com título e conteúdo. Suporta texto longo com quebra de linha.

```lua
local Para = Sec:CreateParagraph(
    "Sobre este Script",
    "Este é um script de ESP avançado com suporte a todos os modos de jogo."
)

-- Atualiza conteúdo:
Para:Set("Novo Título", "Novo conteúdo aqui...")
```

---

### 5.10 Keybind

Captura uma tecla do usuário. Clique no botão e pressione qualquer tecla para definir.

```lua
local KB = Sec:CreateKeybind(
    "Teleport",             -- Nome
    Enum.KeyCode.T,         -- Padrão
    function(Key)           -- Dispara ao pressionar a tecla
        print("Tecla:", Key.Name)
    end,
    "Tecla de teleporte"    -- Tooltip (opcional)
)

-- Controle programático:
KB:Set(Enum.KeyCode.G)
```

> Enquanto o usuário está definindo uma tecla, a UI exibe "..." em amarelo.
> Pressione qualquer tecla para confirmar a escolha.

---

### 5.11 Separator

Linha visual horizontal para separar grupos de elementos.

```lua
Sec:CreateSeparator()   -- Não retorna objeto
```

---

### 5.12 Resumo dos Componentes

| Componente      | Método                  | Principais Métodos do Objeto                          |
|-----------------|-------------------------|-------------------------------------------------------|
| Button          | CreateButton()          | SetTooltip()                                          |
| Toggle          | CreateToggle()          | Set(), Reset(), OnEnable(), OnDisable(), SetTooltip() |
| Slider          | CreateSlider()          | Set(), Reset(), SetTooltip()                          |
| Dropdown        | CreateDropdown()        | Set(), Reset(), Refresh(), SetTooltip()               |
| MultiDropdown   | CreateMultiDropdown()   | Get(), SetTooltip()                                   |
| ColorPicker     | CreateColorPicker()     | Set(), SetTooltip()                                   |
| TextBox         | CreateTextBox()         | Set(), Get(), SetTooltip()                            |
| Label           | CreateLabel()           | Set()                                                 |
| Paragraph       | CreateParagraph()       | Set()                                                 |
| Keybind         | CreateKeybind()         | Set(), SetTooltip()                                   |
| Separator       | CreateSeparator()       | —                                                     |

---

## 6. SISTEMA DE TEMAS

O tema é aplicado em tempo real. Todos os elementos visuais registrados fazem a transição com animação de 0.25 segundos.

```lua
Lib:SetTheme({
    Background   = Color3.fromRGB(18, 18, 22),    -- Fundo principal
    Sidebar      = Color3.fromRGB(14, 14, 18),    -- Fundo da sidebar
    Surface      = Color3.fromRGB(26, 26, 34),    -- Cards e elementos
    SurfaceHover = Color3.fromRGB(34, 34, 44),    -- Hover dos elementos
    Header       = Color3.fromRGB(20, 20, 26),    -- Topbar
    Accent       = Color3.fromRGB(99, 102, 241),  -- Cor de destaque
    Text         = Color3.fromRGB(232, 232, 245), -- Texto principal
    TextMuted    = Color3.fromRGB(130, 130, 155), -- Texto secundário
    Border       = Color3.fromRGB(42, 42, 58),    -- Bordas
})
```

### Temas prontos para copiar

**Dark Red (ESP / Aimbot)**
```lua
Lib:SetTheme({
    Accent     = Color3.fromRGB(239, 68, 68),
    Background = Color3.fromRGB(18, 10, 10),
    Surface    = Color3.fromRGB(30, 18, 18),
})
```

**Dark Green (Farm / Economia)**
```lua
Lib:SetTheme({
    Accent     = Color3.fromRGB(52, 211, 153),
    Background = Color3.fromRGB(10, 18, 14),
    Surface    = Color3.fromRGB(16, 28, 22),
})
```

**Dark Blue (Admin / Utilitários)**
```lua
Lib:SetTheme({
    Accent     = Color3.fromRGB(59, 130, 246),
    Background = Color3.fromRGB(10, 14, 20),
    Surface    = Color3.fromRGB(16, 22, 32),
})
```

---

## 7. NOTIFICAÇÕES

Notificações aparecem no canto inferior direito com animação e barra de progresso. Somem automaticamente após a duração definida.

```lua
Lib:Notify({
    Title    = "Auto Farm",
    Text     = "Farm iniciado no Boss Kilo!",
    Duration = 5,           -- Segundos
    Type     = "Success"    -- Success | Error | Warning | Info
})
```

### Tipos de notificação

| Tipo    | Cor      | Quando usar                                             |
|---------|----------|---------------------------------------------------------|
| Success | Verde    | Operação completada: config salva, item obtido          |
| Error   | Vermelho | Falha: player não encontrado, erro de teleporte         |
| Warning | Amarelo  | Aviso: feature experimental, servidor lotado            |
| Info    | Indigo   | Informação geral: versão carregada, status do script    |

---

## 8. SAVE / LOAD CONFIG

A library salva os valores de Toggles, Sliders, Dropdowns e ColorPickers em arquivos JSON.
Os arquivos ficam em `NexusUI/Configs/*.json` na pasta do executor.

```lua
-- Salva configuração atual
Lib:SaveConfig("Legit")       -- Cria NexusUI/Configs/Legit.json

-- Carrega configuração salva
Lib:LoadConfig("Legit")       -- Restaura todos os valores salvos

-- Reseta para os valores padrão
Lib:ResetConfig()
```

> IMPORTANTE: A library salva os valores, mas NÃO re-executa a lógica do jogo.
> Após LoadConfig(), use os callbacks ou OnEnable/OnDisable para reaplicar efeitos visuais.

> ATENÇÃO: writefile e readfile são funções de executor. Em executores que não suportam
> escrita de arquivos, SaveConfig e LoadConfig não funcionam.

---

## 9. FLAGS & OPTIONS

### 9.1 Flags

Flags ficam em `Lib.Flags` e armazenam o valor atual de cada componente.
A chave é o nome do componente (primeiro parâmetro).

```lua
print(Lib.Flags["Auto Farm"])    -- true ou false
print(Lib.Flags["FOV Radius"])   -- 100 (número)
print(Lib.Flags["Weapon"])       -- "Gun" (string)
```

### 9.2 Options

Options ficam em `Lib.Options` e guardam o objeto do componente, permitindo controle de qualquer lugar do script.

```lua
-- Controlando componentes de fora:
Lib.Options["Auto Farm"]:Set(false)
Lib.Options["FOV Radius"]:Set(200)
Lib.Options["Weapon"]:Set("Knife")

-- Verificando se o componente existe antes de usar:
if Lib.Options["Meu Toggle"] then
    Lib.Options["Meu Toggle"]:Set(true)
end
```

> Use nomes únicos para cada componente. A chave em Flags e Options é sempre o nome do componente.

---

## 10. EXEMPLO COMPLETO — ESP SCRIPT

```lua
local Lib = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Mano-Gustavo/Nexuslib/refs/heads/main/NexusLib.lua"
))()

local Players = game:GetService("Players")

-- Variáveis de estado
local espEnabled = false
local fovSize    = 150
local espColor   = Color3.fromRGB(255, 0, 0)

-- Janela principal
local Win = Lib:CreateWindow({
    Title   = "ESP Hub",
    Keybind = Enum.KeyCode.RightControl
})

-- ─── TAB ESP ──────────────────────────────────────────

local TabESP = Win:CreateTab("ESP")

local SecMain  = TabESP:CreateSection("Configurações ESP")
local SecColor = TabESP:CreateSection("Cores")
local SecKeys  = TabESP:CreateSection("Keybinds")

-- Toggle principal com hooks
local TglESP = SecMain:CreateToggle(
    "ESP Ativado",
    function(v) espEnabled = v end,
    false,
    "Liga/desliga o ESP"
)

TglESP:OnEnable(function()
    Lib:Notify({ Title = "ESP", Text = "ESP ativado!", Type = "Success", Duration = 3 })
    -- Inicia lógica do ESP aqui
end)

TglESP:OnDisable(function()
    Lib:Notify({ Title = "ESP", Text = "ESP desativado.", Type = "Warning", Duration = 3 })
    -- Para lógica do ESP aqui
end)

-- Slider de FOV
SecMain:CreateSlider("FOV Size", 50, 500, 150, function(v)
    fovSize = v
    -- Atualiza círculo de FOV na tela
end, "Raio do FOV Circle")

-- Dropdown de time
SecMain:CreateDropdown("Time", {"Todos", "Inimigos", "Aliados"}, function(v)
    print("Time selecionado:", v)
end, "Todos", "Quais jogadores mostrar")

-- Multi-select de features
SecMain:CreateMultiDropdown("Mostrar", {"Nome", "Vida", "Distância", "Caixa"}, function(selected)
    for _, feature in pairs(selected) do
        print("Feature ativa:", feature)
    end
end, "Informações a exibir")

-- Color Picker
SecColor:CreateColorPicker("Cor ESP", Color3.fromRGB(255, 0, 0), function(c)
    espColor = c
    -- Atualiza cor do ESP
end, "Cor dos highlights")

-- Label de status
local LblStatus = SecMain:CreateLabel("Status: Idle")

-- Atualiza label baseado no toggle
TglESP:OnEnable(function()  LblStatus:Set("Status: ESP Ativo") end)
TglESP:OnDisable(function() LblStatus:Set("Status: Idle") end)

-- Keybind
SecKeys:CreateKeybind("Toggle ESP", Enum.KeyCode.H, function()
    -- Alterna ESP pela tecla
    local current = Lib.Flags["ESP Ativado"]
    Lib.Options["ESP Ativado"]:Set(not current)
end, "Tecla rápida para toggle")

-- ─── TAB CONFIG ───────────────────────────────────────

local TabCfg = Win:CreateTab("Config")
local SecCfg = TabCfg:CreateSection("Configurações")

SecCfg:CreateButton("Salvar Config", function()
    Lib:SaveConfig("ESP_Config")
    Lib:Notify({ Title = "Salvo!", Text = "Configuração salva com sucesso.", Type = "Success", Duration = 3 })
end, "Salva todas as configurações")

SecCfg:CreateButton("Carregar Config", function()
    Lib:LoadConfig("ESP_Config")
    Lib:Notify({ Title = "Carregado!", Text = "Config restaurada.", Type = "Info", Duration = 3 })
end, "Carrega configuração salva")

SecCfg:CreateButton("Resetar Config", function()
    Lib:ResetConfig()
    Lib:Notify({ Title = "Reset!", Text = "Configurações resetadas.", Type = "Warning", Duration = 3 })
end)

SecCfg:CreateSeparator()

SecCfg:CreateParagraph(
    "Sobre",
    "ESP Hub V1.0 — Feito com NexusUI Library. Tecla padrão: RightControl para abrir/fechar."
)

-- ─── TAB SOBRE ────────────────────────────────────────

local TabAbout = Win:CreateTab("Sobre")
local SecAbout = TabAbout:CreateSection("Informações")

SecAbout:CreateLabel("Versão: 1.0")
SecAbout:CreateLabel("Library: NexusUI V1.0")
SecAbout:CreateLabel("Executor: Universal")

-- ─── NOTIFICAÇÃO INICIAL ──────────────────────────────

Lib:Notify({
    Title    = "ESP Hub",
    Text     = "Script carregado! Pressione RightControl para abrir.",
    Type     = "Success",
    Duration = 5
})
```

---

## 11. BOAS PRÁTICAS

### 11.1 Nomes

- Use nomes únicos para cada componente — são usados como chaves nas Flags e Options
- Prefira nomes descritivos: "ESP Players" em vez de "Toggle1"
- Não use o mesmo nome em Tabs diferentes se usar Save/Load

### 11.2 Separe lógica de interface

A library cuida da UI. Seu script cuida da lógica.

```lua
-- ERRADO: loop dentro do callback
Sec:CreateToggle("Farm", function(v)
    while v do task.wait(0.1) end  -- NUNCA faça isso, vai travar
end)

-- CORRETO: lógica separada em funções
local farmActive = false

local function StartFarm()
    farmActive = true
    task.spawn(function()
        while farmActive do
            -- lógica aqui
            task.wait(0.1)
        end
    end)
end

local function StopFarm()
    farmActive = false
end

local T = Sec:CreateToggle("Farm", function() end)
T:OnEnable(StartFarm)
T:OnDisable(StopFarm)
```

### 11.3 Config

- Sempre ofereça botões de Salvar e Carregar na tab de Config
- Use Lib:Notify() para confirmar quando a config é salva ou carregada
- Após LoadConfig(), reaplicar efeitos visuais manualmente se necessário

### 11.4 Performance

- Evite criar muitos componentes dinâmicos — prefira ocultar/mostrar Sections
- Use task.spawn() para loops dentro de hooks
- Desconecte conexões de RenderStepped quando não forem mais necessárias

### 11.5 Organização recomendada

```
Tab "Main"
    Section "Combat"     → Toggles principais (ESP, Aimbot...)
    Section "Visual"     → ColorPickers, sliders visuais
    Section "Movement"   → Speed, Fly, NoClip...

Tab "Config"
    Section "Configs"    → Botões Save, Load, Reset
    Section "About"      → Versão, créditos

Tab "Settings"
    Section "Theme"      → ColorPicker para accent, botões de tema
    Section "Keybinds"   → Todos os keybinds do script
```

---

## REFERÊNCIA RÁPIDA

```lua
-- CARREGAR
local Lib = loadstring(game:HttpGet("URL_AQUI"))()

-- JANELA
local Win = Lib:CreateWindow({ Title = "Hub", Keybind = Enum.KeyCode.RightControl })

-- TAB E SECTION
local Tab = Win:CreateTab("Nome")
local Sec = Tab:CreateSection("Nome")

-- COMPONENTES
Sec:CreateButton("Nome", callback, tooltip)
Sec:CreateToggle("Nome", callback, default, tooltip)
Sec:CreateSlider("Nome", min, max, default, callback, tooltip)
Sec:CreateDropdown("Nome", {opcoes}, callback, default, tooltip)
Sec:CreateMultiDropdown("Nome", {opcoes}, callback, tooltip)
Sec:CreateColorPicker("Nome", Color3.fromRGB(...), callback, tooltip)
Sec:CreateTextBox("Nome", "placeholder", callback, tooltip)
Sec:CreateLabel("Texto")
Sec:CreateParagraph("Titulo", "Conteudo")
Sec:CreateKeybind("Nome", Enum.KeyCode.T, callback, tooltip)
Sec:CreateSeparator()

-- TEMA
Lib:SetTheme({ Accent = Color3.fromRGB(99, 102, 241) })

-- NOTIFICAÇÕES
Lib:Notify({ Title = "Titulo", Text = "Texto", Type = "Success", Duration = 4 })

-- CONFIG
Lib:SaveConfig("nome")
Lib:LoadConfig("nome")
Lib:ResetConfig()

-- CONTROLE EXTERNO
Lib.Flags["Nome do Componente"]        -- valor atual
Lib.Options["Nome do Componente"]:Set(valor)  -- define valor
```

---

◈ NEXUS UI LIBRARY V1.0
Isso não é só UI. É base de projeto.
