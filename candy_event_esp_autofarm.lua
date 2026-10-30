-- Candy Farm + Player ESP UI (Prism)
-- Insert abre/fecha | Arraste o cabeçalho para mover | E alterna o farm | F8 encerra

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local running = true
local uiVisible = true
local currentPage = "Candy"
local uiX, uiY = 150, 110
local uiWidth, uiHeight = 710, 505
local sidebarWidth = 210
local dragging = false
local dragOffset = Vector2.new(0, 0)

-- Candy: lógica preservada.
local farmEnabled = false
local candyEspEnabled = true
local candyKey = Enum.KeyCode.E
local awaitingCandyKey = false
local candies = {}
local candyDrawings = {}
local ignoredCandies = {}
local ignoreDuration = 4

-- Player ESP.
local playerEspEnabled = false
local showUsername = true
local showDisplayName = true
local showTorso = true
local showBoxes = false
local playerFeatures = {}
local playerNameLabels = {}

-- Fly.
local flyEnabled = false
local flySpeed = 80
local flyKey = Enum.KeyCode.G
local awaitingFlyKey = false
local draggingSpeed = false

local COLORS = {
    background = Color3.fromRGB(7, 7, 10),
    surface = Color3.fromRGB(14, 14, 19),
    sidebar = Color3.fromRGB(11, 11, 16),
    row = Color3.fromRGB(18, 18, 25),
    rowActive = Color3.fromRGB(38, 17, 51),
    purple = Color3.fromRGB(187, 0, 240),
    purpleLight = Color3.fromRGB(218, 85, 255),
    text = Color3.fromRGB(242, 239, 247),
    muted = Color3.fromRGB(151, 145, 162),
    green = Color3.fromRGB(102, 255, 166),
    red = Color3.fromRGB(255, 104, 130),
}

local function addSquare(position, size, color, transparency, rounding)
    local item = Drawing.new("Square")
    item.Position = position
    item.Size = size
    item.Color = color
    item.Transparency = transparency or 1
    item.Filled = true
    item.Rounding = rounding or 0
    item.Visible = true
    return item
end

local function addText(position, size, text, color)
    local item = Drawing.new("Text")
    item.Position = position
    item.Size = size
    item.Text = text
    item.Font = Drawing.Fonts.Plex
    item.Color = color or COLORS.text
    item.Outline = true
    item.OutlineColor = Color3.new(0, 0, 0)
    item.Visible = true
    return item
end

