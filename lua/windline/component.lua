---@class Component
---@field hl_colors table
---@field text function
---@field hl function
---@field created boolean
local Comp = {}
local utils=require('windline.utils')

local last_hl = ''
local render_text = function (text, highlight)
    if text == nil or text == "" then return "" end
    if highlight == '' or last_hl == highlight or highlight == nil then return text end
    last_hl = highlight
    return string.format('%%#%s#%s', highlight, text)
end

function Comp.create(params)
    local opt = {}
    if params.text == nil then
        local text = params[1]
        local hl, hl_colors
        if type(params[2]) == "string" then
            hl = function() return params[2] end
        elseif type(params[2]) == 'table' then
            hl_colors = params[2]
        end
        if type(params[1]) == 'string' then
            text = function () return params[1] end
        end
        opt = {
            width = params[3],
            text = text,
            hl = hl,
            hl_colors = hl_colors
        }
    else
        opt = params
    end

    if opt.text == nil then
        error(vim.inspect(opt))
        error("should have text on Windline component")
    end
    if opt.hl_colors and not opt.hl then
        opt.hl = function(c) return c end
    end
    opt.created = true
    return setmetatable(opt, {__index = Comp})
end

function Comp:make_hl(hl, default)
    local highlight = hl
    if type(hl) == 'function' then highlight = hl(self.hl_data) end
    if hl == nil then return default or '' end
    return highlight
end


function Comp:setup_hl(colors)
    local hl_data = {}
    local hl_colors = self.hl_colors
    local create_hl = function (c1, c2, style)
        local fg = colors[c1]
        local bg = colors[c2]
        assert(fg ~= nil, c1 .. ' color is not defined ')
        assert(bg ~= nil, c2 .. ' color is not defined ')
        return utils.hl(fg, bg, style, string.format('WL%s_%s', c1, c2))
    end

    if hl_colors then
        if type(hl_colors[1]) == 'string' and type(hl_colors[2]) == "string" then
            self.hl_data = create_hl(unpack(hl_colors))
            return
        end
        for key, value in pairs(hl_colors) do
            if type(value) == 'table' then
                hl_data[key] = create_hl(unpack(value))
            else
                hl_data[key] = value
            end
        end
    end
    self.hl_data = hl_data
end


function Comp:render(bufnr, winnr)
    self.bufnr = bufnr
    local hl_data = self.hl_data or {}
    local childs = self.text(self.bufnr, winnr)
    if type(childs) == 'table'then
        local result = ''
        for _,child in pairs(childs) do
            local text,hl = child[1],child[2]
            if type(text) == 'function' then
                text = child[1](bufnr, winnr)
            end
            if type(hl) == 'string' then
                hl = hl_data[hl] or hl
            end
            result = result .. render_text(
               text, self:make_hl(hl, hl_data.default)
            )
        end
        return result
    end
    return render_text(childs, self:make_hl(self.hl, hl_data.default))
end

return { create = Comp.create, reset = function () last_hl = '' end}
