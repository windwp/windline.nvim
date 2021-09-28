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
        runtime_colors = {} -- some colors name added by function add_component
    }

local mode = utils.mode

M.statusline_ft = {}

local render = function(bufnr, winid, items, cache)
    M.state.comp = {} --reset component data
    M.state.mode = mode()
    Comp.reset()
    local status = ''
    local win_width = api.nvim_win_is_valid(winid) and api.nvim_win_get_width(winid)
    for _, comp in pairs(items) do
        if win_width and (comp.width == nil or comp.width < win_width) then
            status = status .. comp:render(bufnr, winid, win_width)
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

M.show = function(bufnr, winid)
    bufnr = bufnr or api.nvim_get_current_buf()
    local line = M.get_statusline(bufnr)
    local cur_win = api.nvim_get_current_win()

    if vim.g.statusline_winid ~= cur_win then
        -- in active
        if
            M.last_win == vim.g.statusline_winid
            and api.nvim_win_get_config(cur_win).relative ~= ''
        then
            M.state.last_status_win = nil
            -- disable on floating window
            return M.state.cache_status
        else
            if line then
                -- render active even that component on_inactive
                if line.always_active == true then
                    return render(bufnr, winid, line.active)
                end
                if line.inactive then
                    return render(bufnr, winid, line.inactive)
                end
            end
            -- make an inactive render like the last active
            if M.state.last_status_win == winid and M.state.cache_last_status then
                return M.state.cache_last_status
            end
            return render(bufnr, winid, M.default_line.inactive)
        end
    else
        -- active
        M.bufnr = bufnr
        if line and line.active then
            if line.show_last_status and not M.state.last_status_win then
                M.state.last_status_win = M.last_win
                M.state.cache_last_status = M.state.cache_status
                -- some time the current window draw after the last
                -- window (sample quickfix window)
                M.on_win_enter(nil, M.state.last_status_win)
            end
            M.last_win = winid
            return render(bufnr, winid, line.active, true)
        end
        if M.state.last_status_win then
            M.on_win_enter(nil, M.state.last_status_win)
            M.state.last_status_win = nil
        end
        M.last_win = winid
    end
    return render(bufnr, winid, M.default_line.active, true)
end

M.on_win_enter = function(bufnr, winid)
    winid = winid or vim.api.nvim_get_current_win()
    if not vim.api.nvim_win_is_valid(winid) then return false end
    vim.api.nvim_win_set_option(winid, 'statusline', string.format(
        '%%!v:lua.WindLine.show(%s,%s)',
        bufnr or vim.api.nvim_win_get_buf(winid),
        winid
    ))
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

M.setup_hightlight = function(colors)
    assert(M.default_line ~= nil, 'you need define default statusline')
    assert(M.default_line.active ~= nil, 'default need list active component')
    assert(M.default_line.inactive ~= nil, 'default need list inactive component')

    if M.anim_pause then M.anim_pause() end

    utils.hl_clear()
    colors = colors or M.get_colors(true)

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

---get current colors
---@param reload any
---@return any
M.get_colors = function(reload)
    if not reload and M.state.colors then return M.state.colors end
    local colors = themes.load_theme()
    colors = M.state.config.colors_name(colors) or colors
    if M.state.runtime_colors then
        for _, func_color in pairs(M.state.runtime_colors) do
            colors = func_color(colors) or colors
        end
    end
    M.state.colors = colors
    assert(colors ~= nil, 'a colors_name on setup function should return a value')
    return colors
end

M.on_colorscheme = function(colors)
    M.setup_hightlight(colors or M.get_colors(true))
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
    if M.state.floatline then WindLine.floatline_disable() end
    if M.anim_reset then M.anim_reset() end

    M.state.config.colors_name = opts.colors_name
    M.add_status(opts.statuslines)
    M.setup_event()
end

M.setup_event = function()
    vim.opt.laststatus = 2
    vim.cmd([[set statusline=%!v:lua.WindLine.show()]])
    api.nvim_exec(
        [[augroup WindLine
            au!
            au BufWinEnter,WinEnter * lua WindLine.on_win_enter()
            au VimEnter * lua WindLine.on_vimenter()
            au ColorScheme * lua WindLine.on_colorscheme()
        augroup END]],
        false
    )
    api.nvim_exec("command! -nargs=* WindLineBenchmark lua require('windline.benchmark').benchmark()", false)
    api.nvim_exec("command! -nargs=* WindLineFloatToggle lua require('wlfloatline').toggle()", false)
end

M.add_status = function(lines)
    -- FIXME update change. It will be remove on the future
    for _, line in ipairs(lines) do
        utils.update_check(line.in_active ~= nil,
           "You need to change status line 'in_active' to 'inactive'. ':%s/in_active/inactive/g'")
        line.inactive = line.inactive or line.in_active
        utils.update_check(line.show_in_active ~= nil,
        "You need to change status line 'show_in_active' to 'always_active'. ':%s/show_in_active/always_active/g'")
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
    M.setup_hightlight()
end


--- add component to status
--- you need define a name and a position
--- position can be an index of array or a a name of previous component
--- if position = nil then it will add at a last of statusline
---@param component Component
---@param opt table {filetype = "",  position = "", kind = "active",colors_name}
---opt.position == left add  component before a first divider (%=)
---opt.position == right add component after a first divider (%=)
---opt.color_name table a modifer colors to add to a new component
M.add_component = function(component, opt)
    local line = M.get_statusline_ft(opt.filetype or '') or M.default_line
    local added = false
    local status_line = line[opt.kind or 'active']
    if type(opt.position) == 'number' then
        table.insert(status_line, opt.position, component)
        added = true
    elseif type(opt.position) == 'string' then
        for index, comp in ipairs(status_line) do
            if comp.name and comp.name == opt.position then
                table.insert(status_line, index, component)
                added = true
                break
            end
        end
        if not added then
            local divider_pos = utils.find_divider_index(status_line)
            if divider_pos then
                if opt.position == 'left' then
                    table.insert(status_line,divider_pos,component)
                    added = true
                else
                    table.insert(status_line, divider_pos + 1, component)
                    added = true
                end
            end
        end
    end
    if added then
        if component.name and opt.colors_name then
            M.state.runtime_colors = M.state.runtime_colors or{}
            M.state.runtime_colors[component.name] = opt.colors_name
        end
        M.setup_hightlight()
    else
        vim.api.nvim_echo({{string.format("Cant' find a position %s",opt.position),'ErrorMsg'}},true,{})
    end
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
    M.state.runtime_colors[opt.name] = nil
end

return M