local ui = {
    shadow = addSquare(Vector2.new(0, 0), Vector2.new(uiWidth + 12, uiHeight + 12), Color3.new(0, 0, 0), 0.38, 12),
    panel = addSquare(Vector2.new(0, 0), Vector2.new(uiWidth, uiHeight), COLORS.background, 0.98, 10),
    sidebar = addSquare(Vector2.new(0, 0), Vector2.new(sidebarWidth, uiHeight), COLORS.sidebar, 1, 10),
    header = addSquare(Vector2.new(0, 0), Vector2.new(uiWidth - sidebarWidth, 56), COLORS.surface, 1, 0),
    topAccent = addSquare(Vector2.new(0, 0), Vector2.new(uiWidth, 2), COLORS.purple, 1, 10),
    sideAccent = addSquare(Vector2.new(0, 0), Vector2.new(3, uiHeight), COLORS.purple, 1, 0),
    logo = addSquare(Vector2.new(0, 0), Vector2.new(36, 36), COLORS.purple, 1, 8),
    logoGlow = addSquare(Vector2.new(0, 0), Vector2.new(42, 42), Color3.fromRGB(80, 9, 100), 0.45, 10),
    mainTab = addSquare(Vector2.new(0, 0), Vector2.new(174, 38), COLORS.rowActive, 1, 7),
    espTab = addSquare(Vector2.new(0, 0), Vector2.new(174, 38), COLORS.sidebar, 1, 7),
    flyTab = addSquare(Vector2.new(0, 0), Vector2.new(174, 38), COLORS.sidebar, 1, 7),
    divider = addSquare(Vector2.new(0, 0), Vector2.new(160, 1), Color3.fromRGB(52, 48, 60), 1, 0),
    sectionLine = addSquare(Vector2.new(0, 0), Vector2.new(4, 17), COLORS.purple, 1, 2),
    closeBack = addSquare(Vector2.new(0, 0), Vector2.new(38, 34), COLORS.row, 1, 7),
    rowBack1 = addSquare(Vector2.new(0, 0), Vector2.new(466, 44), COLORS.row, 1, 7),
    rowBack2 = addSquare(Vector2.new(0, 0), Vector2.new(466, 44), COLORS.row, 1, 7),
    rowBack3 = addSquare(Vector2.new(0, 0), Vector2.new(466, 44), COLORS.row, 1, 7),
    rowBack4 = addSquare(Vector2.new(0, 0), Vector2.new(466, 44), COLORS.row, 1, 7),
    rowBack5 = addSquare(Vector2.new(0, 0), Vector2.new(466, 44), COLORS.row, 1, 7),
    track1 = addSquare(Vector2.new(0, 0), Vector2.new(58, 24), Color3.fromRGB(65, 61, 74), 1, 12),
    track2 = addSquare(Vector2.new(0, 0), Vector2.new(58, 24), Color3.fromRGB(65, 61, 74), 1, 12),
    track3 = addSquare(Vector2.new(0, 0), Vector2.new(58, 24), Color3.fromRGB(65, 61, 74), 1, 12),
    track4 = addSquare(Vector2.new(0, 0), Vector2.new(58, 24), Color3.fromRGB(65, 61, 74), 1, 12),
    track5 = addSquare(Vector2.new(0, 0), Vector2.new(58, 24), Color3.fromRGB(65, 61, 74), 1, 12),
    knob1 = addSquare(Vector2.new(0, 0), Vector2.new(18, 18), COLORS.text, 1, 9),
    knob2 = addSquare(Vector2.new(0, 0), Vector2.new(18, 18), COLORS.text, 1, 9),
    knob3 = addSquare(Vector2.new(0, 0), Vector2.new(18, 18), COLORS.text, 1, 9),
    knob4 = addSquare(Vector2.new(0, 0), Vector2.new(18, 18), COLORS.text, 1, 9),
    knob5 = addSquare(Vector2.new(0, 0), Vector2.new(18, 18), COLORS.text, 1, 9),
    sliderBack = addSquare(Vector2.new(0, 0), Vector2.new(230, 4), Color3.fromRGB(58, 54, 66), 1, 2),
    sliderFill = addSquare(Vector2.new(0, 0), Vector2.new(1, 4), COLORS.purple, 1, 2),
    sliderKnob = addSquare(Vector2.new(0, 0), Vector2.new(12, 12), COLORS.purpleLight, 1, 6),
    keyButton = addSquare(Vector2.new(0, 0), Vector2.new(148, 28), Color3.fromRGB(35, 20, 45), 1, 6),

    logoLetter = addText(Vector2.new(0, 0), 20, "E", Color3.fromRGB(255, 255, 255)),
    brand = addText(Vector2.new(0, 0), 17, "Prism Candy", COLORS.text),
    subtitle = addText(Vector2.new(0, 0), 10, "EVENT AUTOMATION", COLORS.muted),
    mainNav = addText(Vector2.new(0, 0), 15, "◈  Candy", COLORS.text),
    espNav = addText(Vector2.new(0, 0), 15, "◉  Player ESP", COLORS.text),
    flyNav = addText(Vector2.new(0, 0), 15, "✦  Fly", COLORS.text),
    keyValue = addText(Vector2.new(0, 0), 13, "", COLORS.purpleLight),
    speedValue = addText(Vector2.new(0, 0), 13, "", COLORS.purpleLight),
    footer = addText(Vector2.new(0, 0), 11, "INSERT  •  abrir/fechar", COLORS.muted),
    title = addText(Vector2.new(0, 0), 18, "Candy", COLORS.text),
    version = addText(Vector2.new(0, 0), 10, "PRISM UI  •  1.1", COLORS.muted),
    close = addText(Vector2.new(0, 0), 19, "×", COLORS.muted),
    section = addText(Vector2.new(0, 0), 12, "CONTROLES", COLORS.purpleLight),
    info = addText(Vector2.new(0, 0), 12, "", COLORS.muted),
    row1 = addText(Vector2.new(0, 0), 15, "", COLORS.text),
    row2 = addText(Vector2.new(0, 0), 15, "", COLORS.text),
    row3 = addText(Vector2.new(0, 0), 15, "", COLORS.text),
    row4 = addText(Vector2.new(0, 0), 15, "", COLORS.text),
    row5 = addText(Vector2.new(0, 0), 15, "", COLORS.text),
}

