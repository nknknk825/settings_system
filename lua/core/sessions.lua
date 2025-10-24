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
