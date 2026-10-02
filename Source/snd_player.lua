-- Minimal audio player, using streamed playback for OGG and WAV files.
local player

function close_snd_player()
    if not player then return end
    player.source:stop()
    player.source:release()
    if minGUI.gtree[player.window] then minGUI:delete_gadget(player.window) end
    player=nil
end

function open_snd_player(path)
    if player and player.path==path and minGUI.gtree[player.window] then
        minGUI:set_window_on_top(player.window);return player.window
    end
    local ok,source=pcall(love.audio.newSource,path,'stream')
    if not ok then love.window.showMessageBox('Audio player',tostring(source),'error');return end
    close_snd_player()
    local window=minGUI:add_window(192,160,440,160,'Audio - '..path,
        bit.bor(MG_FLAG_WINDOW_TITLEBAR,MG_FLAG_WINDOW_CLOSE),BASE_WINDOW)
    if not window then source:release();return end
    local name=path:match('[^/]+$') or path
    minGUI:add_label(16,8,408,28,name,MG_FLAG_ALIGN_CENTER,window)
    local play=minGUI:add_button(104,52,104,32,'Play',nil,window)
    local stop=minGUI:add_button(224,52,104,32,'Stop',nil,window)
    player={window=window,path=path,source=source,play=play,stop=stop}
    return window
end

function snd_player_event(gadget,event)
    if not player or event~=MG_EVENT_LEFT_MOUSE_CLICK then return false end
    if gadget==player.play then
        if not player.source:isPlaying() then player.source:play() end
        return true
    elseif gadget==player.stop then player.source:stop();return true end
    return false
end

function update_snd_player()
    if player and not minGUI.gtree[player.window] then close_snd_player() end
end
