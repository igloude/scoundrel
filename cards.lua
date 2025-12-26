-- Scoundrel - Card domain model
-- Pure functions for card representation and type classification

local Cards = {}

--------------------------------------------------------------------------------
-- B.1: SUITS constant
--------------------------------------------------------------------------------

Cards.SUITS = {
    "spades",
    "clubs", 
    "hearts",
    "diamonds"
}

--------------------------------------------------------------------------------
-- B.2: RANKS constant (A, 2-10, J, Q, K)
--------------------------------------------------------------------------------

Cards.RANKS = {
    "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"
}

--------------------------------------------------------------------------------
-- B.3: Card constructor
-- Creates a card table with suit and rank and unique ID
--------------------------------------------------------------------------------

-- Track card creation for unique IDs
local cardCounter = 0

function Cards.newCard(suit, rank)
    cardCounter = cardCounter + 1
    return {
        id = cardCounter,
        suit = suit,
        rank = rank
    }
end

-- Reset card counter (for testing/new games)
function Cards.resetCardCounter()
    cardCounter = 0
end

--------------------------------------------------------------------------------
-- B.4: cardToString(card)
-- Returns a stable identifier string (e.g., "A♠", "10♥")
--------------------------------------------------------------------------------

local SUIT_SYMBOLS = {
    spades = "♠",
    clubs = "♣",
    hearts = "♥",
    diamonds = "♦"
}

function Cards.cardToString(card)
    local symbol = SUIT_SYMBOLS[card.suit] or "?"
    return card.rank .. symbol
end

--------------------------------------------------------------------------------
-- B.5: rankToValue(rank)
-- Returns numeric value: A=1, 2-10=pip, J=11, Q=12, K=13
--------------------------------------------------------------------------------

local RANK_VALUES = {
    A = 1,
    ["2"] = 2,
    ["3"] = 3,
    ["4"] = 4,
    ["5"] = 5,
    ["6"] = 6,
    ["7"] = 7,
    ["8"] = 8,
    ["9"] = 9,
    ["10"] = 10,
    J = 11,
    Q = 12,
    K = 13
}

function Cards.rankToValue(rank)
    return RANK_VALUES[rank]
end

-- Convenience: get value directly from card
function Cards.cardValue(card)
    return Cards.rankToValue(card.rank)
end

--------------------------------------------------------------------------------
-- B.6: isMonster(card)
-- Monsters are Spades and Clubs
--------------------------------------------------------------------------------

function Cards.isMonster(card)
    return card.suit == "spades" or card.suit == "clubs"
end

--------------------------------------------------------------------------------
-- B.7: isWeapon(card)
-- Weapons are Diamonds
--------------------------------------------------------------------------------

function Cards.isWeapon(card)
    return card.suit == "diamonds"
end

--------------------------------------------------------------------------------
-- B.8: isPotion(card)
-- Potions (healing) are Hearts
--------------------------------------------------------------------------------

function Cards.isPotion(card)
    return card.suit == "hearts"
end

--------------------------------------------------------------------------------
-- B.9: cardType(card)
-- Returns "monster", "weapon", or "potion"
--------------------------------------------------------------------------------

function Cards.cardType(card)
    if Cards.isMonster(card) then
        return "monster"
    elseif Cards.isWeapon(card) then
        return "weapon"
    elseif Cards.isPotion(card) then
        return "potion"
    end
    return nil  -- Should never happen with valid cards
end

return Cards

