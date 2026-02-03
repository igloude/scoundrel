-- ToastManager - simple queue with timeouts

local Theme = require("ui.theme")

local ToastManager = {}

function ToastManager.new()
    return {
        items = {}
    }
end

function ToastManager.push(toastState, message, duration)
    local ttl = duration or 2.5
    table.insert(toastState.items, {
        message = message,
        ttl = ttl
    })
end

function ToastManager.update(toastState, dt)
    for i = #toastState.items, 1, -1 do
        local t = toastState.items[i]
        t.ttl = t.ttl - dt
        if t.ttl <= 0 then
            table.remove(toastState.items, i)
        end
    end
end

function ToastManager.draw(toastState, rect)
    local y = rect.y + 8
    for i = 1, math.min(4, #toastState.items) do
        local toast = toastState.items[i]
        love.graphics.setColor(Theme.colors.panel)
        love.graphics.rectangle("fill", rect.x + 8, y, rect.w - 16, 26, Theme.radii.md, Theme.radii.md)
        love.graphics.setColor(Theme.colors.line)
        love.graphics.rectangle("line", rect.x + 8, y, rect.w - 16, 26, Theme.radii.md, Theme.radii.md)
        love.graphics.setFont(Theme.fonts.sm)
        love.graphics.setColor(Theme.colors.text)
        love.graphics.print(toast.message, rect.x + 16, y + 6)
        y = y + 30
    end
end

return ToastManager
