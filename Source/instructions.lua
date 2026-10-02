cursor_x = 1
cursor_y = 1

graphics_cursor_x = 0
graphics_cursor_y = 0

GEMBASIC_images = {}
GEMBASIC_musics = {}
GEMBASIC_sounds = {}

-- clear the screen
function GEMBASIC_CLS()
	cursor_x, cursor_y = 1, 1
	love.graphics.clear(GEMBASIC_paper_red, GEMBASIC_paper_green, GEMBASIC_paper_blue, 1)
end

-- draw a line
function GEMBASIC_DRAW(x, y)
	local start_x = graphics_cursor_x
	local start_y = graphics_cursor_y
	
	graphics_cursor_x = x
	graphics_cursor_y = y
	
	love.graphics.line(start_x + 0.5, start_y + 0.5, graphics_cursor_x + 0.5, graphics_cursor_y + 0.5)
	-- Line rasterization may omit the final pixel; include both endpoints.
	love.graphics.points(start_x + 0.5, start_y + 0.5, graphics_cursor_x + 0.5, graphics_cursor_y + 0.5)
end

-- draw a line relative
function GEMBASIC_DRAWR(x, y)
	local start_x = graphics_cursor_x
	local start_y = graphics_cursor_y
	
	graphics_cursor_x = graphics_cursor_x + x
	graphics_cursor_y = graphics_cursor_y + y
	
	love.graphics.line(start_x + 0.5, start_y + 0.5, graphics_cursor_x + 0.5, graphics_cursor_y + 0.5)
	-- Line rasterization may omit the final pixel; include both endpoints.
	love.graphics.points(start_x + 0.5, start_y + 0.5, graphics_cursor_x + 0.5, graphics_cursor_y + 0.5)
end

-- load an image
function GEMBASIC_LOADIMAGE(fileName, img_number)
	GEMBASIC_images[img_number] = love.graphics.newImage(fileName)
end

-- load a music
function GEMBASIC_LOADMUSIC(fileName, mus_number)
	GEMBASIC_musics[mus_number] = love.audio.newSource(fileName, "stream")

    -- loop the music
    GEMBASIC_musics[mus_number]:setLooping(true)
end

-- load a sound
function GEMBASIC_LOADSOUND(fileName, snd_number)
	GEMBASIC_sounds[snd_number] = love.audio.newSource(fileName, "static")
end

-- end the program
function GEMBASIC_END()
	GEMBASIC_running_prog = false
	GEMBASIC_finished = true
end

-- position the text cursor
function GEMBASIC_LOCATE(x, y)
	if type(x) ~= "number" or type(y) ~= "number" or x < 1 or y < 1
		or x ~= math.floor(x) or y ~= math.floor(y) then
		error("LOCATE expects positive integer column and row", 0)
	end
	cursor_x = x
	cursor_y = y
end

-- set text mode
function GEMBASIC_MODE(m)
	if m == 0 then
		love.graphics.setFont(GEMBASIC_font_mode_0)
	elseif m == 1 then
		love.graphics.setFont(GEMBASIC_font_mode_1)
	end
end

-- move graphics cursor
function GEMBASIC_MOVE(x, y)
	graphics_cursor_x = x
	graphics_cursor_y = y
end

-- move graphics cursor relative
function GEMBASIC_MOVER(x, y)
	graphics_cursor_x = graphics_cursor_x + x
	graphics_cursor_y = graphics_cursor_y + y
end

-- set pen color
function GEMBASIC_PEN(r, g, b)
	love.graphics.setColor(r / 255.0, g / 255.0, b / 255.0, 1)
end

-- draw a point
function GEMBASIC_PLOT(x, y)
	graphics_cursor_x = x
	graphics_cursor_y = y
	
	love.graphics.points(graphics_cursor_x + 0.5, graphics_cursor_y + 0.5)
end

-- draw a point relative
function GEMBASIC_PLOTR(x, y)
	graphics_cursor_x = graphics_cursor_x + x
	graphics_cursor_y = graphics_cursor_y + y
	
	love.graphics.points(graphics_cursor_x + 0.5, graphics_cursor_y + 0.5)
end

-- LOCATE uses one-based text cells. Optional PRINT coordinates remain in pixels.
function GEMBASIC_PRINT(txt, x, y)
	if x ~= nil and y ~= nil then
		love.graphics.print(txt, x, y)
		return
	end
	local font = love.graphics.getFont()
	love.graphics.print(txt, (cursor_x - 1) * font:getWidth("M"),
		(cursor_y - 1) * font:getHeight() * font:getLineHeight())
	local _, newlines = txt:gsub("\n", "")
	cursor_x, cursor_y = 1, cursor_y + newlines + 1
end
