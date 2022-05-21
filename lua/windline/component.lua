---@class Component
---@field name string
---@field hl_colors table
---@field is_not_group boolean hl_colors only have {fg,bg} not a group {{fg,bg}}
---@field hl_data table a runtime table highlight group name
---@field text function
---@filed click function handle click even on component
---@field click_id number index of click function
---@field hl function
---@field created boolean
local Comp = {}
local utils = require('windline.utils')

--- remember the last highlight
local last_hl = ''
--- remember the last group ex:{'white','black'}
local last_group = {}

local render_text = function(text, highlight)
    if text == nil or text == '' then
        return ''
    end
    if highlight == '' or last_hl == highlight or highlight == nil then
        return text
    end
    last_hl = highlight
    return string.format('%%#%s#%s', highlight, text)
end

local render_click = function(text, click_id)
    if click_id then
        return string.format('%%%s@v:lua.WindLine.on_click@%s%%X', click_id, text)
    end
    return text
end

function Comp.create(params)
    local opt = {}
    if params.text == nil then
        local text = params[1]
        local hl, hl_colors
        if type(params[2]) == 'string' then
            hl = function()
                return params[2]
            end
        elseif type(params[2]) == 'table' then
            hl_colors = params[2]
        end
        if type(params[1]) == 'string' then
            text = function()
                return params[1]
            end
        end
        opt = {
            width = params[3],
            text = text,
            hl = hl,
            hl_colors = hl_colors,
        }
    else
        opt = params
    end

    if opt.text == nil then
        error(vim.inspect(opt))
        error('should have text on Windline component')
    end
    opt.created = true
    return setmetatable(opt, { __index = Comp })
end

function Comp:make_hl(hl)
    if hl == nil then
        return ''
    end
    if type(hl) == 'string' then
        if hl == '' then
            return ''
        end
        last_group = self.is_not_group and self.hl_colors
            or self.hl_colors and self.hl_colors[hl]
            or last_group
        return self.hl_data[hl] or hl
    end
    if type(hl) == 'table' then
        last_group = {
            hl[1] and hl[1] ~= '' and hl[1] or last_group[1],
            hl[2] and hl[2] ~= '' and hl[2] or last_group[2],
            hl[3],
        }
        return utils.hl(last_group, nil, true)
    end
    if type(hl) == 'function' then
        return self:make_hl(hl(self.hl_data))
    end
end

function Comp:setup_hl(colors)
    local hl_data = {}
    local hl_colors = self.hl_colors
    if hl_colors then
        if type(hl_colors[1]) == 'string' or type(hl_colors[2]) == 'string' then
            hl_colors[1] = hl_colors[1] or last_group[1]
            hl_colors[2] = hl_colors[2] or last_group[2]
            last_group = { hl_colors[1], hl_colors[2] }
            self.is_not_group = true
            self.hl_data = utils.hl(hl_colors, colors, false)
            self.hl = self.hl_data
            return
        end
        for key, value in pairs(hl_colors) do
            if type(value) == 'table' then
                hl_data[key] = utils.hl(value, colors, false)
            else
                hl_data[key] = value
            end
        end
    end
    self.hl_data = hl_data
end

function Comp:render(bufnr, winid, width)
    self.bufnr = bufnr
    local hl_data = self.hl_data or {}
    local childs = self.text(bufnr, winid, width)
    if type(childs) == 'table' then
        local result = ''
        for _, child in pairs(childs) do
            local text, hl = child[1], child[2]
            if type(text) == 'function' then
                text = child[1](bufnr, winid, width)
            end
            if type(hl) == 'string' then
                hl = hl_data[hl] or hl
            end
            result = result
                .. render_click(render_text(text, self:make_hl(hl)), child[3])
        end
        return render_click(result, self.click)
    end
    return render_click(render_text(childs, self:make_hl(self.hl)), self.click)
end

return {
    create = Comp.create,
    reset = function()
        last_hl = ''
        last_group = {}
    end,
}
