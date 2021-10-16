local windline = require('windline')
local helper = require('windline.helpers')
local sep = helper.separators
local b_components = require('windline.components.basic')
local state = _G.WindLine.state

local animation = require('wlanimation')
local efffects = require('wlanimation.effects')

local hl_list = {
    Black = { 'white', 'black' },
    White = { 'black', 'white' },
    Normal = { 'NormalFg', 'NormalBg' },
    Inactive = { 'InactiveFg', 'InactiveBg' },
    Active = { 'ActiveFg', 'ActiveBg' },
}
local basic = {}

local luffy_text = ''
basic.divider = { b_components.divider, hl_list.Normal }

local colors_mode_rev = {
    Normal = { 'black', 'magenta' },
    Insert = { 'black', 'green' },
    Visual = { 'black', 'yellow' },
    Replace = { 'black', 'blue_light' },
    Command = { 'black', 'red' },
}


basic.vi_mode = {
    name = 'vi_mode',
    hl_colors = colors_mode_rev,
    text = function()
        return { { luffy_text .. ' ' .. state.mode[1] .. ' ', state.mode[2] } }
    end,
}
basic.right = {
    hl_colors = colors_mode_rev,
    text = function()
        return {
            { ' ', state.mode[2] },
            { b_components.progress },
            { ' '},
            { b_components.line_col },
        }
    end,
}
local default = {
    filetypes = { 'default' },
    active = {
        basic.vi_mode,
        { ' ', { 'white', 'NormalBg' } },
        { b_components.cache_file_name('[No Name]', 'unique')},
        basic.divider,
        { b_components.cache_file_type({ icon = true }), '' },
        { ' ' },
        { b_components.file_format({ icon = true }), { 'white', 'NormalBg' } },
        { ' ' },
        { b_components.file_encoding(), '' },
        { ' ' },
        basic.right,
    },
    inactive = {
        { b_components.full_file_name, hl_list.Inactive },
        basic.divider,
        { b_components.line_col, hl_list.Inactive },
        { b_components.progress, hl_list.Inactive },
    },
}
-- 􏾾􏾿􏿀􏿁􏿂􏿃
windline.setup({
    statuslines = {
        default,
    },
})
-- need to use font family: Fira Code iCursive S12
-- https://github.com/windwp/windline.nvim/wiki/fonts/FiraCodeiCursiveS12-Regular.ttf
local luffy = { '􏾾', '􏾿', '􏿀', '􏿁', '􏿂', '􏿃' }
animation.stop_all()
animation.basic_animation({
    timeout = nil,
    delay = 200,
    interval = 150,
    effect = efffects.list_text(luffy),
    on_tick = function(value)
        luffy_text = value
    end,
})
