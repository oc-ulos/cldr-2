-- recognize OSDI disks

do
  local pattern = "<I4I4c8I3c13"
  local magic = "OSDI\xAA\xAA\x55\x55"
  function fs.partitions.osdi(drive)
    if drive.type ~= "drive" then return end

    local sector = drive.readSector(1)
    local meta = {pattern:unpack(sector)}
    if meta[1] ~= 1 or meta[2] ~= 0 or meta[3] ~= magic then return end
    local partitions = {}


    repeat
      sector = sector:sub(33)
      meta = {pattern:unpack(sector)}
      meta[3] = meta[3]:gsub("\0", "")
      meta[5] = meta[5]:gsub("\0", "")
      if #meta[5] > 0 then
        write("found " .. meta[5])
        partitions[#partitions+1] = fs.create_subdrive(drive, meta[1], meta[2])
      end
    until #sector <= 32

    return partitions
  end
end
