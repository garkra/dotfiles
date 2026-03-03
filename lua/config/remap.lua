-- ╔═══════════════════════════════════════════════════════════════╗
-- ║                      KEYBINDING INDEX                         ║
-- ╠═══════════════════════════════════════════════════════════════╣
-- ║ GENERAL (remap.lua)                                           ║
-- ║   n   <leader>pv      Open file explorer (oil.nvim)           ║
-- ║   n   -               Open parent directory (oil.nvim)        ║
-- ║   i   jk              Exit insert mode                        ║
-- ║   i   <C-c>           Exit insert mode                        ║
-- ║   n   Q               Disabled                                ║
-- ║   v   J/K             Move selection down/up                  ║
-- ║   n   J               Join lines (centered)                   ║
-- ║   n   <C-d>/<C-u>     Scroll down/up (centered)               ║
-- ║   n   n/N             Next/prev search (centered)             ║
-- ║   x   <leader>p       Paste without overwriting register      ║
-- ║   n   <leader>y/Y     Yank to system clipboard                ║
-- ║   n   <leader>yf      Copy current buffer filepath            ║
-- ║   nv  <leader>d       Delete to void register                 ║
-- ║   n   <leader>dq      Diagnostics to quickfix                 ║
-- ║   n   <C-n>/<C-p>     Quickfix next/prev                      ║
-- ║   n   <leader>n/p     Location list next/prev                 ║
-- ╠═══════════════════════════════════════════════════════════════╣
-- ║ TELESCOPE (plugins/telescope.lua)                             ║
-- ║   n   <leader>pf      Find files                              ║
-- ║   n   <leader>gf      Find git files                          ║
-- ║   n   <leader>pg      Live grep                               ║
-- ║   n   <leader>bf      Browse open buffers                     ║
-- ║   n   <C-e>           Recent files (oldfiles)                 ║
-- ║   *   <C-x>           Open in horizontal split (in picker)    ║
-- ║   *   <C-v>           Open in vertical split (in picker)      ║
-- ╠═══════════════════════════════════════════════════════════════╣
-- ║ LSP (plugins/lsp.lua)                                         ║
-- ║   n   gd              Go to definition                        ║
-- ║   n   K               Hover documentation                     ║
-- ║   n   <leader>ws      Workspace symbol search                 ║
-- ║   n   <leader>dd      Open diagnostic float                   ║
-- ║   n   <leader>ca      Code action                             ║
-- ║   n   <leader>rr      Find references                         ║
-- ║   n   <leader>rn      Rename symbol                           ║
-- ║   n   [d / ]d         Prev/next diagnostic                    ║
-- ║   i   <C-h>           Signature help                          ║
-- ╠═══════════════════════════════════════════════════════════════╣
-- ║ CMP (plugins/cmp.lua) — insert mode only                      ║
-- ║   i   <C-n>/<C-p>     Next/prev completion item               ║
-- ║   i   <C-Space>       Trigger completion                      ║
-- ║   i   <C-e>           Abort completion                        ║
-- ║   i   <CR>            Confirm selection                       ║
-- ╠═══════════════════════════════════════════════════════════════╣
-- ║ GIT (plugins/fugitive.lua)                                    ║
-- ║   n   <leader>gs      Git status                              ║
-- ║   n   <leader>gb      Git blame                               ║
-- ║   n   <leader>lg      Open lazygit                            ║
-- ╠═══════════════════════════════════════════════════════════════╣
-- ║ FLASH (plugins/flash.lua)                                     ║
-- ║   nxo s               Flash jump                              ║
-- ║   nxo f/F/t/T         Enhanced with flash labels              ║
-- ║   n   /               Search with flash labels                ║
-- ║   c   <C-s>           Toggle flash during search              ║
-- ╠═══════════════════════════════════════════════════════════════╣
-- ║ COPILOT (plugins/copilot.lua)                                 ║
-- ║   i   Tab             Accept copilot suggestion               ║
-- ╠═══════════════════════════════════════════════════════════════╣
-- ║ SPLITS (remap.lua)                                            ║
-- ║   n   <leader>sv        Vertical split                        ║
-- ║   n   <leader>sh        Horizontal split                      ║
-- ║   n   <leader>sx        Close split                           ║
-- ║   n   <leader>se        Equalize split sizes                  ║
-- ║   n   <C-Up/Down>       Resize split vertically               ║
-- ║   n   <C-Left/Right>    Resize split horizontally             ║
-- ╠═══════════════════════════════════════════════════════════════╣
-- ║ TABS (remap.lua)                                              ║
-- ║   n   Shift+H           Prev tab                              ║
-- ║   n   Shift+L           Next tab                              ║
-- ║   n   <leader>bn        New tab                               ║
-- ║   n   <leader>bc        Close tab                             ║
-- ║   n   <leader>bo        Close other tabs                      ║
-- ╠═══════════════════════════════════════════════════════════════╣
-- ║ TODO (plugins/todo.lua) — buffer-local to TODO float            ║
-- ║   n   <leader>td      Toggle floating TODO                    ║
-- ║   n   q               Close TODO (saves first)                ║
-- ║   n   <leader>a       Add new item to section                  ║
-- ║   n   <leader>s       Start item [~]                          ║
-- ║   n   <leader>d       Mark done [x] + move to DONE            ║
-- ║   n   <leader><BS>    Uncheck [ ]                             ║
-- ╠═══════════════════════════════════════════════════════════════╣
-- ║ OTHER                                                         ║
-- ║   n   <leader>u       Toggle undotree                         ║
-- ║   n   <leader>f       Format buffer                           ║
-- ║   n   <C-?>           Show all keybindings                    ║
-- ╚═══════════════════════════════════════════════════════════════╝

vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })

vim.keymap.set("v", "J", function()
	local reindent = vim.bo.filetype ~= "markdown" and "=" or ""
	return ":m '>+1<CR>gv" .. reindent .. "gv"
end, { expr = true, desc = "Move selection down" })
vim.keymap.set("v", "K", function()
	local reindent = vim.bo.filetype ~= "markdown" and "=" or ""
	return ":m '<-2<CR>gv" .. reindent .. "gv"
end, { expr = true, desc = "Move selection up" })

vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines (centered)" })

vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up (centered)" })

vim.keymap.set("n", "n", "nzzzv", { desc = "Next search (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Prev search (centered)" })

vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Paste without overwriting register" })

vim.keymap.set("n", "<leader>y", '"+y', { desc = "Yank to system clipboard" })
vim.keymap.set("v", "<leader>y", '"+y', { desc = "Yank to system clipboard" })
vim.keymap.set("n", "<leader>Y", '"+Y', { desc = "Yank line to system clipboard" })
vim.keymap.set("n", "<leader>yf", ":let @+ = expand('%')<cr>", { desc = "Copy current buffer filepath" })

vim.keymap.set("n", "<leader>d", '"_d', { desc = "Delete to void register" })
vim.keymap.set("v", "<leader>d", '"_d', { desc = "Delete to void register" })

vim.keymap.set("i", "<C-c>", "<Esc>", { desc = "Exit insert mode" })

vim.keymap.set("n", "Q", "<nop>", { desc = "Disabled" })

vim.keymap.set("n", "<leader>dq", vim.diagnostic.setqflist, { desc = "Diagnostics to quickfix" })
vim.keymap.set("n", "<C-n>", "<cmd>cnext<CR>zz", { desc = "Next quickfix" })
vim.keymap.set("n", "<C-p>", "<cmd>cprev<CR>zz", { desc = "Prev quickfix" })
vim.keymap.set("n", "<leader>n", "<cmd>lnext<CR>zz", { desc = "Next location list" })
vim.keymap.set("n", "<leader>p", "<cmd>lprev<CR>zz", { desc = "Prev location list" })

vim.keymap.set("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "Vertical split" })
vim.keymap.set("n", "<leader>sh", "<cmd>split<CR>", { desc = "Horizontal split" })
vim.keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close split" })
vim.keymap.set("n", "<leader>se", "<C-w>=", { desc = "Equalize split sizes" })
vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Resize split up" })
vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Resize split down" })
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Resize split left" })
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Resize split right" })

vim.keymap.set("n", "<S-h>", "<cmd>tabprevious<CR>", { desc = "Prev tab" })
vim.keymap.set("n", "<S-l>", "<cmd>tabnext<CR>", { desc = "Next tab" })
vim.keymap.set("n", "<leader>bn", "<cmd>tabnew<CR>", { desc = "New tab" })
vim.keymap.set("n", "<leader>bc", "<cmd>tabclose<CR>", { desc = "Close tab" })
vim.keymap.set("n", "<leader>bo", "<cmd>tabonly<CR>", { desc = "Close other tabs" })
