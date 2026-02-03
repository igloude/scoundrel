-- Motion utilities (tweening and easing)

local Motion = {}

function Motion.lerp(a, b, t)
    return a + (b - a) * t
end

function Motion.clamp01(t)
    if t < 0 then return 0 end
    if t > 1 then return 1 end
    return t
end

function Motion.easeOutQuad(t)
    t = Motion.clamp01(t)
    return 1 - (1 - t) * (1 - t)
end

function Motion.easeInQuad(t)
    t = Motion.clamp01(t)
    return t * t
end

function Motion.easeOutBack(t)
    t = Motion.clamp01(t)
    local c1 = 1.70158
    local c3 = c1 + 1
    return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
end

function Motion.approach(current, target, speed, dt)
    if current == target then return current end
    local diff = target - current
    local step = diff * math.min(1, speed * dt)
    return current + step
end

return Motion
