-- Scoundrel - Game state management
-- Pure functions for state creation and constants

local Deck = require("deck")

local State = {}

--------------------------------------------------------------------------------
-- D.1: ROOM_SIZE constant
--------------------------------------------------------------------------------

State.ROOM_SIZE = 4

--------------------------------------------------------------------------------
-- D.2: MAX_HP constant (default starting/max health)
--------------------------------------------------------------------------------

State.MAX_HP = 20

--------------------------------------------------------------------------------
-- D.3: RunState enum-like table
-- Represents the current phase of the game
--------------------------------------------------------------------------------

State.RunState = {
    DEALING = "dealing",       -- Drawing cards into room
    AWAITING = "awaiting",     -- Waiting for player input
    RESOLVING = "resolving",   -- Processing a player action
    GAME_OVER = "gameOver",    -- Player lost (HP <= 0)
    VICTORY = "victory"        -- Player won (deck empty, room cleared)
}

--------------------------------------------------------------------------------
-- D.4-D.14: createNewGameState(seed)
-- Returns a fresh game state object with all required fields
--------------------------------------------------------------------------------

function State.createNewGameState(seed)
    -- Seed the RNG
    math.randomseed(seed)
    
    -- Reset card counter for clean unique IDs
    local Cards = require("cards")
    Cards.resetCardCounter()
    
    -- Create and shuffle the Scoundrel deck
    local deck = Deck.createScoundrelDeck()
    
    -- Debug assertion: verify deck has no duplicates before shuffle
    if State.DEBUG_DEAL then
        local seenIds = {}
        local seenCards = {}
        for i, card in ipairs(deck) do
            if seenIds[card.id] then
                print("=== DECK CREATION BUG: Duplicate ID before shuffle! ===")
                print("Card: " .. Cards.cardToString(card) .. " id=" .. card.id)
                print("========================================================")
            end
            seenIds[card.id] = true
            
            local cardStr = Cards.cardToString(card)
            if seenCards[cardStr] then
                print("=== DECK CREATION BUG: Duplicate card before shuffle! ===")
                print("Card: " .. cardStr)
                print("=========================================================")
            end
            seenCards[cardStr] = true
        end
        print("Deck created with " .. #deck .. " cards, all unique IDs verified")
    end
    
    Deck.shuffle(deck)
    
    -- Build initial state
    local state = {
        -- Meta
        seed = seed,
        
        -- D.5: Player HP
        hp = State.MAX_HP,
        
        -- D.6: Max HP
        maxHp = State.MAX_HP,
        
        -- D.7: Draw deck (shuffled)
        deck = deck,
        
        -- D.8: Discard pile
        discard = {},
        
        -- D.9: Current room
        room = {
            cards = {},
            fleeUsed = false
        },
        
        -- D.10: Equipped weapon (nil = no weapon)
        weapon = nil,
        
        -- D.11: Current run state
        runState = State.RunState.DEALING,
        
        -- D.12: Last action log line
        lastLogLine = "",
        
        -- D.13: Current error message (if any)
        errorMessage = nil,
        
        -- D.14: Turn flags for rule-specific state
        -- lastMonsterSlain tracks the weapon's "max target" rule:
        -- After slaying a monster with a weapon, you can only use that weapon
        -- on monsters of LOWER power. Resets when equipping a new weapon.
        turnFlags = {
            lastMonsterSlain = nil
        }
    }
    
    return state
end

--------------------------------------------------------------------------------
-- E.1: roomCardCount(state)
-- Returns the number of cards currently in the room (non-nil slots)
--------------------------------------------------------------------------------

function State.roomCardCount(state)
    local count = 0
    for i = 1, State.ROOM_SIZE do
        if state.room.cards[i] then
            count = count + 1
        end
    end
    return count
end

--------------------------------------------------------------------------------
-- E.1b: roomIsFull(state)
-- Returns true if room has ROOM_SIZE cards (all slots filled)
--------------------------------------------------------------------------------

function State.roomIsFull(state)
    return State.roomCardCount(state) >= State.ROOM_SIZE
end

--------------------------------------------------------------------------------
-- E.2: deckIsEmpty(state)
-- Returns true if deck has no cards
--------------------------------------------------------------------------------

function State.deckIsEmpty(state)
    return #state.deck == 0
end

--------------------------------------------------------------------------------
-- E.3: roomIsEmpty(state)
-- Returns true if room has no cards (all slots empty)
--------------------------------------------------------------------------------

function State.roomIsEmpty(state)
    return State.roomCardCount(state) == 0
end

--------------------------------------------------------------------------------
-- E.4: dealOneToRoom(state)
-- Draws one card from deck into the first empty slot (1-4)
-- Returns newState (pure function - does not mutate input)
--------------------------------------------------------------------------------

-- Debug flag for deal assertions
State.DEBUG_DEAL = true

function State.dealOneToRoom(state)
    if State.deckIsEmpty(state) or State.roomIsFull(state) then
        return state
    end
    
    -- Copy state
    local newState = State.shallowCopyState(state)
    
    -- Find first empty slot
    local slot = nil
    for i = 1, State.ROOM_SIZE do
        if not newState.room.cards[i] then
            slot = i
            break
        end
    end
    
    if not slot then return state end  -- No empty slot (shouldn't happen)
    
    -- Draw card from deck and place in slot
    local card = table.remove(newState.deck)
    
    -- Debug assertion: check if this card matches any existing room card
    if State.DEBUG_DEAL then
        local Cards = require("cards")
        for i = 1, State.ROOM_SIZE do
            local existingCard = newState.room.cards[i]
            if existingCard then
                if existingCard.id == card.id then
                    print("=== DEAL BUG: Drawing card with same ID as room card! ===")
                    print("Drawn card: " .. Cards.cardToString(card) .. " id=" .. card.id)
                    print("Existing card at slot " .. i .. ": " .. Cards.cardToString(existingCard) .. " id=" .. existingCard.id)
                    print("=========================================================")
                elseif existingCard.suit == card.suit and existingCard.rank == card.rank then
                    print("=== DEAL BUG: Drawing duplicate card (same suit+rank)! ===")
                    print("Drawn card: " .. Cards.cardToString(card) .. " id=" .. card.id)
                    print("Existing card at slot " .. i .. ": " .. Cards.cardToString(existingCard) .. " id=" .. existingCard.id)
                    print("==========================================================")
                end
            end
        end
    end
    
    newState.room.cards[slot] = card
    
    return newState
end

--------------------------------------------------------------------------------
-- E.5: dealRoomUpToFull(state)
-- Fills room until full or deck empty
-- Returns newState
--------------------------------------------------------------------------------

function State.dealRoomUpToFull(state)
    local newState = state
    while not State.roomIsFull(newState) and not State.deckIsEmpty(newState) do
        newState = State.dealOneToRoom(newState)
    end
    return newState
end

--------------------------------------------------------------------------------
-- E.6: removeRoomCard(state, index)
-- Sets slot to nil (card stays in its position, doesn't shift)
-- Returns (newState, removedCard) or (state, nil) if invalid index
--------------------------------------------------------------------------------

function State.removeRoomCard(state, index)
    if index < 1 or index > State.ROOM_SIZE then
        return state, nil
    end
    
    -- Check if there's a card at this index
    if not state.room.cards[index] then
        return state, nil
    end
    
    -- Copy state
    local newState = State.shallowCopyState(state)
    
    -- Get the card and set slot to nil
    local removedCard = newState.room.cards[index]
    newState.room.cards[index] = nil
    
    return newState, removedCard
end

--------------------------------------------------------------------------------
-- E.7: pushToDiscard(state, card)
-- Adds card to discard pile
-- Returns newState
--------------------------------------------------------------------------------

function State.pushToDiscard(state, card)
    local newState = State.shallowCopyState(state)
    table.insert(newState.discard, card)
    return newState
end

--------------------------------------------------------------------------------
-- E.8: setLog(state, text)
-- Updates the lastLogLine
-- Returns newState
--------------------------------------------------------------------------------

function State.setLog(state, text)
    local newState = State.shallowCopyState(state)
    newState.lastLogLine = text
    return newState
end

--------------------------------------------------------------------------------
-- E.9: setError(state, text)
-- Sets the error message
-- Returns newState
--------------------------------------------------------------------------------

function State.setError(state, text)
    local newState = State.shallowCopyState(state)
    newState.errorMessage = text
    return newState
end

--------------------------------------------------------------------------------
-- E.10: clearError(state)
-- Clears the error message
-- Returns newState
--------------------------------------------------------------------------------

function State.clearError(state)
    local newState = State.shallowCopyState(state)
    newState.errorMessage = nil
    return newState
end

--------------------------------------------------------------------------------
-- F.1: isValidRoomIndex(state, index)
-- Returns true if index is valid for the current room
--------------------------------------------------------------------------------

function State.isValidRoomIndex(state, index)
    -- Check if index is in range AND there's a card at that slot
    return index >= 1 and index <= State.ROOM_SIZE and state.room.cards[index] ~= nil
end

--------------------------------------------------------------------------------
-- F.2: canTakeFromRoom(state, index)
-- Returns (bool, reason) - whether player can take card at index
--------------------------------------------------------------------------------

function State.canTakeFromRoom(state, index)
    -- Check game state
    local canAct, reason = State.canAct(state)
    if not canAct then
        return false, reason
    end
    
    -- Check valid index
    if not State.isValidRoomIndex(state, index) then
        return false, "Invalid card index"
    end
    
    return true, nil
end

--------------------------------------------------------------------------------
-- F.3: canFleeFromRoom(state, index)
-- Returns (bool, reason) - whether player can flee with card at index
--------------------------------------------------------------------------------

function State.canFleeFromRoom(state, index)
    -- Check game state
    local canAct, reason = State.canAct(state)
    if not canAct then
        return false, reason
    end
    
    -- Check valid index
    if not State.isValidRoomIndex(state, index) then
        return false, "Invalid card index"
    end
    
    -- Check flee already used
    if state.room.fleeUsed then
        return false, "Already fled this room"
    end
    
    return true, nil
end

--------------------------------------------------------------------------------
-- F.4: canAct(state)
-- Returns (bool, reason) - whether player can take any action
--------------------------------------------------------------------------------

function State.canAct(state)
    if state.runState == State.RunState.GAME_OVER then
        return false, "Game over"
    end
    
    if state.runState == State.RunState.VICTORY then
        return false, "You won!"
    end
    
    if state.runState ~= State.RunState.AWAITING then
        return false, "Not your turn"
    end
    
    if State.roomIsEmpty(state) then
        return false, "Room is empty"
    end
    
    return true, nil
end

--------------------------------------------------------------------------------
-- Utility: shallowCopyState(state)
-- Creates a shallow copy of state with deep-copied mutable fields
-- Used by pure functions to avoid mutating input
--------------------------------------------------------------------------------

function State.shallowCopyState(state)
    -- Deep copy arrays and nested tables
    local newDeck = {}
    for i, card in ipairs(state.deck) do
        newDeck[i] = card  -- Cards are immutable, no need to deep copy
    end
    
    local newDiscard = {}
    for i, card in ipairs(state.discard) do
        newDiscard[i] = card
    end
    
    -- Room cards use sparse array (slots 1-4, nil = empty)
    local newRoomCards = {}
    for i = 1, State.ROOM_SIZE do
        newRoomCards[i] = state.room.cards[i]  -- Can be nil
    end
    
    return {
        seed = state.seed,
        hp = state.hp,
        maxHp = state.maxHp,
        deck = newDeck,
        discard = newDiscard,
        room = {
            cards = newRoomCards,
            fleeUsed = state.room.fleeUsed
        },
        weapon = state.weapon,  -- Weapon is replaced, not mutated
        runState = state.runState,
        lastLogLine = state.lastLogLine,
        errorMessage = state.errorMessage,
        turnFlags = {
            lastMonsterSlain = state.turnFlags.lastMonsterSlain
        }
    }
end

--------------------------------------------------------------------------------
-- I.1: isGameOver(state)
-- Returns true when HP <= 0
--------------------------------------------------------------------------------

function State.isGameOver(state)
    return state.hp <= 0
end

--------------------------------------------------------------------------------
-- I.2: isVictory(state)
-- Returns true when deck is empty AND room is empty (all cards resolved)
--------------------------------------------------------------------------------

function State.isVictory(state)
    return State.deckIsEmpty(state) and State.roomIsEmpty(state)
end

--------------------------------------------------------------------------------
-- I.3: updateRunState(state)
-- Checks win/lose conditions and updates runState accordingly
-- Returns newState
--------------------------------------------------------------------------------

function State.updateRunState(state)
    local newState = State.shallowCopyState(state)
    
    if State.isGameOver(newState) then
        newState.runState = State.RunState.GAME_OVER
    elseif State.isVictory(newState) then
        newState.runState = State.RunState.VICTORY
    end
    
    return newState
end

--------------------------------------------------------------------------------
-- I.4: assertNoDuplicateCards(state)
-- Debug assertion: ensures no card appears in multiple locations
-- Returns (isValid, errorMessage)
--------------------------------------------------------------------------------

function State.assertNoDuplicateCards(state)
    local Cards = require("cards")
    local seenByString = {}  -- Check by suit+rank
    local seenById = {}      -- Check by unique ID
    
    -- Helper to check and record a card
    local function checkCard(card, location)
        local cardStr = Cards.cardToString(card)
        local cardId = card.id
        
        -- Check for duplicate suit+rank (the actual game rule)
        if seenByString[cardStr] then
            return false, string.format("Duplicate card %s (id=%s) found in %s and %s (id=%s)", 
                cardStr, tostring(cardId), location, seenByString[cardStr].location, 
                tostring(seenByString[cardStr].id))
        end
        seenByString[cardStr] = { location = location, id = cardId }
        
        -- Check for same card object appearing twice (reference leak)
        if cardId and seenById[cardId] then
            return false, string.format("Same card instance id=%d (%s) found in %s and %s", 
                cardId, cardStr, seenById[cardId], location)
        end
        if cardId then
            seenById[cardId] = location
        end
        
        return true, nil
    end
    
    -- Check deck
    for i, card in ipairs(state.deck) do
        local valid, err = checkCard(card, "deck[" .. i .. "]")
        if not valid then return false, err end
    end
    
    -- Check discard
    for i, card in ipairs(state.discard) do
        local valid, err = checkCard(card, "discard[" .. i .. "]")
        if not valid then return false, err end
    end
    
    -- Check room (handles sparse array)
    for i = 1, State.ROOM_SIZE do
        local card = state.room.cards[i]
        if card then
            local valid, err = checkCard(card, "room[" .. i .. "]")
            if not valid then return false, err end
        end
    end
    
    -- Check weapon (if equipped)
    if state.weapon and state.weapon.card then
        local valid, err = checkCard(state.weapon.card, "weapon")
        if not valid then return false, err end
    end
    
    return true, nil
end

--------------------------------------------------------------------------------
-- I.5: assertHpInRange(state)
-- Debug assertion: ensures HP is within valid range (0 to maxHp)
-- Returns (isValid, errorMessage)
--------------------------------------------------------------------------------

function State.assertHpInRange(state)
    if state.hp < 0 then
        return false, string.format("HP below 0: %d", state.hp)
    end
    if state.hp > state.maxHp then
        return false, string.format("HP above max: %d > %d", state.hp, state.maxHp)
    end
    return true, nil
end

--------------------------------------------------------------------------------
-- I.6: assertRoomSizeValid(state)
-- Debug assertion: ensures room has valid number of cards (0 to ROOM_SIZE)
-- Returns (isValid, errorMessage)
--------------------------------------------------------------------------------

function State.assertRoomSizeValid(state)
    local roomSize = #state.room.cards
    if roomSize < 0 then
        return false, string.format("Room has negative cards: %d", roomSize)
    end
    if roomSize > State.ROOM_SIZE then
        return false, string.format("Room exceeds max size: %d > %d", roomSize, State.ROOM_SIZE)
    end
    return true, nil
end

--------------------------------------------------------------------------------
-- runAllAssertions(state)
-- Runs all debug assertions and returns combined result
-- Returns (isValid, errorMessages)
--------------------------------------------------------------------------------

function State.runAllAssertions(state)
    local errors = {}
    
    local valid, err = State.assertNoDuplicateCards(state)
    if not valid then table.insert(errors, err) end
    
    valid, err = State.assertHpInRange(state)
    if not valid then table.insert(errors, err) end
    
    valid, err = State.assertRoomSizeValid(state)
    if not valid then table.insert(errors, err) end
    
    if #errors > 0 then
        return false, errors
    end
    return true, nil
end

return State

