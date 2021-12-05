local windline = require('windline')
local b_components = require('windline.components.basic')
local vim_components = require('windline.components.vim')
local git_rev_components = require('windline.components.git_rev')

local state = _G.WindLine.state
local utils = require('windline.utils')

local lsp_comps = require('windline.components.lsp')
local git_comps = require('windline.components.git')

local hl_list = {
    Inactive = { 'InactiveFg', 'InactiveBg' },
    Active = { 'ActiveFg', 'ActiveBg' },
    default = { 'StatusFg', 'StatusBg' },
}
local basic = {}

local medium_width = 100
local large_width = 140
basic.divider = { b_components.divider, '' }

-- stylua: ignore
utils.change_mode_name({
    ['n']    = { ' -- Normal -- '   , 'Normal'  } ,
    ['no']   = { ' -- Visual -- '   , 'Visual'  } ,
    ['nov']  = { ' -- Visual -- '   , 'Visual'  } ,
    ['noV']  = { ' -- Visual -- '   , 'Visual'  } ,
    ['no'] = { ' -- Visual -- '   , 'Visual'  } ,
    ['niI']  = { ' -- Normal -- '   , 'Normal'  } ,
    ['niR']  = { ' -- Normal -- '   , 'Normal'  } ,
    ['niV']  = { ' -- Normal -- '   , 'Normal'  } ,
    ['v']    = { ' -- Visual -- '   , 'Visual'  } ,
    ['V']    = { ' -- Visual -- '   , 'Visual'  } ,
    ['']   = { ' -- Visual -- '   , 'Visual'  } ,
    ['s']    = { ' -- Visual -- '   , 'Visual'  } ,
    ['S']    = { ' -- Visual -- '   , 'Visual'  } ,
    ['']   = { ' -- Visual -- '   , 'Visual'  } ,
    ['i']    = { ' -- Insert -- '   , 'Insert'  } ,
    ['ic']   = { ' -- Insert -- '   , 'Insert'  } ,
    ['ix']   = { ' -- Insert -- '   , 'Insert'  } ,
    ['R']    = { ' -- Replace -- '  , 'Replace' } ,
    ['Rc']   = { ' -- Replace -- '  , 'Replace' } ,
    ['Rv']   = { ' -- Normal -- '   , 'Normal'  } ,
    ['Rx']   = { ' -- Normal -- '   , 'Normal'  } ,
    ['c']    = { ' -- Commmand -- ' , 'Command' } ,
    ['cv']   = { ' -- Commmand -- ' , 'Command' } ,
    ['ce']   = { ' -- Commmand -- ' , 'Command' } ,
    ['r']    = { ' -- Replace -- '  , 'Replace' } ,
    ['rm']   = { ' -- Normal -- '   , 'Normal'  } ,
    ['r?']   = { ' -- Normal -- '   , 'Normal'  } ,
    ['!']    = { ' -- Normal -- '   , 'Normal'  } ,
    ['t']    = { ' -- Normal -- '   , 'Command' } ,
    ['nt']   = { ' -- Terminal -- ' , 'Command' } ,
})

basic.vi_mode = {
    name = 'vi_mode',
    hl_colors = hl_list.default,
    text = function()
        return state.mode[1]
    end,
}

basic.lsp_diagnos = {
    name = 'diagnostic',
    hl_colors = hl_list.default,
    width = large_width,
    text = function(bufnr)
        if lsp_comps.check_lsp(bufnr) then
            -- stylua: ignore
            return {
                { lsp_comps.lsp_error({ format = '  %s', show_zero = true }), '' },
                { lsp_comps.lsp_warning({ format = '  %s', show_zero = true }), '' },
            }
        end
        return ''
    end,
}

basic.file = {
    name = 'file_name',
    text = function()
        return {
            { b_components.cache_file_name('', 'unique'), '' },
            { b_components.file_modified(' ') },
        }
    end,
}

local line_col = function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    return string.format(' Ln %3s, Col %-2s ', row, col + 1)
end

local spaces = function()
    return 'Spaces: ' .. vim.api.nvim_buf_get_option(0, 'shiftwidth') .. ' '
end

local line_format = function()
    local format_icons = {
        unix = 'LF',
        dos = 'CRLF',
        mac = 'LF',
    }
    return function()
        return format_icons[vim.bo.fileformat] or vim.bo.fileformat
    end
end

basic.line_col_right = {
    hl_colors = hl_list.default,
    text = function(_, _, width)
        if
            vim.api.nvim_buf_get_option(0, 'filetype') == ''
            and vim.fn.wordcount().bytes < 1
        then
            return ''
        end
        if width > medium_width then
            return {
                { line_col },
                { spaces },
                { b_components.file_encoding() },
                { ' ' },
                { line_format() },
                { ' ' },
            }
        end
        return {
            { line_col, '' },
        }
    end,
}

basic.lsp_name = {
    width = medium_width,
    name = 'lsp_name',
    text = function(bufnr)
        if lsp_comps.check_lsp(bufnr) then
            return {
                { lsp_comps.lsp_name() },
            }
        end
        return {
            { b_components.cache_file_type({ icon = true, default = '' }) },
        }
    end,
}

basic.git_branch = {
    name = 'git_branch',
    hl_colors = hl_list.default,
    width = medium_width,
    text = function(bufnr)
        if git_comps.is_git(bufnr) then
            return {
                { git_comps.git_branch(), hl_list.default, large_width },
                {
                    git_rev_components.git_rev(),
                    hl_list.default,
                    large_width,
                },
            }
        end
        return ''
    end,
}

local explorer = {
    filetypes = { 'fern', 'NvimTree', 'lir' },
    active = {
        { '  ', hl_list.Inactive },
        { b_components.divider },
        { b_components.file_name('') },
    },
    always_active = true,
    show_last_status = true,
}

local default = {
    filetypes = { 'default' },
    active = {
        basic.git_branch,
        basic.lsp_diagnos,
        basic.vi_mode,
        { vim_components.search_count() },
        basic.divider,
        { ' ' },
        basic.file,
        basic.line_col_right,
        { ' ' },
        basic.lsp_name,
    },
    inactive = {
        { b_components.full_file_name, hl_list.Inactive },
        basic.file_name_inactive,
        basic.divider,
        basic.divider,
        { b_components.line_col, hl_list.Inactive },
        { b_components.progress, hl_list.Inactive },
    },
}

local M = {}
M.setup = function()
    windline.setup({
        colors_name = function(colors)
            colors.StatusFg = colors.ActiveFg
            colors.StatusBg = colors.ActiveBg
            return colors
        end,
        statuslines = {
            default,
            explorer,
        },
    })
end

M.setup()

M.change_color = function(bgcolor, fgcolor)
    local colors = windline.get_colors()
    colors.StatusFg = fgcolor or colors.StatusFg
    colors.StatusBg = bgcolor or colors.StatusBg
    windline.on_colorscheme(colors)
end

return M
