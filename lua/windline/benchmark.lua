local M = {}
local uv = vim.uv or vim.loop
local function bench(iterations, f, ...)
  local start_time = uv.hrtime()
  for _ = 1, iterations do
    f(...)
  end
  return (uv.hrtime() - start_time) / 1E9
end
--- a benchmark current statusline. it need plenary.nvim
M.benchmark = function()
    local Comp = require('windline.component')
    local windline = require('windline')
    local api = vim.api
    local num = 1e4
    local statusline = ''
    local bufnr = api.nvim_get_current_buf()
    local winid = api.nvim_get_current_win()
    local width = api.nvim_win_get_width(0)
    local time = bench(num, function()
        vim.g.statusline_winid = winid
        statusline = WindLine.show(bufnr, winid)
    end)
    local popup = require('plenary.popup')
    local result = {}
    table.insert(result,'Status:')
    table.insert(result, statusline)
    table.insert(result, 'Time:')
    table.insert(result, string.format('render %s time : *%s*', num, time))
    table.insert(result, 'Comp:')
    local line = windline.get_statusline_ft(vim.bo.filetype) or windline.default_line
    table.insert(result, string.format('%s %12s %12s %s %s', ' ', 'time', 'name', 'num   ', 'text'))
    for index, comp in pairs(line.active) do
        local item = ''
        time = bench(num, function()
            Comp.reset()
            item = comp:render(bufnr, winid, width)
        end)
        table.insert(result, string.format('%02d *%10s* %12s %s - %s', index, time, comp.name or '   ', num, item))
    end
    local vim_width = math.floor(vim.o.columns / 1.5)
    local col = math.floor((vim.o.columns - vim_width) / 2)
    popup.create(result, {
        border = {},
        minheight = 30,
        maxwidth=vim_width,
        col = col,
        line = 10,
        width = vim_width,
    })
    vim.bo.filetype = 'help'
end
return M
