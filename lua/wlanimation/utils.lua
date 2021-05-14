local hsl = require('wlanimation.hsl')
local M = {}

M.get_hl_color = function(hl)
    local cmd = vim.api.nvim_exec('highlight ' .. hl, true)
    local _, _, bg = string.find(cmd, "guibg%=(%#%w*)")
    local _, _, fg = string.find(cmd, "guifg%=(%#%w*)")
    return fg, bg
end

---@return HSL
M.rgb_to_hsl = function(rgb)
    local h, s, l = hsl.rgb_string_to_hsl(rgb)
    return  hsl.new(h, s, l)
end

M.get_hsl_color = function(hl)
    local c1, c2 = M.get_hl_color(hl)
    local fg, bg
    if c1 then fg = M.rgb_to_hsl(c1) end
    if c2 then bg = M.rgb_to_hsl(c2) end
    return fg, bg
end

M.highlight = function(group, fg, bg)
    fg = fg and 'guifg=' .. fg:to_rgb() or 'guifg=NONE'
    bg = bg and 'guibg=' .. bg:to_rgb() or 'guibg=NONE'
    vim.api.nvim_command(string.format('highlight %s %s %s', group, fg, bg))
end

return M
