cursor_x = 1
cursor_y = 1

-- clear the screen
function GEMBASIC_CLS()
	cursor_x, cursor_y = 1, 1
	love.graphics.clear(GEMBASIC_paper_red, GEMBASIC_paper_green, GEMBASIC_paper_blue, 1)
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

-- set pen color
function GEMBASIC_PEN(r, g, b)
	love.graphics.setColor(r / 255.0, g / 255.0, b / 255.0)
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
