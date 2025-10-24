#!/bin/bash

# ===============================
# Папки
# ===============================
mkdir -p ~/.config/nvim/lua/core

# ===============================
# init.lua
# ===============================
cat > ~/.config/nvim/init.lua << 'EOF'
-- ===============================
-- ТОЧКА ВХОДА
-- ===============================

require("core.settings")
require("core.project")
require("core.sessions")
require("core.keymaps")
require("core.terminal")
require("core.autocmds")
require("core.diagnostics")
require("core.colorscheme")
require("core.lsp_cmp")
EOF

# ===============================
# core/settings.lua
# ===============================
cat > ~/.config/nvim/lua/core/settings.lua << 'EOF'
-- ===============================
-- БАЗОВЫЕ НАСТРОЙКИ
-- ===============================

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.g.mapleader = " "
EOF

# ===============================
# core/project.lua
# ===============================
cat > ~/.config/nvim/lua/core/project.lua << 'EOF'
-- ===============================
-- ОПРЕДЕЛЕНИЕ КОРНЯ ПРОЕКТА
-- ===============================
local M = {}

function M.get_project_root()
    local current_directory = vim.fn.getcwd()
    local current_file_path = vim.fn.expand('%:p')
    if current_file_path == '' then return current_directory end

    local project_markers = { ".git", "Makefile", "CMakeLists.txt", "compile_commands.json" }
    for _, marker in ipairs(project_markers) do
        if vim.fn.filereadable(current_directory .. "/" .. marker) == 1 or
           vim.fn.isdirectory(current_directory .. "/" .. marker) == 1 then
            return current_directory
        end
    end

    local git_root = vim.fn.systemlist('git -C ' .. vim.fn.shellescape(current_directory) .. ' rev-parse --show-toplevel 2>/dev/null')
    if vim.v.shell_error == 0 and git_root[1] and git_root[1] ~= '' then
        return git_root[1]
    end

    for _, marker in ipairs(project_markers) do
        local path = vim.fn.findfile(marker, vim.fn.expand('%:p:h') .. ';')
        if path ~= '' then
            return vim.fn.fnamemodify(path, ":p:h")
        end
    end

    return current_directory
end

vim.g.project_root = M.get_project_root()
vim.cmd("cd " .. vim.fn.fnameescape(vim.g.project_root))

return M
EOF

# ===============================
# core/sessions.lua
# ===============================
cat > ~/.config/nvim/lua/core/sessions.lua << 'EOF'
-- ===============================
-- УПРАВЛЕНИЕ СЕССИЯМИ S1–S5
-- ===============================
local session = {}
local session_directory = vim.fn.stdpath("data") .. "/sessions"
vim.fn.mkdir(session_directory, "p")

local function get_project_name()
    return vim.fn.getcwd():gsub("[:/\\]", "_")
end

local function get_session_path(slot)
    return string.format("%s/%s_s%d.vim", session_directory, get_project_name(), slot)
end

function session.save(slot)
    if slot < 1 or slot > 5 then
        vim.notify("❌ Неверный слот: " .. tostring(slot), vim.log.levels.ERROR)
        return
    end
    vim.cmd("mks! " .. vim.fn.fnameescape(get_session_path(slot)))
    vim.notify("💾 Сессия сохранена: s" .. slot, vim.log.levels.INFO)
end

function session.load(slot)
    if slot < 1 or slot > 5 then
        vim.notify("❌ Неверный слот: " .. tostring(slot), vim.log.levels.ERROR)
        return
    end
    local path = get_session_path(slot)
    if vim.fn.filereadable(path) == 1 then
        vim.cmd("source " .. vim.fn.fnameescape(path))
        vim.notify("📂 Сессия загружена: s" .. slot, vim.log.levels.INFO)
    else
        vim.notify("⚠️ Сессия s" .. slot .. " не найдена", vim.log.levels.WARN)
    end
end

function session.delete(slot)
    local path = get_session_path(slot)
    if vim.fn.filereadable(path) == 1 then
        os.remove(path)
        vim.notify("🗑️ Сессия удалена: s" .. slot, vim.log.levels.INFO)
    else
        vim.notify("⚠️ Сессия s" .. slot .. " не существует", vim.log.levels.WARN)
    end
