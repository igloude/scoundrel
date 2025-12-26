-- Scoundrel - Action resolution
-- Pure functions for resolving player actions

local Cards = require("cards")
local State = require("state")

local Actions = {}

--------------------------------------------------------------------------------
-- G.5: applyDamage(state, amount)
-- Reduces HP by amount, clamping at 0. Sets GAME_OVER if HP <= 0.
-- Returns newState
--------------------------------------------------------------------------------

function Actions.applyDamage(state, amount)
    local newState = State.shallowCopyState(state)
    newState.hp = math.max(0, newState.hp - amount)
    
    if newState.hp <= 0 then
        newState.runState = State.RunState.GAME_OVER
    end
    
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
-- Resets the monster memory (lastWeaponHitBySuit) when equipping new weapon
-- Returns newState
--------------------------------------------------------------------------------

function Actions.clearWeaponUseFlags(state)
    local newState = State.shallowCopyState(state)
    newState.turnFlags.lastWeaponHitBySuit.spades = nil
    newState.turnFlags.lastWeaponHitBySuit.clubs = nil
    return newState
end

--------------------------------------------------------------------------------
-- G.7: equipWeapon(state, weaponCard)
-- Equips a weapon, discarding the old one if present.
-- Clears monster memory when equipping.
-- Returns newState
--------------------------------------------------------------------------------

