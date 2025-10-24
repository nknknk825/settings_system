-- ~/.config/nvim/lua/core/treesitter.lua
local M = {}

function M.setup()
    local ok, ts = pcall(require, "nvim-treesitter.configs")
    if not ok then
        vim.notify("⚠️ Treesitter не установлен", vim.log.levels.WARN)
        return
    end

    ts.setup {
        ensure_installed = { "c", "cpp", "java", "asm" }, -- языки
        highlight = { enable = true },                    -- подсветка
        indent = { enable = true },                       -- автоотступы
    }
end

return M

