--- It help reduce call function too many time
--- it save data on buffer and only update when event happen

local M = {}
local api = vim.api

--- store an auto events if value equal false mean it need to update in a next call
--- it doesn't update on autocmd it update when statusline call a render so if
--- you don't display that component it will not call
local d_check = {}

local d_value = {}

--- store an cache value action to make sure it is never repeat call on child
--- component
local d_action = {}

--- store an cache action for memo
local d_one_action = {}

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
local function cache_func(auto_event, variable_name, action, loading_action, vim_data)
    if d_action[variable_name] then
        return d_action[variable_name]
    end
    if d_check[variable_name] == nil then
        d_check[variable_name] = false
        local target = auto_event:match('User') and '' or '*'
        api.nvim_create_autocmd(auto_event, {
            group = api.nvim_create_augroup('WL' .. variable_name, { clear = true }),
            pattern = target,
            callback = function()
                WindLine.cache_buffer_cb(variable_name)
            end
        })
    end

    local func = function(bufnr, winid, width)
        if bufnr == nil then return end
        d_value[bufnr] = d_value[bufnr] or {}
        local buffer_v = vim_data or d_value[bufnr]
        if d_check[variable_name] == false then
            d_check[variable_name] = true
            local value = action(bufnr, winid, width)
            buffer_v[variable_name] = value
            return value
        end
        local val = buffer_v[variable_name]
        if not val then
            local value = action(bufnr, winid, width)
            buffer_v[variable_name] = value
            return value
        elseif val == M.LOADING_STATE and loading_action then
            return loading_action(bufnr, winid, width)
        end
        return val or ''
    end
    d_action[variable_name] = func
    return func
end

--- reduce call function on render status line
--- it cache value on buffer variable and calculte when event change
---@param auto_event string event when buffer value change
---@param buf_variable_name string it will save cache on vim.b[variable_name]
---@param action function action to do on buffer
---@return function(bufnr, winr)
M.cache_on_buffer = function(auto_event, buf_variable_name, action)
    return cache_func(auto_event, buf_variable_name, action, nil, nil)
end

--- reduce call function on render status line
--- it cache value on global variable and calculte when event change
---@param auto_event string event when buffer value change
---@param global_variable_name string it will save cache on vim.g[variable_name]
---@param action function action to do on buffer
---@return function(bufnr, winr)
M.cache_on_global = function(auto_event, global_variable_name, action)
    return cache_func(auto_event, global_variable_name, action, nil, vim.g)
end

M.cache_buffer_cb = function(identifier)
    d_check[identifier] = false
    local bufnr = api.nvim_get_current_buf()
    if d_value[bufnr] then
        d_value[bufnr] = {}
    end
end

---Make function only call 1 time after setup no matter what function use inside component
---@param variable_name any
---@param action any
M.one_call_func = function(variable_name, action)
    if not d_one_action[variable_name] then
        d_one_action[variable_name] = action()
    end
    return d_one_action[variable_name]
end

---@param reset_action function call to delete some value on reset
M.add_reset_func = function(variable_name, reset_action)
    if not M.reset_actions then
        M.reset_actions = {}
    end
    if not M.reset_actions[variable_name] then
        M.reset_actions[variable_name] = reset_action
    end
end


M.reset = function()
    d_check = {}
    d_value = {}
    d_action = {}
    d_one_action = {}
    if M.reset_actions then
        for _, action in pairs(M.reset_actions) do
            action()
        end
    end
    M.reset_actions = {}
end

M.set_cache_buffer = function(bufnr, variable_name, value)
    if not d_value[bufnr] then
        d_value[bufnr] = {}
    end
    d_value[bufnr][variable_name] = value
end

_G.WindLine.cache_buffer_cb = M.cache_buffer_cb
return M
