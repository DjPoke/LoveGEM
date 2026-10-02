--==================
--     Löve GEM
--
--   Bruno Vignoli
--   MIT 2023-2026
--
-- with the help of
-- Codex
--==================

-- require minGUI & other stuffs
require "minGUI.minGUI"
require "GEM"
require "instructions"
require "BASIC"
require "lexer"
require "parser"
require "notepad"
require "img_viewer"
require "snd_player"

-- default love.load function
function love.load()
	-- some vars for GEM windows
	BASE_WINDOW = nil

	DESKTOP_INFOS_WINDOW = nil
	DESKTOP_INFOS_WINDOW_OK = nil

	SWAP_DRIVE_WINDOW = nil
	WORK_DRIVE_WINDOW = nil
	PLAY_DRIVE_WINDOW = nil
	RELAX_DRIVE_WINDOW = nil
	
	TRASHCAN_WINDOW = nil
	
	CONTEXT_MENU = nil
	CONTEXT_MENU_INFO = nil

	-- initialize minGUI
	minGUI_init()

	-- set theme
	minGUI:set_theme("GEM")

	-- set colors
	minGUI:set_background_color(1, 1, 1, 1)
	minGUI:set_text_color(0, 0, 0, 1)
	minGUI:set_inverted_text_color(1, 1, 1, 1)
	minGUI:set_greyed_background_color(1, 1, 1, 1)
	minGUI:set_greyed_text_color(0.5, 0.5, 0.5, 1)

	-- load & set font
	minGUI:load_font(1, "fonts/CPCMode1.ttf", 16)
	minGUI:set_font(1)

	-- init array of windows & array of gadgets
	minGUI_window = {}
	minGUI_gadget = {}

	-- add default window
	BASE_WINDOW = minGUI:add_window(320, 60, 1280, 960)

	-- add menu at the top of the window
	MAIN_MENU = minGUI:add_menu(0, 0, 1280, 16, {
		{head_menu = "Desk", menu_list = {"Desktop infos..."}},
		{head_menu = "File", menu_list = {"Open", "Infos/Rename", "Search", "-", "New folder", "Close folder", "Close window", "Select all", "Select none", "-", "Delete", "-", "Quit"}},
		{head_menu = "View", menu_list = {"Show as icons", "Show as text", "-", "Sort by name", "Sort by date", "Sort by size", "Sort by type", "Do not sort", "-", "Define background..."}},
		{head_menu = "Options", menu_list = {"Install icon", "Install application", "Install devices", "Remove desktop icon", "-", "Set preferences", "Desktop configuration", "Change resolution", "-", "Load desktop", "Save desktop"}}
	}, nil, BASE_WINDOW)

	-- add default canvas
	minGUI:add_panel(0, 0, 1280, 944, nil, BASE_WINDOW)

	-- show drives
	icon = {}
	icon[1] = love.graphics.newImage("icons/swap_drive.png")
	icon[2] = love.graphics.newImage("icons/work_drive.png")
	icon[3] = love.graphics.newImage("icons/play_drive.png")
	icon[4] = love.graphics.newImage("icons/relax_drive.png")
	icon[5] = love.graphics.newImage("icons/trashcan.png")

	minGUI_gadget[1] = minGUI:add_image(32, 32, 128, 128, icon[1], nil, BASE_WINDOW)
	minGUI_gadget[2] = minGUI:add_image(192, 32, 128, 128, icon[2], nil, BASE_WINDOW)
	minGUI_gadget[3] = minGUI:add_image(352, 32, 128, 128, icon[3], nil, BASE_WINDOW)
	minGUI_gadget[4] = minGUI:add_image(512, 32, 128, 128, icon[4], nil, BASE_WINDOW)
	minGUI_gadget[5] = minGUI:add_image(32, 768, 128, 128, icon[5], nil, BASE_WINDOW)

	minGUI.gtree[minGUI_gadget[5]].imageDropTarget = true

	-- Drive launchers preserve window focus until their click opens or raises a drive.
	for i = 1, 5 do
		minGUI.gtree[minGUI_gadget[i]].preserveWindowFocus = true
	end

	-- load mouse pointers
	minGUI_mouse_pointer = {
		arrow = love.mouse.newCursor("mouse_cursors/arrow.png", 0, 0),
		wait = love.mouse.newCursor("mouse_cursors/wait.png", 0, 0)
	}

	-- set mouse pointer
	love.mouse.setCursor(minGUI_mouse_pointer.arrow)

	-- create loveGEM disk drives, if needed
	GEM_create_drives()

	-- ********** vars **********
	GEMBASIC_running_prog = false -- no running program at start
	GEMBASIC_finished = false
	GEMBASIC_returningToGUI = false
	GEMBASIC_prog = "" -- void string for BASIC program
	GEMBASIC_lexed_prog = {} -- lexed BASIC program

	GEMBASIC_canvas = love.graphics.newCanvas(480, 270) -- canvas for BASIC games/apps

	GEMBASIC_paper_red = 0 -- clear color
	GEMBASIC_paper_green = 0
	GEMBASIC_paper_blue = 0

	GEMBASIC_font_mode_1 = love.graphics.newFont("fonts/CPCMode1.ttf", 8, "mono") -- fonts for BASIC
	GEMBASIC_font_mode_0 = love.graphics.newFont("fonts/CPCMode0.ttf", 8, "mono")
