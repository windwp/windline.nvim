local Hsl = require('wlanimation.hsl')
local utils = require('wlanimation.utils')

-- local c_status = string.gsub(state.cache_status, "%#WL.*%#", ' ')
-- c_status = string.gsub(c_status, "%%[%-%w]*", ' ')
-- local max_text_length = vim.fn.winwidth(0) - vim.fn.strwidth(c_status)
-- local function iter_text(text, max_length, sep)
--     sep = sep or ' '
--     local idx = 0
--     local step = 1
--     local max = max_length - #text
--     return function()
--         local result = ''
--         if (idx >= max and step == 1)
--             or (idx == 0 and step == -1)
--         then
--             step = step * -1
--         end
--         for _ = 1, idx, 1 do result = result .. sep end
--         idx = idx + step
--         return result .. text
--     end
-- end

local flashyH = function(jump)
    local step = jump or 1
    return function(color)
        local  value = color.H + step
        if value > 360 then
            value = 360
            step = -jump
        end
        if value < 0 then
            value = 0
            step = jump
        end
        return Hsl.new(value, color.S, color.L)
    end
end

local flashyS = function(jump)
    local step = jump
    return function(color)
        local value = color.S + step
        if value > 1 then
            value = 1
            step = -jump
        end
        if value < 0 then
            value = 0
            step = jump
        end
        return Hsl.new(color.H, value, color.L)
    end
end

local flashyL = function(jump )
    local step = jump or 0.01
    return function(color)
        local value = color.L + step
        if value > 1 then
            value = 1
            step = -jump
        end
        if value < 0 then
            value = 0
            step = jump
        end
        return Hsl.new(color.H, color.S, value)
    end
end


local list_color = function(list_color, start)
    local tbl = {}
    local idx = start or 1
    for _, color in pairs(list_color) do
        table.insert(tbl, utils.rgb_to_hsl(color))
    end
    return function(_)
        local value = tbl[idx]
        idx = idx + 1
        if idx > #tbl then idx = 1 end
        return value
    end
end

local rainbow = function(start)
    return list_color({
        "#FF0000",
        "#FF8F00",
        "#FFFF00",
        "#00FF00",
        "#0000FF",
        "#2E2B5F",
        "#8B00FF"
    },start)
end
local blackwhite = function ()
    return flashyL(1)
end

-- we need a different value per animation but we cache a value if it is same
-- key ontick.
-- it need to sure animation have different per color name
local wrap = function (fnc)
    return function (...)
        local opt={...}
        return function()
            return fnc(unpack (opt))
        end
    end
end

return {
    rainbow    = wrap(rainbow),
    list_color = wrap(list_color),
    flashyL    = wrap(flashyL),
    flashyS    = wrap(flashyS),
    flashyH    = wrap(flashyH),
    blackwhite = wrap(blackwhite),
}
