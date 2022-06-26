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

local time = 0
local canvas = love.graphics.newCanvas(400, 400)
local r = 0
local grid = {}

function love.update(dt)
    time = time + dt * -0.1
    plan_to_sphere:send("time", time)
end

function love.draw()
    local center_x = love.graphics.getWidth() / 2
    local center_y = love.graphics.getHeight() / 2
    local planet_center_x = 210
    local planet_center_y = 210

    love.graphics.setCanvas(canvas)
    for x = 1, #grid do
        for y = 1, #grid[x] do
            local f = 1 * grid[x][y]
            love.graphics.setColor( f, f, f, 1 )
            love.graphics.rectangle( 'fill', (x * 8) - 7, (y * 8) - 7, 7, 7 )
            love.graphics.setColor( 1, 1, 1, 1 )
        end
    end
    love.graphics.setCanvas()
    love.graphics.setShader(plan_to_sphere)
    love.graphics.draw(
        canvas,
        center_x, center_y,
        0,
        1, 1,
        planet_center_x, planet_center_y
    )
    love.graphics.setShader()
end

local function noise()
    for x = 1, 60 do
        for y = 1, 60 do
            grid[x] = grid[x] or {}
            grid[x][y] = love.math.noise( x + love.math.random(), y + love.math.random() )
        end
    end
end

function love.keypressed()
    noise()
end