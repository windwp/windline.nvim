local themes = require('windline.themes')
local windline = require('windline')
local helper = require('windline.helpers')
local utils = require('windline.utils')

local separators = helper.separators
local M = {}

local state = _G.WindLine.state

M.setup_hightlight = function(colors)
    colors = colors or windline.get_colors()
    if not colors.TabSelectionBg then
        local fg_tab, bg_tab = themes.get_hl_color('TabLineSel')
        colors.TabSelectionFg = fg_tab or colors.white
        colors.TabSelectionBg = bg_tab or colors.black
    end
    if not colors.TabLineFillBg then
        local fg_fill, bg_fill = themes.get_hl_color('TabLineFill')
        colors.TabLineFillFg = fg_fill or colors.white
        colors.TabLineFillBg = bg_fill or colors.black
    end
    if not colors.TabLineBg then
        local fg_tab, bg_tab = themes.get_hl_color('TabLine')
        colors.TabLineFg = fg_tab or colors.white
        colors.TabLineBg = bg_tab or colors.black
    end
    windline.create_comp_list({ state.tabline.tab_template }, colors)
    windline.create_comp_list(state.tabline.tab_end, colors)
end

local last_tab_name = {}

M.tab_name = function(num)
    local buflist = vim.fn.tabpagebuflist(num)
    local winnr = vim.fn.tabpagewinnr(num)

    if buflist[winnr] ~= nil then
        if vim.fn.buflisted(buflist[winnr]) == 1 then
            local bufname = utils.get_unique_bufname(buflist[winnr])
            if bufname == '' then
                bufname = 'ツ'
            end
            last_tab_name[num] = num .. ' ' .. bufname
            return last_tab_name[num]
        else
            return last_tab_name[num] or ''
        end
    end
    return ''
end

M.show = function()
    local total_tab = vim.fn.tabpagenr('$')
    local result = ''
    local tabSelect = vim.fn.tabpagenr()
    local tab_data = state.tabline
    for i = 1, total_tab, 1 do
        -- set the tab for mouse click"
        if state.tabline.click then
            result = result .. '%' .. i .. 'T'
        end
        local data = {
            is_selection = i == tabSelect,
            is_next_select = ((i + 1) == tabSelect),
            is_tab_finish = i == total_tab,
            template = tab_data.template,
            tab_index = i,
        }
        result = result .. tab_data.tab_template:render(data)
    end
    for _, comp in pairs(tab_data.tab_end) do
        result = result .. comp:render(tabSelect)
    end
    return result
end

-- stylua: ignore
local default_config = {
    template = {
        select        = { '',                           { 'NormalFg', 'NormalBg', 'bold' } },
        select_start  = { separators.block_thin .. ' ', { 'blue', 'NormalBg' } },
        select_end    = { ' ',                          { 'NormalFg', 'NormalBg' } },
        select_fill   = { ' ',                          { 'NormalFg', 'NormalBg' } },
        normal        = { '',                           { 'TabLineFg', 'TabLineBg' } },
        normal_start  = { ' ',                          { 'TabLineFg', 'TabLineBg' } },
        normal_end    = { ' ',                          { 'TabLineFg', 'TabLineBg' } },
        normal_select = { ' ',                          { 'TabLineFg', 'TabLineBg' } },
        normal_last   = { ' ',                          { 'TabLineFg', 'TabLineBg' } },
    },
    click = true,
    tab_end = {
        { ' ', 'TabLineFill' },
    },
}

local tab_template = function(template)
    local hl_colors = {}
    local sep_text = {}
    for key, value in pairs(template) do
        hl_colors[key] = value[2]
        sep_text[key] = value[1]
    end
    return {
        hl_colors = hl_colors,
        text = function(data)
            if data.is_selection then
                local hl_end = 'select_end'
                local text_end = sep_text.select_end
                if data.is_tab_finish then
                    text_end = sep_text.select_last
                    hl_end = 'select_last'
                end
                return {
                    { sep_text.select_start, 'select_start' },
                    { M.tab_name(data.tab_index), 'select' },
                    { text_end, hl_end },
                }
            else
                local hl_end = 'normal_end'
                local text_end = sep_text.normal_end
                local text_start = sep_text.normal_start
                if data.is_tab_finish then
                    text_end = sep_text.normal_last
                    hl_end = 'normal_last'
                elseif data.is_next_select then
                    text_end = sep_text.normal_select
                    hl_end = 'normal_select'
                end
                return {
                    { text_start, 'normal_start' },
                    { M.tab_name(data.tab_index), 'normal' },
                    { text_end, hl_end },
                }
            end
        end,
    }
end

M.setup = function(opts)
    opts = vim.tbl_deep_extend('force', default_config, opts or {})
    opts.tab_template = opts.tab_template or tab_template(opts.template or {})
    WindLine.hl_data = {}
    _G.WindLine.tabline = {
        setup_hightlight = M.setup_hightlight,
        show = M.show,
    }
    state.tabline = opts
    if opts.colors then
--
        M.setup_hightlight(opts.colors)
        utils.hl_create()
    end
    vim.cmd([[set tabline=%!v:lua.WindLine.tabline.show()]])
end

return M
