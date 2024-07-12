local hsl = require('wlanimation.hsl')
local get_hl_color = require('windline.themes').get_hl_color
local M = {}

---@return HSL
M.rgb_to_hsl = function(rgb)
    if rgb == nil or #rgb ~= 7 then return hsl.new(0, 0, 0, '') end
    return hsl.new(rgb)
end

---@return string
M.shade_or_tint = function(rgb, value)
    if rgb == nil or #rgb ~= 7 then return rgb end
    if vim.o.background == 'light' then
        return hsl.new(rgb):shade(value):to_rgb()
    end
    return hsl.new(rgb):tint(value):to_rgb()
end

M.get_hsl_color = function(hl)
    local c1, c2 = get_hl_color(hl)
    local fg, bg
    if c1 then fg = M.rgb_to_hsl(c1) end
    if c2 then bg = M.rgb_to_hsl(c2) end
    return fg, bg
end


return M
