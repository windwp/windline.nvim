local api = vim.api
local M = _G.WindLine or {}
_G.WindLine = _G.WindLine or M

local themes = require('windline.themes')
local utils = require('windline.utils')
local Comp = require('windline.component')

M.lastBuff = 0

M.state = {
    mode = {}, -- vim mode {normal insert}
    comp = {}, -- component state it will reset on begin render
    config = {},
}


local mode = utils.mode

M.statusline_ft = {}

local render = function(bufnr, items)
    local status = ''
    for _, comp in pairs(items) do
        status = status .. comp:render(bufnr)
    end
    return status
end

M.get_statusline = function(bufnr)
    local ft = api.nvim_buf_get_option(bufnr, 'filetype')
    for _, line in pairs(M.statusline_ft) do
        if utils.is_in_table(line.filetypes, ft) then
            return line
        end
    end
end

M.show = function(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    M.state.comp = {} --reset comp
    M.state.mode = mode()
    local line = M.get_statusline(bufnr)

    local win_id = api.nvim_get_current_win()
    if vim.g.statusline_winid ~= win_id then
        -- in active
        if
            M.last_win == vim.g.statusline_winid
            and vim.api.nvim_win_get_config(win_id).relative ~= ''
        then
            -- disable on floating window
            return M.state.cache_status
        else
            if line then
                -- render active even that component on_inactive
                if line.show_in_active == true then
                    return render(bufnr, line.active)
                end
                if line.in_active then
                    return render(bufnr, line.in_active)
                end
            end
            return render(bufnr, M.default_line.in_active)
        end
    else
        M.bufnr = bufnr
        M.last_win = win_id
        if line and line.active then
            return render(bufnr, line.active)
        end
    end
    M.state.cache_status = render(bufnr, M.default_line.active)
    return M.state.cache_status
end

M.on_enter = function(bufnr)
    vim.wo.statusline = string.format('%%!v:lua.WindLine.show(%s)', bufnr)
end

local setup_hightlight = function(colors)
    assert(M.default_line ~= nil, 'you need define default statusline')
    assert(M.default_line.active ~= nil, 'default need list active componet')
    assert(M.default_line.in_active ~= nil, 'default need list in_active component')
    if _G.WindLine.stop then
        _G.WindLine.stop()
    end
    utils.hl_clear()
    colors = colors or M.get_colors()

    --  create component and init highlight first
    local create_comp = function(comps_list)
        if type(comps_list) == 'table' then
            for key, value in pairs(comps_list) do
                local comp = value
                if not value.created then
                    comp = Comp.create(value)
                    comps_list[key] = comp
                end
                comp:setup_hl(colors)
            end
        end
    end

    for _, line in pairs(M.statusline_ft) do
        create_comp(line.active)
        create_comp(line.in_active)
    end
    create_comp(M.default_line.active)
    create_comp(M.default_line.in_active)
    utils.hl_create()
end

M.get_colors = function()
    local colors = themes.load_theme()
    colors = M.state.config.colors_name(colors)
    return colors
end

M.on_colorscheme = function()
    setup_hightlight(M.get_colors())
end

---@class WLConfig
local default_config = {
    default_colors = nil,
    themes = nil,
    colors_name = function(color)
        return color
    end,
}

M.setup = function(opts)
    M.statusline_ft = {}
    opts = vim.tbl_extend('force', default_config, opts)
    themes.default_theme = opts.theme
    M.state.config.colors_name = opts.colors_name
    M.add_status(opts.statuslines)
    setup_hightlight()
    vim.cmd([[set statusline=%!v:lua.WindLine.show()]])
    api.nvim_exec(
        [[augroup WindLine
            au!
            au BufEnter * call v:lua.WindLine.on_enter(expand('<abuf>'))
            au ColorScheme * call v:lua.WindLine.on_colorscheme()
        augroup END]],
        false
    )
end

M.add_status = function(lines)
    if lines.filetypes then
        table.insert(M.statusline_ft, lines)
    else
        for _, value in pairs(lines) do
            if value.filetypes then
                table.insert(M.statusline_ft,value)
            end
        end
    end
    -- verify default and remove it
    for index, cline in pairs(M.statusline_ft) do
        if utils.is_in_table(cline.filetypes, 'default') then
            M.default_line = cline
            table.remove(M.statusline_ft, index)
        end
    end
    setup_hightlight()
end

return M
