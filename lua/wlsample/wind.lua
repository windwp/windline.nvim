local windline = require('windline')
local helper = require('windline.helpers')
local utils = require('windline.utils')
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

utils.change_mode_name({
    ['n'] = { ' NORMAL', 'Normal' },
    ['no'] = { ' O-PENDING', 'Visual' },
    ['nov'] = { ' O-PENDING', 'Visual' },
    ['noV'] = { ' O-PENDING', 'Visual' },
    ['no'] = { ' O-PENDING', 'Visual' },
    ['niI'] = { ' NORMAL', 'Normal' },
    ['niR'] = { ' NORMAL', 'Normal' },
    ['niV'] = { ' NORMAL', 'Normal' },
    ['v'] = { ' VISUAL', 'Visual' },
    ['V'] = { ' V-LINE', 'Visual' },
    [''] = { ' V-BLOCK', 'Visual' },
    ['s'] = { ' SELECT', 'Visual' },
    ['S'] = { ' S-LINE', 'Visual' },
    [''] = { ' S-BLOCK', 'Visual' },
    ['i'] = { ' INSERT', 'Insert' },
    ['ic'] = { ' INSERT', 'Insert' },
    ['ix'] = { ' INSERT', 'Insert' },
    ['R'] = { ' REPLACE', 'Replace' },
    ['Rc'] = { ' REPLACE', 'Replace' },
    ['Rv'] = { 'V-REPLACE', 'Normal' },
    ['Rx'] = { ' REPLACE', 'Normal' },
    ['c'] = { ' COMMAND', 'Command' },
    ['cv'] = { ' COMMAND', 'Command' },
    ['ce'] = { ' COMMAND', 'Command' },
    ['r'] = { ' REPLACE', 'Replace' },
    ['rm'] = { ' MORE', 'Normal' },
    ['r?'] = { ' CONFIRM', 'Normal' },
    ['!'] = { ' SHELL', 'Normal' },
    ['t'] = { ' TERMINAL', 'Command' },
})

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
        wave_blue1 = {'black_light', 'waveleft1'},
        wave_blue2 = {'waveleft1', 'waveleft2'},
        wave_blue3 = {'waveleft2', 'waveleft3'},
        wave_blue4 = {'waveleft3', 'waveleft4'},
        wave_blue5 = {'waveleft4', 'waveleft5'},
        wave_blue6 = {'waveleft5', 'wavedefault'},
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
        wave_blue1 = {'waveright1', 'wavedefault'},
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
        {' ',{'FilenameBg', 'wavedefault'}},
        basic.divider,
        wave_right,
        basic.line_col,
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
        colors.FilenameFg = colors.white_light
        colors.FilenameBg = colors.black_light

        colors.wavedefault = colors.white_light
        colors.waveleft1 = colors.wavedefault
        colors.waveleft2 = colors.wavedefault
        colors.waveleft3 = colors.wavedefault
        colors.waveleft4 = colors.wavedefault
        colors.waveleft5 = colors.wavedefault

        colors.waveright1 = colors.wavedefault
        colors.waveright2 = colors.wavedefault
        colors.waveright3 = colors.wavedefault
        colors.waveright4 = colors.wavedefault
        colors.waveright5 = colors.wavedefault
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


