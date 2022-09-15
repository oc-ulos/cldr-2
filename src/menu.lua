-- Menus

local gpu = component.proxy((component.list("gpu", true)()))
local screen = component.list("screen", true)()
local menu = function(_,_,a) return a end

if gpu and screen then
  gpu.bind(screen)

  local w, h = gpu.maxResolution()
  gpu.setResolution(w, h)

  local hw = math.floor(w / 2)

  local function draw(title, opts, sel)
    gpu.setForeground(0xFFFFFF)
    gpu.setBackground(0x000000)

    local version = "Cynosure Loader v$[{cat version}]"
    gpu.set(hw - math.floor(#version / 2), 2, version)
    gpu.set(hw - math.floor(#title / 2), h - #opts - 2, title)

    for i=#opts, 1, -1 do
      gpu.setForeground(i == sel and 0 or 0xFFFFFF)
      gpu.setBackground(i == sel and 0xFFFFFF or 0)
      gpu.fill(1, h - (#opts - i + 1), w, 1, " ")
      gpu.set(hw - math.floor(#opts[i] / 2), h - (#opts - i + 1), opts[i])
    end
  end

  menu = function(title, opts, default, timeout)
    local selected = default or 1
    local time = computer.uptime()
    timeout = timeout or math.huge
    local maxtime = time + timeout

    gpu.setForeground(0xFFFFFF)
    gpu.setBackground(0)
    gpu.fill(1, 1, w, h, " ")
    gpu.set(w, h, tostring(math.floor(maxtime - time + 0.5)))

    while true do
      draw(title, opts, selected)

      time = computer.uptime()
      local sig, _, char, code = computer.pullSignal(0.5)

      if sig == "key_down" then
        maxtime = math.huge

        if char == 13 then
          return selected

        elseif code == 200 then
          selected = math.max(1, selected - 1)

        elseif code == 208 then
          selected = math.min(#opts, selected + 1)
        end

      elseif time >= maxtime then
        gpu.setForeground(0xFFFFFF)
        gpu.setBackground(0)
        gpu.fill(1, 1, w, h, " ")
        return selected

      else
        gpu.setForeground(0xFFFFFF)
        gpu.setBackground(0)
        gpu.set(w, h, tostring(maxtime - time))
      end
    end
  end
end
