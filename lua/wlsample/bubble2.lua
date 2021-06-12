local windline = require('windline')
local helper = require('windline.helpers')
local sep = helper.separators
local vim_components = require('windline.components.vim')

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

basic.divider = { b_components.divider, '' }
basic.space = { ' ', '' }
basic.bg = { ' ', 'StatusLine' }
basic.file_name_inactive = { b_components.full_file_name, hl_list.Inactive }
basic.line_col_inactive = { b_components.line_col, hl_list.Inactive }
basic.progress_inactive = { b_components.progress, hl_list.Inactive }

basic.vi_mode = {
    name = 'vi_mode',
    hl_colors = {
        Normal = { 'black', 'red', 'bold' },
        Insert = { 'black', 'green', 'bold' },
        Visual = { 'black', 'yellow', 'bold' },
        Replace = { 'black', 'blue_light', 'bold' },
        Command = { 'black', 'magenta', 'bold' },
        NormalBefore = { 'red', 'black' },
        InsertBefore = { 'green', 'black' },
        VisualBefore = { 'yellow', 'black' },
        ReplaceBefore = { 'blue_light', 'black' },
        CommandBefore = { 'magenta', 'black' },
        NormalAfter = { 'white', 'red' },
        InsertAfter = { 'white', 'green' },
        VisualAfter = { 'white', 'yellow' },
        ReplaceAfter = { 'white', 'blue_light' },
        CommandAfter = { 'white', 'magenta' },
    },
    text = function()
        return {
            { sep.left_rounded, state.mode[2] .. 'Before' },
            { state.mode[1] .. ' ', state.mode[2] },
        }
    end,
}

local check_lsp_status = lsp_comps.check_lsp({})
basic.lsp_diagnos = {
    name = 'diagnostic',
    hl_colors = {
        red = { 'red', 'black' },
        yellow = { 'yellow', 'black' },
        blue = { 'blue', 'black' },
    },
    text = function()
        if check_lsp_status() then
            return {
                { lsp_comps.lsp_error({ format = '  %s' }), 'red' },
                { lsp_comps.lsp_warning({ format = '  %s' }), 'yellow' },
                { lsp_comps.lsp_hint({ format = '  %s' }), 'blue' },
            }
        end
        return ''
    end,
}

basic.file = {
    name = 'file',
    hl_colors = {
        default = { 'white', 'black_light' },
    },
    text = function()
        return {
            { ' ', '' },
            { b_components.file_icon(''), 'default' },
            { ' ', '' },
            { b_components.file_name(''), '' },
            { b_components.file_modified(' '), '' },
            { b_components.file_size(), '' },
        }
    end,
}
basic.right = {
    hl_colors = {
        sep_before = { 'black_light', 'white_light' },
        sep_after = { 'white_light', 'black' },
        text = { 'black', 'white_light' },
    },
    text = function()
        return {
            -- { b_components.line_col, 'text' },
            { b_components.progress, 'text' },
            { sep.right_rounded, 'sep_after' },
        }
    end,
}
basic.git = {
    name = 'git',
    hl_colors = {
        green = { 'green', 'black' },
        red = { 'red', 'black' },
        blue = { 'blue', 'black' },
    },
    text = function()
        if git_comps.is_git() then
            return {
                { ' ', ' ' },
                { git_comps.diff_added({ format = ' %s' }), 'green' },
                { git_comps.diff_removed({ format = '  %s' }), 'red' },
                { git_comps.diff_changed({ format = ' 柳%s' }), 'blue' },
            }
        end
        return ''
    end,
}
basic.logo = {
    hl_colors = {
        sep_before = { 'blue', 'black' },
        default = { 'black', 'blue' },
    },
    text = function()
        return {
            { sep.left_rounded, 'sep_before' },
            { ' ', 'default' },
        }
    end,
}

local default = {
    filetypes = { 'default' },
    active = {
        { ' ', hl_list.Black },
        basic.logo,
        basic.file,
        { vim_components.search_count(), { 'red', 'white' } },
        { sep.right_rounded, { 'black_light', 'black' } },
        basic.lsp_diagnos,
        basic.git,
        basic.divider,
        { git_comps.git_branch({ icon = '  ' }), { 'green', 'black' } },
        {' ', hl_list.Black },
        basic.vi_mode,
        basic.right,
        { ' ', hl_list.Black },
    },
    in_active = {
        basic.file_name_inactive,
        basic.divider,
        basic.divider,
        basic.line_col_inactive,
        { '', { 'white', 'InactiveBg' } },
        basic.progress_inactive,
    },
}

windline.setup({
    colors_name = function(colors)
        -- ADD MORE COLOR HERE ----
        return colors
    end,
    statuslines = {
        default,
    },
})
