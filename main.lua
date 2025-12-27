-- Scoundrel - A digital adaptation of the solo card game
-- main.lua - Love2D entry point

---@diagnostic disable: lowercase-global, undefined-global

-- Modules
local Cards = require("cards")
local Deck = require("deck")
local State = require("state")
local Actions = require("actions")
local Render = require("render")

-- Game state holder (initialized in love.load)
local game = {}

-- Forward declarations for game functions
local function gameLoad() end
local function gameUpdate(dt) end
local function gameDraw() end
local function gameKeypressed(key) end
local function gameMousepressed(x, y, button) end
local function resetGame() end

--------------------------------------------------------------------------------
-- Love2D Callbacks
--------------------------------------------------------------------------------

function love.load()
    game = {}
    gameLoad()
end

function love.update(dt)
    gameUpdate(dt)
end

function love.draw()
    gameDraw()
end

function love.keypressed(key)
    gameKeypressed(key)
end

function love.mousepressed(x, y, button)
    gameMousepressed(x, y, button)
end

--------------------------------------------------------------------------------
-- Game Functions
--------------------------------------------------------------------------------

function gameLoad()
    -- Meta state (persists across resets)
    game.debug = false
    game.useFixedSeed = false
    game.fixedSeed = 12345
    
    -- Determine seed
    local seed = game.useFixedSeed and game.fixedSeed or os.time()
    
    -- Create game state using State module
    game.state = State.createNewGameState(seed)
    
    -- Deal initial room
    game.state = State.dealRoomUpToFull(game.state)
    game.state.runState = State.RunState.AWAITING
    
    -- Validate no duplicates at start
    local valid, err = State.assertNoDuplicateCards(game.state)
    if not valid then
        print("=== DUPLICATE CARD BUG AT START ===")
        print(err)
        print("====================================")
    end
    
    -- UI message
    game.message = "Scoundrel - Press R to reset, D to toggle debug"
end

function gameUpdate(dt)
    -- Pass-through to game update logic
    -- (No-op for now)
end

function gameDraw()
    -- Clear with background color
    love.graphics.clear(Render.COLORS.background)
    
    if not game.state then return end
    
    -- Draw all UI elements using Render module
    Render.drawHud(game.state)
    Render.drawRoom(game.state)
    Render.drawLog(game.state)
    Render.drawError(game.state)
    Render.drawControls()
    
    -- Debug overlay
    if game.debug then
        Render.drawDebug(game.state, game)
    end
    
    -- End screen overlay (drawn last, on top)
    Render.drawEndScreen(game.state)
end

function gameKeypressed(key)
    if key == "r" then
        -- Reset the run to fresh game state
        resetGame()
    elseif key == "d" then
        -- Toggle debug flag
        game.debug = not game.debug
    elseif key == "s" and game.debug then
        -- Toggle fixed seed (only in debug mode)
        game.useFixedSeed = not game.useFixedSeed
        resetGame()
    elseif key == "p" and game.debug then
        -- Print state dump to console
        printStateDump()
    elseif key == "t" and game.debug then
        -- Run automated duplicate test
        local allPassed = true
        for i = 1, 10 do
            local passed = runAutomatedDuplicateTest(os.time() + i * 12345)
            allPassed = allPassed and passed
        end
        print(allPassed and "=== ALL TESTS PASSED ===" or "=== SOME TESTS FAILED ===")
        -- Reset to current game
        resetGame()
    elseif key == "space" and game.debug then
        -- Auto-play: take first available card (for stress testing)
        autoPlayStep()
    elseif key == "escape" then
        love.event.quit()
    -- Card actions with 1-4 keys
    elseif key == "1" or key == "2" or key == "3" or key == "4" then
        local index = tonumber(key)
        -- F+number = flee, number alone = take
        if love.keyboard.isDown("f") then
            game.state = Actions.applyFlee(game.state, index)
        else
            game.state = Actions.applyTake(game.state, index)
        end
    end
end

function gameMousepressed(x, y, button)
    if not game.state then return end
    
    -- Check if click is on a room card
    local index = Render.indexFromMouseClick(x, y)
    if not index then return end
    
    -- Check if there's a card at this index (room uses sparse array, can't use #)
    if not game.state.room.cards[index] then return end
    
    -- Left click = take, right click = flee
    if button == 1 then
        game.state = Actions.applyTake(game.state, index)
    elseif button == 2 then
        game.state = Actions.applyFlee(game.state, index)
    end
end

