-- MotionRegistry - per-card animation values for draw helpers

local Registry = {
    alphas = {}
}

function Registry.setAlpha(cardId, alpha)
    Registry.alphas[cardId] = alpha
end

function Registry.getAlpha(cardId)
    return Registry.alphas[cardId] or 1
end

function Registry.clear(cardId)
    Registry.alphas[cardId] = nil
end

return Registry
