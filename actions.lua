-- Scoundrel - Action resolution
-- Pure functions for resolving player actions

local Cards = require("cards")
local State = require("state")

local Actions = {}

-- Debug flag to enable duplicate card assertions
Actions.DEBUG_ASSERTIONS = true

-- Helper to run assertions (call after state changes)
local function runAssertions(state, context)
    if not Actions.DEBUG_ASSERTIONS then return end
    
    local valid, err = State.assertNoDuplicateCards(state)
    if not valid then
        print("=== DUPLICATE CARD BUG DETECTED ===")
        print("Context: " .. (context or "unknown"))
        print("Error: " .. err)
        print("===================================")
    end
end

--------------------------------------------------------------------------------
-- Turn helpers
--------------------------------------------------------------------------------

function Actions.beginTurn(state)
    local newState = State.shallowCopyState(state)
    newState.turnFlags.cardsResolvedThisTurn = 0
    newState.turnFlags.potionUsedThisTurn = false
    newState.turnFlags.turnRoomSize = State.roomCardCount(newState)
    return newState
end

local function discardWeaponAndSlain(state)
    local newState = State.shallowCopyState(state)
    if not newState.weapon then
        return newState
    end
    if newState.weapon.card then
        newState = State.pushToDiscard(newState, newState.weapon.card)
    end
    if newState.weapon.slain then
        for _, slainCard in ipairs(newState.weapon.slain) do
            newState = State.pushToDiscard(newState, slainCard)
        end
    end
    return newState
end

--------------------------------------------------------------------------------
-- Endgame scoring
--------------------------------------------------------------------------------

local function computeLossScore(state)
    local remainingMonsters = 0
    for _, card in ipairs(state.deck) do
        if Cards.isMonster(card) then
            remainingMonsters = remainingMonsters + Cards.cardValue(card)
        end
    end
    return state.hp - remainingMonsters
end

local function computeWinScore(state)
    if state.hp == state.maxHp and state.lastResolvedType == "potion" and state.lastResolvedCard then
        return state.maxHp + Cards.cardValue(state.lastResolvedCard)
    end
    return state.hp
end

function Actions.updateEndState(state)
    local newState = State.shallowCopyState(state)
    if State.isGameOver(newState) then
        newState.runState = State.RunState.GAME_OVER
        if newState.score == nil then
            newState.score = computeLossScore(newState)
        end
        if newState.lastLogLine == "" then
            newState = State.setLog(newState, "Game Over!")
        end
        return newState
    end
    if State.isVictory(newState) then
        newState.runState = State.RunState.VICTORY
        if newState.score == nil then
            newState.score = computeWinScore(newState)
        end
        return newState
    end
    return newState
end

--------------------------------------------------------------------------------
-- G.5: applyDamage(state, amount)
-- Reduces HP by amount (can go below 0).
-- Returns newState
--------------------------------------------------------------------------------

function Actions.applyDamage(state, amount)
    local newState = State.shallowCopyState(state)
    newState.hp = newState.hp - amount
    return newState
end

--------------------------------------------------------------------------------
-- G.6: applyHeal(state, amount)
-- Increases HP by amount, clamping to maxHp
-- Returns newState
--------------------------------------------------------------------------------

function Actions.applyHeal(state, amount)
    local newState = State.shallowCopyState(state)
    newState.hp = math.min(newState.maxHp, newState.hp + amount)
    return newState
end

--------------------------------------------------------------------------------
-- G.8: clearWeaponUseFlags(state)
-- Resets the weapon's "max target" (lastMonsterSlain) when equipping new weapon
-- Returns newState
--------------------------------------------------------------------------------

function Actions.clearWeaponUseFlags(state)
    local newState = State.shallowCopyState(state)
    newState.turnFlags.lastMonsterSlain = nil
    return newState
end

--------------------------------------------------------------------------------
-- G.7: equipWeapon(state, weaponCard)
-- Equips a weapon (discarding handled elsewhere).
-- Clears monster memory when equipping.
-- Returns newState
--------------------------------------------------------------------------------

