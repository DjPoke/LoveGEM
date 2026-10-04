-- create drives (the first time)
function GEM_create_drives()
	local minGUI_info = love.filesystem.getInfo("Swap")
	if not minGUI_info then love.filesystem.createDirectory("Swap") end
	
	local function copyDirectory(source, destination)
		local ok, err = love.filesystem.createDirectory(destination)
		if not ok then return nil, err end
		for _, name in ipairs(love.filesystem.getDirectoryItems(source)) do
			local from, to = source .. "/" .. name, destination .. "/" .. name
			local info = love.filesystem.getInfo(from)
			if info and info.type == "directory" then
				ok, err = copyDirectory(from, to)
			elseif info and info.type == "file" then
				local data
				data, err = love.filesystem.read(from)
				if data then ok, err = love.filesystem.write(to, data)
				else ok = nil end
			else
				return nil, "Unsupported example entry: " .. from
			end
			if not ok then return nil, err end
		end
		return true
	end
	for _, directory in ipairs({"Work", "Play", "Relax"}) do
		if not love.filesystem.getInfo(directory) then
			local ok, err = copyDirectory("examples/" .. directory, directory)
			if not ok then love.window.showMessageBox(directory, tostring(err), "error") end
		end
	end
	
	minGUI_info = love.filesystem.getInfo("Trashcan")	
	if not minGUI_info then love.filesystem.createDirectory("Trashcan") end
end

-- Open a folder in its own window, or raise its existing window.
function GEM_open_folder(path)
    local info = type(path) == "string" and love.filesystem.getInfo(path)
    if not info or info.type ~= "directory" then return end
    for id, gadget in minGUI_each_gadget() do
        if gadget.tp == MG_WINDOW and gadget.driveDirectory == path then
            minGUI:set_window_on_top(id)
            return id
        end
    end
    local window = minGUI:add_window(96, 128, 640, 480, path,
        bit.bor(MG_FLAG_WINDOW_TITLEBAR, MG_FLAG_WINDOW_BUTTONS), BASE_WINDOW)
    if not window then return end
    local area = GEM_create_drive_scrollarea(window, path)
    if not area then minGUI:delete_gadget(window); return end
    minGUI:set_window_on_top(window)
    return window, area
end

