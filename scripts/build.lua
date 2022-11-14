#!/usr/bin/env lua
os.execute("mkdir -p temp/src")
os.execute("scripts/preproc.lua src/main.lua temp/src/init.lua")
