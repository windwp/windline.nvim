local base_component = require('windline.component')
local get_hl_color = require('windline.themes').get_hl_color

---@class tmux_component
local tmux_component = {}
local state = WindLine.state

local last_hl = {}

local render_text = function(text, highlight)
    if text == nil or text == '' then
        return ''
    end
    if not highlight or highlight == '' or (highlight[1] == last_hl[1] and highlight[2] == last_hl[2]) then
        return text
    end
    last_hl = highlight
    return string.format('#[fg=%s,bg=%s]%s', highlight[1], highlight[2], text)
end

function tmux_component:make_hl(hl)
    local colors = state.colors
    if type(hl) == 'table' then
        if colors[hl[1]] or colors[hl[2]] then
            return { colors[hl[1]], colors[hl[2]] }
        end
    else
        if colors[hl] then return colors[hl] end
        local fg, bg = get_hl_color(hl)
        if fg and bg then return { fg, bg } end
    end
    return hl
end

function tmux_component:setup_hl(colors)
    local hl_data = {}
    local hl_colors = self.hl_colors
    if hl_colors then
        if type(hl_colors[1]) == 'string' or type(hl_colors[2]) == 'string' then
            self.hl_data = { colors[hl_colors[1]], colors[hl_colors[2]] }
            self.hl = self.hl_data
            return
        end
        for key, value in pairs(hl_colors) do
            if type(value) == 'table' then
                hl_data[key] = { colors[value[1]], colors[value[2]] }
            else
                local fg, bg = get_hl_color(value)
                hl_data[key] = { fg, bg }
            end
        end
    end
    self.hl_data = hl_data
end

function tmux_component:render(bufnr, winid, width)
    self.bufnr = bufnr
    local hl_data = self.hl_data or {}
    local comps = self.text(bufnr, winid, width)
    if type(comps) == 'table' then
        local result = ''
        for _, child in pairs(comps) do
            local text, hl = child[1], child[2]
            if type(text) == 'function' then
                text = child[1](bufnr, winid, width)
            end
            if type(hl) == 'string' then
                hl = hl_data[hl] or hl
            end
            result = result .. render_text(text, self:make_hl(hl))
        end
        return result
    end
    return render_text(comps, self:make_hl(self.hl))
end

return {
    ---@return tmux_component
    create = function(...)
        local cmp = base_component.create(...)
        ---@diagnostic disable-next-line: return-type-mismatch
        return setmetatable(cmp, { __index = tmux_component })
    end,
    reset = function() last_hl = {} end
}