local function setVisible(item, value)
    item.Visible = value
end

local function applyLayout()
    local x, y = uiX, uiY
    local contentX = x + 235
    local rowX = contentX
    local toggleX = x + 620

    ui.shadow.Position = Vector2.new(x - 6, y - 6)
    ui.panel.Position = Vector2.new(x, y)
    ui.sidebar.Position = Vector2.new(x, y)
    ui.header.Position = Vector2.new(x + sidebarWidth, y)
    ui.topAccent.Position = Vector2.new(x, y)
    ui.sideAccent.Position = Vector2.new(x + sidebarWidth, y)
    ui.logoGlow.Position = Vector2.new(x + 35, y + 24)
    ui.logo.Position = Vector2.new(x + 38, y + 27)
    ui.logoLetter.Position = Vector2.new(x + 49, y + 33)
    ui.brand.Position = Vector2.new(x + 89, y + 29)
    ui.subtitle.Position = Vector2.new(x + 89, y + 51)
    ui.mainTab.Position = Vector2.new(x + 18, y + 118)
    ui.espTab.Position = Vector2.new(x + 18, y + 164)
    ui.flyTab.Position = Vector2.new(x + 18, y + 210)
    ui.mainNav.Position = Vector2.new(x + 33, y + 129)
    ui.espNav.Position = Vector2.new(x + 33, y + 175)
    ui.flyNav.Position = Vector2.new(x + 33, y + 221)
    ui.keyButton.Position = Vector2.new(contentX + 282, y + 176)
    ui.keyValue.Position = Vector2.new(contentX + 296, y + 183)
    ui.speedValue.Position = Vector2.new(contentX + 385, y + 235)
    ui.sliderBack.Position = Vector2.new(contentX + 208, y + 252)
    ui.divider.Position = Vector2.new(x + 30, y + uiHeight - 43)
    ui.footer.Position = Vector2.new(x + 30, y + uiHeight - 30)

    ui.title.Position = Vector2.new(contentX, y + 19)
    ui.version.Position = Vector2.new(x + uiWidth - 155, y + 22)
    ui.closeBack.Position = Vector2.new(x + uiWidth - 46, y + 11)
    ui.close.Position = Vector2.new(x + uiWidth - 34, y + 15)
    ui.sectionLine.Position = Vector2.new(contentX, y + 84)
    ui.section.Position = Vector2.new(contentX + 12, y + 84)

    ui.rowBack1.Position = Vector2.new(rowX, y + 114)
    ui.rowBack2.Position = Vector2.new(rowX, y + 168)
    ui.rowBack3.Position = Vector2.new(rowX, y + 222)
    ui.rowBack4.Position = Vector2.new(rowX, y + 276)
    ui.rowBack5.Position = Vector2.new(rowX, y + 330)
    ui.row1.Position = Vector2.new(contentX + 16, y + 127)
    ui.row2.Position = Vector2.new(contentX + 16, y + 181)
    ui.row3.Position = Vector2.new(contentX + 16, y + 235)
    ui.row4.Position = Vector2.new(contentX + 16, y + 289)
    ui.row5.Position = Vector2.new(contentX + 16, y + 343)
    ui.info.Position = Vector2.new(contentX, y + 414)

    ui.track1.Position = Vector2.new(toggleX, y + 124)
    ui.track2.Position = Vector2.new(toggleX, y + 178)
    ui.track3.Position = Vector2.new(toggleX, y + 232)
    ui.track4.Position = Vector2.new(toggleX, y + 286)
    ui.track5.Position = Vector2.new(toggleX, y + 340)
end

local function updateToggle(track, knob, enabled, visible)
    setVisible(track, visible)
    setVisible(knob, visible)

    if enabled then
        track.Color = COLORS.purple
        knob.Position = Vector2.new(track.Position.X + 36, track.Position.Y + 3)
    else
        track.Color = Color3.fromRGB(65, 61, 74)
        knob.Position = Vector2.new(track.Position.X + 4, track.Position.Y + 3)
    end
