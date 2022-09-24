local M = {}

local windline = require('windline')
local cache_utils = require('windline.cache_utils')
local utils = require('windline.utils')
local state = windline.state

local get_diagnostics_count = function(bufnr)
    bufnr = bufnr or 0
    local diagnostics = vim.diagnostic.get(bufnr)
    local count = { 0, 0, 0, 0 }
    for _, diagnostic in ipairs(diagnostics) do
        count[diagnostic.severity] = count[diagnostic.severity] + 1
    end
    return count[vim.diagnostic.severity.ERROR],
        count[vim.diagnostic.severity.WARN],
        count[vim.diagnostic.severity.INFO],
        count[vim.diagnostic.severity.HINT]
end

local get_lsp_client = nil
if vim.fn.has('nvim-0.8') > 0 then
    get_lsp_client = function(bufnr)
        return vim.lsp.get_active_clients({
            bufnr = bufnr or vim.api.nvim_get_current_buf()
        })
    end
else
    get_lsp_client = vim.lsp.buf_get_clients
end

local function is_lsp(bufnr, opt)
    opt = opt or {}
    local hide_server_names = opt.hide_server_names or { 'copilot' }
    local clients = {}
    for _, client in pairs(get_lsp_client(bufnr)) do
        if not utils.is_in_table(hide_server_names, client.name) then
            clients[#clients + 1] = client.name
        end
    end
    return next(clients) ~= nil
end

M.check_custom_lsp = function(opt)
    opt = opt or {}
    local lsp_check = opt.func_check or is_lsp

    return function(bufnr, config)
        if state.comp.lsp == nil and lsp_check(bufnr, config) then
            local error, warning, information, hint = get_diagnostics_count(bufnr)
            state.comp.lsp_error = error
            state.comp.lsp_warning = warning
            state.comp.lsp_information = information
            state.comp.lsp_hint = hint

            state.comp.lsp = 1
        end
        return state.comp.lsp ~= nil
    end
end

-- it make sure we only call the diagnostic 1 time on render function
M.check_lsp = M.check_custom_lsp()

local lsp_client_names = function(bufnr, opt)
    opt = opt or {}
    local clients = {}
    local icon = opt.icon or ' '
    local sep = opt.separator or '|'
    local hide_server_names = opt.hide_server_names or { 'null-ls', 'copilot' }

    for _, client in pairs(get_lsp_client(bufnr)) do
        if not utils.is_in_table(hide_server_names, client.name) then
            clients[#clients + 1] = client.name
        end
    end
    if next(clients) then
        return icon .. table.concat(clients, sep)
    end
    return nil
end

M.lsp_name = function(opt)
    return cache_utils.cache_on_buffer('BufEnter', 'lsp_server_name', function(bufnr)
        local lsp_name = lsp_client_names(bufnr, opt)
        -- some server need too long to start
        -- it check on bufenter and after 600ms it check again
        if lsp_name == nil then
            vim.defer_fn(function()
                cache_utils.set_cache_buffer(
                    bufnr,
                    'lsp_server_name',
                    lsp_client_names(bufnr, opt) or ''
                )
            end, 600)
            -- return '' will stop that cache func loop check
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
