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

local map = create_map{x = 8, y = 10}

for y, row in ipairs(map) do
  for x, elem in ipairs(row) do
    io.write(string.format('%d, ', elem))
  end
  io.write('\n')
end