end

local function setFeatureEnabled(feature, enabled)
    if feature then
        pcall(function()
            feature:SetEnabled(enabled)
        end)
    end
end

local function updatePlayerEsp()
    for _, features in ipairs(playerFeatures) do
        setFeatureEnabled(features.torso, playerEspEnabled and showTorso)
        setFeatureEnabled(features.box, playerEspEnabled and showBoxes)
    end
end

local espList = entities.new({
    MaxDistance = 5000,
    HideDead = true,
    RefreshInterval = 1,
    Filter = function(entity)
        return entity.Player ~= player
    end,
})

local playerBinding = espList:BindPlayers(Players, function(entity, sourcePlayer)
    if sourcePlayer == player then
        return
    end

    local features = {
        torso = entity:AddSkeleton({
            Color = COLORS.purpleLight,
            Transparency = 1,
            Thickness = 1.5,
            Border = true,
        }),
        box = entity:AddBox({
            Style = "Corner",
            Color = COLORS.purpleLight,
            Transparency = 1,
            Thickness = 1.5,
            Border = true,
        }),
    }

    local displayLabel = addText(Vector2.new(0, 0), 14, "", Color3.fromRGB(235, 215, 255))
    displayLabel.Center = true
    displayLabel.Visible = false

    local usernameLabel = addText(Vector2.new(0, 0), 12, "", COLORS.purpleLight)
    usernameLabel.Center = true
    usernameLabel.Visible = false

    table.insert(playerFeatures, features)
    table.insert(playerNameLabels, {
        player = sourcePlayer,
        display = displayLabel,
        username = usernameLabel,
    })

    setFeatureEnabled(features.torso, playerEspEnabled and showTorso)
    setFeatureEnabled(features.box, playerEspEnabled and showBoxes)
end)

local function updatePlayerNameLabels(camera)
    for _, entry in ipairs(playerNameLabels) do
        local displayVisible = false
        local usernameVisible = false

        pcall(function()
            local character = entry.player.Character
            local anchor = character and (
                character:FindFirstChild("Head")
                or character:FindFirstChild("HumanoidRootPart")
            )

            if anchor and playerEspEnabled then
                local screen, onScreen = camera:WorldToViewportPoint(anchor.Position)

                if onScreen then
                    local displayName = entry.player.DisplayName or entry.player.Name

                    if showDisplayName then
                        entry.display.Position = Vector2.new(screen.X, screen.Y - 34)
                        entry.display.Text = displayName
                        displayVisible = true
                    end

                    if showUsername then
                        entry.username.Position = Vector2.new(
                            screen.X,
                            screen.Y - (showDisplayName and 18 or 34)
                        )
                        entry.username.Text = "@" .. entry.player.Name
                        usernameVisible = true
                    end
                end
            end
        end)

        entry.display.Visible = displayVisible
        entry.username.Visible = usernameVisible
    end
end

local function clearCandyDrawings()
    for _, item in ipairs(candyDrawings) do
        item:Remove()
    end
    candyDrawings = {}
end

local function refreshCandies()
    clearCandyDrawings()
    candies = {}

    local folder = Workspace:FindFirstChild("Candies")
    if not folder then
        return
    end

    for _, child in ipairs(folder:GetChildren()) do
        if child.Name == "Candy" and child:IsA("BasePart") then
            local label = addText(Vector2.new(0, 0), 14, "", Color3.fromRGB(255, 168, 38))
            label.Center = true
            label.Visible = false
            table.insert(candies, { part = child, label = label })
            table.insert(candyDrawings, label)
        end
    end
end

local function getRoot()
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function isIgnored(part)
    local untilTime = ignoredCandies[part]
    if not untilTime then
        return false
    end

    if os.clock() >= untilTime then
        ignoredCandies[part] = nil
        return false
    end

    return true
end

local function ignoreCandy(part)
    ignoredCandies[part] = os.clock() + ignoreDuration
end