end

-- default love.textinput function
function love.textinput(t)
	-- send text input to minGUI
    if not GEMBASIC_running_prog and not GEMBASIC_finished and not GEMBASIC_returningToGUI then minGUI_textinput(t) end
end

-- Resume WAITKEY on any key press.
function love.keypressed(key, scancode, isrepeat)
	if not isrepeat then GEMBASIC_keypressed() end
end

function love.mousepressed(x, y, button)
	GEMBASIC_dismiss()
end

-- default love.update function
function love.update(dt)
	update_img_viewer()
	update_snd_player()
	if GEMBASIC_running_prog then
		GEMBASIC_update()
		return
	end
	if GEMBASIC_finished then return end
	if GEMBASIC_returningToGUI then
		-- Consume the dismissal input before resuming desktop interaction.
		for button = 1, 3 do
			minGUI.mouse.mbtn[button] = love.mouse.isDown(button)
			minGUI.mouse.oldmbtn[button] = minGUI.mouse.mbtn[button]
		end
		if not love.mouse.isDown(1, 2, 3) then GEMBASIC_returningToGUI = false end
		return
	end
	-- update events list for minGUI
	minGUI_update_events(dt)
	update_img_viewer()
	update_notepad()

	-- get new menu events
	local minGUI_eventMenu, minGUI_eventSubMenu, minGUI_menuGadget = minGUI:get_menu_events()

	if notepad_menu_event(minGUI_eventMenu, minGUI_eventSubMenu, minGUI_menuGadget) then
		-- File/Save belongs to the notepad.
	elseif minGUI_menuGadget == MAIN_MENU and minGUI_eventMenu == 1 then
		if minGUI_eventSubMenu == 1 then
			-- desktop infos window
			local minGUI_flags = bit.bor(MG_FLAG_WINDOW_TITLEBAR, MG_FLAG_WINDOW_TOP_PRIORITY)

			DESKTOP_INFOS_WINDOW = minGUI:add_window(320, 240, 640, 480, "Desktop Infos", minGUI_flags, BASE_WINDOW)

			-- add ok button
			DESKTOP_INFOS_WINDOW_OK = minGUI:add_button(520, 395, 100, 25, "Ok", nil, DESKTOP_INFOS_WINDOW)

			-- add label gadgets
			local minGUI_txt = "Love GEM"
			minGUI:add_label(256, 80, 128, 25, minGUI_txt, minGUI_flags, DESKTOP_INFOS_WINDOW)

			minGUI_txt = "========"
			minGUI:add_label(256, 105, 128, 25, minGUI_txt, minGUI_flags, DESKTOP_INFOS_WINDOW)

			minGUI_txt = "By Bruno Vignoli"
			minGUI:add_label(192, 160, 256, 25, minGUI_txt, minGUI_flags, DESKTOP_INFOS_WINDOW)

			minGUI_txt = "A Retro Virtual Computer"
			minGUI:add_label(128, 210, 384, 25, minGUI_txt, minGUI_flags, DESKTOP_INFOS_WINDOW)

			minGUI_txt = "Programmable in BASIC!"
			minGUI:add_label(144, 235, 352, 25, minGUI_txt, minGUI_flags, DESKTOP_INFOS_WINDOW)
		end
	elseif minGUI_menuGadget == MAIN_MENU and minGUI_eventMenu == 2 then
		if minGUI_eventSubMenu == 13 then
			love.event.quit()
		end
	end

	-- get new gadget events
	local gadget, event, source, drop, info = minGUI:get_gadget_events()
	local contextMenu, contextItem = minGUI:get_context_menu_events()
	if contextMenu == CONTEXT_MENU and contextMenu ~= nil and CONTEXT_MENU_INFO then
		if CONTEXT_MENU_INFO.action == "empty" and contextItem == 1 then
			GEM_empty_trashcan()
		elseif CONTEXT_MENU_INFO.action == "restore" and contextItem == 1 then
			GEM_restore_trash_item(CONTEXT_MENU_INFO.source)
		elseif contextItem == 1 then
			-- Run uses the same loading/parsing path as a double-click.
			if gadget then
				table.insert(minGUI.gstack, 1, {eventGadget = gadget, eventType = event, eventSource = source, eventDrop = drop})
			end
			gadget, event, info = contextMenu, MG_EVENT_LEFT_MOUSE_DOUBLECLICK, CONTEXT_MENU_INFO
		elseif contextItem == 3 then
			-- Edit selection: the editor action can use this exact file path.
			open_notepad(CONTEXT_MENU_INFO.filePath)
		elseif contextItem == 5 then
			-- Delete selection: no disk entry is removed without an application handler.
			print("Delete", CONTEXT_MENU_INFO.fileName, CONTEXT_MENU_INFO.filePath)
		end
	end

	-- eventGadget received ?
	if gadget ~= nil then
		-- left click on a gadget ?
		if snd_player_event(gadget, event) then
			-- Audio player owns its Play and Stop buttons.
		elseif event == MG_EVENT_DRAG_DROPPED then
			if gadget == minGUI_gadget[5] then
				GEM_trash_drive_item(source)
			else
				GEM_drop_drive_item(source, gadget)
			end
		elseif event == MG_EVENT_LEFT_MOUSE_CLICK then
			if gadget == DESKTOP_INFOS_WINDOW_OK then
				if DESKTOP_INFOS_WINDOW and minGUI.gtree[DESKTOP_INFOS_WINDOW] then
					minGUI:delete_gadget(DESKTOP_INFOS_WINDOW)
				end
				DESKTOP_INFOS_WINDOW, DESKTOP_INFOS_WINDOW_OK = nil, nil
			elseif info and info.scrollarea and info.filePath
				and love.filesystem.getInfo(info.filePath, "directory") then
				GEM_open_folder(info.filePath)
			else
				local drives = {
					{gadget = minGUI_gadget[1], variable = "SWAP_DRIVE_WINDOW", scrollarea = "SWAP_DRIVE_SCROLLAREA", directory = "Swap", title = "Swap Drive", x = 0, y = 192},
					{gadget = minGUI_gadget[2], variable = "WORK_DRIVE_WINDOW", scrollarea = "WORK_DRIVE_SCROLLAREA", directory = "Work", title = "Work Drive", x = 64, y = 256},
					{gadget = minGUI_gadget[3], variable = "PLAY_DRIVE_WINDOW", scrollarea = "PLAY_DRIVE_SCROLLAREA", directory = "Play", title = "Play Drive", x = 128, y = 320},
					{gadget = minGUI_gadget[4], variable = "RELAX_DRIVE_WINDOW", scrollarea = "RELAX_DRIVE_SCROLLAREA", directory = "Relax", title = "Relax Drive", x = 192, y = 384},
					{gadget = minGUI_gadget[5], variable = "TRASHCAN_WINDOW", scrollarea = "TRASHCAN_SCROLLAREA", directory = "Trashcan", title = "Trashcan", x = 256, y = 448}
				}
				for _, drive in ipairs(drives) do
					if gadget == drive.gadget then
						local window = _G[drive.variable]
						if not window or not minGUI.gtree[window] then
							window = minGUI:add_window(drive.x, drive.y, 640, 480, drive.title,
								bit.bor(MG_FLAG_WINDOW_TITLEBAR, MG_FLAG_WINDOW_BUTTONS), BASE_WINDOW)
							_G[drive.variable] = window
							if window then
								_G[drive.scrollarea] = GEM_create_drive_scrollarea(window, drive.directory)
							end
						end
						if window then minGUI:set_window_on_top(window) end
						break
					end
				end
			end
		elseif event == MG_EVENT_LEFT_MOUSE_DOUBLECLICK then
			local extension = info and info.fileName and info.fileName:lower():match("%.([^%.]+)$")
			if info and info.scrollarea and (extension == "jpg" or extension == "png") then
				open_img_viewer(info.filePath)
			elseif info and info.scrollarea and (extension == "ogg" or extension == "wav") then
				open_snd_player(info.filePath)
			else
			if info and info.scrollarea and info.fileName and info.fileName:lower():sub(-4) == ".bas"
				and not GEMBASIC_running_prog then
				local text, loadError = GEMBASIC_load(info.filePath)
				if not text then
					love.window.showMessageBox("BASIC error", tostring(loadError), "error")
				else
					GEMBASIC_prog = text
					GEMBASIC_lexed_prog = lex(text)
					local ast, err = parse(GEMBASIC_lexed_prog)
					if not ast then
						love.window.showMessageBox("BASIC error", "Line " .. err.line .. ", column " .. err.column .. ": " .. err.message, "error")
					else
						local ok, runtimeError = GEMBASIC_init(ast)
						if not ok then love.window.showMessageBox("BASIC error", tostring(runtimeError), "error") end
					end
				end
			end
			end
		elseif event == MG_EVENT_RIGHT_MOUSE_CLICK then
			local trashItem = info and info.scrollarea and info.filePath
				and info.filePath:match("^Trashcan/[^/]+$")
			if gadget == minGUI_gadget[5] or trashItem then
				if CONTEXT_MENU and minGUI.gtree[CONTEXT_MENU] then minGUI:delete_gadget(CONTEXT_MENU) end
				local action = trashItem and "restore" or "empty"
				local parent = trashItem and TRASHCAN_WINDOW or BASE_WINDOW
				CONTEXT_MENU = minGUI:add_context_menu({trashItem and "Restore" or "Empty"}, parent)
				CONTEXT_MENU_INFO = {action = action, source = gadget}
				if CONTEXT_MENU then minGUI:show_context_menu(CONTEXT_MENU) end
			else
			if info and info.scrollarea and info.fileName and info.fileName:lower():sub(-4) == ".bas"
				and not GEMBASIC_running_prog then

				-- get the parent window of the scrollarea
				local parent_window = info.scrollarea
				while parent_window and minGUI.gtree[parent_window]
					and minGUI.gtree[parent_window].tp ~= MG_WINDOW do
					parent_window = minGUI.gtree[parent_window].parent
				end
				if not parent_window or not minGUI.gtree[parent_window] then return end
				
				-- if there is already a context menu, delete it
				if CONTEXT_MENU and minGUI.gtree[CONTEXT_MENU] then
					minGUI:delete_gadget(CONTEXT_MENU)
				end
				
				-- show the context menu
				CONTEXT_MENU = minGUI:add_context_menu({"Run", "-", "Edit", "-", "Delete"}, parent_window)
				CONTEXT_MENU_INFO = {fileName = info.fileName, filePath = info.filePath, scrollarea = info.scrollarea}
				if CONTEXT_MENU then minGUI:show_context_menu(CONTEXT_MENU) end
			end
			end
		end
	end

	-- update GEMBASIC
	if GEMBASIC_running_prog then
		GEMBASIC_update()
	end
end

-- default love.draw function
function love.draw()
	-- draw the GUI or draw BASIC
	if not GEMBASIC_running_prog and not GEMBASIC_finished then
		-- draw created gadgets from minGUI
		minGUI_draw_all()
	else
		-- draw GEMBASIC game
		GEMBASIC_draw()
	end
end

--[[
function love.keypressed(key)
    if key == "f5" then
        love.graphics.captureScreenshot("capture.png")
    end
end
--]]