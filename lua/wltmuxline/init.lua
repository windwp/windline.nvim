local M = {}
local api = vim.api
local tmux_component = require('wltmuxline.tmux_component')

local uv = vim.uv or vim.loop

---@class tmux_line
---@field original string
---@field tmux 'status-left'|'status-right'
---@field tabline boolean
---@field stdin? uv_pipe_t
---@field job? uv_process_t
---@field shutdown function
---@field setup function
---@field restore function
---@field last_status string
---@field active tmux_component[]|tmux_component
---@field data? any

---@class tmux_config
---@field is_run boolean
---@field statuslines tmux_line[]
local default_config = {
    autocmd = { "BufEnter", "TabEnter", "TabClosed" },
    is_run = true,
    first_run = false,
    statuslines = {}
}

---@type tmux_config
---@diagnostic disable-next-line: missing-fields
local tmux_state = {}
local wline_state = WindLine.state

---@param line tmux_line
local function render_tabline(line)
    local total_tab = vim.fn.tabpagenr('$')
    local status = ''
    local tab_select = vim.fn.tabpagenr()
    for i = 1, total_tab, 1 do
        local data = {
            is_selection = i == tab_select,
            is_next_select = ((i + 1) == tab_select),
            is_tab_finish = i == total_tab,
            template = line.data,
            tab_index = i,
        }
        status = status .. line.active[1]:render(data)
    end
    line.last_status = status
    return status
end

---@param line tmux_line
local function render_status_line(line)
    tmux_component.reset()
    local status = ''
    local winid = api.nvim_get_current_win()
    local bufnr = api.nvim_get_current_buf()
    local win_width = vim.o.columns
    if api.nvim_win_get_config(winid).relative ~= '' then
        bufnr = wline_state.last_bufnr or bufnr
        winid = wline_state.last_winid or winid
    end
    for _, comp in pairs(line.active) do
        status = status .. comp:render(bufnr, winid, win_width)
    end
    line.last_status = status
    return status
end


M.update = function()
    if not tmux_state.is_run then return false end
    for _, line in pairs(tmux_state.statuslines) do
        local text = line.tabline and render_tabline(line) or render_status_line(line)
        if text ~= '' and line.stdin then
            line.stdin:write(text .. '\n')
        end
    end
end

M.stop = function()
    tmux_state.is_run = false
    for _, line in pairs(tmux_state.statuslines) do
        if line.job then
            line.shutdown()
            line.restore()
        end
    end
end


M.tmux_restore = function()
    for _, line in pairs(tmux_state.statuslines) do
        line.restore(true)
    end
end

---@param line tmux_line
local function run_cmd(line)
    local original = vim.fn.systemlist(
        string.format([[sh -c 'tmux display-message -p "#{%s}"']], line.tmux))[1]
    if original and not original:match('socket_path') then
        line.original = original
    end
    local tmux_set_command = string.format([[tmux set  %s '#(cat #{socket_path}-\#{session_id}-%s)']],
        line.tmux, line.tmux)
    vim.fn.system(tmux_set_command);
end

M.tmux_set = function()
    if not M.first_run then
        M.first_run = true
        return
    end
    for _, line in pairs(tmux_state.statuslines) do
        run_cmd(line)
    end
    M.update()
end
---@param line tmux_line
---@param colors table
local function init_tmux(line, colors)
    assert(line.tmux == 'status-left' or line.tmux == 'status-right', ' tmux config is wrong')
    -- compile component
    if #line.active > 0 then
        for key, value in pairs(line.active) do
            local comp = tmux_component.create(value)
            line.active[key] = comp
            comp:setup_hl(colors)
        end
    end

    local session_id = vim.env.TMUX:match(',(%d*)$')
    local tmux_pipe = vim.env.TMUX:match('/tmp/tmux%-%d*/default')
    local pipe_path = string.format('%s-$%s-%s', tmux_pipe, session_id, line.tmux)
    local function restore(verify)
        if verify and line.last_status then
            local check, value = pcall(vim.fn.readfile, pipe_path, '', 1)
            if check and value and value[1] ~= line.last_status then
                return
            end
        end
        if line.original then
            pcall(vim.fn.system,
                string.format('tmux set %s %s', line.tmux, vim.fn.shellescape(line.original)))
        end
    end

    local stdin = uv.new_pipe(false)
    local job_script = string.format(
        [[while IFS=''$\n'' read -r l; do echo "$l" > '%s';tmux refresh-client -S; done]],
        pipe_path
    )

    local job = uv.spawn("bash",
        { cwd = uv.cwd(), stdio = { stdin }, args = { "-c", job_script } }
    )

    if not job then return end
    run_cmd(line)
    line.stdin = stdin
    line.job = job
    line.restore = vim.schedule_wrap(restore)
    line.shutdown = function()
        if stdin and stdin.is_active then stdin:close() end
        if job and job.is_active then job:close() end
        line.stdin = nil
        line.job = nil
    end
end


---@param opts tmux_config
M.setup = function(opts)
    if not vim.env.TMUX then return end
    opts = vim.tbl_deep_extend('force', default_config, opts or {})
    tmux_state = opts
    if #opts.statuslines == 0 then
        return vim.notify('tmuxline: you need to input statuslines on setup')
    end
    M.stop()
    local group = vim.api.nvim_create_augroup('WindlineTmuxLine', { clear = true })
    vim.api.nvim_create_autocmd('FocusGained', {
        group = group,
        pattern = "*",
        callback = function()
            tmux_state.is_run = true
            M.tmux_set()
        end
    })
    vim.api.nvim_create_autocmd('FocusLost', {
        group = group,
        pattern = "*",
        callback = function()
            tmux_state.is_run = false
            vim.schedule(M.tmux_restore)
        end
    })
    vim.api.nvim_create_autocmd('VimLeavePre', {
        group = group,
        pattern = "*",
        callback = vim.schedule_wrap(M.stop)
    })
    vim.api.nvim_create_autocmd(
        tmux_state.autocmd,
        { group = group, pattern = '*', callback = M.update }
    )
    vim.api.nvim_create_autocmd('ColorScheme', {
        group = group,
        pattern = "*",
        callback = function()
            local colors = require('windline').get_colors()
            for _, line in pairs(tmux_state.statuslines) do
                if (line.active) then
                    for _, comp in pairs(line.active) do
                        comp:setup_hl(colors)
                    end
                end
            end
            M.update()
        end
    })
    local colors = require('windline').get_colors()
    for _, line in pairs(tmux_state.statuslines) do
        init_tmux(line, colors)
    end
    tmux_state.is_run = true
    M.update()
end

return M
