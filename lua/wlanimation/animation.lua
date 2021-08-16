---@diagnostic disable: undefined-field
local utils = require('wlanimation.utils')
local hl_anim = require('wlanimation.highlight_anim')
local basic_anim = require('wlanimation.basic_anim')

---@class AnimationOption
local default_option = {
    type = 'highlight',
    highlights = {},
    __hl = {},
    __state = {},
    __timer = nil,
    __tick = nil,
    delay = 100,
    interval = 100,
    is_use_both = false, -- combine fg and bg action to 1
}

_G.WindLine.anim_list = _G.WindLine.anim_list or {}

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
    opt.name = opt.name or ('name' .. opt.uid)
    opt.timeout = opt.timeout and opt.timeout * 1E9
    local ani = setmetatable(opt, { __index = Animation })
    table.insert(_G.WindLine.anim_list, ani)
    uuid_num = uuid_num + 1
    return ani
end

function Animation:run()
    if self.is_run then
        self:stop(true)
    end
    self.is_run = true
    local timer = vim.loop.new_timer()
    local tick = self.__tick
    local start_time = vim.loop.hrtime()
    timer:start(
        self.delay,
        self.interval,
        vim.schedule_wrap(function()
            if not self.is_run then
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
    self.__timer = timer
    return self
end

function Animation:stop(is_not_remove)
    if not self.is_run then
        return
    end
    self.is_run = false
    if self.__timer then
        self.__timer:stop()
        vim.loop.timer_stop(self.__timer)
    end
    self.__timer = nil
    if self.__stop then
        self.__stop(self)
    end
    if self.on_stop then
        self.on_stop()
    end
    if not is_not_remove then
        _G.WindLine.anim_list = vim.tbl_filter(function(ani)
            if ani.uid == self.uid then
                return false
            end
            return true
        end, _G.WindLine.anim_list)
    end
    return self
end

local function pause_all()
    if _G.WindLine.anim_list then
        for _, ani in pairs(_G.WindLine.anim_list) do
            ani:stop(true)
        end
    end
end

local function stop_all()
    pause_all()
    _G.WindLine.anim_list = {}
end

-- only use on_vimenter
local function run_all()
    if _G.WindLine.anim_list then
        for _, ani in pairs(_G.WindLine.anim_list) do
            if not ani.is_run then
                ani:run()
            end
        end
    end
end

return {
    new = Animation.new,
    pause_all = pause_all,
    run_all = run_all,
    stop_all = stop_all,
}
