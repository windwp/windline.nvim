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

    local bg_ani = Animation.new({
        highlights = hl_list,
        interval = opts.interval,
        delay = opts.delay,
        timeout = opts.timeout,
    })
    _G.WindLine.stop = Animation.stop_all
    return bg_ani:run()
end
M.stop_all=Animation.stop_all

return M
