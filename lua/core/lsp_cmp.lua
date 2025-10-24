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
