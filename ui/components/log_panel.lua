-- LogPanel - persistent action log (most recent on top)

local Theme = require("ui.theme")

local LogPanel = {}

function LogPanel.draw(rect, logEntries)
    love.graphics.setColor(Theme.colors.panel)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, Theme.radii.lg, Theme.radii.lg)
    love.graphics.setColor(Theme.colors.line)
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, Theme.radii.lg, Theme.radii.lg)
    
    love.graphics.setFont(Theme.fonts.sm)
    love.graphics.setColor(Theme.colors.textDim)
    love.graphics.print("LOG / TOAST", rect.x + 10, rect.y + 10)
    
    local y = rect.y + 30
    local max = math.min(#logEntries, 20)
    for i = 1, max do
        local entry = logEntries[i]
        love.graphics.setColor(Theme.colors.text)
        love.graphics.print(entry, rect.x + 10, y)
        y = y + 16
    end
end

return LogPanel
