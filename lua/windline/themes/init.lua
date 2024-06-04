local M = {}

local cache_theme = {}

M.default_theme = nil

local get_default_theme = function()
    if vim.o.background == 'light' then
        return vim.deepcopy(M.default_theme or require('windline.themes.wind_light'))
    end
    return vim.deepcopy(M.default_theme or require('windline.themes.wind'))
end

M.load_theme = function(name)
    name = name or vim.g.colors_name
    if not name then return get_default_theme() end
    local cache_name = name .. '_' .. (vim.o.background or '')
    if cache_theme[cache_name] then
        return cache_theme[cache_name]
    end
    local colors
    if vim.o.background == 'light' then
        local ok, light_theme = pcall(require, 'windline.themes.' .. name ..'_light')
        if ok then
            colors = vim.deepcopy(light_theme)
        end
    end
    if not colors then
        local ok, themes_color = pcall(require, 'windline.themes.' .. name)
        if not ok then
            ok, colors = pcall(M.generate_theme)
            if not ok then colors = get_default_theme() end
        else
            colors = vim.deepcopy(themes_color)
        end
    end
    cache_theme[cache_name] = colors
    return colors
end

M.clear_cache = function()
    cache_theme = {}
end

M.get_hl_color = function(group_name)
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group_name })
    if not ok then return nil, nil end
    local fg = hl.fg and '#' .. bit.tohex(hl.fg, 6)
    local bg = hl.bg and '#' .. bit.tohex(hl.bg, 6)
    return fg, bg
end

local function is_dark(color_value)
    local bg_numeric_value = 0;
    for s in color_value:gmatch("[a-fA-F0-9][a-fA-F0-9]") do
        bg_numeric_value = bg_numeric_value + tonumber("0x"..s);
    end
    local is_dark_bg = (bg_numeric_value < 383)
    return is_dark_bg
end

M.generate_theme = function()
    local default = get_default_theme()
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

    if is_dark(colors.black) and vim.o.background == 'light'then
        -- swap some color to match light theme
        local tmp = colors.black
        colors.black = colors.white
        colors.white = tmp
        tmp = colors.black_light
        colors.black_light = colors.white_light
        colors.white_light =tmp
    end

    local fgNormal, bgNormal = M.get_hl_color('Normal')
    colors.NormalFg = fgNormal or colors.white_light
    colors.NormalBg = bgNormal or colors.black_light

    local fgInactive, bgInactive = M.get_hl_color('StatusLineNC')
    colors.InactiveFg = fgInactive or colors.white_light
    colors.InactiveBg = bgInactive or colors.black_light

    local fgActive, bgActive = M.get_hl_color('StatusLine')
    colors.ActiveFg = fgActive or colors.white
    colors.ActiveBg = bgActive or colors.black

    return vim.tbl_extend('keep', colors, default)
end

return M