function Actions.equipWeapon(state, weaponCard)
    local newState = State.shallowCopyState(state)
    
    -- Equip new weapon
    newState.weapon = {
        value = Cards.cardValue(weaponCard),
        card = weaponCard,
        slain = {}
    }
    
    -- Clear monster memory when equipping new weapon
    newState = Actions.clearWeaponUseFlags(newState)
    
    return newState
end

--------------------------------------------------------------------------------
-- G.9: computeMonsterDamage(state, monsterCard, useWeapon)
-- Calculates damage from a monster.
-- If useWeapon is true and weapon exists: damage = max(0, monster - weapon)
-- Otherwise: damage = monster value
-- 
-- Weapon constraint: After slaying a monster with a weapon, you can only use
-- that weapon on monsters of equal or LOWER power (any suit). The weapon's damage
-- never changes, only what it can hit.
-- Returns (damage, canUseWeapon, reason)
--------------------------------------------------------------------------------

function Actions.computeMonsterDamage(state, monsterCard, useWeapon)
    local monsterValue = Cards.cardValue(monsterCard)
    
    -- No weapon or not using weapon: take full damage
    if not useWeapon or not state.weapon then
        return monsterValue, false, nil
    end
    
    -- Check weapon's "max target" rule:
    -- After slaying a monster, weapon can only be used on monsters of equal or lower power
    local lastSlain = state.turnFlags.lastMonsterSlain
    
    if lastSlain and monsterValue > lastSlain then
        -- Cannot use weapon on monster with power > last slain monster
        return monsterValue, false, string.format(
            "Weapon can only hit monsters <= %d (last slain: %d)", lastSlain, lastSlain)
    end
    
    -- Weapon applies: damage reduced
    local damage = math.max(0, monsterValue - state.weapon.value)
    return damage, true, nil
end

--------------------------------------------------------------------------------
-- G.2: resolveTakeMonster(state, card, index, useWeapon)
-- Resolves taking a monster card. 
-- useWeapon: whether to attempt using weapon (defaults to true if weapon exists)
-- Returns newState
--------------------------------------------------------------------------------

function Actions.resolveTakeMonster(state, card, index, useWeapon)
    -- Track if player explicitly chose barehanded
    local choseBarehanded = (useWeapon == false)
    
    -- Default: use weapon if we have one
    if useWeapon == nil then
        useWeapon = (state.weapon ~= nil)
    end
    
    local damage, weaponUsed, reason = Actions.computeMonsterDamage(state, card, useWeapon)
    
    -- If we wanted to use weapon but couldn't, fall back to no weapon
    if useWeapon and not weaponUsed and reason then
        -- Player must choose: can't use weapon due to monster memory
        -- For now, we'll just take full damage and log the reason
        damage = Cards.cardValue(card)
    end
    
    -- Remove card from room
    local newState, removedCard = State.removeRoomCard(state, index)
    
    -- Apply damage
    newState = Actions.applyDamage(newState, damage)
    
    -- Update weapon's "max target" if weapon was used
    -- After slaying a monster with weapon, can only hit monsters of equal or lower power
    if weaponUsed then
        newState.turnFlags.lastMonsterSlain = Cards.cardValue(card)
        -- Stack slain monster on the weapon (not discarded)
        if newState.weapon then
            table.insert(newState.weapon.slain, removedCard)
        else
            newState = State.pushToDiscard(newState, removedCard)
        end
    else
        -- Barehanded: discard the monster
        newState = State.pushToDiscard(newState, removedCard)
    end
    
    -- Log the action with clear fight style indication
    local fightStyle = ""
    if weaponUsed then
        fightStyle = " with weapon"
    elseif choseBarehanded and state.weapon then
        fightStyle = " barehanded"
    end
    local logMsg = string.format("Fought %s%s, took %d damage", 
        Cards.cardToString(card), fightStyle, damage)
    newState = State.setLog(newState, logMsg)
    
    return newState
end

--------------------------------------------------------------------------------
-- G.3: resolveTakeWeapon(state, card, index)
-- Resolves taking a weapon card (equip it)
-- Returns newState
--------------------------------------------------------------------------------

