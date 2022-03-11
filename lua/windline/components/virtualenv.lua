local M = {}
local cache_utils = require('windline.cache_utils')

M.virtualenv = function(opt)
    opt = opt or {}
    local format = opt.format or '廬%s'
    local conda_format = opt.conda_format or format
    return function(bufnr)
        local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
        if filetype == 'python' then
            local venv = os.getenv('CONDA_DEFAULT_ENV')
            if venv ~= nil then
                return string.format(conda_format, vim.fn.fnamemodify(venv, ':t'))
            end
            venv = os.getenv('VIRTUAL_ENV')
            if venv ~= nil then
                return string.format(format, vim.fn.fnamemodify(venv, ':t'))
            end
            return ''
        end
        return ''
    end
end

M.cache_virtualenv = function(opt)
    return cache_utils.cache_on_buffer(
        'BufEnter',
        'wl_virtualenv',
        M.virtualenv(opt)
    )
end

return M
