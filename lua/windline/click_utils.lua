local M = {}
local d_click = {}
local d_click_name = {}
local n_click_id = 0

M.add_click_listerner = function(func)
    if type(func) == 'function' then
        n_click_id = n_click_id + 1
        d_click[n_click_id] = func
        return n_click_id
    end
    return func
end

M.make_click = function(name, func)
    if not d_click_name[name] then
        d_click_name[name] = M.add_click_listerner(func)
    end
    return d_click_name[name]
end

M.click_handler = function(index)
    if d_click[index] then
        d_click[index]()
    end
end

M.clear = function()
    d_click = {}
    n_click_id = 0
    d_click_name = {}
end
return M
