-- RoomView - renders room cards in a slight arc and handles hit detection

local Theme = require("ui.theme")
local CardView = require("ui.components.card_view")
local Motion = require("ui.motion")
local MotionRegistry = require("ui.motion_registry")

local RoomView = {}

local function ensureAnim(ui, cardId)
    ui.cardAnims = ui.cardAnims or {}
    if not ui.cardAnims[cardId] then
        ui.cardAnims[cardId] = {
            hover = 0,
            select = 0,
            scale = 1,
            tilt = 0,
            lift = 0,
            resolve = nil,
            wasSelected = false
        }
    end
    return ui.cardAnims[cardId]
end

function RoomView.layout(roomRect, cards)
    local count = #cards
    local positions = {}
    if count == 0 then return positions end
    
    local scale = 1
    if RoomView._ui and RoomView._ui.cardScale then
        scale = RoomView._ui.cardScale
    end
    local cardW = Theme.card.width * scale
    local cardH = Theme.card.height * scale
    
    local centerX = roomRect.x + roomRect.w * 0.5
    local centerY = roomRect.y + roomRect.h * 0.52
    local spacing = cardW + Theme.spacing.md
    local totalW = spacing * (count - 1) + cardW
    local startX = centerX - totalW / 2
    
    for i, card in ipairs(cards) do
        positions[i] = {
            card = card,
            x = startX + (i - 1) * spacing,
            y = centerY,
            w = cardW,
            h = cardH,
            rot = 0
        }
    end
    
    return positions
end

function RoomView.draw(roomRect, cards, visualStates)
    local positions = RoomView.layout(roomRect, cards)
    for i, pos in ipairs(positions) do
        local state = visualStates[i] or "idle"
        local lift = 0
        local scale = 1
        local tilt = 0
        local offsetX = 0
        local offsetY = 0
        
        if RoomView._ui and pos.card.id then
            local anim = ensureAnim(RoomView._ui, pos.card.id)
            lift = anim.lift
            scale = anim.scale
            tilt = anim.tilt
            if anim.resolve then
                offsetX = anim.resolve.offsetX
                offsetY = anim.resolve.offsetY
            end
        else
            if state == "hovered" then
                lift = Theme.card.liftHover
            elseif state == "selected" then
                lift = Theme.card.liftSelected
            end
        end
        
        love.graphics.push()
        love.graphics.translate(pos.x + pos.w / 2 + offsetX, pos.y + pos.h / 2 - lift + offsetY)
        love.graphics.rotate(pos.rot + tilt)
        love.graphics.scale(scale, scale)
        CardView.draw(pos.card, { x = -pos.w / 2, y = -pos.h / 2, w = pos.w, h = pos.h }, state)
        if RoomView._ui and RoomView._ui.focusedIndex == i then
            love.graphics.setColor(Theme.colors.focus)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", -pos.w / 2 - 4, -pos.h / 2 - 4, pos.w + 8, pos.h + 8, Theme.radii.md, Theme.radii.md)
        end
        love.graphics.pop()
    end
end

function RoomView.hitTest(roomRect, cards, mx, my)
    local positions = RoomView.layout(roomRect, cards)
    -- Iterate from topmost to bottommost
    for i = #positions, 1, -1 do
        local pos = positions[i]
        local dx = mx - (pos.x + pos.w / 2)
        local dy = my - (pos.y + pos.h / 2)
        local cosr = math.cos(-pos.rot)
        local sinr = math.sin(-pos.rot)
        local lx = dx * cosr - dy * sinr
        local ly = dx * sinr + dy * cosr
        if math.abs(lx) <= pos.w / 2 and math.abs(ly) <= pos.h / 2 then
            return i
        end
    end
    return nil
end

function RoomView.bindUi(ui)
    RoomView._ui = ui
end

function RoomView.update(cards, visualStates, dt, ui)
    RoomView.bindUi(ui)
    local completed = {}
    if not ui or not cards then return completed end
    
    local reduced = ui.reducedMotion
    local count = #cards
    local mid = (count + 1) / 2
    
    for i, card in ipairs(cards) do
        if card.id then
            local anim = ensureAnim(ui, card.id)
            local state = visualStates[i] or "idle"
            local hoverTarget = (state == "hovered" or state == "selected") and 1 or 0
            local selectTarget = (state == "selected") and 1 or 0
            local tiltSign = (i - mid) / math.max(1, mid)
            
            if reduced then
                anim.hover = hoverTarget
                anim.select = selectTarget
                anim.lift = hoverTarget == 1 and Theme.card.liftHover or 0
                if selectTarget == 1 then
                    anim.lift = Theme.card.liftSelected
                end
                anim.scale = 1
                anim.tilt = hoverTarget * 0.06 * tiltSign
                MotionRegistry.setAlpha(card.id, 1)
                if anim.resolve then
                    anim.resolve = nil
                    table.insert(completed, card.id)
                end
            else
                anim.hover = Motion.approach(anim.hover, hoverTarget, 10, dt)
                anim.select = Motion.approach(anim.select, selectTarget, 12, dt)
                
                anim.lift = Motion.lerp(0, Theme.card.liftHover, anim.hover)
                if anim.select > 0 then
                    anim.lift = Motion.lerp(anim.lift, Theme.card.liftSelected, anim.select)
                end
                
                if selectTarget == 1 and not anim.wasSelected then
                    anim.snapTimer = 0
                end
                anim.wasSelected = (selectTarget == 1)
                
                if anim.snapTimer ~= nil then
                    anim.snapTimer = anim.snapTimer + dt
                    local t = anim.snapTimer / 0.12
                    if t < 1 then
                        anim.scale = 1 + 0.08 * Motion.easeOutBack(t)
                    else
                        anim.scale = Motion.approach(anim.scale, 1, 8, dt)
                        if anim.scale < 1.005 then
                            anim.scale = 1
                            anim.snapTimer = nil
                        end
                    end
                else
                    anim.scale = Motion.approach(anim.scale, 1, 8, dt)
                end
                
                anim.tilt = Motion.approach(anim.tilt, anim.hover * 0.06 * tiltSign, 8, dt)
                
                if anim.resolve then
                    anim.resolve.time = anim.resolve.time + dt
                    local t = Motion.clamp01(anim.resolve.time / anim.resolve.duration)
                    local eased = Motion.easeInQuad(t)
                    anim.resolve.offsetX = Motion.lerp(0, anim.resolve.targetX, eased)
                    anim.resolve.offsetY = Motion.lerp(0, anim.resolve.targetY, eased)
                    local alpha = Motion.lerp(1, 0, eased)
                    MotionRegistry.setAlpha(card.id, alpha)
                    if t >= 1 then
                        anim.resolve = nil
                        MotionRegistry.setAlpha(card.id, 1)
                        table.insert(completed, card.id)
                    end
                else
                    MotionRegistry.setAlpha(card.id, 1)
                end
            end
        end
    end
    
    return completed
end

function RoomView.startResolve(ui, cardId)
    if not ui or not cardId then return end
    ui.cardAnims = ui.cardAnims or {}
    local anim = ui.cardAnims[cardId]
    if not anim then
        anim = ensureAnim(ui, cardId)
    end
    if ui.reducedMotion then
        anim.resolve = nil
        return
    end
    anim.resolve = {
        time = 0,
        duration = 0.35,
        targetX = 140,
        targetY = 90,
        offsetX = 0,
        offsetY = 0
    }
end

return RoomView
