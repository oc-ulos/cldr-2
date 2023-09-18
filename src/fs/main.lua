-- Abstract filesystem support

local fs = {filesystems = {}, partitions = {}}

-- create partition cover object for unmanaged drives
-- code taken directly from Cynosure 2
function fs.create_subdrive(drive, start, size)
  local sub = {}
  local sector, byte = start, (start - 1) * drive.getSectorSize()
  local byteSize = size * drive.getSectorSize()
  function sub.readSector(n)
    if n < 1 or n > size then
      error("invalid offset, not in a usable sector", 0)
    end
    return drive.readSector(sector + n)
  end
  function sub.writeSector(n, d)
    if n < 1 or n > size then
      error("invalid offset, not in a usable sector", 0)
    end
    return drive.writeSector(sector + n, d)
  end
  function sub.readByte(n)
    if n < 1 or n > byteSize then return 0 end
    return drive.readByte(n + byteOffset)
  end
  function sub.writeByte(n, i)
    if n < 1 or n > byteSize then return 0 end
    return drive.writeByte(n + byteOffset, i)
  end
  sub.getSectorSize = drive.getSectorSize
  function sub.getCapacity()
    return drive.getSectorSize() * size
  end
  sub.type = "drive"
  return sub
end

function fs.detect(component)
  local partitions = {component}

  for pt, partition in pairs(fs.partitions) do
    local result = partition(component)
    if result then
      partitions = result
      break
    end
  end

  local results = {}
  for i=1, #partitions do
    local part = partitions[i]
    for name, reader in pairs(fs.filesystems) do
      local result = reader(part)
      if result then
        results[#results+1] = {
          name = name, proxy = result, index = part.index }
        break
      end
    end
  end

  return results
end

-- partitions
--@[{includeif("PT_OSDI", "src/fs/osdi.lua")}]
-- filesystems
--@[{includeif("FS_MANAGED", "src/fs/managed.lua")}]
--@[{includeif("FS_SFS", "src/fs/simplefs.lua")}]

do
  local detected = {}
  for addr, ctype in component.list() do
    if ctype == "filesystem" or ctype == "drive" then
      write("detect " .. addr)
      local partitions = fs.detect(component.proxy(addr))
      write(#partitions .. " partition(s) are bootable")
      for i=1, #partitions do
        local fstype, interface = partitions[i].name, partitions[i].proxy
        if interface:exists("/boot/cldr.cfg") then
          detected[#detected+1] = {
            address=addr,
            interface=interface,
            type=fstype,
            index=partitions[i].index,
            label=(interface.label or addr)..","..i}
        end
      end
    end
  end

  write("found " .. #detected .. " partition(s) with configuration")

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
  fs.exists = function(f) return detected[opt].interface:exists(f) end

  -- supposedly this function is "deprecated," but everybody still uses it
  if detected[opt].type == "managed" then
    function computer.getBootAddress()
      return detected[opt].address
    end
  else
    function computer.getBootAddress()
      return detected[opt].address..","..detected[opt].index
    end
  end
end
