-- HudWeapon - weapon widget and restriction

local Theme = require("ui.theme")

local HudWeapon = {}

function HudWeapon.draw(rect, weapon)
    love.graphics.setFont(Theme.fonts.md)
    love.graphics.setColor(Theme.colors.text)
    local weaponText = weapon and ("Weapon " .. tostring(weapon.value)) or "Weapon None"
    love.graphics.print(weaponText, rect.x + 12, rect.y + 10)
    
    local restriction = "Unrestricted"
    if weapon and weapon.lastSlainMonsterValue ~= nil then
        restriction = "Can slay \226\137\164 " .. tostring(weapon.lastSlainMonsterValue)
    end
    love.graphics.setFont(Theme.fonts.sm)
    love.graphics.setColor(Theme.colors.textDim)
    love.graphics.print(restriction, rect.x + 12, rect.y + 36)
end

return HudWeapon
