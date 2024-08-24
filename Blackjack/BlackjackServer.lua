--Made by Manmadedrummer for Araxia Server

local AIO = AIO or require("AIO")

-- Register the NPC with ID 1000000
local NPC_ID = 1000000

local BlackjackGame = {}

-- Define the game cost in copper (500 gold)
local GAME_COST = 5000000  -- 500 gold in copper
local BET_COST = 2000000  -- 200 gold in copper

-- Define what happens when the player interacts with the NPC
function BlackjackGame.OnGossipHello(event, player, creature)
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, "Play Blackjack (Cost: 500g)", 0, 1)
    player:GossipMenuAddItem(0, "Rules of Blackjack", 0, 2)
    player:GossipSendMenu(1, creature)
end

-- Handle the player's selection from the gossip menu
function BlackjackGame.OnGossipSelect(event, player, creature, sender, intid, code, menu_id)
    if intid == 1 then
        -- Check if the player has enough gold
        if player:GetCoinage() >= GAME_COST then
            player:ModifyMoney(-GAME_COST)  -- Deduct 500 gold
            AIO.Handle(player, "Blackjack", "ShowBlackjackFrame")
        else
            player:SendBroadcastMessage("|cffff7f00You don't have enough gold to play!|r")
        end
    elseif intid == 2 then
        -- Display the rules
        player:GossipClearMenu()
        player:GossipMenuAddItem(0, "Back", 0, 1)
        player:GossipSendMenu(1, creature)

        player:SendBroadcastMessage("Welcome to Blackjack!")
        player:SendBroadcastMessage("Rules:")
        player:SendBroadcastMessage("1. The goal is to get as close to 21 as possible without going over.")
        player:SendBroadcastMessage("2. The dealer draws until they reach at least 17.")
        player:SendBroadcastMessage("3. You can draw up to 4 cards.")
        player:SendBroadcastMessage("4. You start with 1 card and can place a bet before drawing your second card.")
        player:SendBroadcastMessage("5. The Bet button is disabled after drawing the second card.")
        player:SendBroadcastMessage("6. If you go over 21, you lose, and the dealer wins.")
        player:SendBroadcastMessage("7. If you stand, the dealer draws cards. If the dealer goes over 21, you win.")
        player:SendBroadcastMessage("8. If both you and the dealer stand, the closest to 21 wins.")
        player:SendBroadcastMessage("9. A tie results in a win for the dealer.")
        player:SendBroadcastMessage("10. Enjoy the game!")
    end
    player:GossipComplete()
end

-- Handle starting the game and deducting 500 gold
function BlackjackGame.HandleStartGame(player)
    player:ModifyMoney(-GAME_COST)  -- Deduct 500 gold
end

-- Handle placing a bet and deducting 200 gold
function BlackjackGame.HandleBet(player, betAmount)
    player:ModifyMoney(-BET_COST)  -- Deduct 200 gold
end

-- Handle playing a sound
function BlackjackGame.HandlePlaySound(player, soundId)
    player:PlayDirectSound(soundId)
end

-- Handle the player drawing a card
function BlackjackGame.HandleDrawCard(player)
    player:PlayDirectSound(796)  -- Play draw card sound
end

-- Handle the player winning
function BlackjackGame.HandlePlayerWin(player, betAmount)
    local rewardAmount = betAmount + GAME_COST  -- Add the bet amount and 500 gold
    player:ModifyMoney(rewardAmount)
    SendWorldMessage("|cff00ff00" .. player:GetName() .. " wins " .. (rewardAmount / 10000) .. " gold in Blackjack!|r")
end

-- Register the gossip events for the NPC
RegisterCreatureGossipEvent(NPC_ID, 1, BlackjackGame.OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, BlackjackGame.OnGossipSelect)

-- Register the AIO handler
AIO.AddHandlers("Blackjack", BlackjackGame)
