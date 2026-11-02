-- ESP de depuração para o seu jogo: jogadores, killer e geradores.
-- Reexecute este script ao iniciar uma nova rodada para atualizar os papéis.

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local function destroy(handle)
    if handle and handle.Destroy then
        pcall(function() handle:Destroy() end)
    end
end

if shared.DevESP then
    destroy(shared.DevESP.survivors)
    destroy(shared.DevESP.killer)
    destroy(shared.DevESP.generators)
end

local function addPlayerVisuals(entity, color)
    entity:addChams({
        Style = "Silhouette",
        Color = color,
        Transparency = 0.30,
        Filled = true,
        Outline = true,
        OutlineColor = Color3.new(1, 1, 1),
        OutlineTransparency = 0.95,
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
    entity:AddHealthBar({
        Side = "Left",
        Color = color,
        Transparency = 1,
        ShowText = true,
    })
end

local survivors = entities.new({
    MaxDistance = 0,
    HideDead = true,
    RefreshInterval = 1,
    Filter = function(entity)
        local player = entity.Options.Player
        return player
            and player ~= localPlayer
            and player:GetAttribute("RoundSurvivor") == true
    end,
})

survivors:BindPlayers(Players, function(entity, player)
    entity.Options.Name = "PLAYER | " .. player.Name
    addPlayerVisuals(entity, Color3.fromRGB(0, 220, 255))
end)

local killer = entities.new({
    MaxDistance = 0,
    HideDead = true,
    RefreshInterval = 1,
    Filter = function(entity)
        local player = entity.Options.Player
        return player
            and player ~= localPlayer
            and player:GetAttribute("RoundSurvivor") == false
    end,
})

killer:BindPlayers(Players, function(entity, player)
    entity.Options.Name = "KILLER | " .. player.Name
    addPlayerVisuals(entity, Color3.fromRGB(255, 65, 65))
end)

local generators = entities.new({
    MaxDistance = 0,
    HideDead = false,
    RefreshInterval = 1,
})

local function addGeneratorVisuals(entity)
    local color = Color3.fromRGB(255, 205, 0)
    entity:addChams({
        Style = "Silhouette",
        Color = color,
        Transparency = 0.22,
        Filled = true,
        Outline = true,
        OutlineColor = Color3.new(1, 1, 1),
        OutlineTransparency = 0.9,
        Thickness = 1.25,
    })
    entity:addBox({
        Style = "3D",
        Color = color,
        Transparency = 1,
        Thickness = 1.5,
        Border = true,
        BorderColor = Color3.new(0, 0, 0),
        BorderTransparency = 0.9,
    })
    entity:AddNameTag({
        Color = color,
        Transparency = 1,
        Size = 13,
        Outline = true,
        ShowDistance = true,
    })
end

local map = workspace:FindFirstChild("Map")
local gensFolder = map and map:FindFirstChild("Gens")
if gensFolder then
    for index, model in ipairs(gensFolder:GetChildren()) do
        if model:IsA("Model") then
            local body = model:FindFirstChild("GeneratorBody")
            if body and body:IsA("BasePart") then
                local entity = generators:Add({
                    Name = "GENERATOR " .. index,
                    Parts = { body },
                })
                addGeneratorVisuals(entity)
            end
        end
    end
else
    warn("ESP: Workspace.Map.Gens não foi encontrado.")
end

shared.DevESP = {
    survivors = survivors,
    killer = killer,
    generators = generators,
}

print("ESP ativo: jogadores (azul), killer (vermelho), geradores (amarelo).")

local ok, Library = pcall(function()
    return loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/TrollLexBR/Jael-X/refs/heads/main/examples/DrawingLibPrism"
    ))()
end)

if not ok or type(Library) ~= "table" then
    warn("[ESP UI] " .. tostring(Library))
    return
end

local window = Library:NewWindow({
    title = "Prism ESP",
    subtitle = "Painel de depuração",
    configId = "prism-dev-esp",
    width = 620,
    height = 470,
    autoSave = true,
    configs = true,
})

local tab = window:NewTab("ESP", "Marcadores de depuração", "wallhack")
local controls = tab:NewSection("Visualização", "full")

controls:AddParagraph({
    text = "Use os toggles para mostrar ou ocultar cada categoria. Insert abre ou fecha o painel."
})

controls:AddToggle({
    text = "Jogadores",
    flag = "esp_players",
    default = true,
    tooltip = "Marcadores azuis para sobreviventes.",
    callback = function(enabled)
        survivors:SetEnabled(enabled)
        Library:Notify("ESP", enabled and "Jogadores ativados." or "Jogadores desativados.", 2, "success")
    end,
})

controls:AddToggle({
    text = "Killer",
    flag = "esp_killer",
    default = true,
    tooltip = "Marcadores vermelhos para o killer da rodada.",
    callback = function(enabled)
        killer:SetEnabled(enabled)
        Library:Notify("ESP", enabled and "Killer ativado." or "Killer desativado.", 2, "success")
    end,
})

controls:AddToggle({
    text = "Geradores",
    flag = "esp_generators",
    default = true,
    tooltip = "Marcadores amarelos para os geradores do mapa.",
    callback = function(enabled)
        generators:SetEnabled(enabled)
        Library:Notify("ESP", enabled and "Geradores ativados." or "Geradores desativados.", 2, "success")
    end,
})

controls:AddButton({
    text = "Desativar tudo",
    callback = function()
        survivors:SetEnabled(false)
        killer:SetEnabled(false)
        generators:SetEnabled(false)
        Library:Notify("ESP", "Todos os marcadores foram desativados.", 2, "success")
    end,
})

controls:AddButton({
    text = "Ativar tudo",
    callback = function()
        survivors:SetEnabled(true)
        killer:SetEnabled(true)
        generators:SetEnabled(true)
        Library:Notify("ESP", "Todos os marcadores foram ativados.", 2, "success")
    end,
})

local settings = window:NewTab("Configurações", "Painel e limpeza", "settings")
local options = settings:NewSection("Geral", "full")

options:AddLabel({
    text = "Cores: jogadores azul, killer vermelho, geradores amarelo."
})

options:AddButton({
    text = "Fechar e remover ESP",
    callback = function()
        survivors:Destroy()
        killer:Destroy()
        generators:Destroy()
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
Library:Notify("Prism ESP", "Painel carregado. Use Insert para mostrar ou ocultar.", 4, "success")
