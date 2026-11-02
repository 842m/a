-- Painel de depuração: sobreviventes, killer e geradores.
-- Execute durante uma rodada ativa.

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local SHOW_LOCAL_KILLER = true

local function destroy(value)
    if value and value.Destroy then
        pcall(function()
            value:Destroy()
        end)
    end
end

if shared.DevESP then
    destroy(shared.DevESP)
end

local controller = {
    active = true,
    generatorsEnabled = true,
    generatorMarkers = {},
}

function controller:SetGeneratorsEnabled(enabled)
    self.generatorsEnabled = enabled

    for _, marker in pairs(self.generatorMarkers) do
        marker.visual.Visible = enabled
    end
end

function controller:Destroy()
    self.active = false
    destroy(self.survivors)
    destroy(self.killer)

    for _, marker in pairs(self.generatorMarkers) do
        destroy(marker.visual)
    end

    self.generatorMarkers = {}
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
end

local function characterHas(character, name)
    return character and character:FindFirstChild(name) ~= nil
end

local function isKiller(player)
    local character = player.Character

    -- Marcadores confirmados no personagem do killer nesta experiência.
    return characterHas(character, "Lookscriptkiller")
        or characterHas(character, "Killerost")
        or characterHas(character, "Powers")
        or characterHas(character, "Weapon")
end

local function isSurvivor(player)
    local character = player.Character

    return character
        and not isKiller(player)
        and (
            characterHas(character, "Highlight-forsurvivor")
            or characterHas(character, "Skillcheck-player")
        )
end

controller.survivors = entities.new({
    MaxDistance = 0,
    HideDead = true,
    RefreshInterval = 1,
    Filter = function(entity)
        local player = entity.Options.Player
        return player
            and player ~= localPlayer
            and isSurvivor(player)
    end,
})

controller.survivors:BindPlayers(Players, function(entity, player)
    entity.Options.Name = "PLAYER | " .. player.Name
    addPlayerVisuals(entity, Color3.fromRGB(0, 220, 255))
end)

controller.killer = entities.new({
    MaxDistance = 0,
    HideDead = true,
    RefreshInterval = 1,
    Filter = function(entity)
        local player = entity.Options.Player
        return player
            and (SHOW_LOCAL_KILLER or player ~= localPlayer)
            and isKiller(player)
    end,
})

controller.killer:BindPlayers(Players, function(entity, player)
    entity.Options.Name = "KILLER | " .. player.Name
    addPlayerVisuals(entity, Color3.fromRGB(255, 65, 65))
end)

local function getGeneratorRoot()
    local map = workspace:FindFirstChild("Map")

    -- Estrutura confirmada na sessão: Workspace.Map.Generators
    local generators = map and map:FindFirstChild("Generators")
    if generators then
        return generators
    end

    -- Compatibilidade com mapas que usem os nomes antigos.
    local gens = map and map:FindFirstChild("Gens")
    if gens then
        return gens
    end

    return workspace:FindFirstChild("Generators", true)
        or workspace:FindFirstChild("Gens", true)
end

local function collectParts(model)
    -- Cada gerador confirmado possui GeneratorBody; uma peça é suficiente
    -- para o marcador e evita percorrer todos os descendentes.
    local body = model:FindFirstChild("GeneratorBody", true)
    if body and body:IsA("BasePart") then
        return { body }
    end

    return {}
end

local function getGeneratorCompleted(model)
    local attributeNames = {
        "Completed",
        "IsCompleted",
        "Finished",
        "Repaired",
        "Activated",
    }

    for _, name in ipairs(attributeNames) do
        local value = model:GetAttribute(name)
        if type(value) == "boolean" then
            return value
        end
    end

    -- Estrutura confirmada na sessão: RepairProgress vai de 0 a 100.
    local progress = model:GetAttribute("RepairProgress")
    if type(progress) == "number" then
        return progress >= 100
    end

    for _, object in ipairs(model:GetDescendants()) do
        if object:IsA("BoolValue") then
            local name = string.lower(object.Name)

            if name == "completed"
                or name == "iscompleted"
                or name == "finished"
                or name == "repaired"
                or name == "activated" then
                return object.Value
            end
        end
    end

    return nil
end

local function addGenerator(model, index)
    local parts = collectParts(model)
    if #parts == 0 then
        return
    end

    local visual = Drawing3D.new("Silhouette")
    visual.Filled = true
    visual.Outline = true
    visual.OutlineColor = Color3.new(1, 1, 1)
    visual.OutlineTransparency = 0.88
    visual.Thickness = 1.25
    visual.Visible = true

    controller.generatorMarkers[model] = {
        index = index,
        model = model,
        parts = parts,
        visual = visual,
    }
end

local function discoverGenerators()
    local generatorRoot = getGeneratorRoot()
    if not generatorRoot then
        return
    end

    local index = 0
    for _, model in ipairs(generatorRoot:GetChildren()) do
        if model:IsA("Model") then
            index += 1

            if not controller.generatorMarkers[model] then
                addGenerator(model, index)
            end
        end
    end
