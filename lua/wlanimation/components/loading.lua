local animation = require('wlanimation')
local efffects = require('wlanimation.effects')
local tbl_loading = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }

local function create_loading(opt)
    opt = vim.tbl_extend('force', {
        spin_tbl = tbl_loading,
        interval = 200,
    }, opt or {})
    local loading_text = ''
    local anim = animation.basic_animation({
        timeout = nil,
        delay = 0,
        interval = opt.interval,
        effect = efffects.list_text(opt.spin_tbl),
        on_tick = function(value)
            loading_text = value
        end,
    })

    return function(isLoading)
        if anim.is_run then
            if not isLoading then
                anim:stop()
                return ''
            end
            return loading_text
        else if isLoading then
                anim:run()
                return loading_text
            end
        end

    end
end

return { create_loading = create_loading }
