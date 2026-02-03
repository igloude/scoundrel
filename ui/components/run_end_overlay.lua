-- RunEndOverlay - end-of-run summary and New Run button

local Theme = require("ui.theme")

local RunEndOverlay = {}

local function computeScore(state)
    if state.status == "won" then
        if state.player.hp == state.player.hpMax and state.lastResolvedCard and state.lastResolvedCard.type == "potion" then
            return state.player.hpMax + (state.lastResolvedCard.value or 0), true
        end
        return state.player.hp, false
    elseif state.status == "lost" then
        local penalty = state.remainingMonsterPenalty or 0
        return state.player.hp - penalty, false
    end
    return nil, false
end

function RunEndOverlay.draw(state, screenRect)
    if state.status ~= "won" and state.status ~= "lost" then
        return nil
    end
    
    local title = state.status == "won" and "Victory" or "Defeat"
    local score, specialWin = computeScore(state)
    
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, screenRect.w, screenRect.h)
    
    local panelW = math.min(520, screenRect.w * 0.7)
    local panelH = 260
    local panelX = (screenRect.w - panelW) / 2
    local panelY = (screenRect.h - panelH) / 2
    
    love.graphics.setColor(Theme.colors.panel)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, Theme.radii.lg, Theme.radii.lg)
    love.graphics.setColor(Theme.colors.line)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, Theme.radii.lg, Theme.radii.lg)
    
    love.graphics.setFont(Theme.fonts.xl)
    love.graphics.setColor(Theme.colors.text)
    love.graphics.print(title, panelX + 24, panelY + 16)
    
    love.graphics.setFont(Theme.fonts.lg)
    love.graphics.setColor(Theme.colors.text)
    love.graphics.print("Score: " .. tostring(score), panelX + 24, panelY + 64)
    
    love.graphics.setFont(Theme.fonts.sm)
    love.graphics.setColor(Theme.colors.textDim)
    if state.status == "won" then
        if specialWin then
            love.graphics.print("Full health (20) + last potion value", panelX + 24, panelY + 96)
        else
            love.graphics.print("Score equals remaining HP", panelX + 24, panelY + 96)
        end
    else
        local penalty = state.remainingMonsterPenalty or 0
        love.graphics.print("HP at defeat: " .. tostring(state.player.hp), panelX + 24, panelY + 96)
        love.graphics.print("Remaining monster penalty: -" .. tostring(penalty), panelX + 24, panelY + 114)
    end
    
    local btnW, btnH = 140, 36
    local btnX = panelX + panelW - btnW - 24
    local btnY = panelY + panelH - btnH - 20
    love.graphics.setColor(Theme.colors.accent)
    love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, Theme.radii.md, Theme.radii.md)
    love.graphics.setColor(Theme.colors.line)
    love.graphics.rectangle("line", btnX, btnY, btnW, btnH, Theme.radii.md, Theme.radii.md)
    love.graphics.setFont(Theme.fonts.md)
    love.graphics.setColor(Theme.colors.text)
    love.graphics.print("New Run", btnX + 22, btnY + 8)
    
    return {
        newRun = { x = btnX, y = btnY, w = btnW, h = btnH }
    }
end

function RunEndOverlay.hitTest(mx, my, layout)
    if not layout then return nil end
    local r = layout.newRun
    if mx >= r.x and mx <= r.x + r.w and my >= r.y and my <= r.y + r.h then
        return "newRun"
    end
    return nil
end

return RunEndOverlay
