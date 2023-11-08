local cache_utils = require('windline.cache_utils')
local uv = vim.uv or vim.loop
local uv_utils = require('windline.components.utils')

local M = {}

M.git_result = { 0, 0 }

--- fetch git rev
---@param opt table {interval = 100000}
---@return function
local git_rev_text = function(opt)
    opt = vim.tbl_extend('force', { interval = opt.interval }, opt or {})
    local timer = uv.new_timer()
    timer:start(200, opt.interval, vim.schedule_wrap(M.git_rev_update))
    cache_utils.add_reset_func('git_rev_ext', function()
        timer:stop()
    end)
    return function()
        return M.git_result
    end
end

---force git rev update
---public. Make it can use with some async git plugin or autocmd
M.git_rev_update = function()
    uv_utils.uv_run('git fetch', function()
        uv_utils.uv_run(
            'git rev-list --count --left-right @{upstream}...HEAD',
            function(data)
                if data then
                    local result = vim.split(data, '\t')
                    M.git_result = {
                        tonumber(result[1]) or 0,
                        tonumber(result[2]) or 0,
                    }
                end
            end
        )
    end)
end

--- git rev
--- It can run inside component
---@param opt table {interval = 100000, format = ' ⇡%s⇣%s'}
---@return string
M.git_rev = function(opt)
    return cache_utils.one_call_func('git_rev', function()
        local default = {
            interval = 100000,
            format = ' %s⇣%s⇡ ',
            format_index = { 1, 2 },
        }
        opt = vim.tbl_extend('force', default, opt or {})
        local git_rev = git_rev_text(opt)

        return function()
            local rev = git_rev()
            if rev and (rev[1] > 0 or rev[2] > 0) then
                return string.format(
                    opt.format,
                    rev[opt.format_index[1]],
                    rev[opt.format_index[2]]
                )
            end
            return ''
        end
    end)
end

return M
