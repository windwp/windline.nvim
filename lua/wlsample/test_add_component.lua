---@diagnostic disable: undefined-field, undefined-global
local windline = require('windline')
local helper = require('windline.helpers')
local sep = helper.separators
local b_components = require('windline.components.basic')
local state = _G.WindLine.state
local HSL = require('wlanimation.utils')

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

basic.divider = { b_components.divider, hl_list.Normal }

basic.section_a = {
    name = 'section_a',
    hl_colors = airline_colors.a,
    text = function()
        return {
            { ' ' .. state.mode[1] .. ' ', state.mode[2] },
        }
    end,
}

basic.section_z = {
    name = 'section_z',
    hl_colors = airline_colors.a,
    text = function()
        return {
            { ' ', state.mode[2] },
            { b_components.progress, '' },
            { ' ', '' },
            { b_components.line_col, '' },
        }
    end,
}

local language = 'EN'
basic.language = {
    text = function()
        return {
            { 'LANG: ', '' },
            {
                language,
                '',
                windline.make_click('change_language', function()
                    language = language == 'EN' and 'US' or 'EN'
                end),
            },
        }
    end,
}

local default = {
    filetypes = { 'default' },
    active = {
        basic.section_a,
        basic.divider,
        basic.section_z,
        basic.language,
    },
    inactive = {},
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
    },
})

local animation = require('wlanimation')
local effects = require('wlanimation.effects')
WindLine.test_add_comp = function()
    animation.stop_all()

    local green_anim = {}
    windline.add_component({
        name = 'test',
        hl_colors = {
            wave_green1 = { 'black', 'green_a' },
            wave_green2 = { 'green_a', 'green_b' },
            wave_green3 = { 'green_b', 'green_c' },
            wave_green4 = { 'green_c', 'black' },
            default = { 'black', 'black' },
        },
        text = function()
            return {
                { ' ', 'default' },
                { sep.slant_right .. '  ', 'wave_green1' },
                { sep.slant_right .. '  ', 'wave_green2' },
                { sep.slant_right .. '  ', 'wave_green3' },
                { sep.slant_right .. '  ', 'wave_green4' },
                { ' ', 'default' },
            }
        end,
    }, {
        filetype = 'default',
        position = 'right',
        colors_name = function(colors)
            colors.green_a = colors.NormalBg
            colors.green_b = HSL.rgb_to_hsl(colors.NormalBg):shade(0.5):to_rgb()
            colors.green_c = HSL.rgb_to_hsl(colors.NormalBg):shade(0.7):to_rgb()
            return colors
        end,
    })

    local colors = windline.get_colors()
    green_anim = HSL.rgb_to_hsl(colors.green):shades(10, 8)
    animation.animation({
        data = {
            { 'green_a', effects.list_color(green_anim, 3) },
            { 'green_b', effects.list_color(green_anim, 2) },
            { 'green_c', effects.list_color(green_anim, 1) },
        },

        timeout = nil,
        delay = 200,
        interval = 150,
    })
end

WindLine.test_remove_comp = function()
    animation.stop_all()
    windline.remove_component({ name = 'test', filetype = 'default' })
end

vim.api.nvim_set_keymap(
    'n',
    '<leader>x',
    '<cmd>lua WindLine.test_add_comp()<cr>',
    {}
)
vim.api.nvim_set_keymap(
    'n',
    '<leader>z',
    '<cmd>lua WindLine.test_remove_comp()<cr>',
    {}
)

-- test add_component auto
WindLine.test_remove_auto = function()
    windline.remove_auto_component({ name = 'autocmd_md', autocmd = true })
end

WindLine.test_add_auto = function()
    windline.add_autocmd_component({
        text = function()
            return 'auto cmd on markdown'
        end,
    }, {
        filetype = 'markdown',
        position = 'right',
        name = 'autocmd_md',
    })
end

vim.api.nvim_set_keymap(
    'n',
    '<leader>aa',
    '<cmd>lua WindLine.test_add_auto()<cr>',
    {}
)

vim.api.nvim_set_keymap(
    'n',
    '<leader>ar',
    '<cmd>lua WindLine.test_remove_auto()<cr>',
    {}
)
