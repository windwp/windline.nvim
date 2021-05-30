local M = {}

local cache_theme = {}

M.default_them = nil

M.load_theme = function(name)
    name = name or vim.g.colors_name
    if cache_theme[name] then
        return cache_theme[name]
    end
    if not name then
        return M.default_theme or require('windline.themes.wind')
    end

    local ok, colors = pcall(require, 'windline.themes.' .. name)
    if not ok then
        ok, colors = pcall(M.generate_theme)
        if not ok then
            colors = M.default_theme or require('windline.themes.wind')
        end
    end

    cache_theme[name] = colors
    return colors
end

M.get_hl_color = function(hl)
    local cmd = vim.api.nvim_exec('highlight ' .. hl, true)
    local _, _, bg = string.find(cmd, "guibg%=(%#%w*)")
    local _, _, fg = string.find(cmd, "guifg%=(%#%w*)")
    return fg, bg
end


M.generate_theme = function ()

    local default = M.default_theme or require('windline.themes.wind')
    local colors = {
        black                  = vim.g.terminal_color_0,
        red                    = vim.g.terminal_color_1,
        green                  = vim.g.terminal_color_2,
        yellow                 = vim.g.terminal_color_3,
        blue                   = vim.g.terminal_color_4,
        magenta                = vim.g.terminal_color_5,
        cyan                   = vim.g.terminal_color_6,
        white                  = vim.g.terminal_color_7,
        black_light            = vim.g.terminal_color_8,
        red_light              = vim.g.terminal_color_9,
        green_light            = vim.g.terminal_color_10,
        yellow_light           = vim.g.terminal_color_11,
        blue_light             = vim.g.terminal_color_12,
        magenta_light          = vim.g.terminal_color_13,
        cyan_light             = vim.g.terminal_color_14,
        white_light            = vim.g.terminal_color_15,
    }

    local fgInactive,bgInactive = M.get_hl_color('StatusLineNC')
    colors.InactiveFg = fgInactive or colors.white_light
    colors.InactiveBg = bgInactive or colors.black_light

    local fgActive,bgActive = M.get_hl_color('StatusLine')
    colors.ActiveFg = fgActive or colors.white
    colors.ActiveBg = bgActive or colors.black

    return vim.tbl_extend('force',default,colors)
end

return M
