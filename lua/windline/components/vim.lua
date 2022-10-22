local M = {}

-- need to call that to check when search pattern failed
M.cmdl_search_leave = function()
    -- need to wait cmd finish search to get last search pattern
    vim.defer_fn(function()
        local pattern = vim.fn.getreg('/')
        pcall(vim.fn.searchcount, { pattern = pattern })
    end, 10)
end

M.cmdl_search_enter = function()
    -- recompute when change to new buffer
    if vim.v.hlsearch == 1 and vim.api.nvim_win_get_config(0).relative == '' then
        local pattern = vim.fn.getreg('/')
        if pattern and #pattern > 1 then
            pcall(vim.fn.searchcount, { pattern = pattern })
        end
    end
end

local is_sc_setup = false

local setup_search_count = function()
    if is_sc_setup then
        return
    end
    is_sc_setup = true

    local group = vim.api.nvim_create_augroup("WLSearchLens", { clear = true })
    vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        pattern = "*",
        callback = M.cmdl_search_enter
    })
    vim.api.nvim_create_autocmd("CmdlineLeave", {
        group = group,
        pattern = "[/\\?]",
        callback = M.cmdl_search_leave
    })
end

M.search_count = function(opt)
    opt = opt or {}
    local show_zero = opt.show_zero or false
    setup_search_count()

    return function()
        if vim.v.hlsearch == 0 then
            return ''
        end

        local check, result = pcall(vim.fn.searchcount, { recompute = 0 })
        if not check or not result or result.current == nil then
            return ''
        end

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
        return string.format(' %d/%d ', result.current or '', result.total or '')
    end
end
return M
