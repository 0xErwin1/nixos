(let [bufferline (require :bufferline)]
  (bufferline.setup {:options {:numbers "none" :diagnostics "nvim_lsp"
                               :show_tab_indicators true
                               :show_buffer_close_icons false
                               :show_close_icon false
                               :color_icons true}}))

(vim.api.nvim_set_keymap :n "<TAB>" "<CMD>BufferLineCycleNext<CR>" {:noremap true :silent true})
(vim.api.nvim_set_keymap :n "<S-TAB>" "<CMD>BufferLineCyclePrev<CR>" {:noremap true :silent true})
