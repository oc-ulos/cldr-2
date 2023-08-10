-- Managed fs support

do
  local _node = {}
  function _node:read_file(f)
    local fd, err = self.fs.open(f, "r")
    if not fd then error(err) end
    local data = ""

    for chunk in function()return self.fs.read(fd, math.huge) end do
      data = data .. chunk
    end

    self.fs.close(fd)
    return data
  end

  function _node:exists(f)
    return self.fs.exists(f)
  end

  function fs.readers.managed(comp)
    if comp.type == "filesystem" then
      return setmetatable({
        fs = comp,
        label = comp.getLabel(),
      }, {__index = _node})
    end
  end
end
