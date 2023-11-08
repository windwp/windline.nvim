---@diagnostic disable: need-check-nil
local windline = require('windline')
local cava_text = "OK"
local uv = vim.uv or vim.loop
if _G._cava_stop then
    _G._cava_stop()
end

vim.api.nvim_create_autocmd("VimLeave", {
    pattern = "*",
    callback = function()
        vim.fn.system({ "pkill", '-9', "cava" })
    end
})
local create_cava_colors = function(colors)
    local HSL = require('wlanimation.utils')
    local d_colors = {
        "green", "blue", "yellow", "magenta", "red", "cyan"
    }
    local cava_colors = HSL.rgb_to_hsl(colors[d_colors[math.random(#d_colors)]]):tints(10, 8)
    for i = 1, 8, 1 do
        colors["cava" .. i] = cava_colors[i]:to_rgb()
    end
    return colors
end

local bars = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }
local cava_comp = {
    name = "cava",
    hl_colors = {
        cava1 = { "cava1", "NormalBg" },
        cava2 = { "cava2", "NormalBg" },
        cava3 = { "cava3", "NormalBg" },
        cava4 = { "cava4", "NormalBg" },
        cava5 = { "cava5", "NormalBg" },
        cava6 = { "cava6", "NormalBg" },
        cava7 = { "cava7", "NormalBg" },
        cava8 = { "cava8", "NormalBg" },
    },
    text = function()
        local result = {}
        for i = 1, 60, 2 do
            local c = tonumber(cava_text:sub(i, i))
            if c then
                c = c + 1
                result[#result + 1] = { bars[c], "cava" .. c }
            end
        end
        -- result[#result+1] = {"%="}
        return result
    end,
    click = function()
        vim.notify("change cava colors")
        windline.change_colors(create_cava_colors(windline.get_colors()))
    end
}

local function run_cava()
    local sourced_file = require('plenary.debug_utils').sourced_filepath()
    local plugin_directory = vim.fn.fnamemodify(sourced_file, ':h:h:h:h')

    vim.fn.system({ "pkill", '-9', "cava" })
    local cava_path = vim.fn.expand(plugin_directory .. "/scripts/cava.sh")
    local stdin = uv.new_pipe(false)
    local stdout = uv.new_pipe(false)
    local stderr = uv.new_pipe(false)
    local handle = uv.spawn(cava_path,
        { stdio = { stdin, stdout, stderr }, },
        function() _G._cava_stop() end
    )

    uv.read_start(stdout, vim.schedule_wrap(function(_, data)
        if data then
            cava_text = data
            vim.cmd.redrawstatus()
        end
    end))
    _G._cava_stop = function()
        stdin:read_stop()
        stdin:close()
        stdout:read_stop()
        stdout:close()
        stderr:read_stop()
        stderr:close()
        handle:close()
        _G._cava_stop = nil
    end
end

local M = {}
M.is_stop = true

M.toggle = function()
    if M.is_stop then
        run_cava()
        windline.add_component(cava_comp, {
            name = "cava",
            position = "right",
            auto_remove = true,
            colors_name = create_cava_colors
        })
    else
        vim.fn.system({ "pkill", '-9', "cava" })
        if _G._cava_stop then
            _G._cava_stop()
        end
        windline.remove_component(cava_comp)
    end
    M.is_stop = not M.is_stop
end
-- M.toggle()
return M
