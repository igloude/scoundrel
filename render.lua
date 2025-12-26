-- Scoundrel - Rendering module
-- All drawing functions for the game UI

local Cards = require("cards")
local State = require("state")

local Render = {}

-- Layout constants
Render.CARD_WIDTH = 120
Render.CARD_HEIGHT = 160
Render.CARD_SPACING = 20
Render.ROOM_Y = 120
Render.HUD_Y = 20
Render.LOG_Y = 320
Render.ERROR_Y = 350
Render.END_SCREEN_Y = 400

-- Colors
Render.COLORS = {
    background = {0.12, 0.11, 0.14},
    cardBg = {0.2, 0.2, 0.25},
    cardBorder = {0.4, 0.4, 0.5},
    cardBorderHover = {0.8, 0.8, 0.9},
    monster = {0.9, 0.35, 0.35},
    weapon = {0.4, 0.6, 0.95},
    potion = {0.4, 0.85, 0.5},
    text = {1, 1, 1},
    textDim = {0.6, 0.6, 0.6},
    hpFull = {0.3, 0.9, 0.4},
    hpLow = {0.9, 0.3, 0.3},
    error = {1, 0.3, 0.3},
    victory = {0.3, 1, 0.5},
    gameOver = {1, 0.2, 0.2},
    log = {1, 1, 0.7}
}

--------------------------------------------------------------------------------
-- J.1: layoutRoomSlots()
-- Returns an array of rectangles {x, y, w, h} for each room position
--------------------------------------------------------------------------------

function Render.layoutRoomSlots()
    local slots = {}
    local totalWidth = (Render.CARD_WIDTH * 4) + (Render.CARD_SPACING * 3)
    local startX = (800 - totalWidth) / 2  -- Center in 800px window
    
    for i = 1, State.ROOM_SIZE do
        slots[i] = {
            x = startX + (i - 1) * (Render.CARD_WIDTH + Render.CARD_SPACING),
            y = Render.ROOM_Y,
            w = Render.CARD_WIDTH,
            h = Render.CARD_HEIGHT
        }
    end
    
    return slots
end

--------------------------------------------------------------------------------
-- J.2: drawCardRect(card, rect, index)
-- Draws a card as a rectangle with suit symbol and value
--------------------------------------------------------------------------------

function Render.drawCardRect(card, rect, index)
    local cardType = Cards.cardType(card)
    local value = Cards.cardValue(card)
    
    -- Card background
    love.graphics.setColor(Render.COLORS.cardBg)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 8, 8)
    
    -- Card border (colored by type)
    local borderColor = Render.COLORS.cardBorder
    if cardType == "monster" then
        borderColor = Render.COLORS.monster
    elseif cardType == "weapon" then
        borderColor = Render.COLORS.weapon
    elseif cardType == "potion" then
        borderColor = Render.COLORS.potion
    end
    love.graphics.setColor(borderColor)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, 8, 8)
    
    -- Suit symbol (large, centered)
    local suitSymbols = {
        spades = "♠",
        clubs = "♣",
        hearts = "♥",
        diamonds = "♦"
    }
    local symbol = suitSymbols[card.suit] or "?"
    
    love.graphics.setColor(borderColor)
    local font = love.graphics.getFont()
    local symbolText = symbol
    love.graphics.print(symbolText, rect.x + rect.w/2 - 8, rect.y + 20)
    
    -- Rank (large)
    love.graphics.setColor(Render.COLORS.text)
    love.graphics.print(card.rank, rect.x + rect.w/2 - 8, rect.y + 50)
    
    -- Type label
    local typeLabel = cardType == "monster" and "Monster" or
                      cardType == "weapon" and "Weapon" or "Potion"
    love.graphics.setColor(Render.COLORS.textDim)
    love.graphics.print(typeLabel, rect.x + rect.w/2 - 25, rect.y + 90)
    
    -- Value
    love.graphics.setColor(Render.COLORS.text)
    love.graphics.print("Value: " .. value, rect.x + rect.w/2 - 25, rect.y + 110)
    
    -- Index label (bottom)
    love.graphics.setColor(Render.COLORS.textDim)
    love.graphics.print("[" .. index .. "]", rect.x + rect.w/2 - 8, rect.y + rect.h - 25)
