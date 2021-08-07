local anim = {
  fn = {
    SIN = {fn = math.sin, fn_init = 0, fn_end = math.pi / 2},
    COS = {fn = math.cos, fn_init = 0, fn_end = math.pi / 2},
    SQR = {fn = function(x) return x * x end, fn_init = 0, fn_end = 1},
    SQRT = {fn = function(x) return math.sqrt(x) end, fn_init = 0, fn_end = 1},
  },
  _pending = {},
  _change_list = {},
  _purge_list = {},
  _fps = 60
}

local function lerp(x, a, b, af, bf)  -- linear interpolation
  return af + ((x - a) / (b - a)) * (bf - af)
end

local function calc_num_frames(fps, seconds)
  return math.floor(fps * seconds) + 1 -- + 1 for the case where math.floor(...) returns 0
end

local function construct_animation_frames(old, curr, num_frames, fn_bag) -- n is the number of frames

  local fn, input_init, input_end = 
    fn_bag.fn, fn_bag.fn_init, fn_bag.fn_end
  local output_init, output_end = 
    fn(input_init), fn(input_end)

  local delta = (input_end - input_init) / num_frames

  local frames = {}

  for i = 1, num_frames do
    frames[i] = lerp(
      fn(input_init + delta * i),
       output_init, output_end, 
       old, curr
      ) -- mapping
  end

  return frames
end

function anim:move(params) -- {id, obj, props, seconds, fn}
  params.id = params.id or params.obj
  params.props = params.props or params.to
  params.seconds, params.fn = 
    params.seconds or 0.5, params.fn or anim.fn.SQRT
  params.on_end = 
    params.on_end or function() end -- nothing happens on default
  local bag = {
    obj = params.obj, 
    props = params.props, 
    on_end = params.on_end
  } 
  
  -- add frames to bag
  bag.frames, bag.curr_frame, bag.last_frame = 
    {}, 0, calc_num_frames(self._fps, params.seconds) 
    -- animation not started, curr_frame is 0

  for prop_name, prop_val in pairs(params.props) do
    assert(
      params.obj[prop_name] ~= nil, 
      string.format(
        'ANIM_ERROR: Drawing property \'%s\' not initialized!', 
        prop_name
      )
    )

    bag.frames[prop_name] = construct_animation_frames(
      params.obj[prop_name],
      prop_val,
      bag.last_frame,
      params.fn
    )
  end

  self._pending[params.id] = bag
end

function anim:update(dt)
  self._fps = 1 / dt
  for id, bag in pairs(self._change_list) do
    bag.curr_frame = bag.curr_frame + 1
    if bag.curr_frame <= bag.last_frame then
      for k, frames in pairs(bag.frames) do
        bag.obj[k] = frames[bag.curr_frame]
        if bag.obj.while_animating then -- THIS SHOULD ... *1
          bag.obj:while_animating()
        end
      end
    else
      -- perform on_end action
      self._change_list[id] = nil -- delete animation
      bag.on_end(bag.obj)
    end
  end
  for id, bag in pairs(self._pending) do
    self._change_list[id] = bag
    self._pending[id] = nil
  end

  for id in pairs(self._purge_list) do
    self._change_list[id] = nil
    self._purge_list[id] = nil
  end
end

function anim:purge(obj)
  if self._change_list[obj] then
    self._purge_list[obj] = true
  end
end

function anim:add_fn(name, fn, input_init, input_end)
  self.fn[name] = {
    fn = fn, 
    fn_init = input_init, 
    fn_end = input_end
  }
end

return anim


-- ADDITIONAL COMMENTS

--[[
  1. THIS SHOULD BE CHANGED!! VERY INCONSISTENTLY PLACED!!
     Why is it that the 'on_end' handler is passed to 
     anim:move({...}), but 'while_animating' handler is an 
     object property?? Very bad!!

     Make anim:move be something like:
     anim:move({obj, to, [id, on_end, while_animating]}).

     We are anyway not updating this module in the 'UNO' 
     project. BUT THAT PROJECT HAS A MEMORY LEAK WHICH I
     FIXED HERE OH MY GOD. But if we change the functioning
     of the 'while_animating' handler, WE WILL BE REQUIRED
     TO FIX ALL INSTANCES OF IT IN CODE OH MY GOD. Ok no need
     to hyperventilate, how many instances could there possibly 
     be?

]]