-- MIH HUB Auto-Farm Script (Headless Console Version)
print("[MIH HUB] Initializing auto-farm...")

-- Configuration
getgenv().Webhook = "https://discord.com/api/webhooks/1364262297182404760/KkAgDEMLbUsfzpLBcW0JQLkrNWb9T_oPE1gGI77I94VntVRbSOu2yA-9UG51av-e198J"
getgenv().Priority_Item = "Trait Reroll"
print("[CONFIG] Webhook:", getgenv().Webhook)
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

-- Main script variables
local startTime = os.clock()
local status = "Initializing..."
print("[STATUS] " .. status)

-- Utility functions
local function inGame()
    return workspace:FindFirstChild("WayPoint") ~= nil
end

local function getMerchantResetSeconds()
    return math.max(0, 3600 - (os.time() - hourReset.Value))
end

-- Webhook function
local function sendWebhook(content, embed)
    if getgenv().Webhook == "" or not getgenv().Webhook then return end
    
    local data = {
        content = content,
        embeds = embed and {embed} or nil
    }
    
    local success, err = pcall(function()
        local requestFunc = http_request or request or syn.request
        if not requestFunc then return end
        
        local encoded = HttpService:JSONEncode(data)
        requestFunc({
            Url = getgenv().Webhook,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = encoded
        })
    end)
    
    if not success then
        print("[WEBHOOK-ERROR] Failed to send:", err)
    end
end

local function getInventoryAmount(itemName)
    local found = playerData.Items:FindFirstChild(itemName)
    return found and found.Amount.Value or 0
end

-- Core functions
local function teleportToLobby()
    status = "Teleporting to lobby"
    print("[STATUS] " .. status)
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
    print("[STATUS] " .. status)
    local portalItem = playerData.Items:FindFirstChild(PORTAL_TO_SELL)
    if not portalItem or portalItem.Amount.Value <= 0 then return 0, 0 end
    
    local amountSold = portalItem.Amount.Value
    local goldBefore = goldStat.Value
    SellRemote:FireServer(portalItem, {Amount = amountSold})
    task.wait(0.5)
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
    print("[STATUS] " .. status)
    
    local rerollBefore = getInventoryAmount("Trait Reroll")
    local punkBefore = getInventoryAmount("Dr. Megga Punk")
    local boughtRerolls, boughtPunks = 0, 0
    
    -- Priority: Trait Rerolls
    if traitRerollData and traitRerollData.Quantity.Value > 0 then
        for i = 1, math.min(5, traitRerollData.Quantity.Value) do
            if goldStat.Value < traitRerollData.CurrencyAmount.Value then break end
            MerchantRemote:FireServer("Trait Reroll", 1)
            boughtRerolls = boughtRerolls + 1
            task.wait(0.1)
        end
    end
    
    -- Secondary: Dr. Megga Punk
    if meggaPunkData and meggaPunkData.Quantity.Value > 0 then
        for i = 1, math.min(5, meggaPunkData.Quantity.Value) do
            if goldStat.Value < meggaPunkData.CurrencyAmount.Value then break end
            MerchantRemote:FireServer("Dr. Megga Punk", 1)
            boughtPunks = boughtPunks + 1
            task.wait(0.1)
        end
    end
    
    task.wait(0.5)
    local rerollAfter = getInventoryAmount("Trait Reroll")
    local punkAfter = getInventoryAmount("Dr. Megga Punk")
    
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
    if inGame() then return end
    
    status = "Joining game"
    print("[STATUS] " .. status)
    
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
gameRunningValue:GetPropertyChangedSignal("Value"):Connect(function()
    if not gameRunningValue.Value and not webhookSent then
        status = "Processing rewards"
        print("[STATUS] " .. status)
        webhookSent = true
        task.wait(1.5)
        
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
        print("[STATUS] " .. status)
        webhookSent = false
    end
end)

-- Runtime display
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
while true do
    -- LOBBY PHASE
    while not inGame() do
        sellAllPortals()
        autoBuyMerchant()
        
        -- Check if merchant will restock soon
        if getMerchantResetSeconds() <= 30 then
            teleportToLobby()
            task.wait(15)
            break
        end
        
        joinTokyoGhoul()
        task.wait(3)
    end

    -- IN-GAME PHASE
    while inGame() do
        -- Enable auto-play if not active
        if not autoPlayBool.Value then
            AutoPlayRemote:FireServer()
        end
        
        -- Voting system
        VotePlayingRemote:FireServer()
        task.wait(0.5)
        VoteRetryRemote:FireServer()
        task.wait(2.5)
    end
    
    task.wait(3)
end
