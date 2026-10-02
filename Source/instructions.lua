cursor_x = 1
cursor_y = 1

graphics_cursor_x = 0
graphics_cursor_y = 0

GEMBASIC_images = {}
GEMBASIC_sprites = {}
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

function GEMBASIC_DRAWIMAGE(img_number, x, y)
	love.graphics.draw(GEMBASIC_images[img_number], x, y)
end

function GEMBASIC_DRAWSPRITE(spr_number, img_number, x, y, r, sx, sy, ox, oy)
    local sprite = GEMBASIC_sprites[spr_number]
    if not sprite then error("DRAWSPRITE: sprite not loaded", 0) end
    if type(img_number) ~= "number" or img_number ~= math.floor(img_number)
        or not sprite[img_number] then
        error("DRAWSPRITE: invalid frame number (frames start at 1)", 0)
    end
    love.graphics.draw(sprite.image, sprite[img_number], x, y,
        r or 0, sx or 1, sy or sx or 1, ox or 0, oy or 0)
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
end

-- load a sound
function GEMBASIC_LOADSOUND(fileName, snd_number)
	GEMBASIC_sounds[snd_number] = love.audio.newSource(fileName, "static")
end

-- load spritesheet image to a sprite (list of images)
function GEMBASIC_LOADSPRITE(fileName, spr_number, frame_width, frame_height)
    local function integer(value, minimum)
        return type(value) == "number" and value >= minimum
            and value < math.huge and value == math.floor(value)
    end
    if type(fileName) ~= "string" or fileName == "" then
        error("LOADSPRITE expects an image path", 0)
    end
    if not integer(spr_number, 0) then
        error("LOADSPRITE expects a non-negative integer sprite number", 0)
    end
    if not integer(frame_width, 1) or not integer(frame_height, 1) then
        error("LOADSPRITE expects positive integer frame dimensions", 0)
    end
    local image = love.graphics.newImage(fileName)
    local width, height = image:getDimensions()
    if width % frame_width ~= 0 or height % frame_height ~= 0 then
        error("LOADSPRITE frame dimensions must divide the image dimensions", 0)
    end
    -- Retain the image alongside the numbered quads, in row-major order.
    local sprite = {image = image, frameWidth = frame_width, frameHeight = frame_height}
    for y = 0, height - frame_height, frame_height do
        for x = 0, width - frame_width, frame_width do
            sprite[#sprite + 1] = love.graphics.newQuad(x, y, frame_width, frame_height, width, height)
        end
    end
    GEMBASIC_sprites[spr_number] = sprite
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

-- set the current music to loop or not
function GEMBASIC_LOOPMUSIC(mus_number, bool_value)
	-- loop the music
    if type(bool_value) == "number" then bool_value = bool_value ~= 0 end
    if type(bool_value) ~= "boolean" then error("LOOPMUSIC expects a boolean or number", 0) end
    GEMBASIC_musics[mus_number]:setLooping(bool_value)
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

-- play a music
function GEMBASIC_PLAYMUSIC(mus_number)
	GEMBASIC_musics[mus_number]:play()
end

-- play a sound
function GEMBASIC_PLAYSOUND(snd_number)
	GEMBASIC_sounds[snd_number]:play()
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

-- stop a music
function GEMBASIC_STOPMUSIC(mus_number)
	GEMBASIC_musics[mus_number]:stop()
end

-- stop a sound
function GEMBASIC_STOPSOUND(snd_number)
	GEMBASIC_sounds[snd_number]:stop()
end