end

-- O mapa pode carregar depois do script; registra os geradores quando aparecerem.
discoverGenerators()

task.spawn(function()
    while controller.active do
        discoverGenerators()
        task.wait(2)
    end
end)

task.spawn(function()
    while controller.active do
        for model, marker in pairs(controller.generatorMarkers) do
            if not model.Parent then
                destroy(marker.visual)
                controller.generatorMarkers[model] = nil
            else
                local volumes = {}

                for _, part in ipairs(marker.parts) do
                    if part.Parent then
                        table.insert(volumes, {
                            CFrame = part.CFrame,
                            Size = part.Size,
                        })
                    end
                end

                marker.visual.Parts = volumes
                marker.visual.Visible = controller.generatorsEnabled

                local completed = getGeneratorCompleted(model)

                if completed == true then
                    marker.visual.Color = Color3.fromRGB(65, 225, 120) -- concluído
                    marker.visual.Transparency = 0.34
                elseif completed == false then
                    marker.visual.Color = Color3.fromRGB(255, 155, 45) -- pendente
                    marker.visual.Transparency = 0.24
                else
                    marker.visual.Color = Color3.fromRGB(255, 215, 0) -- estado desconhecido
                    marker.visual.Transparency = 0.24
                end
            end
        end

        task.wait(1)
    end
end)

shared.DevESP = controller

print("DevESP ativo: jogadores azul, killer vermelho, gerador concluído verde, pendente laranja.")

-- Interface de depuração (API Prism).
local ok, Library = pcall(function()
    return loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/TrollLexBR/Jael-X/refs/heads/main/examples/DrawingLibPrism"
    ))()
end)

if not ok or type(Library) ~= "table" then
    warn("[DevESP UI] " .. tostring(Library))
    return
end

local window = Library:NewWindow({
    title = "Prism",
    configId = "prism-dev-tools",
    width = 620,
    height = 470,
    autoSave = true,
    configs = true,
})

local mainTab = window:NewTab("Main", "Visão geral", "main")
local main = mainTab:NewSection("Status", "full")

main:AddParagraph({
    text = "Marcadores de teste: sobreviventes em azul, killer em vermelho, geradores pendentes em laranja e concluídos em verde."
})

main:AddLabel({
    text = "O menu salva suas preferências automaticamente. Insert mostra ou oculta a interface."
})

local espTab = window:NewTab("ESP", "Marcadores de depuração", "wallhack")
local visuals = espTab:NewSection("Visualização", "full")

visuals:AddToggle({
    text = "Sobreviventes",
    flag = "devesp_survivors",
    default = true,
    tooltip = "Exibe jogadores identificados como sobreviventes.",
    callback = function(enabled)
        controller.survivors:SetEnabled(enabled)
        Library:Notify("Sobreviventes", enabled and "Ativados." or "Desativados.", 2, "success")
    end,
})

visuals:AddToggle({
    text = "Killer",
    flag = "devesp_killer",
    default = true,
    tooltip = "Usa os marcadores de personagem do killer encontrados nesta experiência.",
    callback = function(enabled)
        controller.killer:SetEnabled(enabled)
        Library:Notify("Killer", enabled and "Ativado." or "Desativado.", 2, "success")
    end,
})

visuals:AddToggle({
    text = "Geradores",
    flag = "devesp_generators",
    default = true,
    tooltip = "Mostra GeneratorBody com cores conforme RepairProgress.",
    callback = function(enabled)
        controller:SetGeneratorsEnabled(enabled)
        Library:Notify("Geradores", enabled and "Ativados." or "Desativados.", 2, "success")
    end,
})

visuals:AddDivider()

visuals:AddButton({
    text = "Ativar todos os marcadores",
    callback = function()
        controller.survivors:SetEnabled(true)
        controller.killer:SetEnabled(true)
        controller:SetGeneratorsEnabled(true)
        Library:Notify("Dev Tools", "Todos os marcadores foram ativados.", 2, "success")
    end,
})

visuals:AddButton({
    text = "Desativar todos os marcadores",
    callback = function()
        controller.survivors:SetEnabled(false)
        controller.killer:SetEnabled(false)
        controller:SetGeneratorsEnabled(false)
        Library:Notify("Dev Tools", "Todos os marcadores foram desativados.", 2, "success")
    end,
})

local settingsTab = window:NewTab("Settings", "Interface e limpeza", "settings")
local settings = settingsTab:NewSection("Geral", "full")

settings:AddLabel({
    text = "A detecção do killer prioriza Lookscriptkiller, Killerost, Powers e Weapon."
})

settings:AddLabel({
    text = "Geradores usam Workspace.Map.Generators e o atributo RepairProgress."
})

settings:AddButton({
    text = "Fechar e remover marcadores",
    callback = function()
        controller:Destroy()
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
Library:Notify("Prism Dev Tools", "Interface carregada. Pressione Insert para ocultar ou mostrar.", 4, "success")
