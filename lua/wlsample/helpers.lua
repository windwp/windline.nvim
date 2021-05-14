local M={}

M.separators = {
    vertical_bar = '┃',
    vertical_bar_thin = '│',
    left = '',
    right = '',
    block = '█',
    left_filled = '',
    right_filled = '',
    slant_left = '',
    slant_left_thin = '',
    slant_right = '',
    slant_right_thin = '',
    slant_left_2 = '',
    slant_left_2_thin = '',
    slant_right_2 = '',
    slant_right_2_thin = '',
    left_rounded = '',
    left_rounded_thin = '',
    right_rounded = '',
    right_rounded_thin = '',
    circle = '●'
}


local web_devicons = nil

M.get_icon = function (file_name, file_ext)
    if vim.g.wind_use_icon == 1 then
        if web_devicons == nil then
            local ok, icon = pcall(require, 'nvim-web-devicons')
            if ok then web_devicons = icon else web_devicons = false end
        end
        if web_devicons then
            return web_devicons.get_icon(file_name, file_ext, { default = true })
        end
    end
    return ''
end


M.get_diagnostics_count = function(bufnr)
    bufnr = bufnr or 0
    local error = vim.lsp.diagnostic.get_count(bufnr, [[Error]])
    local warning = vim.lsp.diagnostic.get_count(bufnr, [[Warning]])
    local information = vim.lsp.diagnostic.get_count(bufnr, [[Information]])
    -- local hint = vim.lsp.diagnostic.get_count(bufnr, [[Hint]])

    return error, warning,information
end

return M
