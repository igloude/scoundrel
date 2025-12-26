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
    
    -- Create and shuffle the Scoundrel deck
    local deck = Deck.createScoundrelDeck()
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
        -- lastWeaponHitBySuit tracks the "monster memory" rule
        turnFlags = {
            lastWeaponHitBySuit = {
                spades = nil,
                clubs = nil
            }
        }
    }
    
    return state
end

--------------------------------------------------------------------------------
-- E.1: roomIsFull(state)
-- Returns true if room has ROOM_SIZE cards
--------------------------------------------------------------------------------

function State.roomIsFull(state)
    return #state.room.cards >= State.ROOM_SIZE
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
-- Returns true if room has no cards
--------------------------------------------------------------------------------

function State.roomIsEmpty(state)
    return #state.room.cards == 0
end

--------------------------------------------------------------------------------
-- E.4: dealOneToRoom(state)
-- Draws one card from deck into room (if possible)
-- Returns newState (pure function - does not mutate input)
--------------------------------------------------------------------------------

function State.dealOneToRoom(state)
    if State.deckIsEmpty(state) or State.roomIsFull(state) then
        return state
    end
    
    -- Copy state
    local newState = State.shallowCopyState(state)
    
    -- Draw card from deck and add to room
    local card = table.remove(newState.deck)
    table.insert(newState.room.cards, card)
    
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
-- Removes card at index from room
-- Returns (newState, removedCard) or (state, nil) if invalid index
--------------------------------------------------------------------------------

function State.removeRoomCard(state, index)
    if index < 1 or index > #state.room.cards then
        return state, nil
    end
    
    -- Copy state
    local newState = State.shallowCopyState(state)
    
    -- Remove card
    local removedCard = table.remove(newState.room.cards, index)
    
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
    return index >= 1 and index <= #state.room.cards
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
    
    local newRoomCards = {}
    for i, card in ipairs(state.room.cards) do
        newRoomCards[i] = card
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
            lastWeaponHitBySuit = {
                spades = state.turnFlags.lastWeaponHitBySuit.spades,
                clubs = state.turnFlags.lastWeaponHitBySuit.clubs
            }
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
    local seen = {}
    
    -- Helper to check and record a card
    local function checkCard(card, location)
        local id = Cards.cardToString(card)
        if seen[id] then
            return false, string.format("Duplicate card %s found in %s and %s", 
                id, seen[id], location)
        end
        seen[id] = location
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
    
    -- Check room
    for i, card in ipairs(state.room.cards) do
        local valid, err = checkCard(card, "room[" .. i .. "]")
        if not valid then return false, err end
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

