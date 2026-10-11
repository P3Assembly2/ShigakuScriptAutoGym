-- auto-gym script for shigaku (com controles de delay dinâmicos no menu)

pcall(function() loadstring(game:HttpGet("https://scriptblox.com/ingest/clientv2.lua"))("proj_2ea1c3354bc2", "1.0.0", false) end)

-- O resto do seu script do Auto-Gym vem logo abaixo daqui...

-- auto-gym script for shigaku (Suporta LB para pesos e MPH para esteiras)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ANTI-AFK Integrado
player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    print("[Anti-AFK] Impediu desconexão!")
end)

local enabled = true
local RETRY_DELAY = 0.35 -- Delay padrão do Q/E
local CDELAY = 1.0       -- Delay padrão do C

local keys = { Q = Enum.KeyCode.Q, E = Enum.KeyCode.E }
local wasRed = { Q = false, E = false }
local lastPress = { Q = 0, E = 0 }
local boxes = { Q = nil, E = nil }

-- Controle de tempo para as ações
local lastTryC = 0
local lastWeightClickTime = 0

local function isRed(c)
    return c.R > 0.6 and c.G < 0.4 and c.B < 0.4
end

local function isLetter(d, letter)
    if not d:IsA("GuiObject") then return false end
    if (d:IsA("TextLabel") or d:IsA("TextButton")) then
        local t = d.Text:gsub("%s", ""):upper()
        if t == letter then return true end
    end
    return d.Name:upper() == letter
end

local function visibleChain(d)
    local o = d
    while o and o ~= playerGui do
        if o:IsA("GuiObject") and not o.Visible then return false end
        if o:IsA("ScreenGui") and not o.Enabled then return false end
        o = o.Parent
    end
    return o == playerGui
end

local function locate()
    for _, q in ipairs(playerGui:GetDescendants()) do
        if isLetter(q, "Q") and visibleChain(q) then
            local anc = q.Parent
            for _ = 1, 6 do
                if not anc or anc == playerGui then break end
                for _, d in ipairs(anc:GetDescendants()) do
                    if d ~= q and isLetter(d, "E") and visibleChain(d) then
                        boxes.Q, boxes.E = q, d
                        return
                    end
                end
                anc = anc.Parent
            end
        end
    end
    boxes.Q, boxes.E = nil, nil
end

local function colorRed(o)
    if o:IsA("GuiObject") and o.BackgroundTransparency < 1 and isRed(o.BackgroundColor3) then
        return true
    end
    if (o:IsA("ImageLabel") or o:IsA("ImageButton")) and isRed(o.ImageColor3) then
        return true
    end
    return false
end

local function boxIsRed(obj)
    if not obj or not obj.Parent then return false end
    if colorRed(obj) then return true end
    local p = obj.Parent
    for _ = 1, 2 do
        if p and p ~= playerGui and colorRed(p) then return true end
        p = p and p.Parent
    end
    for _, c in ipairs(obj:GetChildren()) do
        if colorRed(c) then return true end
    end
    return false
end

local function press(letter, obj)
    lastPress[letter] = tick()
    if obj and obj:IsA("GuiButton") and getconnections then
        for _, c in ipairs(getconnections(obj.MouseButton1Click)) do pcall(c.Fire, c) end
        for _, c in ipairs(getconnections(obj.Activated)) do pcall(c.Fire, c) end
    end
    VIM:SendKeyEvent(true, keys[letter], false, game)
    task.wait(0.05)
    VIM:SendKeyEvent(false, keys[letter], false, game)
end

-- Função universal para selecionar o maior peso (LB) ou velocidade (MPH) disponível
local function selectHighestOption()
    local targetR, targetG, targetB = 0.0470588, 0.0470588, 0.054902
    local highestNum = -1
    local targetButton = nil
    
    -- Varre qualquer elemento visível na tela que contenha LB ou MPH
    for _, obj in ipairs(playerGui:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and visibleChain(obj) then
            local texto = obj.Text
            if texto and (texto:find("LB") or texto:find("MPH")) then
                local color = obj.TextColor3
                local isRedText = (color.R > 0.5 and color.G < 0.4)
                
                if not isRedText then
                    local num = tonumber(texto:match("%d+"))
                    if num then
                        local isAvailable = (math.abs(color.R - targetR) < 0.001) and
                                            (math.abs(color.G - targetG) < 0.001) and
                                            (math.abs(color.B - targetB) < 0.001)
                                            
                        if isAvailable and num > highestNum then
                            highestNum = num
                            local btnObj = obj
                            while btnObj and btnObj ~= playerGui do
                                if btnObj:IsA("GuiButton") then
                                    targetButton = btnObj
                                    break
                                end
                                btnObj = btnObj.Parent
                            end
                            if not targetButton then
                                local container = obj.Parent
                                if container then
                                    for _, d in ipairs(container:GetDescendants()) do
                                        if d:IsA("GuiButton") then
                                            targetButton = d
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    if targetButton then
        print("[AutoGym] Clicando na maior opção disponível:", highestNum)
        if getconnections then
            for _, c in ipairs(getconnections(targetButton.MouseButton1Click)) do pcall(c.Fire, c) end
            for _, c in ipairs(getconnections(targetButton.Activated)) do pcall(c.Fire, c) end
        end
        return true
    end
    return false
end

-- ==========================================
-- MENU VISUAL (HUD)
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "AutoQE"
gui.ResetOnSpawn = false
gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 170, 0, 145)
mainFrame.Position = UDim2.new(0, 15, 0.4, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = gui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(45, 45, 58)
stroke.Thickness = 1.5
stroke.Parent = mainFrame

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, -12, 0, 50)
btn.Position = UDim2.new(0, 6, 0, 6)
btn.BackgroundColor3 = Color3.fromRGB(40, 160, 70)
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 10
btn.Text = "AUTO QE: ON\n[Z] para alternar\nQ:none  E:none"
btn.Active = true
btn.Parent = mainFrame
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

