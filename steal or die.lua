-- Painel de depuração: monstro, jogadores comuns e itens no chão.
-- Dados confirmados: Workspace.MyLoot / atributos Value, Rarity, Weight e Loot.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

local function destroy(handle)
    if handle and handle.Destroy then
        pcall(function()
            handle:Destroy()
        end)
    elseif handle and handle.Remove then
        pcall(function()
            handle:Remove()
        end)
    end
end

if shared.WorldESP then
    destroy(shared.WorldESP)
end

if shared.MonsterESP then
    destroy(shared.MonsterESP)
end

local function characterHas(character, name)
    return character and character:FindFirstChild(name) ~= nil
end

local function isMonster(player)
    local character = player.Character

    -- Assinatura confirmada para o monstro da rodada atual.
    return characterHas(character, "StomachHollow")
        and characterHas(character, "RibcageLeft")
end

local function addPlayerVisuals(entity, color)
    entity:addChams({
        Style = "Silhouette",
        Color = color,
        Transparency = 0.32,
        Filled = true,
        Outline = true,
        OutlineColor = Color3.new(1, 1, 1),
        OutlineTransparency = 0.9,
        Thickness = 1.5,
    })

    entity:addBox({
        Style = "Corner",
        Color = color,
        Transparency = 1,
        Thickness = 1.5,
        Border = true,
        BorderColor = Color3.new(0, 0, 0),
        BorderTransparency = 0.9,
        CornerLength = 0.25,
    })

    entity:AddNameTag({
        Color = color,
        Transparency = 1,
        Size = 13,
        Outline = true,
        ShowDistance = true,
    })
end

local monsters = entities.new({
    MaxDistance = 0,
    HideDead = false,
    RefreshInterval = 1,
    Filter = function(entity)
        local player = entity.Options.Player
        return player and player ~= localPlayer and isMonster(player)
    end,
})

monsters:BindPlayers(Players, function(entity, player)
    entity.Options.Name = "MONSTRO | " .. player.Name
    addPlayerVisuals(entity, Color3.fromRGB(255, 55, 55))
end)

local players = entities.new({
    MaxDistance = 0,
    HideDead = true,
    RefreshInterval = 1,
    Filter = function(entity)
        local player = entity.Options.Player
        return player and player ~= localPlayer and not isMonster(player)
    end,
})

players:BindPlayers(Players, function(entity, player)
    entity.Options.Name = "PLAYER | " .. player.Name
    addPlayerVisuals(entity, Color3.fromRGB(0, 220, 255))
end)

local suite = {
    active = true,
    lootEnabled = true,
    monsters = monsters,
    players = players,
    items = {},
}

function suite:SetLootEnabled(enabled)
    self.lootEnabled = enabled

    for _, marker in pairs(self.items) do
        marker.box.Visible = enabled
        marker.label.Visible = false
    end
end

function suite:Destroy()
    self.active = false
    destroy(self.monsters)
    destroy(self.players)

    for _, marker in pairs(self.items) do
        destroy(marker.box)
        destroy(marker.label)
    end

    self.items = {}
end

local function addLootMarker(item)
    if not item:IsA("BasePart") then
        return
    end

    local box = Drawing3D.new("Box")
    box.CFrame = item.CFrame
    box.Size = item.Size
    box.Color = Color3.fromRGB(255, 205, 0)
    box.Transparency = 0.45
    box.Filled = true
    box.Visible = true

    local label = Drawing.new("Text")
    label.Color = Color3.fromRGB(255, 225, 90)
    label.Transparency = 1
    label.Size = 13
    label.Center = true
    label.Outline = true
    label.OutlineColor = Color3.new(0, 0, 0)
    label.Visible = false

    suite.items[item] = {
        box = box,
        label = label,
    }
end

local function discoverLoot()
    local folder = workspace:FindFirstChild("MyLoot")
    if not folder then
        return
    end

    for _, item in ipairs(folder:GetChildren()) do
        if item:IsA("BasePart")
            and item:GetAttribute("Loot") == true
            and not suite.items[item] then
            addLootMarker(item)
        end
    end
end

task.spawn(function()
    while suite.active do
        discoverLoot()
        task.wait(1)
    end
end)

