-- ChoicePanel - contextual actions for selected cards

local Theme = require("ui.theme")
local Selectors = require("ui.selectors")

local ChoicePanel = {}

local function button(rect, label, enabled)
    local fill = enabled and Theme.colors.card or Theme.colors.panelDark
    local edge = enabled and Theme.colors.cardEdge or Theme.colors.disabled
    local text = enabled and Theme.colors.text or Theme.colors.textDim
    
    love.graphics.setColor(fill)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, Theme.radii.md, Theme.radii.md)
    love.graphics.setColor(edge)
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, Theme.radii.md, Theme.radii.md)
    love.graphics.setFont(Theme.fonts.sm)
    love.graphics.setColor(text)
    love.graphics.print(label, rect.x + 10, rect.y + 8)
end

function ChoicePanel.draw(rect, state, selectedCard)
    if not selectedCard then
        return nil
    end
    
    love.graphics.setColor(Theme.colors.panel)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, Theme.radii.lg, Theme.radii.lg)
    love.graphics.setColor(Theme.colors.line)
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, Theme.radii.lg, Theme.radii.lg)
    
    love.graphics.setFont(Theme.fonts.sm)
    love.graphics.setColor(Theme.colors.textDim)
    love.graphics.print("Card Action", rect.x + 12, rect.y + 10)
    
    local layout = { buttons = {} }
    local btnW, btnH = 180, 32
    local x = rect.x + 12
    local y = rect.y + 34
    
    if selectedCard.type == "monster" then
        local dmgBare = Selectors.previewDamage(state, selectedCard, "barehanded")
        local canWeapon = Selectors.canWeaponFight(state, selectedCard)
        local dmgWeapon = Selectors.previewDamage(state, selectedCard, "weapon")
        
        local bareRect = { x = x, y = y, w = btnW, h = btnH }
        button(bareRect, "Fight Barehanded (" .. dmgBare .. " dmg)", true)
        layout.buttons.barehanded = { rect = bareRect, enabled = true }
        
        y = y + btnH + 8
        local weaponRect = { x = x, y = y, w = btnW, h = btnH }
        button(weaponRect, "Fight With Weapon (" .. dmgWeapon .. " dmg)", canWeapon.ok)
        layout.buttons.weapon = { rect = weaponRect, enabled = canWeapon.ok, reason = canWeapon.reason }
        
        if not canWeapon.ok and canWeapon.reason then
            love.graphics.setFont(Theme.fonts.xs)
            love.graphics.setColor(Theme.colors.textDim)
            love.graphics.print(canWeapon.reason, x + btnW + 10, y + 8)
        end
    elseif selectedCard.type == "potion" then
        local label = ""
        if state.turn.potionUsedThisTurn then
            label = "Discarded (potion already used)"
        else
            local clamped = math.min(state.player.hpMax, state.player.hp + selectedCard.value)
            local gain = clamped - state.player.hp
            label = "Use Potion (Heal +" .. gain .. ")"
        end
        local potionRect = { x = x, y = y, w = btnW, h = btnH }
        button(potionRect, label, true)
        layout.buttons.potion = { rect = potionRect, enabled = true }
    elseif selectedCard.type == "weapon" then
        local weaponRect = { x = x, y = y, w = btnW, h = btnH }
        button(weaponRect, "Equip Weapon", true)
        layout.buttons.weaponEquip = { rect = weaponRect, enabled = true }
    end
    
    local cancelRect = { x = rect.x + rect.w - 90, y = rect.y + rect.h - 36, w = 78, h = 26 }
    button(cancelRect, "Cancel", true)
    layout.buttons.cancel = { rect = cancelRect, enabled = true }
    
    return layout
end

function ChoicePanel.hitTest(mx, my, layout)
    if not layout then return nil end
    for key, btn in pairs(layout.buttons) do
        local r = btn.rect
        if mx >= r.x and mx <= r.x + r.w and my >= r.y and my <= r.y + r.h then
            return key, btn
        end
    end
    return nil
end

return ChoicePanel
