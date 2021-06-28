local M = {}

-- need to call that to check when search pattern failed
M.cmdl_search_leave = function()
    -- need to wait cmd finish search to get last search pattern
    vim.defer_fn(function()
        local pattern = vim.fn.getreg('/')
        vim.fn.searchcount({ pattern = pattern })
    end, 10)
end

M.cmdl_search_enter = function()
    -- recompute when change to new buffer
    local pattern = vim.fn.getreg('/')
    vim.fn.searchcount({ pattern = pattern })
end

local is_sc_setup = false

local setup_search_count = function()
    if is_sc_setup then
        return
    end
    is_sc_setup = true

    vim.api.nvim_exec(
        [[
        aug WLSearchLens
            au!
            au BufEnter * lua require('windline.components.vim').cmdl_search_enter()
            au CmdlineLeave [/\?] lua require('windline.components.vim').cmdl_search_leave()
        aug END
    ]],
        false
    )
end

M.search_count = function(opt)
    opt = opt or {}
    local show_zero = opt.show_zero or false
    setup_search_count()

    return function()
        if vim.v.hlsearch == 0 then
            return ''
        end
        local result = vim.fn.searchcount({ recompute = 0 })
        if show_zero == false and result.total == 0 and result.current == 0 then
            return ''
        end

        if result.incomplete == 1 then -- timed out
            return ' ?/?? '
        elseif result.incomplete == 2 then -- max count exceeded
            if result.total > result.maxcount and result.current > result.maxcount then
                return string.format(' >%d/>%d ', result.current, result.total)
            elseif result.total > result.maxcount then
                return string.format(' %d/>%d ', result.current, result.total)
            end
        end
        return string.format(' %d/%d ', result.current, result.total)
    end
end
return M
