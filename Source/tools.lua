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
    for i, entry in ipairs(entries) do
        local x = padding + ((i - 1) % columns) * (cellWidth + gap)
        local y = rowY[entry.row]
        GEM_drive_images[entry.icon] = GEM_drive_images[entry.icon] or love.graphics.newImage(entry.icon)
        minGUI:add_image(x + (cellWidth - iconSize) / 2, y, iconSize, iconSize, GEM_drive_images[entry.icon], nil, area)
        local label = minGUI:add_label(x, y + iconSize + 4, cellWidth, entry.labelHeight,
            entry.name, MG_FLAG_ALIGN_CENTER, area)
        if label then
            minGUI.gtree[label].wrapText = true
            minGUI.gtree[label].apaper = 0
        end
    end
    return area
end

-- load a BASIC script in memory
function GEMBASIC_load(filename)
	return love.filesystem.read(filename)
end

-- update function interpreter
function GEMBASIC_init()
end

-- update function interpreter
function GEMBASIC_update()
end

-- draw function interpreter
function GEMBASIC_draw()
	-- prepare to draw BASIC
	love.graphics.setScissor(0, 0, 1920, 1080)
	love.graphics.setCanvas(GEMBASIC_canvas)
	
	-- draw BASIC
	GEMBASIC_CLS()
	GEMBASIC_MODE(1)
	GEMBASIC_PEN(255, 255, 0)
	GEMBASIC_PRINT("Hello, World!", 0, 0)
	
	-- draw GEMBASIC canvas
	love.graphics.setCanvas()
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(GEMBASIC_canvas, 0, 0, 0, 4, 4)
end
