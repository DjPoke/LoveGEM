local dialog

local function close_dialog()
    if dialog and minGUI.gtree[dialog.window] then minGUI:delete_gadget(dialog.window) end
    dialog = nil
end

function GEM_open_file_dialog(owner, path)
    local drive = minGUI.gtree[owner]
    if not drive or not drive.driveDirectory or not minGUI.gtree[drive.driveScrollarea] then return end
    close_dialog()
    local rename = path ~= nil
    local window = minGUI:add_window(200, 160, 420, 160, rename and 'Rename' or 'Search',
        bit.bor(MG_FLAG_WINDOW_TITLEBAR, MG_FLAG_WINDOW_CLOSE, MG_FLAG_WINDOW_TOP_PRIORITY), BASE_WINDOW)
    if not window then return end
    minGUI:add_label(12, 8, 390, 24, rename and 'Name' or 'Search', nil, window)
    local input = minGUI:add_string(12, 36, 390, 26, path and path:match('[^/]+$') or '', nil, window)
    local button = minGUI:add_button(292, 76, 110, 26, rename and 'Rename' or 'Close', nil, window)
    dialog = {window=window, owner=owner, path=path, input=input, button=button}
    if rename then minGUI:add_keyboard_shortcut(window, 'return', 'rename_confirm') end
    minGUI:set_focus(input)
end

function GEM_update_file_dialog()
    if not dialog then return end
    if not minGUI.gtree[dialog.window] then dialog=nil;return end
    if not minGUI.gtree[dialog.owner] then close_dialog();return end
    if dialog.path then return end
    local query = minGUI:get_gadget_text(dialog.input):lower()
    if dialog.query == query then return end
    dialog.query = query
    local area = minGUI.gtree[minGUI.gtree[dialog.owner].driveScrollarea]
    if not area then return end
    local found
    for _, image in minGUI_each_gadget() do
        if image.tp == MG_IMAGE and image.parent == area.num and image.fileName then
            image.selected = query ~= '' and image.fileName:lower() == query
            if image.selected then found = image end
        end
    end
    if found then
        local function reveal(position, size, scroll, viewport)
            if position < scroll then return position end
            if position + size > scroll + viewport then return position + size - viewport end
            return scroll
        end
        area.scrollX = reveal(found.x, found.width, area.scrollX or 0, area.viewWidth)
        area.scrollY = reveal(found.y, found.height, area.scrollY or 0, area.viewHeight)
        minGUI_scrollarea_layout(area)
    end
end

function GEM_file_dialog_event(gadget, event)
    if not dialog then return false end
    if not ((gadget == dialog.button and event == MG_EVENT_LEFT_MOUSE_CLICK)
        or (gadget == dialog.window and event == 'rename_confirm')) then return false end
    if dialog.path then
        local ok, err = GEM_rename_drive_entry(dialog.path, minGUI:get_gadget_text(dialog.input))
        if not ok then love.window.showMessageBox('Rename', tostring(err), 'error');return true end
    end
    close_dialog()
    return true
end