local function nearestCandy(root)
    local closest
    local shortest = math.huge

    for _, item in ipairs(candies) do
        local ok, distance = pcall(function()
            return (item.part.Position - root.Position).Magnitude
        end)

        if ok and not isIgnored(item.part) and distance < shortest then
            shortest = distance
            closest = item.part
        end
    end

    return closest
end

local function setFlyEnabled(enabled)
    flyEnabled = enabled
    pcall(function()
        player:Fly(flyEnabled, flySpeed)
    end)
end

local function setFlySpeedFromMouse(mouseX)
    local sliderStart = uiX + 235 + 208
    local sliderWidth = 230
    local alpha = (mouseX - sliderStart) / sliderWidth
    alpha = math.max(0, math.min(1, alpha))
    flySpeed = math.floor(20 + alpha * 230)

    if flyEnabled then
        pcall(function()
            player:Fly(true, flySpeed)
        end)
    end
end

local function updateUi()
    applyLayout()

    for _, item in pairs(ui) do
        setVisible(item, uiVisible)
    end

    if not uiVisible then
        return
    end

    ui.mainTab.Color = currentPage == "Candy" and COLORS.rowActive or COLORS.sidebar
    ui.espTab.Color = currentPage == "ESP" and COLORS.rowActive or COLORS.sidebar
    ui.flyTab.Color = currentPage == "Fly" and COLORS.rowActive or COLORS.sidebar
    ui.mainNav.Color = currentPage == "Candy" and COLORS.purpleLight or COLORS.muted
    ui.espNav.Color = currentPage == "ESP" and COLORS.purpleLight or COLORS.muted
    ui.flyNav.Color = currentPage == "Fly" and COLORS.purpleLight or COLORS.muted

    if currentPage == "Candy" then
        ui.title.Text = "Candy"
        ui.section.Text = "CANDY EVENT"
        ui.row1.Text = "Autofarm Candy"
        ui.row2.Text = "Candy ESP"
        ui.row3.Text = "Tecla do autofarm"
        ui.row4.Text = ""
        ui.row5.Text = ""
        ui.info.Text = "Clique na tecla para escolher o atalho do autofarm"
        setVisible(ui.rowBack3, true)
        setVisible(ui.rowBack4, false)
        setVisible(ui.rowBack5, false)
        updateToggle(ui.track1, ui.knob1, farmEnabled, true)
        updateToggle(ui.track2, ui.knob2, candyEspEnabled, true)
        updateToggle(ui.track3, ui.knob3, false, false)
        updateToggle(ui.track4, ui.knob4, false, false)
        updateToggle(ui.track5, ui.knob5, false, false)
        ui.keyButton.Position = Vector2.new(uiX + 235 + 282, uiY + 230)
        ui.keyValue.Position = Vector2.new(uiX + 235 + 296, uiY + 237)
        ui.keyValue.Text = awaitingCandyKey and "PRESSIONE UMA TECLA..." or candyKey.Name
        setVisible(ui.keyButton, true)
        setVisible(ui.keyValue, true)
        setVisible(ui.speedValue, false)
        setVisible(ui.sliderBack, false)
        setVisible(ui.sliderFill, false)
        setVisible(ui.sliderKnob, false)
    elseif currentPage == "ESP" then
        ui.title.Text = "Player ESP"
        ui.section.Text = "VISUALIZAÇÃO DE JOGADORES"
        ui.row1.Text = "Ativar Player ESP"
        ui.row2.Text = "@ Usuário"
        ui.row3.Text = "Nome de exibição"
        ui.row4.Text = "Torso / esqueleto"
        ui.row5.Text = "Caixa de canto"
        ui.info.Text = "Opções visuais para jogadores carregados no cliente"
        setVisible(ui.rowBack3, true)
        setVisible(ui.rowBack4, true)
        setVisible(ui.rowBack5, true)
        updateToggle(ui.track1, ui.knob1, playerEspEnabled, true)
        updateToggle(ui.track2, ui.knob2, showUsername, true)
        updateToggle(ui.track3, ui.knob3, showDisplayName, true)
        updateToggle(ui.track4, ui.knob4, showTorso, true)
        updateToggle(ui.track5, ui.knob5, showBoxes, true)
        setVisible(ui.keyButton, false)
        setVisible(ui.keyValue, false)
        setVisible(ui.speedValue, false)
        setVisible(ui.sliderBack, false)
        setVisible(ui.sliderFill, false)
        setVisible(ui.sliderKnob, false)
    else
        ui.title.Text = "Fly"
        ui.section.Text = "MOVIMENTO AÉREO"
        ui.row1.Text = "Ativar Fly"
        ui.row2.Text = "Tecla de ativação"
        ui.row3.Text = "Velocidade"
        ui.row4.Text = ""
        ui.row5.Text = ""
        ui.info.Text = "Clique na tecla e pressione a tecla desejada"
        setVisible(ui.rowBack3, true)
        setVisible(ui.rowBack4, false)
        setVisible(ui.rowBack5, false)
        updateToggle(ui.track1, ui.knob1, flyEnabled, true)
        updateToggle(ui.track2, ui.knob2, false, false)
        updateToggle(ui.track3, ui.knob3, false, false)
        updateToggle(ui.track4, ui.knob4, false, false)
        updateToggle(ui.track5, ui.knob5, false, false)

        ui.keyButton.Position = Vector2.new(uiX + 235 + 282, uiY + 176)
        ui.keyValue.Position = Vector2.new(uiX + 235 + 296, uiY + 183)
        ui.keyValue.Text = awaitingFlyKey and "PRESSIONE UMA TECLA..." or flyKey.Name
        ui.speedValue.Text = tostring(flySpeed)
        setVisible(ui.keyButton, true)
        setVisible(ui.keyValue, true)
        setVisible(ui.speedValue, true)
        setVisible(ui.sliderBack, true)
        setVisible(ui.sliderFill, true)
        setVisible(ui.sliderKnob, true)

        local sliderStart = ui.sliderBack.Position.X
        local sliderWidth = ui.sliderBack.Size.X
        local alpha = (flySpeed - 20) / 230
        local fillWidth = math.max(1, math.floor(sliderWidth * alpha))
        ui.sliderFill.Position = Vector2.new(sliderStart, ui.sliderBack.Position.Y)
        ui.sliderFill.Size = Vector2.new(fillWidth, 4)
        ui.sliderKnob.Position = Vector2.new(
            sliderStart + fillWidth - 6,
            ui.sliderBack.Position.Y - 4
        )
    end
