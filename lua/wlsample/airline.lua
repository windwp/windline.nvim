local windline = require('windline')
local helper = require('windline.helpers')
local sep = helper.separators
local b_components = require('windline.components.basic')
local state = _G.WindLine.state
local vim_components = require('windline.components.vim')
local HSL = require('wlanimation.utils')

local lsp_comps = require('windline.components.lsp')
local git_comps = require('windline.components.git')

local hl_list = {
    Black = { 'white', 'black' },
    White = { 'black', 'white' },
    Normal = { 'NormalFg', 'NormalBg' },
    Inactive = { 'InactiveFg', 'InactiveBg' },
    Active = { 'ActiveFg', 'ActiveBg' },
}
local basic = {}

local airline_colors = {}

airline_colors.a = {
    NormalSep = { 'magenta_a', 'magenta_b' },
    InsertSep = { 'green_a', 'green_b' },
    VisualSep = { 'yellow_a', 'yellow_b' },
    ReplaceSep = { 'blue_a', 'blue_b' },
    CommandSep = { 'red_a', 'red_b' },
    Normal = { 'black', 'magenta_a' },
    Insert = { 'black', 'green_a' },
    Visual = { 'black', 'yellow_a' },
    Replace = { 'black', 'blue_a' },
    Command = { 'black', 'red_a' },
}

airline_colors.b = {
    NormalSep = { 'magenta_b', 'magenta_c' },
    InsertSep = { 'green_b', 'green_c' },
    VisualSep = { 'yellow_b', 'yellow_c' },
    ReplaceSep = { 'blue_b', 'blue_c' },
    CommandSep = { 'red_b', 'red_c' },
    Normal = { 'white', 'magenta_b' },
    Insert = { 'white', 'green_b' },
    Visual = { 'white', 'yellow_b' },
    Replace = { 'white', 'blue_b' },
    Command = { 'white', 'red_b' },
}

airline_colors.c = {
    NormalSep = { 'magenta_c', 'NormalBg' },
    InsertSep = { 'green_c', 'NormalBg' },
    VisualSep = { 'yellow_c', 'NormalBg' },
    ReplaceSep = { 'blue_c', 'NormalBg' },
    CommandSep = { 'red_c', 'NormalBg' },
    Normal = { 'white', 'magenta_c' },
    Insert = { 'white', 'green_c' },
    Visual = { 'white', 'yellow_c' },
    Replace = { 'white', 'blue_c' },
    Command = { 'white', 'red_c' },
}

basic.divider = { b_components.divider, hl_list.Normal }

local width_breakpoint = 100
local check_width = function()
    return vim.fn.winwidth(0) > width_breakpoint
end

basic.section_a = {
    hl_colors = airline_colors.a,
    text = function()
        if check_width() then
            return {
                { ' ' .. state.mode[1] .. ' ', state.mode[2] },
                { sep.right_filled, state.mode[2] .. 'Sep' },
            }
        end
        return {
            { ' ' .. state.mode[1]:sub(1, 1) .. ' ', state.mode[2] },
            { sep.right_filled, state.mode[2] .. 'Sep' },
        }
    end,
}

local get_git_branch = git_comps.git_branch()

basic.section_b = {
    hl_colors = airline_colors.b,
    text = function()
        local branch_name = get_git_branch()
        if check_width() and #branch_name > 1 then
            return {
                { branch_name , state.mode[2] },
                { ' ', '' },
                { sep.right_filled, state.mode[2] .. 'Sep' },
            }
        end
        return { { sep.right_filled, state.mode[2] .. 'Sep' } }
    end,
}


basic.section_c = {
    hl_colors = airline_colors.c,
    text = function()
        return {
            { ' ', state.mode[2] },
            { b_components.cache_file_name('[No Name]', 'unique'), '' },
            { ' ', '' },
            { sep.right_filled, state.mode[2] .. 'Sep' },
        }
    end,
}

basic.section_x = {
    hl_colors = airline_colors.c,
    text = function()
        return {
            { sep.left_filled, state.mode[2] .. 'Sep' },
            { ' ', state.mode[2] },
            { b_components.file_encoding(), '' },
            { ' ', '' },
            { b_components.file_format({ icon = true }) },
            { ' ', '' },
        }
    end,
}

