-- Scoundrel - Love2D configuration

function love.conf(t)
    -- Window settings
    t.window.title = "Scoundrel"
    t.window.width = 800
    t.window.height = 600
    t.window.vsync = 1  -- Enable vsync
    t.window.resizable = false
    
    -- Version
    t.version = "11.4"  -- Love2D version
    
    -- Modules (disable unused ones for faster startup)
    t.modules.audio = true
    t.modules.data = true
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = false
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = false
    t.modules.sound = true
    t.modules.system = true
    t.modules.thread = true
    t.modules.timer = true
    t.modules.touch = false
    t.modules.video = false
    t.modules.window = true
end

