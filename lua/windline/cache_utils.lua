--- It help reduce call function too many time
--- it save data on buffer and only update when event happen

local M = {}

--- store an auto events if value equal false mean it need to update in a next call
--- it doesn't update on autocmd it update when statusline call a render so if
--- you don't display that component it will not call
M.buffer_auto_events = {}

--- store an cache value action to make sure it is never repeat call on child
--- component
M.buffer_auto_funcs = {}
-- state when action cache value need to update realtime
M.LOADING_STATE = 9999

--- I don't use autocommands on buffer it have an problem when buffnr=1??
--- and usually only 1 function call on visible window so update it on global
--- event on another buffer is fine
--- some event like FileType don't work on autocommands with buffer

---@param auto_event string event when buffer value change
---@param variable_name string value will save on vim_data
---@param action function action to do on buffer
---@param loading_action function when value equal state LOADING_STATE
---@param vim_data function when event on state LOADING_STATE
---@return function(bufnr, winr)
M.cache_func = function(auto_event, variable_name, action, loading_action, vim_data)
    if M.buffer_auto_funcs[variable_name] then
        return M.buffer_auto_funcs[variable_name]
    end
    if M.buffer_auto_events[variable_name] == nil then
        M.buffer_auto_events[variable_name] = false
        vim.api.nvim_exec(
            string.format(
                [[
                augroup WL%s
                au!
                au %s * call v:lua.WindLine.cache_buffer_cb('%s')
                augroup END
                ]],
                variable_name,
                auto_event,
                variable_name
            ),
            false
        )
    else
        print(string.format(
            'if it repeat too many time you need to declare a variable for component %s',
            variable_name
        ))
    end

    local func = function(bufnr, winnr)
        if M.buffer_auto_events[variable_name] == false then
            M.buffer_auto_events[variable_name] = true
            local value = action(bufnr, winnr)
            vim_data[variable_name] = value
            return value
        end
        if not vim_data[variable_name] then
            local value = action(bufnr, winnr)
            vim_data[variable_name] = value
            return value
        elseif vim_data[variable_name] == M.LOADING_STATE and loading_action then
            return loading_action(bufnr, winnr)
        end
        return vim_data[variable_name] or ''
    end
    M.buffer_auto_funcs[variable_name] = func
    return func
end

--- reduce call function on render status line
--- it cache value on buffer variable and calculte when event change
---@param auto_event string event when buffer value change
---@param buf_variable_name string it will save cache on vim.b[variable_name]
---@param action function action to do on buffer
---@return function(bufnr, winr)
M.cache_on_buffer = function(auto_event, buf_variable_name, action)
    return M.cache_func(auto_event, buf_variable_name, action, nil, vim.b)
end

--- reduce call function on render status line
--- it cache value on global variable and calculte when event change
---@param auto_event string event when buffer value change
---@param global_variable_name string it will save cache on vim.g[variable_name]
---@param action function action to do on buffer
---@return function(bufnr, winr)
M.cache_on_global = function(auto_event, global_variable_name, action)
    M.cache_func(auto_event, global_variable_name, action, nil, vim.g)
end

M.cache_buffer_cb = function(identifier)
    M.buffer_auto_events[identifier] = false
end

_G.WindLine.cache_buffer_cb = M.cache_buffer_cb

M.reset = function()
    M.buffer_auto_events = {}
    M.buffer_auto_funcs = {}
end

return M
