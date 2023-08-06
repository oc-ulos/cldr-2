-- Abstract filesystem support

local fs = {readers = {}}

function fs.detect(component)
  for name, reader in pairs(fs.readers) do
    local result = reader(component)
    if result then return name, result end
  end
end

--@[{includeif("FS_MANAGED", "src/fs/managed.lua")}]
--@[{includeif("FS_SFS", "src/fs/simplefs.lua")}]

do
  local detected = {}
  for addr, ctype in component.list() do
    if ctype == "filesystem" or ctype == "drive" then
      local fstype, interface = fs.detect(component.proxy(addr))
      if fstype then
        detected[#detected+1] = {interface=interface,type=fstype,label=interface.label or addr}
      end
    end
  end

  if #detected == 0 then
    error("no boot filesystems found!")
  end

  local opt = 1
  if #detected > 1 then
    local names = {}
    table.sort(detected, function(a,b) return a.label<b.label end)
    for i=1, #detected do
      names[i] = detected[i].type .. " from " .. detected[i].label
    end
    opt = menu("Select a boot device:", names, 1, 5)
  end
  fs.read_file = function(f) return detected[opt].interface:read_file(f) end
end
