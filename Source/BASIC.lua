-- BASIC programs run one instruction per update, keeping the application responsive.
function GEMBASIC_load(filename)
    return love.filesystem.read(filename)
end

local function truth(value)
    return value ~= false and value ~= nil and value ~= 0
end

local builtins = {
    abs=math.abs, atn=math.atan, cos=math.cos, sin=math.sin, tan=math.tan,
    sign=function(x) return x < 0 and -1 or x > 0 and 1 or 0 end,
    atn2=function(y,x) return math.atan2 and math.atan2(y,x) or math.atan(y,x) end,
    asc=string.byte, chr=string.char, str=tostring,
    space=function(n) return string.rep(' ', n) end,
    string=function(n,s) return string.rep(type(s)=='number' and string.char(s) or s,n) end
}
local function evaluate(node, state)
    if node.kind=='number' or node.kind=='string' or node.kind=='boolean' then return node.value end
    if node.kind=='variable' then
        local value=state.variables[node.name]
        if value==nil then error('Undefined variable: '..node.name,0) end
        return value
    end
    if node.kind=='call' then
        local fn=builtins[node.name]
        if not fn then error('Unknown function: '..node.name,0) end
        local args={};for i,arg in ipairs(node.arguments) do args[i]=evaluate(arg,state) end
        return fn((unpack or table.unpack)(args))
    end
    if node.kind=='unary' then
        local value=evaluate(node.operand,state)
        if node.operator=='not' then return not truth(value) end
        return node.operator=='-' and -value or value+0
    end
    if node.kind=='binary' then
        local op=node.operator
        local a=evaluate(node.left,state)
        if op=='and' and not truth(a) then return false end
        if op=='or' and truth(a) then return true end
        local b=evaluate(node.right,state)
        if op=='+' then return a+b elseif op=='-' then return a-b
        elseif op=='*' then return a*b elseif op=='/' or op=='mod' then
            if b==0 then error('Division by zero',0) end
            if op=='/' then return a/b else return a%b end
        elseif op=='pow' then return a^b
        elseif op=='=' or op=='==' then return a==b
        elseif op=='~=' or op=='<>' then return a~=b
        elseif op=='<' then return a<b elseif op=='>' then return a>b
        elseif op=='<=' then return a<=b elseif op=='>=' then return a>=b
        elseif op=='and' then return truth(a) and truth(b)
        elseif op=='or' then return truth(a) or truth(b)
        elseif op=='xor' then return truth(a)~=truth(b) end
    end
    error('Unsupported expression: '..tostring(node.kind),0)
end

