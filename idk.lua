-- MIH HUB Auto-Farm Script with FPS Boost
print("[DEBUG] Initializing MIH HUB Auto-Farm with FPS Boost...")

-- Configuration
getgenv().Webhook = "https://discord.com/api/webhooks/1364262297182404760/KkAgDEMLbUsfzpLBcW0JQLkrNWb9T_oPE1gGI77I94VntVRbSOu2yA-9UG51av-e198J"
getgenv().Priority_Item = "Trait Reroll"
print("[CONFIG] Webhook set:", getgenv().Webhook)
print("[CONFIG] Priority item:", getgenv().Priority_Item)

-- Wait for game to load
print("[INIT] Waiting for game to load...")
if not game:IsLoaded() then repeat task.wait() until game:IsLoaded() end
print("[INIT] Game loaded successfully!")

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PLAYER_NAME = LocalPlayer.Name
print("[PLAYER] Local player:", PLAYER_NAME)

-- Configuration
local MAIN_PLACE_ID = 72829404259339
local TARGET_WORLD = "TokyoGhoul"
local TARGET_CHAPTER = "TokyoGhoul_Chapter10"
local TARGET_DIFFICULTY = "Nightmare"
local PORTAL_TO_SELL = "Ghoul City Portal I"
print("[TARGET] World:", TARGET_WORLD)
print("[TARGET] Chapter:", TARGET_CHAPTER)
print("[TARGET] Difficulty:", TARGET_DIFFICULTY)

-- Remotes
local MerchantRemote = ReplicatedStorage.Remote.Server.Gameplay.Merchant
local PlayRoomEvent = ReplicatedStorage.Remote.Server.PlayRoom.Event
local VotePlayingRemote = ReplicatedStorage.Remote.Server.OnGame.Voting.VotePlaying
local VoteRetryRemote = ReplicatedStorage.Remote.Server.OnGame.Voting.VoteRetry
local AutoPlayRemote = ReplicatedStorage.Remote.Server.Units.AutoPlay
local SellRemote = ReplicatedStorage.Remote.Server.Items.Sell
print("[REMOTES] Loaded critical remotes")

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
print("[DATA] Player data paths initialized")

-- Create full-screen black overlay with MIH HUB in the center
print("[GUI] Creating full-screen black overlay...")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MIH_HUB_Overlay"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, 0, 1, 0)
frame.BackgroundTransparency = 0
frame.BackgroundColor3 = Color3.new(0, 0, 0)
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.new(0.5, 0, 0.5, 0)
title.Size = UDim2.new(0, 400, 0, 80)
title.Font = Enum.Font.GothamBlack
title.TextSize = 48
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "MIH HUB"
title.BackgroundTransparency = 1
title.Parent = frame
print("[GUI] Full-screen overlay created")

-- FPS Boost Functions (Optimized)
print("[FPS-BOOST] Applying performance optimizations...")

local function disableShadows()
    Lighting.GlobalShadows = false
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0
end

local function disableEffects()
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Smoke") or o:IsA("Fire") or o:IsA("Sparkles") then 
            o:Destroy()
        elseif o:IsA("Texture") or o:IsA("Decal") then 
            o:Destroy()
        elseif o:IsA("BasePart") then 
            o.Material = Enum.Material.SmoothPlastic
            o.CastShadow = false
            o.Reflectance = 0 
        end
    end
end

local function optimizeTerrain()
    local t = Workspace:FindFirstChildOfClass("Terrain")
    if t then 
        t.WaterWaveSize = 0
        t.WaterWaveSpeed = 0
        t.WaterReflectance = 0
        t.WaterTransparency = 1
        t.Decorations = false 
    end
end

local function disablePostProcessing()
    for _, e in ipairs(Lighting:GetDescendants()) do 
        if e:IsA("PostEffect") then e.Enabled = false end 
    end
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if sky then sky:Destroy() end
end

