local windline = require('windline')
local helper = require('windline.helpers')
local b_components = require('windline.components.basic')
local state = _G.WindLine.state

local lsp_comps = require('windline.components.lsp')
local git_comps = require('windline.components.git')

local hl_list = {
    Black = { 'white', 'black' },
    White = { 'black', 'white' },
    Inactive = { 'InactiveFg', 'InactiveBg' },
    Active = { 'ActiveFg', 'ActiveBg' },
}
local basic = {}

local breakpoint_width = 90
basic.divider = { b_components.divider, '' }

local colors_mode = {
    Normal = { 'red', 'black' },
    Insert = { 'green', 'black' },
    Visual = { 'yellow', 'black' },
    Replace = { 'blue_light', 'black' },
    Command = { 'magenta', 'black' },
}

basic.vi_mode = {
    name = 'vi_mode',
    hl_colors = colors_mode,
    text = function()
        return { { '  ', state.mode[2] } }
    end,
}
basic.square_mode = {
    hl_colors = colors_mode,
    text = function()
        return { { '▊', state.mode[2] } }
    end,
}

basic.lsp_diagnos = {
    name = 'diagnostic',
    width = breakpoint_width,
    text = function(bufnr)
        if lsp_comps.check_lsp(bufnr) then
            return {
                { ' ' },
                {
                    lsp_comps.lsp_error({ format = ' %s', show_zero = true }),
                    { 'red', 'black' },
                },
                {
                    lsp_comps.lsp_warning({ format = '  %s', show_zero = true }),
                    { 'yellow','black' },
                },
                {
                    lsp_comps.lsp_hint({ format = '  %s', show_zero = true }),
                    { 'blue', 'black' },
                },
            }
        end
        return ''
    end,
}

basic.file = {
    name = 'file',
    text = function(_, _, width)
        if width > breakpoint_width then
            return {
                { b_components.cache_file_size(), { 'white', 'black' } },
                { ' ' },
                { b_components.cache_file_name('[No Name]', 'unique'), { 'magenta' } },
                { b_components.line_col_lua, { 'white' } },
                { b_components.progress_lua },
                { ' ' },
                { b_components.file_modified(' '), { 'magenta' } },
            }
        else
            return {
                { b_components.cache_file_size(), { 'white', 'black' } },
                { ' ' },
                { b_components.cache_file_name('[No Name]', 'unique'), { 'magenta' } },
                { ' ' },
                { b_components.file_modified(' '), { 'magenta' } },
            }
        end
    end,
}
basic.file_right = {
    text = function(_, _, width)
        if width < breakpoint_width then
            return {
                { b_components.line_col_lua, { 'white', 'black' } },
                { b_components.progress_lua },
            }
        end
    end,
}
basic.git = {
    name = 'git',
    width = breakpoint_width,
    text = function(bufnr)
        if git_comps.is_git(bufnr) then
            return {
                {
                    git_comps.diff_added({ format = '  %s', show_zero = true }),
                    { 'green', 'black' },
                },
                {
                    git_comps.diff_removed({ format = '  %s', show_zero = true }),
                    { 'red', 'black' },
                },
                {
                    git_comps.diff_changed({ format = ' 柳%s', show_zero = true }),
                    { 'blue' , 'black'},
                },
            }
        end
        return ''
    end,
}

local quickfix = {
    filetypes = { 'qf', 'Trouble' },
    active = {
        { '🚦 Quickfix ', { 'white', 'black' } },
        { helper.separators.slant_right, { 'black', 'black_light' } },
        {
            function()
                return vim.fn.getqflist({ title = 0 }).title
            end,
            { 'cyan', 'black_light' },
        },
        { ' Total : %L ', { 'cyan', 'black_light' } },
        { helper.separators.slant_right, { 'black_light', 'InactiveBg' } },
        { ' ', { 'InactiveFg', 'InactiveBg' } },
        { b_components.divider, '' },
        { helper.separators.slant_right, { 'InactiveBg', 'black' } },
        { '🧛 ', { 'white', 'black' } },
    },

    always_active = true,
    show_last_status = true,
}

local explorer = {
    filetypes = { 'fern', 'NvimTree', 'lir' },
    active = {
        { '  ', { 'black', 'red' } },
        { helper.separators.slant_right, { 'red', 'NormalBg' } },
        { b_components.divider, '' },
        { b_components.file_name(''), { 'white', 'NormalBg' } },
    },
    always_active = true,
    show_last_status = true,
}
local default = {
    filetypes = { 'default' },
    active = {
        basic.square_mode,
        basic.vi_mode,
        basic.file,
        basic.lsp_diagnos,
        basic.divider,
        basic.file_right,
        { lsp_comps.lsp_name(), { 'magenta', 'black' }, breakpoint_width },
        basic.git,
        { git_comps.git_branch(), { 'magenta', 'black' }, breakpoint_width },
        { ' ', hl_list.Black },
        basic.square_mode,
    },
    inactive = {
        { b_components.full_file_name, hl_list.Inactive },
        basic.file_name_inactive,
        basic.divider,
        basic.divider,
        { b_components.line_col, hl_list.Inactive },
        { b_components.progress, hl_list.Inactive },
    },
}

windline.setup({
    colors_name = function(colors)
        -- print(vim.inspect(colors))
        -- ADD MORE COLOR HERE ----
        return colors
    end,
    statuslines = {
        default,
        quickfix,
        explorer,
    },
})
