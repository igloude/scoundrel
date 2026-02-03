-- Keybindings for keyboard navigation and actions

local Selectors = require("ui.selectors")

local Keybindings = {}

function Keybindings.nextFocus(state, dir)
    local count = #state.room.cards
    if count == 0 then
        return nil
    end
    local current = state.ui.focusedIndex or 1
    local nextIndex = current + dir
    if nextIndex < 1 then nextIndex = count end
    if nextIndex > count then nextIndex = 1 end
    return nextIndex
end

function Keybindings.handle(state, key, actions)
    if key == "left" then
        local nextIndex = Keybindings.nextFocus(state, -1)
        if nextIndex then actions.onFocus(nextIndex) end
        return true
    elseif key == "right" then
        local nextIndex = Keybindings.nextFocus(state, 1)
        if nextIndex then actions.onFocus(nextIndex) end
        return true
    elseif key == "return" or key == "kpenter" then
        local idx = state.ui.focusedIndex
        if idx then actions.onSelect(idx) end
        return true
    elseif key == "escape" then
        actions.onClear()
        return true
    elseif key == "a" then
        local canAvoid = Selectors.canAvoidRoom(state)
        actions.onAvoid(canAvoid)
        return true
    elseif key == "1" or key == "2" then
        local selected = state.ui.selectedIndex and state.room.cards[state.ui.selectedIndex] or nil
        if selected and selected.type == "monster" then
            if key == "1" then
                actions.onResolveMonster("barehanded", { ok = true })
            else
                local canWeapon = Selectors.canWeaponFight(state, selected)
                actions.onResolveMonster("weapon", canWeapon)
            end
            return true
        end
    end
    return false
end

return Keybindings
