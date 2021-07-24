local bench = require('plenary.profile').benchmark

-- local num = 10
local num = 2e4
local item = ''
print('total time: ', bench(num, function()
    vim.g.statusline_winid = vim.api.nvim_get_current_win()
    item = WindLine.show(vim.api.nvim_get_current_buf(), vim.g.statusline_winid)
end))

print(vim.inspect(item))
