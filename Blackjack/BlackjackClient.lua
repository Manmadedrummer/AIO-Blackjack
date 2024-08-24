--Made by Manmadedrummer for Araxia Server

local AIO = AIO or require("AIO")

if AIO.AddAddon() then
    return
end

local BlackjackHandler = AIO.AddHandlers("Blackjack", {})

-- Declare buttons and game state variables at the top to avoid nil errors
local drawButton, standButton, betButton, playAgainButton
local gameActive = true  -- Flag to track if the game is active
local playerCardFrames = {}  -- Stores player card frames for easy reset
local dealerCardFrames = {}  -- Stores dealer card frames for easy reset
local currentBet = 0  -- Track current bet amount

-- Function to disable buttons after the game ends
local function DisableButtons()
    if drawButton then drawButton:Disable() end
    if standButton then standButton:Disable() end
    if betButton then betButton:Disable() end
end

-- Function to enable buttons for a new game
local function EnableButtons()
    if drawButton then drawButton:Enable() end
    if standButton then standButton:Enable() end
    if betButton then betButton:Enable() end
end

-- Function to clear all existing card frames
local function ClearCardFrames()
    for _, frame in ipairs(playerCardFrames) do
        frame:Hide()
    end
    for _, frame in ipairs(dealerCardFrames) do
        frame:Hide()
    end
    playerCardFrames = {}
    dealerCardFrames = {}
end

-- Complete mapping of card values to their image file paths
local cardImagePaths = {
    -- Clubs
    ["Club_2"] = "Interface\\Cards\\Club_2.blp",
    ["Club_3"] = "Interface\\Cards\\Club_3.blp",
    ["Club_4"] = "Interface\\Cards\\Club_4.blp",
    ["Club_5"] = "Interface\\Cards\\Club_5.blp",
    ["Club_6"] = "Interface\\Cards\\Club_6.blp",
    ["Club_7"] = "Interface\\Cards\\Club_7.blp",
    ["Club_8"] = "Interface\\Cards\\Club_8.blp",
    ["Club_9"] = "Interface\\Cards\\Club_9.blp",
    ["Club_10"] = "Interface\\Cards\\Club_10.blp",
    ["Club_J"] = "Interface\\Cards\\Club_11.blp",  -- Jack
    ["Club_Q"] = "Interface\\Cards\\Club_12.blp",  -- Queen
    ["Club_K"] = "Interface\\Cards\\Club_13.blp",  -- King
    ["Club_A"] = "Interface\\Cards\\Club_14.blp",  -- Ace

    -- Diamonds
    ["Diamond_2"] = "Interface\\Cards\\Diamond_2.blp",
    ["Diamond_3"] = "Interface\\Cards\\Diamond_3.blp",
    ["Diamond_4"] = "Interface\\Cards\\Diamond_4.blp",
    ["Diamond_5"] = "Interface\\Cards\\Diamond_5.blp",
    ["Diamond_6"] = "Interface\\Cards\\Diamond_6.blp",
    ["Diamond_7"] = "Interface\\Cards\\Diamond_7.blp",
    ["Diamond_8"] = "Interface\\Cards\\Diamond_8.blp",
    ["Diamond_9"] = "Interface\\Cards\\Diamond_9.blp",
    ["Diamond_10"] = "Interface\\Cards\\Diamond_10.blp",
    ["Diamond_J"] = "Interface\\Cards\\Diamond_11.blp",  -- Jack
    ["Diamond_Q"] = "Interface\\Cards\\Diamond_12.blp",  -- Queen
    ["Diamond_K"] = "Interface\\Cards\\Diamond_13.blp",  -- King
    ["Diamond_A"] = "Interface\\Cards\\Diamond_14.blp",  -- Ace

    -- Hearts
    ["Hearts_2"] = "Interface\\Cards\\Hearts_2.blp",
    ["Hearts_3"] = "Interface\\Cards\\Hearts_3.blp",
    ["Hearts_4"] = "Interface\\Cards\\Hearts_4.blp",
    ["Hearts_5"] = "Interface\\Cards\\Hearts_5.blp",
    ["Hearts_6"] = "Interface\\Cards\\Hearts_6.blp",
    ["Hearts_7"] = "Interface\\Cards\\Hearts_7.blp",
    ["Hearts_8"] = "Interface\\Cards\\Hearts_8.blp",
    ["Hearts_9"] = "Interface\\Cards\\Hearts_9.blp",
    ["Hearts_10"] = "Interface\\Cards\\Hearts_10.blp",
    ["Hearts_J"] = "Interface\\Cards\\Hearts_11.blp",  -- Jack
    ["Hearts_Q"] = "Interface\\Cards\\Hearts_12.blp",  -- Queen
    ["Hearts_K"] = "Interface\\Cards\\Hearts_13.blp",  -- King
    ["Hearts_A"] = "Interface\\Cards\\Hearts_14.blp",  -- Ace

    -- Spades
    ["Spades_2"] = "Interface\\Cards\\Spades_2.blp",
    ["Spades_3"] = "Interface\\Cards\\Spades_3.blp",
    ["Spades_4"] = "Interface\\Cards\\Spades_4.blp",
    ["Spades_5"] = "Interface\\Cards\\Spades_5.blp",
    ["Spades_6"] = "Interface\\Cards\\Spades_6.blp",
    ["Spades_7"] = "Interface\\Cards\\Spades_7.blp",
    ["Spades_8"] = "Interface\\Cards\\Spades_8.blp",
    ["Spades_9"] = "Interface\\Cards\\Spades_9.blp",
    ["Spades_10"] = "Interface\\Cards\\Spades_10.blp",
    ["Spades_J"] = "Interface\\Cards\\Spades_11.blp",  -- Jack
    ["Spades_Q"] = "Interface\\Cards\\Spades_12.blp",  -- Queen
    ["Spades_K"] = "Interface\\Cards\\Spades_13.blp",  -- King
    ["Spades_A"] = "Interface\\Cards\\Spades_14.blp",  -- Ace
}

