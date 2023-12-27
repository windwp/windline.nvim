# Windline
Animation statusline. Use lua + luv make some 🔥🔥🔥

**Features**:

 * custom statusline for every file type
 * built-in animation library
 * change colors with your colorscheme
 * fast and powerful customization
 * custommize display of global statusline

## demo

![demo](https://github.com/windwp/windline.nvim/wiki/screenshot/mutli_filetype.gif)
Displaying two different animated status line (markdown and lua file types).

# Intro
Windline supports having a different status line per file type.
`terminal,nvimtree,qf,help,spectre,lsptrouble,diffview,lspoutline`.
It also supports displaying a different status line on **inactive windows**

We offer a built-in animations and color library for status line.
I know it is not useful but why not :).

It is not loaded if you don't use animations.

![demo](https://github.com/windwp/windline.nvim/wiki/screenshot/windline-notify.gif)


# Setup

You can create your own custom status line, using as a base/example the [included status line setups](./lua/wlsample) is recommended for new users.

```lua
local windline = require('windline')
windline.setup({
  statuslines = {
    --- you need to define your status lines here
  }
})


```

## Included Status lines
You can also use any of this status lines and avoid setting up your own *(skipping the example above)* by just requiring it.

### [bubble line](./lua/wlsample/bubble.lua)
![Bubble](https://github.com/windwp/windline.nvim/wiki/screenshot/demo_bubble.png)
```lua
require('wlsample.bubble')
```
---
### [bubble line](./lua/wlsample/bubble2.lua)
![Bubble2](https://github.com/windwp/windline.nvim/wiki/screenshot/demo_bubble2.png)
```lua
require('wlsample.bubble2')
```
---

### [evil line](./lua/wlsample/evil_line.lua)
![evilline](https://raw.githubusercontent.com/wiki/windwp/windline.nvim/screenshot/eviline.png)
```lua
require('wlsample.evil_line')
```
---

### [airline](./lua/wlsample/airline.lua)
![airline](https://raw.githubusercontent.com/wiki/windwp/windline.nvim/screenshot/airline2.png)
```lua
require('wlsample.airline')
--  the animated alternative. you can toggle animation by press `<leader>u9`
require('wlsample.airline_anim')
```
---
### [vscode](./lua/wlsample/vscode.lua)
![vscode](https://raw.githubusercontent.com/wiki/windwp/windline.nvim/screenshot/vscode.png)
```lua
require('wlsample.vscode')
```
---
### [basic animation](./lua/wlsample/basic.lua)
![basic animation](https://github.com/windwp/windline.nvim/wiki/screenshot/demo_basic.gif)
```lua
require('wlsample.basic')
```
---

### [wind animation](./lua/wlsample/wind.lua)
![wind animation](https://github.com/windwp/windline.nvim/wiki/screenshot/demo_wave.gif)

```lua
require('wlsample.wind')
```
---

### [luffy](./lua/wlsample/airline_luffy.lua)
![luffy animation](https://github.com/windwp/windline.nvim/wiki/screenshot/airline_luffy.gif)

```lua
require('wlsample.airline_luffy')
```

### [cava]
![cava animation](https://github.com/windwp/windline.nvim/wiki/screenshot/cava.gif)

```lua
-- only support linux it need install cava
lua require("windline.components.cava").toggle()
```


Remember windline can display  a different status line per file type,
so you can have bubble line for markdown or latex file, and airline
for your working file.

You need install [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) to get git information.

![Swap](https://github.com/windwp/windline.nvim/wiki/screenshot/demo_swap.gif)

# Status line

You need to define a default status line that will be used on all
filetypes that do not define a custom one.

```lua
local default = {
    filetypes={'default'},
    active={
      --- components...
    },
    inactive={
      --- components...
    }
}

local explorer = {
    filetypes = {'fern', 'NvimTree','netrw'},
    active = {
        {'  ', {'white', 'black'} },
    },
    --- show active components when the window is inactive
    always_active = true,
    --- It will display a last window statusline even that window should inactive
    show_last_status = true
}

```

# components
A component is defined as `{text ,{ fgcolor, bgcolor } }`

```lua

local default = {
    filetypes={'default'},
    active={
      --- components...
      {'[',{'red', 'black'}},
      {'%f',{'green','black'}},
      {']',{'red','black'}},

      -- empty color definition uses the previous component colors
      {"%=", ''} ,

      -- hightlight groups can also be used
      {' ','StatusLine'},

      {' %3l:%-2c ',{'white','black'}}
    },
}
```
![demo](https://github.com/windwp/windline.nvim/wiki/screenshot/simple_comp.png)

**A `text` function has a bufnr and winid parameter that can be used to get data from the buffer or window**

A **text** function can return a group of child components

```lua
local lsp_comps = require('windline.components.lsp')

basic.lsp_diagnos = {
    name = 'diagnostic',
    hl_colors = {
        red_text = {'red', 'black'}
    },
    text = function(bufnr, winid, width)
        if lsp_comps.check_lsp() then
            return {

                { '[ lsp: ', 'red_text' },
                -- red_text define in hl_colors. It make easy cache value first
                -- because text function run multiple time on redraw

                { lsp_comps.lsp_name() , 'IncSearch'},
                -- it use a hightlight group IncSearch

                -- but you can create a hightlight on child component too
                { lsp_comps.lsp_error({ format = '  %s' }), {'red','black'} },

                { lsp_comps.lsp_warning({ format = '  %s' }), {'yellow',''} },
                -- it have same background black with the previous component

                { lsp_comps.lsp_hint({ format = '  %s' }), {'', 'blue'} },
                -- it have same foreground yellow with the previous component

                { ' ] ' },
            }
        end
        return ''
    end,
}
```
**Don't do something complex on component. It run multiple times when statusline
rendering. If you want to do that you need to use** [cache component](https://github.com/windwp/windline.nvim/wiki/component#cache-value-on-buffer)

<h4>Never use a Job or run system command inside component. You need to use it
inside cache component </h4>
 

Windline doesn't have a component condition just return an empty string `''`or `nil` to
remove it.

It doesn't have seperator or padding so you can add it by create a child component.

[More info](https://github.com/windwp/windline.nvim/wiki/component)
## Width setting
you can hide components by setting a minimum window width
```lua

local git_comps = require('windline.components.git')

-- short syntax
local git_branch = { git_comps.git_branch(), {'white', 'black'}, 100}

-- syntax using table
local git_branch = {
    text = git_comps.git_branch(),
    hl_colors = {'white','black'},
    --- component not visible if window width is less than 100
    width = 100,
}
```

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
  green_light   = "",  -- terminal_color_10,
  yellow_light  = "",  -- terminal_color_11,
  blue_light    = "",  -- terminal_color_12,
  magenta_light = "",  -- terminal_color_13,
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

If you need to define a new color to use on animation you need to define
it on the `colors_name` function.

```lua

local windline = require('windline')

windline.setup({
  -- this function will run on ColorScheme autocmd
  colors_name = function(colors)
      --- add new colors
      colors.FilenameFg = colors.white_light
      colors.FilenameBg = colors.black

      -- this color will not update if you change a colorscheme
      colors.gray = "#fefefe"

      -- dynamically get color from colorscheme hightlight group
      local searchFg, searchBg = require('windline.themes').get_hl_color('Search')
      colors.SearchFg = searchFg or colors.white
      colors.SearchBg = searchBg or colors.yellow

      return colors
  end,

})
```
you can create a theme for a colorscheme
[gruvbox](./lua/windline/themes/gruvbox.lua)

## animations
animations with colors_name from colors defined above
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
## Global statusline setting
```lua
windline.setup({
  -- hide that filetype on global statusline
    global_skip_filetypes = {
        'NvimTree',
        'lir',
    }
})

```

If that filetype display on floating window (popup).It will always
hiding.You can change that behavior create a custome statusline
```lua
local telescope = {
    filetypes = {'TelescopePrompt'},
    active = {
        {'  ', {'white', 'black'} },
    },
    --- for global statusline (laststatus = 3). 
    --- by default it skip all floating window on global statusline but you can
    --- change it here
    global_show_float = false
}
```


## winbar

[view](https://github.com/windwp/windline.nvim/wiki/Winbar)
## Click

[view](https://github.com/windwp/windline.nvim/wiki/Click)

## Benchmark
A command to benchmark current status line by rendering it 10.000 time.
`:WindLineBenchMark`

## Tabline
[view](https://github.com/windwp/windline.nvim/wiki/tabline)

## Document
[wiki](https://github.com/windwp/windline.nvim/wiki/)
