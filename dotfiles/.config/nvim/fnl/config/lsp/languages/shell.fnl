(let [blink-cmp (require :blink.cmp)]
  (vim.lsp.config :bashls 
                  {:capabilities (blink-cmp.get_lsp_capabilities)})
  (vim.lsp.enable :bashls))
