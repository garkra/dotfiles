-- ╔══════════════════════════════════════════════════════════════╗
-- ║                     KEYBINDING INDEX                       ║
-- ╠══════════════════════════════════════════════════════════════╣
-- ║ GENERAL (remap.lua)                                        ║
-- ║   n  <leader>pv     Open file explorer (oil.nvim)           ║
-- ║   n  -              Open parent directory (oil.nvim)        ║
-- ║   i  jk             Exit insert mode                       ║
-- ║   i  <C-c>          Exit insert mode                       ║
-- ║   n  Q              Disabled                                ║
-- ║   v  J/K            Move selection down/up                  ║
-- ║   n  J              Join lines (centered)                   ║
-- ║   n  <C-d>/<C-u>    Scroll down/up (centered)              ║
-- ║   n  n/N            Next/prev search (centered)             ║
-- ║   x  <leader>p      Paste without overwriting register      ║
-- ║   n  <leader>y/Y    Yank to system clipboard                ║
-- ║   nv <leader>d      Delete to void register                 ║
-- ║   n  <C-n>/<C-p>    Quickfix next/prev                     ║
-- ║   n  <leader>n/p    Location list next/prev                 ║
-- ╠══════════════════════════════════════════════════════════════╣
-- ║ TELESCOPE (plugins/telescope.lua)                          ║
-- ║   n  <leader>pf     Find files                              ║
-- ║   n  <leader>gf     Find git files                          ║
-- ║   n  <leader>pg     Live grep                               ║
-- ╠══════════════════════════════════════════════════════════════╣
-- ║ HARPOON (plugins/harpoon.lua)                              ║
-- ║   n  <leader>a      Add file to harpoon                     ║
-- ║   n  <leader>hr     Remove file from harpoon                ║
-- ║   n  <C-e>          Toggle harpoon menu (telescope)         ║
-- ║   n  <C-j/k/l/;>    Select harpoon file 1/2/3/4            ║
-- ║   n  <C-S-J/K>      Harpoon prev/next                      ║
-- ╠══════════════════════════════════════════════════════════════╣
-- ║ LSP (plugins/lsp.lua)                                      ║
-- ║   n  gd             Go to definition                        ║
-- ║   n  K              Hover documentation                     ║
-- ║   n  <leader>ws     Workspace symbol search                 ║
-- ║   n  <leader>dd     Open diagnostic float                   ║
-- ║   n  <leader>ca     Code action                             ║
-- ║   n  <leader>rr     Find references                         ║
-- ║   n  <leader>rn     Rename symbol                           ║
-- ║   n  [d / ]d        Prev/next diagnostic                    ║
-- ║   i  <C-h>          Signature help                          ║
-- ╠══════════════════════════════════════════════════════════════╣
-- ║ CMP (plugins/cmp.lua) — insert mode only                   ║
-- ║   i  <C-n>/<C-p>    Next/prev completion item               ║
-- ║   i  <C-Space>      Trigger completion                      ║
-- ║   i  <C-e>          Abort completion                        ║
-- ║   i  <CR>           Confirm selection                       ║
-- ╠══════════════════════════════════════════════════════════════╣
-- ║ GIT (plugins/fugitive.lua)                                 ║
-- ║   n  <leader>gs     Git status                              ║
-- ║   n  <leader>gb     Git blame                               ║
-- ║   n  <leader>lg     Open lazygit                            ║
-- ╠══════════════════════════════════════════════════════════════╣
-- ║ OTHER                                                       ║
-- ║   n  <leader>u      Toggle undotree                         ║
-- ║   n  <leader>f      Format buffer                           ║
-- ╚══════════════════════════════════════════════════════════════╝

vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines (centered)" })

vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up (centered)" })

vim.keymap.set("n", "n", "nzzzv", { desc = "Next search (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Prev search (centered)" })

vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Paste without overwriting register" })

vim.keymap.set("n", "<leader>y", '"+y', { desc = "Yank to system clipboard" })
vim.keymap.set("v", "<leader>y", '"+y', { desc = "Yank to system clipboard" })
vim.keymap.set("n", "<leader>Y", '"+Y', { desc = "Yank line to system clipboard" })

vim.keymap.set("n", "<leader>d", '"_d', { desc = "Delete to void register" })
vim.keymap.set("v", "<leader>d", '"_d', { desc = "Delete to void register" })

vim.keymap.set("i", "<C-c>", "<Esc>", { desc = "Exit insert mode" })

vim.keymap.set("n", "Q", "<nop>", { desc = "Disabled" })

vim.keymap.set("n", "<C-n>", "<cmd>cnext<CR>zz", { desc = "Next quickfix" })
vim.keymap.set("n", "<C-p>", "<cmd>cprev<CR>zz", { desc = "Prev quickfix" })
vim.keymap.set("n", "<leader>n", "<cmd>lnext<CR>zz", { desc = "Next location list" })
vim.keymap.set("n", "<leader>p", "<cmd>lprev<CR>zz", { desc = "Prev location list" })
