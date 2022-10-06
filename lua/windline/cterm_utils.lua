-- https://stackoverflow.com/questions/38045839/lua-xterm-256-colors-gradient-scripting
--
local abs, min, max, floor = math.abs, math.min, math.max, math.floor
local levels = { [0] = 0x00, 0x5f, 0x87, 0xaf, 0xd7, 0xff }

local function index_0_5(value) -- value = color component 0..255
    return floor(max((value - 35) / 40, value / 58))
end

local function nearest_16_231(r, g, b) -- r, g, b = 0..255
    -- returns color_index_from_16_to_231, appr_r, appr_g, appr_b
    r, g, b = index_0_5(r), index_0_5(g), index_0_5(b)
    return 16 + 36 * r + 6 * g + b, levels[r], levels[g], levels[b]
end

local function nearest_232_255(r, g, b) -- r, g, b = 0..255
    local gray = (3 * r + 10 * g + b) / 14
    -- this is a rational approximation for well-known formula
    -- gray = 0.2126 * r + 0.7152 * g + 0.0722 * b
    local index = min(23, max(0, floor((gray - 3) / 10)))
    gray = 8 + index * 10
    return 232 + index, gray, gray, gray
end

local function color_distance(r1, g1, b1, r2, g2, b2)
    return abs(r1 - r2) + abs(g1 - g2) + abs(b1 - b2)
end

local function rgb2cterm(hex_color)
    if type(hex_color) == "number" then
        return hex_color
    end
    local r = tonumber(hex_color:sub(2, 3), 16)
    local g = tonumber(hex_color:sub(4, 5), 16)
    local b = tonumber(hex_color:sub(6, 7), 16)
    local idx1, r1, g1, b1 = nearest_16_231(r, g, b)
    local idx2, r2, g2, b2 = nearest_232_255(r, g, b)
    local dist1 = color_distance(r, g, b, r1, g1, b1)
    local dist2 = color_distance(r, g, b, r2, g2, b2)
    return dist1 < dist2 and idx1 or idx2
end

return {
    rgb2cterm = rgb2cterm
}
