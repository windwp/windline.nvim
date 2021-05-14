local windline = require('windline')
local helper = require('wlsample.helpers')
local sep = helper.separators
local animation = require('wlanimation')
local efffects = require('wlanimation.effects')

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
    text = function() return sep.right_rounded end,
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



local wave_left={
    hl_colors = {
        wave_blue1 = {'black', 'waveleft1'},
        wave_blue2 = {'waveleft1', 'waveleft2'},
        wave_blue3 = {'waveleft2', 'waveleft3'},
        wave_blue4 = {'waveleft3', 'waveleft4'},
        wave_blue5 = {'waveleft4', 'waveleft5'},
        wave_blue6 = {'waveleft5', 'wavewhite'},
    },
    text = function()
        return {
            {sep.right_rounded .. ' ', 'wave_blue1'},
            {sep.right_rounded .. ' ', 'wave_blue2'},
            {sep.right_rounded .. ' ', 'wave_blue3'},
            {sep.right_rounded .. ' ', 'wave_blue4'},
            {sep.right_rounded .. ' ', 'wave_blue5'},
            {sep.right_rounded .. ' ', 'wave_blue6'},
        }
    end
}

local wave_right={
    hl_colors = {
        wave_blue1 = {'waveright1', 'wavewhite'},
        wave_blue2 = {'waveright2', 'waveright1'},
        wave_blue3 = {'waveright3', 'waveright2'},
        wave_blue4 = {'waveright4', 'waveright3'},
        wave_blue5 = {'waveright5', 'waveright4'},
        wave_blue6 = {'black', 'waveright5'},
    },
    text = function()
        return {
            {' '..sep.left_rounded , 'wave_blue1'},
            {' '..sep.left_rounded , 'wave_blue2'},
            {' '..sep.left_rounded , 'wave_blue3'},
            {' '..sep.left_rounded , 'wave_blue4'},
            {' '..sep.left_rounded , 'wave_blue5'},
            {' '..sep.left_rounded , 'wave_blue6'},
        }
    end
}


local default = {
    filetypes={'default'},
    active={
        basic.vi_mode,
        basic.vi_mode_sep,
        {' ',''},
        basic.file_name,
        wave_left,
        {' ',{'FilenameBg', 'wavewhite'}},
        basic.divider,
        wave_right,
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
        colors.wavewhite = colors.white
        colors.waveleft1 = colors.blue
        colors.waveleft2 = colors.blue
        colors.waveleft3 = colors.blue
        colors.waveleft4 = colors.blue
        colors.waveleft5 = colors.blue

        colors.waveright1 = colors.blue
        colors.waveright2 = colors.blue
        colors.waveright3 = colors.blue
        colors.waveright4 = colors.blue
        colors.waveright5 = colors.blue
        return colors
    end,
    statuslines = {
        default
    }
})
local blue_colors={
    "#90CAF9",
    "#64B5F6",
    "#42A5F5",
    "#2196F3",
    "#1E88E5",
    "#1976D2",
    "#1565C0",
    "#0D47A1"
}


animation.stop_all()
animation.animation({
   data = {
        {'waveleft1',efffects.list_color(blue_colors,6)},
        {'waveleft2',efffects.list_color(blue_colors,5)},
        {'waveleft3',efffects.list_color(blue_colors,4)},
        {'waveleft4',efffects.list_color(blue_colors,3)},
        {'waveleft5',efffects.list_color(blue_colors,2)},
    },
    timeout = 100,
    delay = 200,
    interval = 150,
})



animation.animation({
   data = {
        {'waveright1',efffects.list_color(blue_colors,2)},
        {'waveright2',efffects.list_color(blue_colors,3)},
        {'waveright3',efffects.list_color(blue_colors,4)},
        {'waveright4',efffects.list_color(blue_colors,5)},
        {'waveright5',efffects.list_color(blue_colors,6)},
    },
    timeout = 100,
    delay = 200,
    interval = 150,
})


