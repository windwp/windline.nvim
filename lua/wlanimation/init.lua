local Animation = require('wlanimation.animation')
local M = {}

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
        for _, value in pairs(hl_data) do
            if string.match(value.name, 'WL' .. effect[1]) then
                addAnimation({
                    color = effect[1],
                    name = value.name,
                    fg_effect = effect[2](),
                })
            end
            if string.match(value.name, '_' .. effect[1]) then
                addAnimation({
                    color = effect[1],
                    name = value.name,
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
    -- we need to animation run after vim enter
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

M.on_vimenter = function()
    if M.is_enter then return true end
    M.is_enter = true
    -- need to wait on colorscheme finish
    -- do that because we don't need WindLine require this animation lib
    vim.defer_fn(function()
        _G.WindLine.anim_stop = Animation.stop_all
    end,100)
    Animation.run_all()
end

M.basic_animation = function(opts)
    local anim = Animation.new({
        type = 'text',
        on_tick = opts.on_tick,
        effect = opts.effect,
        interval = opts.interval,
        delay = opts.delay,
        timeout = opts.timeout,
    })
    return anim:run()
end

M.stop_all = Animation.stop_all

vim.api.nvim_exec(
    [[augroup WLAnimation
    au!
    au VimEnter * lua require('wlanimation').on_vimenter()
    augroup END]],
    false
)

return M
