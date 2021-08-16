--- help to run a command  and process result to get data
--- when command run it display a loading text
local uv = vim.loop
local animation = require('wlanimation')
local efffects = require('wlanimation.effects')
local cache_utils = require('windline.cache_utils')

local M = {}
local tbl_loading = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }

local function uv_run(cmd, action)
    local args = vim.split(cmd, ' ')
    local stdout = uv.new_pipe(false)
    local stderr = uv.new_pipe(false)
    local function handler(_, data)
        if data then
            data = vim.split(data, '\n')
            if #data == 2 then
                data = data[1]
            end
            action(data)
        else
            action('')
        end
    end
    uv.spawn(
        table.remove(args, 1),
        {
            args = args,
            cwd = vim.loop.cwd(),
            stdio = {
                nil,
                stdout,
                stderr,
            },
        },
        vim.schedule_wrap(function()
            stderr:close()
            stdout:close()
        end)
    )
    stdout:read_start(vim.schedule_wrap(handler))
    stderr:read_start(vim.schedule_wrap(handler))
end

local Job = {}
Job.__index = Job

function Job:stop()
    if self.timer then
        vim.loop.timer_stop(self.timer)
        self.timer = nil
    end
end

function Job:run()
    if self.timer then
        self:stop()
    end
    if self.anim then
        self.anim:stop()
    end
    local timer = vim.loop.new_timer()
    self.is_run = false
    self.anim = animation.basic_animation({
        timeout = nil,
        delay = 0,
        interval = 200,
        effect = efffects.list_text(self.loading_text),
        on_tick = function(value)
            self.text = self.action({
                is_load = true,
                winnr = self.winnr,
                bufnr = self.bufnr,
                loading_text = value,
            })
        end,
    })
    timer:start(
        100,
        self.interval,
        vim.schedule_wrap(function()
            if self.is_run then
                return
            end
            self.is_run = true
            if self.anim.is_run == false then
                self.anim:run()
            end
            uv_run(self.cmd, function(data)
                self.is_run = false
                if self.anim then
                    self.anim:stop()
                end
                self.text = self.action({
                    is_load = false,
                    winnr = self.winnr,
                    bufnr = self.bufnr,
                    data = data,
                })
            end)
        end)
    )
    self.timer = timer
end

---run a system command and process result to display on statusline
---triger run command on vim event
---@param cmd string a system command to run
---@param auto_event string vim event to trigger command
---@param name string a unique name to define job
---@param text_action function process result command
---@param loading_text table (option) table text message to display when running cmd
---@return function
M.job_event = function(cmd, auto_event, name, text_action, loading_text)
    if cache_utils.buffer_auto_funcs[name] then
        return cache_utils.buffer_auto_funcs[name]
    end
    if cache_utils.buffer_auto_events[name] == nil then
        cache_utils.buffer_auto_events[name] = false
        vim.api.nvim_exec(
            string.format(
                [[
                augroup WL%s
                au!
                au %s * call v:lua.WindLine.cache_buffer_cb('%s')
                augroup END
                ]],
                name,
                auto_event,
                name
            ),
            false
        )
    end
    loading_text = loading_text or tbl_loading
    local tmp = setmetatable({
        cmd = cmd,
        name = name,
        interval = 0,
        action = text_action,
        loading_text = loading_text,
    }, {
        __index = Job,
    })

    local func = nil
    func = function(bufnr, winnr)
        if not cache_utils.buffer_auto_funcs[name] then
            tmp.bufnr = bufnr
            tmp.winnr = winnr
            cache_utils.buffer_auto_funcs[name] = func
        end
        if not cache_utils.buffer_auto_events[name] then
            cache_utils.buffer_auto_events[name] = true
            if not tmp.is_run then
                tmp:run()
            end
        end
        return tmp.text
    end
    return func
end

---comment
---@param cmd string a system command to run
---@param interval number interval to run on cmd (milliseconds)
---@param name string a unique name to define job
---@param text_action function process command to display on statusline
---@param loading_text table (option) table text message to display when running cmd
---@return function
M.job_interval = function(cmd, interval, name, text_action, loading_text)
    if cache_utils.buffer_auto_funcs[name] then
        return cache_utils.buffer_auto_funcs[name]
    end
    loading_text = loading_text or tbl_loading
    local tmp = setmetatable({
        cmd = cmd,
        name = name,
        interval = interval,
        action = text_action,
        loading_text = loading_text,
    }, {
        __index = Job,
    })
    animation.add_anim_job(tmp)
    local func = nil
    func = function(bufnr, winnr)
        if not cache_utils.buffer_auto_funcs[name] then
            tmp.bufnr = bufnr
            tmp.winnr = winnr
            cache_utils.buffer_auto_funcs[name] = func
        end
        return tmp.text
    end
    return func
end


M.LOADING_STATE = {
    SPINNER = 1,
    RESULT = 2,
    REMOVE = 3,
}

--- a simple way to display spinner component
--- don't use it on child component
---@param opt table {spin_tbl = table, loading = func, result = func, comp_remove = table}}
---@return function
M.loading = function(opt)
    local loading_text = ''
    local anim = nil
    if opt.spin_tbl then
        if opt.spin_tbl == true then
            opt.spin_tbl = tbl_loading
        end
        anim = animation.basic_animation({
            timeout = nil,
            delay = 0,
            interval = 200,
            effect = efffects.list_text(opt.spin_tbl),
            on_tick = function(value)
                loading_text = value
            end,
        })
        animation.add_anim_job(anim)
    end
    return function(bufnr, winnr)
        local state = opt.state()
        if state == M.LOADING_STATE.SPINNER then
            return opt.loading(loading_text, bufnr, winnr)
        end
        if state == M.LOADING_STATE.REMOVE then
            if anim then anim:stop() end
            WindLine.remove_component(opt.comp_remove)
            return ''
        end
        return opt.result(bufnr, winnr)
    end
end

return M
