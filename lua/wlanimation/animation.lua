local utils = require('wlanimation.utils')
local hl_anim = require('wlanimation.highlight_anim')
local basic_anim = require('wlanimation.basic_anim')

---@class AnimationOption
local default_option = {
    type = 'highlight',
    highlights = {},
    __hl = {},
    __state = {},
    delay = 100,
    interval = 100,
    is_use_both = false, -- combine fg and bg action to 1
}
---@class Animation
local Animation = {}
Animation.__index = Animation

-- Used to provide a unique id for each component
local uuid_num = 1
---@param opt AnimationOption
function Animation.new(opt)
    opt = vim.tbl_extend('force', default_option, opt or {})
    if type(opt.highlights) == 'string' then
        opt.highlights = { opt.highlights }
    end
    -- backup old highlight color
    opt.__hl = {}
    opt.__state = { hl = {} }
    local anim = basic_anim
    if opt.type == 'highlight' then
        anim = hl_anim
    end
    anim.setup(opt)
    opt.uid = uuid_num
    opt.timeout = opt.timeout and opt.timeout * 1E9

    if not _G.__animation_list then
        _G.__animation_list = {}
    end

    local ani = setmetatable(opt, { __index = Animation })
    table.insert(_G.__animation_list, ani)
    return ani
end

function Animation:run()
    local _timer = vim.loop.new_timer()
    self.__is_run = true
    local tick = self.__tick
    local start_time = vim.loop.hrtime()
    _timer:start(
        self.delay,
        self.interval,
        vim.schedule_wrap(function()
            if not self.__is_run then
                return
            end
            local ctime = vim.loop.hrtime()
            if self.timeout and ctime > start_time + self.timeout then
                self:stop()
                return
            end
            tick(self)
        end)
    )
    self._timer = _timer
    return self
end

function Animation:stop()
    self.__is_run = false
    if self.__timer ~= nil then
        vim.loop.timer_stop(self.__timer)
    end
    self._timer = nil
    for _, value in pairs(self.__hl) do
        utils.highlight(value.name, value.fg, value.bg)
    end
    _G.__animation_list = vim.tbl_filter(function(ani)
        if ani.uid == self.uid then
            return false
        end
        return true
    end, _G.__animation_list)
    return self
end

local function stop_all()
    if _G.__animation_list then
        for _, ani in pairs(_G.__animation_list) do
            ani:stop()
        end
    end
    _G.__animation_list = {}
end

-- only use on_vimenter
local function run_all()
    if _G.__animation_list then
        for _, ani in pairs(_G.__animation_list) do
            ani:run()
        end
    end
end

return {
    new = Animation.new,
    stop_all = stop_all,
    run_all = run_all,
}
