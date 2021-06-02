local M={}

local windline = require('windline')
local state = windline.state
local lsp = vim.lsp

local get_diagnostics_count = function(bufnr)
    bufnr = bufnr or 0
    local error = lsp.diagnostic.get_count(bufnr, [[Error]])
    local warning = lsp.diagnostic.get_count(bufnr, [[Warning]])
    local information = lsp.diagnostic.get_count(bufnr, [[Information]])
    -- local hint = lsp.diagnostic.get_count(bufnr, [[Hint]])

    return error, warning, information
end

local function is_lsp()
    return next(lsp.buf_get_clients()) ~= nil
end

local lsp_client_names = function(opt)
    local clients = {}
    local icon = opt.icon or ' '
    local sep = opt.seprator or ' '

    for _, client in pairs(lsp.buf_get_clients()) do
        clients[#clients+1] = icon .. client.name
    end
    return table.concat(clients, sep)
end

-- it make sure we only call the diagnostic 1 time on render function
M.check_lsp = function(lsp_opt)
    local lsp_check = lsp_opt.func_check or is_lsp

    return function()
        if state.comp.lsp == nil and lsp_check() then
            local error, warning,hint  = get_diagnostics_count(0)
            state.comp.lsp_error = error
            state.comp.lsp_warning = warning
            state.comp.lsp_hint = hint
            -- save lsp_name on buffer variable

            if error > 0 or warning > 0  then
                state.comp.lsp = 1
            else
                state.comp.lsp = 2
            end
        else
            state.comp.lsp_error = 0
            state.comp.lsp_warning = 0
            state.comp.lsp_hint = 0
        end
        return state.comp.lsp ~= nil
    end
end

M.lsp_name = function()
    windline.add_buf_enter_event(function()
        vim.b.lsp_server_name = lsp_client_names()
    end)

    return function()
        return vim.b.lsp_server_name or ''
    end
end

M.lsp_error = function ()
    return state.comp.lsp_error or 0
end

M.lsp_hint = function ()
    return state.comp.lsp_hint or 0
end

M.lsp_warning = function()
    return state.comp.lsp_warning or 0
end

return M