-- Populate a drive with its folders, text files and BASIC programs.
function GEM_create_drive_scrollarea(window, directory)
    local bounds = minGUI.gtree[window]
    local top = minGUI_window_top_inset(window) + minGUI:window_menu_height(window)
    local bottom = math.max(MG_WINDOW_BORDER_WIDTH, minGUI:window_footerbar_height(window))
    local width, height = bounds.width - 2 * MG_WINDOW_BORDER_WIDTH, bounds.height - top - bottom
    local items, files = {}, {}
    for _, name in ipairs(love.filesystem.getDirectoryItems(directory)) do
        local info = love.filesystem.getInfo(directory .. "/" .. name)
        local icon
        if info and info.type == "directory" then
            icon = "icons/folder.png"
        elseif info and info.type == "file" then
            local extension = name:lower():match("%.([^%.]+)$")
            if extension == "txt" then icon = "icons/text_file.png"
            elseif extension == "bas" then icon = "icons/program_file.png"
            elseif extension == "ogg" then icon = "icons/music_file.png"
            elseif extension == "wav" then icon = "icons/sound_file.png"
            elseif extension == "jpg" or extension == "png" then icon = "icons/image_file.png" end
        end
        if icon then
            local group = info.type == "directory" and items or files
            group[#group + 1] = {name = name, icon = icon}
        end
    end
    -- Create folders first, preserving the listing order within each group.
    for _, file in ipairs(files) do items[#items + 1] = file end

    GEM_drive_images = GEM_drive_images or {}
    local font = minGUI.font[minGUI.numFont]
    local padding, gap, cellWidth, iconSize = 12, 16, 128, 96
    local columns = math.max(1, math.floor((width - MG_SCROLLBAR_SIZE - 2 * padding + gap) / (cellWidth + gap)))
    local entries, rowHeights = {}, {}
    local lineHeight = font:getHeight() * font:getLineHeight()
    for i, item in ipairs(items) do
        local _, lines = font:getWrap(item.name, cellWidth)
        local row = math.floor((i - 1) / columns) + 1
        local labelHeight = math.ceil(math.max(1, #lines) * lineHeight) + 2
        entries[i] = {name = item.name, icon = item.icon, row = row, labelHeight = labelHeight}
        rowHeights[row] = math.max(rowHeights[row] or 0, iconSize + 4 + labelHeight)
    end
    local rowY, contentHeight = {}, padding
    for row, rowHeight in ipairs(rowHeights) do
        rowY[row] = contentHeight
        contentHeight = contentHeight + rowHeight + gap
    end
    contentHeight = math.max(height, contentHeight + padding)
    local area = minGUI:add_scrollarea(MG_WINDOW_BORDER_WIDTH, 0,
        width, height, width, contentHeight, nil, window)
    if not area then return end
    minGUI.gtree[area].driveDirectory = directory
    bounds.driveDirectory, bounds.driveScrollarea = directory, area
    for i, entry in ipairs(entries) do
        local x = padding + ((i - 1) % columns) * (cellWidth + gap)
        local y = rowY[entry.row]
        GEM_drive_images[entry.icon] = GEM_drive_images[entry.icon] or love.graphics.newImage(entry.icon)
        local image = minGUI:add_image(x + (cellWidth - iconSize) / 2, y, iconSize, iconSize,
            GEM_drive_images[entry.icon], MG_FLAG_DRAG_DROPPABLE, area)
        local label = minGUI:add_label(x, y + iconSize + 4, cellWidth, entry.labelHeight,
            entry.name, MG_FLAG_ALIGN_CENTER, area)
        if image then
            minGUI.gtree[image].dragLabel = label
            minGUI.gtree[image].filePath = directory .. "/" .. entry.name
            minGUI.gtree[image].fileName = entry.name
        end
        if label then
            minGUI.gtree[label].wrapText = true
            minGUI.gtree[label].apaper = 0
        end
    end
    return area
end

local function trashIndex()
    local index = {}
    local data = love.filesystem.read(".trashcan-index") or ""
    local function decode(hex) return (hex:gsub("%x%x", function(byte) return string.char(tonumber(byte,16)) end)) end
    for key,value in data:gmatch("(%x+) (%x+)\n") do index[decode(key)] = decode(value) end
    return index
end

local function saveTrashIndex(index)
    local function encode(text) return (text:gsub(".", function(char) return string.format("%02x",char:byte()) end)) end
    local lines = {}
    for path,origin in pairs(index) do lines[#lines+1]=encode(path).." "..encode(origin).."\n" end
    return love.filesystem.write(".trashcan-index",table.concat(lines))
end

local function removeTree(path)
    local info = love.filesystem.getInfo(path)
    if not info then return true end
    if info.type == "directory" then
        for _,name in ipairs(love.filesystem.getDirectoryItems(path)) do
            local ok,err = removeTree(path.."/"..name)
            if not ok then return nil,err end
        end
    end
    return love.filesystem.remove(path)
end

local function refreshDrive(directory)
    local windows={}
    for id,g in minGUI_each_gadget() do
        if g.tp==MG_WINDOW and g.driveDirectory==directory then windows[#windows+1]=id end
    end
    for _,id in ipairs(windows) do
        local old=minGUI.gtree[id].driveScrollarea
        local area=GEM_create_drive_scrollarea(id,directory)
        if area then
            if old and minGUI.gtree[old] then minGUI:delete_gadget(old) end
            _G[directory:upper().."_DRIVE_SCROLLAREA"]=area
        end
    end
end

function GEM_empty_trashcan()
    local index=trashIndex()
    local ok,err=true
    for _,name in ipairs(love.filesystem.getDirectoryItems("Trashcan")) do
        local path="Trashcan/"..name
        local removed,reason=removeTree(path)
        if removed then index[path]=nil else ok,err=nil,reason;break end
    end
    local saved,reason=saveTrashIndex(index)
    refreshDrive("Trashcan")
    if not ok or not saved then love.window.showMessageBox("Trashcan",tostring(err or reason),"error") end
    return ok and saved
end

function GEM_restore_trash_item(sourceID)
    local source=minGUI.gtree[sourceID]
    if not source or not source.filePath or not source.filePath:match("^Trashcan/[^/]+$") then return end
    local index=trashIndex()
    local origin=index[source.filePath]
    if not origin then love.window.showMessageBox("Trashcan","Original location is unknown for this entry.","error");return end
    local directory,name=origin:match("^(.*)/([^/]+)$")
    local ready,reason=love.filesystem.createDirectory(directory)
    if not ready then love.window.showMessageBox("Trashcan",tostring(reason),"error");return end
    local path=source.filePath
    local copied,destination=GEM_drop_drive_item(sourceID,nil,directory,name)
    if not copied then return end
    local ok,err=removeTree(path)
    if ok then index[path]=nil;local saved,reason=saveTrashIndex(index);if not saved then err=reason end end
    refreshDrive(directory);refreshDrive("Trashcan")
    if err then love.window.showMessageBox("Trashcan",tostring(err),"error") end
    return ok,destination
end

-- Move an entry into Trashcan; remove the source only after a successful copy.
function GEM_trash_drive_item(sourceID)
    local source = type(sourceID) == "table" and sourceID or minGUI.gtree[sourceID]
    if not source or not source.filePath then return end
    local window = minGUI.gtree[source.parent]
    while window and not (window.tp == MG_WINDOW and window.driveDirectory) do
        window = minGUI.gtree[window.parent]
    end
    if not window or window.driveDirectory == "Trashcan" then return end
    local path = source.filePath
    -- Only delete an entry inside its owning drive, never the drive itself.
    if path:sub(1, #window.driveDirectory + 1) ~= window.driveDirectory .. "/"
        or path:find("/../", 1, true) or path:sub(-3) == "/.." then return end
    local copied, destination = GEM_drop_drive_item(sourceID, nil, "Trashcan")
    if not copied then return nil end
    local index=trashIndex()
    index[destination]=path
    local saved,reason=saveTrashIndex(index)
    if not saved then
        love.window.showMessageBox("Trashcan",tostring(reason),"error")
        refreshDrive("Trashcan")
        return nil
    end
    local function removeEntry(entryPath)
        local info = love.filesystem.getInfo(entryPath)
        if not info then return true end
        if info.type == "directory" then
            for _, child in ipairs(love.filesystem.getDirectoryItems(entryPath)) do
                local ok, err = removeEntry(entryPath .. "/" .. child)
                if not ok then return nil, err end
            end
        end
        return love.filesystem.remove(entryPath)
    end
    local ok, err = removeEntry(path)
    local oldArea = window.driveScrollarea
    local area = GEM_create_drive_scrollarea(window.num, window.driveDirectory)
    if area then
        if oldArea and minGUI.gtree[oldArea] then minGUI:delete_gadget(oldArea) end
        _G[window.driveDirectory:upper() .. "_DRIVE_SCROLLAREA"] = area
    end
    local trashWindows = {}
    for id, gadget in minGUI_each_gadget() do
        if gadget.tp == MG_WINDOW and gadget.driveDirectory == "Trashcan" then trashWindows[#trashWindows + 1] = id end
    end
    for _, id in ipairs(trashWindows) do
        local trash = minGUI.gtree[id]
        local previous = trash.driveScrollarea
        local refreshed = GEM_create_drive_scrollarea(id, "Trashcan")
        if refreshed then
            if previous and minGUI.gtree[previous] then minGUI:delete_gadget(previous) end
            TRASHCAN_SCROLLAREA = refreshed
        end
    end
    if not ok then love.window.showMessageBox("Trashcan", tostring(err or "Unable to remove source " .. path), "error") end
    return ok, destination
end

-- Copy the disk entry represented by an icon, then rebuild the destination grid.
function GEM_drop_drive_item(sourceID, targetID, destinationDirectory, destinationName)
    local source = type(sourceID) == "table" and sourceID or minGUI.gtree[sourceID]
    local target = destinationDirectory and {driveDirectory=destinationDirectory} or minGUI.gtree[targetID]
    if not source or not source.filePath then return end
    while target and not (target.driveDirectory and (target.tp == MG_WINDOW or destinationDirectory)) do
        target = minGUI.gtree[target.parent]
    end
    if not target then return end
    if target.driveDirectory == "Trashcan" and not destinationDirectory then return GEM_trash_drive_item(sourceID) end
    local sourcePath, directory = source.filePath, target.driveDirectory
    local sourceDirectory, name = sourcePath:match("^(.*)/([^/]+)$")
    name = destinationName or name
    if not name or sourceDirectory == directory then return end
    if directory == sourcePath or directory:sub(1, #sourcePath + 1) == sourcePath .. "/" then return end
    local destination = directory .. "/" .. name
    local info = love.filesystem.getInfo(sourcePath)
    if not info then return end
    -- Preserve existing entries by choosing a free copy name.
    local stem, extension = name, ""
    if info.type == "file" then
        local base, suffix = name:match("^(.*)(%.[^%.]+)$")
        if base then stem, extension = base, suffix end
    end
    local copyNumber = 1
    while love.filesystem.getInfo(destination) do
        destination = directory .. "/" .. stem .. " (copy " .. copyNumber .. ")" .. extension
        copyNumber = copyNumber + 1
    end
    local function copyEntry(from, to)
        local entry = love.filesystem.getInfo(from)
        if not entry then return nil, "Missing entry: " .. from end
        if entry.type == "directory" then
            local ok, err = love.filesystem.createDirectory(to)
            if not ok then return nil, err end
            for _, child in ipairs(love.filesystem.getDirectoryItems(from)) do
                local success, reason = copyEntry(from .. "/" .. child, to .. "/" .. child)
                if not success then return nil, reason end
            end
            return true
        elseif entry.type == "file" then
            local data, err = love.filesystem.read(from)
            if not data then return nil, err end
            return love.filesystem.write(to, data)
        end
        return nil, "Unsupported entry: " .. from
    end
    local ok, err = copyEntry(sourcePath, destination)
    local oldArea = target.driveScrollarea
    local area = target.num and GEM_create_drive_scrollarea(target.num, directory)
    if area then
        if oldArea and minGUI.gtree[oldArea] then minGUI:delete_gadget(oldArea) end
        _G[directory:upper() .. "_DRIVE_SCROLLAREA"] = area
    end
    if not ok then love.window.showMessageBox("Copy failed", tostring(err), "error") end
    return ok, destination
end

-- Snapshot icons before refreshing any grid: refresh deletes their gadget IDs.
function GEM_drop_drive_selection(sources, targetID, trash)
    local entries = {}
    local target = minGUI.gtree[targetID]
    while target and not (target.tp == MG_WINDOW and target.driveDirectory) do
        target = minGUI.gtree[target.parent]
    end
    if not trash and not target then return end
    for _, id in ipairs(sources) do
        local image = minGUI.gtree[id]
        if image and image.filePath then
            local owner = minGUI.gtree[image.parent]
            while owner and not (owner.tp == MG_WINDOW and owner.driveDirectory) do
                owner = minGUI.gtree[owner.parent]
            end
            if owner then
                entries[#entries + 1] = {filePath = image.filePath, parent = owner.num}
            end
        end
    end
    for _, entry in ipairs(entries) do
        if trash or target.driveDirectory == "Trashcan" then
            GEM_trash_drive_item(entry)
        else
            GEM_drop_drive_item(entry, target.num)
        end
    end
end

function GEM_create_drive_entry(windowID, folder)
    local window = minGUI.gtree[windowID]
    if not window or not window.driveDirectory or not minGUI.gtree[window.driveScrollarea] then return end
    local stem, extension = folder and 'New folder' or 'New file', folder and '' or '.txt'
    local name, number = stem .. extension, 0
    while love.filesystem.getInfo(window.driveDirectory .. '/' .. name) do
        number = number + 1
        name = stem .. ' (' .. number .. ')' .. extension
    end
    local path = window.driveDirectory .. '/' .. name
    local ok, err
    if folder then ok, err = love.filesystem.createDirectory(path)
    else ok, err = love.filesystem.write(path, '') end
    if not ok then love.window.showMessageBox('Create', tostring(err), 'error'); return end
    refreshDrive(window.driveDirectory)
    return path
end

function GEM_rename_drive_entry(path, name)
    if type(name) ~= 'string' or name:match('^%s*$') or name == '.' or name == '..'
        or name:find('[/\\%z]') then return nil, 'Invalid name' end
    local directory = path:match('^(.*)/[^/]+$')
    if not directory then return nil, 'Invalid path' end
    local destination = directory .. '/' .. name
    if destination == path then return true end
    if love.filesystem.getInfo(destination) then return nil, 'This name already exists' end
    local save = love.filesystem.getSaveDirectory()
    if love.filesystem.getRealDirectory(path) ~= save then return nil, 'This entry is not writable' end
    local ok, err = os.rename(save .. '/' .. path, save .. '/' .. destination)
    if not ok then return nil, err end
    if directory == 'Trashcan' then
        local index = trashIndex()
        index[destination], index[path] = index[path], nil
        local saved, reason = saveTrashIndex(index)
        if not saved then
            os.rename(save .. '/' .. destination, save .. '/' .. path)
            return nil, reason
        end
    end
    -- Windows opened inside the renamed folder must follow its new path.
    local directories = {[directory] = true}
    for _, window in minGUI_each_gadget() do
        local current = window.driveDirectory
        if window.tp == MG_WINDOW and current
            and (current == path or current:sub(1, #path + 1) == path .. '/') then
            window.driveDirectory = destination .. current:sub(#path + 1)
            window.title = window.driveDirectory
            directories[window.driveDirectory] = true
        end
    end
    for current in pairs(directories) do refreshDrive(current) end
    return true
end
