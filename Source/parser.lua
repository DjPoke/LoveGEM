-- Simple BASIC syntax parser. No execution or evaluation is performed here.
-- parse(source or lex(source)) -> {kind='program', body={...}}, or nil, error.
-- Every node carries line/column. Identifiers and keywords are case insensitive.
local Parser = {}
local precedence = {['or']=1, xor=2, ['and']=3, ['=']=4, ['==']=4,
    ['~=']=4, ['<>']=4, ['<']=4, ['>']=4, ['<=']=4, ['>=']=4,
    ['+']=5, ['-']=5, ['*']=6, ['/']=6, mod=6, pow=8}
local commands = {cls=true, locate=true, mode=true, pen=true, print=true, waitkey=true, waitmouse=true}
local mediaAndGraphicsCommands = {
    draw=2, drawr=2, move=2, mover=2, plot=2, plotr=2,
    loadimage=2, loadsprite=4, loadmusic=2, loadsound=2,
    drawimage=3, drawsprite={4,9}, playmusic=1, stopmusic=1, loopmusic=2,
    playsound=1, stopsound=1
}
for name in pairs(mediaAndGraphicsCommands) do commands[name]=true end
local functions = {abs=true, atn=true, atn2=true, cos=true, sign=true, sin=true,
    tan=true, asc=true, chr=true, str=true, space=true, string=true}

