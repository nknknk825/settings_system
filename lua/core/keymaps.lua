-- ===============================
-- ГОРЯЧИЕ КЛАВИШИ
-- ===============================
local options = { noremap = true, silent = true }

for _, combo in ipairs({ "jk", "kj" }) do
    vim.keymap.set("i", combo, "<Esc>", options)
    vim.keymap.set("v", combo, "<Esc>", options)
    vim.keymap.set("t", combo, "<C-d>", options)
end
--            os.execute([[/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -File "P:\nvim\set_english.ps1"]])

for _, combo in ipairs({ "<C>ол", "<C>ло" }) do
    vim.keymap.set("i", combo, function()
        vim.fn.system([[
            /mnt/c/Windows/System32/cmd.exe /c "autohotkey.exe P:\nvim\switch_layout.ahk"
        ]])
        vim.api.nvim_input("<Esc>")
        return ""
    end, { expr = true })
end


vim.keymap.set("n", "<leader>c", ":nohlsearch<CR>")
vim.keymap.set("n", "<leader>w", ":w<CR>")
vim.keymap.set("n", "<leader>x", ":x<CR>")
vim.keymap.set("n", "<leader>q", ":q!<CR>")

vim.keymap.set("n", "<C-PageDown>", "gt")
vim.keymap.set("n", "<C-PageUp>", "gT")
vim.keymap.set("n", "<C-t>", ":tabnew<CR>")

-- control session keymap
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

vim.keymap.set("n", "<leader>qa", ":qa<CR>")

-- error keymap

vim.keymap.set("n", "<leader>e", function()
  vim.diagnostic.open_float(nil, { focus = false })
end, { desc = "Показать ошибку под курсором" })

