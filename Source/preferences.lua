local preferences = {theme='GEM', font=1}
local dialog
local configPath = '.preferences'

local function themes()
    local result = {}
    for _, name in ipairs(love.filesystem.getDirectoryItems('minGUI/themes')) do
        if love.filesystem.getInfo('minGUI/themes/' .. name, 'directory') then result[#result+1]=name end
    end
    table.sort(result)
    return result
end

local function save(theme, font)
    local ok, err = love.filesystem.write(configPath, theme .. '\n' .. font .. '\n')
    if not ok then love.window.showMessageBox('Preferences', tostring(err), 'error') end
    return ok
end

function GEM_load_preferences()
    minGUI:load_font(1, 'fonts/CPCMode1.ttf', 16)
    minGUI:load_font(2, 'fonts/Born2bSportyV2.ttf', 16)
    minGUI:load_font(3, 'fonts/OldWizard.ttf', 16)
    minGUI:load_font(4, 'fonts/MEGAMAN10.ttf', 16)
    local data = love.filesystem.read(configPath)
    local theme, font
    if data then theme, font = data:match('^([^\r\n]+)\r?\n(%d+)');font=tonumber(font) end
    local validTheme = false
    for _, name in ipairs(themes()) do if name==theme then validTheme=true end end
    if not validTheme then theme='GEM' end
    if not font or font<1 or font>4 then font=1 end
    preferences={theme=theme,font=font}
    minGUI:set_theme(theme)
    minGUI:set_font(font)
    if not data or not validTheme or data ~= theme .. '\n' .. font .. '\n' then save(theme,font) end
end

function GEM_open_preferences()
    if dialog and minGUI.gtree[dialog.window] then minGUI:set_window_on_top(dialog.window);return end
    local window = minGUI:add_window(220,160,420,330,'Preferences',
        bit.bor(MG_FLAG_WINDOW_TITLEBAR,MG_FLAG_WINDOW_CLOSE,MG_FLAG_WINDOW_TOP_PRIORITY),BASE_WINDOW)
    if not window then return end
    local names = themes()
    minGUI:add_label(12,8,100,24,'Theme',nil,window)
    local list = minGUI:add_list(12,36,390,152,names,nil,window)
    for index,name in ipairs(names) do if name==preferences.theme then minGUI:set_gadget_state(list,index) end end
    minGUI:add_label(12,196,100,24,'Font',nil,window)
    local options={}
    for index=1,4 do
        options[index]=minGUI:add_option(100+(index-1)*72,196,64,24,tostring(index),nil,window)
    end
    minGUI:set_gadget_state(options[preferences.font],true)
    local button=minGUI:add_button(292,242,110,28,'Ok',nil,window)
    dialog={window=window,list=list,options=options,button=button,themes=names}
end

function GEM_preferences_event(gadget,event)
    if not dialog or not minGUI.gtree[dialog.window] then dialog=nil;return false end
    if gadget~=dialog.button or event~=MG_EVENT_LEFT_MOUSE_CLICK then return false end
    local theme=dialog.themes[minGUI:get_gadget_state(dialog.list)]
    local font=preferences.font
    for index,id in ipairs(dialog.options) do if minGUI:get_gadget_state(id) then font=index;break end end
    if not theme or not save(theme,font) then return true end
    preferences={theme=theme,font=font}
    minGUI:set_theme(theme)
    minGUI:set_font(font)
    minGUI:delete_gadget(dialog.window)
    dialog=nil
    for _,g in minGUI_each_gadget() do
        if g.tp==MG_EDITOR then minGUI_editor_layout(g,true)
        elseif g.tp==MG_STRING then minGUI_shift_text(g.num,g.text)
        elseif g.tp==MG_LIST or g.tp==MG_COMBO_BOX then minGUI_choice_layout(g) end
    end
    GEM_refresh_file_windows()
    return true
end
