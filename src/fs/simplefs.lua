-- SimpleFS support
-- simple, pared back, read-only driver
do
  local _node = {}

  local structures = {
    superblock = {
      pack = "<c4BBI2I2I3I3",
      names = {"signature", "flags", "revision", "nl_blocks", "blocksize", "blocks", "blocks_used"}
    },
    nl_entry = {
      pack = "<I2I2I2I2I2I4I8I8I2I2c30",
      names = {"flags", "datablock", "next_entry", "last_entry", "parent", "size", "created", "modified", "uid", "gid", "fname"}
    },
  }

  local function split(path)
    local segments = {}
    for piece in path:gmatch("[^/\\]+") do
      if piece == ".." then
        segments[#segments] = nil

      elseif piece ~= "." then
        segments[#segments+1] = piece
      end
    end

    return segments
  end

  local function unpack(name, data)
    local struct = structures[name]
    local ret = {}
    local fields = table.pack(string.unpack(struct.pack, data))
    for i=1, #struct.names do
      ret[struct.names[i]] = fields[i]
      if fields[i] == nil then
        error("unpack:structure " .. name .. " missing field " .. struct.names[i
])
      end
    end
    return ret
  end

  function _node:readBlock(n)
    local data = ""
    for i=1, self.bstosect do
      data = data .. self.drive.readSector(i+n*self.bstosect)
    end
    return data
  end

  function _node:readSuperblock()
    self.sblock = unpack("superblock", self.drive.readSector(1))
    self.sect = self.drive.getSectorSize()
    self.bstosect = self.sblock.blocksize / self.sect
  end

  function _node:readNamelistEntry(n)
    local offset = n * 64 % self.sblock.blocksize + 1
    local block = math.floor(n/8)
    local blockData = self:readBlock(block+2)
    local namelistEntry = blockData:sub(offset, offset + 63)
    local ent = unpack("nl_entry", namelistEntry)
    ent.fname = ent.fname:gsub("\0", "")
    return ent
  end

  function _node:getNext(ent)
    if (not ent) or ent.next_entry == 0 then return nil end
    return self:readNamelistEntry(ent.next_entry), ent.next_entry
  end

  function _node:resolve(path)
    local segments = split(path)
    local dir = self:readNamelistEntry(0)
    local current, cid = dir, 0
    for i=1, #segments do
      current,cid = self:readNamelistEntry(current.datablock), current.datablock
      while current and current.fname ~= segments[i] do
        current, cid = self:getNext(current)
      end
      if not current then
        return nil, "no such file or directory"
      end
    end
    return current, cid
  end

  function _node:getBlocks(ent)
    local blocks = {ent.datablock}
    local current = ent.datablock
    while true do
      local data = self:readBlock(current)
      local nxt = ("<I3"):unpack(data:sub(-3))
      if nxt == 0 then break end
      current = nxt
      blocks[#blocks+1] = nxt
    end
    return blocks
  end

  function _node:read_file(f)
    local ent, eid = self:resolve(f)
    if not ent then return nil, eid end

    local blocks = self:getBlocks(ent)

    local data = ""
    for i=1, #blocks do
      data = data .. self:readBlock(blocks[i]):sub(1,-4):gsub("\0", "")
    end

    return data
  end

  function _node:exists(f)
    return not not self:resolve(f)
  end

  function fs.readers.simplefs(drive)
    if drive.type ~= "drive" then return end
    if unpack("superblock", drive.readSector(1)).signature == "\x1bSFS" then
      local node = setmetatable({
        drive = drive,
        sblock = {},
      }, {__index = _node})
      node:readSuperblock()
      return node
    end
  end
end
