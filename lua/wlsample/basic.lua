local windline = require('windline')

local b_components = require('windline.components.basic')

local helper = require('windline.helpers')
local sep = helper.separators
local animation = require('wlanimation')
local efffects = require('wlanimation.effects')

animation.stop_all()

local state = _G.WindLine.state

local hl_list = {
    Black    = {'white'      , 'black'      } ,
    Inactive = {'InactiveFg' , 'InactiveBg' } ,
    Active   = {'ActiveFg'   , 'ActiveBg' }   ,
}
local basic = {}

basic.divider             = {b_components.divider, ''}
basic.space                 = {' ', ''}
basic.line_col              = {b_components.line_col, hl_list.Black }
basic.progress              = {b_components.progress, hl_list.Black}
basic.file_name_inactive    = {b_components.full_file_name, hl_list.Inactive}
basic.line_col_inactive     = {b_components.line_col, hl_list.Inactive}
basic.progress_inactive     = {b_components.progress, hl_list.Inactive}

basic.vi_mode= {
    name = 'vi_mode',
    hl_colors = {
            Normal  = {'white', 'black'  },
            Insert  = {'black', 'red'    },
            Visual  = {'black', 'green'  },
            Replace = {'black', 'cyan'   },
            Command = {'black', 'yellow' },
        } ,
    text = function() return ' ' .. state.mode[1] .. ' ' end,
    hl = function () return state.mode[2] end,
}

basic.vi_mode_sep =  {
    name = 'vi_mode_sep',
    hl_colors = {
            Normal  = {'black', 'FilenameBg'},
            Insert  = {'red', 'FilenameBg'},
            Visual  = {'green', 'FilenameBg'},
            Replace = {'cyan', 'FilenameBg'},
            Command = {'yellow', 'FilenameBg'},
        }
    ,
    text = function() return '' end,
    hl = function () return state.mode[2] end,
}

basic.file_name = {
    text = function ()
        local name     = vim.fn.expand('%:p:t')
        if name == '' then name = '[No Name]' end
        return name..  ' '
    end,
    hl_colors = {'FilenameFg', 'FilenameBg'}
}

basic.explorer_name = {
    name = 'explorer_name',
    text = function(bufnr)
        if bufnr == nil then return '' end
        local bufname = vim.fn.expand(vim.fn.bufname(bufnr))
        local _,_, bufnamemin = string.find(bufname,[[%/([^%/]*%/[^%/]*);%$$]])
        if bufnamemin ~= nil and #bufnamemin > 1 then return bufnamemin end
        return bufname
    end,
    hl_colors = hl_list.Active
}

local explorer = {
    filetypes = {'fern', 'NvimTree'},
    active = {
        {'  ', {'white', 'black'} },
        {helper.separators.slant_right, {'black', 'ActiveBg'} },
        basic.divider,
        basic.explorer_name,
    },
    always_active = true
}

local default = {
    filetypes={'default'},
    active={
        basic.vi_mode,
        basic.vi_mode_sep,
        {' ',''},
        basic.file_name,
        {sep.slant_right,{'FilenameBg', 'black_light'}},
        basic.divider,
        {sep.slant_right,{'black_light', 'green_light'}},
        {sep.slant_right,{'green_light', 'blue_light'}},
        {sep.slant_right,{'blue_light', 'red_light'}},
        {sep.slant_right,{'red_light', 'cyan_light'}},
        {sep.slant_right,{'cyan_light', 'black'}},
        basic.line_col,
        {sep.slant_right_thin,{'white', 'black'}},
        basic.progress

    },
    inactive={
        basic.file_name_inactive,
        basic.divider,
        basic.divider,
        basic.line_col_inactive,
        {'',{'white', 'InactiveBg'}},
        basic.progress_inactive,
    }
}


windline.setup({
    colors_name = function(colors)
        -- ADD MORE COLOR HERE ----
        colors.FilenameFg = colors.white_light
        colors.FilenameBg = colors.black_light
        return colors
    end,
    statuslines = {
        default,
        explorer
    }
})


animation.animation({
   data = {
        {'red_light',efffects.rainbow()},
        {'green_light',efffects.rainbow()},
        {'cyan_light',efffects.blackwhite()},
        {'FilenameBg',efffects.rainbow()}, --- animation for filename only
        {'FilenameFg',efffects.blackwhite()}
    },
    timeout = nil,
    delay = 200,
    interval = 100,
})

-- run <leader>x to update color
vim.api.nvim_set_keymap('n','<leader>x',':luafile %<cr>',{})
