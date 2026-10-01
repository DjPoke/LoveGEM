-- load a BASIC script in memory
function GEMBASIC_load(filename)
	return love.filesystem.read(filename)
end

-- update function interpreter
function GEMBASIC_init()
	--GEMBASIC_END()
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