basic.section_y = {
    hl_colors = airline_colors.b,
    text = function()
        if check_width() then
            return {
                { sep.left_filled, state.mode[2] .. 'Sep' },
                { b_components.file_type({ icon = true }), state.mode[2] },
                { ' ', '' },
            }
        end
        return { { sep.left_filled, state.mode[2] .. 'Sep' } }
    end,
}

basic.section_z = {
    hl_colors = airline_colors.a,
    text = function()
        return {
            { sep.left_filled, state.mode[2] .. 'Sep' },
            { '', state.mode[2] },
            { b_components.progress, '' },
            { ' ', '' },
            { b_components.line_col, '' },
        }
    end,
}

basic.lsp_diagnos = {
    name = 'diagnostic',
    hl_colors = {
        red = { 'red', 'NormalBg' },
        yellow = { 'yellow', 'NormalBg' },
        blue = { 'blue', 'NormalBg' },
    },
    width = width_breakpoint,
    text = function()
        if check_width() and lsp_comps.check_lsp() then
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

basic.git = {
    name = 'git',
    width = width_breakpoint,
    hl_colors = {
        green = { 'green', 'NormalBg' },
        red = { 'red', 'NormalBg' },
        blue = { 'blue', 'NormalBg' },
    },
    text = function()
        if git_comps.is_git() then
            return {
                { ' ', '' },
                { git_comps.diff_added({ format = ' %s' }), 'green' },
                { git_comps.diff_removed({ format = '  %s' }), 'red' },
                { git_comps.diff_changed({ format = ' 柳%s' }), 'blue' },
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
        basic.divider,
        { helper.separators.slant_right, { 'InactiveBg', 'black' } },
        { '🧛 ', { 'white', 'black' } },
    },
    show_in_active = true,
}

local explorer = {
    filetypes = { 'fern', 'NvimTree', 'lir' },
    active = {
        { '  ', { 'white', 'black' } },
        { helper.separators.slant_right, { 'black', 'black_light' } },
        { b_components.divider, '' },
        { b_components.file_name(''), { 'white', 'black_light' } },
    },
    show_in_active = true,
    show_last_status = true
}

local default = {
    filetypes = { 'default' },
    active = {
        basic.section_a,
        basic.section_b,
        basic.section_c,
        basic.lsp_diagnos,
        { vim_components.search_count(), { 'cyan', 'NormalBg' } },
        basic.divider,
        basic.git,
        basic.section_x,
        basic.section_y,
        basic.section_z,
    },
    in_active = {
        { b_components.full_file_name, hl_list.Inactive },
        { b_components.divider, hl_list.Inactive },
        { b_components.line_col, hl_list.Inactive },
        { b_components.progress, hl_list.Inactive },
    },
}

windline.setup({
    colors_name = function(colors)
        colors.magenta_a = colors.magenta
        colors.magenta_b = HSL.rgb_to_hsl(colors.magenta):shade(0.5):to_rgb()
        colors.magenta_c = HSL.rgb_to_hsl(colors.magenta):shade(0.7):to_rgb()

        colors.yellow_a = colors.yellow
        colors.yellow_b = HSL.rgb_to_hsl(colors.yellow):shade(0.5):to_rgb()
        colors.yellow_c = HSL.rgb_to_hsl(colors.yellow):shade(0.7):to_rgb()

        colors.blue_a = colors.blue
        colors.blue_b = HSL.rgb_to_hsl(colors.blue):shade(0.5):to_rgb()
        colors.blue_c = HSL.rgb_to_hsl(colors.blue):shade(0.7):to_rgb()

        colors.green_a = colors.green
        colors.green_b = HSL.rgb_to_hsl(colors.green):shade(0.5):to_rgb()
        colors.green_c = HSL.rgb_to_hsl(colors.green):shade(0.7):to_rgb()

        colors.red_a = colors.red
        colors.red_b = HSL.rgb_to_hsl(colors.red):shade(0.5):to_rgb()
        colors.red_c = HSL.rgb_to_hsl(colors.red):shade(0.7):to_rgb()

        return colors
    end,
    statuslines = {
        default,
        quickfix,
        explorer,
    },
})