function Actions.resolveTakeWeapon(state, card, index)
    -- Remove card from room
    local newState, removedCard = State.removeRoomCard(state, index)
    
    -- Discard old weapon and its slain stack if present
    newState = discardWeaponAndSlain(newState)
    
    -- Equip new weapon
    newState = Actions.equipWeapon(newState, removedCard)
    
    -- Log the action
    local logMsg = string.format("Equipped %s (value %d)", 
        Cards.cardToString(card), Cards.cardValue(card))
    newState = State.setLog(newState, logMsg)
    
    return newState
end

--------------------------------------------------------------------------------
-- G.4: resolveTakePotion(state, card, index)
-- Resolves taking a potion card (heal)
-- Returns newState
--------------------------------------------------------------------------------

function Actions.resolveTakePotion(state, card, index)
    local healAmount = Cards.cardValue(card)
    local oldHp = state.hp
    
    -- Remove card from room and discard
    local newState, removedCard = State.removeRoomCard(state, index)
    newState = State.pushToDiscard(newState, removedCard)
    
    if newState.turnFlags.potionUsedThisTurn then
        -- Potion already used this turn: no healing
        local logMsg = string.format("Drank %s, no healing (already used potion this turn)", 
            Cards.cardToString(card))
        newState = State.setLog(newState, logMsg)
        return newState
    end
    
    -- Apply healing (first potion this turn)
    newState = Actions.applyHeal(newState, healAmount)
    newState.turnFlags.potionUsedThisTurn = true
    
    -- Log the action
    local actualHeal = newState.hp - oldHp
    local logMsg = string.format("Drank %s, healed %d HP (%d -> %d)", 
        Cards.cardToString(card), actualHeal, oldHp, newState.hp)
    newState = State.setLog(newState, logMsg)
    
    return newState
end

--------------------------------------------------------------------------------
-- G.10: afterSuccessfulTake(state)
-- Called after successfully taking a card.
-- Room transition rule: After taking 3 cards (1 left), the remaining card
-- carries forward to the next room with 3 new cards drawn.
-- Returns newState
--------------------------------------------------------------------------------

function Actions.afterSuccessfulTake(state)
    -- Always work with a copy to avoid mutation issues
    local newState = State.shallowCopyState(state)
    
    -- Check for game end (loss)
    newState = Actions.updateEndState(newState)
    if newState.runState == State.RunState.GAME_OVER then
        return newState
    end
    
    local roomCount = State.roomCardCount(newState)
    local turnRoomSize = newState.turnFlags.turnRoomSize
    
    -- Room transition for full rooms: resolve exactly 3, carry 1
    if turnRoomSize == State.ROOM_SIZE and newState.turnFlags.cardsResolvedThisTurn >= 3 and roomCount >= 1 then
        -- Find the remaining card's position and get reference
        local carryOverCard = nil
        for i = 1, State.ROOM_SIZE do
            if newState.room.cards[i] then
                carryOverCard = newState.room.cards[i]
                break
            end
        end
        
        -- Debug assertion: verify carryOverCard is not in the deck
        if Actions.DEBUG_ASSERTIONS and carryOverCard then
            for i, deckCard in ipairs(newState.deck) do
                if deckCard.id == carryOverCard.id then
                    print("=== CARRY-OVER BUG: Card already in deck! ===")
                    print("Card: " .. Cards.cardToString(carryOverCard) .. " id=" .. carryOverCard.id)
                    print("Found at deck position: " .. i)
                    print("============================================")
                end
            end
        end
        
        -- Clear the old positions first, then set position 1
        for i = 1, State.ROOM_SIZE do
            newState.room.cards[i] = nil
        end
        newState.room.cards[1] = carryOverCard
        newState.turnFlags.carryOverCardId = carryOverCard and carryOverCard.id or nil
        
        -- End the turn (non-avoid), then deal for next turn
        newState.turnFlags.lastTurnWasAvoid = false
        
        -- Debug assertion: verify clean state before dealing
        runAssertions(newState, "after carry-over setup, before dealing")
        
        -- Draw up to full (3 new cards if available)
        newState = State.dealRoomUpToFull(newState)
        
        -- Reset per-turn counters for the new room
        newState = Actions.beginTurn(newState)
        
        -- Debug assertion: verify no duplicates after dealing
        runAssertions(newState, "after carry-over dealing")
        
        return newState
    end
    
    -- Victory: room empty AND deck empty
    if roomCount == 0 and State.deckIsEmpty(newState) then
        newState.turnFlags.lastTurnWasAvoid = false
        newState = Actions.updateEndState(newState)
        if newState.runState == State.RunState.VICTORY then
            newState = State.setLog(newState, "Victory! You survived the dungeon!")
        end
        return newState
    end
    
    return newState
