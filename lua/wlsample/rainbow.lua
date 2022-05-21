
local windline = require('windline')
local helper = require('windline.helpers')
local b_comps = require('windline.components.basic')

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
    text = function() return sep.right_rounded end,
    hl = function () return state.mode[2] end,
}

basic.file_name = {
    text = b_comps.file_name(),
    hl_colors = {'FilenameFg', 'FilenameBg'}
}

local sep_arrow_left = sep.right_filled

local arrow_left={
    hl_colors = {
        arrow_blue1 = {'black_light', 'arrowleft1'},
        arrow_blue2 = {'arrowleft1', 'arrowleft2'},
        arrow_blue3 = {'arrowleft2', 'arrowleft3'},
        arrow_blue4 = {'arrowleft3', 'arrowleft4'},
        arrow_blue5 = {'arrowleft4', 'arrowleft5'},
        arrow_blue6 = {'arrowleft5', 'arrowwhite'},
    },
    text = function()
        return {
            {sep_arrow_left .. '  ', 'arrow_blue1'},
            {sep_arrow_left .. '  ', 'arrow_blue2'},
            {sep_arrow_left .. '  ', 'arrow_blue3'},
            {sep_arrow_left .. '  ', 'arrow_blue4'},
            {sep_arrow_left .. '  ', 'arrow_blue5'},
            {sep_arrow_left .. '  ', 'arrow_blue6'},
        }
    end,
    click = function ()
        sep_arrow_left = 
        sep_arrow_left == sep.right_filled and sep.right_rounded or sep.right_filled
    end
}
local sep_arrow_right = sep.left_filled
local arrow_right={
    hl_colors = {
        arrow_blue1 = {'arrowright1', 'arrowwhite'},
        arrow_blue2 = {'arrowright2', 'arrowright1'},
        arrow_blue3 = {'arrowright3', 'arrowright2'},
        arrow_blue4 = {'arrowright4', 'arrowright3'},
        arrow_blue5 = {'arrowright5', 'arrowright4'},
        arrow_blue6 = {'black', 'arrowright5'},
    },
    text = function()
        return {
            {'  '..sep_arrow_right , 'arrow_blue1'},
            {'  '..sep_arrow_right , 'arrow_blue2'},
            {'  '..sep_arrow_right , 'arrow_blue3'},
            {'  '..sep_arrow_right , 'arrow_blue4'},
            {'  '..sep_arrow_right , 'arrow_blue5'},
            {'  '..sep.slant_left , 'arrow_blue6'},
        }
    end,
    click = function ()
        sep_arrow_right = 
        sep_arrow_right == sep.left_filled and sep.left_rounded or sep.left_filled
    end
}


local default = {
    filetypes={'default'},
    active={
        basic.vi_mode,
        basic.vi_mode_sep,
        {' ',''},
        basic.file_name,
        arrow_left,
        {' ',{'FilenameBg', 'arrowwhite'}},
        basic.divider,
        arrow_right,
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


local wave_left={
    name = "wave_left",
    hl_colors = {
        wave_blue1 = {'black_light', 'waveleft1'},
        wave_blue2 = {'waveleft1', 'waveleft2'},
        wave_blue3 = {'waveleft2', 'waveleft3'},
        wave_blue4 = {'waveleft3', 'waveleft4'},
        wave_blue5 = {'waveleft4', 'waveleft5'},
        wave_blue6 = {'waveleft5', 'black_light'},
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
    end,
}


local sep_right= sep.left_rounded
local wave_right={
    name = "wave_right",
    hl_colors = {
        wave_blue1 = {'waveright1', 'black_light'},
        wave_blue2 = {'waveright2', 'waveright1'},
        wave_blue3 = {'waveright3', 'waveright2'},
        wave_blue4 = {'waveright4', 'waveright3'},
        wave_blue5 = {'waveright5', 'waveright4'},
        wave_blue6 = {'black_light', 'waveright5'},
    },
    text = function()
        return {
            {' '..sep_right , 'wave_blue1'},
            {' '..sep_right , 'wave_blue2'},
            {' '..sep_right , 'wave_blue3'},
            {' '..sep_right , 'wave_blue4'},
            {' '..sep_right , 'wave_blue5'},
            {' '..sep_right , 'wave_blue6'},
        }
    end,
    click = function ()
        print("click is not working now")
        sep_right = sep.right_rounded
    end
}

local markdown = {
    filetypes={'markdown'},
    active={
        {sep.right_rounded,{'red','black_light'}},
        {' ',{'black_light','black_light'}},
        basic.divider,
        wave_right,
        basic.file_name,
        wave_left,
        basic.divider,
        {sep.left_rounded,{'red','black_light'}},
    },
    always_active=true,
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
        colors.arrowwhite = colors.black_light


        colors.arrowleft1 = colors.white
        colors.arrowleft2 = colors.white
        colors.arrowleft3 = colors.white
        colors.arrowleft4 = colors.white
        colors.arrowleft5 = colors.white

        colors.arrowright1 = colors.white
        colors.arrowright2 = colors.white
        colors.arrowright3 = colors.white
        colors.arrowright4 = colors.white
        colors.arrowright5 = colors.white

        colors.wavewhite = colors.white
        colors.waveleft1 = colors.white
        colors.waveleft2 = colors.white
        colors.waveleft3 = colors.white
        colors.waveleft4 = colors.white
        colors.waveleft5 = colors.white

        colors.waveright1 = colors.white
        colors.waveright2 = colors.white
        colors.waveright3 = colors.white
        colors.waveright4 = colors.white
        colors.waveright5 = colors.white
        return colors
    end,
    statuslines = {
        default,
        markdown

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
        {'arrowleft1',efffects.rainbow(6)},
        {'arrowleft2',efffects.rainbow(5)},
        {'arrowleft3',efffects.rainbow(4)},
        {'arrowleft4',efffects.rainbow(3)},
        {'arrowleft5',efffects.rainbow(2)},
    },
    timeout = 100,
    delay = 200,
    interval = 150,
})



animation.animation({
   data = {
        {'arrowright1',efffects.rainbow(2)},
        {'arrowright2',efffects.rainbow(3)},
        {'arrowright3',efffects.rainbow(4)},
        {'arrowright4',efffects.rainbow(5)},
        {'arrowright5',efffects.rainbow(6)},
    },
    timeout = 100,
    delay = 200,
    interval = 150,
})



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
