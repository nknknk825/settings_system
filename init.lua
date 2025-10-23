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

-- ===============================
-- ФУНКЦИЯ: Определение корня проекта
-- ===============================
function get_project_root()
    local cwd = vim.fn.getcwd()
    local current_file = vim.fn.expand('%:p')

    -- Если файл не открыт — возвращаем текущую папку
    if current_file == '' then
        return cwd
    end

    -- Если текущая директория уже содержит .git или Makefile — это корень
    local markers = { ".git", "Makefile", "CMakeLists.txt", "compile_commands.json" }
    for _, name in ipairs(markers) do
        if vim.fn.filereadable(cwd .. "/" .. name) == 1 or vim.fn.isdirectory(cwd .. "/" .. name) == 1 then
            return cwd
        end
    end

    -- Пробуем найти git-корень
    local git_root = vim.fn.systemlist('git -C ' .. vim.fn.shellescape(cwd) .. ' rev-parse --show-toplevel 2>/dev/null')
    if vim.v.shell_error == 0 and git_root[1] and git_root[1] ~= '' then
        return git_root[1]
    end

    -- Альтернатива: ищем любой файл-маркер вверх по дереву
    for _, name in ipairs(markers) do
        local path = vim.fn.findfile(name, vim.fn.expand('%:p:h') .. ';')
        if path ~= '' then
            return vim.fn.fnamemodify(path, ":p:h")
        end
    end

    -- Иначе остаёмся в текущей папке
    return cwd
end

-- ===============================
-- ПЛАГИН-МЕНЕДЖЕР lazy.nvim
-- ===============================
require("lazy").setup({
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = { "cpp", "c", "lua", "python" },
                highlight = { enable = true },
                indent = { enable = true },
            })
        end,
    },

    {
        "neovim/nvim-lspconfig",
        config = function()
            local capabilities = vim.lsp.protocol.make_client_capabilities()

            -- Автозапуск clangd для C/C++
            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "c", "cpp" },
                callback = function()
                    local root = get_project_root()

                    -- Проверяем, не запущен ли уже clangd
                    local existing = vim.lsp.get_clients({ name = "clangd" })
                    if #existing == 0 then
                        vim.lsp.start({
                            name = "clangd",
                            cmd = { "clangd" },
                            root_dir = root,
                            capabilities = capabilities,
                            filetypes = { "c", "cpp" },
                        })
                    end
                end,
            })
        end,
    },
})

-- ===============================
-- УСТАНАВЛИВАЕМ ГЛОБАЛЬНЫЙ КОРЕНЬ
-- ===============================
vim.g.project_root = get_project_root()
vim.cmd("cd " .. vim.fn.fnameescape(vim.g.project_root))

-- ===============================
-- КЛАВИШИ ДЛЯ ВЫХОДА ИЗ РЕЖИМОВ
-- ===============================
local opts = { noremap = true, silent = true }
for _, combo in ipairs({ "jk", "kj" }) do
    vim.keymap.set('i', combo, '<Esc>', opts)
    vim.keymap.set('v', combo, '<Esc>', opts)
    vim.keymap.set('t', combo, '<C-d>', opts)
end

-- ===============================
-- ТЕРМИНАЛ В КОРНЕ ПРОЕКТА
-- ===============================
vim.keymap.set('n', '<leader>tm', function()
    local root_dir = get_project_root()

    -- открываем терминал внизу
    vim.cmd('belowright split term://' .. vim.o.shell)
    vim.cmd('resize 12')

    -- сразу переходим в insert-режим
    vim.cmd('startinsert')

    -- переходим в корень проекта
    vim.defer_fn(function()
        vim.cmd('call chansend(b:terminal_job_id, "cd ' .. vim.fn.shellescape(root_dir) .. ' && clear\\n")')
    end, 100)

    -- автозакрытие терминала после выхода (Ctrl+D или exit)
    vim.cmd([[
        autocmd TermClose * if &buftype == 'terminal' | exe 'close' | endif
    ]])
end, opts)



-- ===============================
-- АВТОМАТИЧЕСКИЙ INSERT В ТЕРМИНАЛЕ
-- ===============================
vim.api.nvim_create_autocmd("TermOpen", {
    pattern = "*",
    callback = function()
        vim.cmd("startinsert")
    end,
})

-- Автоматически включаем режим вставки при входе в терминал
vim.api.nvim_create_autocmd("TermEnter", {
  callback = function()
    vim.cmd("startinsert")
  end
})

-- Автоматически выходим из вставки при уходе из терминала
vim.api.nvim_create_autocmd("TermLeave", {
  callback = function()
    vim.cmd("stopinsert")
  end
})
-- При клике мышью в окно терминала — сразу вставка
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "CursorMoved", "FocusGained" }, {
  callback = function()
    local buftype = vim.bo.buftype
    if buftype == "terminal" then
      vim.cmd("startinsert")
    end
  end,
})
vim.keymap.set('n', '<leader>n', function()
    local root_dir = get_project_root()

    -- Размеры popup-а
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.7)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    -- Создаем скрытый буфер для терминала
    local buf = vim.api.nvim_create_buf(false, true)

    -- Создаём всплывающее окно
    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'rounded',
    })

    -- Запускаем терминал в этом окне
    vim.fn.termopen('bash', {
        cwd = root_dir,
        on_exit = function(_, code, _)
            if code == 0 then
                vim.api.nvim_chan_send(vim.b.terminal_job_id, "\nНажми Enter чтобы закрыть...\n")
            end
        end,
    })

    -- Переходим в insert (режим терминала)
    vim.cmd('startinsert')

    -- Ждём немного и запускаем make
    vim.defer_fn(function()
        local cmd = 'cd ' .. vim.fn.shellescape(root_dir) .. ' && clear && make\n'
        vim.fn.chansend(vim.b.terminal_job_id, cmd)
    end, 200)

    -- Когда пользователь нажимает Enter — закрываем окно
    vim.keymap.set('t', 'jk', function()
        vim.api.nvim_win_close(win, true)
        end, { buffer = buf, noremap = true, silent = true })

    vim.keymap.set('t', 'kj', function()
        vim.api.nvim_win_close(win, true)
        end, { buffer = buf, noremap = true, silent = true })
end, { noremap = true, silent = true, desc = "Run make in popup terminal" })


-- ===============================
-- ДИАГНОСТИКА
-- ===============================
vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
})

-- ===============================
-- ТЕМА
-- ===============================
vim.cmd.colorscheme("retrobox")

-- ===============================
-- ОБНОВЛЕНИЕ КОРНЯ ПРИ СМЕНЕ ФАЙЛА
-- ===============================
vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    callback = function()
        local new_root = get_project_root()
        -- Проверяем, что это реальный путь
        if new_root ~= vim.g.project_root and vim.fn.isdirectory(new_root) == 1 then
            vim.g.project_root = new_root
            pcall(function()
                vim.cmd("cd " .. vim.fn.fnameescape(new_root))
            end)
        end
    end,
})

