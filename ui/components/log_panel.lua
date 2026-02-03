-- LogPanel - persistent action log (most recent on top)

local Theme = require("ui.theme")

local LogPanel = {}

local function clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

function LogPanel.draw(rect, logEntries, scrollLines)
    love.graphics.setColor(Theme.colors.panel)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, Theme.radii.lg, Theme.radii.lg)
    love.graphics.setColor(Theme.colors.line)
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, Theme.radii.lg, Theme.radii.lg)
    
    love.graphics.setFont(Theme.fonts.sm)
    love.graphics.setColor(Theme.colors.textDim)
    love.graphics.print("LOG / TOAST", rect.x + 10, rect.y + 10)
    
    local lineH = 16
    local headerH = 26
    local padding = 10
    local contentY = rect.y + headerH + 6
    local contentH = rect.h - headerH - 12
    local visibleLines = math.max(1, math.floor(contentH / lineH))
    local maxScroll = math.max(0, #logEntries - visibleLines)
    local offset = clamp(scrollLines or 0, 0, maxScroll)
    
    love.graphics.setScissor(rect.x + 6, contentY, rect.w - 12, contentH)
    local y = contentY
    for i = 1 + offset, math.min(#logEntries, offset + visibleLines) do
        local entry = logEntries[i]
        love.graphics.setColor(Theme.colors.text)
        love.graphics.print(entry, rect.x + padding, y)
        y = y + lineH
    end
    love.graphics.setScissor()
    
    -- Scrollbar
    if maxScroll > 0 then
        local barH = math.max(20, contentH * (visibleLines / #logEntries))
        local trackX = rect.x + rect.w - 10
        local trackY = contentY
        local trackH = contentH
        local t = offset / maxScroll
        local barY = trackY + (trackH - barH) * t
        love.graphics.setColor(Theme.colors.panelDark)
        love.graphics.rectangle("fill", trackX, trackY, 4, trackH, 2, 2)
        love.graphics.setColor(Theme.colors.line)
        love.graphics.rectangle("fill", trackX, barY, 4, barH, 2, 2)
    end
    
    return {
        visibleLines = visibleLines,
        maxScroll = maxScroll
    }
end

return LogPanel
