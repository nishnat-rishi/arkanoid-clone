local u = {}
local vec2d = require('ext.vec2d')

function u.color(r, g, b, a)
  return r / 255, g / 255, b / 255, a or 1
end

function u.color_r(t)
  return t[1] / 255, t[2] / 255, t[3] / 255, t[4] or 1
end

function u.choice(t)
  return t[math.random(#t)]
end

function u.debug_values(t)
  local s = ''
  for k, v in pairs(t) do
    s = s .. string.format('%s: %f\n', k, v)
  end
  
  return s
end

function u.copy2d(t)
  local new_t = {}

  for i, row in ipairs(t) do
    new_t[i] = {}
    for j, elem in ipairs(row) do
      new_t[i][j] = elem
    end
  end

  return new_t
end

function u.count_blocks(t)
  local count = 0
  for _, row in ipairs(t) do
    for _, elem in ipairs(row) do
      if elem ~= 0 then
        count = count + 1
      end
    end
  end
  return count
end

function u.ball_collides(circle, object, speed)
  return circle.x + circle.radius + circle.vel.x * speed > object.x and 
    circle.x - circle.radius + circle.vel.x * speed  < object.x + object.width and
    circle.y + circle.radius + circle.vel.y * speed > object.y and
    circle.y - circle.radius + circle.vel.y * speed < object.y + object.height
end

function u.reflect(circle, object, speed)
  local dx, dy = -circle.vel.x * speed, -circle.vel.y * speed
  -- local dx, dy = 0, 0
  if circle.x + circle.radius + dx < object.x or circle.x - circle.radius + dx > object.x + object.width then
    circle.vel.x = -circle.vel.x
  end
  if circle.y + circle.radius + dy < object.y or circle.y - circle.radius + dy > object.y + object.height then
    circle.vel.y = -circle.vel.y
  end

  circle.vel = vec2d.unit(circle.vel)
end

function u.reflect_with_paddle(circle, object, speed)
  local dx, dy = -circle.vel.x * speed, -circle.vel.y * speed
  if circle.x + circle.radius + dx < object.x or circle.x - circle.radius + dx > object.x + object.width then
    circle.vel.y = ((circle.y - (paddle.y + paddle.height / 2)) / paddle.height) * 2
    circle.vel.x = -circle.vel.x
  end
  if circle.y + circle.radius + dy < object.y or circle.y - circle.radius + dy > object.y + object.height then
    circle.vel.x = ((circle.x - (paddle.x + paddle.width / 2)) / paddle.width) * 2
    circle.vel.y = -circle.vel.y
  end

  circle.vel = vec2d.unit(circle.vel)
end

function u.reflect_with_outline(circle, object)
  local dx, dy = circle.vel.x * speed, circle.vel.y * speed

  if circle.x - circle.radius + dx < object.x or circle.x + circle.radius + dx > object.x + object.width then
    circle.vel.x = -circle.vel.x
  end

  if circle.y - circle.radius + dy < object.y then
    circle.vel.y = -circle.vel.y
  end
end

function u.ball_out_of_bounds(circle, object)
  local dy = circle.vel.y * speed

  return circle.y + circle.radius + dy > object.y + object.height
end

--[[ TEST

colors = {
  {255, 150, 143},
  {138, 237, 149},
  {132, 181, 224},
  {214, 224, 137}
}

colors[0] = {255, 255, 255}

print(#colors)

print(u.choice(colors))

--]]

return u