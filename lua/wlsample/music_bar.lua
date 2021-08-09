local windline = require('windline')
local animation = require('wlanimation')
local efffects = require('wlanimation.effects')

local BLOCKS_DATA = {
    '▁',
    '▂',
    '▃',
    '▄',
    '▅',
    '▆',
    '▇',
    '█',
    '█',
    '▇',
    '▆',
    '▅',
    '▄',
    '▃',
    '▂',
    '▁',
}

local blocks = {}
local winwidth = vim.api.nvim_win_get_width(0)
print(vim.inspect(winwidth))
local item = {}
local basic = {}

local num_block = (winwidth - 1) / #BLOCKS_DATA

for _ = 1, num_block do
    for _, v in ipairs(BLOCKS_DATA) do
        table.insert(blocks, v)
    end
end

basic.up = {
    hl_colors = {
        block1 = { 'block1', 'NormalBg' },
        block2 = { 'block2', 'NormalBg' },
        block3 = { 'block3', 'NormalBg' },
        block4 = { 'block4', 'NormalBg' },
        block5 = { 'block5', 'NormalBg' },
        block6 = { 'block6', 'NormalBg' },
    },
    text = function()
        local tbl = {}
        local color = 1
        for _, v in ipairs(item) do
            color = color + 1
            table.insert(tbl, { v, 'block' .. color })
            if color == 6 then
                color = 0
            end
        end
        return tbl
    end,
}

local default = {
    filetypes = { 'default' },
    active = {
        basic.up,
    },
    in_active = {
        { '', '' },
    },
}
windline.setup({
    colors_name = function(colors)
        colors.block1 = colors.blue
        colors.block2 = colors.blue
        colors.block3 = colors.blue
        colors.block4 = colors.blue
        colors.block5 = colors.blue
        colors.block6 = colors.blue

        return colors
    end,
    statuslines = {
        default,
    },
})

local maxNum = #blocks
local num = maxNum

animation.stop_all()
animation.basic_animation({
    timeout = nil,
    delay = 200,
    interval = 250,
    effect = function()
        num = num - 1
        if num < 1 then
            num = maxNum
        end
        return num
    end,
    on_tick = function(value)
        local tbl = {}
        for i = value, maxNum do
            table.insert(tbl, blocks[i])
        end
        for i = 1, value do
            table.insert(tbl, blocks[maxNum - i])
        end
        item = tbl
    end,
})

animation.animation({
    data = {
        { 'block1', efffects.rainbow( 6) },
        { 'block2', efffects.rainbow( 5) },
        { 'block3', efffects.rainbow( 4) },
        { 'block4', efffects.rainbow( 3) },
        { 'block5', efffects.rainbow( 2) },
    },
    timeout = 100,
    delay = 200,
    interval = 250,
})
