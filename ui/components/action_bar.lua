-- ActionBar - bottom actions including Avoid Room button

local Theme = require("ui.theme")
local Selectors = require("ui.selectors")

local ActionBar = {}

function ActionBar.draw(rect, state)
    love.graphics.setColor(Theme.colors.panel)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, Theme.radii.lg, Theme.radii.lg)
    love.graphics.setColor(Theme.colors.line)
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, Theme.radii.lg, Theme.radii.lg)
    
    local avoid = Selectors.canAvoidRoom(state)
    local btnW, btnH = 160, 36
    local btnX = rect.x + Theme.spacing.md
    local btnY = rect.y + (rect.h - btnH) / 2
    local btnRect = { x = btnX, y = btnY, w = btnW, h = btnH }
    
    local btnColor = Theme.colors.accent
    local textColor = Theme.colors.text
    if not avoid.ok then
        btnColor = Theme.colors.disabled
        textColor = Theme.colors.textDim
    end
    
    love.graphics.setColor(btnColor)
    love.graphics.rectangle("fill", btnRect.x, btnRect.y, btnRect.w, btnRect.h, Theme.radii.md, Theme.radii.md)
    love.graphics.setColor(Theme.colors.line)
    love.graphics.rectangle("line", btnRect.x, btnRect.y, btnRect.w, btnRect.h, Theme.radii.md, Theme.radii.md)
    
    love.graphics.setFont(Theme.fonts.md)
    love.graphics.setColor(textColor)
    love.graphics.print("Avoid Room", btnRect.x + 16, btnRect.y + 8)
    
    love.graphics.setFont(Theme.fonts.sm)
    love.graphics.setColor(Theme.colors.textDim)
    love.graphics.print("Select a card to act", btnRect.x + btnRect.w + 18, btnRect.y + 10)
    
    if not avoid.ok and avoid.reason then
        love.graphics.setFont(Theme.fonts.xs)
        love.graphics.setColor(Theme.colors.textDim)
        love.graphics.print(avoid.reason, btnRect.x, btnRect.y - 16)
    end
    
    return {
        avoid = {
            rect = btnRect,
            enabled = avoid.ok,
            reason = avoid.reason
        }
    }
end

function ActionBar.hitTest(mx, my, layout)
    local r = layout.avoid.rect
    if mx >= r.x and mx <= r.x + r.w and my >= r.y and my <= r.y + r.h then
        return "avoid"
    end
    return nil
end

return ActionBar