RunService.RenderStepped:Connect(function()
    if not suite.active then
        return
    end

    for item, marker in pairs(suite.items) do
        if not item.Parent then
            destroy(marker.box)
            destroy(marker.label)
            suite.items[item] = nil
        else
            marker.box.CFrame = item.CFrame
            marker.box.Size = item.Size

            local value = item:GetAttribute("Value") or 0
            local rarity = item:GetAttribute("Rarity") or "Sem raridade"
            marker.label.Text = string.format("%s | $%s | %s", item.Name, tostring(value), tostring(rarity))

            local point, onScreen = Drawing3D.WorldToViewportPoint(item.Position)
            marker.box.Visible = suite.lootEnabled
            marker.label.Visible = suite.lootEnabled and onScreen

            if suite.lootEnabled and onScreen then
                marker.label.Position = Vector2.new(point.X, point.Y - 18)
            end
        end
    end
end)

shared.WorldESP = suite
shared.MonsterESP = monsters

print("[World ESP] Ativo: monstro vermelho, jogadores azuis e itens amarelos com valor.")


-- Interface Prism
local ok, Library = pcall(function()
    return loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/TrollLexBR/Jael-X/refs/heads/main/examples/DrawingLibPrism"
    ))()
end)

if not ok or type(Library) ~= "table" then
    warn("[World ESP UI] " .. tostring(Library))
    return
end

local window = Library:NewWindow({
    title = "Prism",
    configId = "prism-world-esp",
    width = 620,
    height = 470,
    autoSave = true,
    configs = true,
})

local mainTab = window:NewTab("Main", "Visão geral", "main")
local main = mainTab:NewSection("Status", "full")

main:AddParagraph({
    text = "Monstro em vermelho, jogadores em azul e itens no chão em amarelo. Itens mostram nome, valor e raridade."
})

local espTab = window:NewTab("ESP", "Marcadores", "wallhack")
local visuals = espTab:NewSection("Visualização", "full")

visuals:AddToggle({
    text = "Monstro",
    flag = "worldesp_monster",
    default = true,
    callback = function(enabled)
        monsters:SetEnabled(enabled)
        Library:Notify("Monstro", enabled and "Ativado." or "Desativado.", 2, "success")
    end,
})

visuals:AddToggle({
    text = "Jogadores",
    flag = "worldesp_players",
    default = true,
    callback = function(enabled)
        players:SetEnabled(enabled)
        Library:Notify("Jogadores", enabled and "Ativados." or "Desativados.", 2, "success")
    end,
})

visuals:AddToggle({
    text = "Itens no chão",
    flag = "worldesp_loot",
    default = true,
    callback = function(enabled)
        suite:SetLootEnabled(enabled)
        Library:Notify("Itens", enabled and "Ativados." or "Desativados.", 2, "success")
    end,
})

visuals:AddDivider()

visuals:AddButton({
    text = "Ativar todos os marcadores",
    callback = function()
        monsters:SetEnabled(true)
        players:SetEnabled(true)
        suite:SetLootEnabled(true)
        Library:Notify("Prism", "Todos os marcadores foram ativados.", 2, "success")
    end,
})

visuals:AddButton({
    text = "Desativar todos os marcadores",
    callback = function()
        monsters:SetEnabled(false)
        players:SetEnabled(false)
        suite:SetLootEnabled(false)
        Library:Notify("Prism", "Todos os marcadores foram desativados.", 2, "success")
    end,
})

local settingsTab = window:NewTab("Settings", "Limpeza", "settings")
local settings = settingsTab:NewSection("Geral", "full")

settings:AddButton({
    text = "Fechar e remover marcadores",
    callback = function()
        suite:Destroy()
        Library:Unload()
    end,
})

pcall(function()
    window:LoadLastSession()
end)

Library:SetTheme({
    background = Color3.fromRGB(13, 13, 16),
    panel = Color3.fromRGB(20, 20, 25),
    header = Color3.fromRGB(25, 20, 32),
    field = Color3.fromRGB(29, 25, 36),
    border = Color3.fromRGB(72, 34, 104),
    text = Color3.fromRGB(240, 240, 245),
    muted = Color3.fromRGB(160, 155, 170),
    accent = Color3.fromRGB(202, 0, 255),
    danger = Color3.fromRGB(255, 75, 95),
    success = Color3.fromRGB(80, 225, 155),
})

Library:SetVisible(true)
Library:Notify("Prism", "Interface carregada. Insert mostra ou oculta.", 4, "success")
