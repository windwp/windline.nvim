local M = {}
local fn = vim.fn
local api = vim.api
local helper = require('windline.helpers')
local utils = require('windline.utils')
local cache_utils = require('windline.cache_utils')
local themes = require('windline.themes')

M.divider = '%='
M.line_col = [[ %3l:%-2c ]]
M.progress = [[%3p%%]]
M.full_file_name = '%f'

M.progress_lua = function(_,_,_, is_global)
    if is_global == nil then  return M.progress end
    local line_fraction = math.floor(vim.fn.line('.') / vim.fn.line('$') * 100)
        .. '%%'
    return string.format("%5s",line_fraction)
end

M.line_col_lua = function(_, _,_,is_global)
    if is_global == nil then  return M.line_col end
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    return string.format(' %3s:%-2s ', row, col + 1)
end


local function get_buf_name(modify, shorten)
    return function(bufnr)
        local bufname = fn.bufname(bufnr)
        bufname = fn.fnamemodify(bufname, modify)
        if shorten then
            return fn.pathshorten(bufname)
        end
        return bufname
    end
end

M.file_name = function(default, modify)
    default = default or '[No Name]'
    modify = modify or 'name'
    local fnc_name = get_buf_name(':t')
    if modify == 'unique' then
        fnc_name = utils.get_unique_bufname
    elseif modify == 'full' then
        fnc_name = get_buf_name('%:p', true)

    end
    return function(bufnr)
        local name = fnc_name(bufnr)
        if name == '' then
            name = default
        end
        return name .. ' '
    end
end

M.cache_file_name = function(default, modify)
    return cache_utils.cache_on_buffer('BufEnter', 'WL_filename', M.file_name(default, modify))
end

M.file_type = function(opt)
    opt = opt or {}
    local default = opt.default or '  '
    return function(bufnr)
        local file_name = fn.fnamemodify(fn.bufname(bufnr), ':t')
        local file_ext = fn.fnamemodify(file_name, ':e')
        local icon = opt.icon and helper.get_icon(file_name, file_ext) or ''
        local filetype = api.nvim_buf_get_option(bufnr, 'filetype')
        if filetype == '' then
            return default
        end
        if icon ~= '' then
            return icon .. ' ' .. filetype
        end
        return filetype
    end
end

M.cache_file_type = function(opt)
    return cache_utils.cache_on_buffer('FileType', 'WL_filetype', M.file_type(opt))
end

M.file_size = function(opt)
    opt = opt or {}

    local unit_factor = opt.base == nil and 1000
        or opt.base == 10 and 1000
        or opt.base == 2 and 1024

    local clamped_precision = opt.precision == nil and 2
        or opt.precision < 0 and 0
        or opt.precision > 16 and 16
        or opt.precision

    local precision_factor = math.pow(10, clamped_precision)

    local suffixes = {
        'B',
        'kB',
        'MB',
        'GB',
        'TB',
        'PB',
        'EB',
    }

    return function()
        local path = vim.api.nvim_buf_get_name(0)

        if string.len(path) == 0 then
            return ''
        end

        local size = vim.fn.getfsize(path)

        if size < 1 then
            return ''
        end

        local index = 1

        while
            size >= unit_factor
            and index < #suffixes
        do
            size = size / unit_factor
            index = index + 1
        end

        local rounded_size = math.ceil(size * precision_factor - 0.5) / precision_factor

        return rounded_size .. suffixes[index]
    end
end

M.cache_file_size = function(opt)
    return cache_utils.cache_on_buffer('BufWritePost', 'WL_filesize', M.file_size(opt))
end

local format_icons = {
    unix = '', -- e712
    dos = '', -- e70f
    mac = '', -- e711
}

M.file_format = function(opt)
    opt = opt or {}
    if opt.icon then
        return function()
            return format_icons[vim.bo.fileformat] or vim.bo.fileformat
        end
    end
    return function()
        return vim.bo.fileformat
    end
end

function M.file_encoding()
    return function()
        local enc = (vim.bo.fenc ~= '' and vim.bo.fenc) or vim.o.enc
        return enc:upper()
    end
end

M.cache_file_icon = function(opt)
    return cache_utils.cache_on_buffer('FileType', 'WL_fileicon', M.file_icon(opt))
end

M.file_icon = function(opt)
    opt = opt or { default = '' }
    return function(bufnr)
        local file_name = fn.fnamemodify(fn.bufname(bufnr), ':t')
        local file_ext = fn.fnamemodify(file_name, ':e')
        local icon, hl = helper.get_icon(file_name, file_ext)
        if not opt.hl_colors then
            return hl ~= 'DevIconDefault' and icon or opt.default
        end
        if file_ext == "" then file_ext = nil end
        local highlight = string.format('WL%s_%s',opt.hl_colors[1], opt.hl_colors[2])
        if hl == 'DevIconDefault' then
            return { opt.default, highlight }
        end
        if hl then
            highlight = string.format('WL%s_%s', file_ext, opt.hl_colors[2])
            local fg = themes.get_hl_color(hl)
            local bg = utils.get_color(WindLine.state.colors, opt.hl_colors[2])
            utils.highlight(highlight, { fg = fg, bg = bg })
        end
        return {icon or opt.default, highlight }
    end
end

M.file_modified = function(icon, is_buffer)
    if icon and is_buffer then
        return function(bufnr)
            if vim.bo[bufnr].modified and vim.bo[bufnr].modifiable then
                return icon
            end
        end
    end
    if icon then
        return function()
            if vim.bo.modified and vim.bo.modifiable then
                return icon
            end
        end
    end
    return '%m'
end

return M
