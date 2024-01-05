local api = vim.api
---@class WindLine
local M = {}
_G.WindLine = _G.WindLine or M

local themes = require('windline.themes')
local utils = require('windline.utils')
local Comp = require('windline.component')
local click_utils = require('windline.click_utils')

M.state = M.state
    or {
        mode = {},           -- vim mode {normal insert}
        comp = {},           -- component state it will reset on begin render
        config = {},
        runtime_colors = {}, -- some colors name added by function add_component
    }

local mode = utils.mode

M.statusline_ft = {}
M.get_status_width = api.nvim_win_get_width

local render = function(bufnr, winid, items, cache)
    M.state.comp = {} --reset component data
    M.state.mode = mode()
    Comp.reset()
    local status = ''
    winid = winid and api.nvim_win_is_valid(winid) and winid
        or api.nvim_get_current_win()
    local win_width = M.get_status_width(winid) or 0
    for _, comp in pairs(items) do
        if comp.width == nil or comp.width < win_width then
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

M.show_normal = function(bufnr, winid)
    bufnr = bufnr or api.nvim_get_current_buf()
    local line = M.get_statusline(bufnr)
    local cur_win = api.nvim_get_current_win()

    if vim.g.statusline_winid ~= cur_win then
        -- in active
        if M.last_win == vim.g.statusline_winid
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

M.show = M.show_normal

M.show_global = function(bufnr, winid)
    bufnr = bufnr or api.nvim_get_current_buf()
    winid = winid and api.nvim_win_is_valid(winid) and winid
        or api.nvim_get_current_win()
    local ft = api.nvim_buf_get_option(bufnr, 'filetype')
    local check_line = M.get_statusline_ft(ft) or {}

    if vim.g.statusline_winid == winid then
        if utils.is_in_table(M.state.config.global_skip_filetypes, ft)
            or (
                api.nvim_win_get_config(winid).relative ~= ''
                and not check_line.global_show_float
            )
        then
            bufnr = M.state.last_bufnr or bufnr
            winid = M.state.last_winid or winid
        end
        if not api.nvim_win_is_valid(winid) or not api.nvim_buf_is_valid(bufnr) then
            return M.state.cache_status
        end
    else
        return M.show_normal(bufnr, winid)
    end
    local line = M.get_statusline(bufnr) or WindLine.default_line
    M.state.last_bufnr = bufnr
    M.state.last_winid = winid
    return render(bufnr, winid, line.active, true)
end

M.show_ft = function(bufnr, winid, filetype)
    bufnr = bufnr or api.nvim_get_current_buf()
    winid = winid or api.nvim_get_current_win()
    local line = M.get_statusline_ft(filetype)

    if vim.api.nvim_get_current_win() == winid then
        return render(bufnr, winid, line.active)
    end

    return render(bufnr, winid, line.inactive or line.active)
end

M.show_winbar = function(bufnr, winid)
    return M.show_ft(bufnr, winid, 'winbar')
end

M.on_win_enter = function(bufnr, winid)
    winid = winid or vim.api.nvim_get_current_win()
    if not vim.api.nvim_win_is_valid(winid) then return false end
    bufnr = bufnr or vim.api.nvim_win_get_buf(winid)
    M.check_autocmd_component(bufnr)
    vim.api.nvim_win_set_option(
        winid,
        'statusline',
        string.format('%%!v:lua.WindLine.show(%s,%s)', bufnr, winid)
    )
    local winbar = M.get_statusline_ft('winbar')
    if winbar then
        local list_win = vim.api.nvim_tabpage_list_wins(vim.api.nvim_get_current_tabpage())
        -- it need to re set winbar on all another window
        for _, i_winid in pairs(list_win) do
            if not winbar.enable or winbar.enable(bufnr, winid) and i_winid == winid then
                if vim.api.nvim_win_get_config(winid).relative == '' then
                    vim.api.nvim_win_set_option(
                        winid,
                        'winbar',
                        string.format(
                            '%%!v:lua.WindLine.show_winbar(%s,%s)',
                            bufnr,
                            winid
                        )
                    )
                end
            else
                vim.api.nvim_win_set_option(i_winid, 'winbar', '')
            end
        end
    end
end

-- create component and init highlight first
M.create_comp_list = function(comps_list, colors)
    if type(comps_list) == 'table' then
        for key, value in pairs(comps_list) do
            local comp = value
            if not value.created then
                comp = Comp.create(value)
                comps_list[key] = comp
                comp.click = click_utils.add_click_listerner(comp.click or value.click)
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
    -- use it to update modify colors on dynamic component when ColorScheme happen
    if M.state.runtime_colors then
        for _, func_color in pairs(M.state.runtime_colors) do
            colors = vim.tbl_extend('force', colors, func_color(colors))
        end
    end
    for key, c in ipairs(colors) do
        colors[key] = string.lower(c)
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

M.on_set_laststatus = function()
    if vim.go.laststatus == 3 then
        M.show = M.show_global
        M.get_status_width = function(_)
            return vim.o.columns
        end
    else
        M.show = M.show_normal
        M.get_status_width = api.nvim_win_get_width
    end
end

M.on_ft = function()
    local bufnr = vim.api.nvim_get_current_buf()
    M.check_autocmd_component(bufnr)
end

---@class WLConfig
local default_config = {
    theme = nil,
    colors_name = function(color)
        return color
    end,
}

