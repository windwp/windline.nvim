local windline = require('windline')
local helper = require('windline.helpers')
local sep = helper.separators
local b_components = require('windline.components.basic')
local state = _G.WindLine.state

local hl_list = {
    Black = { 'white', 'black' },
    White = { 'black', 'white' },
    Normal = { 'NormalFg', 'NormalBg' },
    Inactive = { 'InactiveFg', 'InactiveBg' },
    Active = { 'ActiveFg', 'ActiveBg' },
}
local basic = {}

basic.divider = { b_components.divider, hl_list.Black }

local colors_mode_light = {
    Normal = { 'magenta', 'black_light' },
    Insert = { 'green', 'black_light' },
    Visual = { 'yellow', 'black_light' },
    Replace = { 'blue_light', 'black_light' },
    Command = { 'red', 'black_light' },
}

local colors_mode_rev = {
    Normal = { 'black', 'magenta' },
    Insert = { 'black', 'green' },
    Visual = { 'black', 'yellow' },
    Replace = { 'black', 'blue_light' },
    Command = { 'black', 'red' },
}

basic.vi_mode = {
    name = 'vi_mode',
    hl_colors = colors_mode_rev,
    text = function()
        return { { state.mode[1] .. ' ', state.mode[2] } }
    end,
}

basic.vi_mode_sep_left = {
    name = 'vi_mode',
    hl_colors = colors_mode_light,
    text = function()
        return { { sep.right_filled, state.mode[2] } }
    end,
}

basic.right = {
    hl_colors = colors_mode_rev,
    text = function()
        return {
            { '', state.mode[2] },
            { b_components.progress, '' },
            { ' ', '' },
            { b_components.line_col, '' },
        }
    end,
}

local job_utils = require('wlanimation.components.job')

basic.job_event = {
    hl_colors = { 'blue', 'black_light' },
    text = job_utils.job_event('sleep 10', 'BufEnter', 'job_sleep', function(data)
        if data.is_load then
            return 'event ' .. data.loading_text
        end
        return 'bufenter done ' .. (data.data or '')
    end),
}

basic.job_interval = {
    hl_colors = { 'green', 'black_light' },
    text = job_utils.job_interval('sleep 10', 7000, 'job_inerval', function(data)
        if data.is_load then
            return 'interval ' .. data.loading_text
        end
        return 'interval done ' .. (data.data or '')
    end),
}

vim.g.tmp_job_state = 'loading'

basic.job_spinner = {
    name = 'job_spinner',
    hl_colors = {
        yellow = { 'yellow', 'black_light' },
        red = { 'red', 'black_light' },
    },
    text = job_utils.loading({
        spin_tbl = true,
        state = function()
            if vim.g.tmp_job_state == 'loading' then
                return job_utils.LOADING_STATE.SPINNER -- 1
            elseif vim.g.tmp_job_state == 'remove' then
                -- it will complete remove that components out of statusline
                return job_utils.LOADING_STATE.REMOVE -- 3
            end
            return job_utils.LOADING_STATE.RESULT --2
        end,
        result = function()
            return {
                { 'result :', 'red' },
                { vim.g.tmp_job_state or '', 'yellow' },
            }
        end,
        loading = function(spinner_text)
            return {
                { 'loading', 'red' },
                { spinner_text, 'yellow' },
            }
        end,
        comp_remove = { name = 'job_spinner', filetype = 'default' },
    }),
}

basic.right_sep = {
    hl_colors = colors_mode_light,
    text = function()
        return {
            { sep.left_filled, state.mode[2] },
        }
    end,
}
local default = {
    filetypes = { 'default' },
    active = {
        basic.vi_mode,
        basic.vi_mode_sep_left,
        basic.divider,
        { '   ', { 'white', 'black' } },
        basic.job_spinner,
        -- basic.job_event,
        -- basic.job_interval,
        basic.right_sep,
        basic.right,
    },
    in_active = {
        { b_components.full_file_name, hl_list.Inactive },
        basic.divider,
        basic.divider,
        { b_components.line_col, hl_list.Inactive },
        { b_components.progress, hl_list.Inactive },
    },
}
windline.setup({
    statuslines = {
        default,
    },
})