end

RunService:BindToRenderStep("CandyUiAndEsp", 201, function()
    local root = getRoot()
    local camera = Workspace.CurrentCamera

    for _, item in ipairs(candies) do
        local visible = false

        local ok = pcall(function()
            local screen, onScreen = camera:WorldToViewportPoint(item.part.Position)
            if candyEspEnabled and onScreen then
                local distance = root and math.floor((item.part.Position - root.Position).Magnitude) or 0
                item.label.Position = Vector2.new(screen.X, screen.Y)
                item.label.Text = "CANDY [" .. distance .. "]"
                visible = true
            end
        end)

        item.label.Visible = ok and visible
    end

    updatePlayerNameLabels(camera)
    updateUi()
end)

local function isInside(pos, x, y, width, height)
    return pos.X >= x and pos.X <= x + width and pos.Y >= y and pos.Y <= y + height
end

UserInputService.InputBegan:Connect(function(inputObject)
    if inputObject.KeyCode == Enum.KeyCode.Insert then
        uiVisible = not uiVisible
        return
    end

    if inputObject.KeyCode == Enum.KeyCode.F8 then
        running = false
        return
    end

    if awaitingFlyKey or awaitingCandyKey then
        if inputObject.UserInputType == Enum.UserInputType.Keyboard then
            if awaitingFlyKey then
                flyKey = inputObject.KeyCode
                awaitingFlyKey = false
            else
                candyKey = inputObject.KeyCode
                awaitingCandyKey = false
            end
        end
        return
    end

    if inputObject.KeyCode == flyKey then
        setFlyEnabled(not flyEnabled)
        return
    end

    if inputObject.KeyCode == candyKey then
        farmEnabled = not farmEnabled
        return
    end

    if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 or not uiVisible then
        return
    end

    local pos = inputObject.Position

    if isInside(pos, uiX + uiWidth - 46, uiY + 11, 38, 34) then
        uiVisible = false
    elseif isInside(pos, uiX + sidebarWidth, uiY, uiWidth - sidebarWidth - 54, 56) then
        dragging = true
        dragOffset = Vector2.new(pos.X - uiX, pos.Y - uiY)
    elseif isInside(pos, uiX + 18, uiY + 118, 174, 38) then
        currentPage = "Candy"
    elseif isInside(pos, uiX + 18, uiY + 164, 174, 38) then
        currentPage = "ESP"
    elseif isInside(pos, uiX + 18, uiY + 210, 174, 38) then
        currentPage = "Fly"
    elseif isInside(pos, uiX + 605, uiY + 114, 78, 44) then
        if currentPage == "Candy" then
            farmEnabled = not farmEnabled
        elseif currentPage == "ESP" then
            playerEspEnabled = not playerEspEnabled
            updatePlayerEsp()
        else
            setFlyEnabled(not flyEnabled)
        end
    elseif isInside(pos, uiX + 605, uiY + 168, 78, 44) then
        if currentPage == "Candy" then
            candyEspEnabled = not candyEspEnabled
        elseif currentPage == "ESP" then
            showUsername = not showUsername
        else
            awaitingFlyKey = true
        end
    elseif currentPage == "Candy" and isInside(pos, uiX + 235 + 270, uiY + 222, 180, 44) then
        awaitingCandyKey = true
    elseif currentPage == "Fly" and isInside(pos, uiX + 235 + 270, uiY + 168, 180, 44) then
        awaitingFlyKey = true
    elseif currentPage == "Fly" and isInside(pos, uiX + 235 + 190, uiY + 222, 260, 44) then
        draggingSpeed = true
        setFlySpeedFromMouse(pos.X)
    elseif currentPage == "ESP" and isInside(pos, uiX + 605, uiY + 222, 78, 44) then
        showDisplayName = not showDisplayName
    elseif currentPage == "ESP" and isInside(pos, uiX + 605, uiY + 276, 78, 44) then
        showTorso = not showTorso
        updatePlayerEsp()
    elseif currentPage == "ESP" and isInside(pos, uiX + 605, uiY + 330, 78, 44) then
        showBoxes = not showBoxes
        updatePlayerEsp()
    end
end)

