-- HudCounts - dungeon and discard counts

local Theme = require("ui.theme")

local HudCounts = {}

function HudCounts.draw(rect, dungeonCount, discardCount)
    love.graphics.setFont(Theme.fonts.md)
    love.graphics.setColor(Theme.colors.text)
    love.graphics.print("Dungeon: " .. tostring(dungeonCount), rect.x + 12, rect.y + 10)
    love.graphics.setColor(Theme.colors.textDim)
    love.graphics.print("Discard: " .. tostring(discardCount), rect.x + 12, rect.y + 34)
end

return HudCounts
