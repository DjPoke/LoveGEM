-- One simple notepad window, editing a file through Love's filesystem.
local notepad

function close_notepad()
    if notepad and minGUI.gtree[notepad.window] then minGUI:delete_gadget(notepad.window) end
    notepad=nil
end

function open_notepad(path)
    if type(path)~='string' or path=='' then return nil,'Expected a file path' end
    if notepad and notepad.path==path and minGUI.gtree[notepad.window] then
        minGUI:set_window_on_top(notepad.window)
        minGUI:set_focus(notepad.editor)
        return notepad.window
    end
    local text,err=love.filesystem.read(path)
    if not text then love.window.showMessageBox('Notepad',tostring(err),'error');return nil,err end
    close_notepad()
    local width,height=720,540
    local window=minGUI:add_window(160,100,width,height,'Notepad - '..path,
        bit.bor(MG_FLAG_WINDOW_TITLEBAR,MG_FLAG_WINDOW_CLOSE),BASE_WINDOW)
    if not window then return end
    local border=MG_WINDOW_BORDER_WIDTH
    local menuHeight=math.max(20,minGUI.font[minGUI.numFont]:getHeight()+4)
    local menu=minGUI:add_menu(border,0,width-2*border,menuHeight,
        {{head_menu='File',menu_list={'Save'}}},nil,window)
    local contentHeight=height-minGUI_window_top_inset(window)-menuHeight-border
    local statusHeight=24
    local editor=minGUI:add_editor(border,0,width-2*border,contentHeight-statusHeight,text,nil,window)
    local row=minGUI:add_label(border+8,contentHeight-statusHeight,180,statusHeight,'Line: 1',nil,window)
    local column=minGUI:add_label(border+196,contentHeight-statusHeight,180,statusHeight,'Column: 1',nil,window)
    notepad={window=window,menu=menu,editor=editor,row=row,column=column,path=path}
    minGUI:set_focus(editor)
    return window
end

function update_notepad()
    if not notepad then return end
    if not minGUI.gtree[notepad.window] then notepad=nil;return end
    local editor=minGUI.gtree[notepad.editor]
    if not editor then return end
    minGUI:get_cursor_position(notepad.editor)
    local row='Line: '..(editor.cursory+1)
    local column='Column: '..(editor.cursorx+1)
    if minGUI.gtree[notepad.row].text~=row then minGUI:set_gadget_text(notepad.row,row) end
    if minGUI.gtree[notepad.column].text~=column then minGUI:set_gadget_text(notepad.column,column) end
end

-- Menu gadget ID prevents File/Save from being mistaken for Desk/Desktop infos.
function notepad_menu_event(menu,item,gadget)
    if not notepad or gadget~=notepad.menu then return false end
    if menu==1 and item==1 and minGUI.gtree[notepad.editor] then
        local ok,err=love.filesystem.write(notepad.path,minGUI:get_gadget_text(notepad.editor))
        if not ok then love.window.showMessageBox('Notepad - Save',tostring(err),'error') end
        minGUI:set_focus(notepad.editor)
    end
    return true
end
