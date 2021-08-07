local u = require('ext.utils')
local lume = require('ext.lume')
local vec2d = require('ext.vec2d')
local anim = require('ext.anim')

--[[ NOTES

Collisions are whack! (NO LONGER WHACK!)

--]]


function love.load()

  local font = love.graphics.newImageFont("assets/image_font.png",
  " abcdefghijklmnopqrstuvwxyz" ..
  "ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
  "123456789.,!?-+/():;%&`'*#=[]\"{}_")
  love.graphics.setFont(font)

  love.graphics.setPointSize(2)

  colors = {
    {255, 150, 143}, -- red
    {138, 237, 149}, -- green
    {132, 181, 224}, -- blue
    {214, 224, 137} -- yellow
  }
  colors[0] = {0, 0, 0}

  original_map = {
    {1, 0, 1, 1, 1, 1, 0, 0, 1},
    {0, 0, 0, 1, 1, 0, 0, 0, 0},
    {0, 1, 0, 1, 1, 0, 0, 1, 0},
    {1, 0, 1, 1, 1, 1, 1, 0, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1},
    {0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0},
  }

  score_limit = u.count_blocks(original_map)
  
  map = u.copy2d(original_map)

  base = {x = 80, y = 100}
  brick = {x = 80, y = 20}
  dims = {x = #map[1], y = #map}
  
  draw_map = {}

  randomize_colors(map, colors)
  fill_draw_map(map, draw_map, base, brick)

  paddle = {
    x = base.x, 
    y = base.y + (dims.y - 1) * brick.y + 4, 
    width = brick.x * 2, 
    height = brick.y - 8
  }
  
  ball = {
    radius = 7, 
    vel = vec2d.unit(
      vec2d{x = math.random() * 2 - 1, y = math.random() * 0.75 - 1}
    ),
    color = {255, 150, 143, 1}
  }
  ball.x = paddle.x + paddle.width / 2
  ball.y = paddle.y - ball.radius

  outline = {
    x = base.x, 
    y = base.y, 
    width = dims.x * brick.x, 
    height = dims.y * brick.y
  }

  ticker = 0
  tickrate = 10 -- second

  in_motion = false
  game_over = false

  score = 0
  speed = 4

  message = ''
end

function tick(dt)
  table.insert(map, 1, table.remove(map))
  table.insert(draw_map, 1, table.remove(draw_map))
  readjust_draw_map(draw_map)

  test_layer = map[#map - 1] -- second last
  
  for _, elem in ipairs(test_layer) do
    if elem > 0 then
      game_over = true
    end
  end
end

function love.update(dt)
  anim:update(dt)

  if not game_over and in_motion then
    ticker = ticker + dt
  end
  if ticker >= tickrate then
      ticker = 0
      tick(dt)
  end

  if not in_motion and not game_over then
    ball.x = paddle.x + paddle.width / 2
  end

  if in_motion then
    move(ball)
  end

  if love.keyboard.isDown('f') then
    move(ball)
  end
end

function love.draw()

  love.graphics.setColor(u.color(255, 255, 255))
  love.graphics.print(message, 20, 20)

  if not game_over then
    love.graphics.print(string.format('Score: %d', score), 20, 60)
  end

  love.graphics.setColor(u.color(255, 255, 255))
  love.graphics.rectangle('line', outline.x, outline.y, outline.width, outline.height)

  for y, row in ipairs(draw_map) do
    for x, item in ipairs(row) do
      -- if item.color >= 1 then
      --   love.graphics.setColor(u.color(255, 255, 255))
      --   love.graphics.printf(string.format('%d, %d\n%s', x, y, item.collides_with), item.x - item.width /  5, item.y, 100, 'center')
      -- end
      love.graphics.setColor(u.color_r(colors[item.color]))
      love.graphics.rectangle('line', item.x, item.y, item.width, item.height)
    end
  end

  love.graphics.setColor(u.color(255, 255, 255))
  love.graphics.rectangle('line', paddle.x, paddle.y, paddle.width, paddle.height)

  love.graphics.setColor(u.color_r(ball.color))
  love.graphics.circle('line', ball.x, ball.y, ball.radius)
  love.graphics.points(ball.x, ball.y)

  if game_over then
    in_motion = false
    love.graphics.setColor(u.color(255, 255, 255))
    if game_won then
      love.graphics.printf(
        string.format('You win!\nScore: %d\n Release screen to restart.', score), 
        base.x + (dims.x * brick.x) / 2 - 100, base.y + (dims.y * brick.y) / 2,
        200, 'center'
      )
    else
      love.graphics.printf(
        string.format('GAME OVER!\nScore: %d\n Release screen to restart.', score), 
        base.x + (dims.x * brick.x) / 2 - 100, base.y + (dims.y * brick.y) / 2,
        200, 'center'
      )
    end
  end
end

function love.mousereleased(x, y)
  if not game_over then
    in_motion = true
  else
    reset()
    in_motion = true
  end
end

function love.mousemoved(x, y, dx, dy)
  paddle.x = lume.clamp(x - paddle.width / 2, base.x + 4, base.x + dims.x * brick.x - paddle.width - 4)
end

function love.keypressed(key)
  if key == 'r' and game_over then
    reset()
  end
end

function reset()
  map = u.copy2d(original_map)

  draw_map = {}

  randomize_colors(map, colors)
  fill_draw_map(map, draw_map, base, brick)

  ball.vel = vec2d.unit(
      vec2d{x = math.random() * 2 - 1, y = math.random() * 0.75 - 1}
    )
  ball.color = {255, 150, 143, 1}
  ball.x = paddle.x + paddle.width / 2
  ball.y = paddle.y - ball.radius

  in_motion = false
  game_over = false

  score = 0
  ticker = 0
end

function randomize_colors(map, colors)
  
  for y, row in ipairs(map) do
    for x, elem in ipairs(row) do
      if elem == 1 then
        map[y][x] = math.random(#colors)
      end
    end
  end
end

function fill_draw_map(map, draw_map, base, brick)
  for y, row in ipairs(map) do
    draw_map[y] = {}
    for x, elem in ipairs(row) do
      draw_map[y][x] = {
        x = base.x + (x - 1) * brick.x + 4,
        y = base.y + (y - 1) * brick.y + 4,
        width = brick.x - 8, height = brick.y - 8,
        color = elem,
        collides_with = false
      }
    end
  end
end

function readjust_draw_map(draw_map)
  for y, row in ipairs(draw_map) do
    for x in ipairs(row) do
      draw_map[y][x].y = base.y + (y - 1) * brick.y + 4
    end
  end
end

function move(ball)
  -- outline detection
  u.reflect_with_outline(ball, outline)

  for y, row in ipairs(draw_map) do
    for x, item in ipairs(row) do
      if item.color > 0 then
        if u.ball_collides(ball, item, speed) then
          item.collides_with = true
          map[y][x] = 0
          item.color = 0
          score = score + 1
          if score >= score_limit then
            game_won = true
            game_over = true
            anim:move{
              obj = ball.color,
              to = {nil, nil, nil, 0}
            }
          end
          u.reflect(ball, item, speed)
        else
          item.collides_with = false
        end
      end
    end
  end

  if u.ball_collides(ball, paddle, speed) then
    u.reflect_with_paddle(ball, paddle, speed)
  end

  if u.ball_out_of_bounds(ball, outline) and not game_over then
    game_over = true
    anim:move{
      obj = ball.color,
      to = {nil, nil, nil, 0},
    }
  end

  ball.x, ball.y = ball.x + ball.vel.x * speed, ball.y + ball.vel.y * speed

end