-- Scoundrel - Deck and pile management
-- Pure functions for deck creation, shuffling, and card movement

local Cards = require("cards")

local Deck = {}

--------------------------------------------------------------------------------
-- C.1: createStandardDeck()
-- Returns a new table containing 52 unique cards (4 suits × 13 ranks)
--------------------------------------------------------------------------------

function Deck.createStandardDeck()
    local deck = {}
    for _, suit in ipairs(Cards.SUITS) do
        for _, rank in ipairs(Cards.RANKS) do
            table.insert(deck, Cards.newCard(suit, rank))
        end
    end
    return deck
end

--------------------------------------------------------------------------------
-- createScoundrelDeck()
-- Returns a 44-card Scoundrel deck:
-- - Removes red Aces (A♥, A♦)
-- - Removes red face cards (J♥, Q♥, K♥, J♦, Q♦, K♦)
--------------------------------------------------------------------------------

local RED_SUITS = { hearts = true, diamonds = true }
local FACE_RANKS = { J = true, Q = true, K = true }

local function isExcludedCard(suit, rank)
    if not RED_SUITS[suit] then
        return false  -- Black cards are never excluded
    end
    -- Red suit: exclude Aces and face cards
    return rank == "A" or FACE_RANKS[rank]
end

function Deck.createScoundrelDeck()
    local deck = {}
    for _, suit in ipairs(Cards.SUITS) do
        for _, rank in ipairs(Cards.RANKS) do
            if not isExcludedCard(suit, rank) then
                table.insert(deck, Cards.newCard(suit, rank))
            end
        end
    end
    return deck
end

--------------------------------------------------------------------------------
-- C.2: shuffle(deck, rng)
-- Fisher-Yates shuffle (in-place). Returns the deck for convenience.
-- rng is optional; if nil, uses math.random
--------------------------------------------------------------------------------

function Deck.shuffle(deck, rng)
    local random = rng or math.random
    local n = #deck
    for i = n, 2, -1 do
        local j = random(1, i)
        deck[i], deck[j] = deck[j], deck[i]
    end
    return deck
end

--------------------------------------------------------------------------------
-- C.3: drawCard(deck)
-- Pops and returns the top card (last element = top of deck)
-- Returns nil if deck is empty
--------------------------------------------------------------------------------

function Deck.drawCard(deck)
    if #deck == 0 then
        return nil
    end
    return table.remove(deck)
end

--------------------------------------------------------------------------------
-- C.4: discardCard(discard, card)
-- Appends a card to the discard pile. Returns the discard pile.
--------------------------------------------------------------------------------

function Deck.discardCard(discard, card)
    table.insert(discard, card)
    return discard
end

--------------------------------------------------------------------------------
-- C.5: countDeck(deck)
-- Returns the number of remaining cards in the deck
--------------------------------------------------------------------------------

function Deck.countDeck(deck)
    return #deck
end

--------------------------------------------------------------------------------
-- C.6: countDiscard(discard)
-- Returns the number of cards in the discard pile
--------------------------------------------------------------------------------

function Deck.countDiscard(discard)
    return #discard
end

--------------------------------------------------------------------------------
-- Utility: putCardOnBottom(deck, card)
-- Places a card at the bottom of the deck (for avoid mechanic)
--------------------------------------------------------------------------------

function Deck.putCardOnBottom(deck, card)
    table.insert(deck, 1, card)
    return deck
end

return Deck
