-- Scoundrel - Love2D entry point with UI layer

---@diagnostic disable: lowercase-global, undefined-global

local Cards = require("cards")
local State = require("state")
local Actions = require("actions")

local Theme = require("ui.theme")
local ScreenMain = require("ui.screen_main")
local ChoicePanel = require("ui.components.choice_panel")
local ActionBar = require("ui.components.action_bar")
local ToastManager = require("ui.components.toast_manager")
local RoomView = require("ui.components.room_view")
local Keybindings = require("ui.keybindings")
local RunEndOverlay = require("ui.components.run_end_overlay")

local app = {}

local function createUiState()
    return {
        selectedIndex = nil,
        focusedIndex = 1,
        hoverIndex = nil,
        visualStates = {},
        log = {"UI ready"},
        hpDisplay = 20,
        reducedMotion = false,
        highContrast = false,
        cardAnims = {},
        cardScale = 1
    }
end

local function pushLog(text)
    table.insert(app.ui.log, 1, text)
    if #app.ui.log > 20 then
        table.remove(app.ui.log)
    end
end

local function pushToast(text)
    ToastManager.push(app.toasts, text, 2.4)
end

local function dispatch(eventName, payload)
    local msg = eventName
    if payload and payload.cardId then
        msg = string.format("%s (card %d)", eventName, payload.cardId)
    end
    print(msg)
end

local function newRun()
    local seed = os.time()
    app.game = {}
    app.game.state = State.createNewGameState(seed)
    app.game.state = State.dealRoomUpToFull(app.game.state)
    app.game.state = Actions.beginTurn(app.game.state)
    app.game.state.runState = State.RunState.AWAITING
    app.ui = createUiState()
    app.ui.hpDisplay = app.game.state.hp
    pushLog("New run started")
end

