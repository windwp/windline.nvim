local utils = import('plug.animation.utils')
local HSL=import('plug.animation.hsl')

---@class AnimationOption
local default_option = {
    highlights = {},
    delay = 100,
    interval = 100,
    is_use_both = false,-- combine fg and bg action to 1
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
        opt.highlights = {opt.highlights}
    end
    -- backup old highlight color
    opt.__hl={}
    opt.__state = {hl = {}}
    for _, group_name in pairs(opt.highlights) do
        local fg, bg = utils.get_hsl_color(group_name.name)
        table.insert(opt.__hl,{
            name = group_name.name,
            fg = fg,
            bg = bg
        })
        table.insert(opt.__state.hl,{
            name = group_name.name,
            color = group_name.color,
            fg_effect = group_name.fg_effect,
            bg_effect = group_name.bg_effect,
            fg = fg and HSL.new(fg.H, fg.S, fg.L) or nil,
            bg = bg and HSL.new(bg.H, bg.S, bg.L) or nil
        })
    end
    uuid_num = uuid_num + 1
    opt.uid = uuid_num
    opt.timeout = opt.timeout and opt.timeout * 1E9

    if not _G.__animation_list then
        _G.__animation_list = {}
    end

    local ani = setmetatable(opt, {__index = Animation})
    table.insert(_G.__animation_list, ani)
    return ani
end


local function tick(animation)
    local cache = { }
    --- all animation should have same value in 1 tick
    for _, value in pairs(animation.__state.hl) do
        local fg, bg = value.fg, value.bg
        if
            fg
            and not cache["fg" .. value.color]
            and value.fg_effect then
            cache["fg" .. value.color] = value.fg_effect(fg)
        end
        if
            bg
            and not cache["bg" .. value.color]
            and value.bg_effect
        then
            cache["bg" .. value.color] = value.bg_effect(bg)
        end

        if value.fg_effect then
            fg = cache["fg" .. value.color] or fg
        end

        if value.bg_effect then
            bg = cache["bg" .. value.color] or bg
        end

        if fg == false or bg == false then
            animation:stop()
            return
        end
        utils.highlight(value.name, fg, bg)
        value.fg = fg
        value.bg = bg
    end
end

function Animation:run()
    local _timer = vim.loop.new_timer()
    self.__is_run = true
    if self.on_start then
        local fg, bg = self.on_start()
        if type(fg) == 'string' then
            local color =  utils.rgb_to_hsl(fg)
            for _,value in pairs(self.__state.hl) do
                value.fg = HSL.new(color.H,color.S,color.L)
            end
        end
        if type(bg) == 'string' then
            local color =  utils.rgb_to_hsl(bg)
            for _,value in pairs(self.__state.hl) do
                value.bg = HSL.new(color.H,color.S,color.L)
            end
        end
    end
    local start_time = vim.loop.hrtime()
    _timer:start(self.delay, self.interval,
        vim.schedule_wrap(function()
            if not self.__is_run then return end
            local ctime = vim.loop.hrtime()
            if
                self.timeout
                and ctime > start_time + self.timeout
            then
                self:stop()
                return
            end
            tick(self)
        end))
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
    for index,ani in pairs(_G.__animation_list) do
        if ani.uid == self.uid then
            table.remove(_G.__animation_list, index)
        end
    end
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


return {
    new = Animation.new,
    stop_all = stop_all
}