end

--------------------------------------------------------------------------------
-- J.3: drawRoom(state)
-- Draws all room cards in their slots
--------------------------------------------------------------------------------

function Render.drawRoom(state)
    local slots = Render.layoutRoomSlots()
    
    -- Draw empty slot backgrounds for all positions
    love.graphics.setColor(0.15, 0.15, 0.18, 1)
    for i = 1, State.ROOM_SIZE do
        love.graphics.rectangle("fill", slots[i].x, slots[i].y, slots[i].w, slots[i].h, 8, 8)
        love.graphics.setColor(0.25, 0.25, 0.3, 1)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", slots[i].x, slots[i].y, slots[i].w, slots[i].h, 8, 8)
        love.graphics.setColor(0.15, 0.15, 0.18, 1)
    end
    
    -- Draw actual cards
    for i, card in ipairs(state.room.cards) do
        Render.drawCardRect(card, slots[i], i)
    end
    
    -- Room label
    love.graphics.setColor(Render.COLORS.textDim)
    love.graphics.print("The Room (press 1-4 to take, F+1-4 to flee)", 20, Render.ROOM_Y - 25)
end

--------------------------------------------------------------------------------
-- J.4: drawHud(state)
-- Draws HP, weapon, deck count, discard count
--------------------------------------------------------------------------------

