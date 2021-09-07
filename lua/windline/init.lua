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

local render = function(bufnr, winnr, items, cache)
    M.state.comp = {} --reset component data
    M.state.mode = mode()
    Comp.reset()
    local status = ''
    local win_width = api.nvim_win_is_valid(winnr) and api.nvim_win_get_width(winnr)
    for _, comp in pairs(items) do
        if win_width and (comp.width == nil or comp.width < win_width) then
            status = status .. comp:render(bufnr, winnr, win_width)
        end
    end
    if cache then
        M.state.cache_status = status
    end
    return status
end

M.get_statusline_ft = function(ft)
    for _, line in pairs(M.statusline_ft) do
        if utils.is_in_table(line.filetypes, ft) then
            return line
        end
    end
end

M.get_statusline = function(bufnr)
    local ft = api.nvim_buf_get_option(bufnr, 'filetype')
    return M.get_statusline_ft(ft)
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
            M.state.last_status_win = nil
            -- disable on floating window
            return M.state.cache_status
        else
            if line then
                -- render active even that component on_inactive
                if line.always_active == true then
                    return render(bufnr, winnr, line.active)
                end
                if line.inactive then
                    return render(bufnr, winnr, line.inactive)
                end
            end
            -- make an inactive render like the last active
            if M.state.last_status_win == vim.g.statusline_winid then
                return M.state.cache_last_status
            end
            return render(bufnr, winnr, M.default_line.inactive)
        end
    else
        -- active
        M.bufnr = bufnr
        if line and line.active then
            if line.show_last_status and not M.state.last_status_win then
                -- remember last window status active
                M.state.last_status_win = M.last_win
                M.state.cache_last_status = M.state.cache_status
                -- current status window will draw after the last window
                -- it need force another window draw again
                vim.cmd[[redraws!]]
            end
            M.last_win = win_id
            return render(bufnr, winnr, line.active, true)
        end
        M.last_win = win_id
        M.state.last_status_win = nil
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
    assert(M.default_line.inactive ~= nil, 'default need list inactive component')

    if M.anim_pause then M.anim_pause() end

    utils.hl_clear()
    colors = colors or M.get_colors()

    if M.tabline then
        M.tabline.setup_hightlight(colors)
    end

    for _, line in pairs(M.statusline_ft) do
        M.create_comp_list(line.active, colors)
        M.create_comp_list(line.inactive, colors)
    end
    M.create_comp_list(M.default_line.active, colors)
    M.create_comp_list(M.default_line.inactive, colors)
    utils.hl_create()

    if M.anim_run then M.anim_run() end
end

M.get_colors = function()
    local colors = themes.load_theme()
    colors = M.state.config.colors_name(colors) or colors
    M.state.colors = colors
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
    api.nvim_exec("command! -nargs=* WindLineBenchmark lua require('windline').benchmark()", false)
end


M.add_status = function(lines)
    for _, line in ipairs(lines) do
        line.inactive = line.inactive or line.in_active
        line.always_active = line.always_active or line.show_in_active
    end
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

--- add component to status
--- you need define a name and a position
--- position can be an index of array or a a name of previous component
--- if position = nil then it will add at a last of statusline
---@param component Component
---@param opt table {filetype = "",  position = "", kind = "active"}
M.add_component = function(component, opt)
    local line = M.get_statusline_ft(opt.filetype or '') or M.default_line

    local status_line = line[opt.kind or 'active']
    if type(opt.position) == 'number' then
        table.insert(status_line, opt.position, component)
    elseif type(opt.position) == 'string' then
        for index, comp in ipairs(status_line) do
            if comp.name and comp.name == opt.position then
                table.insert(status_line, index, component)
                break
            end
        end
    else
        table.insert(status_line, component)
    end
    setup_hightlight()
end

--- remove component
--- remove_component({name = 'lsp', filetype = 'default', kind = 'active'})
M.remove_component = function(opt)
    local line = M.get_statusline_ft(opt.filetype) or M.default_line

    local status_line = line[opt.kind or 'active']
    for index, comp in ipairs(status_line) do
        if comp.name and comp.name == opt.name then
            table.remove(status_line, index)
            break
        end
    end
end


--- a benchmark current statusline. it need plenary.nvim
M.benchmark = function()
    local num = 1e4
    local bench = require('plenary.profile').benchmark
    local statusline = ''
    local time = bench(num, function()
        vim.g.statusline_winid = api.nvim_get_current_win()
        statusline = WindLine.show(api.nvim_get_current_buf(), vim.g.statusline_winid)
    end)
    local popup = require('plenary.popup')
    local result = {}
    table.insert(result,'Status:')
    table.insert(result, statusline)
    table.insert(result, 'Time:')
    table.insert(result, string.format('render %s time : *%s*', num, time))
    table.insert(result, 'Comp:')
    local line = M.get_statusline_ft(vim.bo.filetype) or M.default_line
    local bufnr = api.nvim_get_current_buf()
    local winnr = api.nvim_get_current_win()
    local width = api.nvim_win_get_width(0)
    table.insert(result, string.format('%s %12s %12s %s %s', ' ', 'time', 'name', 'num   ', 'text'))
    for index, comp in ipairs(line.active) do
        local item=''
        time = bench(num, function()
            item = comp:render(bufnr, winnr, width)
        end)
        table.insert(result, string.format('%02d *%10s* %12s %s - %s', index, time, comp.name or '   ', num, item))
    end
    local vim_width = math.floor(vim.o.columns / 1.5)
    local col = math.floor((vim.o.columns - vim_width) / 2)
    popup.create(result, {
        border = {},
        minheight = 30,
        maxwidth=vim_width,
        col = col,
        line = 10,
        width = vim_width,
    })
    vim.bo.filetype = 'help'
end

return M
