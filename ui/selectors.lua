-- UI Selectors for interaction gating and previews

local Selectors = {}

function Selectors.canAvoidRoom(state)
    if state.turn.previousTurnAvoided then
        return { ok = false, reason = "Can't avoid two rooms in a row" }
    end
    if #state.room.cards < state.config.roomSize then
        return { ok = false, reason = "Need a full room (4 cards) to avoid" }
    end
    return { ok = true }
end

function Selectors.canWeaponFight(state, monsterCard)
    local weapon = state.player.weapon
    if not weapon then
        return { ok = false, reason = "No weapon equipped" }
    end
    if weapon.lastSlainMonsterValue ~= nil and monsterCard.value > weapon.lastSlainMonsterValue then
        return { ok = false, reason = "Weapon can only slay \226\137\164 " .. tostring(weapon.lastSlainMonsterValue) }
    end
    return { ok = true }
end

function Selectors.previewDamage(state, monsterCard, mode)
    if mode == "barehanded" then
        return monsterCard.value
    end
    if mode == "weapon" then
        local weapon = state.player.weapon
        if not weapon then return monsterCard.value end
        return math.max(0, monsterCard.value - weapon.value)
    end
    return monsterCard.value
end

return Selectors
