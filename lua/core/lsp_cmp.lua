-- ===============================
-- НАСТРОЙКА LSP И AUTOCOMPLETE
-- ===============================
local cmp = require('cmp')

local function set_cmp_colors()
  vim.api.nvim_set_hl(0, "CmpItemAbbr", { fg = "#d19a66" })
  vim.api.nvim_set_hl(0, "CmpItemAbbrMatch", { fg = "#e5c07b", bold = true })
  vim.api.nvim_set_hl(0, "CmpItemKind", { fg = "#c678dd" })
  vim.api.nvim_set_hl(0, "CmpItemMenu", { fg = "#56b6c2" })
end


cmp.setup({
    enabled = function()
        local buftype = vim.api.nvim_buf_get_option(0, "buftype")
        return not (buftype == "prompt" or buftype == "terminal")
    end,
    set_cmp_colors(),
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
    set_cmp_colors(),
})

vim.keymap.set("n", "<leader>rl", function()
    -- Очищаем только модули вашей конфигурации
    for name, _ in pairs(package.loaded) do
        if name:match("^core%.") or name == "plugins" then
            package.loaded[name] = nil
        end
    end
    
    -- Перезагружаем init.lua
    vim.cmd('source $MYVIMRC')
    
    vim.notify("✅ Конфигурация перезагружена успешно!", vim.log.levels.INFO)
end, { desc = "Reload Neovim config" })