UserInputService.InputChanged:Connect(function(inputObject)
    if inputObject.UserInputType ~= Enum.UserInputType.MouseMovement then
        return
    end

    if draggingSpeed then
        setFlySpeedFromMouse(inputObject.Position.X)
    elseif dragging then
        uiX = math.max(10, inputObject.Position.X - dragOffset.X)
        uiY = math.max(10, inputObject.Position.Y - dragOffset.Y)
    end
end)

UserInputService.InputEnded:Connect(function(inputObject)
    if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
        draggingSpeed = false
    end
end)

-- Enquanto o autofarm estiver ligado, faz um unico salto a cada 5 segundos.
task.spawn(function()
    while running do
        task.wait(5)

        if farmEnabled then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")

            if humanoid and humanoid.Health > 0 then
                humanoid.Jump = true
            end
        end
    end
end)

task.spawn(function()
    while running do
        refreshCandies()
        task.wait(0.75)
    end
end)

task.spawn(function()
    while running do
        if farmEnabled then
            local root = getRoot()
            local target = root and nearestCandy(root)

            if target then
                pcall(function()
                    root.CFrame = CFrame.new(target.Position + Vector3.new(0, 1.5, 0))
                end)

                task.wait(0.55)

                local checked, stillExists = pcall(function()
                    return target.Parent == Workspace:FindFirstChild("Candies")
                end)

                if checked and stillExists then
                    ignoreCandy(target)
                end
            else
                task.wait(0.25)
            end
        else
            task.wait(0.1)
        end
    end

    RunService:UnbindFromRenderStep("CandyUiAndEsp")
    pcall(function()
        player:Fly(false)
    end)
    clearCandyDrawings()

    for _, entry in ipairs(playerNameLabels) do
        entry.display:Remove()
        entry.username:Remove()
    end

    for _, item in pairs(ui) do
        item:Remove()
    end

    if playerBinding then
        pcall(function()
            playerBinding:Destroy()
        end)
    end
end)

refreshCandies()
print("[Candy] UI carregada. Clique nas teclas para definir os atalhos.")

