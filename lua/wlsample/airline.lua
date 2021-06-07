local windline = require('windline')
local helper = require('windline.helpers')
local sep = helper.separators
local b_components = require('windline.components.basic')
local state = _G.WindLine.state
local vim_components = require('windline.components.vim')

local lsp_comps = require('windline.components.lsp')
local git_comps = require('windline.components.git')

local hl_list = {
    Black = { 'white', 'black' },
    White = { 'black', 'white' },
    Normal = {'NormalFg', 'NormalBg'},
    Inactive = { 'InactiveFg', 'InactiveBg' },
    Active = { 'ActiveFg', 'ActiveBg' },
}
local basic = {}

basic.divider = { b_components.divider, hl_list.Normal }

local colors_mode_light = {
    Normal = { 'magenta', 'black_light' },
    Insert = { 'green', 'black_light' },
    Visual = { 'yellow', 'black_light' },
    Replace = { 'blue_light', 'black_light' },
    Command = { 'red', 'black_light' },
}

local colors_mode_rev = {
    Normal = { 'black', 'magenta' },
    Insert = { 'black', 'green' },
    Visual = { 'black', 'yellow' },
    Replace = { 'black', 'blue_light' },
    Command = { 'black', 'red' },
}

local hide_in_width = function()
    return vim.fn.winwidth(0) > 90
end

basic.vi_mode = {
    name = 'vi_mode',
    hl_colors = colors_mode_rev,
    text = function()
        return { { ' ' .. state.mode[1] .. ' ', state.mode[2] } }
    end,
}

basic.vi_mode_sep_left = {
    name = 'vi_mode',
    hl_colors = colors_mode_light,
    text = function()
        return { { sep.right_filled, state.mode[2] } }
    end,
}

local check_lsp_status = lsp_comps.check_lsp({})
basic.lsp_diagnos = {
    name = 'diagnostic',
    hl_colors = {
        red = { 'red', 'NormalBg' },
        yellow = { 'yellow', 'NormalBg' },
        blue = { 'blue', 'NormalBg' },
    },
    text = function()
        if hide_in_width() and check_lsp_status() then
            return {
                { ' ', 'red' },
                { lsp_comps.lsp_error({ format = ' %s', show_zero = true }), 'red' },
                { lsp_comps.lsp_warning({ format = '  %s', show_zero = true }), 'yellow' },
                { lsp_comps.lsp_hint({ format = '  %s', show_zero = true }), 'blue' },
            }
        end
        return { ' ', 'red' }
    end,
}

basic.right = {
    hl_colors = colors_mode_rev,
    text = function()
        return {
            { '', state.mode[2] },
            { b_components.progress, '' },
            { ' ', '' },
            { b_components.line_col, '' },
        }
    end,
}
basic.right_sep = {
    hl_colors = colors_mode_light,
    text = function()
        return {
            { sep.left_filled, state.mode[2] },
        }
    end,
}
local default = {
    filetypes = { 'default' },
    active = {
        basic.vi_mode,
        basic.vi_mode_sep_left,
        { git_comps.git_branch({}), { 'white_light', 'black_light' } },
        { ' ' .. sep.right .. ' ', '' },
        { b_components.file_name(), '' },
        { sep.right_filled, { 'black_light', 'NormalBg' } },
        basic.lsp_diagnos,
        {vim_components.search_count(),{"cyan", "NormalBg"}},
        basic.divider,
        { sep.left_filled, { 'black_light', 'NormalBg' } },
        { ' ', { 'white_light', 'black_light' } },
        { b_components.file_type({ icon = true }), '' },
        { ' ', '' },
        { b_components.file_encoding(), '' },
        { ' ', '' },
        { b_components.file_format({ icon = true }), { 'white_light', 'black_light' } },
        { ' ', '' },
        basic.right_sep,
        basic.right,
    },
    in_active = {
        { b_components.full_file_name, hl_list.Inactive },
        basic.divider,
        basic.divider,
        { b_components.line_col, hl_list.Inactive },
        { b_components.progress, hl_list.Inactive },
    },
}

windline.setup({
    statuslines = {
        default,
    },
})
