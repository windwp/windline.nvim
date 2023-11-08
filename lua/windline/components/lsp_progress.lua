local M = {}
local uv = vim.uv or vim.loop

M.lsp_progress = function(opts)
    -- stylua: ignore
    opts = vim.tbl_extend('force', {
        show_server_name = true,
        message = { commenced = 'In Progress', completed = 'Completed' },
    }, opts or {})
    local clients = {}

    local function handler(_, msg, info)
        local token = tostring(msg.token)
        local val = msg.value
        local client_id = tostring(info.client_id)
        if token then
            if clients[client_id] == nil then
                clients[client_id] = {
                    message = '',
                    name = vim.lsp.get_client_by_id(info.client_id).name,
                    progress = {},
                }
            end
            local client = clients[client_id]
            if client.progress[token] == nil then
                client.progress[token] = {
                    message = '',
                    title = '',
                    percentage = 0,
                }
            end

            local progess = client.progress[token]
            if val then
                if val.kind == 'begin' then
                    progess.message = opts.message.commenced
                    progess.title = val.title and (val.title .. ' ') or ''
                elseif val.kind == 'report' and val.message then
                    progess.message = progess.title .. val.message
                    progess.percentage = val.percentage or 0
                elseif val.kind == 'end' then
                    progess.percentage = 100
                    progess.hrtime = uv.hrtime()
                    progess.is_done = true
                    progess.message = opts.message.completed
                end
            end
        end
    end
    vim.lsp.handlers['$/progress'] = handler

    return function(_, _, _, is_float)
        local text = ''
        local percentmsg = is_float and '%' or '%%'
        for _, client in pairs(clients) do
            local remove_progress = {}
            local is_have_msg = true
            for key_p, progress in pairs(client.progress) do
                if not progress.is_done and progress.message and is_have_msg then
                    is_have_msg = false
                    text = text
                        .. string.format(
                            '%s%s %s',
                            opts.show_server_name
                                    and (' ' .. client.name .. ' ')
                                or ' ',
                            progress.message,
                            progress.percentage ~= 0
                                    and progress.percentage .. percentmsg
                                or ''
                        )
                end
                -- delay 1 second to remove progress
                if
                    progress.is_done
                    and uv.hrtime() - 1e9 > progress.hrtime
                then
                    table.insert(remove_progress, key_p)
                end
            end
            for _, key_p in ipairs(remove_progress) do
                client.progress[key_p] = nil
            end
            if is_have_msg then
                clients[client.name] = nil
            end
        end
        return text
    end
end

return M
