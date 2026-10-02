-- Minimal image viewer: one window and a canvas, preserving image proportions.
local viewer

local function layout_viewer(force)
    if not viewer then return end
    local window=minGUI.gtree[viewer.window]
    local canvas=minGUI.gtree[viewer.canvas]
    if not window or not canvas then viewer=nil;return end
    local border=MG_WINDOW_BORDER_WIDTH
    local cw=math.max(1,window.width-2*border)
    local ch=math.max(1,window.height-minGUI_window_top_inset(viewer.window)
        -minGUI:window_menu_height(viewer.window)
        -math.max(border,minGUI:window_footerbar_height(viewer.window)))
    if canvas.width~=cw or canvas.height~=ch then
        canvas.width,canvas.height=cw,ch
        canvas.canvas=love.graphics.newCanvas(cw,ch)
        force=true
    end
    if not force then return end
    local image=viewer.image
    local scale=math.min(cw/image:getWidth(),ch/image:getHeight())
    love.graphics.push('all')
    love.graphics.setCanvas(canvas.canvas)
    love.graphics.setScissor()
    love.graphics.clear(0.12,0.12,0.12,1)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(image,(cw-image:getWidth()*scale)/2,(ch-image:getHeight()*scale)/2,0,scale,scale)
    love.graphics.pop()
end

function close_img_viewer()
    if viewer and minGUI.gtree[viewer.window] then minGUI:delete_gadget(viewer.window) end
    viewer=nil
end

function open_img_viewer(path)
    if viewer and viewer.path==path and minGUI.gtree[viewer.window] then
        minGUI:set_window_on_top(viewer.window);return viewer.window
    end
    local ok,image=pcall(love.graphics.newImage,path)
    if not ok then love.window.showMessageBox('Image viewer',tostring(image),'error');return end
    close_img_viewer()
    local width,height=640,480
    local window=minGUI:add_window(128,128,width,height,'Image - '..path,
        bit.bor(MG_FLAG_WINDOW_TITLEBAR,MG_FLAG_WINDOW_CLOSE,MG_FLAG_WINDOW_RESIZE),BASE_WINDOW)
    if not window then return end
    local border=MG_WINDOW_BORDER_WIDTH
    local cw,ch=width-2*border,height-minGUI_window_top_inset(window)-math.max(border,minGUI:window_footerbar_height(window))
    local canvas=minGUI:add_canvas(border,0,cw,ch,nil,window)
    if not canvas then minGUI:delete_gadget(window);return end
    viewer={window=window,canvas=canvas,path=path,image=image}
    layout_viewer(true)
    return window
end

function update_img_viewer()
    layout_viewer(false)
end
