local M = {}

local windline = require('windline')
local cache_utils = require('windline.cache_utils')
local state = windline.state
local lsp = vim.lsp

local get_diagnostics_count = function(bufnr)
    bufnr = bufnr or 0
    local error = lsp.diagnostic.get_count(bufnr, [[Error]])
    local warning = lsp.diagnostic.get_count(bufnr, [[Warning]])
    local information = lsp.diagnostic.get_count(bufnr, [[Hint]])
    local hint = lsp.diagnostic.get_count(bufnr, [[Hint]])

    return error, warning, information, hint
end

local function is_lsp()
    return next(lsp.buf_get_clients()) ~= nil
end

local lsp_client_names = function(bufnr, opt)
    opt = opt or {}
    local clients = {}
    local icon = opt.icon or ' '
    local sep = opt.seprator or '|'

    for _, client in pairs(lsp.buf_get_clients(bufnr or 0)) do
        clients[#clients + 1] = client.name
    end
    if next(clients) then
        return icon .. table.concat(clients, sep)
    end
    return nil
end

M.check_custom_lsp = function(opt)
    opt = opt or {}
    local lsp_check = opt.func_check or is_lsp

    return function()
        if state.comp.lsp == nil and lsp_check() then
            local error, warning, information, hint = get_diagnostics_count(0)
            state.comp.lsp_error = error
            state.comp.lsp_warning = warning
            state.comp.lsp_information = information
            state.comp.lsp_hint = hint
            -- save lsp_name on buffer variable

            if error > 0 or warning > 0 then
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

-- it make sure we only call the diagnostic 1 time on render function
M.check_lsp = M.check_custom_lsp()

M.lsp_name = function(opt)
    return cache_utils.cache_on_buffer('BufEnter','lsp_server_name',function (bufnr)
        local lsp_name = lsp_client_names(bufnr, opt)
        -- some server need too long to start
        -- it check on bufenter and after 600ms it check again
        if lsp_name == nil then
            vim.defer_fn(function()
                cache_utils.buffer_value[bufnr]['lsp_server_name'] =  lsp_client_names(bufnr, opt) or ''
            end, 600)
            -- return ''  will stop that cache func loop check
            return ''
        end
        return lsp_name
    end)
end

M.lsp_error = function(opt)
    opt = opt or {}
    local format = opt.format or '%s'
    return function()
        local value = state.comp.lsp_error or 0
        if value > 0 or value == 0 and opt.show_zero == true then
            return string.format(format, value)
        end
        return ''
    end
end


M.lsp_info = function(opt)
    opt = opt or {}
    local format = opt.format or '%s'
    return function()
        local value = state.comp.lsp_information or 0
        if value > 0 or value == 0 and opt.show_zero == true then
            return string.format(format, value)
        end
        return ''
    end
end

M.lsp_hint = function(opt)
    opt = opt or {}
    local format = opt.format or '%s'
    return function()
        local value = state.comp.lsp_hint or 0
        if value > 0 or value == 0 and opt.show_zero == true then
            return string.format(format, value)
        end
        return ''
    end
end

M.lsp_warning = function(opt)
    opt = opt or {}
    local format = opt.format or '%s'
    return function()
        local value = state.comp.lsp_warning or 0
        if value > 0 or value == 0 and opt.show_zero == true then
            return string.format(format, value)
        end
        return ''
    end
end

return M
