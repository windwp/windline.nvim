local windline = require('windline')
local state = windline.state

local M = {}

M.git_branch = function(opt)
    if opt.condition ~= nil then
        if not opt.condition() then
            return ''
        end
    end

    windline.add_buf_enter_event(function()
        state.git_branch = vim.call('fugitive#head') or ''
    end)

    return function()
        if #state.git_branch > 1 then
            return '  ' .. state.git_branch .. ' '
        end
        return state.git_branch or ''
    end
end

M.git_changes = function()
    return function()
        return vim.b.gitsigns_status or ''
    end
end

return M
