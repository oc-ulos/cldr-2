-- Managed fs config loader

local fsaddr
if computer.getBootAddress then
  fsaddr = computer.getBootAddress()
else
  fsaddr = component.list("filesystem", true)()
end

local fs = component.proxy(fsaddr)

local function read_file(f)
  local fd, err = fs.open(f, "r")
  if not fd then error(err) end
  local data = ""

  for chunk in function()return fs.read(fd, math.huge) end do
    data = data .. chunk
  end

  fs.close(fd)
  return data
end

local entry = parse_config(read_file("/boot/cldr.cfg"))

local data = assert(read_file(entry.boot))
assert(load(data, "="..entry.boot, "bt", _G))(table.unpack(entry.flags))
