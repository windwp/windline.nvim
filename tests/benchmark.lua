-- test time to render status line
local num = 1e4
vim.cmd([[packadd plenary.nvim]])
vim.cmd([[packadd windline.nvim]])
vim.opt.termguicolors = true

local log = require('plenary.log').new({ level = 'debug' })
require('wlsample.evil_line')

vim.cmd([[e ./tests/benchmark.lua]])
-- wait to vim enter end test
vim.defer_fn(function()
    local bench = require('plenary.profile').benchmark
    local statusline = ''
    local time = bench(num, function()
        vim.g.statusline_winid = vim.api.nvim_get_current_win()
        statusline = WindLine.show(vim.api.nvim_get_current_buf(), vim.g.statusline_winid)
    end)

    log.info(statusline)
    log.info('windline time :' .. time)
    vim.cmd([[quit]])
end, 100)