end

--------------------------------------------------------------------------------
-- G.11: afterFailedTake(state)
-- Called if take action failed for some reason.
-- Currently just returns state unchanged.
-- Returns newState
--------------------------------------------------------------------------------

function Actions.afterFailedTake(state)
    -- Nothing special needed for failed takes
    return state
end

--------------------------------------------------------------------------------
-- G.1: applyTake(state, index, useWeapon)
-- Single entry point for taking a card from the room.
-- useWeapon: optional, only relevant for monsters
-- Returns newState
--------------------------------------------------------------------------------

function Actions.applyTake(state, index, useWeapon)
    -- Validate
    local canTake, reason = State.canTakeFromRoom(state, index)
    if not canTake then
        return State.setError(state, reason)
    end
    
    -- Clear any previous error
    local newState = State.clearError(state)
    
    -- Get the card
    local card = newState.room.cards[index]
    local cardType = Cards.cardType(card)
    
    -- Resolve based on card type
    if cardType == "monster" then
        newState = Actions.resolveTakeMonster(newState, card, index, useWeapon)
    elseif cardType == "weapon" then
        newState = Actions.resolveTakeWeapon(newState, card, index)
    elseif cardType == "potion" then
        newState = Actions.resolveTakePotion(newState, card, index)
    end

    -- Track last resolved card for scoring
    newState.lastResolvedCard = card
    newState.lastResolvedType = cardType
    newState.turnFlags.cardsResolvedThisTurn = newState.turnFlags.cardsResolvedThisTurn + 1
    if newState.turnFlags.carryOverCardId == card.id then
        newState.turnFlags.carryOverCardId = nil
    end
    
    -- Post-take processing
    newState = Actions.afterSuccessfulTake(newState)
    
    -- Run assertions to catch any duplicate card bugs
    runAssertions(newState, "after applyTake index=" .. index)
    
    return newState
end

--------------------------------------------------------------------------------
-- H.1: applyAvoid(state)
-- Single entry point for avoiding the current room.
-- Moves all face-up cards to the bottom of the deck; cannot be used twice in a row.
-- Returns newState
--------------------------------------------------------------------------------

function Actions.applyAvoid(state)
    local Deck = require("deck")
    
    -- Validate
    local canAvoid, reason = State.canAvoidRoom(state)
    if not canAvoid then
        return State.setError(state, reason)
    end
    
    -- Clear any previous error
    local newState = State.clearError(state)
    newState = State.shallowCopyState(newState)
    
    -- Collect room cards in slot order
    local roomCards = {}
    for i = 1, State.ROOM_SIZE do
        local card = newState.room.cards[i]
        if card then
            table.insert(roomCards, card)
        end
        newState.room.cards[i] = nil
    end
    
    -- Put cards on bottom of deck in slot order (preserve left-to-right order)
    for i = #roomCards, 1, -1 do
        Deck.putCardOnBottom(newState.deck, roomCards[i])
    end
    
    -- Mark avoid used this turn
    newState.turnFlags.lastTurnWasAvoid = true
    newState.turnFlags.carryOverCardId = nil
    
    -- Log the action
    local logMsg = string.format("Avoided the room (sent %d cards to bottom of deck)", #roomCards)
    newState = State.setLog(newState, logMsg)
    
    -- Deal new room and start a new turn
    newState = State.dealRoomUpToFull(newState)
    newState = Actions.beginTurn(newState)
    
    -- Run assertions to catch any duplicate card bugs
    runAssertions(newState, "after applyAvoid")
    
    return newState
end

return Actions
