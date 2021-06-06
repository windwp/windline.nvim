local M = {}
local fn = vim.fn
local helper = require('windline.helpers')

M.divider = '%='
M.line_col = [[ %3l:%-2c ]]
M.progress = [[%3p%%]]
M.full_file_name = '%f'

M.file_name = function(opt)
    opt = opt or{}
    local default = opt.default or '[No Name]'
    return function(bufnr)
        local name = vim.fn.fnamemodify(vim.fn.bufname(bufnr), ':t')
        if name == '' then
            name = default
        end
        return name .. ' '
    end
end

M.file_type = function(opt)
    opt = opt or{}
    local default = opt.default or '  '
    return function(bufnr)
        local file_name = vim.fn.fnamemodify(vim.fn.bufname(bufnr), ':t')
        local file_ext = vim.fn.fnamemodify(file_name, ":e")
        local icon = opt.icon and helper.get_icon(file_name, file_ext) or ''
        local filetype = vim.bo.filetype
        if filetype == '' then
            return default
        end
        return string.format(" %s %s ", icon, filetype):lower()
    end
end

M.file_size = function()
    return function()
        local suffix = { 'b', 'k', 'M', 'G', 'T', 'P', 'E' }
        local index = 1

        local fsize = fn.getfsize(fn.expand('%:p'))

        while fsize > 1024 and index < 7 do
            fsize = fsize / 1024
            index = index + 1
        end

        return string.format('%.2f', fsize) .. suffix[index]
    end
end

local format_icons = {
    unix = '', -- e712
    dos = '', -- e70f
    mac = '',  -- e711
}

M.file_format = function(opt)
    opt = opt or{}
    if opt.icon then
        return function()
            return format_icons[vim.bo.fileformat] or vim.bo.fileformat
        end
    end
    return function()
        return vim.bo.fileformat
    end
end

M.file_icon = function(default)
    default = default or ''
    return function (bufnr)
        local file_name = vim.fn.fnamemodify(vim.fn.bufname(bufnr), ':t')
        local file_ext = vim.fn.fnamemodify(file_name, ":e")
        return helper.get_icon(file_name, file_ext) or default
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
