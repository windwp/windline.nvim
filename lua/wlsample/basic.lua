local windline = require('windline')
local helper = require('wlsample.helpers')
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

basic.divider             = {"%=", ''}
basic.space                 = {' ', ''}
basic.line_col              = {[[ %3l:%-2c ]],hl_list.Black }
basic.progress              = {[[%3p%% ]], hl_list.Black}
basic.bg                    = {" ", 'StatusLine'}
basic.file_name_inactive    = {"%f", hl_list.Inactive}
basic.line_col_inactive     = {[[ %3l:%-2c ]], hl_list.Inactive}
basic.progress_inactive     = {[[%3p%% ]], hl_list.Inactive}

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
    hl = function (hl_data) return hl_data[state.mode[2]] end,
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
    hl = function (data) return data[state.mode[2]] end,
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
    show_in_active = true
}


basic.terminal_name = {
    text = function(bufnr)
        if bufnr == nil then return '' end
        bufnr = tonumber(bufnr)
        local bufname = vim.fn.expand(vim.fn.bufname(bufnr))
        return bufname:sub(#bufname -11,#bufname)
    end,
    hl_colors = hl_list.Inactive
}

basic.terminal_mode =  {
    name='terminal',
    text = function ()
        if
            vim.g.statusline_winid == vim.api.nvim_get_current_win()
            and state.mode[1] == 'TERMINAL'
        then
            return {
                {' ⚡ ', function(hl_data) return hl_data[state.mode[2]] end},
                {sep.slant_right, 'sep'}
            }
        end
        return {
            {' ⚡ ','empty'}
        }
    end,
    hl_colors = {
        sep     = {'red', 'InactiveBg'},
        Normal  = {'ActiveFg', 'ActiveBg'   } ,
        Command = {'white', 'red' } ,
        empty   = {'white', 'black'},
    },
}



local terminal = {
    filetypes = {'toggleterm'},
    active = {
        basic.terminal_mode,
        basic.terminal_name,
        basic.divider,
        basic.line_col_inactive,
        {sep.slant_right_thin,{'white','InactiveBg'}},
        basic.progress_inactive,
    },
    show_in_active = true
}

vim.g.windlinecount = 10
local count = {
  hl_colors = {
        countRed     = {'black', 'red'},
        countNormal  = {'black', 'green'}
  },
  hl = function(hl_colors)
      if vim.g.windlinecount > 50 then
        return hl_colors.countRed
      end
      return hl_colors.countNormal
  end,
  text = function(bufnr)
    vim.g.windlinecount = vim.g.windlinecount + 1
    if vim.g.windlinecount > 99 then
      vim.g.windlinecount = 10
    end
    return ' ' .. vim.fn.strftime("%H:%M:%S") .. ' '
  end,
}

local default = {
    filetypes={'default'},
    active={
        basic.vi_mode,
        basic.vi_mode_sep,
        {' ',''},
        basic.file_name,
        {sep.slant_right,{'FilenameBg', 'ActiveBg'}},
        basic.divider,
        {sep.slant_right,{'ActiveBg', 'black_light'}},
        {sep.slant_right,{'black_light', 'green_light'}},
        {sep.slant_right,{'green_light', 'blue_light'}},
        {sep.slant_right,{'blue_light', 'red_light'}},
        {sep.slant_right,{'red_light', 'cyan_light'}},
        {sep.slant_right,{'cyan_light', 'black'}},
        basic.line_col,
        basic.progress

    },
    in_active={
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
        colors.FilenameFg = colors.white_light
        colors.FilenameBg = colors.black_light
        return colors
    end,
    statuslines = {
        default,
        explorer,
        terminal
    }
})


animation.animation({
   data = {
        {'red_light',efffects.rainbow()},
        {'green_light',efffects.rainbow()},
        {'cyan_light',efffects.blackwhite()},
        {'FilenameBg',efffects.rainbow()},
        {'FilenameFg',efffects.blackwhite()}
    },
    timeout = nil,
    delay = 200,
    interval = 100,
})

