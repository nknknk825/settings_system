-- ===============================
-- АВТОКОМАНДЫ
-- ===============================
local project = require("core.project")
local uv = vim.loop

vim.api.nvim_create_autocmd("TermOpen", { pattern = "*", callback = function() vim.cmd("startinsert") end })
vim.api.nvim_create_autocmd("TermEnter", { callback = function() vim.cmd("startinsert") end })
vim.api.nvim_create_autocmd("TermLeave", { callback = function() vim.cmd("stopinsert") end })
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "CursorMoved", "FocusGained" }, {
    callback = function()
        if vim.bo.buftype == "terminal" then vim.cmd("startinsert") end
    end,
})

local function update_project_root(new_root)
    if not new_root or new_root == "" then return end
    if vim.fn.isdirectory(new_root) == 1 and new_root ~= vim.g.project_root then
        vim.g.project_root = new_root
        pcall(function() vim.cmd("cd " .. vim.fn.fnameescape(new_root)) end)
    end
end

vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    callback = function()
        local ok, new_root = pcall(project.get_project_root)
        if ok then update_project_root(new_root) end
    end,
})

vim.api.nvim_create_autocmd("DirChanged", {
    callback = function()
        update_project_root(uv.cwd())
    end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = { "*.cpp", "*.c", "*.hpp", "*.h" },
    callback = function()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients == 0 then
            local root = project.get_project_root()
            vim.lsp.start({
                name = "clangd",
                cmd = { "clangd" },
                root_dir = root,
                filetypes = { "c", "cpp" },
            })
        end
    end,
})

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local cmp = require('cmp')
        cmp.setup.buffer({
            sources = {
                { name = 'nvim_lsp' },
                { name = 'buffer' },
                { name = 'path' },
                { name = 'luasnip' },
            },
        })
    end,
})
