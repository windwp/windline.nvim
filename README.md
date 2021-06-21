# Windline
 The next generation statusline for neovim

 * custom statusline for filetype
 * built-in animation library
 * change colors with colorscheme
 * simple syntax

## demo
  display 3 different status line on lua, vim and markdown file

 ![swap](https://github.com/windwp/windline.nvim/wiki/screenshot/demo_swap_3.gif)

 ![Mutlifiletype](https://github.com/windwp/windline.nvim/wiki/screenshot/mutli_filetype.gif)
  display an animation statusline to markdown and lua file.


# Intro

Firstly create a statusline in lua is easy and you can do it with some line
code. There are many lua statusline but they do the same thing of vimscript statusline.
It doesn't have anything new

Windline is a first statusline support change statusline per filetype.
You can write a statusline for any filetype.
`terminal,nvimtree, qf,spectre,lsptrouble,diffview,lspoutline`.
If you write a plugin you can define a statusline for your plugin.
It support to display status on **inactive window**

```lua

local yourstatus = {
    filetypes = {'lspcrazy'},
    active = {
        {' lspcrazy ', {'white', 'black'} },
        {function() return 'crazy' end ,{'black', 'red'} },
    },
    show_in_active = true
}

```

We offer an built-in animation color library for statusline.
I know it is not useful but why not :).

It is not loaded if you don't use animation.


# Setup

```lua
local windline = require('windline')
windline.setup({
  statuslines = {
    --- you need define your status line here
  }
})

```

![Bubble](https://github.com/windwp/windline.nvim/wiki/screenshot/demo_bubble.png)
[bubble line](./lua/wlsample/bubble.lua)
```lua
require('wlsample.bubble')
```
---
![Bubble2](https://github.com/windwp/windline.nvim/wiki/screenshot/demo_bubble2.png)
[bubble line](./lua/wlsample/bubble2.lua)
```lua
require('wlsample.bubble2')
```
---
![evilline](https://raw.githubusercontent.com/wiki/windwp/windline.nvim/screenshot/eviline.png)
[evil line](./lua/wlsample/evil_line.lua)
```lua
require('wlsample.evil_line')
```
---
![airline](https://raw.githubusercontent.com/wiki/windwp/windline.nvim/screenshot/airline2.png)
[airline](./lua/wlsample/airline.lua)
```lua
require('wlsample.airline')
```
---
![basic animation](https://github.com/windwp/windline.nvim/wiki/screenshot/demo_basic.gif)
[basic animation](./lua/wlsample/basic.lua)
```lua
require('wlsample.basic')
```
---
![wind animation](https://github.com/windwp/windline.nvim/wiki/screenshot/demo_wave.gif)
[wind animation](./lua/wlsample/wind.lua)

```lua
require('wlsample.wind')
```
---
![luffy animation](https://github.com/windwp/windline.nvim/wiki/screenshot/airline_luffy.gif)
[luffy](./lua/wlsample/airline_luffy.lua)

```lua
require('wlsample.airline_luffy')
```

Remember windline can change status line per filetype so you can have bubble
line for markdown or latex file and airline for your working file.

![Swap](https://github.com/windwp/windline.nvim/wiki/screenshot/demo_swap.gif)

# Status line

You need to define a default statusline it will apply to all filetypes.
```lua
local default = {
    filetypes={'default'},
    active={
      --- component...
    },
    in_active={
      --- component...
    }
}

local explorer = {
    filetypes = {'fern', 'NvimTree','netrw'},
    active = {
        {'  ', {'white', 'black'} },
    },
    show_in_active = true
    -- set this mean if it is inactive it still display same as active mode
}

```

# components
An component define with {text ,{ fgcolor, bgcolor } }

```lua

local default = {
    filetypes={'default'},
    active={
      --- component...
      {'[',{'red', 'black'}},
      {'%f',{'green','black'}},
      {']',{'red','black'}},

      -- use empty mean it use same color with component above
      {"%=", ''} ,

      -- use a hightlight group
      {' ','StatusLine'},

      {' %3l:%-2c ',{'white','black'}}
    },
}
```
![demo](https://github.com/windwp/windline.nvim/wiki/screenshot/simple_comp.png)

**Every component have own hightlight name define in `hl_colors` function**

**A text function has a bufnr parameter and you can use it to get data from buffer**


A text function can return a group of child component.
Child component share `hl_colors` data with parent component.

```lua
local lsp_comps = require('windline.components.lsp')
basic.lsp_diagnos = {
    name = 'diagnostic',
    hl_colors = {
        -- we need define color name here to cache value
        -- then we use it on child of group
        red = { 'red', 'black' },
        yellow = { 'yellow', 'black' },
        blue = { 'blue', 'black' },
    },
    text = function(bufnr)
        if lsp_comps.check_lsp() then
            return {
                -- `red` is define in hl_colors or a hightlight group name
                { lsp_comps.lsp_error({ format = '  %s' }), 'red' },
                { lsp_comps.lsp_warning({ format = '  %s' }), 'yellow' },
                { lsp_comps.lsp_hint({ format = '  %s' }), 'blue' },
            }
        end
        return ''
    end,
}
```

Windline doesn't have a component condition just return it to empty or nil to
make it disappear

# Colors
Windline use a terminal color. It generate from your colorscheme terminal.
Every time you change colorschemes it will be generate a new colors to map
with your colorscheme

![demo](https://github.com/windwp/windline.nvim/wiki/screenshot/demo_colorscheme.gif)

Color name is use to define component and animation

``` lua
-- sample
local colors = {
  black         = "",  -- terminal_color_0,
  red           = "",  -- terminal_color_1,
  green         = "",  -- terminal_color_2,
  yellow        = "",  -- terminal_color_3,
  blue          = "",  -- terminal_color_4,
  magenta       = "",  -- terminal_color_5,
  cyan          = "",  -- terminal_color_6,
  white         = "",  -- terminal_color_7,
  black_light   = "",  -- terminal_color_8,
  red_light     = "",  -- terminal_color_9,
  yellow_light  = "",  -- terminal_color_10,
  blue_light    = "",  -- terminal_color_11,
  magenta_light = "",  -- terminal_color_12,
  green_light   = "",  -- terminal_color_13,
  cyan_light    = "",  -- terminal_color_14,
  white_light   = "",  -- terminal_color_15,

  NormalFg      = "",  -- hightlight Normal fg
  NormalBg      = "",  -- hightlight Normal bg
  ActiveFg      = "",  -- hightlight StatusLine fg
  ActiveBg      = "",  -- hightlight StatusLine bg
  InactiveFg    = "",  -- hightlight StatusLineNc fg
  InactiveBg    = "",  -- hightlight StatusLineNc bg
}
return colors
```

If you need to define a new name of color to use on animation you need define
on colors_name function

```lua

local windline = require('windline')

windline.setup({

  colors_name = function(colors)
      --- add more color
      colors.FilenameFg = colors.white_light
      colors.FilenameBg = colors.black

      -- this color will not update if you change a colorscheme
      colors.gray = "#fefefe"
      return colors
  end,

})
```

## animation
animation with colors_name from colors above
``` lua
animation.animation({
   data = {
        {'red_light',efffects.rainbow()},
        {'green_light',efffects.rainbow()},
        {'cyan_light',efffects.blackwhite()},
        {'FilenameBg',efffects.rainbow()},
        {'FilenameFg',efffects.blackwhite()}
    },
    timeout = 10,
    delay = 200,
    interval = 100,
})

you can create multi animation but only list of data on animation is sync
```

### effects

| Usage                      | KEY                                   |
|----------------------------|---------------------------------------|
| rainbow()                  | a rainbow animation color             |
| blackwhite()               | toggle between black and white        |
| list_color({..list_color}) | swap color from list                  |
| flashyH([number 0-360])    | increase H on every step of animation |
| flashyS([number 0.01 - 1)  | increase S on every step of animation |
| flashyL([number 0.01 - 1)  | increase L on every step of animation |

```lua
-- you can write your own effect
local Hsl = require('wlanimation.hsl')
animation.animation({
   data = {
        {'red',efffects.wrap(function(color)
            return HSL.new(color.H + 1, color.S, color.L)
        end)},
    },
    timeout = 100,
    delay = 200,
    interval = 100,
})
```

## Tabline
add tabline config in setup then it will enable a tabline
```lua
windline.setup({
  tabline = { }
})

-- change seprator of tab
windline.setup({
  tabline = {
    seperator={
      main =">",
      sub = "|"
    }
  }
})
```

[config tabline](./lua/wltabline/init.lua)
