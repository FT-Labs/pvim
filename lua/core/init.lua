local opt = vim.opt
local g = vim.g
local config = require("core.utils").load_config()

-------------------------------------- globals -----------------------------------------
g.nvchad_theme = config.ui.theme
g.base46_cache = vim.fn.stdpath "data" .. "/nvchad/base46/"
g.toggle_theme_icon = "   "
g.transparency = config.ui.transparency
g.mapleader = ";"
g.maplocalleader = ";"

opt.encoding = "utf-8"
opt.mouse = "a"
opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"
opt.foldlevelstart = 20
opt.hidden = true
opt.number = true
opt.hlsearch = false
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.cinoptions = '(0'
opt.expandtab = false
opt.smartindent = true
opt.completeopt = { "menuone", "noselect" }
opt.wildignorecase = true
opt.viminfo="'1000,f1"
opt.ignorecase = true
opt.conceallevel = 0
opt.concealcursor = "vin"
opt.cursorline = true
opt.cursorlineopt = "number"
opt.pumheight = 15
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.updatetime = 200
opt.undofile = true
opt.splitbelow = true
opt.splitright = true
opt.swapfile = false
opt.signcolumn = "yes"
opt.showmode = false
opt.shortmess:append "c"
opt.whichwrap:append "<,>,[,],h,l"
-- Make compatible with st, truecolors
vim["&t_8f"] = "\\<Esc>[38;2;%lu;%lu;%lum"
vim["&t_8b"] = "\\<Esc>[48;2;%lu;%lu;%lum"
opt.termguicolors = true
vim.cmd [[set formatoptions-=cro]]
require "core.macros"
require "core.autocmds"



-------------------------------------- options ------------------------------------------
-- disable some default providers
for _, provider in ipairs { "node", "perl", "python3", "ruby" } do
  vim.g["loaded_" .. provider .. "_provider"] = 0
end

-- add binaries installed by mason.nvim to path
vim.env.PATH = vim.fn.stdpath "data" .. "/mason/bin:" .. vim.env.PATH

-------------------------------------- autocmds ------------------------------------------
local autocmd = vim.api.nvim_create_autocmd

-- dont list quickfix buffers
autocmd("FileType", {
  pattern = "qf",
  callback = function()
    vim.opt_local.buflisted = false
  end,
})

-- reload some chadrc options on-save
autocmd("BufWritePost", {
  pattern = vim.tbl_map(function(path)
    return vim.fs.normalize(vim.loop.fs_realpath(path))
  end, vim.fn.glob(vim.fn.stdpath "config" .. "/lua/custom/**/*.lua", true, true, true)),
  group = vim.api.nvim_create_augroup("ReloadNvChad", {}),

  callback = function(opts)
    local fp = vim.fn.fnamemodify(vim.fs.normalize(vim.api.nvim_buf_get_name(opts.buf)), ":r") --[[@as string]]
    local app_name = vim.env.NVIM_APPNAME and vim.env.NVIM_APPNAME or "nvim"
    local module = string.gsub(fp, "^.*/" .. app_name .. "/lua/", ""):gsub("/", ".")

    require("plenary.reload").reload_module "base46"
    require("plenary.reload").reload_module(module)

    config = require("core.utils").load_config()

    vim.g.nvchad_theme = config.ui.theme
    vim.g.transparency = config.ui.transparency

    -- statusline
    require("plenary.reload").reload_module("nvchad.statusline." .. config.ui.statusline.theme)
    vim.opt.statusline = "%!v:lua.require('nvchad.statusline." .. config.ui.statusline.theme .. "').run()"

    -- tabufline
    if config.ui.tabufline.enabled then
      require("plenary.reload").reload_module "nvchad.tabufline.modules"
      vim.opt.tabline = "%!v:lua.require('nvchad.tabufline.modules').run()"
    end

    require("base46").load_all_highlights()
    -- vim.cmd("redraw!")
  end,
})

-------------------------------------- commands ------------------------------------------
local new_cmd = vim.api.nvim_create_user_command

new_cmd("NvChadUpdate", function()
  require "nvchad.updater"()
end, {})
