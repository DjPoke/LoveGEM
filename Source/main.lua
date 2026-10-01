--==================
--     Löve GEM
--
--   Bruno Vignoli
--   MIT 2023-2024
--==================

-- require minGUI & other stuffs
require "minGUI.minGUI"
require "basic"
require "tools"
require "lexer"

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
	minGUI:add_menu(0, 0, 1280, 16, {
		{head_menu = "Desk", menu_list = {"Desktop infos..."}},
		{head_menu = "File", menu_list = {"Open", "Infos/Rename", "Search", "-", "New folder", "Close folder", "Close window", "Select all", "Selecte none", "-", "Delete", "-", "Quit"}},
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
	
	minGUI_gadget[1] = minGUI:add_image(32, 32, 128, 128, icon[1], nil, BASE_WINDOW)
	minGUI_gadget[2] = minGUI:add_image(192, 32, 128, 128, icon[2], nil, BASE_WINDOW)
	minGUI_gadget[3] = minGUI:add_image(352, 32, 128, 128, icon[3], nil, BASE_WINDOW)
	minGUI_gadget[4] = minGUI:add_image(512, 32, 128, 128, icon[4], nil, BASE_WINDOW)

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
    minGUI_textinput(t)
end

-- default love.update function
function love.update(dt)
	-- update events list for minGUI
	minGUI_update_events(dt)
	
	-- get new menu events
	local minGUI_eventMenu, minGUI_eventSubMenu = minGUI:get_menu_events()

	if minGUI_eventMenu == 1 then
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
	elseif minGUI_eventMenu == 2 then
		if minGUI_eventSubMenu == 13 then
			love.event.quit()
		end
	end
	
	-- get new gadget events
	local minGUI_eventGadget, minGUI_eventType = minGUI:get_gadget_events()
	
	-- eventGadget received ?
	if minGUI_eventGadget ~= nil then
		-- left click on a gadget ?
		if minGUI_eventType == MG_EVENT_LEFT_MOUSE_CLICK then
			if minGUI_eventGadget == DESKTOP_INFOS_WINDOW_OK then
				if DESKTOP_INFOS_WINDOW and minGUI.gtree[DESKTOP_INFOS_WINDOW] then
					minGUI:delete_gadget(DESKTOP_INFOS_WINDOW)
				end
				DESKTOP_INFOS_WINDOW, DESKTOP_INFOS_WINDOW_OK = nil, nil
			else
				local drives = {
					{gadget = minGUI_gadget[1], variable = "SWAP_DRIVE_WINDOW", title = "Swap Drive", x = 0, y = 192},
					{gadget = minGUI_gadget[2], variable = "WORK_DRIVE_WINDOW", title = "Work Drive", x = 64, y = 256},
					{gadget = minGUI_gadget[3], variable = "PLAY_DRIVE_WINDOW", title = "Play Drive", x = 128, y = 320},
					{gadget = minGUI_gadget[4], variable = "RELAX_DRIVE_WINDOW", title = "Relax Drive", x = 192, y = 384}
				}
				for _, drive in ipairs(drives) do
					if minGUI_eventGadget == drive.gadget then
						local window = _G[drive.variable]
						if not window or not minGUI.gtree[window] then
							window = minGUI:add_window(drive.x, drive.y, 640, 480, drive.title,
								bit.bor(MG_FLAG_WINDOW_TITLEBAR, MG_FLAG_WINDOW_BUTTONS), BASE_WINDOW)
							_G[drive.variable] = window
						end
						if window then minGUI:set_window_on_top(window) end
						break
					end
				end
			end
		end
	end
	
	-- load BASIC source code & execute it
	if not GEMBASIC_running_prog then
		--GEMBASIC_prog = GEMBASIC_load("Play/Oncle_B.prog/main.bas")
		--GEMBASIC_lexed_prog = lex(GEMBASIC_prog)
		--GEMBASIC_running_prog = true
		--[[
		for i = 1, #GEMBASIC_lexed_prog do
			if GEMBASIC_lexed_prog[i][1] ~= nil then
				print(GEMBASIC_lexed_prog[i][1].type)
				print(GEMBASIC_lexed_prog[i][1].data)
				print(GEMBASIC_lexed_prog[i][1].posFirst)
				print(GEMBASIC_lexed_prog[i][1].posLast)
			end
		end
		
		GEMBASIC_init()
		--]]
	else
		GEMBASIC_update()
	end
end

-- default love.draw function
function love.draw()
	-- draw the GUI or draw BASIC
	if not GEMBASIC_running_prog then
		-- draw created gadgets from minGUI
		minGUI_draw_all()
	else
		GEMBASIC_draw()
	end
end
