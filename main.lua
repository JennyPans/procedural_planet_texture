if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end

local plan_to_sphere = love.graphics.newShader([[
  const number pi = 3.14159265;
  const number pi2 = 2.0 * pi;
  extern number time;
  vec4 effect(vec4 color, Image texture, vec2 tc, vec2 pixel_coords)
  {
    vec2 p = 2.0 * (tc - 0.5);
    
    number r = sqrt(p.x*p.x + p.y*p.y);
    if (r > 1.0) discard;
    
    number d = r != 0.0 ? asin(r) / r : 0.0;
          
    vec2 p2 = d * p;
    
    number x3 = mod(p2.x / (pi2) + 0.5 + time, 1.0);
    number y3 = p2.y / (pi2) + 0.5;
    
    vec2 newCoord = vec2(x3, y3);
    
    vec4 sphereColor = color * Texel(texture, newCoord);
          
    return sphereColor;
  }
]])

local canvas = nil
local world = {}
local screen_w
local screen_h
local time = 0
local sphere_render = false
local font

local function normalize(value, min, max)
    return (value - min) / (max - min)
end

function world.normalize()
    for l = 1, #world.data do
        for c = 1, #world.data[l] do
            world.data[l][c] = normalize(world.data[l][c], world.min, world.max)
        end
    end
end

function love.math.octave_simplex_noise(x, y, octaves, persistence)
    local total = 0
    local max_value = 0
    x = x + world.seed
    y = y + world.seed
    local frequency = world.frequency
    local amplitude = world.amplitude
    for i = 1, octaves do
        local noise = love.math.noise(x * frequency, y * frequency) * amplitude
        total = total + noise
        max_value = max_value + amplitude
        amplitude = amplitude * persistence
        frequency = frequency * 2
    end
    return total / max_value
end

function world.gen(seed)
    world.seed = seed or love.math.random(0, 1000)
    world.frequency = 0.001
    world.amplitude = 15
    world.min = 0
    world.max = 0
    world.data = {}
    for y = 1, screen_h do
        world.data[y] = {}
        for x = 1, screen_w do
            local noise = love.math.octave_simplex_noise(x, y, 8, 0.8)
            world.data[y][x] = noise
            if noise < world.min or world.min == 0 then world.min = noise end
            if noise > world.max then world.max = noise end
        end
    end
    world.normalize()
    world.draw()
end

function world.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    love.graphics.setBlendMode("alpha")
    local size = 2
    for l = 1, #world.data, size do
        for c = 1, #world.data[l], size do
            -- render noise
            -- local alpha = world.data[l][c]
            -- love.graphics.setColor(1, 1, 1, alpha)
            -- love.graphics.points(c, l)

            -- render sphere
            if world.data[l][c] < 0.42 then
                love.graphics.setColor(0.01,0.10,0.5,1)
            elseif world.data[l][c] < 0.45 then
                love.graphics.setColor(0.01,0.15,0.8,1)
            elseif world.data[l][c] < 0.5 then
                love.graphics.setColor(0.01,0.15,0.8,1)
            elseif world.data[l][c] < 0.6 then
                love.graphics.setColor(0.01,0.2,0.85,1)
            elseif world.data[l][c] <= 0.7 then
                love.graphics.setColor(0.01, 0.4, 0.1, 1)
            elseif world.data[l][c] <= 0.8 then
                love.graphics.setColor(0.01, 0.8, 0.1, 1)
            elseif world.data[l][c] <= 0.9 then
                love.graphics.setColor(0.4, 0.7, 0.1, 1)
            elseif world.data[l][c] <= 1.0 then
                love.graphics.setColor(0.5, 0.80, 0.29, 1)
            end
            love.graphics.rectangle("fill", c - 1, l - 1, size, size)
        end
    end
    love.graphics.setCanvas()
end

function love.keypressed(key)
    if key == "space" then
        world.gen()
    end
    if key == "s" then
        sphere_render = not sphere_render
    end
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    -- screen_w = love.graphics.getWidth()
    -- screen_h = love.graphics.getHeight()
    screen_w = 400
    screen_h = 400
    font = love.graphics.newFont("grixel_acme_5_wide/Acme 5 Wide Bold.ttf")
    canvas = love.graphics.newCanvas(screen_w, screen_h)
    world.gen(585)
end

function love.update(dt)
    time = time + 0.1 * dt
    plan_to_sphere:send("time", time)
end

function love.draw()
    if sphere_render then
        love.graphics.setShader(plan_to_sphere)
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.draw(canvas, 0, 0, 0)
    love.graphics.setShader()
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("fill", 0, 16, 75, 20)
    love.graphics.setColor(0,0,0,1)
    love.graphics.print(tostring(world.seed), font, 16, 16)
end