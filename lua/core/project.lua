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