local function normalize(lines)
    local out = {}
    for line, tokens in ipairs(lines) do
        for _, token in ipairs(tokens) do
            local tp, data = token.type, token.data
            if tp == 'comment' then break end
            if tp ~= 'whitespace' and tp ~= 'newline' then
                if tp == 'symbol' or tp == 'operator' then
                    local i = 1
                    while i <= #data do
                        local pair = data:sub(i, i + 1)
                        local size = (pair == '<=' or pair == '>=' or pair == '~=' or pair == '<>' or pair == '==') and 2 or 1
                        out[#out+1] = {type=tp, data=data:sub(i,i+size-1), line=line,
                            column=(token.posFirst or 1)+i-1}
                        i = i + size
                    end
                else
                    out[#out+1] = {type=tp, data=data, line=line, column=token.posFirst or 1}
                end
            end
        end
        out[#out+1] = {type='eol', data='\n', line=line, column=1}
    end
    out[#out+1] = {type='eof', data='', line=#lines+1, column=1}
    return out
end

local function reader(tokens)
    local p = {tokens=tokens, index=1}
    function p:peek() return self.tokens[self.index] end
    function p:word() return self:peek().data:lower() end
    function p:take() local t=self:peek(); self.index=self.index+1; return t end
    function p:fail(message, token)
        local t = token or self:peek()
        error({message=message, line=t.line, column=t.column}, 0)
    end
    function p:accept(word)
        if self:word()==word then return self:take() end
    end
    function p:expect(word)
        return self:accept(word) or self:fail("Expected '"..word.."'")
    end
    function p:node(kind, t, fields)
        fields=fields or {}; fields.kind=kind; fields.line=t.line; fields.column=t.column
        return fields
    end
    function p:boundary()
        return self:peek().type=='eol' or self:peek().type=='eof' or self:word()==':' or self:word()=='else'
    end
    function p:expression(minimum)
        minimum=minimum or 1
        local t, left = self:take()
        local word=t.data:lower()
        if t.type=='number' then
            local value=tonumber(t.data)
            if not value then self:fail('Invalid number',t) end
            left=self:node('number',t,{value=value})
        elseif t.type=='value' then
            left=self:node('boolean',t,{value=word=='true' or word=='on'})
        elseif t.type=='string_start' then
            if t.data~='"' then self:fail('Long strings are not supported',t) end
            local parts={}
            while self:peek().type=='string' or self:peek().type=='escape' do
                local part=self:take()
                if part.type=='string' then parts[#parts+1]=part.data
                else
                    local escapes={a='\a',b='\b',f='\f',n='\n',r='\r',t='\t',v='\v'}
                    local index=1
                    while index<=#part.data do
                        if part.data:sub(index,index)~='\\' then self:fail('Invalid escape',part) end
                        index=index+1
                        local code=part.data:sub(index,index)
                        local digits=part.data:sub(index):match('^%d%d?%d?')
                        local value
                        if digits then value=tonumber(digits);index=index+#digits
                        elseif code=='x' then
                            value=tonumber(part.data:sub(index+1,index+2),16)
                            if not value then self:fail('Invalid hexadecimal escape',part) end
                            index=index+3
                        else index=index+1 end
                        if value and value>255 then self:fail('Escape exceeds byte range',part) end
                        parts[#parts+1]=value and string.char(value) or escapes[code] or code
                    end
                end
            end
            local closing=self:peek()
            if closing.type~='string_end' or closing.data~='"' then self:fail('Unterminated string',t) end
            self:take();left=self:node('string',t,{value=table.concat(parts)})
        elseif word=='-' or word=='+' or word=='not' then
            left=self:node('unary',t,{operator=word,operand=self:expression(word=='not' and 4 or 7)})
        elseif word=='(' then
            left=self:expression();self:expect(')')
        elseif t.type=='ident' or functions[word] then
            if self:accept('(') then
                local args={}
                if not self:accept(')') then
                    repeat args[#args+1]=self:expression() until not self:accept(',')
                    self:expect(')')
                end
                left=self:node('call',t,{name=word,arguments=args})
            else left=self:node('variable',t,{name=word}) end
        else self:fail('Expected expression',t) end
        while precedence[self:word()] and precedence[self:word()]>=minimum do
            local op=self:take();local priority=precedence[op.data:lower()]
            local right=self:expression(priority+(op.data:lower()=='pow' and 0 or 1))
            left=self:node('binary',op,{operator=op.data:lower(),left=left,right=right})
        end
        return left
    end
    function p:block(stops)
        local body={}
        while self:peek().type~='eof' do
            if self:peek().type=='eol' or self:word()==':' then self:take()
            elseif stops and stops[self:word()] then break
            else
                body[#body+1]=self:statement()
                if not self:boundary() then self:fail('Expected end of statement') end
            end
        end
        return body
    end
    function p:statement()
        local t=self:peek();local word=self:word()
        if word=='rem' then
            repeat self:take() until self:peek().type=='eol' or self:peek().type=='eof'
            return self:node('comment',t)
        elseif t.type=='number' then
            self:take()
            if not t.data:match('^%d+$') then self:fail('Expected integer line number',t) end
            return self:node('line',t,{number=tonumber(t.data),statement=self:boundary() and nil or self:statement()})
        elseif t.type=='label_start' then
            self:take();local name=self:take()
            if name.type~='label' then self:fail('Expected label name',name) end
            if self:peek().type~='label_end' then self:fail('Expected closing label marker') end
            self:take();return self:node('label',t,{name=name.data:lower()})
        elseif word=='if' then
            self:take();local condition=self:expression();self:expect('then')
            local branches={}
            if self:peek().type~='eol' then
                branches[1]={condition=condition,body={self:statement()}}
                local otherwise
                if self:accept('else') then otherwise={self:statement()} end
                return self:node('if',t,{branches=branches,otherwise=otherwise})
            end
            self:take();branches[1]={condition=condition,body=self:block({['else']=true,['elseif']=true,endif=true})}
            while self:accept('elseif') do
                local test=self:expression();self:expect('then')
                if self:peek().type~='eol' then self:fail('Expected newline after THEN') end
                self:take();branches[#branches+1]={condition=test,body=self:block({['else']=true,['elseif']=true,endif=true})}
            end
            local otherwise
            if self:accept('else') then
                if self:peek().type~='eol' then self:fail('Expected newline after ELSE') end
                self:take();otherwise=self:block({endif=true})
            end
            self:expect('endif');return self:node('if',t,{branches=branches,otherwise=otherwise})
        elseif word=='while' or word=='repeat' or word=='for' then
            self:take();local fields={}
            if word=='while' then fields.condition=self:expression()
            elseif word=='for' then
                local name=self:take();if name.type~='ident' then self:fail('Expected loop variable',name) end
                fields.variable=name.data:lower();self:expect('=');fields.start=self:expression();self:expect('to');fields.finish=self:expression()
                if self:accept('step') then fields.step=self:expression() end
            end
            if self:peek().type~='eol' then self:fail('Expected newline before loop body') end
            self:take();local ending=word=='while' and 'wend' or word=='for' and 'next' or 'until'
            fields.body=self:block({[ending]=true});self:expect(ending)
            if word=='repeat' then fields.condition=self:expression()
            elseif word=='for' and self:peek().type=='ident' then
                local name=self:take();if name.data:lower()~=fields.variable then self:fail('NEXT variable does not match FOR',name) end
            end
            return self:node(word,t,fields)
        elseif word=='end' or word=='break' or word=='return' then
            self:take();return self:node(word,t)
        elseif word=='goto' or word=='gosub' then
            self:take();local target=self:take()
            if target.type~='ident' and not (target.type=='number' and target.data:match('^%d+$')) then self:fail('Expected label or line number',target) end
            return self:node(word,t,{target=target.type=='number' and tonumber(target.data) or target.data:lower()})
        elseif commands[word] then
            self:take();local args,separators={},{}
            if not self:boundary() then
                args[1]=self:expression()
                while self:word()==',' or (word=='print' and self:word()==';') do
                    separators[#separators+1]=self:take().data
                    if self:boundary() then break end
                    args[#args+1]=self:expression()
                end
            end
            local arity=mediaAndGraphicsCommands[word]
            if arity then
                local minimum = type(arity)=='table' and arity[1] or arity
                local maximum = type(arity)=='table' and arity[2] or arity
                if #args<minimum or #args>maximum or #separators~=#args-1 then
                    local expected = minimum==maximum and tostring(minimum) or (minimum..' to '..maximum)
                    self:fail(word:upper()..' expects '..expected..' comma-separated arguments',t)
                end
            end
            return self:node('command',t,{name=word,arguments=args,separators=separators})
        elseif t.type=='ident' then
            self:take();self:expect('=')
            return self:node('assign',t,{name=word,value=self:expression()})
        end
        self:fail('Unsupported statement: '..t.data,t)
    end
    return p
end

function Parser.parse(input)
    if type(input)=='string' then
        if not lex then require('lexer') end
        input=lex(input)
    end
    if type(input)~='table' then return nil,{message='Expected source text or lexer tokens',line=1,column=1} end
    local ok, result=pcall(function()
        local p=reader(normalize(input))
        return {kind='program',body=p:block()}
    end)
    if ok then return result end
    if type(result)=='table' then return nil,result end
    return nil,{message=tostring(result),line=1,column=1}
end

-- Match lex()'s global API while also supporting require('parser').parse().
parse = Parser.parse
return Parser
