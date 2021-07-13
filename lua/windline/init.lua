local api = vim.api
local M = _G.WindLine or {}
_G.WindLine = _G.WindLine or M

local themes = require('windline.themes')
local utils = require('windline.utils')
local Comp = require('windline.component')

M.lastBuff = 0

M.state = M.state
    or {
        mode = {}, -- vim mode {normal insert}
        comp = {}, -- component state it will reset on begin render
        config = {},
    }

local mode = utils.mode

M.statusline_ft = {}

local is_width_valid = function (width, winnr)
    if width == nil then return true end
    return api.nvim_win_is_valid(winnr)
        and width < api.nvim_win_get_width(winnr)
end

local render = function(bufnr, winnr, items, cache)
    M.state.comp = {} --reset component data
    M.state.mode = mode()
    Comp.reset()
    local status = ''
    for _, comp in pairs(items) do
        if is_width_valid(comp.width, winnr) then
            status = status .. comp:render(bufnr, winnr)
        end
    end
    if cache then
        M.state.cache_status = status
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

M.show = function(bufnr, winnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    local line = M.get_statusline(bufnr)
    local win_id = api.nvim_get_current_win()
    if vim.g.statusline_winid ~= win_id then
        -- in active
        if
            M.last_win == vim.g.statusline_winid
            and api.nvim_win_get_config(win_id).relative ~= ''
        then
            -- disable on floating window
            return M.state.cache_status
        else
            if line then
                -- render active even that component on_inactive
                if line.show_in_active == true then
                    return render(bufnr, winnr, line.active)
                end
                if line.in_active then
                    return render(bufnr, winnr, line.in_active)
                end
            end
            return render(bufnr, winnr, M.default_line.in_active)
        end
    else
        M.bufnr = bufnr
        M.last_win = win_id
        if line and line.active then
            return render(bufnr, winnr, line.active, true)
        end
    end
    return render(bufnr, winnr, M.default_line.active, true)
end

M.on_win_enter = function(bufnr)
    vim.wo.statusline = string.format(
        '%%!v:lua.WindLine.show(%s,%s)',
        bufnr,
        api.nvim_get_current_win()
    )
end

-- create component and init highlight first
M.create_comp_list = function(comps_list, colors)
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

local setup_hightlight = function(colors)
    assert(M.default_line ~= nil, 'you need define default statusline')
    assert(M.default_line.active ~= nil, 'default need list active componet')
    assert(M.default_line.in_active ~= nil, 'default need list in_active component')

    if M.anim_pause then M.anim_pause() end

    utils.hl_clear()
    colors = colors or M.get_colors()

    if M.tabline then
        M.tabline.setup_hightlight(colors)
    end

    for _, line in pairs(M.statusline_ft) do
        M.create_comp_list(line.active, colors)
        M.create_comp_list(line.in_active, colors)
    end
    M.create_comp_list(M.default_line.active, colors)
    M.create_comp_list(M.default_line.in_active, colors)
    utils.hl_create()

    if M.anim_run then M.anim_run() end
end

M.get_colors = function()
    local colors = themes.load_theme()
    colors = M.state.config.colors_name(colors) or colors
    assert(colors ~= nil, 'a colors_name on setup function should return a value')
    return colors
end

M.on_colorscheme = function(colors)
    setup_hightlight(colors or M.get_colors())
end

M.on_vimenter = function()
    themes.clear_cache()
    M.on_colorscheme()
end

---@class WLConfig
local default_config = {
    theme = nil,
    colors_name = function(color)
        return color
    end,
}

M.setup = function(opts)
    M.statusline_ft = {}
    opts = vim.tbl_extend('force', default_config, opts)
    themes.default_theme = opts.theme
    if opts.tabline then
        require('wltabline').setup(opts.tabline)
    end
    require('windline.cache_utils').reset()
    if M.anim_reset then M.anim_reset() end

    M.state.config.colors_name = opts.colors_name
    M.add_status(opts.statuslines)
    vim.cmd([[set statusline=%!v:lua.WindLine.show()]])
    api.nvim_exec(
        [[augroup WindLine
            au!
            au BufWinEnter,WinEnter * call v:lua.WindLine.on_win_enter(expand('<abuf>'))
            au VimEnter * call v:lua.WindLine.on_vimenter()
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
                table.insert(M.statusline_ft, value)
            end
        end
    end
    M.statusline_ft = vim.tbl_filter(function(cline)
        if utils.is_in_table(cline.filetypes, 'default') then
            M.default_line = cline
            return false
        end
        return true
    end, M.statusline_ft)
    setup_hightlight()
end

return M
