local Animation = require('wlanimation.animation')
local M = {}

-- we need animation run after vim enter
local check_enter = function(anim)
    if M.is_enter == true then
        return anim:run()
    end
    vim.defer_fn(function()
        -- if user call animation libary after vimenter then
        -- we wait a bit to  call anim
        M.on_vimenter()
    end, 200)
    return anim
end

M.is_enter = false

M.animation = function(opts)
    assert(type(opts.data) == 'table', 'param data is required')
    opts = vim.tbl_extend('force', {
        interval = 300,
        delay = 0,
    }, opts)

    local hl_data = _G.WindLine.hl_data
    local hl_list = {}

    local function addAnimation(new_hl)
        for _, hl in pairs(hl_list) do
            if new_hl.name == hl.name then
                if new_hl.fg_effect then
                    hl.fg_effect = new_hl.fg_effect
                end
                if new_hl.bg_effect then
                    hl.bg_effect = new_hl.bg_effect
                end
                hl.color = hl.color .. new_hl.color
                return
            end
        end
        table.insert(hl_list, new_hl)
    end

    for _, effect in pairs(opts.data) do
        for name, _ in pairs(hl_data) do
            if string.match(name, 'WL' .. effect[1]) then
                addAnimation({
                    color = effect[1],
                    name = name,
                    fg_effect = effect[2](),
                })
            end
            if string.match(name, '_' .. effect[1]) then
                addAnimation({
                    color = effect[1],
                    name = name,
                    bg_effect = effect[2](),
                })
            end
        end
    end

    local anim = Animation.new({
        type = 'highlight',
        highlights = hl_list,
        interval = opts.interval,
        delay = opts.delay,
        timeout = opts.timeout,
    })
    return check_enter(anim)
end

---@param opts AnimationOption
---@return Animation
M.basic_animation = function(opts)
    opts.type = opts.type or 'basic'
    local anim = Animation.new(opts)
    return check_enter(anim)
end

local anim_waitting = {}
--- add animation or job on list to will run after setup
M.add_anim_job = function(anim)
    table.insert(anim_waitting, anim)
    M.on_vimenter()
end

M.on_vimenter = function()
    if M.is_enter then
        return true
    end
    M.is_enter = true
    -- do that because we don't need WindLine require this animation lib on
    -- statup
    _G.WindLine.anim_pause = Animation.pause_all
    _G.WindLine.anim_run = Animation.run_all
    _G.WindLine.anim_stop = Animation.stop_all
    _G.WindLine.anim_reset = function()
        -- remove all animtion and put the animtation on waiting to rerun on
        -- setup
        Animation.stop_all()
        _G.WindLine.anim_list = anim_waitting
        anim_waitting = {}
    end

    -- running waiting animation
    Animation.run_all()
end
M.stop_all = Animation.stop_all

vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("WLAnimation", { clear = true }),
    pattern = "*",
    command = "lua require('wlanimation').on_vimenter()"
})

return M