function Render.drawHud(state)
    -- HP bar background
    local hpBarX = 20
    local hpBarY = Render.HUD_Y
    local hpBarW = 200
    local hpBarH = 24
    
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", hpBarX, hpBarY, hpBarW, hpBarH, 4, 4)
    
    -- HP bar fill
    local hpPercent = state.hp / state.maxHp
    local hpColor = hpPercent > 0.3 and Render.COLORS.hpFull or Render.COLORS.hpLow
    love.graphics.setColor(hpColor)
    love.graphics.rectangle("fill", hpBarX, hpBarY, hpBarW * hpPercent, hpBarH, 4, 4)
    
    -- HP text
    love.graphics.setColor(Render.COLORS.text)
    love.graphics.print(string.format("HP: %d / %d", state.hp, state.maxHp), hpBarX + 5, hpBarY + 4)
    
    -- Weapon
    local weaponX = 240
    love.graphics.setColor(Render.COLORS.weapon)
    if state.weapon then
        love.graphics.print(string.format("Weapon: %d", state.weapon.value), weaponX, hpBarY + 4)
    else
        love.graphics.setColor(Render.COLORS.textDim)
        love.graphics.print("Weapon: none", weaponX, hpBarY + 4)
    end
    
    -- Deck and discard counts
    love.graphics.setColor(Render.COLORS.textDim)
    love.graphics.print(string.format("Deck: %d", #state.deck), 400, hpBarY + 4)
    love.graphics.print(string.format("Discard: %d", #state.discard), 500, hpBarY + 4)
    
    -- Flee status
    local fleeX = 620
    if state.room.fleeUsed then
        love.graphics.setColor(0.5, 0.3, 0.3, 1)
        love.graphics.print("Flee: used", fleeX, hpBarY + 4)
    else
        love.graphics.setColor(0.3, 0.5, 0.3, 1)
        love.graphics.print("Flee: ready", fleeX, hpBarY + 4)
    end
    
    -- Second row: Monster memory (if weapon equipped)
    if state.weapon then
        love.graphics.setColor(Render.COLORS.textDim)
        local memSpades = state.turnFlags.lastWeaponHitBySuit.spades or "-"
        local memClubs = state.turnFlags.lastWeaponHitBySuit.clubs or "-"
        love.graphics.print(string.format("Last hit: ♠%s ♣%s", memSpades, memClubs), 20, hpBarY + 28)
    end
end

--------------------------------------------------------------------------------
-- J.5: drawLog(state)
-- Draws the last action log line
--------------------------------------------------------------------------------

function Render.drawLog(state)
    if state.lastLogLine and state.lastLogLine ~= "" then
        love.graphics.setColor(Render.COLORS.log)
        love.graphics.print(state.lastLogLine, 20, Render.LOG_Y)
    end
end

--------------------------------------------------------------------------------
-- J.6: drawError(state)
-- Draws any error message
--------------------------------------------------------------------------------

function Render.drawError(state)
    if state.errorMessage then
        love.graphics.setColor(Render.COLORS.error)
        love.graphics.print("Error: " .. state.errorMessage, 20, Render.ERROR_Y)
    end
end

--------------------------------------------------------------------------------
-- J.7: drawEndScreen(state)
-- Draws victory or game over overlay
--------------------------------------------------------------------------------

function Render.drawEndScreen(state)
    if state.runState == State.RunState.VICTORY then
        -- Victory overlay
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, 800, 600)
        
        love.graphics.setColor(Render.COLORS.victory)
        love.graphics.print("VICTORY!", 320, 250)
        love.graphics.setColor(Render.COLORS.text)
        love.graphics.print("You survived the dungeon!", 280, 290)
        love.graphics.setColor(Render.COLORS.textDim)
        love.graphics.print("Press R to play again", 300, 330)
        
    elseif state.runState == State.RunState.GAME_OVER then
        -- Game over overlay
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, 800, 600)
        
        love.graphics.setColor(Render.COLORS.gameOver)
        love.graphics.print("GAME OVER", 310, 250)
        love.graphics.setColor(Render.COLORS.text)
        love.graphics.print("The dungeon claimed another soul...", 250, 290)
        love.graphics.setColor(Render.COLORS.textDim)
        love.graphics.print("Press R to try again", 305, 330)
    end
end

--------------------------------------------------------------------------------
-- drawControls()
-- Draws control hints at the bottom
--------------------------------------------------------------------------------

function Render.drawControls()
    love.graphics.setColor(Render.COLORS.textDim)
    love.graphics.print("1-4 or Left-Click=Take  |  F+1-4 or Right-Click=Flee  |  R=Reset  D=Debug  ESC=Quit", 20, 570)
end

--------------------------------------------------------------------------------
-- drawDebug(state, game)
-- Draws debug information when enabled
--------------------------------------------------------------------------------

function Render.drawDebug(state, game)
    -- Run assertions
    local assertionsOk, assertionErrors = State.runAllAssertions(state)
    local assertionStatus = assertionsOk and "✓ All OK" or "✗ ERRORS"
    
    local debugInfo = string.format(
        "DEBUG: Seed=%s Fixed=%s RunState=%s Flee=%s\n" ..
        "Monster Memory: ♠=%s ♣=%s | Assertions: %s",
        tostring(state.seed),
        tostring(game.useFixedSeed),
        state.runState,
        tostring(state.room.fleeUsed),
        tostring(state.turnFlags.lastWeaponHitBySuit.spades),
        tostring(state.turnFlags.lastWeaponHitBySuit.clubs),
        assertionStatus
    )
    love.graphics.setColor(0, 1, 0.5, 1)
    love.graphics.print(debugInfo, 20, 380)
    
    -- Show assertion errors if any
    if not assertionsOk and assertionErrors then
        love.graphics.setColor(1, 0.3, 0.3, 1)
        for i, err in ipairs(assertionErrors) do
            love.graphics.print("! " .. err, 20, 420 + (i-1) * 16)
        end
    end
end

--------------------------------------------------------------------------------
-- K.1: indexFromMouseClick(x, y)
-- Returns the room card index (1-4) at position (x, y), or nil if none
--------------------------------------------------------------------------------

function Render.indexFromMouseClick(x, y)
    local slots = Render.layoutRoomSlots()
    
    for i, slot in ipairs(slots) do
        if x >= slot.x and x <= slot.x + slot.w and
           y >= slot.y and y <= slot.y + slot.h then
            return i
        end
    end
    
    return nil
end

return Render

