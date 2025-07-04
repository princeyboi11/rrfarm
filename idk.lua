-- MIH HUB Auto-Farm Script
-- Users configure with: getgenv().Webhook and getgenv().Priority_Item

-- Configuration validation
if not getgenv().Webhook or type(getgenv().Webhook) ~= "string" then
    getgenv().Webhook = ""
end
if not getgenv().Priority_Item or (getgenv().Priority_Item ~= "Dr. Megga Punk" and getgenv().Priority_Item ~= "Trait Reroll") then
    getgenv().Priority_Item = "Dr. Megga Punk"
end

-- Persistent variables
local startTime = os.clock()
local status = "Initializing..."
local screenGui = nil

-- Wait for game to load
repeat task.wait() until game:IsLoaded()

-- GUI Creation
do
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MIH_HUB_GUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = game:GetService("CoreGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 0.5
    frame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Text = "MIH HUB"
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 48
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Size = UDim2.new(1, 0, 0.4, 0)
    title.Position = UDim2.new(0, 0, 0.3, 0)
    title.BackgroundTransparency = 1
    title.Parent = frame

    local runtimeLabel = Instance.new("TextLabel")
    runtimeLabel.Text = "Runtime: 00:00:00"
    runtimeLabel.Font = Enum.Font.Gotham
    runtimeLabel.TextSize = 24
    runtimeLabel.TextColor3 = Color3.new(1, 1, 1)
    runtimeLabel.Size = UDim2.new(1, 0, 0.1, 0)
    runtimeLabel.Position = UDim2.new(0, 0, 0.6, 0)
    runtimeLabel.BackgroundTransparency = 1
    runtimeLabel.Parent = frame

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Text = status
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 24
    statusLabel.TextColor3 = Color3.new(1, 1, 1)
    statusLabel.Size = UDim2.new(1, 0, 0.1, 0)
    statusLabel.Position = UDim2.new(0, 0, 0.7, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Parent = frame

    -- Update GUI
    task.spawn(function()
        while task.wait(1) do
            local seconds = os.clock() - startTime
            local hours = math.floor(seconds/3600)
            local minutes = math.floor((seconds%3600)/60)
            local secs = math.floor(seconds%60)
            runtimeLabel.Text = "Runtime: " .. string.format("%02d:%02d:%02d", hours, minutes, secs)
            statusLabel.Text = status
        end
    end)
end

-- Aggressive FPS Boost
do
    local function OptimizeInstance(inst)
        pcall(function()
            if inst:IsA("DataModelMesh") then
                if inst:IsA("SpecialMesh") then
                    inst.MeshId = ""
                    inst.TextureId = ""
                end
                inst:Destroy()
            elseif inst:IsA("FaceInstance") or inst:IsA("ShirtGraphic") then
                if inst:IsA("FaceInstance") then
                    inst.Transparency = 1
                else
                    inst.Graphic = ""
                end
                inst:Destroy()
            elseif table.find({"ParticleEmitter", "Trail", "Smoke", "Fire", "Sparkles"}, inst.ClassName) then
                inst.Enabled = false
                inst:Destroy()
            elseif inst:IsA("PostEffect") or inst:IsA("Explosion") then
                inst.Enabled = false
                inst:Destroy()
            elseif inst:IsA("Clothing") or inst:IsA("SurfaceAppearance") then
                inst:Destroy()
            elseif inst:IsA("BasePart") then
                inst.Material = Enum.Material.Plastic
                inst.Reflectance = 0
                if inst:IsA("MeshPart") then
                    inst.RenderFidelity = Enum.RenderFidelity.Performance
                    inst.TextureID = ""
                    inst.MeshId = ""
                end
            elseif inst:IsA("TextLabel") and inst:IsDescendantOf(workspace) then
                inst:Destroy()
            elseif inst:IsA("Model") then
                inst.LevelOfDetail = 1
            end
        end)
    end

    -- Apply optimizations
    local Lighting = game:GetService("Lighting")
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.ShadowSoftness = 0
    
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 0
    end
    
    settings().Rendering.QualityLevel = 1
    settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
    
    local MaterialService = game:GetService("MaterialService")
    MaterialService.Use2022Materials = false
    for _, v in ipairs(MaterialService:GetChildren()) do
        pcall(v.Destroy, v)
    end
    
    if setfpscap then
        setfpscap(1000)
    end

    -- Process all instances
    for _, inst in ipairs(game:GetDescendants()) do
        OptimizeInstance(inst)
    end

    game.DescendantAdded:Connect(OptimizeInstance)
end

-- Main Auto-Farm Logic
do
    status = "Loading auto-farm..."
    task.wait(1)

    -- Services
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    local LocalPlayer = Players.LocalPlayer
    local PLAYER_NAME = LocalPlayer.Name

    -- Configuration
    local MAIN_PLACE_ID = 72829404259339
    local TARGET_WORLD = "TokyoGhoul"
    local TARGET_CHAPTER = "TokyoGhoul_Chapter10"
    local TARGET_DIFFICULTY = "Nightmare"
    local PORTAL_TO_SELL = "Ghoul City Portal I"

    -- Remotes
    local MerchantRemote = ReplicatedStorage.Remote.Server.Gameplay.Merchant
    local PlayRoomEvent = ReplicatedStorage.Remote.Server.PlayRoom.Event
    local VotePlayingRemote = ReplicatedStorage.Remote.Server.OnGame.Voting.VotePlaying
    local VoteRetryRemote = ReplicatedStorage.Remote.Server.OnGame.Voting.VoteRetry
    local AutoPlayRemote = ReplicatedStorage.Remote.Server.Units.AutoPlay
    local SellRemote = ReplicatedStorage.Remote.Server.Items.Sell

    -- Data paths
    local playerData = ReplicatedStorage.Player_Data[PLAYER_NAME]
    local merchantData = playerData.Merchant
    local traitRerollData = merchantData:FindFirstChild("Trait Reroll")
    local meggaPunkData = merchantData:FindFirstChild("Dr. Megga Punk")
    local goldStat = playerData.Data.Gold
    local expStat = playerData.Data.Exp
    local gemStat = playerData.Data.Gem
    local hourReset = playerData.Data.HourReset
    local autoPlayBool = playerData.Data.AutoPlay
    local gameRunningValue = ReplicatedStorage.Values.Game.GameRunning

    -- Utility functions
    local function inGame()
        return workspace:FindFirstChild("WayPoint") ~= nil
    end

    local function getMerchantResetSeconds()
        return math.max(0, 3600 - (os.time() - hourReset.Value))
    end

    local function sendWebhook(message, embed)
        if getgenv().Webhook == "" then return end
        pcall(function()
            local data = {["content"] = message, ["embeds"] = embed and {embed} or nil}
            local headers = {["content-type"] = "application/json"}
            local request = http_request or request or HttpPost or syn.request
            request({
                Url = getgenv().Webhook,
                Method = "POST",
                Headers = headers,
                Body = HttpService:JSONEncode(data)
            })
        end)
    end

    local function getInventoryAmount(itemName)
        local found = playerData.Items:FindFirstChild(itemName)
        return found and found.Amount.Value or 0
    end

    -- Core functions
    local function teleportToLobby()
        status = "Teleporting to lobby"
        local timeLeft = math.floor(getMerchantResetSeconds())
        sendWebhook("🔄 Teleporting to Lobby", {
            title = "Merchant Restock Cycle",
            description = string.format("**%s** is returning to lobby for merchant restock\nTime until restock: **%d seconds**", PLAYER_NAME, timeLeft),
            color = 0xFFA500,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        })
        task.wait(1)
        TeleportService:Teleport(MAIN_PLACE_ID)
    end

    local function sellAllPortals()
        if inGame() then return 0, 0 end
        status = "Selling portals"
        local portalItem = playerData.Items:FindFirstChild(PORTAL_TO_SELL)
        if not portalItem or portalItem.Amount.Value <= 0 then return 0, 0 end
        
        local amountSold = portalItem.Amount.Value
        local goldBefore = goldStat.Value
        SellRemote:FireServer(portalItem, {Amount = amountSold})
        task.wait(1)
        local goldGained = goldStat.Value - goldBefore
        
        sendWebhook("💰 Portal Sold", {
            title = "Auto-Sell Completed",
            fields = {
                {name = "Item Sold", value = "`"..PORTAL_TO_SELL.."`", inline = true},
                {name = "Amount", value = "`"..amountSold.."`", inline = true},
                {name = "Gold Gained", value = "**+"..goldGained.."** (Total: `"..goldStat.Value.."`)", inline = false}
            },
            color = 0x00FF00,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        })
        
        return amountSold, goldGained
    end

    local function autoBuyMerchant()
        if inGame() then return 0, 0, 0, 0 end
        status = "Buying from merchant"
        
        local rerollBefore = getInventoryAmount("Trait Reroll")
        local punkBefore = getInventoryAmount("Dr. Megga Punk")
        
        local function buy(itemName, itemData)
            if not itemData then return end
            for _ = 1, 50 do
                if itemData.Quantity.Value <= 0 or goldStat.Value < itemData.CurrencyAmount.Value then break end
                MerchantRemote:FireServer(itemName, 1)
                task.wait(0.05)
            end
        end
        
        if getgenv().Priority_Item == "Dr. Megga Punk" then
            buy("Dr. Megga Punk", meggaPunkData)
            buy("Trait Reroll", traitRerollData)
        else
            buy("Trait Reroll", traitRerollData)
            buy("Dr. Megga Punk", meggaPunkData)
        end
        
        task.wait(0.5)
        local rerollAfter = getInventoryAmount("Trait Reroll")
        local punkAfter = getInventoryAmount("Dr. Megga Punk")
        
        local rerollsGained = rerollAfter - rerollBefore
        local punksGained = punkAfter - punkBefore
        
        if rerollsGained > 0 or punksGained > 0 then
            sendWebhook("🛒 Merchant Purchase", {
                title = "Auto-Buy Completed",
                fields = {
                    {name = "Trait Rerolls", value = "**+"..rerollsGained.."** (Total: `"..rerollAfter.."`)", inline = true},
                    {name = "Dr. Megga Punks", value = "**+"..punksGained.."** (Total: `"..punkAfter.."`)", inline = true},
                    {name = "Next Restock", value = "**"..math.floor(getMerchantResetSeconds()/60).." minutes**", inline = false}
                },
                color = 0x3498DB,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            })
        end
        
        return rerollsGained, rerollAfter, punksGained, punkAfter
    end

    local function joinTokyoGhoul()
        if inGame() then return end
        status = "Joining game"
        PlayRoomEvent:FireServer("Create")
        task.wait(0.2)
        PlayRoomEvent:FireServer("Change-World", {World = TARGET_WORLD})
        task.wait(0.1)
        PlayRoomEvent:FireServer("Change-Chapter", {Chapter = TARGET_CHAPTER})
        task.wait(0.1)
        PlayRoomEvent:FireServer("Change-Difficulty", {Difficulty = TARGET_DIFFICULTY})
        task.wait(0.1)
        PlayRoomEvent:FireServer("Submit")
        task.wait(0.2)
        PlayRoomEvent:FireServer("Start")
    end

    -- Main loop
    status = "Starting main loop"
    sendWebhook("🚀 Script Started", {
        title = "Auto-Farm Initialized",
        description = string.format("**Player:** %s\n**Target:** %s (%s)", PLAYER_NAME, TARGET_CHAPTER, TARGET_DIFFICULTY),
        color = 0x9B59B6,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    })

    -- Stat tracking
    local lastExp, lastGem, lastGold = expStat.Value, gemStat.Value, goldStat.Value
    local webhookSent = false

    -- Game state listener
    gameRunningValue:GetPropertyChangedSignal("Value"):Connect(function()
        if not gameRunningValue.Value and not webhookSent then
            status = "Processing rewards"
            webhookSent = true
            task.wait(2)
            
            local expGain = expStat.Value - lastExp
            local gemGain = gemStat.Value - lastGem
            local goldGain = goldStat.Value - lastGold
            
            lastExp, lastGem, lastGold = expStat.Value, gemStat.Value, goldStat.Value
            
            if expGain > 0 or gemGain > 0 or goldGain > 0 then
                sendWebhook("🏆 Stage Cleared!", {
                    title = string.format("%s - %s", TARGET_CHAPTER, TARGET_DIFFICULTY),
                    fields = {
                        {name = "EXP Gained", value = "**+"..expGain.."** (Total: `"..expStat.Value.."`)", inline = true},
                        {name = "Gems Gained", value = "**+"..gemGain.."** (Total: `"..gemStat.Value.."`)", inline = true},
                        {name = "Gold Gained", value = "**+"..goldGain.."** (Total: `"..goldStat.Value.."`)", inline = true}
                    },
                    color = 0xFFD700,
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                })
            end
            
            if LocalPlayer.PlayerGui:FindFirstChild("Visual") then
                LocalPlayer.PlayerGui.Visual:Destroy()
            end
        elseif gameRunningValue.Value then
            status = "Farming stage"
            webhookSent = false
        end
    end)

    -- Main cycle
    while true do
        while not inGame() do
            sellAllPortals()
            autoBuyMerchant()
            
            if getMerchantResetSeconds() <= 20 then
                teleportToLobby()
                task.wait(30)
                break
            end
            
            joinTokyoGhoul()
            task.wait(3)
        end

        while inGame() do
            if not autoPlayBool.Value then
                AutoPlayRemote:FireServer()
                task.wait(0.5)
            end
            
            VotePlayingRemote:FireServer()
            task.wait(1)
            VoteRetryRemote:FireServer()
            task.wait(2)
        end
        
        task.wait(5)
    end
end
