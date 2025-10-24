-- ===============================
-- ТЕРМИНАЛЫ
-- ===============================
local M = {}
local opts = { noremap = true, silent = true }
local project = require("core.project")

vim.keymap.set("n", "<leader>tm", function()
    local root_dir = project.get_project_root()
    vim.cmd("belowright split term://" .. vim.o.shell)
    vim.cmd("resize 12")
    vim.cmd("startinsert")
    vim.defer_fn(function()
        vim.cmd('call chansend(b:terminal_job_id, "cd ' .. vim.fn.shellescape(root_dir) .. ' && clear\\n")')
    end, 100)
    vim.cmd([[
        autocmd TermClose * if &buftype == 'terminal' | exe 'close' | endif
    ]])
end, opts)

vim.keymap.set("n", "<leader>r", function()
    local root_dir = project.get_project_root()
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.7)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
    })

    vim.fn.termopen("bash", {
        cwd = root_dir,
        on_exit = function(_, code, _)
            if code == 0 then
                vim.api.nvim_chan_send(vim.b.terminal_job_id, "\nНажми Enter чтобы закрыть...\n")
            end
        end,
    })

    vim.cmd("startinsert")

    vim.defer_fn(function()
        local cmd = "cd " .. vim.fn.shellescape(root_dir) .. " && clear && make\n"
        vim.fn.chansend(vim.b.terminal_job_id, cmd)
    end, 200)

    vim.keymap.set('t', 'jk', function() vim.api.nvim_win_close(win, true) end, { buffer = buf, noremap = true, silent = true })
    vim.keymap.set('t', 'kj', function() vim.api.nvim_win_close(win, true) end, { buffer = buf, noremap = true, silent = true })
end, { noremap = true, silent = true, desc = "Run make in popup terminal" })

return M
