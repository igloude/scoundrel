-- CardView - renders a single card with styling states

local Theme = require("ui.theme")
local MotionRegistry = require("ui.motion_registry")

local CardView = {}

local SUIT_SYMBOLS = {
    spades = "♠",
    clubs = "♣",
    hearts = "♥",
    diamonds = "♦"
}

local function cardType(card)
    if card.type then return card.type end
    if card.suit == "spades" or card.suit == "clubs" then
        return "monster"
    elseif card.suit == "hearts" then
        return "potion"
    elseif card.suit == "diamonds" then
        return "weapon"
    end
    return "monster"
end

local function cardValue(card)
    if card.value then return card.value end
    if card.rank == "A" then
        return 14
    elseif card.rank == "J" then
        return 11
    elseif card.rank == "Q" then
        return 12
    elseif card.rank == "K" then
        return 13
    end
    return tonumber(card.rank) or 0
end

local function typeLabel(t)
    if t == "monster" then return "MONSTER" end
    if t == "potion" then return "POTION" end
    return "WEAPON"
end

local function setColor(color, alpha)
    local a = (color[4] or 1) * alpha
    love.graphics.setColor(color[1], color[2], color[3], a)
end

function CardView.draw(card, rect, visualState)
    local alpha = 1
    if card.id then
        alpha = MotionRegistry.getAlpha(card.id)
    end
    local t = cardType(card)
    local value = cardValue(card)
    local label = typeLabel(t)
    local suit = SUIT_SYMBOLS[card.suit] or "?"
    
    local bg = Theme.colors.card
    local edge = Theme.colors.cardEdge
    local typeColor = Theme.colors.weapon
    if t == "monster" then
        typeColor = Theme.colors.monster
    elseif t == "potion" then
        typeColor = Theme.colors.potion
    end
    
    if visualState == "disabled" then
        bg = Theme.colors.panelDark
        edge = Theme.colors.disabled
    elseif visualState == "hovered" then
        edge = Theme.colors.cardHover
    elseif visualState == "selected" then
        edge = Theme.colors.cardSelected
    end
    
    -- Shadow
    setColor(Theme.shadows.soft, alpha)
    love.graphics.rectangle("fill", rect.x + 4, rect.y + 6, rect.w, rect.h, Theme.radii.md, Theme.radii.md)
    
    -- Card body
    setColor(bg, alpha)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, Theme.radii.md, Theme.radii.md)
    
    -- Edge
    setColor(edge, alpha)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, Theme.radii.md, Theme.radii.md)
    
    -- Suit + Rank
    love.graphics.setFont(Theme.fonts.lg)
    setColor(typeColor, alpha)
    love.graphics.print(suit, rect.x + Theme.spacing.md, rect.y + Theme.spacing.md)
    
    love.graphics.setFont(Theme.fonts.lg)
    setColor(Theme.colors.text, alpha)
    love.graphics.print(card.rank, rect.x + rect.w - Theme.spacing.lg, rect.y + Theme.spacing.md)
    
    -- Type label
    love.graphics.setFont(Theme.fonts.sm)
    setColor(Theme.colors.textDim, alpha)
    love.graphics.print(label, rect.x + Theme.spacing.md, rect.y + rect.h - 52)
    
    -- Value
    love.graphics.setFont(Theme.fonts.md)
    setColor(Theme.colors.text, alpha)
    love.graphics.print("Value: " .. tostring(value), rect.x + Theme.spacing.md, rect.y + rect.h - 30)
    
    -- Carried ribbon
    if card.carriedFromLastTurn then
        love.graphics.setColor(Theme.colors.accent[1], Theme.colors.accent[2], Theme.colors.accent[3], 0.6 * alpha)
        love.graphics.rectangle("fill", rect.x, rect.y, rect.w, 10, Theme.radii.md, Theme.radii.md)
        setColor(Theme.shadows.glow, alpha)
        love.graphics.rectangle("line", rect.x - 2, rect.y - 2, rect.w + 4, rect.h + 4, Theme.radii.md, Theme.radii.md)
    end
end

return CardView