local function compile(ast)
    local code, labels, loopID = {}, {}, 0
    local function emit(op,node,fields)
        local item=fields or {};item.op,item.node=op,node;code[#code+1]=item;return item
    end
    local block
    local function statement(node, breaks)
        local kind=node.kind
        if kind=='line' or kind=='label' then
            local key=kind=='line' and node.number or node.name
            if labels[key] then error('Duplicate label: '..tostring(key),0) end
            labels[key]=#code+1
            if node.statement then statement(node.statement,breaks) end
        elseif kind=='comment' then
            emit('noop',node)
        elseif kind=='if' then
            local exits={}
            for _,branch in ipairs(node.branches) do
                local test=emit('test',node,{condition=branch.condition})
                block(branch.body,breaks)
                exits[#exits+1]=emit('jump',node)
                test.target=#code+1
            end
            if node.otherwise then block(node.otherwise,breaks) end
            for _,exit in ipairs(exits) do exit.target=#code+1 end
        elseif kind=='while' or kind=='repeat' or kind=='for' then
            local localBreaks={}
            local start=#code+1
            local test,setup
            if kind=='while' then test=emit('test',node,{condition=node.condition})
            elseif kind=='for' then
                loopID=loopID+1
                setup=emit('for_init',node,{id=loopID});start=#code+1
                test=emit('for_test',node,{id=loopID})
            end
            block(node.body,localBreaks)
            if kind=='repeat' then emit('test',node,{condition=node.condition,target=start})
            else
                if kind=='for' then emit('for_next',node,{id=setup.id}) end
                emit('jump',node,{target=start})
            end
            local finish=#code+1
            if test then test.target=finish end
            for _,exit in ipairs(localBreaks) do exit.target=finish end
        elseif kind=='break' then
            if not breaks then error('BREAK outside a loop at line '..node.line,0) end
            breaks[#breaks+1]=emit('jump',node)
        else emit(kind,node) end
    end
    block=function(body,breaks) for _,node in ipairs(body) do statement(node,breaks) end end
    block(ast.body)
    for _,item in ipairs(code) do
        if item.op=='goto' or item.op=='gosub' then
            item.target=labels[item.node.target]
            if not item.target then error('Unknown jump target: '..tostring(item.node.target),0) end
        end
    end
    return code
end

local function command(node,state)
    local args={};for i,arg in ipairs(node.arguments) do args[i]=evaluate(arg,state) end
    local function count(n)
        if #args~=n then error(node.name..' expects '..n..' arguments',0) end
    end
    if node.name=='cls' then count(0);GEMBASIC_CLS()
    elseif node.name=='locate' then count(2);GEMBASIC_LOCATE(args[1],args[2])
    elseif node.name=='draw' then count(2);GEMBASIC_DRAW(args[1],args[2])
    elseif node.name=='drawr' then count(2);GEMBASIC_DRAWR(args[1],args[2])
    elseif node.name=='move' then count(2);GEMBASIC_MOVE(args[1],args[2])
    elseif node.name=='mover' then count(2);GEMBASIC_MOVER(args[1],args[2])
    elseif node.name=='plot' then count(2);GEMBASIC_PLOT(args[1],args[2])
    elseif node.name=='plotr' then count(2);GEMBASIC_PLOTR(args[1],args[2])
    elseif node.name=='loadimage' then count(2);GEMBASIC_LOADIMAGE(args[1],args[2])
    elseif node.name=='loadmusic' then count(2);GEMBASIC_LOADMUSIC(args[1],args[2])
    elseif node.name=='loadsound' then count(2);GEMBASIC_LOADSOUND(args[1],args[2])
    elseif node.name=='mode' then
        count(1);if args[1]~=0 and args[1]~=1 then error('MODE must be 0 or 1',0) end
        state.mode=args[1];GEMBASIC_MODE(state.mode)
    elseif node.name=='pen' then
        count(3);state.pen={args[1],args[2],args[3]};GEMBASIC_PEN((unpack or table.unpack)(state.pen))
    elseif node.name=='print' then
        if #args==3 and type(args[2])=='number' and type(args[3])=='number' then
            GEMBASIC_PRINT(tostring(args[1]),args[2],args[3])
        else
            local parts={}
            for i,value in ipairs(args) do
                parts[#parts+1]=tostring(value)
                if node.separators[i]==',' then parts[#parts+1]='\t' end
            end
            GEMBASIC_PRINT(table.concat(parts))
        end
    elseif node.name=='waitkey' or node.name=='waitmouse' then
        count(0);state.waiting={kind=node.name,armed=false}
    else error('Unsupported command: '..node.name,0) end
end

function GEMBASIC_init(ast)
    GEMBASIC_running_prog=false
    GEMBASIC_finished=false
    if not ast or ast.kind~='program' then return nil,'Expected parsed BASIC program' end
    local ok,code=pcall(compile,ast)
    if not ok then return nil,code end
    graphics_cursor_x, graphics_cursor_y=0,0
    GEMBASIC_state={code=code,pc=1,variables={},loops={},returns={},mode=1,pen={255,255,255}}
    love.graphics.push('all')
    love.graphics.origin()
    love.graphics.setCanvas(GEMBASIC_canvas)
    GEMBASIC_CLS()
    love.graphics.pop()
    GEMBASIC_running_prog=true
    return true
end

local function step(state)
    local item=state.code[state.pc]
    if not item then GEMBASIC_END();return end
    state.line=item.node.line
    state.pc=state.pc+1
    local node,op=item.node,item.op
    if op=='assign' then state.variables[node.name]=evaluate(node.value,state)
    elseif op=='command' then command(node,state)
    elseif op=='test' then if not truth(evaluate(item.condition,state)) then state.pc=item.target end
    elseif op=='jump' or op=='goto' then state.pc=item.target
    elseif op=='gosub' then state.returns[#state.returns+1]=state.pc;state.pc=item.target
    elseif op=='return' then
        if #state.returns==0 then error('RETURN without GOSUB',0) end
        state.pc=table.remove(state.returns)
    elseif op=='for_init' then
        local first=evaluate(node.start,state)
        local finish=evaluate(node.finish,state)
        local increment=node.step and evaluate(node.step,state) or 1
        if type(first)~='number' or type(finish)~='number' or type(increment)~='number' or increment==0 then error('Invalid FOR bounds or STEP',0) end
        state.variables[node.variable]=first;state.loops[item.id]={finish=finish,step=increment}
    elseif op=='for_test' then
        local loop=state.loops[item.id];local value=state.variables[node.variable]
        if loop.step>0 and value>loop.finish or loop.step<0 and value<loop.finish then state.pc=item.target end
    elseif op=='for_next' then state.variables[node.variable]=state.variables[node.variable]+state.loops[item.id].step
    elseif op=='end' then GEMBASIC_END()
    elseif op~='noop' then error('Unsupported instruction: '..op,0) end
end

function GEMBASIC_update()
    local state=GEMBASIC_state
    if not GEMBASIC_running_prog or not state then return end
    if state.waiting then
        if state.waiting.kind=='waitmouse' then
            local down=love.mouse.isDown(1,2,3)
            if not down then state.waiting.armed=true end
            if down and state.waiting.armed then state.waiting=nil end
        end
        return
    end
    love.graphics.push('all')
    love.graphics.origin()
    love.graphics.setCanvas(GEMBASIC_canvas)
    love.graphics.setScissor()
    love.graphics.setLineStyle('rough')
    love.graphics.setLineWidth(1)
    love.graphics.setPointSize(1)
    GEMBASIC_MODE(state.mode)
    GEMBASIC_PEN((unpack or table.unpack)(state.pen))
    local ok,err=pcall(step,state)
    love.graphics.pop()
    if not ok then
        GEMBASIC_running_prog=false
        state.error={line=state.line,message=tostring(err)}
        love.window.showMessageBox('BASIC error','Line '..tostring(state.line)..': '..tostring(err),'error')
    end
end

function GEMBASIC_dismiss()
    if not GEMBASIC_finished then return false end
    GEMBASIC_finished=false
    GEMBASIC_returningToGUI=true
    return true
end

function GEMBASIC_keypressed()
    if GEMBASIC_dismiss() then return end
    local state=GEMBASIC_state
    if GEMBASIC_running_prog and state and state.waiting and state.waiting.kind=='waitkey' then
        state.waiting=nil
    end
end

function GEMBASIC_draw()
    love.graphics.push('all')
    love.graphics.origin()
    love.graphics.setCanvas()
    love.graphics.setScissor()
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(GEMBASIC_canvas,0,0,0,4,4)
    love.graphics.pop()
end
