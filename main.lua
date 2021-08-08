local u = require('ext.utils')
local lume = require('ext.lume')
local vec2d = require('ext.vec2d')
local anim = require('ext.anim')

--[[ NOTES

  [ ] Some weird issues with paddle collision! When the ball hits the paddle
      right near the vertex (right on it?), the ball's y-axis trajectory doesn't
      reverse!!! WTF. This has caused me to lose a game while making a SUPERFLY
      move! Punished for style!

  [ ] Sounds?

  [ ] Guns and stuff

  ---

  [X] (MADE) a random map filling function.

  [X] Collisions are (NO LONGER) whack!

--]]


function love.load()

  local font = love.graphics.newImageFont("assets/image_font.png",
  " abcdefghijklmnopqrstuvwxyz" ..
  "ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
  "123456789.,!?-+/():;%&`'*#=[]\"{}_")
  love.graphics.setFont(font)

  hi_score_file = io.open('hiscore', 'r')
  hi_score = hi_score_file:read("*n")
  hi_score_file:close()

  love.graphics.setPointSize(2)

  colors = {
    {255, 150, 143}, -- red
    {138, 237, 149}, -- green
    {132, 181, 224}, -- blue
    {214, 224, 137} -- yellow
  }
  colors[0] = {0, 0, 0}

  dims = {x = 8, y = 10}
  base = {x = 80, y = 80}
  brick = {x = 80, y = 40}

  paddle = {
    x = base.x, 
    y = base.y + (dims.y - 1) * brick.y + 4, 
    width = brick.x * 2, 
    height = brick.y - 8
  }

  ball = {
    radius = 20, 
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

  map = create_map(dims)
  score_limit = u.count_blocks(map)
  
  draw_map = {}
  randomize_colors(map, colors)
  fill_draw_map(map, draw_map, base, brick)

  ticker = 0
  tickrate = 5 -- second

  in_motion = false
  game_over = false

  score = 0
  total_score = 0
  speed = 7

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
  -- love.graphics.print(message, 20, 20)

  if not game_over then
    love.graphics.print(string.format(
      'Hi-score: %d\nTotal Score: %d\nScore: %d', hi_score, total_score, score), 
      20, 20
    )
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
  -- love.graphics.points(ball.x, ball.y)

  if game_over then
    in_motion = false
    love.graphics.setColor(u.color(255, 255, 255))
    if game_won then
      love.graphics.printf(
        string.format('You win!\nScore: %d\nTotal score: %d\n Click to start next level!', score, total_score), 
        base.x + (dims.x * brick.x) / 2 - 150, base.y + (dims.y * brick.y) / 2,
        300, 'center'
      )
    else
      love.graphics.printf(
        string.format('GAME OVER!\nTotal score: %d\n Click or press \'R\' to restart.', total_score), 
        base.x + (dims.x * brick.x) / 2 - 150, base.y + (dims.y * brick.y) / 2,
        300, 'center'
      )
    end
  end
end

function love.mousereleased(x, y)
  if not game_over then
    in_motion = true
  else
    if game_won then
      reset_win()
    else
      reset_loss()
    end
    in_motion = true
  end
end

function love.mousemoved(x, y, dx, dy)
  paddle.x = lume.clamp(x - paddle.width / 2, base.x + 4, base.x + dims.x * brick.x - paddle.width - 4)
end

function love.keypressed(key)
  if game_over and not game_won and key == 'r' then
    reset_loss()
  end
end

function create_map(dims)
  local map = {}
  for y = 1, dims.y / 2 do
    map[y] = {}
    for x = 1, dims.x / 2 do
      map[y][x] = (math.random(2) - 1)
    end
    for x = dims.x / 2 + 1, dims.x do
      map[y][x] = map[y][(dims.x + 1) - x]
    end
  end

  for y = dims.y / 2 + 1, dims.y do
    map[y] = {}
    for x = 1, dims.x do
      map[y][x] = 0
    end
  end

  return map
end

function reset()
  map = create_map(dims)
  score_limit = u.count_blocks(map)

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
  game_won = false

  score = 0
  ticker = 0
end

function reset_win()
  reset()
end

function reset_loss()
  reset()
  total_score = 0
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
            total_score = total_score + score
            if total_score > hi_score then
              hi_score = total_score
              hi_score_file = io.open('hiscore', 'w')
              hi_score_file:write(string.format('%d', hi_score))
              hi_score_file:close()
            end
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