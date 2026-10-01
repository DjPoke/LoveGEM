-- clear the screen
function GEMBASIC_CLS()
	love.graphics.clear(GEMBASIC_paper_red, GEMBASIC_paper_green, GEMBASIC_paper_blue, 1)
end

-- set pen color
function GEMBASIC_PEN(r, g, b)
	love.graphics.setColor(r / 255.0, g / 255.0, b / 255.0)
end

-- set text mode
function GEMBASIC_MODE(m)
	if m == 0 then
		love.graphics.setFont(GEMBASIC_font_mode_0)
	elseif m == 1 then
		love.graphics.setFont(GEMBASIC_font_mode_1)
	end
end

-- print a text at coordinates
function GEMBASIC_PRINT(txt, x, y)
	love.graphics.print(txt, x, y)
end
