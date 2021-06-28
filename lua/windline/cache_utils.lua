--- It will help reduce call function too many time on buffer.
--- it save data on buffer and only update when event happen

--- store an auto events when value == false it need to update in a next call
local buffer_auto_events = {}

--- store an cache value action to make sure it is never repeat call on child
--- component
local buffer_auto_func = {}

local M = {}

--- I don't use autocommands on buffer it have an problem when buffnr=1??
--- and usually only 1 function call on visible window so update it on global
--- event on another buffer is fine
--- some event like FileType don't work on autocommands with buffer
---@param auto_event string event when buffer value change
---@param buf_variable_name string buf_variable_name then
---@param action function action to do on buffer
M.cache_on_buffer = function(auto_event, buf_variable_name, action)
    if buffer_auto_func[buf_variable_name] then
        return buffer_auto_func[buf_variable_name]
    end
    if buffer_auto_events[buf_variable_name] == nil then
        vim.api.nvim_exec(
            string.format(
                [[
                augroup WL%s
                au!
                au %s * call v:lua.WindLine.cache_buffer_cb('%s')
                augroup END
                ]],
                buf_variable_name,
                auto_event,
                buf_variable_name
            ),
            false
        )
    else
        print(string.format(
            'if it repeat too many time use need to declare a variable for component %s',
            buf_variable_name
        ))
    end

    local func = function(bufnr, winnr)
        if buffer_auto_events[buf_variable_name] == false then
            buffer_auto_events[buf_variable_name] = true
            local value = action(bufnr, winnr)
            vim.b[buf_variable_name] = value
            return value
        end
        if vim.b[buf_variable_name] == nil then
            local value = action(bufnr, winnr)
            vim.b[buf_variable_name] = value
            return value
        end
        return vim.b[buf_variable_name] or ''
    end
    buffer_auto_func[buf_variable_name] = func
    return func
end

M.cache_buffer_cb = function(identifier)
    buffer_auto_events[identifier] = false
end

_G.WindLine.cache_buffer_cb = M.cache_buffer_cb

M.reset = function()
    buffer_auto_events = {}
    buffer_auto_func = {}
end
return M
