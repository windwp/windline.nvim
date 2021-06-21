local themes = require('windline.themes')
local windline = require('windline')
local helper = require('windline.helpers')
local utils = require('windline.utils')

local seperator = helper.separators
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
        result = result .. '%' .. i .. 'T'
        local data = {
            is_selection = i == tabSelect,
            is_next_select = ((i + 1) == tabSelect),
            is_tab_end = i == total_tab,
            seperator = tab_data.seperator,
            tab_index = i,
        }
        result = result .. tab_data.tab_template:render(data)
    end
    for _, comp in pairs(tab_data.tab_end) do
        result = result .. comp:render()
    end
    return result
end

local default_config = {
    seperator = {
        main = seperator.right_filled .. ' ',
        sub = seperator.right .. ' ',
    },
    tab_template = {
        hl_colors = {
            tab_selection = { 'TabSelectionFg', 'TabSelectionBg' },
            tab_normal = { 'TabLineFg', 'TabLineBg' },
            tab_sep_end = { 'TabSelectionBg', 'TabLineFillBg' },
            tab_normal_end = { 'TabLineBg', 'TabLineFillBg' },
            tab_normal_next = { 'TabLineBg', 'TabSelectionBg' },
            tab_sep = { 'TabSelectionBg', 'TabLineBg' },
        },
        text = function(data)
            local result = {}
            if data.is_selection then
                table.insert(result, { M.tab_name(data.tab_index), 'tab_selection' })
                if data.is_tab_end then
                    table.insert(result, { data.seperator.main, 'tab_sep_end' })
                else
                    table.insert(result, { data.seperator.main, 'tab_sep' })
                end
            else
                table.insert(result, { M.tab_name(data.tab_index), 'tab_normal' })
                if data.is_next_select then
                    table.insert(result, { data.seperator.main, 'tab_normal_next' })
                elseif data.is_tab_end then
                    table.insert(result, { data.seperator.main, 'tab_normal_end' })
                else
                    table.insert(result, { data.seperator.sub, '' })
                end
            end
            return result
        end,
    },
    tab_end = {
        { ' ', 'TabLineFill' },
    },
}

M.setup = function(opts)
    opts = vim.tbl_extend('force', default_config, opts or {})
    _G.WindLine.tabline = {
        setup_hightlight = M.setup_hightlight,
        show = M.show,
    }
    state.tabline = opts
    vim.cmd([[set tabline=%!v:lua.WindLine.tabline.show()]])
end

return M