end

vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function() pcall(session.save, 5) end,
})

_G.session = session
return session
EOF

# ===============================
# core/keymaps.lua
# ===============================
cat > ~/.config/nvim/lua/core/keymaps.lua << 'EOF'
-- ===============================
-- ГОРЯЧИЕ КЛАВИШИ
-- ===============================
local options = { noremap = true, silent = true }

for _, combo in ipairs({ "jk", "kj" }) do
    vim.keymap.set("i", combo, "<Esc>", options)
    vim.keymap.set("v", combo, "<Esc>", options)
    vim.keymap.set("t", combo, "<C-d>", options)
end

vim.keymap.set("n", "<leader>c", ":nohlsearch<CR>")
vim.keymap.set("n", "<leader>s", ":w<CR>")
vim.keymap.set("n", "<leader>x", ":x<CR>")
vim.keymap.set("n", "<leader>q", ":q!<CR>")

vim.keymap.set("n", "<C-PageDown>", "gt")
vim.keymap.set("n", "<C-PageUp>", "gT")
vim.keymap.set("n", "<C-t>", ":tabnew<CR>")

local session = require("core.sessions")
vim.keymap.set("n", "<leader>ss", function()
    local slot = tonumber(vim.fn.input("💾 Сохранить в слот (1–4): "))
    if slot and slot >= 1 and slot <= 4 then session.save(slot) end
end)

vim.keymap.set("n", "<leader>sl", function()
    local slot = tonumber(vim.fn.input("📂 Загрузить слот (1–5): "))
    if slot and slot >= 1 and slot <= 5 then session.load(slot) end
end)

vim.keymap.set("n", "<leader>sd", function()
    local slot = tonumber(vim.fn.input("🗑 Удалить слот (1–4): "))
    if slot and slot >= 1 and slot <= 4 then session.delete(slot) end
end)
EOF

# ===============================
# core/terminal.lua
# ===============================
cat > ~/.config/nvim/lua/core/terminal.lua << 'EOF'
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
EOF

# ===============================
# core/autocmds.lua
# ===============================
cat > ~/.config/nvim/lua/core/autocmds.lua << 'EOF'
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
EOF

# ===============================
# core/diagnostics.lua
# ===============================
cat > ~/.config/nvim/lua/core/diagnostics.lua << 'EOF'
-- ===============================
-- НАСТРОЙКА ДИАГНОСТИКИ
-- ===============================
vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
})
EOF

# ===============================
# core/colorscheme.lua
# ===============================
cat > ~/.config/nvim/lua/core/colorscheme.lua << 'EOF'
-- ===============================
-- ЦВЕТОВАЯ СХЕМА
-- ===============================
vim.cmd.colorscheme("retrobox")
EOF

# ===============================
# core/lsp_cmp.lua
# ===============================
cat > ~/.config/nvim/lua/core/lsp_cmp.lua << 'EOF'
-- ===============================
-- НАСТРОЙКА LSP И AUTOCOMPLETE
-- ===============================
local cmp = require('cmp')

cmp.setup({
    enabled = function()
        local buftype = vim.api.nvim_buf_get_option(0, "buftype")
        return not (buftype == "prompt" or buftype == "terminal")
    end,
})

cmp.setup({
    snippet = {
        expand = function(args)
            require("luasnip").lsp_expand(args.body)
        end,
    },
    mapping = cmp.mapping.preset.insert({
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        ["<Tab>"] = cmp.mapping.select_next_item(),
        ["<S-Tab>"] = cmp.mapping.select_prev_item(),
    }),
    sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" },
    }, {
        { name = "buffer" },
        { name = "path" },
    }),
})

vim.keymap.set("n", "<leader>rl", function()
    for name, _ in pairs(package.loaded) do
        if name:match("^user") or name:match("^config") or name:match("^plugins") then
            package.loaded[name] = nil
        end
    end
    dofile(vim.env.MYVIMRC)
    vim.notify("✅ Конфигурация перезагружена успешно!", vim.log.levels.INFO)
end, { desc = "Reload Neovim config" })
EOF

echo "✅ Neovim конфигурация создана полностью!"