M.setup = function(opts)
    M.hl_data = {}
    click_utils.clear()
    opts = vim.tbl_extend('force', default_config, opts)
    themes.default_theme = opts.theme
    if opts.tabline then
        require('wltabline').setup(opts.tabline)
    end
    require('windline.cache_utils').reset()
    if M.anim_reset then M.anim_reset() end

    M.state.config.colors_name = opts.colors_name
    M.state.config.global_skip_filetypes = opts.global_skip_filetypes or {
        'NvimTree',
        'lir',
    }
    M.add_status(opts.statuslines)
    M.on_set_laststatus()
    M.setup_event()
end


M.setup_event = function()
    vim.opt.statusline = "%!v:lua.WindLine.show()"
    local group = api.nvim_create_augroup("WindLine", { clear = true })
    api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
        group = group,
        pattern = "*",
        callback = function() M.on_win_enter() end
    })
    api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "*",
        callback = function() M.on_ft() end
    })
    api.nvim_create_autocmd("VimEnter", {
        group = group,
        pattern = "*",
        callback = function() M.on_vimenter() end
    })
    api.nvim_create_autocmd("ColorScheme", {
        group = group,
        pattern = "*",
        callback = function() M.on_colorscheme() end
    })
    api.nvim_create_autocmd("OptionSet", {
        group = group,
        pattern = "laststatus",
        callback = function() M.on_set_laststatus() end
    })
    api.nvim_create_user_command("WindLineBenchmark", "lua require('windline.benchmark').benchmark()", {})
end

M.remove_status_by_ft = function(filetypes)
    for _, ft in pairs(filetypes) do
        M.statusline_ft = vim.tbl_filter(function(cline)
            return not utils.is_in_table(cline.filetypes, ft)
        end, M.statusline_ft)
    end
end

M.add_status = function(lines)
    assert(lines ~= nil, 'You need to define a statuslines.')
    if lines and lines.filetypes then
        lines = { lines }
    end
    for _, value in pairs(lines) do
        if value.filetypes then
            table.insert(M.statusline_ft, value)
            if value.colors_name then
                M.state.runtime_colors[value.filetypes[1]] = value.colors_name
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

--- dynamic change color it will not change the color with event ColorScheme
M.change_colors = function(colors)
    for key, value in pairs(colors) do
        M.state.colors[key] = value
    end
    M.setup_hightlight(M.state.colors)
end

---add component to status
---@param component Component
---@param opt table {filetype = "",  position = "", kind = "active",colors_name}
---  you need define name and position
--   name      string
--   position   string|number position can be an index or a name of previous component
---     position == left add  component before a first divider (%=)
---     position == right add component after a first divider (%=)
---  auto_remove auto remove old component with same name
---  colors_name table    a modifier colors to add to a new component
---  autocmd    boolean  It use an auto command to add component to default statusline.
M.add_component = function(component, opt)
    if opt.autocmd then
        opt.autocmd = false
        M.add_autocmd_component(component, opt)
        return
    end
    if opt.auto_remove then
        M.remove_component(opt)
    end
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
            M.state.mode = mode()
            local divider_pos = utils.find_divider_index(status_line)
            if divider_pos then
                if opt.position == 'left' then
                    table.insert(status_line, divider_pos, component)
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
            M.state.runtime_colors = M.state.runtime_colors or {}
            M.state.runtime_colors[component.name] = opt.colors_name
            M.state.colors = vim.tbl_extend('force', M.state.colors, opt.colors_name(M.state.colors))
        end
        M.setup_hightlight(M.state.colors)
    else
        vim.api.nvim_echo({ { string.format("Can't find a position %s", opt.position), 'ErrorMsg' } }, true, {})
    end
end

--- remove component
--- remove_component({name = 'lsp', filetype = 'default', kind = 'active'})
M.remove_component = function(opt)
    local line = M.get_statusline_ft(opt.filetype) or M.default_line

    local status_line = line[opt.kind or 'active']
    M.state.runtime_colors[opt.name] = nil
    for index, comp in pairs(status_line) do
        if comp.name and comp.name == opt.name then
            table.remove(status_line, index)
            return true
        end
    end
    return false
end

M.add_autocmd_component = function(component, opts)
    if not M.state.auto_comps then
        M.state.auto_comps = {}
    end
    if component.name ~= opts.name or component.name == nil then
        component.name = opts.name or component.name
        opts.name = component.name
    end
    if opts.auto_remove then
        M.remove_auto_component(opts)
        M.remove_component(opts)
    end
    M.state.auto_comps[component.name] = {
        component = component,
        is_added = false,
        opts = opts,
    }
end

M.check_autocmd_component = function(bufnr)
    if not M.state.auto_comps then
        return
    end
    local ft = api.nvim_buf_get_option(bufnr, 'filetype')
    for index, value in pairs(M.state.auto_comps) do
        if value.opts.filetype == ft or value.opts.filetype == '*' then
            if not value.is_added then
                value.is_added = true
                M.add_component(value.component, value.opts)
            end
        elseif value.is_added then
            value.is_added = false
            if not M.remove_component({ name = value.opts.name }) then
                --it can't remove so we need to remove auto event
                M.state.auto_comps[index] = nil
            end
        end
    end
end

M.remove_auto_component = function(opts)
    M.state.auto_comps = vim.tbl_filter(function(value)
        return value.opts.name ~= opts.name
    end, M.state.auto_comps)
    if #M.state.auto_comps == 0 then
        M.state.auto_comps = nil
    end
end

M.on_click = click_utils.click_handler
M.make_click = click_utils.make_click
M.render_status = render
return M
