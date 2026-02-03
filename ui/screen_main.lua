-- ScreenMain - layout shell and render UI regions

local Theme = require("ui.theme")
local RoomView = require("ui.components.room_view")
local ActionBar = require("ui.components.action_bar")
local ChoicePanel = require("ui.components.choice_panel")
local HudHp = require("ui.components.hud_hp")
local HudWeapon = require("ui.components.hud_weapon")
local HudCounts = require("ui.components.hud_counts")
local LogPanel = require("ui.components.log_panel")
local ToastManager = require("ui.components.toast_manager")
local RunEndOverlay = require("ui.components.run_end_overlay")

local ScreenMain = {}

local function computeLayout(w, h)
    local pad = Theme.spacing.lg
    local rightWidth = math.max(220, math.floor(w * 0.24))
    local topHeight = (w < 780) and 140 or 90
    local bottomHeight = 70
    local collapseLog = w < 900
    local drawerHeight = collapseLog and 120 or 0
    
    local hud = {
        x = pad,
        y = pad,
        w = w - (collapseLog and 0 or rightWidth) - pad * 2,
        h = topHeight
    }
    local log = {
        x = collapseLog and pad or (w - rightWidth + pad * 0.5),
        y = collapseLog and (h - bottomHeight - drawerHeight - pad) or pad,
        w = collapseLog and (w - pad * 2) or (rightWidth - pad * 1.5),
        h = collapseLog and drawerHeight or (h - pad * 2)
    }
    local room = {
        x = pad,
        y = hud.y + hud.h + pad,
        w = w - (collapseLog and 0 or rightWidth) - pad * 2,
        h = h - hud.h - bottomHeight - drawerHeight - pad * 3
    }
    local action = {
        x = pad,
        y = h - bottomHeight - pad,
        w = w - (collapseLog and 0 or rightWidth) - pad * 2,
        h = bottomHeight
    }
    return hud, room, action, log, collapseLog
end

local function drawPanel(rect, label)
    love.graphics.setColor(Theme.colors.panel)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, Theme.radii.lg, Theme.radii.lg)
    love.graphics.setColor(Theme.colors.line)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, Theme.radii.lg, Theme.radii.lg)
    
    if label then
        love.graphics.setFont(Theme.fonts.sm)
        love.graphics.setColor(Theme.colors.textDim)
        love.graphics.print(label, rect.x + Theme.spacing.md, rect.y + Theme.spacing.md)
    end
end

function ScreenMain.draw(state, toastState)
    local w, h = love.graphics.getDimensions()
    local hud, room, action, log, collapsed = computeLayout(w, h)
    
    love.graphics.clear(Theme.colors.bg)
    
    drawPanel(hud, "HUD")
    drawPanel(room, "ROOM")
    -- Action bar is drawn by component
    
    -- HUD content
    local hpRect = { x = hud.x + 8, y = hud.y + 8, w = 200, h = hud.h - 16 }
    local weaponRect = { x = hud.x + 220, y = hud.y + 8, w = 200, h = hud.h - 16 }
    local countsRect = { x = hud.x + 432, y = hud.y + 8, w = 170, h = hud.h - 16 }
    if hud.h > 120 then
        weaponRect.x = hud.x + 8
        weaponRect.y = hud.y + 70
        countsRect.x = hud.x + 220
        countsRect.y = hud.y + 70
    end
    HudHp.draw(hpRect, state.player.hp, state.player.hpMax, state.ui.hpDisplay)
    HudWeapon.draw(weaponRect, state.player.weapon)
    HudCounts.draw(countsRect, state.dungeonCount, state.discardCount)
    
    -- Room cards
    local scaleW = room.w / 680
    local scaleH = room.h / 320
    state.ui.cardScale = math.max(0.75, math.min(1, scaleW, scaleH))
    RoomView.bindUi(state.ui)
    RoomView.draw(room, state.room.cards, state.ui.visualStates)
    
    -- Action bar
    local actionLayout = ActionBar.draw(action, state)
    
    -- Log region
    LogPanel.draw(log, state.ui.log)
    if toastState then
        ToastManager.draw(toastState, log)
    end
    
    -- Choice panel
    local choiceRect = { x = action.x + 200, y = action.y - 100, w = 420, h = 120 }
    local selectedCard = state.ui.selectedIndex and state.room.cards[state.ui.selectedIndex] or nil
    local choiceLayout = ChoicePanel.draw(choiceRect, state, selectedCard)
    
    local overlayLayout = RunEndOverlay.draw(state, { w = w, h = h })
    
    return {
        hud = hud,
        room = room,
        action = action,
        log = log,
        collapsed = collapsed,
        actionLayout = actionLayout,
        choiceLayout = choiceLayout,
        choiceRect = choiceRect,
        overlayLayout = overlayLayout
    }
end

function ScreenMain.hitTestRoom(state, mx, my)
    local w, h = love.graphics.getDimensions()
    local _, room = computeLayout(w, h)
    return RoomView.hitTest(room, state.room.cards, mx, my)
end

function ScreenMain.computeVisualStates(state, hoverIndex)
    local visualStates = {}
    for i = 1, #state.room.cards do
        if state.ui.selectedIndex == i then
            visualStates[i] = "selected"
        elseif hoverIndex == i then
            visualStates[i] = "hovered"
        else
            visualStates[i] = "idle"
        end
    end
    return visualStates
end

function ScreenMain.computeLayout()
    local w, h = love.graphics.getDimensions()
    return computeLayout(w, h)
end

return ScreenMain
