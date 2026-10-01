-- create drives (the first time)
function GEM_create_drives()
	local minGUI_info = love.filesystem.getInfo("Swap")
	if not minGUI_info then love.filesystem.createDirectory("Swap") end
	
	minGUI_info = love.filesystem.getInfo("Work")	
	if not minGUI_info then love.filesystem.createDirectory("Work") end
	
	minGUI_info = love.filesystem.getInfo("Play")	
	if not minGUI_info then love.filesystem.createDirectory("Play") end
	
	minGUI_info = love.filesystem.getInfo("Relax")	
	if not minGUI_info then love.filesystem.createDirectory("Relax") end
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
            elseif extension == "bas" then icon = "icons/program_file.png" end
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

-- Copy the disk entry represented by an icon, then rebuild the destination grid.
function GEM_drop_drive_item(sourceID, targetID)
    local source, target = minGUI.gtree[sourceID], minGUI.gtree[targetID]
    if not source or not source.filePath then return end
    while target and not (target.tp == MG_WINDOW and target.driveDirectory) do
        target = minGUI.gtree[target.parent]
    end
    if not target then return end
    local sourcePath, directory = source.filePath, target.driveDirectory
    local sourceDirectory, name = sourcePath:match("^(.*)/([^/]+)$")
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
    local area = GEM_create_drive_scrollarea(target.num, directory)
    if area then
        if oldArea and minGUI.gtree[oldArea] then minGUI:delete_gadget(oldArea) end
        _G[directory:upper() .. "_DRIVE_SCROLLAREA"] = area
    end
    if not ok then love.window.showMessageBox("Copy failed", tostring(err), "error") end
    return ok, destination
end