function resetGame()
    -- Determine seed
    local seed = game.useFixedSeed and game.fixedSeed or os.time()
    
    -- Create fresh game state
    game.state = State.createNewGameState(seed)
    
    -- Deal initial room
    game.state = State.dealRoomUpToFull(game.state)
    game.state.runState = State.RunState.AWAITING
    
    game.message = "Game reset! Seed: " .. seed
end

--------------------------------------------------------------------------------
-- Debug Utilities
--------------------------------------------------------------------------------

-- L.1: Print concise state dump to console
function printStateDump()
    if not game.state then 
        print("No game state")
        return 
    end
    
    local s = game.state
    print("========== STATE DUMP ==========")
    print(string.format("Seed: %s | RunState: %s", s.seed, s.runState))
    print(string.format("HP: %d/%d | Weapon: %s", s.hp, s.maxHp, 
        s.weapon and tostring(s.weapon.value) or "none"))
    print(string.format("Deck: %d | Discard: %d | Flee: %s", 
        #s.deck, #s.discard, tostring(s.room.fleeUsed)))
    
    -- Room cards with full IDs (handles sparse array)
    print("Room cards:")
    for i = 1, State.ROOM_SIZE do
        local card = s.room.cards[i]
        if card then
            print(string.format("  [%d] %s (id=%d, %s, value %d)", 
                i, Cards.cardToString(card), card.id or 0, Cards.cardType(card), Cards.cardValue(card)))
        else
            print(string.format("  [%d] (empty)", i))
        end
    end
    
    -- Weapon target constraint
    local lastSlain = s.turnFlags.lastMonsterSlain
    if lastSlain then
        print(string.format("Weapon can hit: < %d", lastSlain))
    else
        print("Weapon can hit: any monster")
    end
    
    -- Run duplicate assertion
    local valid, err = State.assertNoDuplicateCards(s)
    if valid then
        print("Card integrity: OK (no duplicates)")
    else
        print("Card integrity: FAILED - " .. err)
    end
    
    -- Total card count (should always equal 44)
    local totalCards = #s.deck + #s.discard + State.roomCardCount(s)
    if s.weapon and s.weapon.card then
        totalCards = totalCards + 1
    end
    print(string.format("Total cards accounted for: %d/44", totalCards))
    
    print("================================")
end

-- L.5: Auto-play one step (take first available card)
function autoPlayStep()
    if not game.state then return end
    
    local s = game.state
    
    -- Check if game is over
    if s.runState == State.RunState.GAME_OVER or 
       s.runState == State.RunState.VICTORY then
        print("Auto-play: Game ended")
        return
    end
    
    -- Check if room has cards (use roomCardCount for sparse array)
    if State.roomCardCount(s) == 0 then
        print("Auto-play: Room empty")
        return
    end
    
    -- Simple strategy: take first available card (handle sparse array)
    for i = 1, State.ROOM_SIZE do
        if s.room.cards[i] then
            game.state = Actions.applyTake(game.state, i)
            print(string.format("Auto-play: Took card %d", i))
            return
        end
    end
end

-- Run a full automated game and check for duplicates
function runAutomatedDuplicateTest(seed)
    print("=== AUTOMATED DUPLICATE TEST (seed=" .. seed .. ") ===")
    
    Cards.resetCardCounter()
    local testState = State.createNewGameState(seed)
    testState = State.dealRoomUpToFull(testState)
    testState.runState = State.RunState.AWAITING
    
    local moves = 0
    local maxMoves = 200
    local duplicateFound = false
    
    while moves < maxMoves do
        -- Validate state
        local valid, err = State.assertNoDuplicateCards(testState)
        if not valid then
            print("DUPLICATE FOUND at move " .. moves .. ": " .. err)
            duplicateFound = true
            break
        end
        
        -- Check for game end
        if testState.runState == State.RunState.GAME_OVER or 
           testState.runState == State.RunState.VICTORY then
            break
        end
        
        -- Take first available card
        local taken = false
        for i = 1, State.ROOM_SIZE do
            if testState.room.cards[i] then
                -- Randomly flee or take
                if not testState.room.fleeUsed and math.random() < 0.1 then
                    testState = Actions.applyFlee(testState, i)
                else
                    testState = Actions.applyTake(testState, i)
                end
                taken = true
                break
            end
        end
        
        if not taken then break end
        moves = moves + 1
    end
    
    if not duplicateFound then
        print("PASSED: " .. moves .. " moves, ended with " .. testState.runState)
    end
    print("==============================================")
    
    return not duplicateFound
end

