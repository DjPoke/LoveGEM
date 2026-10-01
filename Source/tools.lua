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
	GEMBASIC_PEN(1, 1, 0)
	GEMBASIC_PRINT("Hello, World!", 0, 0)
	
	-- draw GEMBASIC canvas
	love.graphics.setCanvas()
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(GEMBASIC_canvas, 0, 0, 0, 4, 4)
end