local function disableAnimations()
    for _, h in ipairs(Workspace:GetDescendants()) do 
        if h:IsA("Humanoid") then 
            for _, t in ipairs(h:GetPlayingAnimationTracks()) do 
                t:Stop(0) 
            end 
        end 
    end
    Workspace.DescendantAdded:Connect(function(o) 
        if o:IsA("AnimationTrack") then o:Stop(0) end 
    end)
end

local function optimizeCamera()
    local cam = workspace.CurrentCamera
    cam.FieldOfView = 70
    cam:GetPropertyChangedSignal("FieldOfView"):Connect(function() 
        cam.FieldOfView = 70 
    end)
end

local function muteAllSounds()
    for _, s in ipairs(Workspace:GetDescendants()) do 
        if s:IsA("Sound") then s.Volume = 0 end 
    end
end

local function optimizePhysics()
    workspace.PhysicsSteppingMode = Enum.PhysicsSteppingMode.Disabled
    workspace.SimulationRadius = 0
    workspace.SimulationRadiusMomentum = 0
end

local function optimizeNetwork()
    pcall(function() game.ReplicatedFirst:Destroy() end)
end

local function capGraphicsQuality()
    pcall(function() 
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
end

local function disableLensFlare()
    for _, e in ipairs(Lighting:GetDescendants()) do 
        if e:IsA("LensFlare") then e.Enabled = false end 
    end
end

local function disable3DChats()
    for _, c in ipairs(Workspace:GetDescendants()) do 
        if c.Name == "ChatMain" or c.Name == "Chat" then c:Destroy() end 
    end
end

-- Full Boost
local function fullBoost()
    disableShadows()
    disableEffects()
    optimizeTerrain()
    disablePostProcessing()
    disableAnimations()
    optimizeCamera()
    muteAllSounds()
    optimizePhysics()
    optimizeNetwork()
    capGraphicsQuality()
    disableLensFlare()
    disable3DChats()
    print("[FPS-BOOST] Full optimization applied")
end

-- Apply FPS boost
fullBoost()

-- Main script functions
local startTime = os.clock()
local status = "Initializing..."
print("[STATUS] " .. status)

-- Utility functions
local function inGame()
    local result = workspace:FindFirstChild("WayPoint") ~= nil
    print("[GAME-STATE] In game:", result)
    return result
end

local function getMerchantResetSeconds()
    local seconds = math.max(0, 3600 - (os.time() - hourReset.Value))
    print("[MERCHANT] Restock in:", seconds, "seconds")
    return seconds
end

-- Webhook function
local function sendWebhook(content, embed)
    if getgenv().Webhook == "" or not getgenv().Webhook then 
        print("[WEBHOOK] No webhook configured, skipping")
        return 
    end
    
    print("[WEBHOOK] Sending notification:", content)
    local data = {
        content = content,
        embeds = embed and {embed} or nil
    }
    
    local success, err = pcall(function()
        local requestFunc = http_request or request or syn.request
        if not requestFunc then return end
        
        local encoded = HttpService:JSONEncode(data)
        local response = requestFunc({
            Url = getgenv().Webhook,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = encoded
        })
    end)
    
    if not success then
        print("[WEBHOOK-ERROR] Failed to send:", err)
    end
end

local function getInventoryAmount(itemName)
    local found = playerData.Items:FindFirstChild(itemName)
    local amount = found and found.Amount.Value or 0
    print("[INVENTORY] Checking", itemName, "Amount:", amount)
    return amount
end

-- Core functions
local function teleportToLobby()
    status = "Teleporting to lobby"
    print("[STATUS] " .. status)
    local timeLeft = math.floor(getMerchantResetSeconds())
    
    print("[TELEPORT] Returning to lobby for merchant restock")
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
    print("[SELL] Attempting to sell portals")
    if inGame() then 
        print("[SELL] Skipping - currently in game")
        return 0, 0 
    end
    
    status = "Selling portals"
    print("[STATUS] " .. status)
    local portalItem = playerData.Items:FindFirstChild(PORTAL_TO_SELL)
    
    if not portalItem or portalItem.Amount.Value <= 0 then 
        print("[SELL] No portals to sell")
        return 0, 0 
    end
    
    local amountSold = portalItem.Amount.Value
    local goldBefore = goldStat.Value
    print("[SELL] Selling", amountSold, PORTAL_TO_SELL, "Gold before:", goldBefore)
    
    SellRemote:FireServer(portalItem, {Amount = amountSold})
    task.wait(0.5)
    
    local goldGained = goldStat.Value - goldBefore
    print("[SELL] Sold successfully! Gold gained:", goldGained, "Total gold:", goldStat.Value)
    
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
    print("[MERCHANT] Attempting auto-buy")
    if inGame() then 
        print("[MERCHANT] Skipping - currently in game")
        return 0, 0, 0, 0 
    end
    
    status = "Buying from merchant"
    print("[STATUS] " .. status)
    
    local rerollBefore = getInventoryAmount("Trait Reroll")
    local punkBefore = getInventoryAmount("Dr. Megga Punk")
    local boughtRerolls, boughtPunks = 0, 0
    
    -- Priority: Trait Rerolls
    if traitRerollData and traitRerollData.Quantity.Value > 0 then
        print("[MERCHANT] Buying priority item: Trait Reroll")
        for i = 1, math.min(5, traitRerollData.Quantity.Value) do
            if goldStat.Value < traitRerollData.CurrencyAmount.Value then 
                print("[MERCHANT] Insufficient gold for Trait Reroll")
                break 
            end
            
            MerchantRemote:FireServer("Trait Reroll", 1)
            boughtRerolls = boughtRerolls + 1
            task.wait(0.1)
        end
    end
    
    -- Secondary: Dr. Megga Punk
    if meggaPunkData and meggaPunkData.Quantity.Value > 0 then
        print("[MERCHANT] Buying secondary item: Dr. Megga Punk")
        for i = 1, math.min(5, meggaPunkData.Quantity.Value) do
            if goldStat.Value < meggaPunkData.CurrencyAmount.Value then 
                print("[MERCHANT] Insufficient gold for Dr. Megga Punk")
                break 
            end
            
            MerchantRemote:FireServer("Dr. Megga Punk", 1)
            boughtPunks = boughtPunks + 1
            task.wait(0.1)
        end
    end
    
    task.wait(0.5)
    local rerollAfter = getInventoryAmount("Trait Reroll")
    local punkAfter = getInventoryAmount("Dr. Megga Punk")
    
    print(string.format(
        "[MERCHANT] Purchase summary: Rerolls +%d (%d total) | Punks +%d (%d total)",
        rerollAfter - rerollBefore, rerollAfter,
        punkAfter - punkBefore, punkAfter
    ))
    
    if boughtRerolls > 0 or boughtPunks > 0 then
        sendWebhook("🛒 Merchant Purchase", {
            title = "Auto-Buy Completed",
            fields = {
                {name = "Trait Rerolls", value = "**+"..boughtRerolls.."** (Total: `"..rerollAfter.."`)", inline = true},
                {name = "Dr. Megga Punks", value = "**+"..boughtPunks.."** (Total: `"..punkAfter.."`)", inline = true},
                {name = "Next Restock", value = "**"..math.floor(getMerchantResetSeconds()/60).." minutes**", inline = false}
            },
            color = 0x3498DB,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        })
    end
    
    return boughtRerolls, rerollAfter, boughtPunks, punkAfter
end

local function joinTokyoGhoul()
    if inGame() then 
        print("[GAME] Already in game, skipping join")
        return 
    end
    
    status = "Joining game"
    print("[STATUS] " .. status)
    print("[GAME] Joining Tokyo Ghoul...")
    
    -- Batch all join commands
    PlayRoomEvent:FireServer("Create")
    task.wait(0.1)
    PlayRoomEvent:FireServer("Change-World", {World = TARGET_WORLD})
    task.wait(0.1)
    PlayRoomEvent:FireServer("Change-Chapter", {Chapter = TARGET_CHAPTER})
    task.wait(0.1)
    PlayRoomEvent:FireServer("Change-Difficulty", {Difficulty = TARGET_DIFFICULTY})
    task.wait(0.1)
    PlayRoomEvent:FireServer("Submit")
    task.wait(0.2)
    PlayRoomEvent:FireServer("Start")
    
    print("[GAME] Join sequence completed")
end

-- Main loop
print("[MAIN] Starting main loop...")
status = "Starting main loop"

-- Initial webhook
sendWebhook("🚀 Script Started", {
    title = "Auto-Farm Initialized",
    description = string.format("**Player:** %s\n**Target:** %s (%s)", PLAYER_NAME, TARGET_CHAPTER, TARGET_DIFFICULTY),
    color = 0x9B59B6,
    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
})

-- Stat tracking
local lastExp, lastGem, lastGold = expStat.Value, gemStat.Value, goldStat.Value
local webhookSent = false
print(string.format("[STATS] Initial values - Exp: %d, Gems: %d, Gold: %d", lastExp, lastGem, lastGold))

-- Game state listener
print("[LISTENER] Setting up game state listener...")
gameRunningValue:GetPropertyChangedSignal("Value"):Connect(function()
    if not gameRunningValue.Value and not webhookSent then
        status = "Processing rewards"
        print("[STATUS] " .. status)
        webhookSent = true
        task.wait(1.5)
        
        local expGain = expStat.Value - lastExp
        local gemGain = gemStat.Value - lastGem
        local goldGain = goldStat.Value - lastGold
        
        print(string.format(
            "[REWARDS] Stage cleared! Exp: +%d, Gems: +%d, Gold: +%d",
            expGain, gemGain, goldGain
        ))
        
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
            print("[CLEANUP] Removed Visual GUI")
        end
    elseif gameRunningValue.Value then
        status = "Farming stage"
        print("[STATUS] " .. status)
        webhookSent = false
        print("[GAME] Game started")
    end
end)

-- Runtime display in console
task.spawn(function()
    while true do
        local seconds = os.clock() - startTime
        local hours = math.floor(seconds/3600)
        local minutes = math.floor((seconds%3600)/60)
        local secs = math.floor(seconds%60)
        print(string.format("[RUNTIME] %02d:%02d:%02d | %s", hours, minutes, secs, status))
        task.wait(10)
    end
end)

-- Optimized main cycle
print("[CORE] Entering main farming loop")
while true do
    -- LOBBY PHASE
    print("[PHASE] Entering lobby phase")
    while not inGame() do
        sellAllPortals()
        autoBuyMerchant()
        
        -- Check if merchant will restock soon
        if getMerchantResetSeconds() <= 30 then
            print("[MERCHANT] Restock imminent, teleporting to refresh")
            teleportToLobby()
            task.wait(15)
            break
        end
        
        joinTokyoGhoul()
        task.wait(3)  -- Increased wait to prevent spamming
    end

    -- IN-GAME PHASE
    print("[PHASE] Entering game phase")
    while inGame() do
        -- Enable auto-play if not active
        if not autoPlayBool.Value then
            print("[AUTOPLAY] Enabling auto-play")
            AutoPlayRemote:FireServer()
        end
        
        -- Voting system
        print("[VOTE] Sending votes")
        VotePlayingRemote:FireServer()
        task.wait(0.5)
        VoteRetryRemote:FireServer()
        task.wait(2.5)  -- Increased delay between votes
    end
    
    print("[TRANSITION] Between phases, waiting...")
    task.wait(3)
end