function Actions.equipWeapon(state, weaponCard)
    local newState = State.shallowCopyState(state)
    
    -- Discard old weapon if present
    if newState.weapon then
        -- Old weapon goes to discard (as a card representation)
        -- Note: weapon is stored as {value, card} but we just track value for simplicity
    end
    
    -- Equip new weapon
    newState.weapon = {
        value = Cards.cardValue(weaponCard),
        card = weaponCard
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
-- Returns (damage, canUseWeapon, reason)
--------------------------------------------------------------------------------

function Actions.computeMonsterDamage(state, monsterCard, useWeapon)
    local monsterValue = Cards.cardValue(monsterCard)
    
    -- No weapon or not using weapon: take full damage
    if not useWeapon or not state.weapon then
        return monsterValue, false, nil
    end
    
    -- Check monster memory rule (same-suit non-decreasing)
    local suit = monsterCard.suit
    local lastHit = state.turnFlags.lastWeaponHitBySuit[suit]
    
    if lastHit and monsterValue < lastHit then
        -- Cannot use weapon on smaller monster of same suit
        return monsterValue, false, "Must fight larger " .. suit .. " first (last: " .. lastHit .. ")"
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
    
    -- Remove card from room and discard
    local newState, removedCard = State.removeRoomCard(state, index)
    newState = State.pushToDiscard(newState, removedCard)
    
    -- Apply damage
    newState = Actions.applyDamage(newState, damage)
    
    -- Update monster memory if weapon was used
    if weaponUsed then
        newState.turnFlags.lastWeaponHitBySuit[card.suit] = Cards.cardValue(card)
    end
    
    -- Log the action
    local weaponStr = weaponUsed and " (weapon)" or ""
    local logMsg = string.format("Fought %s%s, took %d damage", 
        Cards.cardToString(card), weaponStr, damage)
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
    
    -- Discard old weapon if present
    if newState.weapon and newState.weapon.card then
        newState = State.pushToDiscard(newState, newState.weapon.card)
    end
    
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
    
    -- Apply healing
    newState = Actions.applyHeal(newState, healAmount)
    
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
    local newState = state
    
    -- Check if player died
    if newState.hp <= 0 then
        newState.runState = State.RunState.GAME_OVER
        return newState
    end
    
    local roomCount = State.roomCardCount(newState)
    
    -- Room transition: 1 card left and deck has cards
    if roomCount == 1 and not State.deckIsEmpty(newState) then
        -- Find the remaining card and move it to position 1
        local carryOverCard = nil
        for i = 1, State.ROOM_SIZE do
            if newState.room.cards[i] then
                carryOverCard = newState.room.cards[i]
                break
            end
        end
        
        -- Reset room with carry-over card at position 1
        newState = State.shallowCopyState(newState)
        newState.room.cards = { carryOverCard, nil, nil, nil }
        newState.room.fleeUsed = false
        
        -- Draw 3 new cards to fill positions 2, 3, 4
        newState = State.dealRoomUpToFull(newState)
        
        return newState
    end
    
    -- Victory: room empty AND deck empty
    if roomCount == 0 and State.deckIsEmpty(newState) then
        newState.runState = State.RunState.VICTORY
        newState = State.setLog(newState, "Victory! You survived the dungeon!")
        return newState
    end
    
    -- Edge case: 1 card left but deck is empty - player must take it to win
    -- (No transition needed, player continues taking from room)
    
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
    
    -- Post-take processing
    newState = Actions.afterSuccessfulTake(newState)
    
    return newState
end

--------------------------------------------------------------------------------
-- H.2: resolveFleeCard(state, card, index)
-- Places the chosen card at the bottom of the deck.
-- Returns newState
--------------------------------------------------------------------------------

function Actions.resolveFleeCard(state, card, index)
    local Deck = require("deck")
    
    -- Remove card from room (don't discard it)
    local newState, removedCard = State.removeRoomCard(state, index)
    
    -- Put the card at the bottom of the deck
    Deck.putCardOnBottom(newState.deck, removedCard)
    
    return newState
end

--------------------------------------------------------------------------------
-- H.3: applyFleePenalty(state)
-- Applies any penalty for fleeing (none in base rules).
-- Returns newState
--------------------------------------------------------------------------------

function Actions.applyFleePenalty(state)
    -- No penalty in base rules
    return state
end

--------------------------------------------------------------------------------
-- H.4: afterFlee(state)
-- Called after fleeing. Discards remaining room cards and refills room.
-- Returns newState
--------------------------------------------------------------------------------

function Actions.afterFlee(state)
    local newState = State.shallowCopyState(state)
    
    -- Discard all remaining room cards (handles sparse array)
    for i = 1, State.ROOM_SIZE do
        local card = newState.room.cards[i]
        if card then
            table.insert(newState.discard, card)
            newState.room.cards[i] = nil
        end
    end
    
    -- Mark flee as used (already done in applyFlee, but ensure it)
    newState.room.fleeUsed = true
    
    -- Check if deck is empty -> victory (room is now empty)
    if State.deckIsEmpty(newState) then
        newState.runState = State.RunState.VICTORY
        newState = State.setLog(newState, "Victory! You survived the dungeon!")
        return newState
    end
    
    -- Deal new room (flee resets the room)
    newState.room.fleeUsed = false  -- Reset for the new room
    newState = State.dealRoomUpToFull(newState)
    
    return newState
end

--------------------------------------------------------------------------------
-- H.1: applyFlee(state, index)
-- Single entry point for fleeing from a card.
-- The chosen card goes to the bottom of the deck; others are discarded.
-- Returns newState
--------------------------------------------------------------------------------

function Actions.applyFlee(state, index)
    -- Validate
    local canFlee, reason = State.canFleeFromRoom(state, index)
    if not canFlee then
        return State.setError(state, reason)
    end
    
    -- Clear any previous error
    local newState = State.clearError(state)
    
    -- Get the card we're fleeing from
    local card = newState.room.cards[index]
    
    -- Mark flee as used before we modify the room
    newState = State.shallowCopyState(newState)
    newState.room.fleeUsed = true
    
    -- Put the chosen card at the bottom of the deck
    newState = Actions.resolveFleeCard(newState, card, index)
    
    -- Apply any flee penalty
    newState = Actions.applyFleePenalty(newState)
    
    -- Log the action
    local logMsg = string.format("Fled from %s (sent to bottom of deck)", 
        Cards.cardToString(card))
    newState = State.setLog(newState, logMsg)
    
    -- Post-flee processing (discard remaining cards, deal new room)
    newState = Actions.afterFlee(newState)
    
    return newState
end

return Actions

