-- UI Theme Tokens for Digital Scoundrel

local Theme = {}

Theme.spacing = {
    xs = 4,
    sm = 8,
    md = 12,
    lg = 18,
    xl = 24,
    xxl = 32
}

Theme.fontSizes = {
    xs = 12,
    sm = 14,
    md = 16,
    lg = 20,
    xl = 26
}

Theme.radii = {
    sm = 6,
    md = 10,
    lg = 16
}

Theme.shadows = {
    soft = {0, 0, 0, 0.35},
    glow = {0.8, 0.9, 1.0, 0.25}
}

Theme.colors = {
    bg = {0.08, 0.08, 0.1},
    panel = {0.12, 0.12, 0.15},
    panelDark = {0.1, 0.1, 0.12},
    line = {0.25, 0.25, 0.3},
    text = {0.95, 0.95, 0.95},
    textDim = {0.7, 0.7, 0.75},
    accent = {0.3, 0.7, 0.95},
    monster = {0.9, 0.35, 0.35},
    potion = {0.45, 0.85, 0.55},
    weapon = {0.45, 0.6, 0.95},
    card = {0.16, 0.16, 0.2},
    cardEdge = {0.35, 0.35, 0.42},
    cardHover = {0.6, 0.7, 0.9},
    cardSelected = {0.85, 0.85, 0.95},
    disabled = {0.35, 0.35, 0.4},
    focus = {1.0, 0.9, 0.2}
}

local BASE_COLORS = {}
for k, v in pairs(Theme.colors) do
    BASE_COLORS[k] = { v[1], v[2], v[3], v[4] }
end

local HIGH_CONTRAST = {
    bg = {0, 0, 0},
    panel = {0.1, 0.1, 0.1},
    panelDark = {0.05, 0.05, 0.05},
    line = {0.9, 0.9, 0.9},
    text = {1, 1, 1},
    textDim = {0.85, 0.85, 0.85},
    accent = {1, 0.85, 0.2},
    monster = {1, 0.25, 0.25},
    potion = {0.35, 1, 0.45},
    weapon = {0.35, 0.7, 1},
    card = {0.12, 0.12, 0.12},
    cardEdge = {0.9, 0.9, 0.9},
    cardHover = {1, 1, 1},
    cardSelected = {1, 1, 1},
    disabled = {0.4, 0.4, 0.4},
    focus = {1, 1, 0}
}

Theme.card = {
    width = 130,
    height = 180,
    liftHover = 10,
    liftSelected = 16
}

function Theme.init()
    Theme.fonts = {
        xs = love.graphics.newFont(Theme.fontSizes.xs),
        sm = love.graphics.newFont(Theme.fontSizes.sm),
        md = love.graphics.newFont(Theme.fontSizes.md),
        lg = love.graphics.newFont(Theme.fontSizes.lg),
        xl = love.graphics.newFont(Theme.fontSizes.xl)
    }
end

function Theme.setHighContrast(enabled)
    local source = enabled and HIGH_CONTRAST or BASE_COLORS
    for k, v in pairs(source) do
        Theme.colors[k] = { v[1], v[2], v[3], v[4] }
    end
end

return Theme
