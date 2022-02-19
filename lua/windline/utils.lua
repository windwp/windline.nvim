local M = {}

local mode_map = {
    ['n'] = { 'NORMAL', 'Normal' },
    ['no'] = { 'O-PENDING', 'Visual' },
    ['nov'] = { 'O-PENDING', 'Visual' },
    ['noV'] = { 'O-PENDING', 'Visual' },
    ['no'] = { 'O-PENDING', 'Visual' },
    ['nt'] = { 'T-NORMAL', 'Normal' },
    ['niI'] = { 'NORMAL', 'Normal' },
    ['niR'] = { 'NORMAL', 'Normal' },
    ['niV'] = { 'NORMAL', 'Normal' },
    ['v'] = { 'VISUAL', 'Visual' },
    ['V'] = { 'V-LINE', 'Visual' },
    [''] = { 'V-BLOCK', 'Visual' },
    ['s'] = { 'SELECT', 'Visual' },
    ['S'] = { 'S-LINE', 'Visual' },
    [''] = { 'S-BLOCK', 'Visual' },
    ['i'] = { 'INSERT', 'Insert' },
    ['ic'] = { 'INSERT', 'Insert' },
    ['ix'] = { 'INSERT', 'Insert' },
    ['R'] = { 'REPLACE', 'Replace' },
    ['Rc'] = { 'REPLACE', 'Replace' },
    ['Rv'] = { 'V-REPLACE', 'Normal' },
    ['Rx'] = { 'REPLACE', 'Normal' },
    ['Rvc'] = { 'V-REPLACE', 'Replace' },
    ['Rvx'] = { 'V-REPLACE', 'Replace' },
    ['c'] = { 'COMMAND', 'Command' },
    ['cv'] = { 'EX', 'Command' },
    ['ce'] = { 'EX', 'Command' },
    ['r'] = { 'REPLACE', 'Replace' },
    ['rm'] = { 'MORE', 'Normal' },
    ['r?'] = { 'CONFIRM', 'Normal' },
    ['!'] = { 'SHELL', 'Normal' },
    ['t'] = { 'TERMINAL', 'Command' },
}

M.mode = function()
    local mode_code = vim.api.nvim_get_mode().mode
    if mode_map[mode_code] == nil then
        return { mode_code, 'Normal' }
    end
    return mode_map[mode_code]
end

M.change_mode_name = function(new_mode)
    mode_map = new_mode
end

M.is_in_table = function(tbl, val)
    if tbl == nil then
        return false
    end
    for _, value in pairs(tbl) do
        if val == value then
            return true
        end
    end
    return false
end

M.hl_text = function(text, highlight)
    if text == nil then
        text = ''
    end
    return string.format('%%#%s#%s', highlight, text)
end

local api = vim.api
local rgb2cterm = not vim.go.termguicolors
    and require('windline.cterm_utils').rgb2cterm

if vim.version().minor >= 7 then
    M.highlight = function(group, color)
        if rgb2cterm then
            color.ctermfg = color.fg and rgb2cterm(color.fg)
            color.ctermbg = color.bg and rgb2cterm(color.bg)
        end
        api.nvim_set_hl(0, group, color)
    end
else
    M.highlight = function(group, color)
        local c = {
            guifg = color.fg,
            guibg = color.bg,
            gui = color.bold and 'bold',
        }
        if rgb2cterm then
            c.ctermfg = color.fg and rgb2cterm(color.fg)
            c.ctermbg = color.bg and rgb2cterm(color.bg)
        end
        local options = {}
        for k, v in pairs(c) do
            table.insert(options, string.format('%s=%s', k, v))
        end
        vim.api.nvim_command(
            string.format([[highlight  %s %s]], group, table.concat(options, ' '))
        )
    end
end

M.get_color = function (colors, name)
    local c = colors[name]
    if c == nil then
        print('WL' .. (name or '') .. ' color is not defined ')
        return
    end
    if string.lower(c) == 'none' then
        c = nil
    end
    return c
end

M.get_hl_name = function(c1, c2, style)
    local name = string.format('WL%s_%s', c1 or '', c2 or '')
    if style == 'bold' then
        name = name .. 'b'
    end
    return name
end

-- use it on setup
M.hl = function(tbl, colors, is_runtime)
    local name = M.get_hl_name(tbl[1], tbl[2], tbl[3])
    if WindLine.hl_data[name] then
        return name
    end
    colors = colors or WindLine.state.colors
    local fg = M.get_color(colors,tbl[1])
    local bg = M.get_color(colors,tbl[2])

    local style = {
        bg = bg,
        fg = fg,
    }
    if tbl[3] then
        style[string.lower(tbl[3])] = true
    end

    if is_runtime then
        M.highlight(name, style)
    end

    WindLine.hl_data[name] = style
    return name
end

M.hl_clear = function()
    _G.WindLine.hl_data = {}
end

M.hl_create = function()
    local hl_data = _G.WindLine.hl_data
    for name, value in pairs(hl_data) do
        M.highlight(name, value)
    end
end

M.get_unique_bufname = function(bufnr, max_length)
    max_length = max_length or 24
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    local all_bufers = vim.tbl_filter(function(buffer)
        return buffer.listed == 1 and buffer.name ~= bufname
    end, vim.fn.getbufinfo())
    local all_name = vim.tbl_map(function(buffer)
        return string.reverse(buffer.name)
    end, all_bufers)
    local tmp_name = string.reverse(bufname)
    local position = 1
    if #all_name > 1 then
        for _, other_name in pairs(all_name) do
            for i = 1, #tmp_name do
                if tmp_name:sub(i, i) ~= other_name:sub(i, i) then
                    if i > position then
                        position = i
                    end
                    break
                end
            end
        end
    end
    while position <= #tmp_name do
        if tmp_name:sub(position, position) == '/' then
            position = position - 1
            break
        end
        position = position + 1
    end
    local name = string.reverse(string.sub(tmp_name, 1, position))
    if #name > max_length then
        return vim.fn.pathshorten(name)
    end
    return name
end

M.update_check = function(check, message)
    if check then
        vim.notify('WindLine Update: ' .. message)
    end
end

M.find_divider_index = function(status_line)
    for index, comp in pairs(status_line) do
        local text = comp.text(
            vim.api.nvim_get_current_buf(),
            vim.api.nvim_get_current_win(),
            100
        )
        if type(text) == 'string' then
            if text == '%=' then
                return index
            end
        elseif type(text) == 'table' then
            for _, value in ipairs(text) do
                if value[1] == '%=' then
                    return index
                end
            end
        end
    end
end

M.buf_get_var = function(bufnr, key)
    local ok, value = pcall(vim.api.nvim_buf_get_var, bufnr, key)
    if ok then
        return value
    end
    return nil
end

return M
