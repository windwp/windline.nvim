local windline = require('windline')
local effects = require('wlanimation.effects')
local HSL = require('wlanimation.utils')
require('wlsample.airline')
local animation = require('wlanimation')

local is_run = false

local function toggle_anim()
    if is_run then
        animation.stop_all()
        is_run = false
        return
    end
    is_run = true
    local magenta_anim={}
    local yellow_anim={}
    local blue_anim = {}
    local green_anim={}
    local red_anim = {}
    local colors = windline.get_colors()

    if vim.o.background == 'light' then
        magenta_anim = HSL.rgb_to_hsl(colors.magenta):tints(10,8)
        yellow_anim = HSL.rgb_to_hsl(colors.yellow):tints(10,8)
        blue_anim = HSL.rgb_to_hsl(colors.blue):tints(10, 8)
        green_anim = HSL.rgb_to_hsl(colors.green):tints(10,8)
        red_anim = HSL.rgb_to_hsl(colors.red):tints(10,8)
    else
        -- shades will create array of color from color to black color .I don't need
        -- black color then I only take 8
        magenta_anim = HSL.rgb_to_hsl(colors.magenta):shades(10,8)
        yellow_anim = HSL.rgb_to_hsl(colors.yellow):shades(10, 8)
        blue_anim = HSL.rgb_to_hsl(colors.blue):shades(10, 8)
        green_anim = HSL.rgb_to_hsl(colors.green):shades(10, 8)
        red_anim = HSL.rgb_to_hsl(colors.red):shades(10, 8)
    end

    animation.stop_all()
    animation.animation({
        data = {
            { 'magenta_a', effects.list_color(magenta_anim, 3) },
            { 'magenta_b', effects.list_color(magenta_anim, 2) },
            { 'magenta_c', effects.list_color(magenta_anim, 1) },

            { 'yellow_a', effects.list_color(yellow_anim, 3) },
            { 'yellow_b', effects.list_color(yellow_anim, 2) },
            { 'yellow_c', effects.list_color(yellow_anim, 1) },

            { 'blue_a', effects.list_color(blue_anim, 3) },
            { 'blue_b', effects.list_color(blue_anim, 2) },
            { 'blue_c', effects.list_color(blue_anim, 1) },

            { 'green_a', effects.list_color(green_anim, 3) },
            { 'green_b', effects.list_color(green_anim, 2) },
            { 'green_c', effects.list_color(green_anim, 1) },

            { 'red_a', effects.list_color(red_anim, 3) },
            { 'red_b', effects.list_color(red_anim, 2) },
            { 'red_c', effects.list_color(red_anim, 1) },
        },

        timeout = nil,
        delay = 200,
        interval = 150,
    })
end

WindLine.airline_anim_toggle = toggle_anim

vim.api.nvim_set_keymap('n', '<leader>u9', '<cmd>lua WindLine.airline_anim_toggle()<cr>', {})

-- make it run on startup
vim.defer_fn(function()
    toggle_anim()
end, 200)
