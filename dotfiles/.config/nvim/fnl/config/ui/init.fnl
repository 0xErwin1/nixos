(let [noice (require :noice)]
  (noice.setup {:lsp {:process {:enabled false}
                      :signature {:enabled false}
                      :hover {:enabled false}}}))

(let [notify (require :notify)]
  (notify.setup {:fps 10
                 :render :minimal
                 :stages :fade_in_slide_out
                 :timeout 4000
                 :top_down false
                 :background_colour "#000000"}))

(let [navic (require :nvim-navic)]
  (navic.setup {}))

(require :config.ui.treesitter)
(require :config.ui.themes)
(require :config.ui.lualine)
(require :config.ui.colorizer)
(require :config.ui.bufferline)
