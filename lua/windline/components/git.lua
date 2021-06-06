local windline = require('windline')
local state = windline.state

local M = {}

-- M.git_branch = function(opt)
--     if opt.condition ~= nil then
--         if not opt.condition() then
--             return ''
--         end
--     end

--     windline.add_buf_enter_event(function()
--         state.git_branch = vim.call('fugitive#head') or ''
--     end)

--     return function()
--         if state.git_branch and #state.git_branch > 1 then
--             return '  ' .. state.git_branch .. ' '
--         end
--         return state.git_branch or ''
--     end
-- end

M.git_changes = function()
    return function()
        return vim.b.gitsigns_status or ''
    end
end

M.git_branch = function(opt)
    if opt.condition ~= nil then
        if not opt.condition() then
            return ''
        end
    end
    return function()
        local git_dict = vim.b.gitsigns_status_dict
        if git_dict and git_dict.head and #git_dict.head > 0 then
            local icon = opt.icon or '  '
            return icon .. git_dict.head
        else
            return ''
        end
    end
end

M.diff_added = function(opt)
    opt = opt or {}
    local format = opt.format or '%s'
    return function()
        local git_dict = vim.b.gitsigns_status_dict
        if git_dict and git_dict.head and #git_dict.head > 0 then
            local value = git_dict.added
            if value > 0 or value == 0 and opt.show_zero == true then
                return string.format(format, value)
            end
            return ''
        end
    end
end

M.diff_removed = function(opt)
    opt = opt or {}
    local format = opt.format or '%s'
    return function()
        local git_dict = vim.b.gitsigns_status_dict
        if git_dict and git_dict.head and #git_dict.head > 0 then
            local value = git_dict.removed
            if value > 0 or value == 0 and opt.show_zero == true then
                return string.format(format, value)
            end
            return ''
        end
    end
end

M.diff_changed = function(opt)
    opt = opt or {}
    local format = opt.format or '%s'
    return function()
        local git_dict = vim.b.gitsigns_status_dict
        if git_dict and git_dict.head and #git_dict.head > 0 then
            local value = git_dict.changed
            if value > 0 or value == 0 and opt.show_zero == true then
                return string.format(format, value)
            end
            return ''
        end
    end
end

M.git_changes = function()
    return function()
        return vim.b.gitsigns_status or ''
    end
end

return M
