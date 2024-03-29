-- Common config parsing bits

local function to_words(str)
  local words = {}

  for word in str:gmatch("[^ ]+") do
    words[#words+1] = word
  end

  return words
end

local function to_lines(str)
  local lines = {}
  for line in str:gmatch("[^\n]+") do
    if line:sub(1,1) ~= "#" then
      lines[#lines+1] = line
    end
  end

  local i = 0
  return function()
    i = i + 1
    return lines[i]
  end
end

local arch_aliases = {
  lua52 = "Lua 5.2",
  lua53 = "Lua 5.3"
}

local function parse_config(str)
  local entries = {}
  local names = {}
  local entry = {}
  local default = 1
  local timeout = math.huge

  for line in to_lines(str) do
    local words = to_words(line)

    if line:sub(1,2) ~= "  " then
      if words[1] == "entry" then
        entry = {}
        entries[#entries+1] = entry
        names[#names+1] = table.concat(words, " ", 2)

      elseif words[1] == "default" then
        default = tonumber(words[2]) or default

      elseif words[1] == "timeout" then
        timeout = tonumber(words[2]) or timeout
      end

    elseif words[1] == "flags" then
      entry.flags = table.pack(table.unpack(words, 2))

    elseif words[1] == "boot" then
      entry.boot = words[2]

    elseif words[1] == "arch" then
      entry.arch = arch_aliases[words[2]]

    elseif words[1] == "reboot" then
      entry.reboot = true
    end
  end

  local opt = menu("Select a boot option:", names, default, timeout)

  local selected = entries[opt]
  if selected.arch then computer.setArchitecture(selected.arch) end
  if selected.reboot then computer.shutdown(true) end

  return selected
end

local entry = parse_config(fs.read_file("/boot/cldr.cfg"))
local data = assert(fs.read_file(entry.boot))
assert(load(data, "="..entry.boot, "bt", _G))(table.unpack(entry.flags))
