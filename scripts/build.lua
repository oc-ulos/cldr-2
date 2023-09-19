#!/usr/bin/env lua

local bconf = dofile("config.lua")

function _G.includeif(name, file)
  return bconf[name] and ("#include \""..file.."\"") or ""
end

os.execute("mkdir -p temp/src")
assert(loadfile("scripts/preproc.lua"))("src/main.lua", "temp/src/init.lua")
