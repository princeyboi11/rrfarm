-- MIH HUB Auto-Farm Script (Fixed Teleportation)
print("[MIH HUB] Initializing auto-farm...")

-- Configuration
getgenv().Webhook = "https://discord.com/api/webhooks/1364262297182404760/KkAgDEMLbUsfzpLBcW0JQLkrNWb9T_oPE1gGI77I94VntVRbSOu2yA-9UG51av-e198J"
getgenv().Priority_Item = "Trait Reroll"
local MAIN_PLACE_ID = 72829404259339
local TARGET_WORLD = "TokyoGhoul"
local TARGET_CHAPTER = "TokyoGhoul_Chapter10"
local TARGET_DIFFICULTY = "Nightmare"
local PORTAL_TO_SELL = "Ghoul City Portal I"

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PLAYER_NAME = LocalPlayer.Name

-- Wait for game to load
if not game:IsLoaded() then repeat task.wait() until game:IsLoaded() end

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

-- Main variables
local startTime = os.clock()
local status = "Initializing..."
local teleporting = false

-- Utility functions
local function inGame()
    return workspace:FindFirstChild("WayPoint") ~= nil
end

local function getMerchantResetSeconds()
    return math.max(0, 3600 - (os.time() - hourReset.Value))
end

local function sendWebhook(content, embed)
    if not getgenv().Webhook then return end
    pcall(function()
        local request = (http_request or request or syn.request)
        request({
            Url = getgenv().Webhook,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                content = content,
                embeds = embed and {embed} or nil
            })
        })
    end)
end

local function getInventoryAmount(itemName)
    local item = playerData.Items:FindFirstChild(itemName)
    return item and item.Amount.Value or 0
end

-- Core functions
local function teleportToLobby()
    if teleporting then return end
    teleporting = true
    status = "Teleporting to lobby"
    
    sendWebhook("🔄 Teleporting to Lobby", {
        title = "Merchant Restock Cycle",
        description = string.format("**%s** is returning to lobby for merchant restock", PLAYER_NAME),
        color = 0xFFA500
    })
    
    task.wait(1)
    local success, err = pcall(function()
        TeleportService:Teleport(MAIN_PLACE_ID)
    end)
    
    if not success then
        warn("Teleport failed: "..tostring(err))
        task.wait(5)
        teleporting = false
        teleportToLobby() -- Retry
    else
        task.wait(10) -- Wait after teleport
        teleporting = false
    end
end

local function sellAllPortals()
    if inGame() then return 0, 0 end
    local portalItem = playerData.Items:FindFirstChild(PORTAL_TO_SELL)
    if not portalItem or portalItem.Amount.Value <= 0 then return 0, 0 end
    
    local amountSold = portalItem.Amount.Value
    local goldBefore = goldStat.Value
    SellRemote:FireServer(portalItem, {Amount = amountSold})
    task.wait(0.5)
    
    sendWebhook("💰 Portal Sold", {
        title = "Auto-Sell Completed",
        fields = {
            {name = "Amount", value = "`"..amountSold.."`", inline = true},
            {name = "Gold Gained", value = "**+"..(goldStat.Value - goldBefore).."**", inline = true}
        },
        color = 0x00FF00
    })
    
    return amountSold, goldStat.Value - goldBefore
end

local function autoBuyMerchant()
    if inGame() then return end
    
    -- Buy Trait Rerolls
    if traitRerollData and traitRerollData.Quantity.Value > 0 then
        for i = 1, math.min(5, traitRerollData.Quantity.Value) do
            if goldStat.Value >= traitRerollData.CurrencyAmount.Value then
                MerchantRemote:FireServer("Trait Reroll", 1)
                task.wait(0.1)
            end
        end
    end
    
    -- Buy Dr. Megga Punks
    if meggaPunkData and meggaPunkData.Quantity.Value > 0 then
        for i = 1, math.min(5, meggaPunkData.Quantity.Value) do
            if goldStat.Value >= meggaPunkData.CurrencyAmount.Value then
                MerchantRemote:FireServer("Dr. Megga Punk", 1)
                task.wait(0.1)
            end
        end
    end
    
    task.wait(0.5)
end

local function joinTokyoGhoul()
    if inGame() then return end
    
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
sendWebhook("🚀 Script Started", {
    title = "Auto-Farm Initialized",
    description = string.format("**Player:** %s\n**Target:** %s (%s)", PLAYER_NAME, TARGET_CHAPTER, TARGET_DIFFICULTY),
    color = 0x9B59B6
})

local lastExp, lastGem, lastGold = expStat.Value, gemStat.Value, goldStat.Value
local webhookSent = false

gameRunningValue:GetPropertyChangedSignal("Value"):Connect(function()
    if not gameRunningValue.Value and not webhookSent then
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
                    {name = "EXP", value = "**+"..expGain.."**", inline = true},
                    {name = "Gems", value = "**+"..gemGain.."**", inline = true},
                    {name = "Gold", value = "**+"..goldGain.."**", inline = true}
                },
                color = 0xFFD700
            })
        end
    elseif gameRunningValue.Value then
        webhookSent = false
    end
end)

while true do
    -- Lobby phase
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

    -- In-game phase
    while inGame() do
        if not autoPlayBool.Value then
            AutoPlayRemote:FireServer()
        end
        
        VotePlayingRemote:FireServer()
        task.wait(0.5)
        VoteRetryRemote:FireServer()
        task.wait(2.5)
    end
    
    task.wait(3)
end
