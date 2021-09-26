local M = {}
local fn = vim.fn
local api = vim.api
local helper = require('windline.helpers')
local utils = require('windline.utils')
local cache_utils = require('windline.cache_utils')
local themes = require('windline.themes')
local ffi_convert = require('wlfloatline.ffi_convert')

M.divider = '%='
M.line_col = [[ %3l:%-2c ]]
M.progress = [[%3p%%]]
M.full_file_name = '%f'

M.progress_lua = function()
    local line_fraction = math.floor(vim.fn.line('.') / vim.fn.line('$') * 100)
        .. '%%'
    return utils.str_rpad(line_fraction, 5, ' ')
end

M.line_col_lua = function(_, winid,_,is_floatline)
    if is_floatline then winid = 0 end
    local row, col = unpack(vim.api.nvim_win_get_cursor(winid or 0))
    return string.format(' %s:%s ', utils.str_rpad(row, 3), utils.str_lpad(col, 2))
end

M.ffi_convert = function(status)
    return function (_,_,_, is_floatline)
        if is_floatline then
            local item = ffi_convert.get_stl_string(status) or ''
            -- something weird with lua string need to double %
            return item:gsub("%%",'%%%%')
        end
        return status
    end
end

M.progress_ffi = M.ffi_convert(M.progress)
M.line_col_ffi = M.ffi_convert(M.line_col)

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

---@return any
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

---@return any
M.cache_file_type = function(opt)
    return cache_utils.cache_on_buffer('FileType', 'WL_filetype', M.file_type(opt))
end

M.file_size = function()
    return function()
        local file = fn.expand('%:p')
        if string.len(file) == 0 then
            return ''
        end
        local suffix = { 'b', 'k', 'M', 'G', 'T', 'P', 'E' }
        local index = 1

        local fsize = fn.getfsize(file)
        if fsize < 1 then
            return ''
        end
        while fsize > 1024 and index < 7 do
            fsize = fsize / 1024
            index = index + 1
        end

        return string.format('%.2f', fsize) .. suffix[index]
    end
end

---@return any
M.cache_file_size = function()
    return cache_utils.cache_on_buffer('BufWritePost', 'WL_filesize', M.file_size())
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
            local bg = WindLine.state.colors[opt.hl_colors[2]]
            utils.highlight(highlight, { guifg = fg, guibg = bg })
        end
        return {icon or opt.default, highlight }
    end
end

M.file_modified = function(icon)
    if icon then
        return function()
            if vim.bo.modified or vim.bo.modifiable == false then
                return icon
            end
        end
    end
    return '%m'
end

return M
