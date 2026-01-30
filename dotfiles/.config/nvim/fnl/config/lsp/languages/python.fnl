(let [blink-cmp (require :blink.cmp)]
  (vim.lsp.config :pyright 
                  {:capabilities (blink-cmp.get_lsp_capabilities)})
  (vim.lsp.enable :pyright))
