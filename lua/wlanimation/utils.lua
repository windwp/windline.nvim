local hsl = require('wlanimation.hsl')
local get_hl_color = require('windline.themes').get_hl_color
local M = {}

---@return HSL
M.rgb_to_hsl = function(rgb)
    local h, s, l = hsl.rgb_string_to_hsl(rgb)
    return hsl.new(h, s, l, rgb)
end

M.get_hsl_color = function(hl)
    local c1, c2 = get_hl_color(hl)
    local fg, bg
    if c1 then fg = M.rgb_to_hsl(c1) end
    if c2 then bg = M.rgb_to_hsl(c2) end
    return fg, bg
end


return M
