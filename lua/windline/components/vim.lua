local M = {}


M.cmdl_search_leave = function()

    -- need to wait cmd finish search to get last search pattern
    vim.defer_fn(function()
        local pattern = vim.fn.getreg("/")
        local result = vim.fn.searchcount({pattern = pattern})
        vim.b.windline_search_cache = result
        vim.cmd "redrawstatus"
    end, 10)
end

M.search_count = function(opt)
    opt= opt or{}
    local show_zero = opt.show_zero or false

    vim.api.nvim_exec([[
        aug WLSearchLens
            au!
            au CmdlineLeave [/\?] lua require('windline.components.vim').cmdl_search_leave()
        aug END
    ]], false)

     return function()
        if vim.v.hlsearch == 0 then return '' end

        local result = vim.b.windline_search_cache or {}
        if vim.tbl_isempty(result) then
            return ''
        end
        if show_zero == false and result.total == 0 and result.current == 0 then
            return ''
        end
        -- this make sure we have correct location
        result = vim.fn.searchcount({recompute = 0})

        if result.incomplete == 1 then -- timed out
            return " ?/?? "
        elseif result.incomplete == 2 then -- max count exceeded
            if result.total > result.maxcount and result.current > result.maxcount then
                return string.format(" >%d/>%d ", result.current, result.total)
            elseif result.total > result.maxcount then
                return string.format(" >%d/>%d ", result.current, result.total)
            end
        end
        return string.format(" %d/%d ", result.current, result.total)
    end
end
return M
