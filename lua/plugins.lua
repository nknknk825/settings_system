-- ===============================
-- ПЛАГИНЫ
-- ===============================
return {
    -- nvim-cmp и источники
    { "hrsh7th/nvim-cmp" },
    { "hrsh7th/cmp-buffer" },
    { "hrsh7th/cmp-path" },
    { "hrsh7th/cmp-nvim-lsp" },
    { "saadparwaiz1/cmp_luasnip" },

    -- LuaSnip
    { "L3MON4D3/LuaSnip" },

    -- LSP config
    { "neovim/nvim-lspconfig" },

    -- Цветовая схема (retrobox)
    { "loctvl842/monokai-pro.nvim" },
    { "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" },
    -- для asm подсветки
--    { "rhysd/asm.vim" }, 
}