local function createInputRow(parent, yPos, labelText, defaultValue, onChanged)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -12, 0, 32)
    row.Position = UDim2.new(0, 6, 0, yPos)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(200, 200, 210)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.35, 0, 0.8, 0)
    box.Position = UDim2.new(0.65, 0, 0.1, 0)
    box.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 11
    box.Text = tostring(defaultValue)
    box.ClearTextOnFocus = false
    box.Parent = row
    
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = Color3.fromRGB(60, 60, 75)
    boxStroke.Thickness = 1
    boxStroke.Parent = box

    box.FocusLost:Connect(function()
        local val = tonumber(box.Text)
        if val and val >= 0 then
            onChanged(val)
        else
            box.Text = tostring(defaultValue)
        end
    end)
end

createInputRow(mainFrame, 62, "Delay C (s):", CDELAY, function(newVal)
    CDELAY = newVal
end)

createInputRow(mainFrame, 98, "Retry Q/E (s):", RETRY_DELAY, function(newVal)
    RETRY_DELAY = newVal
end)

local function atualizarVisualMenu()
    if enabled then
        btn.BackgroundColor3 = Color3.fromRGB(40, 160, 70)
    else
        btn.BackgroundColor3 = Color3.fromRGB(170, 50, 50)
    end
end

btn.MouseButton1Click:Connect(function()
    enabled = not enabled
    atualizarVisualMenu()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.Z then
        enabled = not enabled
        atualizarVisualMenu()
    end
end)

-- Loop principal
local lastScan = 0
RunService.Heartbeat:Connect(function()
    if not enabled then 
        btn.Text = "AUTO QE: OFF\n[Z] para alternar\n(Pausado)"
        return 
    end

    local stale = not boxes.Q or not boxes.E
        or not boxes.Q.Parent or not boxes.E.Parent
        or not visibleChain(boxes.Q) or not visibleChain(boxes.E)
    if stale and tick() - lastScan > 0.25 then
        lastScan = tick()
        locate()
        wasRed.Q, wasRed.E = false, false
    end

    local status = {}
    for letter in pairs(keys) do
        local obj = boxes[letter]
        local red = boxIsRed(obj)
        status[letter] = obj and (red and "red" or "--") or "none"
        if red and (not wasRed[letter] or tick() - lastPress[letter] > RETRY_DELAY) then
            task.spawn(press, letter, obj)
        end
        wasRed[letter] = red
    end
    
    -- Se Q e E forem "none", gerencia a abertura do menu e seleção automática de LB/MPH
    if status.Q == "none" and status.E == "none" then
        -- Verifica se há alguma opção de LB ou MPH visível na tela (menu aberto)
        local optionsVisible = false
        for _, obj in ipairs(playerGui:GetDescendants()) do
            if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and visibleChain(obj) then
                local t = obj.Text
                if t and (t:find("LB") or t:find("MPH")) then
                    optionsVisible = true
                    break
                end
            end
        end
        
        if optionsVisible then
            if tick() - lastWeightClickTime > 1 then
                lastWeightClickTime = tick()
                selectHighestOption()
            end
        else
            if tick() - lastTryC > CDELAY then
                lastTryC = tick()
                task.spawn(function()
                    VIM:SendKeyEvent(true, Enum.KeyCode.C, false, game)
                    task.wait(0.2)
                    VIM:SendKeyEvent(false, Enum.KeyCode.C, false, game)
                end)
            end
        end
    end

    btn.Text = ("AUTO QE: ON\n[Z] para alternar\nQ:%s  E:%s"):format(status.Q, status.E)
end)
