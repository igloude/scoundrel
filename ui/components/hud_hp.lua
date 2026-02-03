-- HudHp - HP widget with animated bar

local Theme = require("ui.theme")

local HudHp = {}

function HudHp.draw(rect, hpValue, hpMax, displayHp)
    love.graphics.setFont(Theme.fonts.md)
    love.graphics.setColor(Theme.colors.text)
    local display = math.floor((displayHp or hpValue) + 0.5)
    love.graphics.print(string.format("HP %d/%d", display, hpMax), rect.x + 12, rect.y + 10)
    
    local barX = rect.x + 12
    local barY = rect.y + 36
    local barW = rect.w - 24
    local barH = 12
    love.graphics.setColor(Theme.colors.panelDark)
    love.graphics.rectangle("fill", barX, barY, barW, barH, Theme.radii.sm, Theme.radii.sm)
    
    local clamped = math.max(0, math.min(hpMax, displayHp))
    local pct = hpMax > 0 and (clamped / hpMax) or 0
    love.graphics.setColor(Theme.colors.potion)
    love.graphics.rectangle("fill", barX, barY, barW * pct, barH, Theme.radii.sm, Theme.radii.sm)
    love.graphics.setColor(Theme.colors.line)
    love.graphics.rectangle("line", barX, barY, barW, barH, Theme.radii.sm, Theme.radii.sm)
end

return HudHp
