require('lexer');require('parser');require('instructions');require('BASIC');assert(loadfile('main.lua'))
local output,errors,clears={}, {}, 0
love={graphics={},window={showMessageBox=function(_,message)errors[#errors+1]=message end},mouse={isDown=function()return false end}}
for _,name in ipairs({'push','pop','setCanvas','setScissor','setFont','setColor','draw'}) do love.graphics[name]=function()end end
love.graphics.clear=function()clears=clears+1 end
love.graphics.print=function(text,x,y)output[#output+1]={text,x,y}end
love.graphics.getFont=function()return {getHeight=function()return 8 end,getWidth=function()return 8 end,getLineHeight=function()return 1 end}end
GEMBASIC_canvas={};GEMBASIC_paper_red=0;GEMBASIC_paper_green=0;GEMBASIC_paper_blue=0
local function run(source)
 local ast,err=parse(source);assert(ast,err and err.message)
 local ok,err=GEMBASIC_init(ast);assert(ok,err)
 local n=0;while GEMBASIC_running_prog and n<1000 do GEMBASIC_update();n=n+1 end
 assert(n<1000,'Interpreter did not finish');return GEMBASIC_state
end
local state=run('x=0\nfor i=1 to 3\nx=x+i\nnext i\nif x=6 then\nprint "OK", 10, 20\nelse\nprint "BAD"\nendif\nend')
assert(state.variables.x==6 and output[1][1]=='OK' and output[1][2]==10 and output[1][3]==20)
state=run('x=0\nwhile x<3\nx=x+1\nwend\nrepeat\nx=x-1\nuntil x=0\nfor i=3 to 1 step -1\nx=x+i\nnext\nend');assert(state.variables.x==6)
state=run('x=0\n10 gosub sub\nend\n::sub::\nx=x+2\nreturn');assert(state.variables.x==2)
state=run('for i=1 to 9\nbreak\nnext i\nend');assert(state.variables.i==1)
state=run('x=abs(-2)+sin(0)\ny=not 0\nend');assert(state.variables.x==2 and state.variables.y==true)
local ast=parse('goto missing');local ok,err=GEMBASIC_init(ast);assert(not ok and err:find('Unknown jump target'))
state=run('x=1/0');assert(state.error.line==1 and #errors==1)
local ast=parse('x=1\nx=2\nend');assert(GEMBASIC_init(ast));assert(GEMBASIC_state.variables.x==nil);GEMBASIC_update();assert(GEMBASIC_state.variables.x==1);GEMBASIC_update();assert(GEMBASIC_state.variables.x==2)
local count=clears;GEMBASIC_draw();GEMBASIC_draw();assert(clears==count)
assert(GEMBASIC_init(parse('waitkey\nx=5\nend')));GEMBASIC_update();GEMBASIC_update();assert(GEMBASIC_state.variables.x==nil);GEMBASIC_keypressed();GEMBASIC_update();assert(GEMBASIC_state.variables.x==5)
print('Passed: execution only in updates, expressions, loops, conditions, jumps, errors, WAITKEY and persistent canvas.')

state=run('locate 5, 3\nprint "Located"\nprint "Next"\nend')
assert(output[#output-1][2]==32 and output[#output-1][3]==16)
assert(output[#output][2]==0 and output[#output][3]==24)
state=run('locate 2, 4\ncls\nprint "Reset"\nend')
assert(output[#output][2]==0 and output[#output][3]==0)
for _,src in ipairs({'locate 0, 1','locate 1.5, 2','locate "x", 2','locate 1'}) do
 state=run(src);assert(state.error and state.error.line==1)
end
print('Passed: LOCATE cell coordinates, PRINT advances, CLS resets and invalid arguments fail.')