local function buildViewState(gameState, ui)
    local roomCards = {}
    local slotByIndex = {}
    for slot = 1, State.ROOM_SIZE do
        local card = gameState.room.cards[slot]
        if card then
            local cardType = Cards.cardType(card)
            local cardValue = Cards.cardValue(card)
            table.insert(roomCards, {
                id = card.id,
                suit = card.suit,
                rank = card.rank,
                type = cardType,
                value = cardValue,
                carriedFromLastTurn = (gameState.turnFlags.carryOverCardId == card.id)
            })
            slotByIndex[#roomCards] = slot
        end
    end

    local lastResolvedCard = nil
    if gameState.lastResolvedCard then
        lastResolvedCard = {
            type = Cards.cardType(gameState.lastResolvedCard),
            value = Cards.cardValue(gameState.lastResolvedCard)
        }
    end

    local remainingMonsterPenalty = 0
    for _, card in ipairs(gameState.deck) do
        if Cards.isMonster(card) then
            remainingMonsterPenalty = remainingMonsterPenalty + Cards.cardValue(card)
        end
    end

    local status = nil
    if gameState.runState == State.RunState.VICTORY then
        status = "won"
    elseif gameState.runState == State.RunState.GAME_OVER then
        status = "lost"
    end

    return {
        player = {
            hp = gameState.hp,
            hpMax = gameState.maxHp,
            weapon = gameState.weapon and {
                value = gameState.weapon.value,
                lastSlainMonsterValue = gameState.turnFlags.lastMonsterSlain
            } or nil
        },
        turn = {
            potionUsedThisTurn = gameState.turnFlags.potionUsedThisTurn,
            previousTurnAvoided = gameState.turnFlags.lastTurnWasAvoid
        },
        room = {
            cards = roomCards,
            slotByIndex = slotByIndex
        },
        config = {
            roomSize = State.ROOM_SIZE
        },
        dungeonCount = #gameState.deck,
        discardCount = #gameState.discard,
        status = status,
        lastResolvedCard = lastResolvedCard,
        remainingMonsterPenalty = remainingMonsterPenalty,
        ui = ui
    }
end

local function clearSelection()
    app.ui.selectedIndex = nil
end

local function cardSummary(card)
    local suitSymbol = ({ spades = "♠", clubs = "♣", hearts = "♥", diamonds = "♦" })
    local sym = suitSymbol[card.suit] or "?"
    return string.format("%s%s (%s)", card.rank, sym, string.upper(card.type))
end

local function syncGameLog(gameState)
    if gameState.lastLogLine and gameState.lastLogLine ~= "" and gameState.lastLogLine ~= app.ui.lastGameLog then
        app.ui.lastGameLog = gameState.lastLogLine
        pushLog(gameState.lastLogLine)
    end
    if gameState.errorMessage and gameState.errorMessage ~= "" then
        pushLog("Action blocked: " .. gameState.errorMessage)
        pushToast(gameState.errorMessage)
        gameState = State.clearError(gameState)
    end
    return gameState
end

local function resolveCard(viewState, mode, canWeapon)
    local selected = app.ui.selectedIndex and viewState.room.cards[app.ui.selectedIndex] or nil
    if not selected then return end
    local slot = viewState.room.slotByIndex[app.ui.selectedIndex]
    if not slot then return end

    if selected.type == "monster" then
        if mode == "barehanded" then
            pushLog("Fight barehanded: " .. cardSummary(selected))
            app.game.state = Actions.applyTake(app.game.state, slot, false)
        else
            if canWeapon and canWeapon.ok then
                pushLog("Fight with weapon: " .. cardSummary(selected))
                app.game.state = Actions.applyTake(app.game.state, slot, true)
            else
                local reason = (canWeapon and canWeapon.reason) or "Weapon fight blocked"
                pushLog("Attempted weapon fight: blocked (" .. reason .. ")")
                pushToast(reason)
                return
            end
        end
        RoomView.startResolve(app.ui, selected.id)
        dispatch("onResolveCard", { cardId = selected.id, kind = "monster", mode = mode })
    elseif selected.type == "potion" then
        pushLog("Use potion: " .. cardSummary(selected))
        app.game.state = Actions.applyTake(app.game.state, slot)
        RoomView.startResolve(app.ui, selected.id)
        dispatch("onResolveCard", { cardId = selected.id, kind = "potion" })
    elseif selected.type == "weapon" then
        pushLog("Equip weapon: " .. cardSummary(selected))
        app.game.state = Actions.applyTake(app.game.state, slot)
        RoomView.startResolve(app.ui, selected.id)
        dispatch("onResolveCard", { cardId = selected.id, kind = "weapon" })
    end

    app.game.state = syncGameLog(app.game.state)
    if not app.game.state.errorMessage then
        clearSelection()
    end
end

function love.load()
    Theme.init()
    app.toasts = ToastManager.new()
    newRun()
end

function love.update(dt)
    local viewState = buildViewState(app.game.state, app.ui)

    local mx, my = love.mouse.getPosition()
    local hoverIndex = ScreenMain.hitTestRoom(viewState, mx, my)
    app.ui.hoverIndex = hoverIndex
    app.ui.visualStates = ScreenMain.computeVisualStates(viewState, hoverIndex)
    ToastManager.update(app.toasts, dt)

    if app.ui.reducedMotion then
        app.ui.hpDisplay = app.game.state.hp
    else
        local target = app.game.state.hp
        local current = app.ui.hpDisplay
        app.ui.hpDisplay = current + (target - current) * math.min(1, dt * 10)
    end

    local completed = RoomView.update(viewState.room.cards, app.ui.visualStates, dt, app.ui)
    for _, cardId in ipairs(completed) do
        pushLog("Resolve animation complete (card " .. cardId .. ")")
        dispatch("onResolveAnimationComplete", { cardId = cardId })
    end
end

function love.draw()
    local viewState = buildViewState(app.game.state, app.ui)
    app.layout = ScreenMain.draw(viewState, app.toasts)
end

function love.mousepressed(x, y, button)
    local viewState = buildViewState(app.game.state, app.ui)

    if app.layout and app.layout.overlayLayout then
        local hit = RunEndOverlay.hitTest(x, y, app.layout.overlayLayout)
        if hit == "newRun" then
            pushLog("New Run requested")
            dispatch("onNewRun")
            newRun()
            return
        end
    end

    if app.layout and app.layout.actionLayout then
        local hit = ActionBar.hitTest(x, y, app.layout.actionLayout)
        if hit == "avoid" then
            if app.layout.actionLayout.avoid.enabled then
                pushLog("Avoid Room")
                app.game.state = Actions.applyAvoid(app.game.state)
                app.game.state = syncGameLog(app.game.state)
                dispatch("onAvoidRoom")
                clearSelection()
            else
                local reason = app.layout.actionLayout.avoid.reason or "Avoid blocked"
                pushLog("Avoid Room: blocked (" .. reason .. ")")
                pushToast(reason)
            end
            return
        end
    end

    local index = ScreenMain.hitTestRoom(viewState, x, y)
    if index then
        local card = viewState.room.cards[index]
        app.ui.selectedIndex = index
        app.ui.focusedIndex = index
        if card.type == "monster" then
            if button == 2 then
                resolveCard(viewState, "barehanded", { ok = true })
            else
                local Selectors = require("ui.selectors")
                local canWeapon = Selectors.canWeaponFight(viewState, card)
                if canWeapon.ok then
                    resolveCard(viewState, "weapon", canWeapon)
                else
                    resolveCard(viewState, "barehanded", { ok = true })
                end
            end
        elseif card.type == "potion" then
            if button == 1 then
                resolveCard(viewState, "potion")
            end
        elseif card.type == "weapon" then
            if button == 1 then
                resolveCard(viewState, "weapon")
            end
        end
    else
        clearSelection()
        pushLog("Selection cleared")
    end
end

function love.keypressed(key)
    local viewState = buildViewState(app.game.state, app.ui)
    local handled = Keybindings.handle(viewState, key, {
        onFocus = function(idx)
            app.ui.focusedIndex = idx
            local card = viewState.room.cards[idx]
            pushLog("Focus " .. cardSummary(card))
        end,
        onSelect = function(idx)
            app.ui.selectedIndex = idx
            app.ui.focusedIndex = idx
            local card = viewState.room.cards[idx]
            pushLog("Selected " .. cardSummary(card))
            dispatch("card_selected", { cardId = card.id })
        end,
        onClear = function()
            clearSelection()
            pushLog("Selection cleared")
        end,
        onAvoid = function(canAvoid)
            if canAvoid.ok then
                pushLog("Avoid Room")
                app.game.state = Actions.applyAvoid(app.game.state)
                app.game.state = syncGameLog(app.game.state)
                dispatch("onAvoidRoom")
                clearSelection()
            else
                local reason = canAvoid.reason or "Avoid blocked"
                pushLog("Avoid Room: blocked (" .. reason .. ")")
                pushToast(reason)
            end
        end,
        onResolveMonster = function(mode, canWeapon)
            resolveCard(viewState, mode, canWeapon)
        end
    })
    if handled then return end

    if key == "escape" then
        love.event.quit()
    elseif key == "m" then
        app.ui.reducedMotion = not app.ui.reducedMotion
        local label = app.ui.reducedMotion and "ON" or "OFF"
        pushLog("Reduced motion: " .. label)
        pushToast("Reduced motion " .. label)
    elseif key == "h" then
        app.ui.highContrast = not app.ui.highContrast
        Theme.setHighContrast(app.ui.highContrast)
        local label = app.ui.highContrast and "ON" or "OFF"
        pushLog("High contrast: " .. label)
        pushToast("High contrast " .. label)
    end
end
