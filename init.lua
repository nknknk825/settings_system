-- ===============================
-- ТОЧКА ВХОДА
-- ===============================

-- Установка настроек
require("core.settings")

-- Установка плагинов
require("lazy").setup("plugins")

require("core.project")
require("core.sessions")
require("core.keymaps")
require("core.terminal")
require("core.autocmds")
require("core.diagnostics")
require("core.colorscheme")
require("core.lsp_cmp")

-- Treesitter (подсветка синтаксиса)
require("core.treesitter").setup()

