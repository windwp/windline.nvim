local utils = require('wlanimation.utils')
local w_utils = require('windline.utils')
local HSL = require('wlanimation.hsl')

local M = {}
--- @params animation Animation
local function tick(animation)
    local cache = {}
    --- all animation should have same value in 1 tick
    for _, value in pairs(animation.__state.hl) do
        local fg, bg = value.fg, value.bg
        if fg and not cache['fg' .. value.color] and value.fg_effect then
            cache['fg' .. value.color] = value.fg_effect(fg)
        end
        if bg and not cache['bg' .. value.color] and value.bg_effect then
            cache['bg' .. value.color] = value.bg_effect(bg)
        end

        if value.fg_effect then
            fg = cache['fg' .. value.color] or fg
        end

        if value.bg_effect then
            bg = cache['bg' .. value.color] or bg
        end

        if fg == false or bg == false then
            animation:stop()
            return
        end
        w_utils.highlight(value.name, {
            fg = fg and fg:to_rgb(),
            bg = bg and bg:to_rgb(),
        })
        value.fg = fg
        value.bg = bg
    end
end

local function stop(animation)
    for _, value in pairs(animation.__hl) do
        w_utils.highlight(value.name, {
            fg = value.fg and value.fg:to_rgb(),
            bg = value.bg and value.bg:to_rgb(),
        })
    end
end

--- @param opt AnimationOption
M.setup = function(opt)
    for _, group_name in pairs(opt.highlights) do
        local fg, bg = utils.get_hsl_color(group_name.name)
        table.insert(opt.__hl, {
            name = group_name.name,
            fg = fg,
            bg = bg,
        })
        table.insert(opt.__state.hl, {
            name = group_name.name,
            color = group_name.color,
            fg_effect = group_name.fg_effect,
            bg_effect = group_name.bg_effect,
            fg = fg and HSL.new(fg.H, fg.S, fg.L) or nil,
            bg = bg and HSL.new(bg.H, bg.S, bg.L) or nil,
        })
    end
    opt.__stop = stop
    opt.__tick = tick
end
return M