-- Function to create and display the Blackjack game frame
local function CreateBlackjackFrame()
    -- Create the main frame
    local frame = CreateFrame("Frame", "BlackjackFrame", UIParent)
    frame:SetSize(720, 520)  -- Frame size
    frame:SetPoint("CENTER", UIParent, "CENTER")

    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0, 0, 0, 1)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT")

    -- Create the player's and dealer's hands tables to hold drawn cards
    local playerHand = {}
    local dealerHand = {}

    -- Create FontStrings to display the values of the hands
    local dealerValueText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    dealerValueText:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -25)
    dealerValueText:SetText("Dealer Value: 0")

    local playerValueText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    playerValueText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 25)
    playerValueText:SetText("Player Value: 0")

    -- Create FontString to display the bet amount
    local betValueText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    betValueText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 25)
    betValueText:SetText("Bet: 0g")

    -- Function to create a label and a card next to it
    local function CreateLabelAndCard(labelText, card, parentFrame, labelX, labelY, cardX, cardOffset, isDealer)
        -- Create the label
        local label = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", labelX, labelY)
        label:SetText(labelText)

        -- Create the card next to the label
        local cardSize = 128
        local cardFrame = CreateFrame("Frame", nil, parentFrame)
        cardFrame:SetSize(cardSize, cardSize)
        cardFrame:SetPoint("TOPLEFT", label, "TOPRIGHT", cardX + cardOffset, 0)

        local texture = cardFrame:CreateTexture(nil, "BACKGROUND")
        texture:SetAllPoints(cardFrame)

        -- Get the direct image path from the mapping
        local imagePath = cardImagePaths[card.suit .. "_" .. card.displayValue]

        if texture then
            texture:SetTexture(imagePath)
        else
            print("Error: Could not find card image at path: " .. imagePath)
        end

        cardFrame.texture = texture

        -- Add to appropriate card frame list
        if isDealer then
            table.insert(dealerCardFrames, cardFrame)
        else
            table.insert(playerCardFrames, cardFrame)
        end
    end

    -- Function to generate a random card with correct values
    local function GetRandomCard(excludeCard)
        local suits = {"Club", "Diamond", "Hearts", "Spades"}
        local values = {"2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"}

        local card
        repeat
            local suit = suits[math.random(#suits)]
            local value = values[math.random(#values)]

            card = { suit = suit, displayValue = value }
        until not (excludeCard and excludeCard.suit == card.suit and excludeCard.displayValue == card.displayValue)

        return card
    end

    -- Function to calculate the total value of a hand
    local function CalculateHandValue(hand)
        local total = 0
        local aces = 0

        for _, card in ipairs(hand) do
            local value = card.displayValue
            if value == "J" or value == "Q" or value == "K" then
                total = total + 10
            elseif value == "A" then
                total = total + 11
                aces = aces + 1
            else
                total = total + tonumber(value)
            end
        end

        -- Adjust for aces
        while total > 21 and aces > 0 do
            total = total - 10
            aces = aces - 1
        end

        return total
    end

    -- Function to start a new game by randomizing the dealer and player cards
    local function StartNewGame()
        gameActive = true  -- Set the game as active
        currentBet = 0  -- Reset the current bet
        betValueText:SetText("Bet: 0g")  -- Reset bet display
        ClearCardFrames()  -- Clear any existing cards from the previous game

        -- Generate two random cards for the dealer
        local dealerCard1 = GetRandomCard()
        local dealerCard2 = GetRandomCard(dealerCard1)
        dealerHand = {dealerCard1, dealerCard2}

        -- Generate one random card for the player
        local playerCard1 = GetRandomCard(dealerCard1)
        playerHand = {playerCard1}

        -- Display the dealer's label and cards
        CreateLabelAndCard("Dealer:", dealerCard1, frame, 20, -40, 10, 0, true)

        -- Display the player's label and cards
        CreateLabelAndCard("Player:", playerCard1, frame, 20, -320, 10, 0, false)

        -- Update the displayed hand values
        dealerValueText:SetText("Dealer Value: " .. CalculateHandValue({dealerCard1}))
        playerValueText:SetText("Player Value: " .. CalculateHandValue(playerHand))

        EnableButtons()  -- Re-enable the buttons for a new game
        playAgainButton:Disable()  -- Disable play again until the game is over
    end

    -- Function to handle the drawing of an additional card for the player
    local function DrawCardForPlayer()
        if gameActive and #playerHand < 4 then  -- Limiting the player to drawing a maximum of 4 cards
            -- Generate a new card for the player
            local newCard = GetRandomCard()

            -- Add the new card to the player's hand
            table.insert(playerHand, newCard)

            -- Display the new card next to the previous ones
            CreateLabelAndCard("", newCard, frame, 0, -320, 150, (#playerHand - 1) * 140, false)

            -- Update the player's hand value display
            playerValueText:SetText("Player Value: " .. CalculateHandValue(playerHand))

            -- Request the server to play the draw card sound
            AIO.Handle("Blackjack", "HandleDrawCard")

            -- Check if the player busts
            if CalculateHandValue(playerHand) > 21 then
                print("Player busts! |cffFF0000Dealer wins.|r")  -- Red text for dealer win
                gameActive = false  -- Deactivate the game
                DisableButtons()
                playAgainButton:Enable()  -- Enable the play again button
            end
        elseif not gameActive then
            print("The game is over. Please close the frame and start a new game.")
        else
            print("|cffff69b4Player cannot draw more than 4 cards.|r")
        end
    end

    -- Function to handle the dealer's actions after the player stands
    local function DealerTurn()
        if gameActive then
            -- Reveal the dealer's second card
            CreateLabelAndCard("", dealerHand[2], frame, 0, -40, 150, 0, true)

            -- Continue drawing cards for the dealer until the total is 17 or more
            while CalculateHandValue(dealerHand) < 17 do
                local newCard = GetRandomCard()
                table.insert(dealerHand, newCard)
                CreateLabelAndCard("", newCard, frame, 0, -40, 150, (#dealerHand - 2) * 140, true)
            end

            -- Update the dealer's hand value display
            dealerValueText:SetText("Dealer Value: " .. CalculateHandValue(dealerHand))

            -- Determine the winner and display the result
            local playerTotal = CalculateHandValue(playerHand)
            local dealerTotal = CalculateHandValue(dealerHand)

            if playerTotal > 21 then
                print("Player busts! |cffFF0000Dealer wins.|r")
            elseif dealerTotal > 21 or playerTotal > dealerTotal then
                print("Player wins!")
                AIO.Handle("Blackjack", "HandlePlayerWin", currentBet)
            elseif playerTotal == dealerTotal then
                print("|cffFF7F00It's a tie! Dealer wins.|r")
            else
                print("|cffFF0000Dealer wins.|r")
            end

            gameActive = false  -- Deactivate the game after dealer's turn
            DisableButtons()
            playAgainButton:Enable()  -- Enable the play again button
        else
            print("The game is over. Please close the frame and start a new game.")
        end
    end

    -- Function to handle betting
    local function PlaceBet()
        if gameActive and #playerHand == 1 then  -- Allow betting only before drawing the second card
            local betAmount = 200 * 10000  -- 200 gold in copper
            currentBet = currentBet + betAmount
            betValueText:SetText("Bet: " .. (currentBet / 10000) .. "g")  -- Update bet amount display in gold

            -- Deduct the bet amount from the player's money
            AIO.Handle("Blackjack", "HandleBet", betAmount)

            -- Play the sound when the bet is placed
            AIO.Handle("Blackjack", "HandlePlaySound", 895)
        else
            print("|cffff69b4You can only bet before drawing the second card.|r")
        end
    end

    -- Create a button for drawing a card
    drawButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    drawButton:SetSize(100, 30)
    drawButton:SetPoint("CENTER", frame, "CENTER", -100, -40)
    drawButton:SetText("Draw Card")
    drawButton:SetScript("OnClick", function()
        if gameActive then
            DrawCardForPlayer()
        else
            DisableButtons()
        end
    end)

    -- Create a button for standing (ending the player's turn)
    standButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    standButton:SetSize(100, 30)
    standButton:SetPoint("CENTER", frame, "CENTER", 20, -40)
    standButton:SetText("Stand")
    standButton:SetScript("OnClick", function()
        if gameActive then
            DealerTurn()
        else
            DisableButtons()
        end
    end)

    -- Create a button for betting
    betButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    betButton:SetSize(100, 30)
    betButton:SetPoint("CENTER", frame, "CENTER", 140, -40)
    betButton:SetText("Bet")
    betButton:SetScript("OnClick", function()
        if gameActive then
            PlaceBet()
        else
            DisableButtons()
        end
    end)

    -- Create a button for playing again
    playAgainButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    playAgainButton:SetSize(100, 30)
    playAgainButton:SetPoint("CENTER", frame, "CENTER", 260, -40)
    playAgainButton:SetText("Play Again")
    playAgainButton:SetScript("OnClick", function()
        if not gameActive then
            AIO.Handle("Blackjack", "HandleStartGame")
            StartNewGame()
        else
            DisableButtons()
        end
    end)
    playAgainButton:Disable()  -- Initially disable the play again button

    -- Start the game for the first time when the frame is shown
    StartNewGame()

    frame:Show()
end

-- AIO handler function to trigger the frame display
function BlackjackHandler.ShowBlackjackFrame()
    CreateBlackjackFrame()
end